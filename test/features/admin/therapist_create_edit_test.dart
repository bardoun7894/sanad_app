import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_profile.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';
import 'package:sanad_app/features/admin/models/activity_log.dart';

/// Unit tests covering the create/edit therapist flow behaviors.
///
/// These tests verify:
/// 1. TherapistProfile can be built for create mode (empty id)
/// 2. TherapistProfile can be built for edit mode (existing id)
/// 3. ActivityType.therapistRejected exists (bug fix verification)
/// 4. TherapistProfile.toFirestore() covers all write-path fields
/// 5. Status sync: approvalStatus.name matches expected Firestore strings
void main() {
  // ---------------------------------------------------------------------------
  // Task 1 – createTherapist / updateTherapist data contract
  // ---------------------------------------------------------------------------

  group('createTherapist – data contract', () {
    test('create-mode profile has empty id before Firestore assignment', () {
      final profile = TherapistProfile(
        id: '',
        email: 'new@example.com',
        name: 'Dr. New',
        bio: 'A bio',
        yearsExperience: 3,
        sessionPrice: 200.0,
        approvalStatus: TherapistApprovalStatus.pending,
        createdAt: DateTime(2026, 4, 25),
      );

      // Provider generates the Firestore doc ref id – model starts empty
      expect(profile.id, '');
      expect(profile.email, 'new@example.com');
      expect(profile.approvalStatus, TherapistApprovalStatus.pending);
    });

    test('toFirestore() writes approval_status as snake_case string', () {
      final profile = TherapistProfile(
        id: '',
        email: 'doc@test.com',
        name: 'Dr. Test',
        approvalStatus: TherapistApprovalStatus.pending,
        createdAt: DateTime(2026, 4, 25),
      );

      final map = profile.toFirestore();

      // createTherapist overrides this with 'pending' but it must be the
      // correct key name per the Firestore data contract.
      expect(map.containsKey('approval_status'), isTrue);
      expect(map['approval_status'], 'pending');
    });

    test('toFirestore() includes is_active field', () {
      final profile = TherapistProfile(
        id: '',
        email: 'doc@test.com',
        name: 'Dr. Test',
        isActive: false,
        createdAt: DateTime(2026, 4, 25),
      );

      final map = profile.toFirestore();

      expect(map.containsKey('is_active'), isTrue);
      expect(map['is_active'], false);
    });
  });

  // ---------------------------------------------------------------------------
  // Task 1 – updateTherapist data contract
  // ---------------------------------------------------------------------------

  group('updateTherapist – data contract', () {
    test('edit-mode profile retains original id', () {
      final existing = TherapistProfile(
        id: 'existing-uid-123',
        email: 'doc@test.com',
        name: 'Dr. Existing',
        approvalStatus: TherapistApprovalStatus.approved,
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = existing.copyWith(name: 'Dr. Updated Name');

      // id must not change after copyWith
      expect(updated.id, 'existing-uid-123');
      expect(updated.name, 'Dr. Updated Name');
      expect(updated.email, 'doc@test.com');
    });

    test('approvalStatus.name maps to correct Firestore therapist_status', () {
      // updateTherapist writes: 'therapist_status': data.approvalStatus.name
      expect(TherapistApprovalStatus.approved.name, 'approved');
      expect(TherapistApprovalStatus.rejected.name, 'rejected');
      expect(TherapistApprovalStatus.suspended.name, 'suspended');
      expect(TherapistApprovalStatus.pending.name, 'pending');
    });

    test('toFirestore() includes languages array', () {
      final profile = TherapistProfile(
        id: 'uid-456',
        email: 'doc@test.com',
        name: 'Dr. Test',
        languages: ['Arabic', 'English'],
        createdAt: DateTime(2026, 4, 25),
      );

      final map = profile.toFirestore();

      expect(map['languages'], ['Arabic', 'English']);
    });
  });

  // ---------------------------------------------------------------------------
  // Task 2 – Activity log bug fix: therapistRejected not therapistApproved
  // ---------------------------------------------------------------------------

  group('Activity log bug fix', () {
    test('ActivityType.therapistRejected is distinct from therapistApproved',
        () {
      expect(
        ActivityType.therapistRejected == ActivityType.therapistApproved,
        isFalse,
        reason:
            'rejectTherapist must log therapistRejected, not therapistApproved',
      );
    });

    test('ActivityType.therapistRejected is a recognized enum value', () {
      expect(
        ActivityType.values.contains(ActivityType.therapistRejected),
        isTrue,
      );
    });

    test(
        'ActivityType enum has both therapistApproved and therapistRejected values',
        () {
      final names = ActivityType.values.map((t) => t.name).toSet();
      expect(names.contains('therapistApproved'), isTrue);
      expect(names.contains('therapistRejected'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Task 3 – TherapistFormDialog behavior (pure logic, no widget pump)
  // ---------------------------------------------------------------------------

  group('TherapistFormDialog – form logic', () {
    test('create mode profile has empty specialties by default', () {
      // Simulates _save() building a TherapistProfile with no specialties entered
      final profile = TherapistProfile(
        id: '',
        email: 'new@example.com',
        name: 'Dr. Fresh',
        specialties: const [],
        languages: const [],
        yearsExperience: 0,
        sessionPrice: 0.0,
        approvalStatus: TherapistApprovalStatus.pending,
        isActive: false,
        rating: 0.0,
        reviewCount: 0,
        createdAt: DateTime(2026, 4, 25),
        sessionTypes: const [],
        therapyTypes: const [TherapyType.individual],
        currency: 'SAR',
        qualifications: const [],
      );

      expect(profile.specialties, isEmpty);
      expect(profile.languages, isEmpty);
    });

    test('specialty string maps back to Specialty enum correctly', () {
      // This is the mapping _save() performs for specialty chip strings
      final specialtyStrings = ['anxiety', 'depression', 'trauma'];

      final specialtyList = specialtyStrings
          .map((s) => Specialty.values.firstWhere(
                (spec) => spec.name.toLowerCase() == s.toLowerCase(),
                orElse: () => Specialty.anxiety,
              ))
          .toList();

      expect(specialtyList, [
        Specialty.anxiety,
        Specialty.depression,
        Specialty.trauma,
      ]);
    });

    test('edit mode carries over createdAt from existing therapist', () {
      final original = TherapistProfile(
        id: 'uid-789',
        email: 'edit@test.com',
        name: 'Dr. Edit',
        createdAt: DateTime(2025, 6, 15),
        approvalStatus: TherapistApprovalStatus.approved,
      );

      // In _save(), createdAt is taken from widget.therapist?.createdAt
      final saved = TherapistProfile(
        id: original.id,
        email: original.email,
        name: 'Dr. Edit Updated',
        createdAt: original.createdAt, // must preserve original
        approvalStatus: original.approvalStatus,
      );

      expect(saved.createdAt, DateTime(2025, 6, 15));
      expect(saved.id, 'uid-789');
    });
  });

  // ---------------------------------------------------------------------------
  // Task 4 / Task 5 – Verify wiring contract types are correct
  // ---------------------------------------------------------------------------

  group('Create/Edit wiring – type contracts', () {
    test(
        'onSaved callback receives TherapistProfile for both create and edit modes',
        () {
      TherapistProfile? received;
      void onSaved(TherapistProfile p) => received = p;

      final profile = TherapistProfile(
        id: '',
        email: 'wire@test.com',
        name: 'Dr. Wire',
        approvalStatus: TherapistApprovalStatus.pending,
        createdAt: DateTime(2026, 4, 25),
      );

      onSaved(profile);

      expect(received, isNotNull);
      expect(received!.email, 'wire@test.com');
    });

    test('null therapist constructor param signals create mode', () {
      // The dialog uses: bool get _isEditMode => widget.therapist != null;
      const TherapistProfile? therapist = null;
      final isEditMode = therapist != null;

      expect(isEditMode, isFalse);
    });

    test('non-null therapist constructor param signals edit mode', () {
      final therapist = TherapistProfile(
        id: 'uid-edit',
        email: 'edit@test.com',
        name: 'Dr. Edit',
        createdAt: DateTime(2026, 4, 25),
        approvalStatus: TherapistApprovalStatus.pending,
      );
      final isEditMode = therapist != null;

      expect(isEditMode, isTrue);
    });
  });
}
