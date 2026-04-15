import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/therapist_profile.dart';
import '../../../../core/services/storage_service.dart';

/// Service for therapist authentication and registration
class TherapistAuthService {
  final FirebaseFirestore _firestore;

  final StorageService _storageService;

  TherapistAuthService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storageService = storageService ?? StorageService();

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _therapistsCollection =>
      _firestore.collection('therapists');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get therapist approval status for a user
  Future<TherapistApprovalStatus> getTherapistStatus(String userId) async {
    try {
      // First check therapists collection
      final therapistDoc = await _therapistsCollection.doc(userId).get();
      if (therapistDoc.exists) {
        final data = therapistDoc.data();
        return TherapistApprovalStatusX.fromString(
          data?['approval_status'] as String?,
        );
      }

      // Check users collection for pending registrations
      final userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final role = data?['role'] as String?;
        if (role == 'therapist') {
          return TherapistApprovalStatusX.fromString(
            data?['therapist_status'] as String?,
          );
        }
      }

      // Not a therapist
      return TherapistApprovalStatus.pending;
    } catch (e) {
      throw Exception('Failed to get therapist status: $e');
    }
  }

  /// Check if user is an approved therapist
  Future<bool> isApprovedTherapist(String userId) async {
    final status = await getTherapistStatus(userId);
    return status == TherapistApprovalStatus.approved;
  }

  /// Submit therapist registration
  Future<void> submitRegistration(TherapistProfile profile) async {
    try {
      final batch = _firestore.batch();

      // Create therapist document with pending status
      final therapistRef = _therapistsCollection.doc(profile.id);
      batch.set(therapistRef, profile.toFirestore());

      // Update user document with role and status
      final userRef = _usersCollection.doc(profile.id);
      batch.update(userRef, {
        'role': 'therapist',
        'therapist_status': TherapistApprovalStatus.pending.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to submit registration: $e');
    }
  }

  /// Get therapist profile
  Future<TherapistProfile?> getProfile(String therapistId) async {
    try {
      final doc = await _therapistsCollection.doc(therapistId).get();
      if (!doc.exists) return null;
      return TherapistProfile.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get therapist profile: $e');
    }
  }

  /// Get therapist profile as stream
  Stream<TherapistProfile?> getProfileStream(String therapistId) {
    return _therapistsCollection.doc(therapistId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TherapistProfile.fromFirestore(doc);
    });
  }

  /// Update therapist profile
  Future<void> updateProfile(
    String therapistId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _therapistsCollection.doc(therapistId).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Update profile with TherapistProfile object
  Future<void> updateProfileFromModel(TherapistProfile profile) async {
    try {
      await _therapistsCollection.doc(profile.id).update(profile.toFirestore());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Toggle therapist active status
  Future<void> toggleActive(String therapistId, bool isActive) async {
    try {
      await _therapistsCollection.doc(therapistId).update({
        'is_active': isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle active status: $e');
    }
  }

  /// Upload profile photo and update URL
  Future<String> uploadProfilePhoto(
    String therapistId,
    Uint8List photoBytes,
  ) async {
    try {
      final path =
          'therapist_photos/$therapistId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final downloadUrl = await _storageService.uploadFile(
        path: path,
        data: photoBytes,
        contentType: 'image/jpeg',
      );

      await updatePhotoUrl(therapistId, downloadUrl);
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Update profile photo URL
  Future<void> updatePhotoUrl(String therapistId, String photoUrl) async {
    try {
      await _therapistsCollection.doc(therapistId).update({
        'photo_url': photoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update photo URL: $e');
    }
  }

  /// Admin: Approve therapist registration
  Future<void> approveTherapist(String therapistId, String adminId) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Update therapist document
      final therapistRef = _therapistsCollection.doc(therapistId);
      batch.update(therapistRef, {
        'approval_status': TherapistApprovalStatus.approved.name,
        'approved_at': Timestamp.fromDate(now),
        'approved_by': adminId,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update user document
      final userRef = _usersCollection.doc(therapistId);
      batch.update(userRef, {
        'therapist_status': TherapistApprovalStatus.approved.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to approve therapist: $e');
    }
  }

  /// Admin: Reject therapist registration
  Future<void> rejectTherapist(
    String therapistId,
    String adminId,
    String reason,
  ) async {
    try {
      final batch = _firestore.batch();

      // Update therapist document
      final therapistRef = _therapistsCollection.doc(therapistId);
      batch.update(therapistRef, {
        'approval_status': TherapistApprovalStatus.rejected.name,
        'rejection_reason': reason,
        'approved_by': adminId,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update user document
      final userRef = _usersCollection.doc(therapistId);
      batch.update(userRef, {
        'therapist_status': TherapistApprovalStatus.rejected.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to reject therapist: $e');
    }
  }

  /// Admin: Suspend therapist
  Future<void> suspendTherapist(String therapistId, String adminId) async {
    try {
      final batch = _firestore.batch();

      // Update therapist document
      final therapistRef = _therapistsCollection.doc(therapistId);
      batch.update(therapistRef, {
        'approval_status': TherapistApprovalStatus.suspended.name,
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update user document
      final userRef = _usersCollection.doc(therapistId);
      batch.update(userRef, {
        'therapist_status': TherapistApprovalStatus.suspended.name,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to suspend therapist: $e');
    }
  }

  /// Admin: Get pending therapist registrations
  Stream<List<TherapistProfile>> getPendingRegistrations() {
    return _therapistsCollection
        .where(
          'approval_status',
          isEqualTo: TherapistApprovalStatus.pending.name,
        )
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistProfile.fromFirestore(doc))
              .toList();
        });
  }

  /// Admin: Get all therapists with optional status filter
  Stream<List<TherapistProfile>> getTherapists({
    TherapistApprovalStatus? status,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _therapistsCollection;

    if (status != null) {
      query = query.where('approval_status', isEqualTo: status.name);
    }

    query = query.orderBy('created_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TherapistProfile.fromFirestore(doc))
          .toList();
    });
  }

  /// Get approved and active therapists (for client-side listing)
  Stream<List<TherapistProfile>> getActiveTherapists() {
    return _therapistsCollection
        .where(
          'approval_status',
          isEqualTo: TherapistApprovalStatus.approved.name,
        )
        .where('is_active', isEqualTo: true)
        .orderBy('rating', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TherapistProfile.fromFirestore(doc))
              .toList();
        });
  }
}
