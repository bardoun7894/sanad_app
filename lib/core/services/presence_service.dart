import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

/// Tracks the signed-in user's online state in Firestore so chat partners
/// can render a real "Online" / "Last seen X ago" badge instead of a
/// hardcoded one.
///
/// Writes:
///   users/{uid}.is_online: bool
///   users/{uid}.last_seen: Timestamp (server)
///
/// Strategy:
///   • App resumed → is_online=true + last_seen=now
///   • App paused/inactive/detached → is_online=false + last_seen=now
///   • Heartbeat every 45 s while resumed so a long open chat keeps
///     last_seen fresh enough that other clients consider the user online.
///
/// Firestore is not real-time disconnect-aware (no onDisconnect like RTDB),
/// so other clients read it as: online == is_online && last_seen within
/// kStaleAfter — see [PresenceX.isOnline].
class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  static const Duration _heartbeatInterval = Duration(seconds: 45);

  String? _uid;
  Timer? _heartbeat;
  bool _attached = false;

  /// Wire into the app lifecycle and start tracking [uid].
  /// Call once after sign-in.
  Future<void> start(String uid) async {
    if (_uid == uid && _attached) return;
    if (_attached) await stop();
    _uid = uid;
    WidgetsBinding.instance.addObserver(this);
    _attached = true;
    await _writeState(online: true);
    _scheduleHeartbeat();
  }

  /// Stop tracking and mark offline. Call on sign-out.
  Future<void> stop() async {
    _heartbeat?.cancel();
    _heartbeat = null;
    if (_attached) {
      WidgetsBinding.instance.removeObserver(this);
      _attached = false;
    }
    if (_uid != null) {
      await _writeState(online: false);
      _uid = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _writeState(online: true);
        _scheduleHeartbeat();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _heartbeat?.cancel();
        _writeState(online: false);
        break;
    }
  }

  void _scheduleHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) {
      _writeState(online: true);
    });
  }

  Future<void> _writeState({required bool online}) async {
    final uid = _uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'is_online': online,
        'last_seen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('PresenceService: write failed: $e');
    }
  }
}

/// Read-side helper. A user is considered online when [isOnlineFlag] is true
/// AND their last_seen heartbeat is within [staleAfter]. This guards against
/// a crash that left is_online=true on the doc.
class PresenceState {
  final bool isOnlineFlag;
  final DateTime? lastSeen;

  static const Duration staleAfter = Duration(minutes: 2);

  const PresenceState({required this.isOnlineFlag, required this.lastSeen});

  factory PresenceState.fromUserDoc(Map<String, dynamic>? data) {
    if (data == null) {
      return const PresenceState(isOnlineFlag: false, lastSeen: null);
    }
    final ts = data['last_seen'];
    DateTime? last;
    if (ts is Timestamp) last = ts.toDate();
    return PresenceState(
      isOnlineFlag: data['is_online'] == true,
      lastSeen: last,
    );
  }

  bool get isOnline {
    if (!isOnlineFlag) return false;
    final last = lastSeen;
    if (last == null) return false;
    return DateTime.now().difference(last) <= staleAfter;
  }
}
