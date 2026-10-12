import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/chat/models/message.dart';
import 'package:sanad_app/features/chat/providers/chat_provider.dart';
import 'package:sanad_app/features/subscription/providers/feature_gating_provider.dart';

Message _user(DateTime at, [String id = 'u']) => Message(
  id: '$id-${at.microsecondsSinceEpoch}',
  content: 'hi',
  type: MessageType.user,
  timestamp: at,
);

Message _bot(DateTime at) => Message(
  id: 'b-${at.microsecondsSinceEpoch}',
  content: 'hello',
  type: MessageType.bot,
  timestamp: at,
);

void main() {
  final now = DateTime(2026, 10, 12, 15, 0);

  group('AI chat message limit', () {
    test('signed-in free user with empty history is NOT locked', () {
      final r = evaluateAiMessageLimit(
        userId: 'uid-1',
        tier: SubscriptionTier.free,
        messages: const [],
        now: now,
      );
      expect(r.limitReached, isFalse);
      expect(r.count, 0);
    });

    test('signed-in free user with only a bot welcome message is NOT locked',
        () {
      final r = evaluateAiMessageLimit(
        userId: 'uid-1',
        tier: SubscriptionTier.free,
        messages: [_bot(now)],
        now: now,
      );
      expect(r.limitReached, isFalse);
    });

    test('guest stays locked (guest limit is 0)', () {
      final r = evaluateAiMessageLimit(
        userId: null,
        tier: SubscriptionTier.free,
        messages: const [],
        now: now,
      );
      expect(r.limitReached, isTrue);
    });

    test('free user at the limit is locked, below it is not', () {
      final five = List.generate(
        5,
        (i) => _user(now.subtract(Duration(minutes: i + 1)), 'a$i'),
      );
      expect(
        evaluateAiMessageLimit(
          userId: 'uid-1',
          tier: SubscriptionTier.free,
          messages: five,
          now: now,
        ).limitReached,
        isTrue,
      );
      expect(
        evaluateAiMessageLimit(
          userId: 'uid-1',
          tier: SubscriptionTier.free,
          messages: five.take(4).toList(),
          now: now,
        ).limitReached,
        isFalse,
      );
    });

    test('free tier counts per DAY: yesterday messages do not count today', () {
      final yesterday = DateTime(2026, 10, 11, 23, 30);
      final old = List.generate(5, (i) => _user(yesterday, 'y$i'));
      final r = evaluateAiMessageLimit(
        userId: 'uid-1',
        tier: SubscriptionTier.free,
        messages: old,
        now: now,
      );
      expect(r.count, 0);
      expect(r.limitReached, isFalse);
    });

    test('paid tier keeps its monthly window (yesterday still counts)', () {
      final yesterday = DateTime(2026, 10, 11, 23, 30);
      final msgs = List.generate(50, (i) => _user(yesterday, 'w$i'));
      final r = evaluateAiMessageLimit(
        userId: 'uid-1',
        tier: SubscriptionTier.weekly, // 50 / month
        messages: msgs,
        now: now,
      );
      expect(r.count, 50);
      expect(r.limitReached, isTrue);
    });

    test('unlimited tier is never locked', () {
      final msgs = List.generate(500, (i) => _user(now, 'v$i'));
      final r = evaluateAiMessageLimit(
        userId: 'uid-1',
        tier: SubscriptionTier.premiumVip,
        messages: msgs,
        now: now,
      );
      expect(r.limitReached, isFalse);
    });
  });
}
