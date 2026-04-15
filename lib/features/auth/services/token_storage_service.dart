import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';

/// Service for persisting authentication data using Hive
class TokenStorageService {
  static const String _userBoxName = 'auth_user_box';
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _pendingRegistrationKey = 'pending_registration';

  late Box _box;

  /// Initialize the storage service
  /// Should be called before the app starts
  Future<void> initialize() async {
    _box = await Hive.openBox(_userBoxName);
  }

  /// Save user to local storage
  Future<void> saveUser(AuthUser user) async {
    await _box.put(_userKey, user.toJson());
    await _box.put(_isLoggedInKey, true);
  }

  /// Set logged in status
  Future<void> setLoggedIn(bool value) async {
    await _box.put(_isLoggedInKey, value);
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _box.get(_isLoggedInKey, defaultValue: false) as bool;
  }

  /// Get stored user from local storage
  Future<AuthUser?> getStoredUser() async {
    try {
      final json = _box.get(_userKey);
      if (json == null) return null;
      return AuthUser.fromJson(Map<String, dynamic>.from(json));
    } catch (e, st) {
      // Log error but don't throw - graceful degradation
      debugPrint('Error retrieving stored user: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  /// Save authentication token to local storage
  Future<void> saveToken(String token) async {
    await _box.put(_tokenKey, token);
  }

  /// Get saved authentication token
  Future<String?> getToken() async {
    try {
      return _box.get(_tokenKey) as String?;
    } catch (e, st) {
      debugPrint('Error retrieving token: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }

  /// Clear user and token from storage
  Future<void> clearUser() async {
    await _box.delete(_userKey);
    await _box.delete(_tokenKey);
    await _box.put(_isLoggedInKey, false);
  }

  /// Clear all authentication data
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Check if user is stored locally
  bool hasStoredUser() {
    return _box.containsKey(_userKey);
  }

  /// Save pending registration data (for phone auth signup)
  Future<void> savePendingRegistration({
    required String phoneNumber,
    required String firstName,
    required String lastName,
  }) async {
    await _box.put(_pendingRegistrationKey, {
      'phone': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
    });
  }

  /// Get pending registration data
  Map<String, String>? getPendingRegistration() {
    final data = _box.get(_pendingRegistrationKey);
    if (data == null) return null;
    return Map<String, String>.from(data);
  }

  /// Clear pending registration data
  Future<void> clearPendingRegistration() async {
    await _box.delete(_pendingRegistrationKey);
  }

  /// Close the storage service (for cleanup)
  Future<void> close() async {
    await _box.close();
  }
}
