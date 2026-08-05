import 'package:hive_flutter/hive_flutter.dart';

/// Durable throttle for the personalized subscription nudge.
///
/// The nudge may fire on a 15-minute in-app timer and on every app resume, but
/// we cap it to at most once per [_cooldown] so it stays a gentle,
/// hook-ethical prompt rather than a spam loop. Backed by Hive, mirroring
/// [SubscriptionStorageService]'s box pattern, so the cap survives app
/// restarts (all other prompt guards in the app are in-memory only).
class SubscriptionNudgeService {
  static const String _boxName = 'subscription_nudge';
  static const String _lastShownKey = 'lastNudgeShownAt';
  static const Duration _cooldown = Duration(hours: 24);

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<String>(_boxName);
    }
    return _box!;
  }

  /// Whether enough time has passed since the last nudge to show another one.
  Future<bool> canShowNudge() async {
    final box = await _getBox();
    final raw = box.get(_lastShownKey);
    if (raw == null) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last) >= _cooldown;
  }

  /// Record that the nudge was shown now, starting the cooldown window.
  Future<void> markShown() async {
    final box = await _getBox();
    await box.put(_lastShownKey, DateTime.now().toIso8601String());
  }

  /// User tapped "Maybe later" — same effect as [markShown] (respect the
  /// dismissal for the full cooldown window).
  Future<void> markDismissedForToday() => markShown();
}
