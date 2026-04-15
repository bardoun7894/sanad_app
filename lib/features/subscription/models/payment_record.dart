import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final String? referenceCode;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.referenceCode,
  });

  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentRecord(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      status: data['status'] as String? ?? 'unknown',
      paymentMethod: data['payment_method'] as String? ?? 'unknown',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      referenceCode: data['reference_code'] as String?,
    );
  }
}
