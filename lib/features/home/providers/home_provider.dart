import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../content/models/content_models.dart';
import '../../content/repositories/content_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/user_booking_service.dart';

final dailyQuoteProvider = FutureProvider<DailyQuote?>((ref) {
  ref.keepAlive();
  final repository = ref.watch(contentRepositoryProvider);
  return repository.getLatestQuote();
});

final featuredContentProvider = FutureProvider<List<ContentItem>>((ref) {
  ref.keepAlive();
  final repository = ref.watch(contentRepositoryProvider);
  return repository.getFeaturedContent();
});

/// Provider for the user's next upcoming session
final nextUpcomingSessionProvider = FutureProvider<UpcomingSession?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Future.value(null);

  final service = ref.watch(userBookingServiceProvider);
  return service.getNextUpcomingSession(user.uid);
});

/// Provider for all upcoming sessions stream
final upcomingSessionsStreamProvider = StreamProvider<List<UpcomingSession>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final service = ref.watch(userBookingServiceProvider);
  return service.getUpcomingSessionsStream(user.uid);
});
