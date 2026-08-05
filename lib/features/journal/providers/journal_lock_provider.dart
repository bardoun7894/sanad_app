import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

class JournalLockState {
  final bool isEnabled;
  final bool isUnlocked;

  const JournalLockState({this.isEnabled = false, this.isUnlocked = false});

  JournalLockState copyWith({bool? isEnabled, bool? isUnlocked}) {
    return JournalLockState(
      isEnabled: isEnabled ?? this.isEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  /// True when the lock screen must be shown before content.
  bool get isLocked => isEnabled && !isUnlocked;
}

class JournalLockNotifier extends StateNotifier<JournalLockState> {
  static const String _pinKey = 'journal_pin_hash';
  static const String _enabledKey = 'journal_lock_enabled';

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  JournalLockNotifier({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication(),
        super(const JournalLockState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final enabled = await _read(_enabledKey);
      final isEnabled = enabled == 'true';
      // When locked, entries start hidden until the user unlocks this session.
      state = JournalLockState(isEnabled: isEnabled, isUnlocked: !isEnabled);
    } catch (e) {
      // Storage unavailable — default to unlocked rather than crashing.
      debugPrint('Journal lock init failed: $e');
      state = const JournalLockState(isEnabled: false, isUnlocked: true);
    }
  }

  // --- Storage with graceful fallback to app-private Hive ---
  // Prefer the OS secure enclave; if the secure-storage plugin is unavailable
  // fall back to a local Hive box so the lock still works.
  static const String _fallbackBox = 'journal_lock_fallback';

  Future<String?> _read(String key) async {
    try {
      final v = await _storage.read(key: key);
      if (v != null) return v;
    } catch (_) {}
    try {
      final box = await Hive.openBox(_fallbackBox);
      return box.get(key) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return;
    } catch (_) {}
    final box = await Hive.openBox(_fallbackBox);
    await box.put(key, value);
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
    try {
      final box = await Hive.openBox(_fallbackBox);
      await box.delete(key);
    } catch (_) {}
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  /// Set (or change) the PIN and enable the lock.
  Future<void> setPin(String pin) async {
    await _write(_pinKey, _hash(pin));
    await _write(_enabledKey, 'true');
    state = const JournalLockState(isEnabled: true, isUnlocked: true);
  }

  /// Remove the PIN and disable the lock entirely.
  Future<void> disableLock() async {
    await _delete(_pinKey);
    await _write(_enabledKey, 'false');
    state = const JournalLockState(isEnabled: false, isUnlocked: true);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _read(_pinKey);
    if (stored != null && stored == _hash(pin)) {
      state = state.copyWith(isUnlocked: true);
      return true;
    }
    return false;
  }

  /// Attempt biometric unlock. Returns true on success.
  Future<bool> unlockWithBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canCheck) return false;
      final ok = await _localAuth.authenticate(
        localizedReason: 'افتح مذكرتي',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (ok) state = state.copyWith(isUnlocked: true);
      return ok;
    } catch (e) {
      debugPrint('Biometric unlock failed: $e');
      return false;
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      return (await _localAuth.canCheckBiometrics) ||
          (await _localAuth.isDeviceSupported());
    } catch (_) {
      return false;
    }
  }

  /// Re-lock (e.g. when app is backgrounded or on leaving the journal).
  void lock() {
    if (state.isEnabled) state = state.copyWith(isUnlocked: false);
  }
}

final journalLockProvider =
    StateNotifierProvider<JournalLockNotifier, JournalLockState>((ref) {
  return JournalLockNotifier();
});
