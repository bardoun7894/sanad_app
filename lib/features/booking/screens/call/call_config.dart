import 'package:sanad_app/core/services/app_config.dart';

/// Video call configuration.
///
/// Priority chain: Firestore (admin dashboard) > --dart-define > .env
/// Set keys from Admin > Settings > API Keys.
class CallConfig {
  /// ZegoCloud App ID
  static int get appId => AppConfig.zegoAppId;

  /// ZegoCloud App Sign
  static String get appSign => AppConfig.zegoAppSign;

  /// Optional token-based auth
  static String get token => AppConfig.zegoToken;

  static bool get isConfigured => AppConfig.isZegoConfigured;
}
