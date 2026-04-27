import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../providers/psych_tests_admin_provider.dart';
import '../../../content/models/psychological_test.dart';

class PsychTestsManagementScreen extends ConsumerWidget {
  const PsychTestsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(psychTestsAdminProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : AppColors.textPrimary);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:
            Text('Psychological Tests', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: () =>
                ref.read(psychTestsAdminProvider.notifier).load(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showTestDialog(context, ref, isDark, textColor),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _buildBody(context, ref, state, textColor, isDark),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PsychTestsAdminState state,
    Color textColor,
    bool isDark,
  ) {
    if (state.isLoading && state.tests.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: AppColors.error.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Error loading tests',
                style: TextStyle(color: textColor, fontSize: 16)),
            const SizedBox(height: 8),
            Text(state.error!,
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.5), fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () =>
                  ref.read(psychTestsAdminProvider.notifier).load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined,
                size: 64, color: textColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No psychological tests yet',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.5), fontSize: 16)),
            const SizedBox(height: 8),
            Text('Tap + to add a test',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.3), fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.tests.length,
      itemBuilder: (context, index) {
        final test = state.tests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            color: isDark
                ? AppColors.surfaceGlass.withValues(alpha: 0.6)
                : Colors.white,
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        test.titleEn,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          _buildChip(
                            '${test.questions.length} questions',
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.primary,
                          ),
                          _buildChip(
                            test.type.toUpperCase(),
                            AppColors.statusInfo.withValues(alpha: 0.15),
                            AppColors.statusInfo,
                          ),
                          _buildChip(
                            test.isActive ? 'Active' : 'Inactive',
                            test.isActive
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.warning.withValues(alpha: 0.15),
                            test.isActive
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          color: textColor.withValues(alpha: 0.5), size: 20),
                      onPressed: () => _showTestDialog(
                          context, ref, isDark, textColor,
                          test: test),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppColors.error.withValues(alpha: 0.7),
                          size: 20),
                      onPressed: () =>
                          _confirmDelete(context, ref, isDark, textColor, test),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color textColor,
    PsychologicalTest test,
  ) async {
    final outerTheme = Theme.of(context);
    final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
    final primaryText = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: outerTheme,
        child: AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Delete Test', style: TextStyle(color: primaryText)),
          content: Text(
            'Delete "${test.title}"? This action cannot be undone.',
            style: TextStyle(color: secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await ref.read(psychTestsAdminProvider.notifier).deleteTest(test.id);
    }
  }

  void _showTestDialog(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color textColor, {
    PsychologicalTest? test,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _TestDialog(
        test: test,
        isDark: isDark,
        onSave: (updated) async {
          if (test == null) {
            await ref.read(psychTestsAdminProvider.notifier).addTest(updated);
          } else {
            await ref
                .read(psychTestsAdminProvider.notifier)
                .updateTest(updated);
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TestDialog — StatefulWidget dialog for add / edit
// ---------------------------------------------------------------------------

class _TestDialog extends StatefulWidget {
  final PsychologicalTest? test;
  final bool isDark;
  final Future<void> Function(PsychologicalTest) onSave;

  const _TestDialog({
    this.test,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_TestDialog> createState() => _TestDialogState();
}

class _TestDialogState extends State<_TestDialog> {
  // Basic info
  late final TextEditingController _titleCtrl;
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _descEnCtrl;
  late final TextEditingController _durationCtrl;
  late String _type;
  late bool _isActive;

  // Questions
  late List<_QuestionData> _questions;

  // Scoring Ranges
  late List<_RangeData> _ranges;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.test;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _titleEnCtrl = TextEditingController(text: t?.titleEn ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _descEnCtrl = TextEditingController(text: t?.descriptionEn ?? '');
    _durationCtrl =
        TextEditingController(text: t?.durationMinutes.toString() ?? '5');
    _type = t?.type ?? 'anxiety';
    _isActive = t?.isActive ?? true;

    _questions = (t?.questions ?? []).map((q) {
      return _QuestionData(
        text: TextEditingController(text: q.text),
        textEn: TextEditingController(text: q.textEn),
        options: q.options.map((o) {
          return _OptionData(
            text: TextEditingController(text: o.text),
            textEn: TextEditingController(text: o.textEn),
            score: TextEditingController(text: o.score.toString()),
          );
        }).toList(),
      );
    }).toList();

    _ranges = (t?.scoringRanges ?? []).map((r) {
      return _RangeData(
        min: TextEditingController(text: r.min.toString()),
        max: TextEditingController(text: r.max.toString()),
        level: TextEditingController(text: r.level),
        text: TextEditingController(text: r.text),
        textEn: TextEditingController(text: r.textEn),
      );
    }).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _titleEnCtrl.dispose();
    _descCtrl.dispose();
    _descEnCtrl.dispose();
    _durationCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    for (final r in _ranges) {
      r.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Arabic title is required');
      return false;
    }
    if (_questions.isEmpty) {
      _showError('At least one question is required');
      return false;
    }
    for (final q in _questions) {
      if (q.options.isEmpty) {
        _showError('Each question must have at least one option');
        return false;
      }
    }
    if (_ranges.isEmpty) {
      _showError('At least one scoring range is required');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
    ));
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = PsychologicalTest(
        id: widget.test?.id ?? '',
        title: _titleCtrl.text.trim(),
        titleEn: _titleEnCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        descriptionEn: _descEnCtrl.text.trim(),
        type: _type,
        durationMinutes: int.tryParse(_durationCtrl.text.trim()) ?? 5,
        isActive: _isActive,
        questions: _questions.map((q) {
          return TestQuestion(
            text: q.text.text.trim(),
            textEn: q.textEn.text.trim(),
            options: q.options.map((o) {
              return TestOption(
                text: o.text.text.trim(),
                textEn: o.textEn.text.trim(),
                score: int.tryParse(o.score.text.trim()) ?? 0,
              );
            }).toList(),
          );
        }).toList(),
        scoringRanges: _ranges.map((r) {
          return ScoringRange(
            min: int.tryParse(r.min.text.trim()) ?? 0,
            max: int.tryParse(r.max.text.trim()) ?? 0,
            level: r.level.text.trim(),
            text: r.text.text.trim(),
            textEn: r.textEn.text.trim(),
          );
        }).toList(),
      );
      await widget.onSave(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Save failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final outerTheme = Theme.of(context);
    final dialogBg = widget.isDark ? AppColors.adminSurface : Colors.white;
    final primaryText =
        widget.isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText =
        widget.isDark ? Colors.white70 : AppColors.textSecondary;
    final borderColor =
        widget.isDark ? AppColors.adminBorder : AppColors.border;
    final isEditing = widget.test != null;

    return Theme(
      data: outerTheme,
      child: AlertDialog(
        backgroundColor: dialogBg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(
          isEditing ? 'Edit Psychological Test' : 'Add Psychological Test',
          style: TextStyle(color: primaryText),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── BASIC INFO ──
                _sectionHeader('Basic Info', primaryText),
                _field(
                  controller: _titleCtrl,
                  label: 'Title (Arabic) *',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  borderColor: borderColor,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                _field(
                  controller: _titleEnCtrl,
                  label: 'Title (English)',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  borderColor: borderColor,
                ),
                const SizedBox(height: 8),
                _field(
                  controller: _descCtrl,
                  label: 'Description (Arabic)',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  borderColor: borderColor,
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 8),
                _field(
                  controller: _descEnCtrl,
                  label: 'Description (English)',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  borderColor: borderColor,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  dropdownColor: dialogBg,
                  style: TextStyle(color: primaryText),
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: secondaryText),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor)),
                  ),
                  items: ['depression', 'anxiety', 'stress', 'other']
                      .map((v) => DropdownMenuItem(
                          value: v, child: Text(v.toUpperCase())))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 8),
                _field(
                  controller: _durationCtrl,
                  label: 'Duration (minutes)',
                  primaryText: primaryText,
                  secondaryText: secondaryText,
                  borderColor: borderColor,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Active',
                      style: TextStyle(
                          color: primaryText, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _isActive
                        ? 'Visible to users in the app'
                        : 'Hidden — not visible to users',
                    style: TextStyle(
                      color: _isActive ? AppColors.success : AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isActive = v),
                ),

                const Divider(height: 32),

                // ── QUESTIONS ──
                _sectionHeader('Questions', primaryText),
                ..._buildQuestionsSection(
                    primaryText, secondaryText, borderColor, dialogBg),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                  label: const Text('Add Question',
                      style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () => setState(() {
                    _questions.add(_QuestionData(
                      text: TextEditingController(),
                      textEn: TextEditingController(),
                      options: [],
                    ));
                  }),
                ),

                const Divider(height: 32),

                // ── SCORING RANGES ──
                _sectionHeader('Scoring Ranges', primaryText),
                ..._buildRangesSection(
                    primaryText, secondaryText, borderColor),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, color: AppColors.primary),
                  label: const Text('Add Range',
                      style: TextStyle(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () => setState(() {
                    _ranges.add(_RangeData(
                      min: TextEditingController(),
                      max: TextEditingController(),
                      level: TextEditingController(),
                      text: TextEditingController(),
                      textEn: TextEditingController(),
                    ));
                  }),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    int maxLines = 1,
    TextDirection? textDirection,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: primaryText),
      textDirection: textDirection,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: secondaryText),
        enabledBorder: maxLines > 1
            ? OutlineInputBorder(borderSide: BorderSide(color: borderColor))
            : UnderlineInputBorder(borderSide: BorderSide(color: borderColor)),
        focusedBorder: maxLines > 1
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary))
            : const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary)),
      ),
    );
  }

  List<Widget> _buildQuestionsSection(
    Color primaryText,
    Color secondaryText,
    Color borderColor,
    Color dialogBg,
  ) {
    return _questions.asMap().entries.map((entry) {
      final i = entry.key;
      final q = entry.value;
      return Card(
        color: widget.isDark
            ? AppColors.adminGlass.withValues(alpha: 0.4)
            : AppColors.background,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor),
        ),
        child: ExpansionTile(
          initiallyExpanded: i == _questions.length - 1,
          title: Text(
            'Question ${i + 1}',
            style:
                TextStyle(color: primaryText, fontWeight: FontWeight.w600),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 18),
                onPressed: () => setState(() => _questions.removeAt(i)),
              ),
              const Icon(Icons.expand_more),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    controller: q.text,
                    label: 'Question (Arabic) *',
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    borderColor: borderColor,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  _field(
                    controller: q.textEn,
                    label: 'Question (English)',
                    primaryText: primaryText,
                    secondaryText: secondaryText,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 12),
                  Text('Options',
                      style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...q.options.asMap().entries.map((oe) {
                    final oi = oe.key;
                    final o = oe.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _field(
                              controller: o.text,
                              label: 'Option ${oi + 1} (AR)',
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 3,
                            child: _field(
                              controller: o.textEn,
                              label: 'Option ${oi + 1} (EN)',
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            flex: 1,
                            child: _field(
                              controller: o.score,
                              label: 'Score',
                              primaryText: primaryText,
                              secondaryText: secondaryText,
                              borderColor: borderColor,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppColors.error, size: 18),
                            onPressed: () =>
                                setState(() => q.options.removeAt(oi)),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded,
                        size: 16, color: AppColors.primary),
                    label: const Text('Add Option',
                        style:
                            TextStyle(color: AppColors.primary, fontSize: 12)),
                    onPressed: () => setState(() => q.options.add(_OptionData(
                          text: TextEditingController(),
                          textEn: TextEditingController(),
                          score: TextEditingController(text: '0'),
                        ))),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRangesSection(
    Color primaryText,
    Color secondaryText,
    Color borderColor,
  ) {
    return _ranges.asMap().entries.map((entry) {
      final i = entry.key;
      final r = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Range ${i + 1}',
                      style: TextStyle(
                          color: primaryText, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error, size: 18),
                    onPressed: () => setState(() => _ranges.removeAt(i)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: r.min,
                      label: 'Min Score',
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      borderColor: borderColor,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      controller: r.max,
                      label: 'Max Score',
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      borderColor: borderColor,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      controller: r.level,
                      label: 'Level',
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      borderColor: borderColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _field(
                controller: r.text,
                label: 'Result Text (Arabic)',
                primaryText: primaryText,
                secondaryText: secondaryText,
                borderColor: borderColor,
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 8),
              _field(
                controller: r.textEn,
                label: 'Result Text (English)',
                primaryText: primaryText,
                secondaryText: secondaryText,
                borderColor: borderColor,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Data holders for dialog state
// ---------------------------------------------------------------------------

class _QuestionData {
  final TextEditingController text;
  final TextEditingController textEn;
  final List<_OptionData> options;

  _QuestionData({
    required this.text,
    required this.textEn,
    required this.options,
  });

  void dispose() {
    text.dispose();
    textEn.dispose();
    for (final o in options) {
      o.dispose();
    }
  }
}

class _OptionData {
  final TextEditingController text;
  final TextEditingController textEn;
  final TextEditingController score;

  _OptionData({
    required this.text,
    required this.textEn,
    required this.score,
  });

  void dispose() {
    text.dispose();
    textEn.dispose();
    score.dispose();
  }
}

class _RangeData {
  final TextEditingController min;
  final TextEditingController max;
  final TextEditingController level;
  final TextEditingController text;
  final TextEditingController textEn;

  _RangeData({
    required this.min,
    required this.max,
    required this.level,
    required this.text,
    required this.textEn,
  });

  void dispose() {
    min.dispose();
    max.dispose();
    level.dispose();
    text.dispose();
    textEn.dispose();
  }
}
