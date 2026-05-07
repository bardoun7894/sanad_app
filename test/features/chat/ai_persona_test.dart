import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/chat/models/ai_persona.dart';

/// Tests verifying the AiPersona enum contract.
///
/// The backend expects exact snake_case id strings. A typo here causes a
/// silent server-side rejection, so these are the highest-value tests in
/// the persona feature.
void main() {
  group('AiPersona.id — backend contract strings', () {
    test('companion id is "companion"', () {
      expect(AiPersona.companion.id, 'companion');
    });

    test('coach id is "coach"', () {
      expect(AiPersona.coach.id, 'coach');
    });

    test('cbtTherapist id is "cbt_therapist"', () {
      expect(AiPersona.cbtTherapist.id, 'cbt_therapist');
    });

    test('mindfulnessGuide id is "mindfulness_guide"', () {
      expect(AiPersona.mindfulnessGuide.id, 'mindfulness_guide');
    });

    test('crisisCompanion id is "crisis_companion"', () {
      expect(AiPersona.crisisCompanion.id, 'crisis_companion');
    });
  });

  group('AiPersona.fromId — round-trip from backend id string', () {
    test('parses "companion"', () {
      expect(AiPersonaX.fromId('companion'), AiPersona.companion);
    });

    test('parses "cbt_therapist"', () {
      expect(AiPersonaX.fromId('cbt_therapist'), AiPersona.cbtTherapist);
    });

    test('parses "mindfulness_guide"', () {
      expect(AiPersonaX.fromId('mindfulness_guide'), AiPersona.mindfulnessGuide);
    });

    test('parses "crisis_companion"', () {
      expect(AiPersonaX.fromId('crisis_companion'), AiPersona.crisisCompanion);
    });

    test('unknown id defaults to companion', () {
      expect(AiPersonaX.fromId('unknown'), AiPersona.companion);
    });
  });

  group('AiPersona — all values have non-empty ids', () {
    test('every persona has a non-empty id', () {
      for (final p in AiPersona.values) {
        expect(p.id, isNotEmpty, reason: 'Persona $p has empty id');
      }
    });
  });
}
