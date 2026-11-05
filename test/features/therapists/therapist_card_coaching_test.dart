import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/config/store_profile.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/therapists/models/therapist.dart';
import 'package:sanad_app/features/therapists/widgets/therapist_card.dart';

void main() {
  tearDown(() => appleCoachingBuildOverride = null);

  final chip = S(AppLanguage.arabic).specialtyAnxiety;

  const therapist = Therapist(
    id: 't1',
    name: 'Test Name',
    nameEn: 'Test Name',
    title: 'Licensed psychologist',
    titleEn: 'Licensed psychologist',
    bio: 'bio',
    specialties: [Specialty.anxiety, Specialty.depression],
    sessionTypes: [SessionType.audio],
    rating: 4.5,
    reviewCount: 3,
    yearsExperience: 5,
    sessionPrice: 20,
    languages: ['ar'],
    qualifications: [],
  );

  Future<void> pump(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(800, 1600));
    await t.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TherapistCard(therapist: therapist, onTap: () {}),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('specialty chips and clinical title visible off iOS', (t) async {
    appleCoachingBuildOverride = false;
    await pump(t);
    expect(find.text('Licensed psychologist'), findsOneWidget);
    expect(find.text(chip), findsOneWidget);
  });

  testWidgets('specialty chips and clinical title hidden on iOS', (t) async {
    appleCoachingBuildOverride = true;
    await pump(t);
    expect(find.text('Licensed psychologist'), findsNothing);
    expect(find.text('Test Name'), findsOneWidget);
    expect(find.text(chip), findsNothing);
  });
}
