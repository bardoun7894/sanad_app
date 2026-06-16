import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/admin_users_provider.dart';

AdminUser _user(String id, {DateTime? createdAt}) =>
    AdminUser(id: id, email: '$id@x.com', createdAt: createdAt);

void main() {
  group('sortUsersByCreatedAtDesc', () {
    test('orders newest first and puts null createdAt last', () {
      final users = [
        _user('a', createdAt: DateTime(2026, 1, 1)),
        _user('no_date_1'), // null createdAt
        _user('b', createdAt: DateTime(2026, 6, 1)),
        _user('no_date_2'), // null createdAt
        _user('c', createdAt: DateTime(2026, 3, 1)),
      ];

      sortUsersByCreatedAtDesc(users);

      // Dated docs come first, newest → oldest.
      expect(users[0].id, 'b'); // June
      expect(users[1].id, 'c'); // March
      expect(users[2].id, 'a'); // January
      // Null-createdAt docs (e.g. phone-only signups) are kept, placed last —
      // never dropped the way an orderBy('created_at') query would drop them.
      expect(users[3].id.startsWith('no_date'), isTrue);
      expect(users[4].id.startsWith('no_date'), isTrue);
    });

    test('handles empty and single-element lists', () {
      final empty = <AdminUser>[];
      sortUsersByCreatedAtDesc(empty);
      expect(empty, isEmpty);

      final single = [_user('only')];
      sortUsersByCreatedAtDesc(single);
      expect(single.single.id, 'only');
    });
  });

  group('AdminUser.fullName', () {
    test('prefers first+last over the legacy "User" placeholder', () {
      final u = AdminUser(
        id: '1',
        email: 'No Email',
        displayName: 'User',
        firstName: 'محمد',
        lastName: 'البردوني',
      );
      expect(u.fullName, 'محمد البردوني');
    });

    test('uses display_name when it is a real name', () {
      final u = AdminUser(id: '2', email: 'x', displayName: 'Sara Ali');
      expect(u.fullName, 'Sara Ali');
    });

    test('returns null when nothing usable exists', () {
      final u = AdminUser(id: '3', email: 'No Email');
      expect(u.fullName, isNull);
    });
  });

  group('isGuestUser', () {
    test('hides anonymous accounts', () {
      final u = AdminUser(id: 'g', email: 'No Email', authProvider: 'anonymous');
      expect(isGuestUser(u), isTrue);
    });

    test('hides not-yet-tagged guest (unknown provider, no email, no phone)', () {
      final u = AdminUser(id: 'g2', email: 'No Email', authProvider: 'unknown');
      expect(isGuestUser(u), isTrue);
    });

    test('keeps a Google user (has email)', () {
      final u = AdminUser(
          id: 'r1', email: 'real@gmail.com', authProvider: 'google');
      expect(isGuestUser(u), isFalse);
    });

    test('keeps a phone-only signup (has phone, no email)', () {
      final u = AdminUser(
          id: 'r2',
          email: 'No Email',
          phoneNumber: '+249123456789',
          authProvider: 'phone');
      expect(isGuestUser(u), isFalse);
    });

    test('keeps an incomplete Google user (email present, unknown provider)',
        () {
      // e.g. signed up with Google but never finished profile — still a real user.
      final u = AdminUser(id: 'r3', email: 'ola123@gmail.com');
      expect(isGuestUser(u), isFalse);
    });
  });
}
