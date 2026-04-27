import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_profile.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';

void main() {
  group('TherapistProfile toFirestore', () {
    final profile = TherapistProfile(
      id: 'test-id',
      email: 'test@example.com',
      name: 'Dr. Test',
      bio: 'A bio',
      yearsExperience: 5,
      sessionPrice: 150.0,
      createdAt: DateTime(2026, 1, 1),
      approvalStatus: TherapistApprovalStatus.pending,
    );

    test('toFirestore includes all required fields', () {
      final map = profile.toFirestore();

      expect(map['email'], 'test@example.com');
      expect(map['name'], 'Dr. Test');
      expect(map['bio'], 'A bio');
      expect(map['years_experience'], 5);
      expect(map['session_price'], 150.0);
      expect(map['approval_status'], 'pending');
      expect(map['is_active'], false);
    });

    test('toFirestore serializes specialties as string list', () {
      final withSpecialties = profile.copyWith(
        specialties: [Specialty.anxiety, Specialty.depression],
      );
      final map = withSpecialties.toFirestore();

      expect(map['specialties'], isA<List>());
      expect(
        (map['specialties'] as List).contains('anxiety'),
        isTrue,
      );
    });

    test('toFirestore serializes languages correctly', () {
      final withLanguages = profile.copyWith(languages: ['Arabic', 'English']);
      final map = withLanguages.toFirestore();

      expect(map['languages'], ['Arabic', 'English']);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = profile.copyWith(name: 'Dr. Updated');
      expect(updated.id, 'test-id');
      expect(updated.email, 'test@example.com');
      expect(updated.name, 'Dr. Updated');
    });
  });

  group('TherapistApprovalStatus', () {
    test('all 4 statuses exist', () {
      expect(TherapistApprovalStatus.values.length, 4);
      expect(TherapistApprovalStatus.pending.name, 'pending');
      expect(TherapistApprovalStatus.approved.name, 'approved');
      expect(TherapistApprovalStatus.rejected.name, 'rejected');
      expect(TherapistApprovalStatus.suspended.name, 'suspended');
    });

    test('fromString handles all valid values', () {
      expect(
        TherapistApprovalStatusX.fromString('approved'),
        TherapistApprovalStatus.approved,
      );
      expect(
        TherapistApprovalStatusX.fromString('rejected'),
        TherapistApprovalStatus.rejected,
      );
      expect(
        TherapistApprovalStatusX.fromString('suspended'),
        TherapistApprovalStatus.suspended,
      );
      expect(
        TherapistApprovalStatusX.fromString(null),
        TherapistApprovalStatus.pending,
      );
    });
  });
}
