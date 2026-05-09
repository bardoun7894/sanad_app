import 'package:flutter/foundation.dart';

enum SubscriptionState { free, active, expired, pending, cancelled, error }

/// Represents the subscription status of a user
@immutable
class SubscriptionStatus {
  final SubscriptionState state;
  final String? productId; // "chat_monthly"
  final DateTime? expiryDate;
  final bool autoRenew;
  final String? paymentGateway; // "google_pay", "bank_transfer"
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
  ///
  /// `cancelled` subscriptions stay active until their `expiryDate` — the user
  /// already paid for the period; cancelling only disables auto-renew.
  bool get isActive {
    if (state == SubscriptionState.active) {
      if (expiryDate == null) return true;
      return expiryDate!.isAfter(DateTime.now());
    }
    if (state == SubscriptionState.cancelled && expiryDate != null) {
      return expiryDate!.isAfter(DateTime.now());
    }
    return false;
  }

  /// Get subscription tier level (0-4)
  /// 0: Free/Inactive
  /// 1: Weekly
  /// 2: Basic
  /// 3: Premium
  /// 4: Premium VIP
  int get tierLevel {
    if (!isActive) return 0;
    switch (productId) {
      case 'weekly':
        return 1;
      case 'basic':
        return 2;
      case 'premium':
        return 3;
      case 'premium_vip':
        return 4;
      default:
        // Check if it's a legacy or admin-granted premium without a specific ID
        return 3; // Default to premium if active but unknown ID
    }
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
      productId:
          json['productId'] as String? ?? json['subscription_plan'] as String?,
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
    return const SubscriptionStatus(state: SubscriptionState.free);
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
