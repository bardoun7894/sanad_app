import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/payment_verification.dart';
import 'activity_log_provider.dart';
import '../models/activity_log.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/models/app_notification.dart';

// Admin state
class AdminState {
  final bool isLoading;
  final List<PaymentVerification> pendingVerifications;
  final List<PaymentVerification> processedVerifications;
  final String? error;
  final VerificationFilter filter;

  const AdminState({
    this.isLoading = false,
    this.pendingVerifications = const [],
    this.processedVerifications = const [],
    this.error,
    this.filter = VerificationFilter.pending,
  });

  AdminState copyWith({
    bool? isLoading,
    List<PaymentVerification>? pendingVerifications,
    List<PaymentVerification>? processedVerifications,
    String? error,
    VerificationFilter? filter,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      pendingVerifications: pendingVerifications ?? this.pendingVerifications,
      processedVerifications:
          processedVerifications ?? this.processedVerifications,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  /// Admin status is now derived from authProvider (single source of truth).
  /// Use ref.watch(isAdminProvider) from auth_provider.dart instead.

  List<PaymentVerification> get filteredVerifications {
    switch (filter) {
      case VerificationFilter.pending:
        return pendingVerifications;
      case VerificationFilter.approved:
        return processedVerifications
            .where((v) => v.status == VerificationStatus.approved)
            .toList();
      case VerificationFilter.rejected:
        return processedVerifications
            .where((v) => v.status == VerificationStatus.rejected)
            .toList();
      case VerificationFilter.all:
        return [...pendingVerifications, ...processedVerifications];
    }
  }
}

enum VerificationFilter { pending, approved, rejected, all }

// Admin provider
class AdminNotifier extends StateNotifier<AdminState> {
  final FirebaseFirestore _firestore;
  final Ref _ref;
  final ActivityLogService _activityLogService = ActivityLogService();

  AdminNotifier(this._ref)
    : _firestore = FirebaseFirestore.instance,
      super(const AdminState()) {
    _initializeIfAdmin();
  }

  /// Helper to get the current admin UID for audit trail.
  String get _actorUid {
    final authState = _ref.read(authProvider);
    return authState.user?.uid ?? 'unknown';
  }

  /// Helper to get the current admin display name.
  String get _actorName {
    final authState = _ref.read(authProvider);
    return authState.user?.displayName ?? 'Admin';
  }

  /// Check admin status from the single source of truth (authProvider)
  /// and load data if admin.
  Future<void> _initializeIfAdmin() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authProvider);
      if (authState.user == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // Use authProvider.isAdmin as the single source of truth.
      // authProvider checks custom claims first, then Firestore fallback.
      final isAdmin = authState.isAdmin;

      if (isAdmin) {
        state = state.copyWith(isLoading: false);
        await loadVerifications();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize admin: $e',
      );
    }
  }

