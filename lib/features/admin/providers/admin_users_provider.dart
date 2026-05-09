import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activity_log_provider.dart';
import '../models/activity_log.dart';
import '../../therapists/providers/therapist_assignment_provider.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/app_notification.dart';

// Simple model for User list (expand as needed)
class AdminUser {
  final String id;
  final String email;
  final String? displayName;
  final bool isPremium;
  final DateTime? createdAt;
  final String subscriptionStatus;
  final String role;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? assignedTherapistId;
  final String? assignedTherapistName;

  AdminUser({
    required this.id,
    required this.email,
    this.displayName,
    this.isPremium = false,
    this.createdAt,
    this.subscriptionStatus = 'free',
    this.role = 'user',
    this.phoneNumber,
    this.dateOfBirth,
    this.assignedTherapistId,
    this.assignedTherapistName,
  });

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      email: data['email'] ?? 'No Email',
      displayName: data['display_name'] ?? data['name'],
      isPremium: data['is_premium'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      subscriptionStatus: data['subscription_status'] ?? 'free',
      role: data['role'] ?? 'user',
      phoneNumber: data['phone_number'],
      dateOfBirth: (data['date_of_birth'] as Timestamp?)?.toDate(),
      assignedTherapistId: data['assigned_therapist_id'] as String?,
      assignedTherapistName: data['assigned_therapist_name'] as String?,
    );
  }

  AdminUser copyWith({
    String? role,
    bool? isPremium,
    String? subscriptionStatus,
    String? assignedTherapistId,
    String? assignedTherapistName,
  }) {
    return AdminUser(
      id: id,
      email: email,
      displayName: displayName,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      role: role ?? this.role,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      assignedTherapistId: assignedTherapistId ?? this.assignedTherapistId,
      assignedTherapistName: assignedTherapistName ?? this.assignedTherapistName,
    );
  }
}

class AdminUsersState {
  final bool isLoading;
  final List<AdminUser> users;
  final String? error;

  const AdminUsersState({
    this.isLoading = false,
    this.users = const [],
    this.error,
  });

