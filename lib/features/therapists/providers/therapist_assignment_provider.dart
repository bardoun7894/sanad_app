import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/models/activity_log.dart';
import '../../therapist_chat/models/therapist_chat.dart';
import '../../therapist_chat/services/therapist_chat_service.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/app_strings_en.dart';
import '../../../core/l10n/app_strings_fr.dart';

// ============= Result types =============

sealed class AssignmentResult {
  const AssignmentResult();
}

class AssignmentSuccess extends AssignmentResult {
  const AssignmentSuccess();
}

class AssignmentValidationError extends AssignmentResult {
  final String reason;
  const AssignmentValidationError({required this.reason});
}

class AssignmentPartialSuccess extends AssignmentResult {
  final bool chatWriteFailed;
  const AssignmentPartialSuccess({required this.chatWriteFailed});
}

// ============= Notifier =============

class TherapistAssignmentNotifier extends StateNotifier<void> {
  final FirebaseFirestore _firestore;
  final TherapistChatService _chatService;

  TherapistAssignmentNotifier({
    FirebaseFirestore? firestore,
    TherapistChatService? chatService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _chatService = chatService ?? TherapistChatService(),
        super(null);

  /// Assign a therapist to a user.
  ///
  /// [triggeredBy] must be 'admin' or 'user' to identify the actor in
  /// activity logs and welcome-message metadata.
  Future<AssignmentResult> assignTherapist({
    required String userId,
    required String therapistId,
    required String therapistName,
    String? therapistPhotoUrl,
    required String actorUid,
    required String actorName,
    required String triggeredBy,
  }) async {
    try {
      // 1. Validate therapist — must exist and be approved.
      final therapistDoc =
          await _firestore.collection('therapists').doc(therapistId).get();
      if (!therapistDoc.exists) {
        return const AssignmentValidationError(reason: 'therapist_not_found');
      }
      final therapistData = therapistDoc.data() as Map<String, dynamic>;
      if (therapistData['approval_status'] != 'approved') {
        return const AssignmentValidationError(reason: 'therapist_not_approved');
      }

      // 2. Validate user — must exist.
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return const AssignmentValidationError(reason: 'user_not_found');
      }
      final userData = userDoc.data() as Map<String, dynamic>;

      // 3. Idempotency: if the user is already assigned to this therapist, no-op.
      final currentTherapistId =
          userData['assigned_therapist_id'] as String?;
      if (currentTherapistId == therapistId) {
        return const AssignmentSuccess();
      }

      final userName =
          userData['display_name'] as String? ??
          userData['name'] as String? ??
          '';
      final userPhotoUrl = userData['avatar_url'] as String?;

      // 4. Batch: update user doc + activity log entry.
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);

      batch.update(userRef, {
        'assigned_therapist_id': therapistId,
        'assigned_therapist_name': therapistName,
        'therapist_assigned_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': actorUid,
      });

      final activityRef = _firestore.collection('activity_logs').doc();
      batch.set(activityRef, {
        'type': ActivityType.userUpdated.name,
        'user_id': actorUid,
        'user_name': actorName,
        'description':
            'assigned therapist $therapistName to user $userId',
        'timestamp': FieldValue.serverTimestamp(),
        'actor_uid': actorUid,
        'metadata': {
          'target_user_id': userId,
          'therapist_id': therapistId,
          'therapist_name': therapistName,
          'old_therapist_id': currentTherapistId,
          'actor_uid': actorUid,
          'triggered_by': triggeredBy,
        },
      });

      await batch.commit();

      // 5. Chat operations (outside the batch; tolerable partial failure).
      String chatId;
      try {
        TherapistChatThread chatThread;
        if (currentTherapistId != null && currentTherapistId.isNotEmpty) {
          // Reassign: replace old chat with new one.
          chatThread = await _chatService.replaceChat(
            oldTherapistId: currentTherapistId,
            newTherapistId: therapistId,
            userId: userId,
            newTherapistName: therapistName,
            newTherapistPhotoUrl: therapistPhotoUrl ?? '',
            userName: userName,
            userPhotoUrl: userPhotoUrl,
            source: ChatSource.direct,
          );
        } else {
          // Fresh assign: get or create chat.
          chatThread = await _chatService.getOrCreateChat(
            therapistId: therapistId,
            userId: userId,
            therapistName: therapistName,
            userName: userName,
            therapistPhotoUrl: therapistPhotoUrl,
            userPhotoUrl: userPhotoUrl,
            source: ChatSource.direct,
          );
        }
        chatId = chatThread.chatId;
      } catch (e) {
        debugPrint('[TherapistAssignment] chat write failed: $e');
        return const AssignmentPartialSuccess(chatWriteFailed: true);
      }

      // 6. Idempotency-guarded welcome message.
      try {
        final hasMessages = await _chatService.chatHasMessages(chatId);
        if (!hasMessages) {
          final locale =
              userData['locale'] as String? ?? 'ar';
          final welcomeText = _buildWelcomeText(
            locale: locale,
            userName: userName,
            therapistName: therapistName,
          );
          await _chatService.sendWelcomeMessage(
            chatId: chatId,
            therapistId: therapistId,
            therapistName: therapistName,
            content: welcomeText,
            triggeredBy: triggeredBy,
          );
        }
      } catch (e) {
        debugPrint('[TherapistAssignment] welcome message failed: $e');
        // Non-fatal: chat exists but no welcome. Better than blocking the assignment.
      }

      return const AssignmentSuccess();
    } catch (e) {
      debugPrint('[TherapistAssignment] assignTherapist unexpected: $e');
      return AssignmentValidationError(reason: e.toString());
    }
  }

