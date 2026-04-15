import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity status
enum NetworkStatus { connected, disconnected, unknown }

/// Network service for monitoring connectivity
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _statusController =
      StreamController<NetworkStatus>.broadcast();

  NetworkService() {
    _init();
  }

  /// Initialize network monitoring
  Future<void> _init() async {
    // Check initial connectivity
    final initialResults = await _connectivity.checkConnectivity();
    _statusController.add(_getStatusFromResults(initialResults));

    // Listen for connectivity changes (now returns List<ConnectivityResult>)
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _statusController.add(_getStatusFromResults(results));
    });
  }

  /// Connected if ANY result indicates a connection
  NetworkStatus _getStatusFromResults(List<ConnectivityResult> results) {
    // If no results or only none, we're disconnected
    if (results.isEmpty) {
      return NetworkStatus.unknown;
    }

    // Check if any result indicates a connection
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
        case ConnectivityResult.mobile:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.vpn:
        case ConnectivityResult.bluetooth:
          return NetworkStatus.connected;
        case ConnectivityResult.none:
          continue; // Check next result
        default:
          continue;
      }
    }

    // If we only have 'none' results
    if (results.contains(ConnectivityResult.none)) {
      return NetworkStatus.disconnected;
    }

    return NetworkStatus.unknown;
  }

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Check current connectivity
  Future<NetworkStatus> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return _getStatusFromResults(results);
  }

  /// Check if device is currently connected to the internet
  Future<bool> isConnected() async {
    final status = await checkConnectivity();
    return status == NetworkStatus.connected;
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }
}

/// Riverpod provider for network service
final networkServiceProvider = Provider<NetworkService>((ref) {
  final service = NetworkService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Riverpod provider for current network status
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final networkService = ref.watch(networkServiceProvider);
  return networkService.statusStream;
});

/// Riverpod provider for connectivity check (bool)
final isConnectedProvider = StreamProvider<bool>((ref) {
  final networkStatusAsync = ref.watch(networkStatusProvider);
  return networkStatusAsync.when(
    data: (status) => Stream.value(status == NetworkStatus.connected),
    error: (error, stackTrace) => Stream.value(false),
    loading: () => Stream.value(false),
  );
});

/// Helper function to check connectivity before network operations
Future<bool> checkNetworkConnectivity(Ref ref) async {
  final networkService = ref.read(networkServiceProvider);
  return await networkService.isConnected();
}

/// Network-aware operation wrapper
Future<T> withNetworkCheck<T>(
  Ref ref,
  Future<T> Function() operation, {
  Future<T> Function()? offlineFallback,
  String? errorMessage,
}) async {
  final isConnected = await checkNetworkConnectivity(ref);

  if (!isConnected) {
    if (offlineFallback != null) {
      return await offlineFallback();
    }
    throw NetworkException(
      message: errorMessage ?? 'No internet connection',
      isOffline: true,
    );
  }

  try {
    return await operation();
  } catch (e) {
    // Re-throw with network context if it's a network error
    if (e.toString().contains('SocketException') ||
        e.toString().contains('Network') ||
        e.toString().contains('timeout')) {
      throw NetworkException(
        message: 'Network error: ${e.toString()}',
        originalError: e,
        isOffline: false,
      );
    }
    rethrow;
  }
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  final Object? originalError;
  final bool isOffline;

  NetworkException({
    required this.message,
    this.originalError,
    required this.isOffline,
  });

  @override
  String toString() {
    return 'NetworkException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
  }
}

/// Diagnostic function to test network connectivity
Future<Map<String, dynamic>> runNetworkDiagnostics() async {
  final connectivity = Connectivity();
  final results = <String, dynamic>{};

  try {
    // Check connectivity status (returns List<ConnectivityResult> in 6.x)
    final statusList = await connectivity.checkConnectivity();
    results['connectivity_status'] = statusList.toString();
    results['has_connection'] =
        !statusList.contains(ConnectivityResult.none) ||
        statusList.any(
          (r) =>
              r == ConnectivityResult.wifi ||
              r == ConnectivityResult.mobile ||
              r == ConnectivityResult.ethernet,
        );

    // Additional diagnostic info
    results['timestamp'] = DateTime.now().toIso8601String();
    results['diagnostic_version'] = '1.1';

    return results;
  } catch (e) {
    results['error'] = e.toString();
    results['has_connection'] = false;
    return results;
  }
}
