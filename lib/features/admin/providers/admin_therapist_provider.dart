import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../therapist_portal/models/therapist_profile.dart';
import '../providers/activity_log_provider.dart';
import '../models/activity_log.dart';

/// Page size for admin therapist list pagination (M6.1).
const int kAdminTherapistsPageSize = 20;

// State class for AdminTherapistNotifier
class AdminTherapistState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<TherapistProfile> therapists;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  const AdminTherapistState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.therapists = const [],
    this.hasMore = true,
    this.lastDocument,
  });

  AdminTherapistState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<TherapistProfile>? therapists,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool clearLastDocument = false,
  }) {
    return AdminTherapistState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      therapists: therapists ?? this.therapists,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
    );
  }

  // Helpers to filter
  List<TherapistProfile> get pendingTherapists => therapists
      .where((t) => t.approvalStatus == TherapistApprovalStatus.pending)
      .toList();

  List<TherapistProfile> get approvedTherapists => therapists
      .where((t) => t.approvalStatus == TherapistApprovalStatus.approved)
      .toList();

  List<TherapistProfile> get rejectedTherapists => therapists
      .where((t) => t.approvalStatus == TherapistApprovalStatus.rejected)
      .toList();
}

class AdminTherapistNotifier extends StateNotifier<AdminTherapistState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityLogService _activityLogService = ActivityLogService();

  AdminTherapistNotifier() : super(const AdminTherapistState()) {
    _fetchTherapists();
    _backfillMissingCreatedAt();
  }

  /// Backfill `created_at` for therapists missing it so the
  /// `orderBy('created_at')` query doesn't silently exclude them.
  Future<void> _backfillMissingCreatedAt() async {
    try {
      final snapshot = await _firestore.collection('therapists').get();
      final batch = _firestore.batch();
      int count = 0;
      for (final doc in snapshot.docs) {
        if (doc.data()['created_at'] == null) {
          batch.update(doc.reference, {
            'created_at': FieldValue.serverTimestamp(),
          });
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
        debugPrint('Backfilled created_at for $count therapists');
      }
    } catch (e) {
      debugPrint('Failed to backfill created_at: $e');
    }
  }

  /// Fetch first page of therapists with cursor-based pagination (M6.1).
  Future<void> _fetchTherapists() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      hasMore: true,
      clearLastDocument: true,
    );
    try {
      final snapshot = await _firestore
          .collection('therapists')
          .orderBy('created_at', descending: true)
          .limit(kAdminTherapistsPageSize)
          .get();

      final result = _parseTherapists(snapshot.docs);
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      state = state.copyWith(
        isLoading: false,
        therapists: result.therapists,
        hasMore: snapshot.docs.length >= kAdminTherapistsPageSize,
        lastDocument: lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load next page using startAfterDocument cursor (M6.1).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.lastDocument == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final snapshot = await _firestore
          .collection('therapists')
          .orderBy('created_at', descending: true)
          .startAfterDocument(state.lastDocument!)
          .limit(kAdminTherapistsPageSize)
          .get();

      final result = _parseTherapists(snapshot.docs);
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      state = state.copyWith(
        isLoadingMore: false,
        therapists: [...state.therapists, ...result.therapists],
        hasMore: snapshot.docs.length >= kAdminTherapistsPageSize,
        lastDocument: lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Returns (parsed therapists, list of doc IDs that failed).
  ({List<TherapistProfile> therapists, List<String> failedIds}) _parseTherapists(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final failedIds = <String>[];
    final therapists = docs.map((doc) {
      try {
        return TherapistProfile.fromFirestore(doc);
      } catch (e) {
        debugPrint('Error parsing therapist ${doc.id}: $e');
        failedIds.add(doc.id);
        return null;
      }
    }).whereType<TherapistProfile>().toList();
    return (therapists: therapists, failedIds: failedIds);
  }

  Future<void> refresh() => _fetchTherapists();

  /// Create a new therapist profile in Firestore.
  ///
  /// Generates a new document ID and writes to `therapists/{newId}`.
  /// Also creates/merges a `users/{newId}` document with role info.
  /// Note: The new ID is NOT a Firebase Auth UID — the therapist cannot
  /// log in until linked to an auth account separately.
  Future<void> createTherapist(TherapistProfile data, String adminId) async {
    try {
      state = state.copyWith(isLoading: true);

      final newRef = _firestore.collection('therapists').doc();
      final newId = newRef.id;

      // Write therapist document.
      // Admin-created therapists are auto-approved so they appear to users
      // immediately — admin creation is itself the trust signal.
      await newRef.set({
        ...data.toFirestore(),
        'created_at': FieldValue.serverTimestamp(),
        'approval_status': TherapistApprovalStatus.approved.name,
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': adminId,
      });

      // Create/merge user document so the user-role lookup works
      await _firestore.collection('users').doc(newId).set({
        'role': 'therapist',
        'therapist_status': TherapistApprovalStatus.approved.name,
        'email': data.email,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log activity
      try {
        final adminDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .get();
        final adminName =
            adminDoc.data()?['full_name'] as String? ??
            adminDoc.data()?['name'] as String? ??
            'Admin';

        await _activityLogService.logActivity(
          type: ActivityType.therapistApproved,
          userId: adminId,
          userName: adminName,
          description: 'created therapist profile for ${data.name}',
          metadata: {
            'therapist_id': newId,
            'therapist_name': data.name,
            'actor_uid': adminId,
            'action': 'created',
          },
        );
      } catch (e) {
        debugPrint('Failed to log therapist creation activity: $e');
      }

      await _fetchTherapists();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update an existing therapist profile in Firestore.
  Future<void> updateTherapist(TherapistProfile data, String adminId) async {
    try {
      state = state.copyWith(isLoading: true);

      final fields = data.toFirestore();
      // Don't overwrite server-managed fields on update
      fields.remove('created_at');
      fields.remove('rating');
      fields.remove('review_count');

      // Update therapist document
      await _firestore.collection('therapists').doc(data.id).update(fields);

      // Sync status to the user document
      await _firestore.collection('users').doc(data.id).set({
        'role': 'therapist',
        'therapist_status': data.approvalStatus.name,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log activity
      try {
        final adminDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .get();
        final adminName =
            adminDoc.data()?['full_name'] as String? ??
            adminDoc.data()?['name'] as String? ??
            'Admin';

        await _activityLogService.logActivity(
          type: ActivityType.userUpdated,
          userId: adminId,
          userName: adminName,
          description: 'updated therapist profile for ${data.name}',
          metadata: {
            'therapist_id': data.id,
            'therapist_name': data.name,
            'actor_uid': adminId,
            'action': 'updated',
          },
        );
      } catch (e) {
        debugPrint('Failed to log therapist update activity: $e');
      }

      await _fetchTherapists();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> approveTherapist(String therapistId, String adminId) async {
    try {
      state = state.copyWith(isLoading: true);

      // Get therapist details for activity log
      final therapistDoc = await _firestore
          .collection('therapists')
          .doc(therapistId)
          .get();
      final therapistName =
          therapistDoc.data()?['full_name'] as String? ??
          therapistDoc.data()?['name'] as String? ??
          'Therapist';

      await _firestore.collection('therapists').doc(therapistId).update({
        'approval_status': TherapistApprovalStatus.approved.name,
        'approved_at': FieldValue.serverTimestamp(),
        'approved_by': adminId,
        'is_active': true,
      });

      // Also update the main user document to reflect the therapist role
      await _firestore.collection('users').doc(therapistId).set({
        'role': 'therapist',
        'therapist_status': TherapistApprovalStatus.approved.name,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log activity
      try {
        // Get admin name
        final adminDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .get();
        final adminName =
            adminDoc.data()?['full_name'] as String? ??
            adminDoc.data()?['name'] as String? ??
            'Admin';

        await _activityLogService.logTherapistApproved(
          adminId: adminId,
          adminName: adminName,
          therapistName: therapistName,
        );
      } catch (e) {
        debugPrint('Failed to log therapist approval activity: $e');
      }

      await _fetchTherapists(); // Refresh list
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Suspend a therapist — distinct from block. Sets approval_status to
  /// `suspended` AND `is_active=false` so they cannot accept bookings or
  /// log into the therapist portal until reactivated.
  Future<void> suspendTherapist(String therapistId, String adminId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _firestore.collection('therapists').doc(therapistId).update({
        'approval_status': TherapistApprovalStatus.suspended.name,
        'is_active': false,
        'suspended_by': adminId,
        'suspended_at': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(therapistId).set({
        'therapist_status': TherapistApprovalStatus.suspended.name,
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      try {
        final adminDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .get();
        final adminName =
            adminDoc.data()?['full_name'] as String? ??
            adminDoc.data()?['name'] as String? ??
            'Admin';
        await _activityLogService.logActivity(
          type: ActivityType.userSuspended,
          userId: adminId,
          userName: adminName,
          description: 'suspended therapist $therapistId',
          metadata: {
            'therapist_id': therapistId,
            'actor_uid': adminId,
            'action': 'suspended',
          },
        );
      } catch (e) {
        debugPrint('Failed to log therapist suspend activity: $e');
      }
      await _fetchTherapists();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Reverse a suspension by restoring `approved` + `is_active=true`.
  Future<void> reactivateTherapist(String therapistId, String adminId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _firestore.collection('therapists').doc(therapistId).update({
        'approval_status': TherapistApprovalStatus.approved.name,
        'is_active': true,
        'reactivated_by': adminId,
        'reactivated_at': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('users').doc(therapistId).set({
        'therapist_status': TherapistApprovalStatus.approved.name,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      try {
        final adminDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .get();
        final adminName =
            adminDoc.data()?['full_name'] as String? ??
            adminDoc.data()?['name'] as String? ??
            'Admin';
        await _activityLogService.logActivity(
          type: ActivityType.userUpdated,
          userId: adminId,
          userName: adminName,
          description: 'reactivated therapist $therapistId',
          metadata: {
            'therapist_id': therapistId,
            'actor_uid': adminId,
            'action': 'reactivated',
          },
        );
      } catch (e) {
        debugPrint('Failed to log therapist reactivate activity: $e');
      }
      await _fetchTherapists();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Toggle therapist active status (block/unblock).
  Future<void> setTherapistActive(
    String therapistId,
    bool isActive,
    String adminId,
  ) async {
    try {
      state = state.copyWith(isLoading: true);
      await _firestore.collection('therapists').doc(therapistId).update({
        'is_active': isActive,
      });
      await _firestore.collection('users').doc(therapistId).set({
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // Log using the closest available enum — userSuspended for block,
      // userUpdated for unblock.
      try {
        final adminDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .get();
        final adminName =
            adminDoc.data()?['full_name'] as String? ??
            adminDoc.data()?['name'] as String? ??
            'Admin';
        await _activityLogService.logActivity(
          type: isActive
              ? ActivityType.userUpdated
              : ActivityType.userSuspended,
          userId: adminId,
          userName: adminName,
          description:
              '${isActive ? 'unblocked' : 'blocked'} therapist $therapistId',
          metadata: {
            'therapist_id': therapistId,
            'is_active': isActive,
            'actor_uid': adminId,
            'action': isActive ? 'unblocked' : 'blocked',
          },
        );
      } catch (e) {
        debugPrint('Failed to log therapist block/unblock activity: $e');
      }
      await _fetchTherapists();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> rejectTherapist(
    String therapistId,
    String reason,
    String adminId,
  ) async {
    try {
      state = state.copyWith(isLoading: true);

      // Get therapist details for activity log
      final therapistDoc = await _firestore
          .collection('therapists')
          .doc(therapistId)
          .get();
      final therapistName =
          therapistDoc.data()?['full_name'] as String? ??
          therapistDoc.data()?['name'] as String? ??
          'Therapist';

      await _firestore.collection('therapists').doc(therapistId).update({
        'approval_status': TherapistApprovalStatus.rejected.name,
        'rejection_reason': reason,
        'rejected_by': adminId,
        'is_active': false,
      });

      // Also update the main user document
      await _firestore.collection('users').doc(therapistId).set({
        'therapist_status': TherapistApprovalStatus.rejected.name,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Log activity (was previously silent)
      try {
        final adminDoc = await _firestore
            .collection('users')
            .doc(adminId)
            .get();
        final adminName =
            adminDoc.data()?['full_name'] as String? ??
            adminDoc.data()?['name'] as String? ??
            'Admin';

        await _activityLogService.logActivity(
          type: ActivityType.therapistRejected,
          userId: adminId,
          userName: adminName,
          description: 'rejected therapist $therapistName',
          metadata: {
            'therapist_id': therapistId,
            'therapist_name': therapistName,
            'rejection_reason': reason,
            'actor_uid': adminId,
            'action': 'rejected',
          },
        );
      } catch (e) {
        debugPrint('Failed to log therapist rejection activity: $e');
      }

      await _fetchTherapists();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final adminTherapistProvider =
    StateNotifierProvider<AdminTherapistNotifier, AdminTherapistState>((ref) {
      return AdminTherapistNotifier();
    });
