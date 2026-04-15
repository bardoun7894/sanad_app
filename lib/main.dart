import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'features/auth/services/token_storage_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/services/app_config.dart';
import 'core/services/fcm_service.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up Zego call invitation system navigator key and system calling UI
  // This must happen before runApp per Zego docs
  // Zego SDK does not support web platform
  if (!kIsWeb) {
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
    await ZegoUIKit().initLog().then((value) async {
      await ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
        [ZegoUIKitSignalingPlugin()],
      );
    });
  }

  runApp(const StartupBootstrapApp());
}

class StartupBootstrapApp extends StatefulWidget {
  const StartupBootstrapApp({super.key});

  @override
  State<StartupBootstrapApp> createState() => _StartupBootstrapAppState();
}

class _StartupBootstrapAppState extends State<StartupBootstrapApp> {
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
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      },
      timeout: const Duration(seconds: 4),
      critical: false,
    );

    if (!kIsWeb) {
      await _runStep(
        label: 'fcm.background_handler',
        action: () async {
          FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler,
          );
        },
        timeout: const Duration(seconds: 4),
        critical: false,
      );
    }

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

    await _runStep(
      label: 'system.orientation',
      action: () => SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
      timeout: const Duration(seconds: 4),
      critical: false,
    );

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

    _startFcmInitializationInBackground();

    return _StartupInitResult(tokenStorage: tokenStorage);
  }

  void _startFcmInitializationInBackground() {
    unawaited(
      _runStep(
        label: 'fcm.initialize.background',
        action: () async {
          final fcmService = FCMService();
          fcmService.setNavigatorKey(navigatorKey);
          await fcmService.initialize();
        },
        // 20s: allows APNS polling (~2s) + getInitialMessage timeout (5s)
        // + local-notifications setup on a real device.  Not critical —
        // a timeout here just means push-tap navigation on launch is skipped.
        timeout: const Duration(seconds: 20),
        critical: false,
      ),
    );
  }

  Future<void> _runStep({
    required String label,
    required Future<void> Function() action,
    required Duration timeout,
    required bool critical,
  }) async {
    final sw = Stopwatch()..start();
    debugPrint('🚀 Startup step begin: $label');

    try {
      await action().timeout(timeout);
      sw.stop();
      debugPrint('✅ Startup step done: $label (${sw.elapsedMilliseconds}ms)');
    } catch (e, st) {
      sw.stop();
      debugPrint('❌ Startup step failed: $label (${sw.elapsedMilliseconds}ms)');
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
          final error = snapshot.error;
          return _StartupErrorApp(
            errorMessage: error?.toString() ?? 'Unknown startup error',
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
                  'App failed to start',
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