  Future<void> loadVerifications() async {
    // Guard: use authProvider as single source of truth
    final authState = _ref.read(authProvider);
    if (!authState.isAdmin) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      // Load pending verifications
      final pendingSnapshot = await _firestore
          .collection('payment_verifications')
          .where('status', isEqualTo: 'pending')
          .orderBy('created_at', descending: true)
          .get();

      final pending = pendingSnapshot.docs
          .map((doc) => PaymentVerification.fromFirestore(doc))
          .toList();

      // Load processed verifications (last 50)
      final processedSnapshot = await _firestore
          .collection('payment_verifications')
          .where('status', whereIn: ['approved', 'rejected'])
          .orderBy('reviewed_at', descending: true)
          .limit(50)
          .get();

      final processed = processedSnapshot.docs
          .map((doc) => PaymentVerification.fromFirestore(doc))
          .toList();

      state = state.copyWith(
        pendingVerifications: pending,
        processedVerifications: processed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load verifications: $e',
      );
    }
  }

  void setFilter(VerificationFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<bool> approveVerification(String verificationId) async {
    final authState = _ref.read(authProvider);
    if (!authState.isAdmin) return false;

    try {
      final adminId = _actorUid;

      // Get verification details
      final verificationDoc = await _firestore
          .collection('payment_verifications')
          .doc(verificationId)
          .get();

      if (!verificationDoc.exists) {
        state = state.copyWith(error: 'Verification not found');
        return false;
      }

      final verification = PaymentVerification.fromFirestore(verificationDoc);

      // Update verification status
      await _firestore
          .collection('payment_verifications')
          .doc(verificationId)
          .update({
            'status': 'approved',
            'reviewed_at': FieldValue.serverTimestamp(),
            'reviewed_by': adminId,
          });

      // Activate user subscription
      await _activateSubscription(
        userId: verification.odId,
        productId: verification.productId,
        productTitle: verification.productTitle,
        amount: verification.amount,
        currency: verification.currency,
        actorUid: adminId,
      );

      // Log activity
      try {
        final adminName = _actorName;

        // Get user name
        final userDoc = await _firestore
            .collection('users')
            .doc(verification.odId)
            .get();
        final userName =
            userDoc.data()?['full_name'] as String? ??
            userDoc.data()?['name'] as String? ??
            'User';

        await _activityLogService.logPaymentVerified(
          adminId: adminId,
          adminName: adminName,
          userName: userName,
          amount: verification.amount,
        );
      } catch (e) {
        debugPrint('Failed to log payment verification activity: $e');
      }

      // Reload verifications
      await loadVerifications();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to approve: $e');
      return false;
    }
  }

  Future<bool> rejectVerification(String verificationId, String reason) async {
    final authState = _ref.read(authProvider);
    if (!authState.isAdmin) return false;

    try {
      final adminId = _actorUid;
      final adminName = _actorName;

      // Get verification details for logging
      final verificationDoc = await _firestore
          .collection('payment_verifications')
          .doc(verificationId)
          .get();

      final userId = verificationDoc.data()?['user_id'] as String? ?? '';

      await _firestore
          .collection('payment_verifications')
          .doc(verificationId)
          .update({
            'status': 'rejected',
            'reviewed_at': FieldValue.serverTimestamp(),
            'reviewed_by': adminId,
            'rejection_reason': reason,
          });

      // Log the rejection (was previously silent)
      try {
        await _activityLogService.logActivity(
          type: ActivityType.paymentVerified,
          userId: adminId,
          userName: adminName,
          description:
              'rejected payment verification $verificationId for user $userId',
          metadata: {
            'verification_id': verificationId,
            'user_id': userId,
            'rejection_reason': reason,
            'actor_uid': adminId,
            'action': 'rejected',
          },
        );
      } catch (e) {
        debugPrint('Failed to log payment rejection activity: $e');
      }

      // Reload verifications
      await loadVerifications();
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to reject: $e');
      return false;
    }
  }

  Future<void> _activateSubscription({
    required String userId,
    required String productId,
    required String productTitle,
    required double amount,
    required String currency,
    required String actorUid,
  }) async {
    // Calculate end date (1 month from now for monthly, 1 year for yearly)
    final now = DateTime.now();
    final isYearly =
        productId.contains('yearly') || productId.contains('annual');
    final endDate = isYearly
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);

    // Update user subscription status
    await _firestore.collection('users').doc(userId).update({
      'subscription_status': 'active',
      'subscription_plan': productId,
      'subscription_product_title': productTitle,
      'subscription_start_date': FieldValue.serverTimestamp(),
      'subscription_expiry_date': Timestamp.fromDate(endDate),
      'is_premium': true,
      'payment_gateway': 'bank_transfer',
      'auto_renew': false,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': actorUid,
    });

    // Create payment record with actor_uid
    await _firestore.collection('payments').add({
      'user_id': userId,
      'product_id': productId,
      'product_title': productTitle,
      'amount': amount,
      'currency': currency,
      'payment_method': 'bank_transfer',
      'status': 'completed',
      'created_at': FieldValue.serverTimestamp(),
      'start_date': FieldValue.serverTimestamp(),
      'end_date': Timestamp.fromDate(endDate),
      'approved_by': actorUid,
    });

    // Create in-app notification (non-blocking; tolerable failure)
    try {
      NotificationService(firestore: _firestore).createNotification(
        AppNotification(
          id: '',
          userId: userId,
          title: 'Subscription Activated',
          body: 'Your $productTitle subscription is now active.',
          type: NotificationType.payment,
          createdAt: DateTime.now(),
          data: {
            'plan_id': productId,
            'plan_title': productTitle,
          },
          actionRoute: '/subscription',
        ),
      );
    } catch (_) {
      debugPrint(
        'Failed to create subscription notification (non-fatal)',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref);
});

