import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'firestore_cache_helper.dart';

/// App configuration for API keys and settings.
///
/// ## Priority chain (highest wins):
/// 1. Firestore `system_settings/api_keys` (set from admin dashboard)
/// 2. `--dart-define` compile-time constants
/// 3. `.env` file values
///
/// Call [loadFromFirestore] once at app startup (after Firebase.initializeApp).
/// Admin dashboard writes keys via [saveToFirestore].
class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------------------
  // Firestore-backed cache (populated by loadFromFirestore)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> _firestoreKeys = {};

  /// Load config from Firestore. Reads two documents:
  /// - `system_settings/client_config` — non-secret client keys (Zego, FCM), readable by all authenticated users
  /// - `system_settings/api_keys` — sensitive keys (OpenAI, Gemini), admin-only
  ///
  /// Safe to call even if documents don't exist yet.
  static Future<void> loadFromFirestore() async {
    // 1. Always load client_config (readable by all authenticated users)
    try {
      final clientDoc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('client_config')
          .getCacheFirst();
      if (clientDoc.exists && clientDoc.data() != null) {
        _firestoreKeys.addAll(clientDoc.data()!);
        debugPrint(
          'AppConfig: Loaded ${clientDoc.data()!.length} keys from client_config',
        );
      } else {
        debugPrint('AppConfig: No client_config document (using fallbacks)');
      }
    } catch (e) {
      debugPrint('AppConfig: Could not load client_config: $e');
    }

    // 2. Try to load api_keys (admin-only — will fail for regular users)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('api_keys')
          .getCacheFirst();
      if (doc.exists && doc.data() != null) {
        _firestoreKeys.addAll(doc.data()!);
        debugPrint(
          'AppConfig: Loaded ${doc.data()!.length} keys from api_keys (admin)',
        );
      }
    } catch (e) {
      // Permission denied is expected for non-admin users
      debugPrint('AppConfig: Could not load api_keys (non-admin): $e');
    }
  }

  /// Save a single API key to Firestore (admin only).
  /// Routes to `client_config` or `api_keys` based on the field.
  static Future<void> saveKey(String field, String value) async {
    final docName = _clientConfigFields.contains(field)
        ? 'client_config'
        : 'api_keys';
    await FirebaseFirestore.instance
        .collection('system_settings')
        .doc(docName)
        .set({
          field: value,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    // Update local cache
    _firestoreKeys[field] = value;
  }

  /// Client-side (non-secret) key fields stored in `client_config`.
  static const _clientConfigFields = {
    'zego_app_id',
    'zego_app_sign',
    'zego_token',
    'fcm_vapid_key',
  };

  /// Save all API keys to Firestore at once (admin only).
  /// Automatically routes keys to the correct document:
  /// - Zego/FCM keys → `client_config` (readable by all authenticated users)
  /// - OpenAI/Gemini keys → `api_keys` (admin-only)
  static Future<void> saveAllKeys(Map<String, String> keys) async {
    final clientKeys = <String, dynamic>{};
    final secretKeys = <String, dynamic>{};

    for (final entry in keys.entries) {
      if (_clientConfigFields.contains(entry.key)) {
        clientKeys[entry.key] = entry.value;
      } else {
        secretKeys[entry.key] = entry.value;
      }
    }

    // Save client-side keys to client_config
    if (clientKeys.isNotEmpty) {
      clientKeys['updated_at'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('client_config')
          .set(clientKeys, SetOptions(merge: true));
    }

    // Save sensitive keys to api_keys
    if (secretKeys.isNotEmpty) {
      secretKeys['updated_at'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('system_settings')
          .doc('api_keys')
          .set(secretKeys, SetOptions(merge: true));
    }

    // Update local cache
    _firestoreKeys.addAll(keys);
  }

  /// Read a Firestore-cached value, then fall back to sources.
  static String _resolve(
    String firestoreField,
    String dartDefineValue,
    String dotenvKey,
  ) {
    // 1. Firestore (highest priority)
    final fsValue = _firestoreKeys[firestoreField] as String?;
    if (fsValue != null && fsValue.isNotEmpty) return fsValue;
    // 2. --dart-define
    if (dartDefineValue.isNotEmpty) return dartDefineValue;
    // 3. .env
    return dotenv.env[dotenvKey] ?? '';
  }

  // ---------------------------------------------------------------------------
  // dart-define constants (compile-time, cannot change at runtime)
  // ---------------------------------------------------------------------------
  static const String _geminiDartDefine = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _youtubeDartDefine = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: '',
  );
  static const String _fcmVapidDartDefine = String.fromEnvironment(
    'FCM_VAPID_KEY',
    defaultValue: '',
  );
  static const int _zegoAppIdDartDefine = int.fromEnvironment(
    'ZEGO_APP_ID',
    defaultValue: 0,
  );
  static const String _zegoAppSignDartDefine = String.fromEnvironment(
    'ZEGO_APP_SIGN',
    defaultValue: '',
  );
  static const String _zegoTokenDartDefine = String.fromEnvironment(
    'ZEGO_TOKEN',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // Gemini
  // ---------------------------------------------------------------------------
  static String get geminiApiKey =>
      _resolve('gemini_api_key', _geminiDartDefine, 'GEMINI_API_KEY');

  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // YouTube Data API v3
  // ---------------------------------------------------------------------------
  static String get youtubeApiKey =>
      _resolve('youtube_api_key', _youtubeDartDefine, 'YOUTUBE_API_KEY');

  static bool get isYouTubeConfigured => youtubeApiKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // FCM VAPID (web push)
  // ---------------------------------------------------------------------------
  static String get fcmVapidKey =>
      _resolve('fcm_vapid_key', _fcmVapidDartDefine, 'FCM_VAPID_KEY');

  static bool get isFCMConfigured => fcmVapidKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // ZegoCloud (video calls)
  // ---------------------------------------------------------------------------
  static int get zegoAppId {
    // 1. Firestore (highest priority)
    final fsValue = _firestoreKeys['zego_app_id'];
    if (fsValue != null) {
      if (fsValue is int && fsValue > 0) return fsValue;
      if (fsValue is String && fsValue.isNotEmpty) {
        final parsed = int.tryParse(fsValue);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    // 2. --dart-define
    if (_zegoAppIdDartDefine > 0) return _zegoAppIdDartDefine;
    // 3. .env fallback
    final envValue = dotenv.env['ZEGO_APP_ID'] ?? '';
    if (envValue.isNotEmpty) return int.tryParse(envValue) ?? 0;
    return 0;
  }

  static String get zegoAppSign =>
      _resolve('zego_app_sign', _zegoAppSignDartDefine, 'ZEGO_APP_SIGN');

  static String get zegoToken =>
      _resolve('zego_token', _zegoTokenDartDefine, 'ZEGO_TOKEN');

  static bool get isZegoConfigured =>
      zegoAppId > 0 && (zegoAppSign.isNotEmpty || zegoToken.isNotEmpty);

  // ---------------------------------------------------------------------------
  // App Settings (non-secret, hardcoded)
  // ---------------------------------------------------------------------------
  static const int chatHistoryLimit = 50;
  static const int contextMessagesLimit = 20;
  static const Duration typingIndicatorDelay = Duration(milliseconds: 500);
  static const Duration messageRetryDelay = Duration(seconds: 2);
  static const int maxMessageRetries = 3;

  // ---------------------------------------------------------------------------
  // Debug
  // ---------------------------------------------------------------------------
  static void printConfigStatus() {
    debugPrint('=== App Configuration Status ===');
    debugPrint(
      'Gemini API: ${isGeminiConfigured ? "Configured" : "Not configured"}',
    );
    debugPrint(
      'FCM VAPID:  ${isFCMConfigured ? "Configured" : "Not configured"}',
    );
    debugPrint(
      'ZegoCloud:  ${isZegoConfigured ? "Configured" : "Not configured"}',
    );
    debugPrint('Source: Firestore keys=${_firestoreKeys.length}');
    debugPrint('================================');
  }
}
