import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'app_config.dart';

/// Centralized service for Zego Call Invitation system.
///
/// Handles:
/// - Initialization on login / uninit on logout
/// - Programmatic call sending
/// - Event callbacks that write to Firestore `call_invites` for history tracking
class ZegoCallService {
  ZegoCallService._();
  static final ZegoCallService instance = ZegoCallService._();

  bool _initialized = false;
  void Function(String callID)? _onCallCompleted;

  /// Initialize Zego call invitation service for the current user.
  /// Call this after successful login.
  Future<void> init({
    required String userId,
    required String userName,
    String callNotificationsChannelName = 'Call Notifications',
    void Function(String callID)? onCallCompleted,
  }) async {
    _onCallCompleted = onCallCompleted;
    if (_initialized) {
      debugPrint('ZegoCallService: Already initialized, uninit first');
      await uninit();
    }

    final appId = AppConfig.zegoAppId;
    final appSign = AppConfig.zegoAppSign;

    if (appId == 0 || appSign.isEmpty) {
      debugPrint('ZegoCallService: Zego not configured, skipping init');
      return;
    }

    try {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: appId,
        appSign: appSign,
        userID: userId,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
        config: ZegoCallInvitationConfig(
          missedCall: ZegoCallInvitationMissedCallConfig(
            enabled: true,
            enableDialBack: true,
          ),
        ),
        notificationConfig: ZegoCallInvitationNotificationConfig(
          androidNotificationConfig: ZegoCallAndroidNotificationConfig(
            callChannel: ZegoCallAndroidNotificationChannelConfig(
              channelID: 'ZegoUIKit',
              channelName: callNotificationsChannelName,
              sound: 'call',
              icon: 'notification_icon',
            ),
          ),
          iOSNotificationConfig: ZegoCallIOSNotificationConfig(
            isSandboxEnvironment: kDebugMode,
            systemCallingIconName: 'AppIcon',
          ),
        ),
        requireConfig: (ZegoCallInvitationData data) {
          final config = ZegoCallInvitationType.videoCall == data.type
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
          config.duration.isVisible = true;
          return config;
        },
        events: ZegoUIKitPrebuiltCallEvents(onCallEnd: _onCallEnd),
        invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
          onOutgoingCallAccepted: _onOutgoingCallAccepted,
          onOutgoingCallDeclined: _onOutgoingCallDeclined,
          onOutgoingCallTimeout: _onOutgoingCallTimeout,
          onIncomingCallTimeout: _onIncomingCallTimeout,
        ),
      );

