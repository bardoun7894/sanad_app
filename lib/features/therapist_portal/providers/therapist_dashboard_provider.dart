import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/therapist_profile.dart';
import '../models/therapist_booking.dart';
import '../services/therapist_auth_service.dart';
import '../services/therapist_booking_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'therapist_registration_provider.dart' show therapistAuthServiceProvider;
import '../../therapist_chat/models/therapist_chat.dart';
import '../../therapist_chat/services/therapist_chat_service.dart';

/// State for therapist dashboard
class TherapistDashboardState {
  final TherapistProfile? profile;
  final List<TherapistBooking> upcomingBookings;
  final List<TherapistBooking> pendingBookings;
  final List<TherapistBooking> todaysBookings;
  final List<TherapistChatThread> activeChats;
  final List<TherapistChatThread> urgentChats;
  final List<TherapistBooking> waitingQueue;
  final int totalSessions;
  final double totalEarnings;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  const TherapistDashboardState({
    this.profile,
    this.upcomingBookings = const [],
    this.pendingBookings = const [],
    this.todaysBookings = const [],
    this.activeChats = const [],
    this.urgentChats = const [],
    this.waitingQueue = const [],
    this.totalSessions = 0,
    this.totalEarnings = 0.0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  TherapistDashboardState copyWith({
    TherapistProfile? profile,
    List<TherapistBooking>? upcomingBookings,
    List<TherapistBooking>? pendingBookings,
    List<TherapistBooking>? todaysBookings,
    List<TherapistChatThread>? activeChats,
    List<TherapistChatThread>? urgentChats,
    List<TherapistBooking>? waitingQueue,
    int? totalSessions,
    double? totalEarnings,
    bool? isLoading,
    bool? isRefreshing,
    bool? useMockData,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TherapistDashboardState(
      profile: profile ?? this.profile,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      pendingBookings: pendingBookings ?? this.pendingBookings,
      todaysBookings: todaysBookings ?? this.todaysBookings,
      activeChats: activeChats ?? this.activeChats,
      urgentChats: urgentChats ?? this.urgentChats,
      waitingQueue: waitingQueue ?? this.waitingQueue,
      totalSessions: totalSessions ?? this.totalSessions,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Check if therapist is active
  bool get isActive => profile?.isActive ?? false;

  /// Check if there are pending requests
  bool get hasPendingRequests => pendingBookings.isNotEmpty;

  /// Check if there are urgent alerts
  bool get hasUrgentAlerts => urgentChats.isNotEmpty;

  /// Get number of active chats
  int get activeChatsCount => activeChats.length;

  /// Get number of pending requests
  int get pendingCount => pendingBookings.length;

  /// Get number of today's sessions
  int get todaysSessionCount => todaysBookings.length;

  /// Get number of urgent alerts
  int get urgentCount => urgentChats.length;

  /// Get total sessions
  int get displayTotalSessions => totalSessions;

  /// Get total earnings
  double get displayTotalEarnings => totalEarnings;

  /// Check if there are users in waiting queue
  bool get hasWaitingUsers => waitingQueue.isNotEmpty;
}

/// State notifier for therapist dashboard
class TherapistDashboardNotifier
    extends StateNotifier<TherapistDashboardState> {
  final TherapistAuthService _authService;
  final TherapistBookingService _bookingService;
  final TherapistChatService _chatService;
  final String _therapistId;

  StreamSubscription? _profileSubscription;
  StreamSubscription? _upcomingSubscription;
  StreamSubscription? _pendingSubscription;
  StreamSubscription? _todaysSubscription;
  StreamSubscription? _chatsSubscription;

  TherapistDashboardNotifier(
    this._authService,
    this._bookingService,
    this._chatService,
    this._therapistId,
  ) : super(const TherapistDashboardState()) {
    if (_therapistId.isNotEmpty) {
      _initialize();
    }
  }

  /// Initialize dashboard with real-time listeners
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Listen to profile changes
      _profileSubscription = _authService
          .getProfileStream(_therapistId)
          .listen(
            (profile) {
              state = state.copyWith(profile: profile, isLoading: false);
            },
            onError: (e) {
              state = state.copyWith(
                errorMessage: 'Failed to load profile',
                isLoading: false,
              );
            },
          );

      // Listen to upcoming bookings
      _upcomingSubscription = _bookingService
          .getUpcomingBookings(_therapistId)
          .listen((bookings) {
            state = state.copyWith(upcomingBookings: bookings);
          });

      // Listen to pending bookings
      _pendingSubscription = _bookingService
          .getPendingBookings(_therapistId)
          .listen((bookings) {
            state = state.copyWith(pendingBookings: bookings);
          });

      // Listen to today's bookings
      _todaysSubscription = _bookingService
          .getTodaysBookings(_therapistId)
          .listen((bookings) {
            state = state.copyWith(
              todaysBookings: bookings,
              // Waiting queue: confirmed bookings that haven't started yet
              waitingQueue: bookings
                  .where(
                    (b) =>
                        b.status == BookingStatus.confirmed &&
                        b.scheduledTime.isAfter(DateTime.now()),
                  )
                  .toList(),
            );
          });

      // Listen to active chats
      _chatsSubscription = _chatService
          .getChatsForTherapist(_therapistId)
          .listen((chats) {
            final now = DateTime.now();
            final tenMinutesAgo = now.subtract(const Duration(minutes: 10));

            // Filter urgent: unread by therapist AND last message > 10 mins ago
            final urgent = chats
                .where(
                  (chat) =>
                      chat.unreadCountTherapist > 0 &&
                      chat.lastMessageTime != null &&
                      chat.lastMessageTime!.isBefore(tenMinutesAgo),
                )
                .toList();

            state = state.copyWith(activeChats: chats, urgentChats: urgent);
          });

      // Load stats
      await _loadStats();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize dashboard',
      );
    }
  }

  /// Load booking statistics
  Future<void> _loadStats() async {
    try {
      final stats = await _bookingService.getBookingStats(_therapistId);
      final completedBookings = stats['completed_bookings'] as int? ?? 0;
      final earnings = stats['total_earnings'] as double? ?? 0.0;

      if (!mounted) return;
      state = state.copyWith(
        totalSessions: completedBookings,
        totalEarnings: earnings,
      );
    } catch (e) {
      debugPrint('Failed to load stats: $e');
    }
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    await _loadStats();
    if (!mounted) return;
    state = state.copyWith(isRefreshing: false);
  }

  /// Toggle active status
  Future<void> toggleActive() async {
    if (state.profile == null) return;

    final newStatus = !state.profile!.isActive;

    try {
      await _authService.toggleActive(_therapistId, newStatus);
      // State will be updated via stream listener
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to update status');
    }
  }

  /// Accept a booking request
  Future<void> acceptBooking(String bookingId) async {
    try {
      await _bookingService.acceptBooking(bookingId);
      // State will be updated via stream listener
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to accept booking');
    }
  }

  /// Reject a booking request
  Future<void> rejectBooking(String bookingId, String reason) async {
    try {
      await _bookingService.rejectBooking(bookingId, reason);
      // State will be updated via stream listener
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to reject booking');
    }
  }

  /// Complete a session
  Future<void> completeSession(String bookingId, {String? notes}) async {
    try {
      await _bookingService.completeSession(bookingId, notes: notes);
      if (!mounted) return;
      await _loadStats(); // Refresh stats after completion
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to complete session');
    }
  }

  /// Mark client as no-show
  Future<void> markNoShow(String bookingId) async {
    try {
      await _bookingService.markNoShow(bookingId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to mark no-show');
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _bookingService.cancelBooking(bookingId, reason);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to cancel booking');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _upcomingSubscription?.cancel();
    _pendingSubscription?.cancel();
    _todaysSubscription?.cancel();
    _chatsSubscription?.cancel();
    super.dispose();
  }
}

// Providers
final therapistBookingServiceProvider = Provider<TherapistBookingService>((
  ref,
) {
  return TherapistBookingService();
});

final therapistChatServiceProvider = Provider<TherapistChatService>((ref) {
  return TherapistChatService();
});

final therapistDashboardProvider =
    StateNotifierProvider<TherapistDashboardNotifier, TherapistDashboardState>((
      ref,
    ) {
      final authState = ref.watch(authProvider);
      final authService = ref.watch(therapistAuthServiceProvider);
      final bookingService = ref.watch(therapistBookingServiceProvider);
      final chatService = ref.watch(therapistChatServiceProvider);

      final therapistId = authState.user?.uid ?? '';

      return TherapistDashboardNotifier(
        authService,
        bookingService,
        chatService,
        therapistId,
      );
    });

/// Helper provider for therapist profile
final therapistProfileProvider = Provider<TherapistProfile?>((ref) {
  return ref.watch(therapistDashboardProvider).profile;
});

/// Helper provider for pending bookings count
final pendingBookingsCountProvider = Provider<int>((ref) {
  return ref.watch(therapistDashboardProvider).pendingCount;
});

/// Helper provider for today's sessions count
final todaysSessionsCountProvider = Provider<int>((ref) {
  return ref.watch(therapistDashboardProvider).todaysSessionCount;
});

/// Helper provider for therapist active status
final isTherapistActiveProvider = Provider<bool>((ref) {
  return ref.watch(therapistDashboardProvider).isActive;
});
