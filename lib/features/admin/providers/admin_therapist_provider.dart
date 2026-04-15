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
      lastDocument:
          clearLastDocument ? null : (lastDocument ?? this.lastDocument),
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

      final therapists = _parseTherapists(snapshot.docs);
      final lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      state = state.copyWith(
        isLoading: false,
        therapists: therapists,
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

      final newTherapists = _parseTherapists(snapshot.docs);
      final lastDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      state = state.copyWith(
        isLoadingMore: false,
        therapists: [...state.therapists, ...newTherapists],
        hasMore: snapshot.docs.length >= kAdminTherapistsPageSize,
        lastDocument: lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  List<TherapistProfile> _parseTherapists(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs
        .map((doc) {
          try {
            return TherapistProfile.fromFirestore(doc);
          } catch (e) {
            debugPrint('Error parsing therapist ${doc.id}: $e');
            return null;
          }
        })
        .whereType<TherapistProfile>()
        .toList();
  }

  Future<void> refresh() => _fetchTherapists();

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
      await _firestore.collection('users').doc(therapistId).update({
        'role': 'therapist',
        'therapist_status': TherapistApprovalStatus.approved.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

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
      await _firestore.collection('users').doc(therapistId).update({
        'therapist_status': TherapistApprovalStatus.rejected.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

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
          type: ActivityType.therapistApproved,
          userId: adminId,
          userName: adminName,
          description: 'rejected therapist ',
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
