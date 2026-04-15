import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_profile.dart';

void main() {
  final now = DateTime(2026, 1, 15);

  group('AuthState', () {
    test('creates with defaults', () {
      const state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isGoogleSigningIn, isFalse);
      expect(state.isPhoneSigningIn, isFalse);
      expect(state.userRole, isNull);
      expect(state.verificationId, isNull);
    });

    test('copyWith creates updated copy', () {
      const state = AuthState();
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: true,
      );

      expect(updated.status, AuthStatus.authenticated);
      expect(updated.isLoading, isTrue);
      expect(updated.user, isNull);
    });

    test('copyWith clears error when clearError is true', () {
      const state = AuthState(errorMessage: 'some error');
      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });

    test('copyWith clears verification when clearVerification is true', () {
      const state = AuthState(
        verificationId: 'verif-123',
        pendingPhoneNumber: '+1234567890',
      );
      final updated = state.copyWith(clearVerification: true);

      expect(updated.verificationId, isNull);
      expect(updated.pendingPhoneNumber, isNull);
    });

    test(
      'copyWith clears therapistStatus when clearTherapistStatus is true',
      () {
        const state = AuthState(
          therapistStatus: TherapistApprovalStatus.pending,
        );
        final updated = state.copyWith(clearTherapistStatus: true);

        expect(updated.therapistStatus, isNull);
      },
    );

    test('isAuthenticated returns true for authenticated status', () {
      const state = AuthState(status: AuthStatus.authenticated);
      expect(state.isAuthenticated, isTrue);
    });

    test(
      'needsProfileCompletion returns true for profileIncomplete status',
      () {
        const state = AuthState(status: AuthStatus.profileIncomplete);
        expect(state.needsProfileCompletion, isTrue);
      },
    );

    test('isInitial returns true for initial status', () {
      const state = AuthState(status: AuthStatus.initial);
      expect(state.isInitial, isTrue);
    });

    test('isTherapist returns true for therapist role', () {
      const state = AuthState(userRole: UserRole.therapist);
      expect(state.isTherapist, isTrue);
      expect(state.isAdmin, isFalse);
      expect(state.isRegularUser, isFalse);
    });

    test('isAdmin returns true for admin role', () {
      const state = AuthState(userRole: UserRole.admin);
      expect(state.isAdmin, isTrue);
      expect(state.isTherapist, isFalse);
    });

    test('isRegularUser returns true for user role or null', () {
      const stateNull = AuthState();
      expect(stateNull.isRegularUser, isTrue);

      const stateUser = AuthState(userRole: UserRole.user);
      expect(stateUser.isRegularUser, isTrue);
    });

    test('isApprovedTherapist returns correct state', () {
      const state = AuthState(
        userRole: UserRole.therapist,
        therapistStatus: TherapistApprovalStatus.approved,
      );
      expect(state.isApprovedTherapist, isTrue);
      expect(state.isPendingTherapist, isFalse);
      expect(state.isRejectedTherapist, isFalse);
      expect(state.isSuspendedTherapist, isFalse);
    });

    test('isPendingTherapist returns correct state', () {
      const state = AuthState(
        userRole: UserRole.therapist,
        therapistStatus: TherapistApprovalStatus.pending,
      );
      expect(state.isPendingTherapist, isTrue);
      expect(state.isApprovedTherapist, isFalse);
    });
  });

  group('AuthStatus', () {
    test('has expected values', () {
      expect(AuthStatus.values.length, 4);
      expect(AuthStatus.initial.name, 'initial');
      expect(AuthStatus.authenticated.name, 'authenticated');
      expect(AuthStatus.unauthenticated.name, 'unauthenticated');
      expect(AuthStatus.profileIncomplete.name, 'profileIncomplete');
    });
  });
}
