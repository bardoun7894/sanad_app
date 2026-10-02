import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const aiPrivacyConsentVersion = '2026-10-01';

class AiConsentRequiredException implements Exception {
  const AiConsentRequiredException();
}

bool isAiConsentRequiredError(Object error) =>
    error is AiConsentRequiredException ||
    (error is FirebaseFunctionsException &&
        error.code == 'permission-denied' &&
        error.details is Map &&
        (error.details as Map)['reason'] == 'ai-consent-required');

final aiPrivacyConsentServiceProvider = Provider<AiPrivacyConsentService>((
  ref,
) {
  return AiPrivacyConsentService();
});

/// No local acceptance cache: every transfer checks the server account record.
class AiPrivacyConsentService {
  final String? Function() _currentUserId;
  final Future<Map<String, dynamic>?> Function(String) _readConsent;
  final Future<Map<String, dynamic>> Function(bool, String) _saveConsent;

  AiPrivacyConsentService({
    String? Function()? currentUserId,
    Future<Map<String, dynamic>?> Function(String)? readConsent,
    Future<Map<String, dynamic>> Function(bool, String)? saveConsent,
  }) : _currentUserId = currentUserId ?? _signedInUserId,
       _readConsent = readConsent ?? _readServerConsent,
       _saveConsent = saveConsent ?? _saveServerConsent;

  static String? _signedInUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  static Future<Map<String, dynamic>?> _readServerConsent(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get(const GetOptions(source: Source.server));
    final value = doc.data()?['ai_privacy_consent'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static Future<Map<String, dynamic>> _saveServerConsent(
    bool accepted,
    String expectedUserId,
  ) async {
    final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('setAiPrivacyConsent')
        .call({
          'accepted': accepted,
          'version': aiPrivacyConsentVersion,
          'expectedUserId': expectedUserId,
        });
    return Map<String, dynamic>.from(result.data as Map);
  }

  static bool _isAccepted(Map<String, dynamic>? value) =>
      value?['accepted'] == true &&
      value?['version'] == aiPrivacyConsentVersion;

  Future<bool> hasConsent() async {
    final uid = _currentUserId();
    if (uid == null) return false;
    final value = await _readConsent(uid);
    return _currentUserId() == uid && _isAccepted(value);
  }

  Future<bool> ensureConsent({
    required Future<bool?> Function() prompt,
    void Function(Object)? onError,
  }) async {
    final uid = _currentUserId();
    if (uid == null) return false;
    try {
      final value = await _readConsent(uid);
      if (_currentUserId() != uid) return false;
      if (_isAccepted(value)) return true;
      final answer = await prompt();
      if (_currentUserId() != uid || answer == null) return false;
      final saved = await _saveConsent(answer, uid);
      return _currentUserId() == uid && answer && _isAccepted(saved);
    } catch (error) {
      onError?.call(error);
      return false;
    }
  }

  /// Returns the persisted acceptance state, including false after revocation.
  Future<bool> setConsent(bool accepted) async {
    final uid = _currentUserId();
    if (uid == null) throw const AiConsentRequiredException();
    final saved = await _saveConsent(accepted, uid);
    if (_currentUserId() != uid ||
        saved['accepted'] != accepted ||
        saved['version'] != aiPrivacyConsentVersion) {
      throw const AiConsentRequiredException();
    }
    return accepted;
  }

  Future<void> requireConsent({
    required String userId,
    Set<String> subjectUserIds = const {},
  }) async {
    if (_currentUserId() != userId) throw const AiConsentRequiredException();
    try {
      for (final uid in {userId, ...subjectUserIds}) {
        if (!_isAccepted(await _readConsent(uid))) {
          throw const AiConsentRequiredException();
        }
      }
    } catch (_) {
      throw const AiConsentRequiredException();
    }
    if (_currentUserId() != userId) throw const AiConsentRequiredException();
  }
}
