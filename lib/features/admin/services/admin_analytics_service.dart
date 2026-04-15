import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches average star rating across all therapists.
  /// Uses `therapists` collection (aligned with Laravel — M6.4).
  Future<Map<String, dynamic>> fetchTherapistRatings() async {
    try {
      // M6.4: Use `therapists` collection (same as Laravel AnalyticsService)
      // instead of `therapist_profiles` to ensure KPI parity.
      final snapshot = await _firestore
          .collection('therapists')
          .where('review_count', isGreaterThan: 0)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'average_rating': 0.0, 'review_count': 0};
      }

      int totalReviews = 0;
      double weightedTotal = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final reviews = (data['review_count'] as num?)?.toInt() ?? 0;

        if (reviews > 0) {
          weightedTotal += (rating * reviews);
          totalReviews += reviews;
        }
      }

      final average = totalReviews > 0 ? (weightedTotal / totalReviews) : 0.0;

      return {'average_rating': average, 'review_count': totalReviews};
    } catch (e) {
      return {'average_rating': 0.0, 'review_count': 0};
    }
  }

  /// Fetches average response speed from real chat data
  Future<String> fetchResponseSpeed() async {
    try {
      // 1. Get recent active chats
      final chatsSnapshot = await _firestore
          .collection('therapist_chats')
          .orderBy('last_message_time', descending: true)
          .limit(20)
          .get();

      if (chatsSnapshot.docs.isEmpty) {
        return 'N/A';
      }

      int totalResponseTimeSeconds = 0;
      int responseCount = 0;

      // 2. For each chat, sample the last few messages to find response pairs
      for (var chatDoc in chatsSnapshot.docs) {
        final messagesSnapshot = await chatDoc.reference
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(10) // Check last 10 messages per chat
            .get();

        final messages = messagesSnapshot.docs;

        for (int i = 0; i < messages.length - 1; i++) {
          final currentMsg = messages[i].data();
          final prevMsg = messages[i + 1].data();

          final currentSenderId = currentMsg['sender_id'] as String?;
          final prevSenderId = prevMsg['sender_id'] as String?;

          final chatUserId = chatDoc.data()['user_id'] as String?;

          if (chatUserId == null) continue;

          // Check if Current is Therapist (Response) and Prev is User (Question)
          final isTherapistResponse = currentSenderId != chatUserId;
          final isUserMessage = prevSenderId == chatUserId;

          if (isTherapistResponse && isUserMessage) {
            final responseTime = (currentMsg['timestamp'] as Timestamp)
                .toDate();
            final questionTime = (prevMsg['timestamp'] as Timestamp).toDate();

            final diffFn = responseTime.difference(questionTime).inSeconds;
            if (diffFn > 0 && diffFn < 86400) {
              // Filter outliers (>24h)
              totalResponseTimeSeconds += diffFn;
              responseCount++;
            }
          }
        }
      }

      if (responseCount == 0) {
        return 'N/A';
      }

      // 3. Calculate Average
      final avgSeconds = (totalResponseTimeSeconds / responseCount).round();

      // 4. Format Output
      if (avgSeconds < 60) {
        return '${avgSeconds}s';
      } else if (avgSeconds < 3600) {
        final minutes = avgSeconds ~/ 60;
        final seconds = avgSeconds % 60;
        return '${minutes}m ${seconds}s';
      } else {
        final hours = avgSeconds ~/ 3600;
        final minutes = (avgSeconds % 3600) ~/ 60;
        return '${hours}h ${minutes}m';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  /// Fetches session volume (counts per day/week).
  /// Already scoped by date range — no change needed.
  Future<List<Map<String, dynamic>>> fetchSessionVolume(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where(
            'scheduled_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('scheduled_time', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      // Group by day of week (1 = Mon, 7 = Sun)
      final Map<int, int> dayCounts = {};
      for (var doc in snapshot.docs) {
        final date = (doc.data()['scheduled_time'] as Timestamp).toDate();
        final day = date.weekday;
        dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      }

      // Convert to list for chart
      return List.generate(7, (index) {
        final day = index + 1;
        return {'day': day, 'count': dayCounts[day] ?? 0};
      });
    } catch (e) {
      return [];
    }
  }

  /// Fetches revenue stats — already scoped by date range.
  Future<List<Map<String, dynamic>>> fetchRevenue(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'completed')
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .get();

      // Group by month
      final Map<int, double> monthRevenue = {};
      for (var doc in snapshot.docs) {
        final date = (doc.data()['created_at'] as Timestamp).toDate();
        final month = date.month;
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        monthRevenue[month] = (monthRevenue[month] ?? 0) + amount;
      }

      // Return last 6 months
      final List<Map<String, dynamic>> results = [];
      for (int i = 5; i >= 0; i--) {
        final targetDate = DateTime(end.year, end.month - i, 1);
        final month = targetDate.month;
        results.add({
          'month': month,
          'year': targetDate.year,
          'revenue': monthRevenue[month] ?? 0.0,
        });
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  /// Fetches no-show rate — ALIGNED with Laravel (M6.4).
  ///
  /// Formula (both Flutter and Laravel):
  ///   no_show_rate = no_show_count / (no_show_count + completed_count) * 100
  ///
  /// Uses aggregate count() to avoid full-collection scan (M6.2).
  Future<double> fetchNoShowRate() async {
    try {
      // Use aggregate count queries instead of fetching all bookings (M6.2)
      final results = await Future.wait([
        _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'no_show')
            .count()
            .get(),
        _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'completed')
            .count()
            .get(),
      ]);

      final noShowCount = results[0].count ?? 0;
      final completedCount = results[1].count ?? 0;
      final total = noShowCount + completedCount;

      if (total == 0) return 0.0;
      return (noShowCount / total) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Fetches distribution of session types — uses aggregate counts (M6.2).
  Future<Map<String, int>> fetchSessionTypeDistribution() async {
    try {
      // Use aggregate count queries per type instead of full scan (M6.2)
      final types = ['video', 'audio', 'chat', 'in_person'];
      final counts = await Future.wait(
        types.map((type) => _firestore
            .collection('bookings')
            .where('session_type', isEqualTo: type)
            .count()
            .get()),
      );

      final Map<String, int> distribution = {};
      for (int i = 0; i < types.length; i++) {
        distribution[types[i]] = counts[i].count ?? 0;
      }
      return distribution;
    } catch (e) {
      return {};
    }
  }

  /// Fetches clinician performance (top therapists by completed sessions).
  /// Optimized: batch-fetch therapist names instead of N+1 (M6.2).
  Future<List<Map<String, dynamic>>> fetchClinicianPerformance() async {
    try {
      // Get completed bookings (limited to recent for performance)
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'completed')
          .orderBy('scheduled_time', descending: true)
          .limit(500)
          .get();

      // Count sessions per therapist
      final Map<String, int> sessionCounts = {};
      for (var doc in bookingsSnapshot.docs) {
        final therapistId = doc.data()['therapist_id'] as String?;
        if (therapistId != null) {
          sessionCounts[therapistId] = (sessionCounts[therapistId] ?? 0) + 1;
        }
      }

      if (sessionCounts.isEmpty) return [];

      // Sort and take top 5 therapist IDs
      final sortedEntries = sessionCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top5Entries = sortedEntries.take(5).toList();
      final top5Ids = top5Entries.map((e) => e.key).toList();

      // Batch-fetch therapist names in one query (M6.2 — fixes N+1)
      final therapistNames = <String, String>{};
      // Firestore `whereIn` supports up to 30 items — 5 is fine
      if (top5Ids.isNotEmpty) {
        final therapistsSnapshot = await _firestore
            .collection('therapists')
            .where(FieldPath.documentId, whereIn: top5Ids)
            .get();
        for (var doc in therapistsSnapshot.docs) {
          therapistNames[doc.id] =
              doc.data()['name'] as String? ?? 'Therapist';
        }
      }

      // Build performance list
      return top5Entries.map((entry) {
        return {
          'name': therapistNames[entry.key] ?? 'Therapist',
          'sessions': entry.value,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
