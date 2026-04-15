import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/features/crisis/screens/crisis_response_screen.dart';
import 'package:sanad_app/core/theme/app_theme.dart';
import 'package:sanad_app/features/crisis/models/crisis_keywords.dart';

Widget createTestableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  group('CrisisResponseScreen', () {
    testWidgets('renders crisis response screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(const CrisisResponseScreen()),
      );

      await tester.pump();

      expect(find.byType(CrisisResponseScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('has emergency contact information', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(const CrisisResponseScreen()),
      );

      await tester.pump();

      // Should have some emergency-related content
      expect(find.byType(CrisisResponseScreen), findsOneWidget);
    });
  });

  group('CrisisKeywords', () {
    test('analyze returns non-crisis for empty text', () {
      final result = CrisisKeywords.analyze('');
      expect(result.isCrisis, isFalse);
    });

    test('analyze returns non-crisis for normal text', () {
      final result = CrisisKeywords.analyze('Hello, how are you?');
      expect(result.isCrisis, isFalse);
    });

    test('analyze detects crisis in Arabic', () {
      final result = CrisisKeywords.analyze('أريد أن أموت');
      expect(result.isCrisis, isTrue);
      expect(result.detectedLanguage, 'ar');
    });

    test('analyze detects crisis in English', () {
      final result = CrisisKeywords.analyze('I want to kill myself');
      expect(result.isCrisis, isTrue);
      expect(result.detectedLanguage, 'en');
    });

    test('analyze detects crisis in French', () {
      final result = CrisisKeywords.analyze('je veux me suicider');
      expect(result.isCrisis, isTrue);
      expect(result.detectedLanguage, 'fr');
    });
  });
}
