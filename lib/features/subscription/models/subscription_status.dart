import 'package:flutter/foundation.dart';

enum SubscriptionState {
  free,
  active,
  expired,
  pending,
  cancelled,
  error,
}

/// Represents the subscription status of a user
@immutable
class SubscriptionStatus {
  final SubscriptionState state;
  final String? productId; // "chat_monthly"
  final DateTime? expiryDate;
  final bool autoRenew;
  final String? paymentGateway; // "paypal", "2checkout", "bank_transfer"
  final String? errorMessage;

  const SubscriptionStatus({
    required this.state,
    this.productId,
    this.expiryDate,
    this.autoRenew = false,
    this.paymentGateway,
    this.errorMessage,
  });

  /// Check if subscription is currently active and not expired
  bool get isActive {
    if (state != SubscriptionState.active) return false;
    if (expiryDate == null) return true;
    return expiryDate!.isAfter(DateTime.now());
  }

  /// Check if subscription has expired
  bool get isExpired {
    if (state == SubscriptionState.expired) return true;
    if (expiryDate == null) return false;
    return expiryDate!.isBefore(DateTime.now());
  }

  /// Check if subscription is pending verification
  bool get isPending => state == SubscriptionState.pending;

  /// Check if subscription is in error state
  bool get hasError => state == SubscriptionState.error;

  /// Get days remaining until expiry
  int? get daysRemaining {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Create a copy with updated fields
  SubscriptionStatus copyWith({
    SubscriptionState? state,
    String? productId,
    DateTime? expiryDate,
    bool? autoRenew,
    String? paymentGateway,
    String? errorMessage,
  }) {
    return SubscriptionStatus(
      state: state ?? this.state,
      productId: productId ?? this.productId,
      expiryDate: expiryDate ?? this.expiryDate,
      autoRenew: autoRenew ?? this.autoRenew,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'state': state.name,
      'productId': productId,
      'expiryDate': expiryDate?.toIso8601String(),
      'autoRenew': autoRenew,
      'paymentGateway': paymentGateway,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      state: SubscriptionState.values.byName(
        json['state'] as String? ?? 'free',
      ),
      productId: json['productId'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      autoRenew: json['autoRenew'] as bool? ?? false,
      paymentGateway: json['paymentGateway'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Default free subscription
  factory SubscriptionStatus.free() {
    return const SubscriptionStatus(
      state: SubscriptionState.free,
    );
  }

  /// For pending bank transfer verification
  factory SubscriptionStatus.pending(String paymentGateway) {
    return SubscriptionStatus(
      state: SubscriptionState.pending,
      paymentGateway: paymentGateway,
    );
  }

  @override
  String toString() {
    return 'SubscriptionStatus(state: $state, productId: $productId, '
        'isActive: $isActive, daysRemaining: $daysRemaining)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionStatus &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          productId == other.productId &&
          expiryDate == other.expiryDate &&
          autoRenew == other.autoRenew &&
          paymentGateway == other.paymentGateway &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      state.hashCode ^
      productId.hashCode ^
      expiryDate.hashCode ^
      autoRenew.hashCode ^
      paymentGateway.hashCode ^
      errorMessage.hashCode;
}
