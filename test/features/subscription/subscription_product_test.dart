import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/subscription/models/subscription_product.dart';

void main() {
  group('SubscriptionProduct', () {
    test('creates with required fields', () {
      const product = SubscriptionProduct(
        id: 'test-1',
        title: 'Test Plan',
        description: 'A test plan',
        price: 9.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
      );

      expect(product.id, 'test-1');
      expect(product.title, 'Test Plan');
      expect(product.price, 9.99);
      expect(product.currencyCode, 'USD');
      expect(product.billingPeriod, 'monthly');
      expect(product.billingPeriodDays, 30);
      expect(product.isFeatured, isFalse);
      expect(product.features, isEmpty);
    });

    test('pricePerPeriod returns price', () {
      const product = SubscriptionProduct(
        id: 'test-1',
        title: 'Test',
        description: 'Test',
        price: 19.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
      );

      expect(product.pricePerPeriod, 19.99);
    });

    test('pricePerMinute calculates for hourly billing', () {
      const product = SubscriptionProduct(
        id: 'call-1',
        title: 'Call',
        description: 'Call',
        price: 60.0,
        currencyCode: 'USD',
        billingPeriod: 'hourly',
        billingPeriodDays: 0,
      );

      expect(product.pricePerMinute, closeTo(1.0, 0.01));
    });

    test('pricePerMinute returns 0 for non-hourly billing', () {
      const product = SubscriptionProduct(
        id: 'test-1',
        title: 'Test',
        description: 'Test',
        price: 19.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
      );

      expect(product.pricePerMinute, 0);
    });

    test('copyWith creates updated copy', () {
      const product = SubscriptionProduct(
        id: 'test-1',
        title: 'Old Title',
        description: 'Old desc',
        price: 9.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
      );

      final updated = product.copyWith(
        title: 'New Title',
        price: 14.99,
        isFeatured: true,
      );

      expect(updated.title, 'New Title');
      expect(updated.price, 14.99);
      expect(updated.isFeatured, isTrue);
      expect(updated.id, 'test-1');
      expect(product.title, 'Old Title');
    });

    test('toJson serializes correctly', () {
      const product = SubscriptionProduct(
        id: 'test-1',
        title: 'Test',
        description: 'Desc',
        price: 19.99,
        currencyCode: 'SAR',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
        isFeatured: true,
        features: ['Feature 1', 'Feature 2'],
      );

      final json = product.toJson();

      expect(json['id'], 'test-1');
      expect(json['title'], 'Test');
      expect(json['price'], 19.99);
      expect(json['currencyCode'], 'SAR');
      expect(json['isFeatured'], true);
      expect(json['features'], ['Feature 1', 'Feature 2']);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'test-1',
        'title': 'Test',
        'description': 'Desc',
        'price': 19.99,
        'currencyCode': 'SAR',
        'billingPeriod': 'monthly',
        'billingPeriodDays': 30,
        'isFeatured': true,
        'features': ['Feature 1'],
      };

      final product = SubscriptionProduct.fromJson(json);

      expect(product.id, 'test-1');
      expect(product.title, 'Test');
      expect(product.price, 19.99);
      expect(product.isFeatured, isTrue);
      expect(product.features, ['Feature 1']);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'test-1',
        'title': 'Test',
        'description': 'Desc',
        'price': 19.99,
        'billingPeriod': 'monthly',
      };

      final product = SubscriptionProduct.fromJson(json);

      expect(product.currencyCode, 'USD');
      expect(product.billingPeriodDays, 0);
      expect(product.isFeatured, isFalse);
      expect(product.features, isEmpty);
    });

    test('equality works correctly', () {
      const product1 = SubscriptionProduct(
        id: 'test-1',
        title: 'Test',
        description: 'Desc',
        price: 19.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
      );

      const product2 = SubscriptionProduct(
        id: 'test-1',
        title: 'Test',
        description: 'Different desc',
        price: 19.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
      );

      expect(product1, equals(product2));
    });

    test('inequality works correctly', () {
      const product1 = SubscriptionProduct(
        id: 'test-1',
        title: 'Test',
        description: 'Desc',
        price: 19.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
      );

      const product2 = SubscriptionProduct(
        id: 'test-2',
        title: 'Test',
        description: 'Desc',
        price: 19.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
      );

      expect(product1, isNot(equals(product2)));
    });
  });

  group('SubscriptionProduct predefined', () {
    test('allProducts returns 4 plans', () {
      expect(SubscriptionProduct.allProducts.length, 4);
    });

    test('weekly plan has correct properties', () {
      expect(SubscriptionProduct.weekly.id, 'weekly');
      expect(SubscriptionProduct.weekly.price, 7.99);
      expect(SubscriptionProduct.weekly.billingPeriodDays, 7);
    });

    test('premium plan is featured', () {
      expect(SubscriptionProduct.premium.isFeatured, isTrue);
    });

    test('basic plan has correct price', () {
      expect(SubscriptionProduct.basic.price, 19.99);
    });

    test('premium VIP plan has correct price', () {
      expect(SubscriptionProduct.premiumVip.price, 54.99);
    });
  });
}
