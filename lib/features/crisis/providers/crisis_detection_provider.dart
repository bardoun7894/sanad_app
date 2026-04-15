import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/crisis_detection_service.dart';

/// Provider for the CrisisDetectionService.
final crisisDetectionServiceProvider = Provider<CrisisDetectionService>((ref) {
  return CrisisDetectionService();
});

/// Stream provider for a user's crisis mode status.
/// Watches the user document's `crisis_mode` field in real-time.
final userCrisisModeProvider = StreamProvider.family<bool, String>((
  ref,
  userId,
) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.data()?['crisis_mode'] as bool? ?? false);
});
