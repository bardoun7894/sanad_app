import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activity_log_provider.dart';
import '../models/activity_log.dart';

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
    );
  }

  AdminUser copyWith({
    String? role,
    bool? isPremium,
    String? subscriptionStatus,
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

      // Update user document with subscription info
      await _firestore.collection('users').doc(userId).update({
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

      // Create a payment record for tracking
      await _firestore.collection('payments').add({
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
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
      return AdminUsersNotifier();
    });
