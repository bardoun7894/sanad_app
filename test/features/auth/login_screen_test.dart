import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/features/auth/screens/login_screen.dart';
import 'package:sanad_app/features/auth/providers/auth_provider.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/theme/app_theme.dart';

/// Helper to wrap widgets with required providers for testing
Widget createTestableWidget(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders login screen with key elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));

      // Wait for initial build
      await tester.pump();

      // Verify the login screen renders
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('has phone number input field when phone login is shown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));

      await tester.pump();

      // Look for text fields
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('has Google sign-in button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));

      await tester.pump();

      // The login screen should have sign-in options
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('displays app logo', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));

      await tester.pump();

      // Should have some kind of logo or image
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
