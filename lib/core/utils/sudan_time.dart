/// Sudan (Africa/Khartoum) is a fixed UTC+2 with no DST. All booking times are
/// expressed in Sudan time; the device timezone is never consulted.
const Duration kSudanOffset = Duration(hours: 2);

/// Sudan calendar date (time fields zeroed). [now] is injectable for tests.
DateTime sudanToday({DateTime? now}) {
  final w = (now ?? DateTime.now()).toUtc().add(kSudanOffset);
  return DateTime(w.year, w.month, w.day);
}

/// The UTC instant at which [hour]:00 Sudan time occurs on [date]'s y/m/d.
DateTime sudanSlotInstant(DateTime date, int hour) =>
    DateTime.utc(date.year, date.month, date.day, hour - 2);

/// Sudan wall clock for [instant]. Use only the y/m/d/h/m fields.
DateTime toSudanWallClock(DateTime instant) =>
    instant.toUtc().add(kSudanOffset);

const _arMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];
const _enMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _frMonths = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// Date in Sudan time, e.g. "18 October 2026" / "18 أكتوبر 2026".
String formatSudanDate(DateTime instant, String locale) {
  final w = toSudanWallClock(instant);
  final i = w.month - 1;
  return switch (locale) {
    'ar' => '${w.day} ${_arMonths[i]} ${w.year}',
    'fr' => '${w.day} ${_frMonths[i]} ${w.year}',
    _ => '${_enMonths[i]} ${w.day}, ${w.year}',
  };
}

/// Time in Sudan time: "8:00 مساءً" / "8:00 PM" / "20:00".
String formatSudanTime(DateTime instant, String locale) {
  final w = toSudanWallClock(instant);
  final mm = w.minute.toString().padLeft(2, '0');
  if (locale == 'fr') return '${w.hour.toString().padLeft(2, '0')}:$mm';
  final h12 = w.hour % 12 == 0 ? 12 : w.hour % 12;
  final pm = w.hour >= 12;
  final suffix = locale == 'ar' ? (pm ? 'مساءً' : 'صباحاً') : (pm ? 'PM' : 'AM');
  return '$h12:$mm $suffix';
}
