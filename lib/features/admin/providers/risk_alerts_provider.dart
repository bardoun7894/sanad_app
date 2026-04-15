import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dashboard/risk_alerts_panel.dart';
import '../../mood/models/mood_enums.dart';

/// Provider for risk alerts (patients with high/critical risk levels).
///
/// M6.2: Fixed N+1 user fetch — now batch-fetches user names in one query.
/// M6.4: Risk classification aligned with Laravel RiskAlertService:
///   - critical: avgMood >= 3.5  (or sharp decline trend < -2.0)
///   - high:     avgMood >= 2.5  (or moderate decline trend < -1.5)
///   - moderate: avgMood >= 1.5  (or slight decline trend < -1.0)
///   - low:      avgMood < 1.5
///
/// NOTE: This provider requires Firestore security rules to allow admin users
/// to perform collectionGroup queries on 'mood_entries'. Example rule:
///   match /{path=**}/mood_entries/{entryId} {
///     allow read: if request.auth != null && request.auth.token.admin == true;
///   }
/// Also requires a composite index on collectionGroup 'mood_entries' with
/// field 'date' descending.
final riskAlertsProvider = StreamProvider<List<RiskAlert>>((ref) {
  final firestore = FirebaseFirestore.instance;

  return firestore
      .collectionGroup('mood_entries')
      .orderBy('date', descending: true)
      .limit(100)
      .snapshots(includeMetadataChanges: false)
      .asyncMap((snapshot) async {
        // Process mood entries to detect risk patterns
        final alerts = <RiskAlert>[];
        final processedUsers = <String>{};

        // Group mood entries by user
        final entriesByUser = <String, List<Map<String, dynamic>>>{};

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final userId = doc.reference.parent.parent?.id;

          if (userId != null) {
            entriesByUser.putIfAbsent(userId, () => []);
            entriesByUser[userId]!.add({
              ...data,
              'timestamp':
                  (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          }
        }

        // Collect user IDs that need alerts (pre-pass to batch-fetch names)
        final alertCandidates = <String, _AlertCandidate>{};

        // Analyze each user's mood pattern
        for (final entry in entriesByUser.entries) {
          final userId = entry.key;
          if (processedUsers.contains(userId)) continue;

          final moodEntries = entry.value;
          if (moodEntries.isEmpty) continue;

          // Sort by timestamp
          moodEntries.sort(
            (a, b) => (b['timestamp'] as DateTime).compareTo(
              a['timestamp'] as DateTime,
            ),
          );

          // Check for declining mood (last 7 days)
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          final recentEntries = moodEntries
              .where((e) => (e['timestamp'] as DateTime).isAfter(sevenDaysAgo))
              .toList();

          if (recentEntries.length >= 3) {
            // Analyze mood trend
            final moodValues = recentEntries.map((e) {
              final moodIndex = (e['mood'] as int?) ?? 0;
              return _moodToScore(moodIndex);
            }).toList();

            // Calculate trend (negative = declining)
            final avgFirst =
                moodValues
                    .take(moodValues.length ~/ 2)
                    .reduce((a, b) => a + b) /
                (moodValues.length ~/ 2);
            final avgLast =
                moodValues
                    .skip(moodValues.length ~/ 2)
                    .reduce((a, b) => a + b) /
                (moodValues.length - moodValues.length ~/ 2);
            final trend = avgLast - avgFirst;

            // If declining significantly, create alert candidate
            if (trend < -1.0) {
              final avgScore =
                  moodValues.reduce((a, b) => a + b) / moodValues.length;

              alertCandidates[userId] = _AlertCandidate(
                userId: userId,
                level: _scoreToRiskLevel(avgScore, trend),
                daysCount: recentEntries.length,
                lastUpdated: recentEntries.first['timestamp'] as DateTime,
              );

              processedUsers.add(userId);
            }
          }

          // Limit to top 10 alerts
          if (alertCandidates.length >= 10) break;
        }

        if (alertCandidates.isEmpty) return alerts;

        // M6.2: Batch-fetch all user names in ONE query instead of N+1
        final userIds = alertCandidates.keys.toList();
        final userNames = <String, String>{};

        // Firestore `whereIn` supports up to 30 items — we have max 10
        if (userIds.isNotEmpty) {
          try {
            final usersSnapshot = await firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: userIds)
                .get();
            for (final doc in usersSnapshot.docs) {
              userNames[doc.id] =
                  doc.data()['full_name'] as String? ?? 'Patient';
            }
          } catch (e) {
            debugPrint('Failed to batch-fetch user names: $e');
          }
        }

        // Build final alerts with names
        for (final candidate in alertCandidates.values) {
          alerts.add(
            RiskAlert(
              patientId: candidate.userId,
              patientName: userNames[candidate.userId] ?? 'Patient',
              level: candidate.level,
              daysCount: candidate.daysCount,
              lastUpdated: candidate.lastUpdated,
            ),
          );
        }

        // Sort by risk level (critical first)
        alerts.sort((a, b) {
          final levelOrder = {
            RiskLevel.critical: 0,
            RiskLevel.high: 1,
            RiskLevel.moderate: 2,
            RiskLevel.low: 3,
          };
          return levelOrder[a.level]!.compareTo(levelOrder[b.level]!);
        });

        return alerts;
      })
      .handleError((error) {
        debugPrint('Error loading risk alerts: $error');
        return <RiskAlert>[];
      });
});

/// Temporary holder for alert data before user names are fetched.
class _AlertCandidate {
  final String userId;
  final RiskLevel level;
  final int daysCount;
  final DateTime lastUpdated;

  _AlertCandidate({
    required this.userId,
    required this.level,
    required this.daysCount,
    required this.lastUpdated,
  });
}

/// Convert mood index to numeric score (higher = better).
/// Aligned with Laravel RiskAlertService mood scale (M6.4):
///   0=happy(5), 1=calm(4), 2=anxious(2), 3=sad(1), 4=angry(1), 5=tired(2)
int _moodToScore(int moodIndex) {
  if (moodIndex < 0 || moodIndex >= MoodType.values.length) {
    return 3;
  }

  switch (MoodType.values[moodIndex]) {
    case MoodType.happy:
      return 5;
    case MoodType.calm:
      return 4;
    case MoodType.anxious:
    case MoodType.tired:
      return 2;
    case MoodType.sad:
    case MoodType.angry:
      return 1;
  }
}

/// Determine risk level based on average score and trend.
///
/// M6.4 — Aligned with Laravel RiskAlertService::calculateRiskLevel().
/// Laravel uses raw mood index (0-5, higher = more negative).
/// Flutter uses inverted score (1-5, higher = better).
///
/// Equivalent thresholds (Flutter score ↔ Laravel avgMood):
///   critical: score < 2.0 OR trend < -2.0  ↔  avgMood >= 3.5
///   high:     score < 2.5 OR trend < -1.5  ↔  avgMood >= 2.5
///   moderate: score < 3.0 OR trend < -1.0  ↔  avgMood >= 1.5
///   low:      score >= 3.0                 ↔  avgMood < 1.5
RiskLevel _scoreToRiskLevel(double avgScore, double trend) {
  // Critical: Very low score OR sharp decline
  if (avgScore < 2.0 || trend < -2.0) {
    return RiskLevel.critical;
  }

  // High: Low score OR moderate decline
  if (avgScore < 2.5 || trend < -1.5) {
    return RiskLevel.high;
  }

  // Moderate: Below average or slight decline
  if (avgScore < 3.0 || trend < -1.0) {
    return RiskLevel.moderate;
  }

  // Low: Good scores and stable/improving
  return RiskLevel.low;
}
