import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/journal_entry.dart';

/// LOCAL-ONLY, ENCRYPTED store for private journal entries.
///
/// Entries live in an AES-encrypted Hive box on the device. The 256-bit key is
/// generated once and kept in the OS secure storage (Keychain / Keystore).
/// Nothing here ever touches Firestore or the network — this is the privacy
/// boundary the client requires.
class JournalRepository {
  static const String _boxName = 'journal_entries';
  static const String _keyStorageKey = 'journal_hive_encryption_key';

  final FlutterSecureStorage _secureStorage;
  Box? _box;

  JournalRepository({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Box> _openBox() async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;

    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box(_boxName);
      return _box!;
    }

    final key = await _readOrCreateKey();
    _box = await Hive.openBox(
      _boxName,
      encryptionCipher: HiveAesCipher(key),
    );
    return _box!;
  }

  Future<List<int>> _readOrCreateKey() async {
    // Prefer the OS secure enclave; fall back to an app-private Hive box if the
    // secure-storage plugin is unavailable (keeps the journal box encrypted and
    // device-only rather than crashing).
    final existing = await _readKeyString();
    if (existing != null) return base64Url.decode(existing);

    final key = Hive.generateSecureKey();
    await _writeKeyString(base64Url.encode(key));
    return key;
  }

  Future<String?> _readKeyString() async {
    try {
      final v = await _secureStorage.read(key: _keyStorageKey);
      if (v != null) return v;
    } catch (_) {
      // Secure storage unavailable — fall through to local fallback.
    }
    try {
      final box = await Hive.openBox('journal_key_fallback');
      return box.get(_keyStorageKey) as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeKeyString(String value) async {
    try {
      await _secureStorage.write(key: _keyStorageKey, value: value);
      return;
    } catch (_) {
      // Secure storage unavailable — persist to app-private Hive instead.
    }
    final box = await Hive.openBox('journal_key_fallback');
    await box.put(_keyStorageKey, value);
  }

  /// All entries, newest first.
  Future<List<JournalEntry>> getAll() async {
    final box = await _openBox();
    final entries = <JournalEntry>[];
    for (final value in box.values) {
      try {
        final map = Map<String, dynamic>.from(value as Map);
        entries.add(JournalEntry.fromJson(map));
      } catch (e) {
        debugPrint('Skipping corrupt journal entry: $e');
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> save(JournalEntry entry) async {
    final box = await _openBox();
    await box.put(entry.id, entry.toJson());
  }

  Future<void> delete(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
