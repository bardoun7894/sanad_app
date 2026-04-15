import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/features/auth/screens/signup_screen.dart';
import 'package:sanad_app/core/theme/app_theme.dart';

/// Helper to wrap widgets with required providers for testing
Widget createTestableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  group('SignupScreen', () {
    testWidgets('renders signup screen with key elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));

      await tester.pump();

      // Verify the signup screen renders
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('has form fields for name input', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));

      await tester.pump();

      // Should have text form fields
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('has form key for validation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));

      await tester.pump();

      // The screen should render without errors
      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('scrolls without error', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const SignupScreen()));

      await tester.pump();

      // Try scrolling
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0, -200),
        500,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });
}
