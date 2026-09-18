import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  /// Notification channel identity. Zego requires channelID, channelName and
  /// sound to match the values configured in the ZEGOCLOUD console *exactly*,
  /// so these are constants — never localized. A translated channel name makes
  /// offline pushes silently fail for whichever language doesn't match.
  static const String _channelId = 'ZegoUIKit';
  static const String _channelName = 'Call Notifications';
  static const String _channelSound = 'call';

  bool _initialized = false;
  String? _currentUserId;
  void Function(String callID)? _onCallCompleted;

  /// True only when the SDK reports a live invitation session. This is the
  /// signal that decides whether this device can *receive* a call — a device
  /// that never got here is invisible to callers even with the app open.
  bool get isRegistered =>
      _initialized && ZegoUIKitPrebuiltCallInvitationService().isInit;

  /// Initialize Zego call invitation service for the current user.
  /// Call this after successful login. Returns whether the device ended up
  /// registered and therefore reachable.
  Future<bool> init({
    required String userId,
    required String userName,
    void Function(String callID)? onCallCompleted,
  }) async {
    _onCallCompleted = onCallCompleted;

    // The Zego call SDK reaches for dart:io Platform internally, which throws
    // "Unsupported operation: Platform._operatingSystem" on Flutter web and
    // burns all 3 retry attempts with a red stack trace each time. The admin
    // dashboard is the only web build and it never places or receives calls,
    // so skip registration outright instead of failing loudly.
    if (kIsWeb) {
      debugPrint('ZegoCallService: skipped on web (calls are mobile-only)');
      return false;
    }

    // Re-initializing for the same user tears down a working session and
    // leaves a window where the device is unreachable. Auth state can emit
    // more than once per launch, so only rebuild when the user changed.
    if (_initialized && _currentUserId == userId && isRegistered) {
      debugPrint('ZegoCallService: Already registered for $userId, keeping it');
      return true;
    }
    if (_initialized) {
      await uninit();
    }

    final appId = AppConfig.zegoAppId;
    final appSign = AppConfig.zegoAppSign;

    if (appId == 0 || appSign.isEmpty) {
      debugPrint(
        'ZegoCallService: MISCONFIGURED — appId=$appId appSign=${appSign.isEmpty ? "empty" : "set"}. '
        'This device cannot send or receive calls.',
      );
      await _recordRegistration(userId, false, reason: 'not_configured');
      return false;
    }

    // Transient network failures at login would otherwise leave the user
    // unreachable for the whole session with nothing to retry.
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
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
              // The whole point of a call notification: reach someone whose
              // phone is locked and in their pocket.
              showOnLockedScreen: true,
              showOnFullScreen: true,
              callChannel: ZegoCallAndroidNotificationChannelConfig(
                channelID: _channelId,
                channelName: _channelName,
                sound: _channelSound,
                icon: 'notification_icon',
              ),
              missedCallChannel: ZegoCallAndroidNotificationChannelConfig(
                channelID: '${_channelId}_missed',
                channelName: 'Missed Calls',
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
            onError: (error) =>
                debugPrint('ZegoCallService: SDK error: $error'),
            onOutgoingCallSent: _onOutgoingCallSent,
            onOutgoingCallAccepted: _onOutgoingCallAccepted,
            onOutgoingCallDeclined: _onOutgoingCallDeclined,
            onOutgoingCallRejectedCauseBusy: _onOutgoingCallRejectedCauseBusy,
            onOutgoingCallTimeout: _onOutgoingCallTimeout,
            onOutgoingCallCancelButtonPressed: _onOutgoingCallCancelled,
            onIncomingCallReceived: _onIncomingCallReceived,
            onIncomingCallTimeout: _onIncomingCallTimeout,
          ),
        );

        // init() returns void and swallows signaling-login failures, so ask
        // the SDK directly rather than assuming success.
        if (ZegoUIKitPrebuiltCallInvitationService().isInit) {
          _initialized = true;
          _currentUserId = userId;
          debugPrint('ZegoCallService: Registered $userId (attempt $attempt)');
          await _recordRegistration(userId, true);
          return true;
        }

        debugPrint(
          'ZegoCallService: init() returned but SDK reports not initialized '
          '(attempt $attempt/$maxAttempts)',
        );
      } catch (e, st) {
        debugPrint('ZegoCallService: Init attempt $attempt failed: $e');
        debugPrintStack(stackTrace: st);
      }

      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    debugPrint(
      'ZegoCallService: FAILED to register $userId after $maxAttempts attempts — '
      'this device will not receive calls.',
    );
    await _recordRegistration(userId, false, reason: 'init_failed');
    return false;
  }

  /// Uninitialize Zego call invitation service.
  /// Call this on logout.
  Future<void> uninit() async {
    if (!_initialized) return;

    final userId = _currentUserId;
    try {
      ZegoUIKitPrebuiltCallInvitationService().uninit();
      _initialized = false;
      _currentUserId = null;
      debugPrint('ZegoCallService: Uninitialized');
    } catch (e, st) {
      debugPrint('ZegoCallService: Uninit failed: $e');
      debugPrintStack(stackTrace: st);
    }
    if (userId != null) {
      await _recordRegistration(userId, false, reason: 'signed_out');
    }
  }

  /// Publish whether this device is reachable for calls to `users/{uid}`.
  ///
  /// Callers read it before dialling so an unreachable callee produces a real
  /// message instead of a "calling…" screen that rings forever, and it is the
  /// only way to tell from the outside whether a device ever registered.
  Future<void> _recordRegistration(
    String userId,
    bool registered, {
    String? reason,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'zego_registered': registered,
        'zego_registered_at': FieldValue.serverTimestamp(),
        'zego_registration_error': reason ?? FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ZegoCallService: Failed to record registration state: $e');
    }
  }

  /// Send a call invitation to a target user.
  /// Zego handles the full flow: ringing UI, accept/decline, call screen.
  ///
  /// Returns a record with [ok] and an optional [error] reason so callers
  /// can surface a useful message instead of a generic "Failed".
  Future<({bool ok, String? error, String? warning})> sendCallInvitation({
    required String targetUserId,
    required String targetUserName,
    bool isVideoCall = false,
    String? callID,
    int timeoutSeconds = 60,
    String? callerUserId,
    String? callerName,
    String? chatId,
  }) async {
    if (!isRegistered) {
      const msg =
          'Call service not ready. Sign out and back in, then try again.';
      debugPrint('ZegoCallService: Not registered, cannot send invitation');
      return (ok: false, error: msg, warning: null);
    }
    if (targetUserId.isEmpty) {
      return (ok: false, error: 'Target user is missing.', warning: null);
    }

    // Zego accepts an invitation addressed to any string and reports success
    // even when nobody is listening on the other end — which is exactly how a
    // call ends up ringing forever with no device to ring. We can't tell the
    // caller *for certain*, but we can warn them instead of leaving them to
    // guess why nobody picks up.
    final warning = await _calleeReachabilityWarning(targetUserId);
    if (warning != null) {
      debugPrint('ZegoCallService: $targetUserId may be unreachable — $warning');
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
      if (result == true) return (ok: true, error: null, warning: warning);
      return (
        ok: false,
        error:
            'Invitation rejected by the call service. The other user may not be registered or reachable yet.',
        warning: warning,
      );
    } catch (e, st) {
      debugPrint('ZegoCallService: Send failed: $e');
      debugPrintStack(stackTrace: st);
      return (ok: false, error: e.toString(), warning: null);
    }
  }

  /// A warning to show the caller when [targetUserId] looks unreachable, or
  /// null when nothing is known against them.
  ///
  /// Advisory only — it never stops the call. `zego_registered` is written by
  /// the callee's device, so it is stale by construction: `uninit()` runs on
  /// explicit sign-out but not when the app is killed or crashes, and every
  /// device on an older build has never written it at all. Treating a `false`
  /// as authoritative would permanently block calls to users who are in fact
  /// reachable, which is strictly worse than a call that rings unanswered.
  Future<String?> _calleeReachabilityWarning(String targetUserId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) {
        return 'This account no longer exists.';
      }
      // Absent means "unknown" (older build), not "unreachable".
      if (doc.data()?['zego_registered'] == false) {
        return 'This user may not be signed in, so their phone might not '
            'ring. Calling anyway.';
      }
      return null;
    } catch (e) {
      debugPrint('ZegoCallService: Reachability check failed: $e');
      return null;
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

  void _onOutgoingCallSent(
    String callID,
    ZegoCallUser caller,
    ZegoCallInvitationType callType,
    List<ZegoCallUser> callees,
    String customData,
  ) {
    debugPrint('ZegoCallService: Invitation $callID sent to '
        '${callees.map((c) => c.id).join(",")}');
    _updateCallStatus(callID, 'ringing');
  }

  /// The callee's device actually rendered the incoming call. Recording it is
  /// what separates "never delivered" from "delivered but not answered" —
  /// without it every unanswered call looks identical in `call_invites`.
  void _onIncomingCallReceived(
    String callID,
    ZegoCallUser caller,
    ZegoCallInvitationType callType,
    List<ZegoCallUser> callees,
    String customData,
  ) {
    debugPrint('ZegoCallService: Incoming call $callID from ${caller.id}');
    _updateCallStatus(callID, 'delivered');
  }

  void _onOutgoingCallCancelled() {
    debugPrint('ZegoCallService: Caller cancelled the outgoing call');
  }

  void _onOutgoingCallRejectedCauseBusy(
    String callID,
    ZegoCallUser callee,
    String customData,
  ) {
    debugPrint('ZegoCallService: ${callee.id} is busy');
    _updateCallStatus(callID, 'busy');
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

  /// How far along a call got. A status may only move forward, so a late
  /// callback (e.g. the caller's timeout firing after the callee answered)
  /// can't rewrite history.
  static const _statusRank = <String, int>{
    'ringing': 0,
    'delivered': 1,
    'missed': 2,
    'busy': 2,
    'declined': 2,
    'accepted': 3,
    'ended': 4,
  };

  /// Update call status in Firestore for history tracking.
  Future<void> _updateCallStatus(String callID, String status) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('call_invites')
          .doc(callID);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final current = doc.data()?['status'] as String? ?? 'ringing';
      final currentRank = _statusRank[current] ?? 0;
      final nextRank = _statusRank[status] ?? 0;
      if (nextRank <= currentRank) {
        debugPrint(
          'ZegoCallService: Ignoring $current -> $status for $callID',
        );
        return;
      }

      await docRef.update({
        'status': status,
        if (status == 'delivered') 'delivered_at': FieldValue.serverTimestamp(),
        if (status == 'accepted') 'answered_at': FieldValue.serverTimestamp(),
        if (status == 'declined' ||
            status == 'missed' ||
            status == 'busy' ||
            status == 'ended')
          'ended_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ZegoCallService: Failed to update call status: $e');
    }
  }
}
