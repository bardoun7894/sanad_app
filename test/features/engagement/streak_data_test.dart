import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sanad_app/features/engagement/models/streak_data.dart';

void main() {
  group('StreakData', () {
    test('creates with defaults', () {
      const data = StreakData();

      expect(data.currentStreak, 0);
      expect(data.longestStreak, 0);
      expect(data.lastActivityDate, isNull);
      expect(data.totalMoodsLogged, 0);
      expect(data.totalSessions, 0);
      expect(data.challengesCompleted, 0);
      expect(data.achievements, isEmpty);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final data = StreakData(
        currentStreak: 7,
        longestStreak: 14,
        lastActivityDate: now,
        totalMoodsLogged: 20,
        totalSessions: 5,
        challengesCompleted: 3,
        achievements: ['first_mood', '7_day_streak'],
      );

      expect(data.currentStreak, 7);
      expect(data.longestStreak, 14);
      expect(data.totalMoodsLogged, 20);
      expect(data.achievements.length, 2);
    });

    test('isStreakActive returns true for today activity', () {
      final data = StreakData(lastActivityDate: DateTime.now());
      expect(data.isStreakActive, isTrue);
    });

    test('isStreakActive returns true for yesterday activity', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final data = StreakData(lastActivityDate: yesterday);
      expect(data.isStreakActive, isTrue);
    });

    test('isStreakActive returns false for old activity', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 3));
      final data = StreakData(lastActivityDate: oldDate);
      expect(data.isStreakActive, isFalse);
    });

    test('isStreakActive returns false when no activity', () {
      const data = StreakData();
      expect(data.isStreakActive, isFalse);
    });

    test('hasActivityToday returns true for today', () {
      final data = StreakData(lastActivityDate: DateTime.now());
      expect(data.hasActivityToday, isTrue);
    });

    test('hasActivityToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final data = StreakData(lastActivityDate: yesterday);
      expect(data.hasActivityToday, isFalse);
    });

    test('copyWith creates updated copy', () {
      const data = StreakData(currentStreak: 5);
      final updated = data.copyWith(currentStreak: 6, longestStreak: 10);

      expect(updated.currentStreak, 6);
      expect(updated.longestStreak, 10);
      expect(data.currentStreak, 5);
    });

    test('toJson serializes correctly', () {
      final now = DateTime(2026, 2, 15);
      final data = StreakData(
        currentStreak: 5,
        longestStreak: 10,
        lastActivityDate: now,
        totalMoodsLogged: 15,
        achievements: ['badge1'],
      );

      final json = data.toJson();

      expect(json['current_streak'], 5);
      expect(json['longest_streak'], 10);
      expect(json['last_activity'], isA<Timestamp>());
      expect(json['total_moods_logged'], 15);
      expect(json['achievements'], ['badge1']);
    });

    test('fromJson deserializes correctly', () {
      final now = DateTime(2026, 2, 15);
      final json = {
        'current_streak': 7,
        'longest_streak': 14,
        'last_activity': Timestamp.fromDate(now),
        'total_moods_logged': 20,
        'total_sessions': 3,
        'challenges_completed': 5,
        'achievements': ['badge1', 'badge2'],
      };

      final data = StreakData.fromJson(json);

      expect(data.currentStreak, 7);
      expect(data.longestStreak, 14);
      expect(data.totalMoodsLogged, 20);
      expect(data.achievements.length, 2);
    });

    test('fromJson handles missing fields with defaults', () {
      final data = StreakData.fromJson({});

      expect(data.currentStreak, 0);
      expect(data.longestStreak, 0);
      expect(data.lastActivityDate, isNull);
      expect(data.achievements, isEmpty);
    });

    test('demo provides sample data', () {
      final demo = StreakData.demo;

      expect(demo.currentStreak, 5);
      expect(demo.longestStreak, 12);
      expect(demo.totalMoodsLogged, 23);
      expect(demo.achievements.length, 2);
    });
  });
}
