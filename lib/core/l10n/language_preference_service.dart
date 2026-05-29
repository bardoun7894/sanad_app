import 'package:hive_flutter/hive_flutter.dart';

import 'language_provider.dart';

/// Persists the user's chosen UI language across app restarts.
///
/// Without this, the app defaults back to Arabic on every cold start, even
/// after the user explicitly switched to English. Hive-backed so the value
/// survives kill+relaunch on iOS and Android.
class LanguagePreferenceService {
  static const String _boxName = 'language_prefs';
  static const String _key = 'app_language';

  late Box _box;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _box = await Hive.openBox(_boxName);
    _initialized = true;
  }

  /// Read the saved language. Returns null if the user has never chosen one
  /// — in that case callers should fall back to the app default (Arabic).
  AppLanguage? getSavedLanguage() {
    if (!_initialized) return null;
    final code = _box.get(_key) as String?;
    return _codeToLanguage(code);
  }

  Future<void> saveLanguage(AppLanguage language) async {
    if (!_initialized) return;
    await _box.put(_key, language.code);
  }

  AppLanguage? _codeToLanguage(String? code) {
    switch (code) {
      case 'ar':
        return AppLanguage.arabic;
      case 'en':
        return AppLanguage.english;
      case 'fr':
        return AppLanguage.french;
      default:
        return null;
    }
  }
}
