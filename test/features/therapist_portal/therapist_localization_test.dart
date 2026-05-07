import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_profile.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';

void main() {
  // ---------------------------------------------------------------------------
  // TherapistProfile — localized accessors
  // ---------------------------------------------------------------------------
  group('TherapistProfile.localizedName', () {
    final base = TherapistProfile(
      id: 'p1',
      email: 'doc@example.com',
      name: 'الدكتور أحمد',
      createdAt: DateTime(2026, 1, 1),
    );

    test('returns nameEn for English locale when nameEn is set', () {
      final profile = base.copyWith(
        nameAr: 'الدكتور أحمد',
        nameEn: 'Dr. Ahmad',
        nameFr: 'Dr Ahmad (FR)',
      );
      expect(profile.localizedName('en'), 'Dr. Ahmad');
    });

    test('returns nameFr for French locale when nameFr is set', () {
      final profile = base.copyWith(
        nameAr: 'الدكتور أحمد',
        nameEn: 'Dr. Ahmad',
        nameFr: 'Dr Ahmad FR',
      );
      expect(profile.localizedName('fr'), 'Dr Ahmad FR');
    });

    test('returns nameAr for Arabic locale', () {
      final profile = base.copyWith(
        nameAr: 'الدكتور أحمد',
        nameEn: 'Dr. Ahmad',
      );
      expect(profile.localizedName('ar'), 'الدكتور أحمد');
    });

    test('falls back to legacy name when all localized variants are empty', () {
      // Simulates legacy Firestore doc with only the un-suffixed field
      final profile = TherapistProfile(
        id: 'legacy',
        email: 'doc@example.com',
        name: 'Legacy Name',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(profile.localizedName('en'), 'Legacy Name');
      expect(profile.localizedName('ar'), 'Legacy Name');
      expect(profile.localizedName('fr'), 'Legacy Name');
    });

    test('falls back to nameAr when nameEn is empty but nameAr is set', () {
      final profile = base.copyWith(
        nameAr: 'الدكتور أحمد',
        nameEn: '',
      );
      expect(profile.localizedName('en'), 'الدكتور أحمد');
    });

    test('falls back to nameAr when nameFr is empty but nameAr is set', () {
      final profile = base.copyWith(
        nameAr: 'الدكتور أحمد',
        nameFr: '',
      );
      expect(profile.localizedName('fr'), 'الدكتور أحمد');
    });
  });

  group('TherapistProfile.localizedBio', () {
    final base = TherapistProfile(
      id: 'p1',
      email: 'doc@example.com',
      name: 'Doc',
      bio: 'ترجمة بيو',
      createdAt: DateTime(2026, 1, 1),
    );

    test('returns bioEn for English locale', () {
      final profile = base.copyWith(
        bioAr: 'ترجمة بيو',
        bioEn: 'English bio',
      );
      expect(profile.localizedBio('en'), 'English bio');
    });

    test('falls back to legacy bio when all localized variants are empty', () {
      final profile = TherapistProfile(
        id: 'legacy',
        email: 'doc@example.com',
        name: 'Doc',
        bio: 'Legacy bio',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(profile.localizedBio('en'), 'Legacy bio');
    });
  });

  group('TherapistProfile.localizedTitle', () {
    final base = TherapistProfile(
      id: 'p1',
      email: 'doc@example.com',
      name: 'Doc',
      title: 'معالج نفسي',
      createdAt: DateTime(2026, 1, 1),
    );

    test('returns titleEn for English locale', () {
      final profile = base.copyWith(
        titleAr: 'معالج نفسي',
        titleEn: 'Psychotherapist',
      );
      expect(profile.localizedTitle('en'), 'Psychotherapist');
    });

    test('falls back to legacy title when all localized variants are empty', () {
      final profile = TherapistProfile(
        id: 'legacy',
        email: 'doc@example.com',
        name: 'Doc',
        title: 'Legacy Title',
        createdAt: DateTime(2026, 1, 1),
      );
      expect(profile.localizedTitle('en'), 'Legacy Title');
    });
  });

  // ---------------------------------------------------------------------------
  // TherapistProfile.fromJson — reads new suffixed fields
  // ---------------------------------------------------------------------------
  group('TherapistProfile.fromJson new localized fields', () {
    test('reads name_en, name_fr, name_ar from Firestore map', () {
      final json = {
        'id': 'p1',
        'email': 'doc@example.com',
        'name': 'الدكتور أحمد',
        'name_ar': 'الدكتور أحمد',
        'name_en': 'Dr. Ahmad',
        'name_fr': 'Dr Ahmad FR',
        'created_at': null,
      };
      final profile = TherapistProfile.fromJson(json);
      expect(profile.nameAr, 'الدكتور أحمد');
      expect(profile.nameEn, 'Dr. Ahmad');
      expect(profile.nameFr, 'Dr Ahmad FR');
    });

    test('defaults to empty string for missing localized fields (legacy doc)', () {
      final json = {
        'id': 'legacy',
        'email': 'doc@example.com',
        'name': 'Legacy Name',
        'created_at': null,
      };
      final profile = TherapistProfile.fromJson(json);
      expect(profile.nameAr, '');
      expect(profile.nameEn, '');
      expect(profile.nameFr, '');
      expect(profile.bioAr, '');
      expect(profile.bioEn, '');
      expect(profile.bioFr, '');
      expect(profile.titleAr, '');
      expect(profile.titleEn, '');
      expect(profile.titleFr, '');
    });
  });

  // ---------------------------------------------------------------------------
  // TherapistProfile.toFirestore — writes new + legacy fields
  // ---------------------------------------------------------------------------
  group('TherapistProfile.toFirestore new localized fields', () {
    test('writes all 9 localized fields', () {
      final profile = TherapistProfile(
        id: 'p1',
        email: 'doc@example.com',
        name: 'الدكتور أحمد',
        nameAr: 'الدكتور أحمد',
        nameEn: 'Dr. Ahmad',
        nameFr: 'Dr Ahmad FR',
        bio: 'بيو',
        bioAr: 'بيو',
        bioEn: 'Bio EN',
        bioFr: 'Bio FR',
        title: 'معالج',
        titleAr: 'معالج',
        titleEn: 'Therapist',
        titleFr: 'Thérapeute',
        createdAt: DateTime(2026, 1, 1),
      );
      final map = profile.toFirestore();
      expect(map['name_ar'], 'الدكتور أحمد');
      expect(map['name_en'], 'Dr. Ahmad');
      expect(map['name_fr'], 'Dr Ahmad FR');
      expect(map['bio_ar'], 'بيو');
      expect(map['bio_en'], 'Bio EN');
      expect(map['bio_fr'], 'Bio FR');
      expect(map['title_ar'], 'معالج');
      expect(map['title_en'], 'Therapist');
      expect(map['title_fr'], 'Thérapeute');
    });

    test('legacy name field is preserved for backward compat', () {
      final profile = TherapistProfile(
        id: 'p1',
        email: 'doc@example.com',
        name: 'الدكتور أحمد',
        nameAr: 'الدكتور أحمد',
        nameEn: 'Dr. Ahmad',
        createdAt: DateTime(2026, 1, 1),
      );
      final map = profile.toFirestore();
      // Legacy field must not be null/empty
      expect(map['name'], isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // TherapistProfile.toTherapist — plumbs localized fields through
  // ---------------------------------------------------------------------------
  group('TherapistProfile.toTherapist', () {
    test('propagates localized name/bio/title fields to Therapist', () {
      final profile = TherapistProfile(
        id: 'p1',
        email: 'doc@example.com',
        name: 'الدكتور أحمد',
        nameAr: 'الدكتور أحمد',
        nameEn: 'Dr. Ahmad',
        nameFr: 'Dr Ahmad FR',
        bio: 'بيو',
        bioAr: 'بيو',
        bioEn: 'Bio EN',
        bioFr: 'Bio FR',
        title: 'معالج',
        titleAr: 'معالج',
        titleEn: 'Therapist',
        titleFr: 'Thérapeute',
        createdAt: DateTime(2026, 1, 1),
      );
      final therapist = profile.toTherapist();
      expect(therapist.nameEn, 'Dr. Ahmad');
      expect(therapist.nameFr, 'Dr Ahmad FR');
      expect(therapist.bioEn, 'Bio EN');
      expect(therapist.titleEn, 'Therapist');
    });
  });

  // ---------------------------------------------------------------------------
  // Therapist — localized accessors (user-facing model)
  // ---------------------------------------------------------------------------
  group('Therapist.localizedName', () {
    const base = Therapist(
      id: 't1',
      name: 'الدكتور أحمد',
      title: 'معالج',
      bio: 'بيو',
      specialties: [],
      sessionTypes: [],
      rating: 4.5,
      reviewCount: 10,
      yearsExperience: 5,
      sessionPrice: 100,
      languages: [],
      qualifications: [],
    );

    test('returns nameEn for English locale', () {
      final t = Therapist(
        id: 't1',
        name: 'الدكتور أحمد',
        nameAr: 'الدكتور أحمد',
        nameEn: 'Dr. Ahmad',
        title: 'معالج',
        bio: 'بيو',
        specialties: const [],
        sessionTypes: const [],
        rating: 4.5,
        reviewCount: 10,
        yearsExperience: 5,
        sessionPrice: 100,
        languages: const [],
        qualifications: const [],
      );
      expect(t.localizedName('en'), 'Dr. Ahmad');
    });

    test('falls back to legacy name when no localized fields set', () {
      expect(base.localizedName('en'), 'الدكتور أحمد');
    });

    test('returns nameFr for French locale', () {
      final t = Therapist(
        id: 't1',
        name: 'الدكتور أحمد',
        nameAr: 'الدكتور أحمد',
        nameFr: 'Dr Ahmad FR',
        title: 'معالج',
        bio: 'بيو',
        specialties: const [],
        sessionTypes: const [],
        rating: 4.5,
        reviewCount: 10,
        yearsExperience: 5,
        sessionPrice: 100,
        languages: const [],
        qualifications: const [],
      );
      expect(t.localizedName('fr'), 'Dr Ahmad FR');
    });
  });

  group('Therapist.localizedBio', () {
    test('returns bioEn for English, falls back to legacy bio', () {
      const t = Therapist(
        id: 't1',
        name: 'Doc',
        title: 'T',
        bio: 'Legacy bio',
        specialties: [],
        sessionTypes: [],
        rating: 4.0,
        reviewCount: 0,
        yearsExperience: 1,
        sessionPrice: 50,
        languages: [],
        qualifications: [],
      );
      expect(t.localizedBio('en'), 'Legacy bio');
    });
  });

  group('Therapist.localizedTitle', () {
    test('returns titleEn for English, falls back to legacy title', () {
      const t = Therapist(
        id: 't1',
        name: 'Doc',
        title: 'Legacy title',
        bio: 'Bio',
        specialties: [],
        sessionTypes: [],
        rating: 4.0,
        reviewCount: 0,
        yearsExperience: 1,
        sessionPrice: 50,
        languages: [],
        qualifications: [],
      );
      expect(t.localizedTitle('en'), 'Legacy title');
    });
  });
}
