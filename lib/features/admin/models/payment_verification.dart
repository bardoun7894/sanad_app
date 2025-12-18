import 'package:cloud_firestore/cloud_firestore.dart';

enum VerificationStatus { pending, approved, rejected }

class PaymentVerification {
  final String id;
  final String odId;
  final String productId;
  final String productTitle;
  final double amount;
  final String currency;
  final String referenceCode;
  final String? receiptUrl;
  final VerificationStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;
  final String userName;
  final String userEmail;

  const PaymentVerification({
    required this.id,
    required this.odId,
    required this.productId,
    required this.productTitle,
    required this.amount,
    required this.currency,
    required this.referenceCode,
    this.receiptUrl,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
    required this.userName,
    required this.userEmail,
  });

  factory PaymentVerification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentVerification(
      id: doc.id,
      odId: data['user_id'] ?? '',
      productId: data['product_id'] ?? '',
      productTitle: data['product_title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      referenceCode: data['reference_code'] ?? '',
      receiptUrl: data['receipt_url'],
      status: _parseStatus(data['status']),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (data['reviewed_at'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewed_by'],
      rejectionReason: data['rejection_reason'],
      userName: data['user_name'] ?? 'Unknown',
      userEmail: data['user_email'] ?? '',
    );
  }

  static VerificationStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': odId,
      'product_id': productId,
      'product_title': productTitle,
      'amount': amount,
      'currency': currency,
      'reference_code': referenceCode,
      'receipt_url': receiptUrl,
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'reviewed_at': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewed_by': reviewedBy,
      'rejection_reason': rejectionReason,
      'user_name': userName,
      'user_email': userEmail,
    };
  }

  PaymentVerification copyWith({
    String? id,
    String? odId,
    String? productId,
    String? productTitle,
    double? amount,
    String? currency,
    String? referenceCode,
    String? receiptUrl,
    VerificationStatus? status,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    String? userName,
    String? userEmail,
  }) {
    return PaymentVerification(
      id: id ?? this.id,
      odId: odId ?? this.odId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      referenceCode: referenceCode ?? this.referenceCode,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}
