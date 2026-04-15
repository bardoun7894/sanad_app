import 'dart:async';
import 'dart:math';

/// Retry configuration
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffFactor;
  final Duration maxDelay;
  final bool Function(dynamic error)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffFactor = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });
}

/// Retry utility for network operations
class RetryUtils {
  /// Execute an operation with retry logic
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
  }) async {
    int attempt = 0;
    final errors = <Exception>[];

    while (attempt < config.maxAttempts) {
      attempt++;

      try {
        return await operation();
      } catch (error) {
        errors.add(error is Exception ? error : Exception(error.toString()));

        // Check if we should retry
        final shouldRetry = _shouldRetry(error, config);
        if (!shouldRetry || attempt >= config.maxAttempts) {
          throw RetryException(
            'Operation failed after $attempt attempts',
            errors,
            attempt,
          );
        }

        // Calculate delay with exponential backoff
        final delay = _calculateDelay(attempt, config);

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    throw RetryException(
      'Operation failed after ${config.maxAttempts} attempts',
      errors,
      config.maxAttempts,
    );
  }

  /// Execute an operation with retry and fallback
  static Future<T> retryWithFallback<T>({
    required Future<T> Function() operation,
    required Future<T> Function() fallback,
    RetryConfig config = const RetryConfig(),
  }) async {
    try {
      return await retry(operation, config: config);
    } catch (e) {
      // If retry fails, try fallback
      try {
        return await fallback();
      } catch (fallbackError) {
        throw RetryException('Both operation and fallback failed', [
          e is Exception ? e : Exception(e.toString()),
          fallbackError is Exception
              ? fallbackError
              : Exception(fallbackError.toString()),
        ], 0);
      }
    }
  }

  /// Check if an error should trigger a retry
  static bool _shouldRetry(dynamic error, RetryConfig config) {
    // Use custom shouldRetry function if provided
    if (config.shouldRetry != null) {
      return config.shouldRetry!(error);
    }

    // Check for network-related exceptions
    if (error is TimeoutException) {
      return true;
    }

    // Check error message for network-related errors
    final errorString = error.toString().toLowerCase();
    const networkKeywords = [
      'socket',
      'timeout',
      'network',
      'connection',
      'unavailable',
      'host',
      'dns',
    ];

    for (final keyword in networkKeywords) {
      if (errorString.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Calculate delay with exponential backoff and jitter
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    // Exponential backoff: delay = initialDelay * (backoffFactor ^ (attempt - 1))
    final exponentialMs =
        config.initialDelay.inMilliseconds *
        pow(config.backoffFactor, attempt - 1);

    // Add jitter (±20%) to prevent thundering herd
    final jitter = 0.8 + Random().nextDouble() * 0.4; // 0.8 to 1.2
    final delayMs = (exponentialMs * jitter).round();

    // Cap at maxDelay
    if (delayMs > config.maxDelay.inMilliseconds) {
      return config.maxDelay;
    }

    return Duration(milliseconds: delayMs);
  }

  /// Create a retryable Firestore operation
  static Future<T> retryFirestore<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(
      maxAttempts: 3,
      initialDelay: Duration(seconds: 2),
      backoffFactor: 2.0,
      maxDelay: Duration(seconds: 10),
    ),
  }) async {
    return await retry(operation, config: config);
  }

  /// Create a retryable network request
  static Future<T> retryNetworkRequest<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(
      maxAttempts: 3,
      initialDelay: Duration(seconds: 1),
      backoffFactor: 1.5,
      maxDelay: Duration(seconds: 5),
    ),
  }) async {
    return await retry(operation, config: config);
  }

  /// Execute multiple operations in parallel with retry
  static Future<List<T>> retryAll<T>(
    List<Future<T> Function()> operations, {
    RetryConfig config = const RetryConfig(),
  }) async {
    final futures = operations.map((op) => retry(op, config: config));
    return await Future.wait(futures);
  }
}

/// Exception thrown when retries are exhausted
class RetryException implements Exception {
  final String message;
  final List<Exception> errors;
  final int attempts;

  RetryException(this.message, this.errors, this.attempts);

  @override
  String toString() {
    final errorMessages = errors.map((e) => e.toString()).join(', ');
    return 'RetryException: $message (attempts: $attempts, errors: $errorMessages)';
  }
}

/// Circuit breaker for preventing cascading failures
class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;
  final int halfOpenMaxRequests;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _halfOpenSuccessCount = 0;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 30),
    this.halfOpenMaxRequests = 3,
  });

  /// Get current state
  CircuitBreakerState get state => _state;

  /// Check if request is allowed
  bool allowRequest() {
    _updateState();
    return _state != CircuitBreakerState.open;
  }

  /// Record a successful operation
  void recordSuccess() {
    if (_state == CircuitBreakerState.halfOpen) {
      _halfOpenSuccessCount++;
      if (_halfOpenSuccessCount >= halfOpenMaxRequests) {
        _reset();
      }
    } else {
      _reset();
    }
  }

  /// Record a failed operation
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  /// Update circuit breaker state based on time
  void _updateState() {
    if (_state == CircuitBreakerState.open && _lastFailureTime != null) {
      final timeSinceFailure = DateTime.now().difference(_lastFailureTime!);
      if (timeSinceFailure >= resetTimeout) {
        _state = CircuitBreakerState.halfOpen;
        _halfOpenSuccessCount = 0;
      }
    }
  }

  /// Reset to closed state
  void _reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitBreakerState.closed;
    _halfOpenSuccessCount = 0;
  }
}

/// Circuit breaker states
enum CircuitBreakerState {
  closed, // Normal operation
  open, // Rejecting requests
  halfOpen, // Testing if service recovered
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerException implements Exception {
  final String message;

  CircuitBreakerException(this.message);

  @override
  String toString() => 'CircuitBreakerException: $message';
}
