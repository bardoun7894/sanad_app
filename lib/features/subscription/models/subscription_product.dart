import 'package:flutter/foundation.dart';

/// Represents a subscription product/plan
@immutable
class SubscriptionProduct {
  final String id; // "chat_monthly", "call_hour"
  final String title; // "Chat Subscription", "Therapy Call"
  final String description;
  final double price; // in USD
  final String currencyCode; // "USD"
  final String billingPeriod; // "monthly", "hourly", "pay_per_minute"
  final int billingPeriodDays; // 30 for monthly, 1 for daily, 0 for pay-as-you-go
  final String? localizedPrice; // Formatted price string
  final bool isFeatured;
  final List<String> features; // List of feature descriptions

  const SubscriptionProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currencyCode,
    required this.billingPeriod,
    required this.billingPeriodDays,
    this.localizedPrice,
    this.isFeatured = false,
    this.features = const [],
  });

  /// Get price per period
  double get pricePerPeriod => price;

  /// For hourly calls: get price per minute
  double get pricePerMinute {
    if (billingPeriod == 'hourly') {
      return price / 60.0; // $5/hour = $0.0833/minute
    }
    return 0;
  }

  /// Create a copy with updated fields
  SubscriptionProduct copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? currencyCode,
    String? billingPeriod,
    int? billingPeriodDays,
    String? localizedPrice,
    bool? isFeatured,
    List<String>? features,
  }) {
    return SubscriptionProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currencyCode: currencyCode ?? this.currencyCode,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      billingPeriodDays: billingPeriodDays ?? this.billingPeriodDays,
      localizedPrice: localizedPrice ?? this.localizedPrice,
      isFeatured: isFeatured ?? this.isFeatured,
      features: features ?? this.features,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currencyCode': currencyCode,
      'billingPeriod': billingPeriod,
      'billingPeriodDays': billingPeriodDays,
      'localizedPrice': localizedPrice,
      'isFeatured': isFeatured,
      'features': features,
    };
  }

  /// Create from JSON
  factory SubscriptionProduct.fromJson(Map<String, dynamic> json) {
    return SubscriptionProduct(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      billingPeriod: json['billingPeriod'] as String,
      billingPeriodDays: json['billingPeriodDays'] as int? ?? 0,
      localizedPrice: json['localizedPrice'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Predefined products
  static const SubscriptionProduct chatMonthly = SubscriptionProduct(
    id: 'chat_monthly',
    title: 'Chat Subscription',
    description: 'Unlimited messaging with AI and therapists',
    price: 5.0,
    currencyCode: 'USD',
    billingPeriod: 'monthly',
    billingPeriodDays: 30,
    isFeatured: true,
    features: [
      'Unlimited messaging with AI',
      'Access to licensed therapists',
      'Mood tracking tools',
      'Therapy resources library',
      'Cancel anytime',
    ],
  );

  static const SubscriptionProduct therapyCallHourly = SubscriptionProduct(
    id: 'call_hourly',
    title: 'Therapy Call',
    description: 'Voice/video call with therapist',
    price: 5.0,
    currencyCode: 'USD',
    billingPeriod: 'hourly',
    billingPeriodDays: 0,
    isFeatured: false,
    features: [
      'One-on-one video/audio calls',
      'Scheduled therapy sessions',
      'Licensed therapist consultations',
      'Flexible booking',
      'Pay only for what you use',
    ],
  );

  static List<SubscriptionProduct> get allProducts => [
        chatMonthly,
        therapyCallHourly,
      ];

  @override
  String toString() {
    return 'SubscriptionProduct(id: $id, title: $title, price: $price)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          price == other.price &&
          currencyCode == other.currencyCode &&
          billingPeriod == other.billingPeriod;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      price.hashCode ^
      currencyCode.hashCode ^
      billingPeriod.hashCode;
}
