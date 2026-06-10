import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';

void main() {
  group('AuthNotifier.isStaleProfileDowngrade', () {
    test('ignores a snapshot that would downgrade a locally-complete profile',
        () {
      expect(
        AuthNotifier.isStaleProfileDowngrade(
          currentProfileComplete: true,
          incomingStatus: AuthStatus.profileIncomplete,
        ),
        isTrue,
      );
    });

    test('applies the snapshot when the local profile is not complete', () {
      expect(
        AuthNotifier.isStaleProfileDowngrade(
          currentProfileComplete: false,
          incomingStatus: AuthStatus.profileIncomplete,
        ),
        isFalse,
      );
    });

    test('applies the snapshot when local completion is unknown', () {
      expect(
        AuthNotifier.isStaleProfileDowngrade(
          currentProfileComplete: null,
          incomingStatus: AuthStatus.profileIncomplete,
        ),
        isFalse,
      );
    });

    test('applies a snapshot that confirms the profile is complete', () {
      expect(
        AuthNotifier.isStaleProfileDowngrade(
          currentProfileComplete: true,
          incomingStatus: AuthStatus.authenticated,
        ),
        isFalse,
      );
    });
  });
}
