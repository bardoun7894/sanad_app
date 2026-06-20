import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/utils/user_display_name.dart';

void main() {
  group('resolveDisplayName', () {
    test('explicit display name wins', () {
      expect(
        resolveDisplayName(displayName: 'محمد البردوني'),
        'محمد البردوني',
      );
    });

    test('legacy "User" placeholder is ignored in favour of first/last', () {
      expect(
        resolveDisplayName(
            displayName: 'User', firstName: 'Sara', lastName: 'Ali'),
        'Sara Ali',
      );
    });

    test('first + last combine when no display name', () {
      expect(
        resolveDisplayName(firstName: 'Sara', lastName: 'Ali'),
        'Sara Ali',
      );
    });

    test('legacy "User" placeholder is never surfaced — resolves to null', () {
      expect(resolveDisplayName(displayName: 'User'), isNull);
      expect(resolveDisplayName(displayName: 'user'), isNull);
    });

    test('null when nothing present', () {
      expect(resolveDisplayName(), isNull);
    });
  });

  group('resolveDisplayNameFromUserDoc', () {
    test('reads display_name/name/full_name precedence and first/last', () {
      expect(
        resolveDisplayNameFromUserDoc({'name': 'Mona Dugag'}),
        'Mona Dugag',
      );
      expect(
        resolveDisplayNameFromUserDoc(
            {'first_name': 'Fahd', 'last_name': 'AlQahtani'}),
        'Fahd AlQahtani',
      );
      expect(resolveDisplayNameFromUserDoc({}), isNull);
    });
  });
}