      _initialized = true;
      debugPrint('ZegoCallService: Initialized for user $userId');
    } catch (e, st) {
      debugPrint('ZegoCallService: Init failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Uninitialize Zego call invitation service.
  /// Call this on logout.
  Future<void> uninit() async {
    if (!_initialized) return;

    try {
      ZegoUIKitPrebuiltCallInvitationService().uninit();
      _initialized = false;
      debugPrint('ZegoCallService: Uninitialized');
    } catch (e, st) {
      debugPrint('ZegoCallService: Uninit failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Send a call invitation to a target user.
  /// Zego handles the full flow: ringing UI, accept/decline, call screen.
  Future<bool> sendCallInvitation({
    required String targetUserId,
    required String targetUserName,
    bool isVideoCall = false,
    String? callID,
    int timeoutSeconds = 60,
    String? callerUserId,
    String? callerName,
    String? chatId,
  }) async {
    if (!_initialized) {
      debugPrint('ZegoCallService: Not initialized, cannot send invitation');
      return false;
    }

    try {
      // Write to call_invites for history tracking BEFORE sending
      final effectiveCallId =
          callID ?? _generateCallId(callerUserId ?? '', targetUserId);
      if (callerUserId != null && callerName != null) {
        _writeCallInviteToFirestore(
          callId: effectiveCallId,
          callerId: callerUserId,
          callerName: callerName,
          calleeId: targetUserId,
          calleeName: targetUserName,
          chatId: chatId ?? '',
        );
      }

      final result = await ZegoUIKitPrebuiltCallInvitationService().send(
        invitees: [ZegoCallUser(targetUserId, targetUserName)],
        isVideoCall: isVideoCall,
        resourceID: 'zegouikit_call',
        timeoutSeconds: timeoutSeconds,
        callID: effectiveCallId,
      );

      debugPrint('ZegoCallService: Send result: $result');
      return result;
    } catch (e, st) {
      debugPrint('ZegoCallService: Send failed: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  /// Generate a consistent call ID from two user IDs.
  String _generateCallId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'call_${sortedIds[0].hashCode.abs()}_${sortedIds[1].hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ---------------------------------------------------------------------------
  // Event callbacks — write to Firestore `call_invites` for history tracking
  // ---------------------------------------------------------------------------

  void _onCallEnd(ZegoCallEndEvent event, VoidCallback defaultAction) {
    debugPrint('ZegoCallService: Call ended, reason: ${event.reason}');
    defaultAction();

    if (event.reason == ZegoCallEndReason.remoteHangUp ||
        event.reason == ZegoCallEndReason.localHangUp) {
      _autoCompleteBooking(event.callID);
      _onCallCompleted?.call(event.callID);
    }
  }

  Future<void> _autoCompleteBooking(String callID) async {
    try {
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(callID);
      final doc = await bookingRef.get();

      if (doc.exists) {
        final data = doc.data();
        final status = data?['status'] as String?;
        if (status == 'confirmed') {
          // Calculate duration from call_invites
          int? durationSeconds;
          try {
            final callDoc = await FirebaseFirestore.instance
                .collection('call_invites')
                .doc(callID)
                .get();
            if (callDoc.exists) {
              final callData = callDoc.data();
              final answeredAt = callData?['answered_at'] as Timestamp?;
              if (answeredAt != null) {
                durationSeconds = DateTime.now()
                    .difference(answeredAt.toDate())
                    .inSeconds;
              }
            }
          } catch (e) {
            debugPrint('ZegoCallService: Failed to get call duration: $e');
          }

          await bookingRef.update({
            'status': 'completed',
            'completed_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
            if (durationSeconds != null)
              'actual_duration_seconds': durationSeconds,
          });
          debugPrint('ZegoCallService: Auto-completed booking $callID');
        }
      }
    } catch (e) {
      debugPrint('ZegoCallService: Failed to auto-complete booking: $e');
    }
  }

  void _onOutgoingCallAccepted(String callID, ZegoCallUser callee) {
    debugPrint('ZegoCallService: Outgoing call accepted by ${callee.id}');
    _updateCallStatus(callID, 'accepted');
  }

  void _onOutgoingCallDeclined(
    String callID,
    ZegoCallUser callee,
    String customData,
  ) {
    debugPrint('ZegoCallService: Outgoing call declined by ${callee.id}');
    _updateCallStatus(callID, 'declined');
  }

  void _onOutgoingCallTimeout(
    String callID,
    List<ZegoCallUser> callees,
    bool isVideoCall,
  ) {
    debugPrint('ZegoCallService: Outgoing call timeout');
    _updateCallStatus(callID, 'missed');
  }

  void _onIncomingCallTimeout(String callID, ZegoCallUser caller) {
    debugPrint('ZegoCallService: Incoming call timeout from ${caller.id}');
    _updateCallStatus(callID, 'missed');
  }

  /// Write initial call invite to Firestore for history tracking.
  Future<void> _writeCallInviteToFirestore({
    required String callId,
    required String callerId,
    required String callerName,
    required String calleeId,
    required String calleeName,
    required String chatId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('call_invites')
          .doc(callId)
          .set({
            'call_id': callId,
            'chat_id': chatId,
            'caller_id': callerId,
            'caller_name': callerName,
            'callee_id': calleeId,
            'callee_name': calleeName,
            'status': 'ringing',
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
            'expires_at': Timestamp.fromDate(
              DateTime.now().add(const Duration(seconds: 60)),
            ),
          });
    } catch (e) {
      debugPrint('ZegoCallService: Failed to write call invite: $e');
    }
  }

  /// Update call status in Firestore for history tracking.
  Future<void> _updateCallStatus(String callID, String status) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('call_invites')
          .doc(callID);
      final doc = await docRef.get();

      if (doc.exists) {
        await docRef.update({
          'status': status,
          if (status == 'accepted') 'answered_at': FieldValue.serverTimestamp(),
          if (status == 'declined' || status == 'missed' || status == 'ended')
            'ended_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('ZegoCallService: Failed to update call status: $e');
    }
  }
}