  /// Remove the therapist assignment from a user.
  ///
  /// [triggeredBy] must be 'admin' or 'user'.
  Future<AssignmentResult> unassignTherapist({
    required String userId,
    required String actorUid,
    required String actorName,
    required String triggeredBy,
  }) async {
    try {
      // 1. Read user; if no assigned therapist → no-op.
      final userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return const AssignmentValidationError(reason: 'user_not_found');
      }
      final userData = userDoc.data() as Map<String, dynamic>;
      final currentTherapistId =
          userData['assigned_therapist_id'] as String?;
      if (currentTherapistId == null || currentTherapistId.isEmpty) {
        return const AssignmentSuccess();
      }

      // 2. Batch: clear assignment fields + activity log.
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);

      batch.update(userRef, {
        'assigned_therapist_id': FieldValue.delete(),
        'assigned_therapist_name': FieldValue.delete(),
        'therapist_assigned_at': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': actorUid,
      });

      final activityRef = _firestore.collection('activity_logs').doc();
      batch.set(activityRef, {
        'type': ActivityType.userUpdated.name,
        'user_id': actorUid,
        'user_name': actorName,
        'description': 'removed therapist assignment for user $userId',
        'timestamp': FieldValue.serverTimestamp(),
        'actor_uid': actorUid,
        'metadata': {
          'target_user_id': userId,
          'old_therapist_id': currentTherapistId,
          'actor_uid': actorUid,
          'triggered_by': triggeredBy,
        },
      });

      await batch.commit();

      // 3. Archive old chat (outside batch; tolerable partial failure).
      try {
        final chatId = TherapistChatThread.generateChatId(
          currentTherapistId,
          userId,
        );
        await _chatService.archiveChat(chatId);
      } catch (e) {
        debugPrint('[TherapistAssignment] archiveChat failed: $e');
        return const AssignmentPartialSuccess(chatWriteFailed: true);
      }

      return const AssignmentSuccess();
    } catch (e) {
      debugPrint('[TherapistAssignment] unassignTherapist unexpected: $e');
      return AssignmentValidationError(reason: e.toString());
    }
  }

  // ============= Private helpers =============

  /// Build the welcome text for the given locale, substituting
  /// {userName} and {therapistName} placeholders.
  String _buildWelcomeText({
    required String locale,
    required String userName,
    required String therapistName,
  }) {
    final template = _welcomeTemplateForLocale(locale);
    return template
        .replaceAll('{userName}', userName)
        .replaceAll('{therapistName}', therapistName);
  }

  String _welcomeTemplateForLocale(String locale) {
    switch (locale) {
      case 'en':
        return AppStringsEn.therapistAssignmentWelcomeTemplate;
      case 'fr':
        return AppStringsFr.therapistAssignmentWelcomeTemplate;
      default:
        return AppStrings.therapistAssignmentWelcomeTemplate;
    }
  }
}

// ============= Result helpers =============

/// Maps an [AssignmentResult] to a bool for callers that only care about
/// success/failure (e.g. AdminUsersNotifier pass-throughs).
bool assignmentResultToBool(AssignmentResult result) {
  return switch (result) {
    AssignmentSuccess() => true,
    AssignmentPartialSuccess() => true,
    AssignmentValidationError() => false,
  };
}

// ============= Provider =============

final therapistAssignmentProvider =
    StateNotifierProvider<TherapistAssignmentNotifier, void>((ref) {
  return TherapistAssignmentNotifier();
});
