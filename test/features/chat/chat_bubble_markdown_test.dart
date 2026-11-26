import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/chat/models/message.dart';
import 'package:sanad_app/features/chat/widgets/chat_bubble.dart';

void main() {
  group('botMarkdownSpans', () {
    test('turns **bold** into bold runs without asterisks', () {
      final spans = botMarkdownSpans('Try **Box Breathing** now.');
      expect(spans.map((s) => s.text).join(), 'Try Box Breathing now.');
      expect(spans.where((s) => s.bold).map((s) => s.text), ['Box Breathing']);
    });

    test('turns markdown bullets and headings into plain text', () {
      final spans = botMarkdownSpans('## Steps\n* breathe in\n- hold');
      expect(spans.map((s) => s.text).join(), 'Steps\n• breathe in\n• hold');
    });

    test('leaves text without markdown untouched, including Arabic', () {
      const s = 'خذ نفساً عميقاً، 4 × 4 ثوانٍ.';
      expect(botMarkdownSpans(s).map((x) => x.text).join(), s);
      expect(botMarkdownSpans(s).any((x) => x.bold), isFalse);
    });

    test('an unmatched ** stays as typed', () {
      expect(botMarkdownSpans('a ** b').map((x) => x.text).join(), 'a ** b');
    });
  });

  testWidgets('bot bubble renders no literal asterisks; user bubble is verbatim',
      (tester) async {
    final now = DateTime(2026, 11, 27);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          ChatBubble(
            message: Message(
                id: 'b', content: 'Try **Box Breathing**', type: MessageType.bot, timestamp: now),
          ),
          ChatBubble(
            message: Message(
                id: 'u', content: 'I typed **this**', type: MessageType.user, timestamp: now),
          ),
        ]),
      ),
    ));
    expect(find.textContaining('**Box', findRichText: true), findsNothing);
    expect(find.textContaining('Box Breathing', findRichText: true), findsOneWidget);
    expect(find.text('I typed **this**'), findsOneWidget);
  });
}
