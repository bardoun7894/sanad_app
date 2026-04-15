import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_logger.dart';

/// Service for testing network and Firestore connectivity
class ConnectivityTestService {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  ConnectivityTestService() {
    // Configure Dio with reasonable timeouts
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.sendTimeout = const Duration(seconds: 10);
  }

  /// Run comprehensive connectivity tests
  Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};
    results['timestamp'] = DateTime.now().toIso8601String();

    try {
      // Test 1: Basic network connectivity
      results['basic_connectivity'] = await testBasicConnectivity();

      // Test 2: DNS resolution
      results['dns_resolution'] = await testDnsResolution();

      // Test 3: Firebase connectivity
      results['firebase_connectivity'] = await testFirebaseConnectivity();

      // Test 4: Firestore operations
      results['firestore_operations'] = await testFirestoreOperations();

      // Test 5: Internet access
      results['internet_access'] = await testInternetAccess();

      // Calculate overall status
      results['overall_status'] = _calculateOverallStatus(results);
      results['is_healthy'] = results['overall_status'] == 'healthy';
    } catch (e) {
      results['error'] = e.toString();
      results['overall_status'] = 'failed';
      results['is_healthy'] = false;
    }

    return results;
  }

  /// Test basic network connectivity
  Future<Map<String, dynamic>> testBasicConnectivity() async {
    final result = <String, dynamic>{};

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      result['connectivity_type'] = connectivityResult.toString();
      result['has_connection'] = connectivityResult != ConnectivityResult.none;
      result['status'] = 'success';
    } catch (e) {
      result['error'] = e.toString();
      result['status'] = 'failed';
      result['has_connection'] = false;
    }

    return result;
  }

  /// Test DNS resolution for critical domains using HTTP HEAD requests
  /// (Works on all platforms including web)
  Future<Map<String, dynamic>> testDnsResolution() async {
    final result = <String, dynamic>{};
    final domains = [
      'firestore.googleapis.com',
      'firebasestorage.googleapis.com',
      'googleapis.com',
      'google.com',
    ];

    for (final domain in domains) {
      try {
        final response = await _dio.head('https://$domain');
        result[domain] = {'resolved': true, 'status_code': response.statusCode};
      } catch (e) {
        // Even a 404 means DNS resolved successfully
        final errorStr = e.toString();
        if (errorStr.contains('404') ||
            errorStr.contains('403') ||
            errorStr.contains('301') ||
            errorStr.contains('302')) {
          result[domain] = {
            'resolved': true,
            'note': 'DNS resolved (HTTP error)',
          };
        } else {
          result[domain] = {'resolved': false, 'error': errorStr};
        }
      }
    }

    // Check if all critical domains resolved
    final criticalDomains = ['firestore.googleapis.com', 'googleapis.com'];
    final allCriticalResolved = criticalDomains.every((domain) {
      final domainResult = result[domain] as Map<String, dynamic>;
      return domainResult['resolved'] == true;
    });

    result['all_critical_resolved'] = allCriticalResolved;
    result['status'] = allCriticalResolved ? 'success' : 'partial';

    return result;
  }

  /// Test Firebase connectivity
  Future<Map<String, dynamic>> testFirebaseConnectivity() async {
    final result = <String, dynamic>{};
    final timer = TimedNetworkOperation('Firebase connectivity test');

    try {
      // Test Firestore ping by reading a non-existent document
      final testDoc = _firestore.collection('_connectivity_test').doc('ping');
      await testDoc.get();

      timer.complete();
      result['firestore_ping'] = 'success';
      result['latency_ms'] = 'N/A'; // Would need actual timing
      result['status'] = 'success';
    } catch (e) {
      timer.error(e);
      result['firestore_ping'] = 'failed';
      result['error'] = e.toString();
      result['status'] = 'failed';

      // Check for specific error types
      if (e.toString().contains('PERMISSION_DENIED')) {
        result['error_type'] = 'permission_denied';
      } else if (e.toString().contains('UNAVAILABLE')) {
        result['error_type'] = 'unavailable';
      } else if (e.toString().contains('NOT_FOUND')) {
        result['error_type'] = 'not_found';
      } else if (e.toString().contains('network')) {
        result['error_type'] = 'network_error';
      }
    }

    return result;
  }

  /// Test Firestore operations
  Future<Map<String, dynamic>> testFirestoreOperations() async {
    final result = <String, dynamic>{};
    final testId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Test write operation
      final writeDoc = _firestore
          .collection('_connectivity_test')
          .doc('write_$testId');
      await writeDoc.set({
        'test': 'connectivity',
        'timestamp': FieldValue.serverTimestamp(),
      });
      result['write_operation'] = 'success';

      // Test read operation
      final readDoc = await writeDoc.get();
      result['read_operation'] = 'success';
      result['document_exists'] = readDoc.exists;

      // Test delete operation
      await writeDoc.delete();
      result['delete_operation'] = 'success';

      result['status'] = 'success';
      result['all_operations_passed'] = true;
    } catch (e) {
      result['error'] = e.toString();
      result['status'] = 'failed';
      result['all_operations_passed'] = false;
    }

    return result;
  }

  /// Test general internet access
  Future<Map<String, dynamic>> testInternetAccess() async {
    final result = <String, dynamic>{};
    final testUrls = [
      'https://www.google.com',
      'https://www.cloudflare.com',
      'https://api.github.com',
    ];

    for (final url in testUrls) {
      try {
        final response = await _dio.head(url);
        result[url] = {
          'status_code': response.statusCode,
          'success':
              response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 400,
        };
      } catch (e) {
        result[url] = {'error': e.toString(), 'success': false};
      }
    }

    // Check if at least one URL succeeded
    final anySuccess = result.entries.any((entry) {
      if (entry.value is Map) {
        final value = entry.value as Map<String, dynamic>;
        return value['success'] == true;
      }
      return false;
    });

    result['any_success'] = anySuccess;
    result['status'] = anySuccess ? 'success' : 'failed';

    return result;
  }

  /// Calculate overall status from test results
  String _calculateOverallStatus(Map<String, dynamic> results) {
    final criticalTests = [
      results['basic_connectivity']?['has_connection'],
      results['dns_resolution']?['all_critical_resolved'],
      results['firebase_connectivity']?['status'] == 'success',
      results['firestore_operations']?['all_operations_passed'],
    ];

    final allCriticalPassed = criticalTests.every((test) => test == true);

    if (allCriticalPassed) {
      return 'healthy';
    }

    final anyCriticalFailed = criticalTests.any((test) => test == false);
    if (anyCriticalFailed) {
      return 'critical_failure';
    }

    return 'degraded';
  }

  /// Format test results for display
  String formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    buffer.writeln('🔧 CONNECTIVITY TEST RESULTS');
    buffer.writeln('=' * 60);
    buffer.writeln('Timestamp: ${results['timestamp']}');
    buffer.writeln(
      'Overall Status: ${results['overall_status']?.toString().toUpperCase()}',
    );
    buffer.writeln('Healthy: ${results['is_healthy'] == true ? '✅' : '❌'}');
    buffer.writeln();

    // Basic connectivity
    final basic = results['basic_connectivity'] as Map<String, dynamic>?;
    if (basic != null) {
      buffer.writeln('📶 BASIC CONNECTIVITY');
      buffer.writeln('  Type: ${basic['connectivity_type']}');
      buffer.writeln(
        '  Connected: ${basic['has_connection'] == true ? '✅' : '❌'}',
      );
      buffer.writeln();
    }

    // DNS resolution
    final dns = results['dns_resolution'] as Map<String, dynamic>?;
    if (dns != null) {
      buffer.writeln('🔍 DNS RESOLUTION');
      for (final entry in dns.entries) {
        if (entry.key == 'status' || entry.key == 'all_critical_resolved')
          continue;
        final domainResult = entry.value as Map<String, dynamic>;
        buffer.writeln(
          '  ${entry.key}: ${domainResult['resolved'] == true ? '✅' : '❌'}',
        );
        if (domainResult['resolved'] == true) {
          final addresses = domainResult['addresses'] as List<dynamic>?;
          if (addresses != null && addresses.isNotEmpty) {
            buffer.writeln('    → ${addresses.first}');
          }
        }
      }
      buffer.writeln(
        '  All Critical Resolved: ${dns['all_critical_resolved'] == true ? '✅' : '❌'}',
      );
      buffer.writeln();
    }

    // Firebase connectivity
    final firebase = results['firebase_connectivity'] as Map<String, dynamic>?;
    if (firebase != null) {
      buffer.writeln('🔥 FIREBASE CONNECTIVITY');
      buffer.writeln(
        '  Firestore Ping: ${firebase['firestore_ping'] == 'success' ? '✅' : '❌'}',
      );
      if (firebase['error_type'] != null) {
        buffer.writeln('  Error Type: ${firebase['error_type']}');
      }
      buffer.writeln();
    }

    // Firestore operations
    final firestore = results['firestore_operations'] as Map<String, dynamic>?;
    if (firestore != null) {
      buffer.writeln('💾 FIRESTORE OPERATIONS');
      buffer.writeln(
        '  Write: ${firestore['write_operation'] == 'success' ? '✅' : '❌'}',
      );
      buffer.writeln(
        '  Read: ${firestore['read_operation'] == 'success' ? '✅' : '❌'}',
      );
      buffer.writeln(
        '  Delete: ${firestore['delete_operation'] == 'success' ? '✅' : '❌'}',
      );
      buffer.writeln(
        '  All Operations: ${firestore['all_operations_passed'] == true ? '✅' : '❌'}',
      );
      buffer.writeln();
    }

    // Internet access
    final internet = results['internet_access'] as Map<String, dynamic>?;
    if (internet != null) {
      buffer.writeln('🌐 INTERNET ACCESS');
      for (final entry in internet.entries) {
        if (entry.key == 'status' || entry.key == 'any_success') continue;
        final urlResult = entry.value as Map<String, dynamic>;
        buffer.writeln(
          '  ${entry.key}: ${urlResult['success'] == true ? '✅' : '❌'}',
        );
      }
      buffer.writeln(
        '  Any Success: ${internet['any_success'] == true ? '✅' : '❌'}',
      );
    }

    buffer.writeln('=' * 60);
    return buffer.toString();
  }

  /// Quick health check
  Future<bool> quickHealthCheck() async {
    try {
      final connectivity = await _connectivity.checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        return false;
      }

      // Quick Firestore test
      final testDoc = _firestore
          .collection('_connectivity_test')
          .doc('healthcheck');
      await testDoc.get(const GetOptions(source: Source.serverAndCache));

      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Riverpod provider for connectivity test service
final connectivityTestServiceProvider = Provider<ConnectivityTestService>((
  ref,
) {
  return ConnectivityTestService();
});

/// Riverpod provider for connectivity test results
final connectivityTestResultsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.read(connectivityTestServiceProvider);
  return await service.runAllTests();
});
