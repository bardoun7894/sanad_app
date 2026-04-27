import 'package:flutter/material.dart';

/// Wraps the current selection in [controller] with [before] and [after].
/// If there is no valid selection, does nothing.
/// If the selection is collapsed (cursor only), wraps empty string — places
/// cursor immediately after the closing marker.
void wrapSelection(
    TextEditingController controller, String before, String after) {
  final sel = controller.selection;
  if (!sel.isValid) return;
  final text = controller.text;
  final selected = sel.textInside(text);
  final newText =
      text.replaceRange(sel.start, sel.end, '$before$selected$after');
  controller.value = controller.value.copyWith(
    text: newText,
    selection: TextSelection.collapsed(
        offset: sel.start + before.length + selected.length + after.length),
  );
}

/// Prepends [prefix] to the beginning of the line the cursor is currently on.
/// The cursor is moved forward by [prefix.length].
void prefixLine(TextEditingController controller, String prefix) {
  final sel = controller.selection;
  final text = controller.text;
  final lineStart =
      text.lastIndexOf('\n', sel.start > 0 ? sel.start - 1 : 0);
  final insertPos = lineStart < 0 ? 0 : lineStart + 1;
  final newText =
      text.substring(0, insertPos) + prefix + text.substring(insertPos);
  controller.value = controller.value.copyWith(
    text: newText,
    selection: TextSelection.collapsed(offset: sel.start + prefix.length),
  );
}

/// Sets the heading level (1–3) for the line the cursor is on.
///
/// If the line already starts with the exact heading marker for [level],
/// the marker is removed (toggle off). If it starts with a different heading
/// marker, that marker is replaced with the one for [level]. Otherwise the
/// marker is prepended.
void setHeadingLevel(TextEditingController controller, int level) {
  assert(level >= 1 && level <= 3, 'level must be 1, 2, or 3');
  final prefix = '${'#' * level} ';
  final sel = controller.selection;
  final text = controller.text;
  // Locate the start of the current line.
  final lineStart = () {
    final idx = text.lastIndexOf('\n', sel.start > 0 ? sel.start - 1 : 0);
    return idx < 0 ? 0 : idx + 1;
  }();

  // Detect any existing heading prefix at lineStart (longest first to avoid
  // matching '# ' when the line starts with '## ').
  String? existingPrefix;
  for (final p in ['### ', '## ', '# ']) {
    if (text.startsWith(p, lineStart)) {
      existingPrefix = p;
      break;
    }
  }

  final String newText;
  final int newCursorOffset;

  if (existingPrefix == prefix) {
    // Same level — toggle off: remove the prefix.
    final epLen = existingPrefix!.length;
    newText = text.substring(0, lineStart) +
        text.substring(lineStart + epLen);
    newCursorOffset = (sel.start - epLen).clamp(lineStart, text.length - epLen);
  } else if (existingPrefix != null) {
    // Different level — replace the existing prefix.
    final epLen = existingPrefix.length;
    newText = text.substring(0, lineStart) +
        prefix +
        text.substring(lineStart + epLen);
    final delta = prefix.length - epLen;
    newCursorOffset = sel.start + delta;
  } else {
    // No heading — prepend.
    newText = text.substring(0, lineStart) + prefix + text.substring(lineStart);
    newCursorOffset = sel.start + prefix.length;
  }

  controller.value = controller.value.copyWith(
    text: newText,
    selection: TextSelection.collapsed(offset: newCursorOffset.clamp(0, newText.length)),
  );
}
