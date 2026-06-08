import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

/// Represents the level of access a user has to a specific therapist chat.
///
/// Maps directly to the `user_access` field on
/// `therapist_chats/{therapistId}_{userId}` (written by the backend):
///   'full'      → [TherapistChatAccess.full]      — read + send
///   'read_only' → [TherapistChatAccess.readOnly]  — read history only
///   absent/null → [TherapistChatAccess.none]       — no access
enum TherapistChatAccess { none, readOnly, full }

/// Pure mapping function — kept separate so it is trivially unit-testable
/// without any Firebase/Riverpod setup.
TherapistChatAccess therapistChatAccessFromFlag(String? userAccess) {
  switch (userAccess) {
    case 'full':
      return TherapistChatAccess.full;
    case 'read_only':
      return TherapistChatAccess.readOnly;
    default:
      return TherapistChatAccess.none;
  }
}

/// Streams the [TherapistChatAccess] for the current user against a specific
/// therapist, keyed by [therapistId].
///
/// Chat document ID follows the canonical format `{therapistId}_{userId}`.
/// If the current user is unauthenticated, the stream immediately emits
/// [TherapistChatAccess.none] and completes no further work.
final therapistChatAccessProvider =
    StreamProvider.family<TherapistChatAccess, String>((ref, therapistId) {
  final auth = ref.watch(authProvider);
  final uid = auth.user?.uid;

  if (uid == null) {
    return Stream.value(TherapistChatAccess.none);
  }

  final chatId = '${therapistId}_$uid';

  return FirebaseFirestore.instance
      .collection('therapist_chats')
      .doc(chatId)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return TherapistChatAccess.none;
    final data = snap.data();
    final flag = data?['user_access'] as String?;
    return therapistChatAccessFromFlag(flag);
  });
});
