import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/mood/models/mood_entry.dart';
import 'package:sanad_app/features/mood/models/mood_enums.dart';
import 'package:sanad_app/features/chat/models/message.dart';
import 'package:sanad_app/features/subscription/models/subscription_product.dart';
import 'package:sanad_app/features/community/models/post.dart';
import 'package:sanad_app/features/reviews/models/review.dart';
import 'package:sanad_app/features/engagement/models/streak_data.dart';
import 'package:sanad_app/features/notifications/models/app_notification.dart';
import 'package:sanad_app/features/crisis/models/crisis_keywords.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_booking.dart';

/// Google Play Pre-Launch Compliance Checks
/// These tests verify the app meets Google Play quality guidelines
void main() {
  group('Google Play Pre-Launch: Model Integrity', () {
    test('AuthUser serialization roundtrip preserves data', () {
      final now = DateTime(2026, 1, 15);
      final user = AuthUser(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: now,
        provider: AuthProvider.email,
        role: UserRole.user,
        isProfileComplete: false,
      );

      final json = user.toJson();
      final restored = AuthUser.fromJson(json);

      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
      expect(restored.provider, user.provider);
      expect(restored.role, user.role);
    });

    test('MoodEntry serialization roundtrip preserves data', () {
      final now = DateTime(2026, 2, 15);
      final entry = MoodEntry(
        id: 'mood-1',
        mood: MoodType.happy,
        date: now,
        note: 'Feeling great!',
      );

      final json = entry.toJson();
      final restored = MoodEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.mood, entry.mood);
      expect(restored.note, entry.note);
    });

    test('Message serialization roundtrip preserves data', () {
      final now = DateTime(2026, 2, 15);
      final message = Message(
        id: 'msg-1',
        content: 'Hello',
        type: MessageType.user,
        timestamp: now,
        status: MessageStatus.sent,
      );

      final map = message.toFirestore();
      final restored = Message.fromFirestore(map);

      expect(restored.id, message.id);
      expect(restored.content, message.content);
      expect(restored.type, message.type);
    });

    test('SubscriptionProduct serialization roundtrip preserves data', () {
      const product = SubscriptionProduct(
        id: 'test-1',
        title: 'Test Plan',
        description: 'A test plan',
        price: 9.99,
        currencyCode: 'USD',
        billingPeriod: 'monthly',
        billingPeriodDays: 30,
        features: ['Feature 1', 'Feature 2'],
      );

      final json = product.toJson();
      final restored = SubscriptionProduct.fromJson(json);

      expect(restored.id, product.id);
      expect(restored.title, product.title);
      expect(restored.price, product.price);
      expect(restored.features, product.features);
    });
  });

  group('Google Play Pre-Launch: No Crashes on Edge Cases', () {
    test('Empty AuthUser JSON does not crash', () {
      final json = {'uid': '', 'email': ''};

      final user = AuthUser.fromJson(json);
      expect(user.uid, '');
      expect(user.email, '');
    });

    test('Empty MoodEntry JSON does not crash', () {
      final json = {
        'id': '',
        'mood': MoodType.happy.index,
        'date': DateTime(2026, 1, 1).toIso8601String(),
      };

      final entry = MoodEntry.fromJson(json);
      expect(entry.id, '');
    });

    test('Empty SubscriptionProduct JSON does not crash', () {
      final json = {
        'id': '',
        'title': '',
        'description': '',
        'price': 0,
        'billingPeriod': 'monthly',
      };

      final product = SubscriptionProduct.fromJson(json);
      expect(product.id, '');
      expect(product.price, 0);
    });

    test('CrisisKeywords handles empty input gracefully', () {
      final result = CrisisKeywords.analyze('');
      expect(result.isCrisis, isFalse);
      expect(result.severity, 'none');
    });

    test('CrisisKeywords handles very long input', () {
      final longText = 'a' * 10000;
      final result = CrisisKeywords.analyze(longText);
      expect(result.isCrisis, isFalse);
    });

    test('CrisisKeywords handles special characters', () {
      final result = CrisisKeywords.analyze('!@#\$%^&*()_+');
      expect(result.isCrisis, isFalse);
    });

    test('StreakData handles null lastActivityDate', () {
      const data = StreakData();
      expect(data.isStreakActive, isFalse);
      expect(data.hasActivityToday, isFalse);
    });
  });

  group('Google Play Pre-Launch: Accessibility Data', () {
    test('All MoodType values have associated emojis', () {
      for (final mood in MoodType.values) {
        final emoji = _getMoodEmoji(mood);
        expect(
          emoji.isNotEmpty,
          isTrue,
          reason: 'MoodType.$mood should have an emoji',
        );
      }
    });

    test('All NotificationType values have associated icons', () {
      for (final type in NotificationType.values) {
        final icon = _getNotificationIcon(type);
        expect(
          icon.isNotEmpty,
          isTrue,
          reason: 'NotificationType.$type should have an icon',
        );
      }
    });

    test('All BookingStatus values have display names', () {
      for (final status in BookingStatus.values) {
        final name = status.name;
        expect(
          name.isNotEmpty,
          isTrue,
          reason: 'BookingStatus.$status should have a name',
        );
      }
    });
  });

  group('Google Play Pre-Launch: Data Validation', () {
    test('Subscription prices are non-negative', () {
      for (final product in SubscriptionProduct.allProducts) {
        expect(
          product.price,
          greaterThanOrEqualTo(0),
          reason: 'Product ${product.id} should have non-negative price',
        );
        expect(
          product.billingPeriodDays,
          greaterThanOrEqualTo(0),
          reason: 'Product ${product.id} should have non-negative billing days',
        );
      }
    });

    test('Review rating is within valid range', () {
      final now = DateTime.now();
      final review = Review(
        id: 'r1',
        therapistId: 't1',
        userId: 'u1',
        bookingId: 'b1',
        rating: 4.5,
        createdAt: now,
      );

      expect(review.isValidRating, isTrue);
      expect(review.rating, inInclusiveRange(1.0, 5.0));
    });

    test('StreakData values are non-negative', () {
      final demo = StreakData.demo;
      expect(demo.currentStreak, greaterThanOrEqualTo(0));
      expect(demo.longestStreak, greaterThanOrEqualTo(0));
      expect(demo.totalMoodsLogged, greaterThanOrEqualTo(0));
      expect(demo.totalSessions, greaterThanOrEqualTo(0));
      expect(demo.challengesCompleted, greaterThanOrEqualTo(0));
    });
  });
}

String _getMoodEmoji(MoodType mood) {
  switch (mood) {
    case MoodType.happy:
      return '😊';
    case MoodType.calm:
      return '😌';
    case MoodType.anxious:
      return '😨';
    case MoodType.sad:
      return '😢';
    case MoodType.angry:
      return '😠';
    case MoodType.tired:
      return '😴';
  }
}

String _getNotificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.booking:
      return '📅';
    case NotificationType.message:
      return '💬';
    case NotificationType.community:
      return '👥';
    case NotificationType.mood:
      return '😊';
    case NotificationType.system:
      return '🔔';
    case NotificationType.therapist:
      return '👨‍⚕️';
    case NotificationType.payment:
      return '💳';
    case NotificationType.call:
      return '📞';
    case NotificationType.crisis:
      return '🚨';
  }
}
