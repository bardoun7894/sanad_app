import 'dart:developer';
import 'package:dio/dio.dart';

/// Network logger interceptor for Dio
class NetworkLoggerInterceptor extends Interceptor {
  final bool logRequests;
  final bool logResponses;
  final bool logErrors;

  NetworkLoggerInterceptor({
    this.logRequests = true,
    this.logResponses = true,
    this.logErrors = true,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (logRequests) {
      log('🌐 NETWORK REQUEST', name: 'NetworkLogger');
      log('  Method: ${options.method}', name: 'NetworkLogger');
      log('  URL: ${options.uri}', name: 'NetworkLogger');
      if (options.headers.isNotEmpty) {
        log(
          '  Headers: ${_sanitizeHeaders(options.headers)}',
          name: 'NetworkLogger',
        );
      }
      if (options.data != null) {
        log('  Body: ${options.data}', name: 'NetworkLogger');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (logResponses) {
      log('✅ NETWORK RESPONSE', name: 'NetworkLogger');
      log('  URL: ${response.requestOptions.uri}', name: 'NetworkLogger');
      log('  Status: ${response.statusCode}', name: 'NetworkLogger');
      log('  Status Message: ${response.statusMessage}', name: 'NetworkLogger');
      if (response.data != null) {
        final data = response.data;
        if (data is Map || data is List) {
          log('  Data: $data', name: 'NetworkLogger');
        } else {
          log(
            '  Data: ${data.toString().length > 200 ? '${data.toString().substring(0, 200)}...' : data}',
            name: 'NetworkLogger',
          );
        }
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (logErrors) {
      log('❌ NETWORK ERROR', name: 'NetworkLogger');
      log('  URL: ${err.requestOptions.uri}', name: 'NetworkLogger');
      log('  Method: ${err.requestOptions.method}', name: 'NetworkLogger');
      log('  Error Type: ${err.type}', name: 'NetworkLogger');
      log('  Error Message: ${err.message}', name: 'NetworkLogger');
      log('  Response: ${err.response?.data}', name: 'NetworkLogger');
      log('  Stack Trace: ${err.stackTrace}', name: 'NetworkLogger');
    }
    super.onError(err, handler);
  }

  /// Sanitize headers to remove sensitive information
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    const sensitiveKeys = [
      'authorization',
      'Authorization',
      'token',
      'Token',
      'api-key',
      'Api-Key',
      'password',
      'Password',
    ];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '***REDACTED***';
      }
    }

    return sanitized;
  }
}

/// Firestore operation logger
class FirestoreLogger {
  static void logOperation(
    String operation,
    String collection,
    String documentId, [
    dynamic data,
  ]) {
    log('🔥 FIRESTORE $operation', name: 'FirestoreLogger');
    log('  Collection: $collection', name: 'FirestoreLogger');
    if (documentId.isNotEmpty) {
      log('  Document: $documentId', name: 'FirestoreLogger');
    }
    if (data != null) {
      log('  Data: $data', name: 'FirestoreLogger');
    }
  }

  static void logSuccess(
    String operation,
    String collection,
    String documentId,
  ) {
    log('✅ FIRESTORE $operation SUCCESS', name: 'FirestoreLogger');
    log('  Collection: $collection', name: 'FirestoreLogger');
    if (documentId.isNotEmpty) {
      log('  Document: $documentId', name: 'FirestoreLogger');
    }
  }

  static void logError(
    String operation,
    String collection,
    String documentId,
    dynamic error,
  ) {
    log('❌ FIRESTORE $operation ERROR', name: 'FirestoreLogger');
    log('  Collection: $collection', name: 'FirestoreLogger');
    if (documentId.isNotEmpty) {
      log('  Document: $documentId', name: 'FirestoreLogger');
    }
    log('  Error: $error', name: 'FirestoreLogger');
    if (error is Error) {
      log('  Stack Trace: ${error.stackTrace}', name: 'FirestoreLogger');
    }
  }

  static void logQuery(String collection, Map<String, dynamic> query) {
    log('🔍 FIRESTORE QUERY', name: 'FirestoreLogger');
    log('  Collection: $collection', name: 'FirestoreLogger');
    log('  Query: $query', name: 'FirestoreLogger');
  }
}

/// Network diagnostic utilities
class NetworkDiagnostics {
  static Future<Map<String, dynamic>> collectDiagnostics() async {
    final diagnostics = <String, dynamic>{};

    try {
      // Basic system info
      diagnostics['timestamp'] = DateTime.now().toIso8601String();
      diagnostics['platform'] = 'Flutter';

      // Network connectivity (simulated - would need connectivity package)
      diagnostics['network_available'] =
          true; // This would be checked with connectivity package

      // DNS resolution test (simulated)
      diagnostics['dns_resolution'] = await _testDnsResolution();

      // Firebase connectivity test
      diagnostics['firebase_connectivity'] = await _testFirebaseConnectivity();

      return diagnostics;
    } catch (e) {
      diagnostics['error'] = e.toString();
      return diagnostics;
    }
  }

  static Future<Map<String, dynamic>> _testDnsResolution() async {
    final results = <String, dynamic>{};
    const domains = [
      'firestore.googleapis.com',
      'firebasestorage.googleapis.com',
      'googleapis.com',
    ];

    for (final domain in domains) {
      results[domain] = 'Not implemented - would use DNS lookup';
    }

    return results;
  }

  static Future<Map<String, dynamic>> _testFirebaseConnectivity() async {
    final results = <String, dynamic>{};

    try {
      results['status'] =
          'Test not implemented - would test Firebase connection';
      results['timestamp'] = DateTime.now().toIso8601String();
    } catch (e) {
      results['error'] = e.toString();
      results['status'] = 'Failed';
    }

    return results;
  }

  static String formatDiagnostics(Map<String, dynamic> diagnostics) {
    final buffer = StringBuffer();
    buffer.writeln('📊 NETWORK DIAGNOSTICS');
    buffer.writeln('=' * 50);

    for (final entry in diagnostics.entries) {
      if (entry.value is Map) {
        buffer.writeln('${entry.key}:');
        final subMap = entry.value as Map;
        for (final subEntry in subMap.entries) {
          buffer.writeln('  ${subEntry.key}: ${subEntry.value}');
        }
      } else {
        buffer.writeln('${entry.key}: ${entry.value}');
      }
    }

    buffer.writeln('=' * 50);
    return buffer.toString();
  }
}

/// Utility to log network operations with timing
class TimedNetworkOperation {
  final String operation;
  final DateTime startTime;

  TimedNetworkOperation(this.operation) : startTime = DateTime.now();

  void complete([dynamic result]) {
    final duration = DateTime.now().difference(startTime);
    log(
      '⏱️ NETWORK TIMING: $operation completed in ${duration.inMilliseconds}ms',
      name: 'NetworkLogger',
    );
    if (result != null) {
      log('  Result: $result', name: 'NetworkLogger');
    }
  }

  void error(dynamic error) {
    final duration = DateTime.now().difference(startTime);
    log(
      '⏱️ NETWORK TIMING: $operation failed after ${duration.inMilliseconds}ms',
      name: 'NetworkLogger',
    );
    log('  Error: $error', name: 'NetworkLogger');
  }
}
