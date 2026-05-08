// TDD tests for Phase 2a UI tasks (T4–T8)
//
// Tests cover pure-Dart helpers that are defined in production files.
// Widget/snackbar flows are validated via flutter analyze + manual QA.
//
// Note: assignmentButtonLabel was removed from therapist_profile_screen.dart
// when the "Choose as my therapist" / "Switch therapist" UI was removed from
// user mode (2026-05-08). Those tests have been removed accordingly.

import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/therapists/providers/therapist_assignment_provider.dart'
    show AssignmentSuccess, AssignmentPartialSuccess,
         AssignmentValidationError, assignmentResultToBool;

void main() {
  group('assignmentResultToBool (T6 pass-through helper)', () {
    test('AssignmentSuccess maps to true', () {
      expect(assignmentResultToBool(const AssignmentSuccess()), isTrue);
    });

    test('AssignmentPartialSuccess maps to true', () {
      expect(
        assignmentResultToBool(
          const AssignmentPartialSuccess(chatWriteFailed: true),
        ),
        isTrue,
      );
    });

    test('AssignmentValidationError maps to false', () {
      expect(
        assignmentResultToBool(
          const AssignmentValidationError(reason: 'therapist_not_found'),
        ),
        isFalse,
      );
    });
  });
}
