import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/screens/cms/rich_text_helpers.dart';

void main() {
  group('wrapSelection', () {
    test('wraps selected text with bold markers', () {
      final controller = TextEditingController(text: 'Hello World');
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11);

      wrapSelection(controller, '**', '**');

      expect(controller.text, 'Hello **World**');
      // cursor lands after closing marker
      expect(controller.selection.baseOffset, 15);
    });

    test('wraps selected text with italic markers', () {
      final controller = TextEditingController(text: 'Hello World');
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);

      wrapSelection(controller, '*', '*');

      expect(controller.text, '*Hello* World');
      expect(controller.selection.baseOffset, 7);
    });

    test('wraps empty selection (cursor) — inserts markers with cursor after both', () {
      final controller = TextEditingController(text: 'abc');
      controller.selection = const TextSelection.collapsed(offset: 2);

      wrapSelection(controller, '**', '**');

      // With no selection, selected text is '' — we get '****' inserted at offset 2
      expect(controller.text, 'ab****c');
      // cursor lands after all 4 markers
      expect(controller.selection.baseOffset, 6);
    });

    test('does nothing when selection is invalid', () {
      final controller = TextEditingController(text: 'Hello');
      controller.selection = const TextSelection.collapsed(offset: -1);

      wrapSelection(controller, '**', '**');

      expect(controller.text, 'Hello');
    });
  });

  group('prefixLine', () {
    test('prepends prefix to first line when cursor is at position 0', () {
      final controller = TextEditingController(text: 'First line');
      controller.selection = const TextSelection.collapsed(offset: 0);

      prefixLine(controller, '> ');

      expect(controller.text, '> First line');
      expect(controller.selection.baseOffset, 2);
    });

    test('prepends prefix to current line when cursor is mid-line', () {
      final controller = TextEditingController(text: 'First line\nSecond line');
      // cursor at character 15 (inside 'Second line')
      controller.selection = const TextSelection.collapsed(offset: 15);

      prefixLine(controller, '1. ');

      expect(controller.text, 'First line\n1. Second line');
      expect(controller.selection.baseOffset, 18);
    });

    test('prepends prefix to second line when cursor is right after newline', () {
      final controller = TextEditingController(text: 'First line\nSecond line');
      // cursor at offset 11 — start of 'Second line'
      controller.selection = const TextSelection.collapsed(offset: 11);

      prefixLine(controller, '> ');

      expect(controller.text, 'First line\n> Second line');
      expect(controller.selection.baseOffset, 13);
    });

    test('prepends prefix to first line when cursor is at end of first line', () {
      final controller = TextEditingController(text: 'Hello\nWorld');
      controller.selection = const TextSelection.collapsed(offset: 5);

      prefixLine(controller, '1. ');

      expect(controller.text, '1. Hello\nWorld');
      expect(controller.selection.baseOffset, 8);
    });
  });

  group('setHeadingLevel', () {
    test('prepends H1 marker to a plain line', () {
      final controller = TextEditingController(text: 'Hello');
      controller.selection = const TextSelection.collapsed(offset: 0);

      setHeadingLevel(controller, 1);

      expect(controller.text, '# Hello');
    });

    test('prepends H2 marker to a plain line', () {
      final controller = TextEditingController(text: 'Hello');
      controller.selection = const TextSelection.collapsed(offset: 0);

      setHeadingLevel(controller, 2);

      expect(controller.text, '## Hello');
    });

    test('prepends H3 marker to a plain line', () {
      final controller = TextEditingController(text: 'Hello');
      controller.selection = const TextSelection.collapsed(offset: 0);

      setHeadingLevel(controller, 3);

      expect(controller.text, '### Hello');
    });

    test('replaces existing H1 with H2', () {
      final controller = TextEditingController(text: '# Hello');
      controller.selection = const TextSelection.collapsed(offset: 2);

      setHeadingLevel(controller, 2);

      expect(controller.text, '## Hello');
    });

    test('replaces existing H2 with H3', () {
      final controller = TextEditingController(text: '## Hello');
      controller.selection = const TextSelection.collapsed(offset: 3);

      setHeadingLevel(controller, 3);

      expect(controller.text, '### Hello');
    });

    test('replaces existing H3 with H1', () {
      final controller = TextEditingController(text: '### Hello');
      controller.selection = const TextSelection.collapsed(offset: 4);

      setHeadingLevel(controller, 1);

      expect(controller.text, '# Hello');
    });

    test('toggles off H1 when line already starts with H1', () {
      final controller = TextEditingController(text: '# Hello');
      controller.selection = const TextSelection.collapsed(offset: 2);

      setHeadingLevel(controller, 1);

      expect(controller.text, 'Hello');
    });

    test('toggles off H2 when line already starts with H2', () {
      final controller = TextEditingController(text: '## Hello');
      controller.selection = const TextSelection.collapsed(offset: 3);

      setHeadingLevel(controller, 2);

      expect(controller.text, 'Hello');
    });

    test('toggles off H3 when line already starts with H3', () {
      final controller = TextEditingController(text: '### Hello');
      controller.selection = const TextSelection.collapsed(offset: 4);

      setHeadingLevel(controller, 3);

      expect(controller.text, 'Hello');
    });

    test('works on second line of multi-line text', () {
      final controller = TextEditingController(text: 'First\nSecond');
      controller.selection = const TextSelection.collapsed(offset: 8);

      setHeadingLevel(controller, 2);

      expect(controller.text, 'First\n## Second');
    });
  });
}
