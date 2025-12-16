import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SanadApp(),
      ),
    );

    // Wait for animations
    await tester.pumpAndSettle();

    // Verify that the home screen is displayed
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('How are you feeling today?'), findsOneWidget);
  });
}
