import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'features/auth/services/token_storage_service.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase initialized');
  } catch (e) {
    print('✗ Firebase initialization error: $e');
  }

  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();
    print('✓ Hive initialized');
  } catch (e) {
    print('✗ Hive initialization error: $e');
  }

  // Initialize TokenStorageService before the app starts
  final tokenStorage = TokenStorageService();
  try {
    await tokenStorage.initialize();
    print('✓ TokenStorageService initialized');
  } catch (e) {
    print('✗ TokenStorageService initialization error: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        // Override the tokenStorageProvider with our initialized instance
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
      child: const SanadApp(),
    ),
  );
}
