import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../notifications/services/notification_service.dart';

class CallInviteResult {
  final bool success;
  final String? error;

  const CallInviteResult._({required this.success, this.error});

  const CallInviteResult.success() : this._(success: true);
  const CallInviteResult.failure(String message)
    : this._(success: false, error: message);
}

class CallInvite {
  final String id;
  final String chatId;
  final String callId;
  final String callerId;
  final String callerName;
  final String calleeId;
  final String calleeName;

  final String status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int? callDurationSeconds;

  const CallInvite({
    required this.id,
    required this.chatId,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.calleeId,
    required this.calleeName,

    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.answeredAt,
    this.endedAt,
    this.callDurationSeconds,
  });

  bool get isRinging => status == 'ringing';

  factory CallInvite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CallInvite(
      id: doc.id,
      chatId: data['chat_id'] as String? ?? '',
      callId: data['call_id'] as String? ?? '',
      callerId: data['caller_id'] as String? ?? '',
      callerName: data['caller_name'] as String? ?? 'Caller',
      calleeId: data['callee_id'] as String? ?? '',
      calleeName: data['callee_name'] as String? ?? 'Recipient',

      status: data['status'] as String? ?? 'ringing',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expires_at'] as Timestamp?)?.toDate(),
      answeredAt: (data['answered_at'] as Timestamp?)?.toDate(),
      endedAt: (data['ended_at'] as Timestamp?)?.toDate(),
      callDurationSeconds: data['call_duration_seconds'] as int?,
    );
  }
}

class CallInviteService {
  static const Duration _ringTimeout = Duration(seconds: 45);
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  CallInviteService({
    FirebaseFirestore? firestore,
    required NotificationService notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService;

  CollectionReference get _invitesRef => _firestore.collection('call_invites');

  Future<String> createInvite({
    required String chatId,
    required String callId,
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
  }) async {
    try {
      final docRef = await _invitesRef.add({
        'chat_id': chatId,
        'call_id': callId,
        'caller_id': callerId,
        'caller_name': callerName,
        'callee_id': calleeId,
        'callee_name': calleeName,

        'status': 'ringing',
        'created_at': FieldValue.serverTimestamp(),
        'expires_at': Timestamp.fromDate(DateTime.now().add(_ringTimeout)),
        'updated_at': FieldValue.serverTimestamp(),
      });


      // Create a notification for the callee so they see it in notifications
      // Fire-and-forget: don't block invite creation
      try {
        _notificationService.createCallNotification(
          userId: calleeId,
          title: 'Incoming Call',
          body: '$callerName is calling you',
          chatId: chatId,
          callerName: callerName,
          inviteId: docRef.id,
        );
      } catch (e) {
        debugPrint('CallInvite: Failed to create call notification: $e');
      }

      return docRef.id;
    } catch (e, st) {
      debugPrint('CallInvite create failed: $e');
      debugPrintStack(stackTrace: st);
      throw Exception('Failed to create call invite');
    }
  }

  bool _isExpired(CallInvite invite) {
    if (invite.expiresAt != null) {
      return DateTime.now().isAfter(invite.expiresAt!);
    }
    return DateTime.now().difference(invite.createdAt) > _ringTimeout;
  }

  /// Ends an active call: computes duration and updates Firestore.
  /// If the call was still ringing (caller hung up early), marks as cancelled.
  Future<CallInviteResult> endCall(String inviteId) async {
    try {
      final doc = await _invitesRef.doc(inviteId).get();
      if (!doc.exists) {
        return const CallInviteResult.failure('Invite not found');
      }

      final invite = CallInvite.fromFirestore(doc);

      // Caller hung up before callee answered
      if (invite.status == 'ringing') {
        return _updateInviteStatus(inviteId, 'cancelled', ended: true);
      }

      // Compute duration from answered_at to now
      final now = DateTime.now();
      int? durationSeconds;
      if (invite.answeredAt != null) {
        durationSeconds = now.difference(invite.answeredAt!).inSeconds;
      }

      await _invitesRef.doc(inviteId).update({
        'status': 'ended',
        'ended_at': FieldValue.serverTimestamp(),
        if (durationSeconds != null) 'call_duration_seconds': durationSeconds,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return const CallInviteResult.success();
    } catch (e, st) {
      debugPrint('CallInvite endCall failed: $e');
      debugPrintStack(stackTrace: st);
      return const CallInviteResult.failure('Failed to end call');
    }
  }

  Stream<CallInvite?> watchLatestIncoming(String userId) {
    return _invitesRef
        .where('callee_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(5)
        .snapshots()
        .asyncMap((snapshot) async {
          for (final doc in snapshot.docs) {
            final invite = CallInvite.fromFirestore(doc);
            if (invite.isRinging && _isExpired(invite)) {
              try {
                await markMissed(invite.id);
                // Notify callee: missed call
                _notificationService.createCallNotification(
                  userId: invite.calleeId,
                  title: 'Missed Call',
                  body: 'You missed a call from ${invite.callerName}',
                  chatId: invite.chatId,
                  callerName: invite.callerName,
                  inviteId: invite.id,
                );
                // Notify caller: no answer
                _notificationService.createCallNotification(
                  userId: invite.callerId,
                  title: 'No Answer',
                  body: '${invite.calleeName} did not answer your call',
                  chatId: invite.chatId,
                  callerName: invite.callerName,
                  inviteId: invite.id,
                );
              } catch (e, st) {
                debugPrint('CallInvite markMissed in stream failed: $e');
                debugPrintStack(stackTrace: st);
              }
              continue;
            }
            if (invite.isRinging) {
              return invite;
            }
          }
          return null;
        });
  }

  Future<CallInviteResult> acceptInvite(String inviteId) async {
    return _updateInviteStatus(inviteId, 'accepted', answered: true);
  }

  Future<CallInviteResult> declineInvite(String inviteId) async {
    return _updateInviteStatus(inviteId, 'declined', ended: true);
  }

  Future<CallInviteResult> markMissed(String inviteId) async {
    return _updateInviteStatus(inviteId, 'missed', ended: true);
  }

  Future<CallInviteResult> _updateInviteStatus(
    String inviteId,
    String status, {
    bool answered = false,
    bool ended = false,
  }) async {
    try {
      await _invitesRef.doc(inviteId).update({
        'status': status,
        if (answered) 'answered_at': FieldValue.serverTimestamp(),
        if (ended) 'ended_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return const CallInviteResult.success();
    } catch (e, st) {
      debugPrint('CallInvite update status failed [$status]: $e');
      debugPrintStack(stackTrace: st);
      return const CallInviteResult.failure('Failed to update call status');
    }
  }
}

final callInviteServiceProvider = Provider<CallInviteService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return CallInviteService(notificationService: notificationService);
});

final incomingCallInviteProvider = StreamProvider.family<CallInvite?, String>((
  ref,
  userId,
) {
  final service = ref.watch(callInviteServiceProvider);
  return service.watchLatestIncoming(userId);
});
