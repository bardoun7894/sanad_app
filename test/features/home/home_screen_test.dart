import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/features/home/home_screen.dart';
import 'package:sanad_app/core/theme/app_theme.dart';

Widget createTestableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.lightTheme, home: child),
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const HomeScreen()));

      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const HomeScreen()));

      await tester.pump();

      // Home screen should have scrollable content
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('selectedMoodProvider', () {
    test('initial value is null', () {
      final container = ProviderContainer();
      final mood = container.read(selectedMoodProvider);
      expect(mood, isNull);
      container.dispose();
    });
  });
}
