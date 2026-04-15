import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_booking_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapist_portal/models/therapist_booking.dart';

final userBookingServiceProvider = Provider<UserBookingService>((ref) {
  return UserBookingService();
});

final userUpcomingBookingsProvider = StreamProvider<List<TherapistBooking>>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final service = ref.watch(userBookingServiceProvider);
  return service.getUpcomingBookings(user.uid);
});

final userPastBookingsProvider = StreamProvider<List<TherapistBooking>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final service = ref.watch(userBookingServiceProvider);
  return service.getPastBookings(user.uid);
});

final hasBookedTherapistProvider = Provider.family<bool, String>((
  ref,
  therapistId,
) {
  final pastBookings = ref.watch(userPastBookingsProvider).valueOrNull ?? [];
  final upcomingBookings =
      ref.watch(userUpcomingBookingsProvider).valueOrNull ?? [];

  final allBookings = [...pastBookings, ...upcomingBookings];

  // Check if any booking matches the therapistId AND is not cancelled
  return allBookings.any(
    (b) => b.therapistId == therapistId && b.status != BookingStatus.cancelled,
  );
});
