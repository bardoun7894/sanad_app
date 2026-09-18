import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../admin/screens/cms/rich_text_helpers.dart';
import '../../mood/models/mood_enums.dart';
import '../l10n/journal_strings.dart';
import '../models/journal_entry.dart';
import '../../../routes/app_routes.dart';
import '../providers/journal_prompt_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/mood_advice_provider.dart';
import '../widgets/mood_pick_row.dart';
import '../widgets/tag_editor.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  final JournalEntry? existing;
  const JournalEntryScreen({super.key, this.existing});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  late final TextEditingController _controller;
  MoodType? _mood;
  List<String> _tags = [];
  bool _promptDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.body ?? '');
    _mood = widget.existing?.mood;
    _tags = List<String>.from(widget.existing?.tags ?? const []);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(JournalStrings js) async {
    final text = _controller.text.trim();
    if (text.isEmpty && _mood == null) {
      Navigator.pop(context);
      return;
    }
    await ref.read(journalProvider.notifier).upsert(
          id: widget.existing?.id,
          body: text,
          mood: _mood,
          tags: _tags,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(js.saved)),
    );
    context.pop();
  }

  Future<void> _delete(JournalStrings js) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(js.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(js.skip),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(js.delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true && widget.existing != null) {
      await ref.read(journalProvider.notifier).delete(widget.existing!.id);
      if (mounted) context.pop();
    }
  }

  /// Supportive advice card shown when a mood is selected. Advice text is
  /// admin-editable (mood_advice); negative moods also get an exercise CTA.
  Widget _moodAdvice(JournalStrings js, AppLanguage lang, Color ink) {
    final mood = _mood;
    if (mood == null) return const SizedBox.shrink();
    final adviceMap = ref.watch(moodAdviceProvider).valueOrNull;
    final entry = adviceMap?[mood.name];
    final text = entry?.localized(lang);
    final showExercise = negativeMoods.contains(mood);
    if ((text == null || text.isEmpty) && !showExercise) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  js.aGentleReminder,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (text != null && text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                text,
                style: TextStyle(fontSize: 14, height: 1.5, color: ink),
              ),
            ],
            if (showExercise) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.air, size: 18),
                  label: Text(js.tryExercise),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  onPressed: () => context.push(AppRoutes.exercises),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider).language;
    final js = JournalStrings(lang);
    final prompt = ref.watch(promptOfTheDayProvider);
    final date = widget.existing?.createdAt ?? DateTime.now();

    final bg = isDark ? AppColors.journalBgDark : AppColors.journalBgLight;
    final ink = isDark ? AppColors.journalInkDark : AppColors.journalInkLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          DateFormat.yMMMMd(lang.code).format(date),
          style: TextStyle(color: ink, fontSize: 16),
        ),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _delete(js),
            ),
          TextButton(
            onPressed: () => _save(js),
            child: Text(
              js.save,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacingSm),
                    MoodPickRow(
                      selected: _mood,
                      onChanged: (m) => setState(() => _mood = m),
                    ),
                    if (_mood != null) _moodAdvice(js, lang, ink),
                    if (prompt != null && !_promptDismissed) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          color: AppColors.journalAccent.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    js.promptOfDay,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.journalAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    prompt.localized(lang),
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  setState(() => _promptDismissed = true),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.close, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingLg),
                    TextField(
                      controller: _controller,
                      maxLines: null,
                      minLines: 8,
                      style: TextStyle(fontSize: 16, height: 1.6, color: ink),
                      decoration: InputDecoration(
                        hintText: js.startWriting,
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: ink.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _FormatToolbar(
              controller: _controller,
              js: js,
              tagCount: _tags.length,
              onTags: () async {
                final res = await showTagEditor(
                  context,
                  initial: _tags,
                  js: js,
                );
                if (res != null) setState(() => _tags = res);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatToolbar extends StatelessWidget {
  final TextEditingController controller;
  final JournalStrings js;
  final int tagCount;
  final VoidCallback onTags;

  const _FormatToolbar({
    required this.controller,
    required this.js,
    required this.tagCount,
    required this.onTags,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.journalSurfaceDark : AppColors.journalSurfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          _btn(Icons.format_list_bulleted,
              () => prefixLine(controller, '- ')),
          _btn(Icons.title, () => setHeadingLevel(controller, 2)),
          const Spacer(),
          Stack(
            children: [
              _btn(Icons.local_offer_outlined, onTags),
              if (tagCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '$tagCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 22),
      color: AppColors.textSecondary,
      onPressed: onTap,
    );
  }
}
