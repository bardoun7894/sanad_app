import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_content_provider.dart';
import '../../models/cms_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../mood/models/mood_enums.dart';

/// Admin CMS for the supportive advice shown when a user picks a mood in
/// مذكرتي. One entry per mood (6 total). Doc id = MoodType.name.
class MoodAdviceManagementScreen extends ConsumerStatefulWidget {
  const MoodAdviceManagementScreen({super.key});

  @override
  ConsumerState<MoodAdviceManagementScreen> createState() =>
      _MoodAdviceManagementScreenState();
}

class _MoodAdviceManagementScreenState
    extends ConsumerState<MoodAdviceManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminContentProvider.notifier).loadMoodAdvice(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminContentProvider);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;
    final byMood = {for (final a in state.moodAdvice) a.mood: a};

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Mood Advice', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: () =>
                ref.read(adminContentProvider.notifier).loadMoodAdvice(),
          ),
        ],
      ),
      body: state.isLoading && state.moodAdvice.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: MoodType.values.map((mood) {
                final existing = byMood[mood.name];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildMoodCard(mood, existing, textColor),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildMoodCard(MoodType mood, MoodAdvice? advice, Color textColor) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(MoodTypeExtension.emoji(mood),
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MoodTypeExtension.label(mood),
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice == null || advice.advice.isEmpty
                      ? 'No advice set'
                      : advice.advice,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (advice != null && !advice.isActive) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Inactive',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: textColor.withValues(alpha: 0.6),
            ),
            onPressed: () => _showEditDialog(mood, advice),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(MoodType mood, MoodAdvice? advice) {
    final adviceController = TextEditingController(text: advice?.advice ?? '');
    final adviceEnController =
        TextEditingController(text: advice?.adviceEn ?? '');
    bool isActive = advice?.isActive ?? true;

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
              '${MoodTypeExtension.emoji(mood)} ${MoodTypeExtension.label(mood)}',
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
                      controller: adviceController,
                      style: TextStyle(color: primaryText),
                      textDirection: TextDirection.rtl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Advice (Arabic) *',
                        labelStyle: TextStyle(color: secondaryText),
                        hintText: 'خذ نفساً عميقاً، أنت بأمان الآن...',
                        hintStyle: TextStyle(color: hintColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: adviceEnController,
                      style: TextStyle(color: primaryText),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Advice (English)',
                        labelStyle: TextStyle(color: secondaryText),
                        hintText: 'Take a deep breath, you are safe now...',
                        hintStyle: TextStyle(color: hintColor),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Active',
                          style: TextStyle(color: secondaryText)),
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
                  await ref.read(adminContentProvider.notifier).saveMoodAdvice(
                        MoodAdvice(
                          mood: mood.name,
                          advice: adviceController.text.trim(),
                          adviceEn: adviceEnController.text.trim(),
                          isActive: isActive,
                        ),
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
