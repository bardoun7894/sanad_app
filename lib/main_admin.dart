// Admin-only entrypoint — for the Flutter Web admin deploy.
// Build with:
//   flutter build web -t lib/main_admin.dart --release --base-href /admin/
//
// The full app (mobile, with user + admin) uses lib/main.dart.
// The Play Store user-only build uses lib/main_user.dart.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'features/auth/services/token_storage_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/services/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AdminStartupBootstrapApp());
}

class _AdminStartupBootstrapApp extends StatefulWidget {
  const _AdminStartupBootstrapApp();

  @override
  State<_AdminStartupBootstrapApp> createState() =>
      _AdminStartupBootstrapAppState();
}

class _AdminStartupBootstrapAppState extends State<_AdminStartupBootstrapApp> {
  late Future<_StartupInitResult> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<_StartupInitResult> _initialize() async {
    await _runStep(
      label: 'firebase.initialize',
      action: () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      timeout: const Duration(seconds: 12),
      critical: true,
    );

    await _runStep(
      label: 'firestore.settings',
      action: () async {
        // IndexedDB persistence on Flutter web triggers
        // "INTERNAL ASSERTION FAILED (Unexpected state)" b815/ca9 in the JS
        // Firestore SDK when admin pages mount/dispose snapshot listeners
        // rapidly. Admin is online-only, so disable persistence on web.
        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: !kIsWeb,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      },
      timeout: const Duration(seconds: 4),
      critical: false,
    );

    await _runStep(
      label: 'hive.init',
      action: Hive.initFlutter,
      timeout: const Duration(seconds: 8),
      critical: true,
    );

    await _runStep(
      label: 'dotenv.load',
      action: () => dotenv.load(fileName: '.env'),
      timeout: const Duration(seconds: 4),
      critical: false,
    );

    await _runStep(
      label: 'appconfig.load_api_keys',
      action: AppConfig.loadFromFirestore,
      timeout: const Duration(seconds: 5),
      critical: false,
    );

    final tokenStorage = TokenStorageService();
    await _runStep(
      label: 'token_storage.initialize',
      action: tokenStorage.initialize,
      timeout: const Duration(seconds: 8),
      critical: true,
    );

    if (!kIsWeb) {
      await _runStep(
        label: 'system.orientation',
        action: () => SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]),
        timeout: const Duration(seconds: 4),
        critical: false,
      );
    }

    await _runStep(
      label: 'system.overlay_style',
      action: () async {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );
      },
      timeout: const Duration(seconds: 4),
      critical: false,
    );

    return _StartupInitResult(tokenStorage: tokenStorage);
  }

  Future<void> _runStep({
    required String label,
    required Future<void> Function() action,
    required Duration timeout,
    required bool critical,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint('🚀 [admin] startup begin: $label');
    try {
      await action().timeout(timeout);
      sw.stop();
      debugPrint('✅ [admin] startup done: $label (${sw.elapsedMilliseconds}ms)');
    } catch (e, st) {
      sw.stop();
      debugPrint(
          '❌ [admin] startup failed: $label (${sw.elapsedMilliseconds}ms)');
      debugPrint('   reason: $e');
      debugPrintStack(stackTrace: st);
      if (critical) {
        throw _StartupException(
          message: 'Critical startup step failed: $label',
          cause: e,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StartupInitResult>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _StartupLoadingApp();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _StartupErrorApp(
            errorMessage:
                snapshot.error?.toString() ?? 'Unknown startup error',
            onRetry: () {
              setState(() {
                _initFuture = _initialize();
              });
            },
          );
        }
        final result = snapshot.data!;
        return ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(result.tokenStorage),
          ],
          child: const SanadApp(),
        );
      },
    );
  }
}

class _StartupInitResult {
  final TokenStorageService tokenStorage;
  const _StartupInitResult({required this.tokenStorage});
}

class _StartupException implements Exception {
  final String message;
  final Object cause;
  const _StartupException({required this.message, required this.cause});

  @override
  String toString() => '$message\nCause: $cause';
}

class _StartupLoadingApp extends StatelessWidget {
  const _StartupLoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  const _StartupErrorApp({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 12),
                const Text(
                  'Admin failed to start',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
