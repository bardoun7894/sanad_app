import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_handoff.dart';

class ChatHandoffRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'chat_handoffs';

  ChatHandoffRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _handoffsRef => _firestore.collection(_collection);

  /// Create a new handoff.
  Future<String> create(ChatHandoff handoff) async {
    try {
      final docRef = await _handoffsRef.add(handoff.toFirestore());
      debugPrint('Handoff created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating handoff: $e');
      rethrow;
    }
  }

  /// Get a handoff by ID.
  Future<ChatHandoff?> get(String handoffId) async {
    final doc = await _handoffsRef.doc(handoffId).get();
    if (!doc.exists) return null;
    return ChatHandoff.fromFirestore(doc);
  }

  /// Update handoff status.
  Future<void> updateStatus(String handoffId, HandoffStatus status) async {
    await _handoffsRef.doc(handoffId).update({
      'status': status.name,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Accept a handoff (therapist action).
  Future<void> accept(
    String handoffId,
    String therapistId,
    String therapistName,
  ) async {
    await _handoffsRef.doc(handoffId).update({
      'status': HandoffStatus.accepted.name,
      'therapist_id': therapistId,
      'therapist_name': therapistName,
      'accepted_at': FieldValue.serverTimestamp(),
    });
  }

  /// Complete a handoff.
  Future<void> complete(String handoffId) async {
    await _handoffsRef.doc(handoffId).update({
      'status': HandoffStatus.completed.name,
      'completed_at': FieldValue.serverTimestamp(),
    });
  }

  /// Cancel a handoff.
  Future<void> cancel(String handoffId) async {
    await _handoffsRef.doc(handoffId).update({
      'status': HandoffStatus.cancelled.name,
    });
  }

  /// Link a therapist chat ID to the handoff.
  Future<void> linkTherapistChat(
    String handoffId,
    String therapistChatId,
  ) async {
    await _handoffsRef.doc(handoffId).update({
      'therapist_chat_id': therapistChatId,
    });
  }

  /// Stream pending handoffs for admin queue.
  Stream<List<ChatHandoff>> streamPendingHandoffs() {
    return _handoffsRef
        .where('status', isEqualTo: HandoffStatus.pending.name)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatHandoff.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream handoffs for a specific user.
  Stream<List<ChatHandoff>> streamUserHandoffs(String userId) {
    return _handoffsRef
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatHandoff.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream handoffs assigned to a therapist.
  Stream<List<ChatHandoff>> streamTherapistHandoffs(String therapistId) {
    return _handoffsRef
        .where('therapist_id', isEqualTo: therapistId)
        .where(
          'status',
          whereIn: [HandoffStatus.accepted.name, HandoffStatus.inProgress.name],
        )
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatHandoff.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get active handoff for a user (if any).
  Future<ChatHandoff?> getActiveHandoffForUser(String userId) async {
    final snapshot = await _handoffsRef
        .where('user_id', isEqualTo: userId)
        .where(
          'status',
          whereIn: [
            HandoffStatus.pending.name,
            HandoffStatus.accepted.name,
            HandoffStatus.inProgress.name,
          ],
        )
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return ChatHandoff.fromFirestore(snapshot.docs.first);
  }
}
