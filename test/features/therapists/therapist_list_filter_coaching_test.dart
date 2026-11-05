import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/core/config/store_profile.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/features/therapist_portal/models/therapist_profile.dart';
import 'package:sanad_app/features/therapists/repositories/therapist_repository.dart';
import 'package:sanad_app/features/therapists/therapist_list_screen.dart';

/// Avoids touching Firestore: `implements` skips the real field initialisers.
class _FakeTherapistRepository implements TherapistRepository {
  @override
  Future<List<TherapistProfile>> getApprovedTherapists() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => appleCoachingBuildOverride = null);

  final s = S(AppLanguage.arabic);

  Future<void> openFilters(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(800, 1600));
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          therapistRepositoryProvider.overrideWithValue(
            _FakeTherapistRepository(),
          ),
          currentUserProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(home: TherapistListScreen()),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.tune_rounded));
    await t.pumpAndSettle();
  }

  testWidgets('specialty filter is shown off iOS', (t) async {
    appleCoachingBuildOverride = false;
    await openFilters(t);
    expect(find.text(s.specialties), findsOneWidget);
    expect(find.text(s.specialtyAnxiety), findsOneWidget);
    expect(find.text(s.specialtyDepression), findsOneWidget);
    expect(find.text(s.sessionTypes), findsOneWidget);
  });

  testWidgets('specialty filter is hidden on iOS, session types stay', (
    t,
  ) async {
    appleCoachingBuildOverride = true;
    await openFilters(t);
    expect(find.text(s.specialties), findsNothing);
    expect(find.text(s.specialtyAnxiety), findsNothing);
    expect(find.text(s.specialtyDepression), findsNothing);
    expect(find.text(s.sessionTypes), findsOneWidget);
  });
}
