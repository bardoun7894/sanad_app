import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/signup_failure.dart';

class SignupFailuresState {
  final bool isLoading;
  final List<SignupFailure> failures;
  final List<SignupFailure> incompleteProfiles;
  final String? error;

  const SignupFailuresState({
    this.isLoading = false,
    this.failures = const [],
    this.incompleteProfiles = const [],
    this.error,
  });

  SignupFailuresState copyWith({
    bool? isLoading,
    List<SignupFailure>? failures,
    List<SignupFailure>? incompleteProfiles,
    String? error,
  }) =>
      SignupFailuresState(
        isLoading: isLoading ?? this.isLoading,
        failures: failures ?? this.failures,
        incompleteProfiles: incompleteProfiles ?? this.incompleteProfiles,
        error: error,
      );
}

class SignupFailuresNotifier extends StateNotifier<SignupFailuresState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SignupFailuresNotifier() : super(const SignupFailuresState());

  /// Load both: hard failures (signup_failures collection) and "stuck"
  /// users (have an auth doc but never finished profile completion).
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final failuresSnap = await _firestore
          .collection('signup_failures')
          .where('resolved', isEqualTo: false)
          .orderBy('attempted_at', descending: true)
          .limit(100)
          .get();

      final failures =
          failuresSnap.docs.map(SignupFailure.fromFirestore).toList();

      final incompleteSnap = await _firestore
          .collection('users')
          .where('has_complete_profile', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      final incomplete =
          incompleteSnap.docs.map(SignupFailure.fromIncompleteUser).toList();

      state = state.copyWith(
        isLoading: false,
        failures: failures,
        incompleteProfiles: incomplete,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load signup health: $e',
      );
    }
  }

  Future<void> markResolved(String uid) async {
    try {
      await _firestore
          .collection('signup_failures')
          .doc(uid)
          .update({'resolved': true, 'resolved_at': FieldValue.serverTimestamp()});
      await load();
    } catch (e) {
      state = state.copyWith(error: 'Could not mark resolved: $e');
    }
  }

  Future<void> dismiss(String uid) async {
    try {
      await _firestore.collection('signup_failures').doc(uid).delete();
      await load();
    } catch (e) {
      state = state.copyWith(error: 'Could not dismiss: $e');
    }
  }

  /// Invoke the `backfillOrphanUsers` Cloud Function. Reconciles any Firebase
  /// Auth user without a Firestore users/{uid} doc — seeds the missing doc
  /// from Auth metadata. Returns a stats map so the UI can show the result.
  Future<Map<String, dynamic>> runBackfill({required bool dryRun}) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('backfillOrphanUsers');
      final result = await callable.call({'dryRun': dryRun});
      if (!dryRun) {
        // Reload the dashboard so newly seeded users show up
        await load();
      }
      final data = Map<String, dynamic>.from(result.data as Map);
      return data;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('${e.code}: ${e.message}');
    }
  }
}

final signupFailuresProvider =
    StateNotifierProvider<SignupFailuresNotifier, SignupFailuresState>(
        (ref) => SignupFailuresNotifier());

/// Auto-loading list of users who signed up but never completed their profile.
/// Used by the admin dashboard to surface them inline (no manual load() needed).
/// Relies on every signup writing `has_complete_profile` so the equality query
/// can match abandoned users, and the (has_complete_profile, created_at) index.
final incompleteProfilesProvider =
    FutureProvider.autoDispose<List<SignupFailure>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .where('has_complete_profile', isEqualTo: false)
      .orderBy('created_at', descending: true)
      .limit(50)
      .get();

  return snap.docs.map(SignupFailure.fromIncompleteUser).toList();
});
