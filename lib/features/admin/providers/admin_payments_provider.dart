import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Payment record model for admin view
class PaymentRecord {
  final String id;
  final String userId;
  final String? userEmail;
  final double amount;
  final String currency;
  final String status; // pending, completed, failed, refunded
  final String paymentMethod; // card, bank_transfer, google_pay
  final String? referenceCode;
  final String? gatewayTransactionId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentRecord({
    required this.id,
    required this.userId,
    this.userEmail,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.referenceCode,
    this.gatewayTransactionId,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentRecord(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      userEmail: data['user_email'] as String?,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      status: data['status'] as String? ?? 'pending',
      paymentMethod: data['payment_method'] as String? ?? 'unknown',
      referenceCode: data['reference_code'] as String?,
      gatewayTransactionId: data['gateway_transaction_id'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}

/// Payment statistics
class PaymentStats {
  final double totalRevenue;
  final int totalPayments;
  final int pendingPayments;
  final int completedPayments;
  final int failedPayments;
  final double monthlyRevenue;
  final double weeklyRevenue;

  PaymentStats({
    required this.totalRevenue,
    required this.totalPayments,
    required this.pendingPayments,
    required this.completedPayments,
    required this.failedPayments,
    required this.monthlyRevenue,
    required this.weeklyRevenue,
  });

  factory PaymentStats.empty() => PaymentStats(
    totalRevenue: 0,
    totalPayments: 0,
    pendingPayments: 0,
    completedPayments: 0,
    failedPayments: 0,
    monthlyRevenue: 0,
    weeklyRevenue: 0,
  );
}

/// State for admin payments
class AdminPaymentsState {
  final List<PaymentRecord> payments;
  final PaymentStats stats;
  final bool isLoading;
  final String? error;
  final String? statusFilter;
  final String? methodFilter;

  AdminPaymentsState({
    this.payments = const [],
    PaymentStats? stats,
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.methodFilter,
  }) : stats = stats ?? PaymentStats.empty();

  AdminPaymentsState copyWith({
    List<PaymentRecord>? payments,
    PaymentStats? stats,
    bool? isLoading,
    String? error,
    String? statusFilter,
    String? methodFilter,
  }) {
    return AdminPaymentsState(
      payments: payments ?? this.payments,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      methodFilter: methodFilter ?? this.methodFilter,
    );
  }

  List<PaymentRecord> get filteredPayments {
    return payments.where((p) {
      if (statusFilter != null && p.status != statusFilter) return false;
      if (methodFilter != null && p.paymentMethod != methodFilter) return false;
      return true;
    }).toList();
  }
}

/// Notifier for admin payments
class AdminPaymentsNotifier extends StateNotifier<AdminPaymentsState> {
  final FirebaseFirestore _firestore;

  AdminPaymentsNotifier({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(AdminPaymentsState()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final snapshot = await _firestore
          .collection('payments')
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      final payments = snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();

      // Calculate stats
      final stats = _calculateStats(payments);

      state = state.copyWith(
        payments: payments,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  PaymentStats _calculateStats(List<PaymentRecord> payments) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    double totalRevenue = 0;
    double weeklyRevenue = 0;
    double monthlyRevenue = 0;
    int pendingPayments = 0;
    int completedPayments = 0;
    int failedPayments = 0;

    for (final payment in payments) {
      if (payment.status == 'completed') {
        totalRevenue += payment.amount;
        completedPayments++;

        if (payment.createdAt.isAfter(weekAgo)) {
          weeklyRevenue += payment.amount;
        }
        if (payment.createdAt.isAfter(monthAgo)) {
          monthlyRevenue += payment.amount;
        }
      } else if (payment.status == 'pending') {
        pendingPayments++;
      } else if (payment.status == 'failed') {
        failedPayments++;
      }
    }

    return PaymentStats(
      totalRevenue: totalRevenue,
      totalPayments: payments.length,
      pendingPayments: pendingPayments,
      completedPayments: completedPayments,
      failedPayments: failedPayments,
      monthlyRevenue: monthlyRevenue,
      weeklyRevenue: weeklyRevenue,
    );
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
  }

  void setMethodFilter(String? method) {
    state = state.copyWith(methodFilter: method);
  }

  void clearFilters() {
    state = AdminPaymentsState(
      payments: state.payments,
      stats: state.stats,
      isLoading: false,
    );
  }

  Future<void> updatePaymentStatus(String paymentId, String newStatus) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
      await loadPayments();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => loadPayments();
}

/// Provider for admin payments
final adminPaymentsProvider =
    StateNotifierProvider<AdminPaymentsNotifier, AdminPaymentsState>((ref) {
      return AdminPaymentsNotifier();
    });
