import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_content_provider.dart';
import '../../models/cms_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class ChallengesManagementScreen extends ConsumerStatefulWidget {
  const ChallengesManagementScreen({super.key});

  @override
  ConsumerState<ChallengesManagementScreen> createState() =>
      _ChallengesManagementScreenState();
}

class _ChallengesManagementScreenState
    extends ConsumerState<ChallengesManagementScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminContentProvider.notifier).loadChallenges(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminContentProvider);
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Challenges Management',
          style: TextStyle(color: textColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: () =>
                ref.read(adminContentProvider.notifier).loadChallenges(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChallengeDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: state.isLoading && state.challenges.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : state.challenges.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No challenges yet',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add daily challenges',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: state.challenges.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final challenge = state.challenges[index];
                return Padding(
                  key: ValueKey(challenge.id),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildChallengeCard(challenge, textColor, index),
                );
              },
            ),
    );
  }

  Widget _buildChallengeCard(
    DailyChallenge challenge,
    Color textColor,
    int index,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Order indicator
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
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Type icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getChallengeColor(challenge.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getChallengeIcon(challenge.type),
                  color: _getChallengeColor(challenge.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title and type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getChallengeColor(
                              challenge.type,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            challenge.type.name.toUpperCase(),
                            style: TextStyle(
                              color: _getChallengeColor(challenge.type),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.durationMinutes} min',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: challenge.isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            challenge.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: challenge.isActive
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                    icon: Icon(
                      Icons.edit_outlined,
                      color: textColor.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: () => _showChallengeDialog(challenge),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: () => _deleteChallenge(challenge.id),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: textColor.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Description
          if (challenge.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              challenge.description,
              style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.breathing:
        return Icons.air_rounded;
      case ChallengeType.gratitude:
        return Icons.favorite_outline_rounded;
      case ChallengeType.mindfulness:
        return Icons.self_improvement_rounded;
      case ChallengeType.exercise:
        return Icons.fitness_center_rounded;
      case ChallengeType.journaling:
        return Icons.edit_note_rounded;
      case ChallengeType.social:
        return Icons.people_outline_rounded;
      case ChallengeType.selfCare:
        return Icons.spa_outlined;
      case ChallengeType.general:
        return Icons.emoji_events_outlined;
    }
  }

  Color _getChallengeColor(ChallengeType type) {
    switch (type) {
      case ChallengeType.breathing:
        return Colors.cyan;
      case ChallengeType.gratitude:
        return Colors.pink;
      case ChallengeType.mindfulness:
        return Colors.purple;
      case ChallengeType.exercise:
        return Colors.orange;
      case ChallengeType.journaling:
        return Colors.teal;
      case ChallengeType.social:
        return Colors.blue;
      case ChallengeType.selfCare:
        return Colors.green;
      case ChallengeType.general:
        return AppColors.primary;
    }
  }

  void _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final challenges = List<DailyChallenge>.from(
      ref.read(adminContentProvider).challenges,
    );
    final item = challenges.removeAt(oldIndex);
    challenges.insert(newIndex, item);

    // Update order in Firestore
    for (int i = 0; i < challenges.length; i++) {
      final updated = challenges[i].copyWith(order: i);
      await ref.read(adminContentProvider.notifier).updateChallenge(updated);
    }
  }

  void _showChallengeDialog([DailyChallenge? challenge]) {
    final isEditing = challenge != null;
    final titleController = TextEditingController(text: challenge?.title ?? '');
    final titleEnController = TextEditingController(
      text: challenge?.titleEn ?? '',
    );
    final descriptionController = TextEditingController(
      text: challenge?.description ?? '',
    );
    final descriptionEnController = TextEditingController(
      text: challenge?.descriptionEn ?? '',
    );
    final durationController = TextEditingController(
      text: (challenge?.durationMinutes ?? 5).toString(),
    );
    ChallengeType type = challenge?.type ?? ChallengeType.general;
    bool isActive = challenge?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
          final primaryText = isDark ? Colors.white : AppColors.textPrimary;
          final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;
          final hintColor = isDark ? Colors.white30 : AppColors.textMuted;
          final borderColor = isDark ? AppColors.adminBorder : AppColors.border;
          return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(
            isEditing ? 'Edit Challenge' : 'Add Challenge',
            style: TextStyle(color: primaryText),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic title
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: primaryText),
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: 'Title (Arabic) *',
                      labelStyle: TextStyle(color: secondaryText),
                      hintText: 'عنوان التحدي',
                      hintStyle: TextStyle(color: hintColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // English title
                  TextField(
                    controller: titleEnController,
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      labelText: 'Title (English)',
                      labelStyle: TextStyle(color: secondaryText),
                      hintText: 'Challenge title',
                      hintStyle: TextStyle(color: hintColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Type dropdown
                  DropdownButtonFormField<ChallengeType>(
                    initialValue: type,
                    dropdownColor: dialogBg,
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      labelText: 'Type',
                      labelStyle: TextStyle(color: secondaryText),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    items: ChallengeType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(
                              _getChallengeIcon(t),
                              color: _getChallengeColor(t),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(t.name.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setDialogState(() => type = v!),
                  ),
                  const SizedBox(height: 16),
                  // Duration
                  TextField(
                    controller: durationController,
                    style: TextStyle(color: primaryText),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Duration (minutes)',
                      labelStyle: TextStyle(color: secondaryText),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Arabic description
                  TextField(
                    controller: descriptionController,
                    style: TextStyle(color: primaryText),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Arabic) *',
                      labelStyle: TextStyle(color: secondaryText),
                      hintText: 'وصف التحدي...',
                      hintStyle: TextStyle(color: hintColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // English description
                  TextField(
                    controller: descriptionEnController,
                    style: TextStyle(color: primaryText),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (English)',
                      labelStyle: TextStyle(color: secondaryText),
                      hintText: 'Challenge description...',
                      hintStyle: TextStyle(color: hintColor),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Active switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Active',
                      style: TextStyle(color: secondaryText),
                    ),
                    subtitle: Text(
                      isActive
                          ? 'Challenge will appear to users'
                          : 'Challenge is hidden from users',
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
                if (titleController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Arabic title and description are required',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final duration =
                    int.tryParse(durationController.text.trim()) ?? 5;
                final currentChallenges = ref
                    .read(adminContentProvider)
                    .challenges;
                final newOrder = isEditing
                    ? challenge.order
                    : currentChallenges.length;

                final newChallenge = DailyChallenge(
                  id: challenge?.id ?? '',
                  title: titleController.text.trim(),
                  titleEn: titleEnController.text.trim(),
                  description: descriptionController.text.trim(),
                  descriptionEn: descriptionEnController.text.trim(),
                  type: type,
                  durationMinutes: duration,
                  order: newOrder,
                  isActive: isActive,
                  publishDate: challenge?.publishDate ?? DateTime.now(),
                );

                if (isEditing) {
                  await ref
                      .read(adminContentProvider.notifier)
                      .updateChallenge(newChallenge);
                } else {
                  await ref
                      .read(adminContentProvider.notifier)
                      .addChallenge(newChallenge);
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

  void _deleteChallenge(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
        final primaryText = isDark ? Colors.white : AppColors.textPrimary;
        final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;
        return AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          'Confirm Delete',
          style: TextStyle(color: primaryText),
        ),
        content: Text(
          'Are you sure you want to delete this challenge? This action cannot be undone.',
          style: TextStyle(color: secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      );
      },
    );
    if (confirm == true) {
      await ref.read(adminContentProvider.notifier).deleteChallenge(id);
    }
  }
}
