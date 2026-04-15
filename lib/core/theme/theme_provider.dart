import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _boxName = 'settings';
  static const String _key = 'themeMode';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = await Hive.openBox(_boxName);
    final savedTheme = box.get(_key) as String?;
    if (savedTheme != null) {
      state = _themeModeFromString(savedTheme);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final box = await Hive.openBox(_boxName);
    await box.put(_key, mode.toString());
  }

  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.dark;
    await setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  ThemeMode _themeModeFromString(String themeString) {
    if (themeString == ThemeMode.light.toString()) return ThemeMode.light;
    if (themeString == ThemeMode.dark.toString()) return ThemeMode.dark;
    return ThemeMode.system;
  }
}
