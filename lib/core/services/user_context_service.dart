import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/mood/models/mood_enums.dart';
import '../../features/mood/models/mood_entry.dart';

/// Fetches and summarises user-specific data for RAG context injection into
/// the AI chatbot system prompt.
///
/// All queries are lightweight (limited, single-pass) to avoid slowing down
/// chat responses. Results are cached per session.
class UserContextService {
  final FirebaseFirestore _firestore;

  /// In-memory cache keyed by userId. Cleared when the service is recreated.
  final Map<String, Map<String, dynamic>> _cache = {};

  UserContextService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Build the full user context map. Cached after the first call per user.
  Future<Map<String, dynamic>> buildContext(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId]!;

    final results = await Future.wait([
      _moodSummary(userId),
      _testResultsSummary(userId),
      _streakSummary(userId),
      _sessionsSummary(userId),
      _subscriptionSummary(userId),
      _riskAnalysis(userId),
    ]);

    final ctx = <String, dynamic>{
      ...results[0],
      ...results[1],
      ...results[2],
      ...results[3],
      ...results[4],
      ...results[5],
    };

    _cache[userId] = ctx;
    return ctx;
  }

  /// Invalidate cache (e.g. when new data is logged).
  void invalidate(String userId) => _cache.remove(userId);

  // ── Mood Summary ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _moodSummary(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mood_entries')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      if (snapshot.docs.isEmpty) return {'moodSummary': 'No mood data yet.'};

      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        return MoodEntry.fromMap(data, doc.id);
      }).toList();

      // Recent 7-day entries
      final recent = entries
          .where((e) => e.date.isAfter(sevenDaysAgo))
          .toList();

      // Mood frequency (last 30)
      final freq = <MoodType, int>{};
      for (final e in entries) {
        freq[e.mood] = (freq[e.mood] ?? 0) + 1;
      }
      final dominant = freq.entries.reduce((a, b) => a.value > b.value ? a : b);

      // Average score (last 7 days)
      double? avgScore;
      String trend = 'stable';
      if (recent.length >= 2) {
        final scores = recent
            .map((e) => MoodMetadata.getMoodScore(e.mood))
            .toList();
        avgScore = scores.reduce((a, b) => a + b) / scores.length;

        // Trend: compare first half vs second half
        final half = scores.length ~/ 2;
        final firstAvg = scores.sublist(0, half).reduce((a, b) => a + b) / half;
        final secondAvg =
            scores.sublist(half).reduce((a, b) => a + b) /
            (scores.length - half);
        final diff = secondAvg - firstAvg;
        if (diff > 0.5) {
          trend = 'improving';
        } else if (diff < -0.5) {
          trend = 'declining';
        }
      }

      // Last entry note
      final lastNote = entries.first.note;

      return {
        'moodSummary':
            'Last 7 days: ${recent.length} entries. '
            'Dominant mood (30 days): ${dominant.key.name}. '
            'Average wellbeing score: ${avgScore?.toStringAsFixed(1) ?? "N/A"}/5. '
            'Trend: $trend.',
        'moodTrend': trend,
        'moodAvgScore': avgScore,
        'dominantMood': dominant.key.name,
        'totalMoodEntries': entries.length,
        'recentMoods': recent
            .take(5)
            .map((e) => '${e.mood.name} (${e.date.day}/${e.date.month})')
            .join(', '),
        if (lastNote != null && lastNote.isNotEmpty) 'lastMoodNote': lastNote,
      };
    } catch (e) {
      debugPrint('UserContextService._moodSummary error: $e');
      return {};
    }
  }

  // ── Test Results ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _testResultsSummary(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('test_results')
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) return {};

      final results = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'type': data['test_type'] as String? ?? '',
          'score': (data['total_score'] as num?)?.toInt() ?? 0,
          'interpretation': data['interpretation'] as String? ?? '',
          'date': (data['created_at'] as Timestamp?)?.toDate(),
        };
      }).toList();

      // Latest result per test type
      final latest = <String, Map<String, dynamic>>{};
      for (final r in results) {
        final type = r['type'] as String;
        if (!latest.containsKey(type)) latest[type] = r;
      }

      final summary = latest.entries
          .map((e) {
            final r = e.value;
            final date = r['date'] as DateTime?;
            final dateStr = date != null ? '${date.day}/${date.month}' : '';
            return '${e.key}: score ${r['score']} (${r['interpretation']}) on $dateStr';
          })
          .join('; ');

      return {'testResults': summary, 'testResultDetails': latest};
    } catch (e) {
      debugPrint('UserContextService._testResultsSummary error: $e');
      return {};
    }
  }

  // ── Streaks & Engagement ───────────────────────────────────────────────

  Future<Map<String, dynamic>> _streakSummary(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('engagement')
          .doc('streak')
          .get();

      if (!doc.exists) return {};

      final data = doc.data()!;
      return {
        'streakDays': data['current_streak'] as int? ?? 0,
        'longestStreak': data['longest_streak'] as int? ?? 0,
        'totalMoodsLogged': data['total_moods_logged'] as int? ?? 0,
        'totalSessions': data['total_sessions'] as int? ?? 0,
        'challengesCompleted': data['challenges_completed'] as int? ?? 0,
        'achievements':
            (data['achievements'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      };
    } catch (e) {
      debugPrint('UserContextService._streakSummary error: $e');
      return {};
    }
  }

  // ── Sessions / Bookings ────────────────────────────────────────────────

  Future<Map<String, dynamic>> _sessionsSummary(String userId) async {
    try {
      // Upcoming sessions
      final now = Timestamp.fromDate(DateTime.now());
      final upcomingSnap = await _firestore
          .collection('bookings')
          .where('client_id', isEqualTo: userId)
          .where('scheduled_time', isGreaterThanOrEqualTo: now)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('scheduled_time')
          .limit(3)
          .get();

      // Completed sessions count
      final completedSnap = await _firestore
          .collection('bookings')
          .where('client_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .count()
          .get();

      final upcoming = upcomingSnap.docs.map((doc) {
        final data = doc.data();
        final time = (data['scheduled_time'] as Timestamp?)?.toDate();
        final therapistName = data['therapist_name'] as String? ?? 'Therapist';
        final type = data['session_type'] as String? ?? '';
        final status = data['status'] as String? ?? '';
        return '$therapistName ($type, $status) on ${time?.day}/${time?.month} at ${time?.hour}:${time?.minute.toString().padLeft(2, '0')}';
      }).toList();

      return {
        'completedSessions': completedSnap.count ?? 0,
        'upcomingSessions': upcoming.isEmpty ? 'None' : upcoming.join('; '),
        'hasUpcomingSessions': upcoming.isNotEmpty,
      };
    } catch (e) {
      debugPrint('UserContextService._sessionsSummary error: $e');
      return {};
    }
  }

  // ── Subscription ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _subscriptionSummary(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return {};

      final data = doc.data()!;
      final subState = data['subscription_state'] as String? ?? 'free';
      final productId = data['subscription_product_id'] as String?;
      final expiry = (data['subscription_expiry'] as Timestamp?)?.toDate();

      return {
        'tier': _tierFromProductId(productId, subState),
        'subscriptionState': subState,
        if (expiry != null)
          'subscriptionExpiry': '${expiry.day}/${expiry.month}/${expiry.year}',
      };
    } catch (e) {
      debugPrint('UserContextService._subscriptionSummary error: $e');
      return {};
    }
  }

  String _tierFromProductId(String? productId, String state) {
    if (state == 'free' || productId == null) return 'free';
    if (productId.contains('vip')) return 'premiumVip';
    if (productId.contains('premium')) return 'premium';
    if (productId.contains('basic')) return 'basic';
    if (productId.contains('weekly')) return 'weekly';
    return 'free';
  }

  // ── Risk Analysis ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _riskAnalysis(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mood_entries')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
          )
          .orderBy('date', descending: true)
          .get();

      if (snapshot.docs.length < 3) return {'riskLevel': 'insufficient_data'};

      final scores = snapshot.docs.map((doc) {
        final moodIndex = (doc.data()['mood'] as int?) ?? 0;
        return MoodMetadata.getMoodScore(MoodType.values[moodIndex]);
      }).toList();

      final avgScore = scores.reduce((a, b) => a + b) / scores.length;

      // Trend: first half vs second half
      final half = scores.length ~/ 2;
      final firstAvg = scores.sublist(0, half).reduce((a, b) => a + b) / half;
      final secondAvg =
          scores.sublist(half).reduce((a, b) => a + b) / (scores.length - half);
      final trend = secondAvg - firstAvg;

      String riskLevel;
      if (avgScore < 2.0 || trend < -2.0) {
        riskLevel = 'critical';
      } else if (avgScore < 2.5 || trend < -1.5) {
        riskLevel = 'high';
      } else if (avgScore < 3.0 || trend < -1.0) {
        riskLevel = 'moderate';
      } else {
        riskLevel = 'low';
      }

      // Check for consecutive low-mood days
      int consecutiveLowDays = 0;
      for (final score in scores) {
        if (score <= 2) {
          consecutiveLowDays++;
        } else {
          break;
        }
      }

      final flags = <String>[];
      if (riskLevel == 'critical' || riskLevel == 'high') {
        flags.add(
          'RISK: User shows $riskLevel risk level (avgScore=${avgScore.toStringAsFixed(1)}, trend=${trend.toStringAsFixed(1)})',
        );
      }
      if (consecutiveLowDays >= 3) {
        flags.add(
          'WARNING: $consecutiveLowDays consecutive days of low mood (score<=2)',
        );
      }
      if (trend < -1.0) {
        flags.add(
          'DECLINING: Mood trend is declining (${trend.toStringAsFixed(1)})',
        );
      }

      return {
        'riskLevel': riskLevel,
        'riskAvgScore': avgScore,
        'riskTrend': trend,
        'consecutiveLowDays': consecutiveLowDays,
        if (flags.isNotEmpty) 'riskFlags': flags.join('; '),
      };
    } catch (e) {
      debugPrint('UserContextService._riskAnalysis error: $e');
      return {};
    }
  }
}