  AdminUsersState copyWith({
    bool? isLoading,
    List<AdminUser>? users,
    String? error,
  }) {
    return AdminUsersState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error,
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityLogService _activityLogService = ActivityLogService();

  AdminUsersNotifier() : super(const AdminUsersState());

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snapshot = await _firestore
          .collection('users')
          .orderBy('created_at', descending: true)
          .limit(50) // Pagination can be added later
          .get();

      final users = snapshot.docs
          .map((doc) => AdminUser.fromFirestore(doc))
          .toList();

      state = state.copyWith(isLoading: false, users: users);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load users: $e',
      );
    }
  }

  /// Update user role with audit logging.
  Future<void> updateUserRole(
    String userId,
    String newRole, {
    String? actorUid,
    String? actorName,
  }) async {
    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);

      // 1. Update user role
      final Map<String, dynamic> updateData = {
        'role': newRole,
        'updated_at': FieldValue.serverTimestamp(),
        if (actorUid != null) 'updated_by': actorUid,
      };

      if (newRole == 'therapist') {
        updateData['therapist_status'] = 'approved';
      } else {
        updateData['therapist_status'] = FieldValue.delete();
      }

      batch.update(userRef, updateData);

      // 2. If promoting to therapist, create therapist profile if missing
      if (newRole == 'therapist') {
        final therapistRef = _firestore.collection('therapists').doc(userId);
        final therapistDoc = await therapistRef.get();

        if (!therapistDoc.exists) {
          // Get current user data for defaults
          final userDoc = await userRef.get();
          final userData = userDoc.data();
          final name =
              userData?['name'] ?? userData?['display_name'] ?? 'New Therapist';
          final email = userData?['email'] ?? '';

          batch.set(therapistRef, {
            'id': userId,
            'name': name,
            'email': email,
            'title': 'Mental Health Specialist',
            'bio':
                'Welcome to my profile. I am dedicated to helping you achieve your mental health goals.',
            'approval_status': 'approved',
            'status': 'active',
            'is_active': true,
            'specialties': ['General Counseling'],
            'session_types': ['video', 'audio', 'chat'],
            'session_price': 150.0,
            'currency': 'SAR',
            'languages': ['Arabic', 'English'],
            'years_experience': 1,
            'rating': 5.0,
            'review_count': 0,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
            'approved_at': FieldValue.serverTimestamp(),
            if (actorUid != null) 'approved_by': actorUid,
          });
        }
      }

      await batch.commit();

      // Log activity
      try {
        await _activityLogService.logActivity(
          type: ActivityType.userUpdated,
          userId: actorUid ?? 'admin',
          userName: actorName ?? 'Admin',
          description: 'changed role of user $userId to $newRole',
          metadata: {
            'target_user_id': userId,
            'new_role': newRole,
            'actor_uid': actorUid ?? 'admin',
          },
        );
      } catch (e) {
        debugPrint('Failed to log role update activity: $e');
      }

      // Update local state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return user.copyWith(role: newRole);
        }
        return user;
      }).toList();

      state = state.copyWith(users: updatedUsers);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update role: $e');
    }
  }

  /// Update user premium status with audit logging.
  Future<bool> updateUserPremium(
    String userId,
    bool isPremium, {
    String? actorUid,
    String? actorName,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'is_premium': isPremium,
        'subscription_status': isPremium ? 'active' : 'free',
        'subscription_plan': isPremium ? 'premium' : null,
        'subscription_expiry_date': isPremium
            ? Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 36500)),
              )
            : null,
        'payment_gateway': isPremium ? 'admin_grant' : null,
        'subscription_assigned_by': isPremium ? (actorUid ?? 'admin') : null,
        'subscription_assigned_at': isPremium
            ? FieldValue.serverTimestamp()
            : null,
        'premium_updated_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        if (actorUid != null) 'updated_by': actorUid,
      });

      // Log activity
      try {
        await _activityLogService.logActivity(
          type: isPremium
              ? ActivityType.subscriptionAssigned
              : ActivityType.subscriptionRevoked,
          userId: actorUid ?? 'admin',
          userName: actorName ?? 'Admin',
          description: isPremium
              ? 'granted premium to user $userId'
              : 'revoked premium from user $userId',
          metadata: {
            'target_user_id': userId,
            'is_premium': isPremium,
            'actor_uid': actorUid ?? 'admin',
          },
        );
      } catch (e) {
        debugPrint('Failed to log premium update activity: $e');
      }

      // Update local state
      state = state.copyWith(
        users: state.users.map((user) {
          if (user.id == userId) {
            return user.copyWith(isPremium: isPremium);
          }
          return user;
        }).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update premium status: $e');
      return false;
    }
  }

  /// Assign a subscription plan to a user with specific duration and audit logging.
  Future<bool> assignSubscription({
    required String userId,
    required String planId,
    required String planTitle,
    required int durationDays,
    double? amount,
    String? currency,
    String? actorUid,
    String? actorName,
  }) async {
    try {
      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));
      final adminId = actorUid ?? 'admin';

      // Batch user-doc update + payment-doc create into a single atomic commit
      // so the Firestore watch stream sees one coherent change instead of
      // multiple back-to-back writes (avoids JS-SDK b815 watch-aggregator
      // assertions on Flutter web admin).
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);
      final paymentRef = _firestore.collection('payments').doc();

      batch.update(userRef, {
        'is_premium': true,
        'subscription_status': 'active',
        'subscription_plan': planId,
        'subscription_product_title': planTitle,
        'subscription_expiry_date': Timestamp.fromDate(endDate),
        'subscription_start_date': FieldValue.serverTimestamp(),
        'payment_gateway': 'admin_grant',
        'auto_renew': false,
        'subscription_assigned_by': adminId,
        'subscription_assigned_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': adminId,
      });

      batch.set(paymentRef, {
        'user_id': userId,
        'product_id': planId,
        'product_title': planTitle,
        'amount': amount ?? 0,
        'currency': currency ?? 'SAR',
        'payment_method': 'admin_grant',
        'status': 'completed',
        'created_at': FieldValue.serverTimestamp(),
        'start_date': FieldValue.serverTimestamp(),
        'end_date': Timestamp.fromDate(endDate),
        'notes': 'Subscription granted by admin',
        'approved_by': adminId,
      });

      await batch.commit();

      // Log activity
      try {
        await _activityLogService.logActivity(
          type: ActivityType.subscriptionAssigned,
          userId: adminId,
          userName: actorName ?? 'Admin',
          description:
              'assigned $planTitle subscription ($durationDays days) to user $userId',
          metadata: {
            'target_user_id': userId,
            'plan_id': planId,
            'plan_title': planTitle,
            'duration_days': durationDays,
            'actor_uid': adminId,
          },
        );
      } catch (e) {
        debugPrint('Failed to log subscription assignment activity: $e');
      }

      // Create in-app notification (non-blocking; tolerable failure)
      try {
        NotificationService(firestore: _firestore).createNotification(
          AppNotification(
            id: '',
            userId: userId,
            title: 'Subscription Activated',
            body: 'Your $planTitle subscription is now active.',
            type: NotificationType.payment,
            createdAt: DateTime.now(),
            data: {
              'plan_id': planId,
              'plan_title': planTitle,
            },
            actionRoute: '/subscription',
            pushFcm: true,
          ),
        );
      } catch (_) {
        debugPrint(
          'Failed to create subscription notification (non-fatal)',
        );
      }

      // Update local state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return user.copyWith(isPremium: true, subscriptionStatus: 'active');
        }
        return user;
      }).toList();

      state = state.copyWith(users: updatedUsers);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to assign subscription: $e');
      return false;
    }
  }

  /// Revoke subscription from a user with audit logging.
  Future<bool> revokeSubscription(
    String userId, {
    String? actorUid,
    String? actorName,
  }) async {
    try {
      final adminId = actorUid ?? 'admin';

      await _firestore.collection('users').doc(userId).update({
        'is_premium': false,
        'subscription_status': 'cancelled',
        'auto_renew': false,
        'subscription_revoked_at': FieldValue.serverTimestamp(),
        'subscription_revoked_by': adminId,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': adminId,
      });

      // Log activity
      try {
        await _activityLogService.logActivity(
          type: ActivityType.subscriptionRevoked,
          userId: adminId,
          userName: actorName ?? 'Admin',
          description: 'revoked subscription for user $userId',
          metadata: {
            'target_user_id': userId,
            'actor_uid': adminId,
          },
        );
      } catch (e) {
        debugPrint('Failed to log subscription revocation activity: $e');
      }

      // Update local state
      final updatedUsers = state.users.map((user) {
        if (user.id == userId) {
          return user.copyWith(
            isPremium: false,
            subscriptionStatus: 'cancelled',
          );
        }
        return user;
      }).toList();

      state = state.copyWith(users: updatedUsers);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to revoke subscription: $e');
      return false;
    }
  }

  /// Assign a therapist to a user.
  ///
  /// Thin pass-through to [TherapistAssignmentNotifier]. Returns true on
  /// success or partial-success, false on validation error.
  Future<bool> assignTherapist({
    required String userId,
    required String therapistId,
    required String therapistName,
    String? therapistPhotoUrl,
    String? actorUid,
    String? actorName,
  }) async {
    try {
      final result = await TherapistAssignmentNotifier().assignTherapist(
        userId: userId,
        therapistId: therapistId,
        therapistName: therapistName,
        therapistPhotoUrl: therapistPhotoUrl,
        actorUid: actorUid ?? 'admin',
        actorName: actorName ?? 'Admin',
        triggeredBy: 'admin',
      );
      final ok = assignmentResultToBool(result);
      if (!ok) {
        final reason = result is AssignmentValidationError ? result.reason : '';
        state = state.copyWith(error: 'Failed to assign therapist: $reason');
      }
      return ok;
    } catch (e) {
      state = state.copyWith(error: 'Failed to assign therapist: $e');
      return false;
    }
  }

  /// Remove therapist assignment from a user.
  ///
  /// Thin pass-through to [TherapistAssignmentNotifier].
  Future<bool> removeTherapistAssignment(
    String userId, {
    String? actorUid,
    String? actorName,
  }) async {
    try {
      final result = await TherapistAssignmentNotifier().unassignTherapist(
        userId: userId,
        actorUid: actorUid ?? 'admin',
        actorName: actorName ?? 'Admin',
        triggeredBy: 'admin',
      );
      final ok = assignmentResultToBool(result);
      if (!ok) {
        final reason = result is AssignmentValidationError ? result.reason : '';
        state = state.copyWith(error: 'Failed to remove therapist: $reason');
      }
      return ok;
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove therapist: $e');
      return false;
    }
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
      return AdminUsersNotifier();
    });

/// Provider that fetches all approved therapists for admin assignment UI.
final approvedTherapistsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('therapists')
      .where('approval_status', isEqualTo: 'approved')
      .get();

  final therapists = snapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'id': doc.id,
      'name': data['name'] ?? 'Unknown',
    };
  }).toList();

  // Sort in-memory to avoid needing a composite Firestore index
  therapists.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  return therapists;
});
