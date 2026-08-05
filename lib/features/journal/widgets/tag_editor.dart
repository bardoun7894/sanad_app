import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../l10n/journal_strings.dart';

/// Bottom sheet to add/remove tags. Returns the updated list, or null if
/// dismissed without changes.
Future<List<String>?> showTagEditor(
  BuildContext context, {
  required List<String> initial,
  required JournalStrings js,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceDark
        : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
    ),
    builder: (context) => _TagEditorSheet(initial: initial, js: js),
  );
}

class _TagEditorSheet extends StatefulWidget {
  final List<String> initial;
  final JournalStrings js;

  const _TagEditorSheet({required this.initial, required this.js});

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  late List<String> _tags;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final raw = _controller.text.trim().replaceAll('#', '');
    if (raw.isEmpty || _tags.contains(raw)) {
      _controller.clear();
      return;
    }
    setState(() {
      _tags.add(raw);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingXl,
        AppTheme.spacingXl,
        AppTheme.spacingXl,
        AppTheme.spacingXl + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.js.tags,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  decoration: InputDecoration(
                    hintText: widget.js.addTag,
                    prefixText: '#',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _add,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags
                .map(
                  (t) => Chip(
                    label: Text('#$t'),
                    onDeleted: () => setState(() => _tags.remove(t)),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    labelStyle: const TextStyle(color: AppColors.primary),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context, _tags),
              child: Text(
                widget.js.save,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
