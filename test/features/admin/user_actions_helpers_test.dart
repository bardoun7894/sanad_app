// ignore_for_file: avoid_relative_lib_imports

/// Unit tests for pure-Dart helpers for user block/delete actions.
/// These helpers must be extractable top-level functions.
///
/// blockButtonLabel(isBlocked: bool, blockLabel: String, unblockLabel: String) -> String
/// blockButtonIcon(isBlocked: bool) -> IconData
///
/// These functions live in:
///   lib/features/admin/screens/clinic_patient_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sanad_app/features/admin/screens/clinic_patient_profile_screen.dart';

void main() {
  group('blockButtonLabel', () {
    test('returns unblockLabel when user is blocked', () {
      final label = blockButtonLabel(
        isBlocked: true,
        blockLabel: 'Block user',
        unblockLabel: 'Unblock user',
      );
      expect(label, 'Unblock user');
    });

    test('returns blockLabel when user is not blocked', () {
      final label = blockButtonLabel(
        isBlocked: false,
        blockLabel: 'Block user',
        unblockLabel: 'Unblock user',
      );
      expect(label, 'Block user');
    });
  });

  group('blockButtonIcon', () {
    test('returns lock_open_rounded icon when user is blocked', () {
      expect(blockButtonIcon(isBlocked: true), Icons.lock_open_rounded);
    });

    test('returns block_rounded icon when user is not blocked', () {
      expect(blockButtonIcon(isBlocked: false), Icons.block_rounded);
    });
  });
}
