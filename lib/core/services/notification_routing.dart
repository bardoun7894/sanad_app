import '../../routes/app_routes.dart';

/// Booking notification types sent to a therapist (recipientRole == 'therapist').
const _therapistBookingTypes = {
  'new_booking',
  'booking_confirmed',
  'booking_cancelled',
  'booking_reminder',
};

/// Route for a therapist-targeted booking notification that opens the booking detail,
/// or falls back to AppRoutes.therapistBookings if no bookingId is present.
/// Never routes to chat. Returns null for non-therapist role or non-booking notifications.
String? therapistNotificationRoute(Map<String, dynamic> data) {
  final role = data['recipientRole'] ?? data['recipient_role'];
  if (role != 'therapist') return null;
  if (!_therapistBookingTypes.contains(data['type'])) return null;
  final bookingId = (data['bookingId'] ?? data['booking_id']) as String?;
  if (bookingId != null && bookingId.isNotEmpty) {
    return '${AppRoutes.therapistBookingDetail}/$bookingId';
  }
  return AppRoutes.therapistBookings;
}
