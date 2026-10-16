/// Booking notification types sent to a therapist (recipientRole == 'therapist').
const _therapistBookingTypes = {
  'new_booking',
  'booking_confirmed',
  'booking_cancelled',
  'booking_reminder',
};

/// Route for a therapist-targeted booking notification that carries a chatId,
/// or null so the caller keeps its existing type-based navigation.
String? therapistNotificationRoute(Map<String, dynamic> data) {
  final role = data['recipientRole'] ?? data['recipient_role'];
  final chatId = (data['chatId'] ?? data['chat_id']) as String?;
  if (role != 'therapist') return null;
  if (!_therapistBookingTypes.contains(data['type'])) return null;
  if (chatId == null || chatId.isEmpty) return null;
  return '/therapist/messages/$chatId';
}
