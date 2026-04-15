import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/auth/models/auth_user.dart';

void main() {
  final now = DateTime(2026, 1, 15, 10, 30);

  group('AuthUser', () {
    test('creates with required fields', () {
      final user = AuthUser(
        uid: 'uid-123',
        email: 'test@example.com',
        createdAt: now,
        provider: AuthProvider.email,
      );

      expect(user.uid, 'uid-123');
      expect(user.email, 'test@example.com');
      expect(user.provider, AuthProvider.email);
      expect(user.role, UserRole.user);
      expect(user.isProfileComplete, isFalse);
      expect(user.whatsappConsent, isFalse);
    });

    test('role helper getters work correctly', () {
      final user = AuthUser(
        uid: 'u1',
        email: 'test@test.com',
        createdAt: now,
        provider: AuthProvider.email,
        role: UserRole.therapist,
      );

      expect(user.isTherapist, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.isRegularUser, isFalse);
    });

    test('isGuest returns true for anonymous provider', () {
      final user = AuthUser(
        uid: 'u1',
        email: '',
        createdAt: now,
        provider: AuthProvider.anonymous,
      );

      expect(user.isGuest, isTrue);
    });

    test('copyWith creates updated copy', () {
      final user = AuthUser(
        uid: 'u1',
        email: 'old@test.com',
        createdAt: now,
        provider: AuthProvider.email,
      );

      final updated = user.copyWith(
        email: 'new@test.com',
        displayName: 'Test User',
      );

      expect(updated.email, 'new@test.com');
      expect(updated.displayName, 'Test User');
      expect(updated.uid, 'u1');
      expect(user.email, 'old@test.com');
    });

    test('toJson serializes correctly', () {
      final user = AuthUser(
        uid: 'u1',
        email: 'test@test.com',
        displayName: 'Test',
        createdAt: now,
        provider: AuthProvider.google,
        role: UserRole.admin,
        isProfileComplete: true,
      );

      final json = user.toJson();

      expect(json['uid'], 'u1');
      expect(json['email'], 'test@test.com');
      expect(json['displayName'], 'Test');
      expect(json['provider'], 'google');
      expect(json['role'], 'admin');
      expect(json['isProfileComplete'], true);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'uid': 'u1',
        'email': 'test@test.com',
        'displayName': 'Test',
        'provider': 'apple',
        'role': 'therapist',
        'isProfileComplete': true,
      };

      final user = AuthUser.fromJson(json);

      expect(user.uid, 'u1');
      expect(user.email, 'test@test.com');
      expect(user.provider, AuthProvider.apple);
      expect(user.role, UserRole.therapist);
      expect(user.isProfileComplete, isTrue);
    });

    test('fromJson defaults to email provider for unknown', () {
      final json = {
        'uid': 'u1',
        'email': 'test@test.com',
        'provider': 'unknown_provider',
      };

      final user = AuthUser.fromJson(json);
      expect(user.provider, AuthProvider.email);
    });

    test('fromJson defaults to user role for unknown', () {
      final json = {
        'uid': 'u1',
        'email': 'test@test.com',
        'role': 'unknown_role',
      };

      final user = AuthUser.fromJson(json);
      expect(user.role, UserRole.user);
    });
  });

  group('AuthUser.profileCompletionPercentage', () {
    test('returns 1.0 for guest users', () {
      final user = AuthUser(
        uid: 'u1',
        email: '',
        createdAt: now,
        provider: AuthProvider.anonymous,
      );

      expect(user.profileCompletionPercentage, 1.0);
    });

    test('returns 1.0 when profile is complete', () {
      final user = AuthUser(
        uid: 'u1',
        email: 'test@test.com',
        createdAt: now,
        provider: AuthProvider.email,
        isProfileComplete: true,
      );

      expect(user.profileCompletionPercentage, 1.0);
    });

    test('returns 0.0 for empty profile', () {
      final user = AuthUser(
        uid: 'u1',
        email: 'test@test.com',
        createdAt: now,
        provider: AuthProvider.email,
      );

      expect(user.profileCompletionPercentage, 0.0);
    });

    test('returns 1/3 when only name is set', () {
      final user = AuthUser(
        uid: 'u1',
        email: 'test@test.com',
        displayName: 'Test User',
        createdAt: now,
        provider: AuthProvider.email,
      );

      expect(user.profileCompletionPercentage, closeTo(1 / 3, 0.01));
    });

    test('returns 2/3 when name and phone are set', () {
      final user = AuthUser(
        uid: 'u1',
        email: 'test@test.com',
        displayName: 'Test User',
        phoneNumber: '+1234567890',
        createdAt: now,
        provider: AuthProvider.email,
      );

      expect(user.profileCompletionPercentage, closeTo(2 / 3, 0.01));
    });

    test('returns 1.0 when all fields are set', () {
      final user = AuthUser(
        uid: 'u1',
        email: 'test@test.com',
        displayName: 'Test User',
        phoneNumber: '+1234567890',
        matchingPreferences: {'gender': 'male'},
        createdAt: now,
        provider: AuthProvider.email,
      );

      expect(user.profileCompletionPercentage, 1.0);
    });
  });

  group('AuthProvider', () {
    test('has expected values', () {
      expect(AuthProvider.values.length, 5);
      expect(AuthProvider.email.name, 'email');
      expect(AuthProvider.google.name, 'google');
      expect(AuthProvider.apple.name, 'apple');
      expect(AuthProvider.phone.name, 'phone');
      expect(AuthProvider.anonymous.name, 'anonymous');
    });
  });

  group('UserRole', () {
    test('has expected values', () {
      expect(UserRole.values.length, 3);
      expect(UserRole.user.name, 'user');
      expect(UserRole.therapist.name, 'therapist');
      expect(UserRole.admin.name, 'admin');
    });
  });
}
