import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/admin_analytics_service.dart';

class AdminAnalyticsState {
  final bool isLoading;
  final double averageRating;
  final int totalReviews;
  final String responseSpeed;
  final List<Map<String, dynamic>> sessionVolume;
  final List<Map<String, dynamic>> revenue;
  final double noShowRate;
  final Map<String, int> sessionTypeDistribution;
  final List<Map<String, dynamic>> clinicianPerformance;

  const AdminAnalyticsState({
    this.isLoading = false,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.responseSpeed = '--',
    this.sessionVolume = const [],
    this.revenue = const [],
    this.noShowRate = 0.0,
    this.sessionTypeDistribution = const {},
    this.clinicianPerformance = const [],
  });

  AdminAnalyticsState copyWith({
    bool? isLoading,
    double? averageRating,
    int? totalReviews,
    String? responseSpeed,
    List<Map<String, dynamic>>? sessionVolume,
    List<Map<String, dynamic>>? revenue,
    double? noShowRate,
    Map<String, int>? sessionTypeDistribution,
    List<Map<String, dynamic>>? clinicianPerformance,
  }) {
    return AdminAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      responseSpeed: responseSpeed ?? this.responseSpeed,
      sessionVolume: sessionVolume ?? this.sessionVolume,
      revenue: revenue ?? this.revenue,
      noShowRate: noShowRate ?? this.noShowRate,
      sessionTypeDistribution:
          sessionTypeDistribution ?? this.sessionTypeDistribution,
      clinicianPerformance: clinicianPerformance ?? this.clinicianPerformance,
    );
  }
}

class AdminAnalyticsNotifier extends StateNotifier<AdminAnalyticsState> {
  final AdminAnalyticsService _service;

  AdminAnalyticsNotifier(this._service) : super(const AdminAnalyticsState()) {
    loadMetrics();
  }

  Future<void> loadMetrics() async {
    state = state.copyWith(isLoading: true);

    try {
      final now = DateTime.now();
      final startOf30Days = now.subtract(const Duration(days: 30));

      // Fetch all real metrics in parallel
      final results = await Future.wait([
        _service.fetchTherapistRatings(),
        _service.fetchResponseSpeed(),
        _service.fetchSessionVolume(startOf30Days, now),
        _service.fetchRevenue(now.subtract(const Duration(days: 180)), now),
        _service.fetchNoShowRate(),
        _service.fetchSessionTypeDistribution(),
        _service.fetchClinicianPerformance(),
      ]);

      final ratingsData = results[0] as Map<String, dynamic>;
      final speed = results[1] as String;
      final sessionVolume = results[2] as List<Map<String, dynamic>>;
      final revenue = results[3] as List<Map<String, dynamic>>;
      final noShowRate = results[4] as double;
      final sessionTypeDistribution = results[5] as Map<String, int>;
      final clinicianPerformance = results[6] as List<Map<String, dynamic>>;

      state = state.copyWith(
        isLoading: false,
        averageRating: ratingsData['average_rating'],
        totalReviews: ratingsData['review_count'],
        responseSpeed: speed,
        sessionVolume: sessionVolume,
        revenue: revenue,
        noShowRate: noShowRate,
        sessionTypeDistribution: sessionTypeDistribution,
        clinicianPerformance: clinicianPerformance,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        averageRating: 0.0,
        totalReviews: 0,
        responseSpeed: 'N/A',
        sessionVolume: [],
        revenue: [],
        noShowRate: 0.0,
        sessionTypeDistribution: {},
        clinicianPerformance: [],
      );
    }
  }

  Future<void> refresh() async {
    await loadMetrics();
  }
}

final adminAnalyticsProvider =
    StateNotifierProvider<AdminAnalyticsNotifier, AdminAnalyticsState>((ref) {
      return AdminAnalyticsNotifier(AdminAnalyticsService());
    });