// NOTE: isAdminProvider is defined in auth_provider.dart as the single source
// of truth. It checks Firebase custom claims first, then Firestore fallback.
// Do NOT re-declare isAdminProvider here to avoid conflicts.
// Import it from: '../../auth/providers/auth_provider.dart'

final pendingVerificationsCountProvider = Provider<int>((ref) {
  return ref.watch(adminProvider).pendingVerifications.length;
});

// Dashboard Stats Model
class DashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int criticalFlags;
  final int sessionsToday;
  final int pendingSessions;
  final double totalRevenue;
  final double todayRevenue;
  final int newUsersThisMonth;
  final int premiumUsers;

  const DashboardStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.criticalFlags = 0,
    this.sessionsToday = 0,
    this.pendingSessions = 0,
    this.totalRevenue = 0,
    this.todayRevenue = 0,
    this.newUsersThisMonth = 0,
    this.premiumUsers = 0,
  });

  String get formattedRevenue {
    if (totalRevenue >= 1000) {
      return 'SAR ${(totalRevenue / 1000).toStringAsFixed(1)}k';
    }
    return 'SAR ${totalRevenue.toStringAsFixed(0)}';
  }

  String get usersTrend {
    if (totalUsers == 0) return '+0%';
    final percentage = ((newUsersThisMonth / totalUsers) * 100).round();
    return '+$percentage%';
  }
}

// Dashboard Stats Provider
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final startOfMonth = DateTime(now.year, now.month, 1);

  try {
    // Get total users count
    final usersSnapshot = await firestore.collection('users').get();
    final totalUsers = usersSnapshot.docs.length;

    // Count premium users
    final premiumUsers = usersSnapshot.docs
        .where((doc) => doc.data()['is_premium'] == true)
        .length;

    // Count active users (logged in within last 30 days)
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final activeUsers = usersSnapshot.docs.where((doc) {
      final lastLogin = doc.data()['last_login'] as Timestamp?;
      return lastLogin != null && lastLogin.toDate().isAfter(thirtyDaysAgo);
    }).length;

    // Count new users this month
    final newUsersThisMonth = usersSnapshot.docs.where((doc) {
      final createdAt = doc.data()['created_at'] as Timestamp?;
      return createdAt != null && createdAt.toDate().isAfter(startOfMonth);
    }).length;

    // Get bookings for today
    final bookingsSnapshot = await firestore
        .collection('bookings')
        .where(
          'scheduled_time',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where(
          'scheduled_time',
          isLessThan: Timestamp.fromDate(
            startOfDay.add(const Duration(days: 1)),
          ),
        )
        .get();

    final sessionsToday = bookingsSnapshot.docs.length;
    final pendingSessions = bookingsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'pending')
        .length;

    // Get payments/revenue
    final paymentsSnapshot = await firestore
        .collection('payments')
        .where('status', isEqualTo: 'completed')
        .get();

    double totalRevenue = 0;
    for (final doc in paymentsSnapshot.docs) {
      final amount = doc.data()['amount'];
      if (amount is num) {
        totalRevenue += amount.toDouble();
      }
    }

    // Get critical flags (users with high risk assessment)
    final assessmentsSnapshot = await firestore
        .collection('assessments')
        .where('risk_level', whereIn: ['high', 'critical'])
        .get();
    final criticalFlags = assessmentsSnapshot.docs.length;

    return DashboardStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      criticalFlags: criticalFlags,
      sessionsToday: sessionsToday,
      pendingSessions: pendingSessions,
      totalRevenue: totalRevenue,
      newUsersThisMonth: newUsersThisMonth,
      premiumUsers: premiumUsers,
    );
  } catch (e) {
    // Return empty stats on error
    return const DashboardStats();
  }
});
