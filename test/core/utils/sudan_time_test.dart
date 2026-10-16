import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/utils/sudan_time.dart';

void main() {
  test('sudanSlotInstant maps 19:00 Sudan to 17:00 UTC', () {
    final i = sudanSlotInstant(DateTime(2026, 10, 18), 19);
    expect(i, DateTime.utc(2026, 10, 18, 17));
    expect(i.isUtc, isTrue);
  });

  test('sudanSlotInstant at hour 0 rolls to previous UTC day', () {
    expect(sudanSlotInstant(DateTime(2026, 3, 1), 1), DateTime.utc(2026, 2, 28, 23));
  });

  test('toSudanWallClock adds 2 hours regardless of input zone', () {
    final w = toSudanWallClock(DateTime.utc(2026, 10, 18, 22, 30));
    expect([w.year, w.month, w.day, w.hour, w.minute], [2026, 10, 19, 0, 30]);
  });

  test('sudanToday uses UTC+2 date', () {
    final d = sudanToday(now: DateTime.utc(2026, 10, 16, 22, 30));
    expect([d.year, d.month, d.day], [2026, 10, 17]);
    final e = sudanToday(now: DateTime.utc(2026, 10, 16, 21, 59));
    expect([e.year, e.month, e.day], [2026, 10, 16]);
  });

  test('formatSudanTime ar/en/fr', () {
    final t = DateTime.utc(2026, 10, 18, 18); // 20:00 Sudan
    expect(formatSudanTime(t, 'ar'), '8:00 مساءً');
    expect(formatSudanTime(t, 'en'), '8:00 PM');
    expect(formatSudanTime(t, 'fr'), '20:00');
    expect(formatSudanTime(DateTime.utc(2026, 10, 18, 7), 'ar'), '9:00 صباحاً');
  });

  test('formatSudanDate ar/en/fr use Gregorian names', () {
    final t = DateTime.utc(2026, 10, 18, 17);
    expect(formatSudanDate(t, 'en'), contains('October'));
    expect(formatSudanDate(t, 'en'), contains('18'));
    expect(formatSudanDate(t, 'fr'), contains('octobre'));
    expect(formatSudanDate(t, 'ar'), contains('أكتوبر'));
  });
}
