import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_content_provider.dart';
import '../../models/cms_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

/// Admin CMS for the 5 journaling prompts ("أسئلة تحفيزية للكتابة")
/// shown in the user app's مذكرتي editor. Mirrors ChallengesManagementScreen.
class JournalingPromptsManagementScreen extends ConsumerStatefulWidget {
  const JournalingPromptsManagementScreen({super.key});

  @override
  ConsumerState<JournalingPromptsManagementScreen> createState() =>
      _JournalingPromptsManagementScreenState();
}

class _JournalingPromptsManagementScreenState
    extends ConsumerState<JournalingPromptsManagementScreen> {
  static const int _softCap = 5;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminContentProvider.notifier).loadJournalPrompts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminContentProvider);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final prompts = state.journalPrompts;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Journaling Prompts', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: () =>
                ref.read(adminContentProvider.notifier).loadJournalPrompts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: prompts.length >= _softCap
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Up to 5 prompts are recommended.'),
                  ),
                );
              }
            : () => _showPromptDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: state.isLoading && prompts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : prompts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 64,
                        color: textColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No prompts yet',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add up to 5 writing prompts',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.3),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: prompts.length,
                  itemBuilder: (context, index) {
                    final prompt = prompts[index];
                    return Padding(
                      key: ValueKey(prompt.id),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPromptCard(prompt, textColor, index),
                    );
                  },
                ),
    );
  }

  Widget _buildPromptCard(
    JournalPromptCms prompt,
    Color textColor,
    int index,
  ) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt.question,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (prompt.questionEn.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    prompt.questionEn,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: prompt.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    prompt.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: prompt.isActive ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: textColor.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: () => _showPromptDialog(prompt),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: () => _deletePrompt(prompt.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPromptDialog([JournalPromptCms? prompt]) {
    final isEditing = prompt != null;
    final questionController =
        TextEditingController(text: prompt?.question ?? '');
    final questionEnController =
        TextEditingController(text: prompt?.questionEn ?? '');
    bool isActive = prompt?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
          final primaryText = isDark ? Colors.white : AppColors.textPrimary;
          final secondaryText =
              isDark ? Colors.white70 : AppColors.textSecondary;
          final hintColor = isDark ? Colors.white30 : AppColors.textMuted;
          final borderColor = isDark ? AppColors.adminBorder : AppColors.border;
          return AlertDialog(
            backgroundColor: dialogBg,
            title: Text(
              isEditing ? 'Edit Prompt' : 'Add Prompt',
              style: TextStyle(color: primaryText),
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: questionController,
                      style: TextStyle(color: primaryText),
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Question (Arabic) *',
                        labelStyle: TextStyle(color: secondaryText),
                        hintText: 'ما الذي جعلك تبتسم اليوم؟',
                        hintStyle: TextStyle(color: hintColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: questionEnController,
                      style: TextStyle(color: primaryText),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Question (English)',
                        labelStyle: TextStyle(color: secondaryText),
                        hintText: 'What made you smile today?',
                        hintStyle: TextStyle(color: hintColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Active', style: TextStyle(color: secondaryText)),
                      subtitle: Text(
                        isActive
                            ? 'Prompt can appear to users'
                            : 'Prompt is hidden from users',
                        style: TextStyle(
                          color: secondaryText.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      value: isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () async {
                  if (questionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Arabic question is required'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  final currentPrompts =
                      ref.read(adminContentProvider).journalPrompts;
                  final newOrder =
                      isEditing ? prompt.order : currentPrompts.length;
                  final newPrompt = JournalPromptCms(
                    id: prompt?.id ?? '',
                    question: questionController.text.trim(),
                    questionEn: questionEnController.text.trim(),
                    order: newOrder,
                    isActive: isActive,
                  );
                  if (isEditing) {
                    await ref
                        .read(adminContentProvider.notifier)
                        .updateJournalPrompt(newPrompt);
                  } else {
                    await ref
                        .read(adminContentProvider.notifier)
                        .addJournalPrompt(newPrompt);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deletePrompt(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
        final primaryText = isDark ? Colors.white : AppColors.textPrimary;
        final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Confirm Delete', style: TextStyle(color: primaryText)),
          content: Text(
            'Delete this writing prompt? This cannot be undone.',
            style: TextStyle(color: secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await ref.read(adminContentProvider.notifier).deleteJournalPrompt(id);
    }
  }
}
