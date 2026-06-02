import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/admin_content_provider.dart';
import '../../models/cms_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import 'rich_text_helpers.dart';

class ContentManagementScreen extends ConsumerStatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  ConsumerState<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState
    extends ConsumerState<ContentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
    Future.microtask(() {
      ref.read(adminContentProvider.notifier).loadContent();
      ref.read(adminContentProvider.notifier).loadQuotes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminContentProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : AppColors.textPrimary);

    final articles = state.contentList
        .where((c) => c.type == ContentType.article)
        .toList();
    final exercises = state.contentList
        .where((c) => c.type == ContentType.exercise)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Content Management', style: TextStyle(color: textColor)),
        actions: [
          if (_currentTab > 0 && state.contentList.any((c) => !c.isPublished))
            TextButton.icon(
              icon: const Icon(Icons.publish_rounded, color: AppColors.primary),
              label: const Text(
                'Publish all drafts',
                style: TextStyle(color: AppColors.primary),
              ),
              onPressed: () => _publishAllDrafts(state.contentList),
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: () {
              ref.read(adminContentProvider.notifier).loadContent();
              ref.read(adminContentProvider.notifier).loadQuotes();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? Colors.white54
              : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Daily Tip'),
            Tab(text: 'Articles'),
            Tab(text: 'Exercises'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentTab == 0) {
            _showQuoteDialog();
          } else {
            _showContentDialog(
              defaultType: _currentTab == 2
                  ? ContentType.exercise
                  : ContentType.article,
            );
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTipTab(state, textColor, isDark),
          _buildContentList(articles, textColor, isDark, 'No articles yet'),
          _buildContentList(exercises, textColor, isDark, 'No exercises yet'),
        ],
      ),
    );
  }

  Widget _buildDailyTipTab(dynamic state, Color textColor, bool isDark) {
    if (state.isLoading && state.quotes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state.quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: textColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No daily tips yet',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add a daily tip',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.quotes.length,
      itemBuilder: (context, index) {
        final quote = state.quotes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            color: isDark
                ? AppColors.surfaceGlass.withValues(alpha: 0.6)
                : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        quote.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: textColor.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          onPressed: () => _showQuoteDialog(quote),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error.withValues(alpha: 0.5),
                            size: 20,
                          ),
                          onPressed: () => _deleteQuote(quote.id),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '"${quote.text}"',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '- ${quote.author}',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentList(
    List<AppContent> items,
    Color textColor,
    bool isDark,
    String emptyLabel,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: textColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildContentCard(items[index], textColor, isDark);
      },
    );
  }

  Widget _buildContentCard(AppContent item, Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        color: isDark
            ? AppColors.surfaceGlass.withValues(alpha: 0.6)
            : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getContentIcon(item.type),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
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
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.isPublished
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.isPublished ? 'Published' : 'Draft',
                              style: TextStyle(
                                color: item.isPublished
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
                      onPressed: () => _showContentDialog(
                        content: item,
                        defaultType: item.type,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onPressed: () => _deleteContent(item.id),
                    ),
                  ],
                ),
              ],
            ),
            // Content preview
            if (item.contentText != null && item.contentText!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                item.contentText!.length > 100
                    ? '${item.contentText!.substring(0, 100)}...'
                    : item.contentText!,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ],
            // URLs
            if (item.mediaUrl != null || item.linkUrl != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (item.mediaUrl != null)
                    _buildUrlChip(Icons.image_outlined, 'Media', textColor),
                  if (item.linkUrl != null)
                    _buildUrlChip(Icons.link_outlined, 'Link', textColor),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrlChip(IconData icon, String label, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContentIcon(ContentType type) {
    switch (type) {
      case ContentType.article:
        return Icons.article_outlined;
      case ContentType.video:
        return Icons.play_circle_outline_rounded;
      case ContentType.exercise:
        return Icons.fitness_center_outlined;
    }
  }

  void _showQuoteDialog([DailyQuote? quote]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
    final primaryText = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;
    final borderColor = isDark ? Colors.white24 : AppColors.border;
    final textController = TextEditingController(text: quote?.text);
    final textEnController = TextEditingController(text: quote?.textEn);
    final authorController = TextEditingController(text: quote?.author);
    final authorEnController = TextEditingController(text: quote?.authorEn);
    String category = quote?.category ?? 'General';
    bool notifyUsers = true;

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: dialogBg,
            title: Text(
              quote == null ? 'Add Daily Tip' : 'Edit Daily Tip',
              style: TextStyle(color: primaryText),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      labelText: 'Tip / Quote Text',
                      labelStyle: TextStyle(color: secondaryText),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: authorController,
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      labelText: 'Author (optional)',
                      labelStyle: TextStyle(color: secondaryText),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: dialogBg,
                    style: TextStyle(color: primaryText),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: secondaryText),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    items:
                        [
                              'General',
                              'Inspirational',
                              'Mental Health',
                              'Anxiety',
                              'Hope',
                            ]
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (v) => setDialogState(() => category = v!),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    value: notifyUsers,
                    activeColor: AppColors.primary,
                    onChanged: (v) =>
                        setDialogState(() => notifyUsers = v ?? false),
                    title: Text(
                      'Notify all users',
                      style: TextStyle(color: primaryText, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Push + bell entry to every user when saved.',
                      style: TextStyle(color: secondaryText, fontSize: 12),
                    ),
                  ),
                ],
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
                  if (textController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tip text is required'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  final newQuote = DailyQuote(
                    id: quote?.id ?? '',
                    text: textController.text.trim(),
                    author: authorController.text.trim().isNotEmpty
                        ? authorController.text.trim()
                        : 'Sanad',
                    category: category,
                    publishDate: quote?.publishDate ?? DateTime.now(),
                  );
                  if (quote == null) {
                    await ref
                        .read(adminContentProvider.notifier)
                        .addQuote(newQuote, notifyUsers: notifyUsers);
                  } else {
                    await ref
                        .read(adminContentProvider.notifier)
                        .updateQuote(newQuote, notifyUsers: notifyUsers);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text(quote == null ? 'Add' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteQuote(String id) async {
    final outerTheme = Theme.of(context);
    final isDark = outerTheme.brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
    final primaryText = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: outerTheme,
        child: AlertDialog(
          backgroundColor: dialogBg,
          title: Text('Confirm Delete', style: TextStyle(color: primaryText)),
          content: Text(
            'Delete this daily tip?',
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
        ),
      ),
    );
    if (confirm == true) {
      await ref.read(adminContentProvider.notifier).deleteQuote(id);
    }
  }

  void _showContentDialog({
    AppContent? content,
    ContentType defaultType = ContentType.article,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
    final primaryText = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;
    final hintText = isDark ? Colors.white30 : AppColors.textMuted;
    final borderColor = isDark ? Colors.white24 : AppColors.border;
    final isEditing = content != null;
    final titleController = TextEditingController(text: content?.title ?? '');
    final titleEnController = TextEditingController(
      text: content?.titleEn ?? '',
    );
    final categoryController = TextEditingController(
      text: content?.category ?? '',
    );
    final descriptionFocusNode = FocusNode();
    final descriptionController = TextEditingController(
      text: content?.contentText ?? '',
    );
    final descriptionEnController = TextEditingController(
      text: content?.contentTextEn ?? '',
    );
    final mediaUrlController = TextEditingController(
      text: content?.mediaUrl ?? '',
    );
    final linkUrlController = TextEditingController(
      text: content?.linkUrl ?? '',
    );
    ContentType type = content?.type ?? defaultType;
    bool isPublished = content?.isPublished ?? true;
    bool notifyUsers = true;
    final selectedMoodTags = <String>{
      ...(content?.moodTags ?? const <String>[]),
    };
    const allMoodTags = <String>[
      'happy',
      'calm',
      'sad',
      'anxious',
      'tired',
      'energetic',
      'angry',
    ];

    showDialog(
      context: context,
      builder: (context) => Theme(
        data: theme,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: dialogBg,
            title: Text(
              isEditing ? 'Edit Content' : 'Add Content',
              style: TextStyle(color: primaryText),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: primaryText),
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: 'Title (Arabic) *',
                        labelStyle: TextStyle(color: secondaryText),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleEnController,
                      style: TextStyle(color: primaryText),
                      decoration: InputDecoration(
                        labelText: 'Title (English)',
                        labelStyle: TextStyle(color: secondaryText),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: categoryController,
                      style: TextStyle(color: primaryText),
                      decoration: InputDecoration(
                        labelText: 'Category *',
                        labelStyle: TextStyle(color: secondaryText),
                        hintText: 'e.g., Anxiety, Sleep, Mindfulness',
                        hintStyle: TextStyle(color: hintText),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ContentType>(
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
                      items: ContentType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(
                                _getContentIcon(t),
                                color: AppColors.primary,
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
                    ExcludeFocus(
                      child: _RichTextToolbar(
                        controller: descriptionController,
                        focusNode: descriptionFocusNode,
                        iconColor: AppColors.primary,
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      focusNode: descriptionFocusNode,
                      style: TextStyle(color: primaryText),
                      maxLines: 10,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: 'Content Text (Arabic)',
                        labelStyle: TextStyle(color: secondaryText),
                        hintText: 'أدخل المحتوى هنا...',
                        hintStyle: TextStyle(color: hintText),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionEnController,
                      style: TextStyle(color: primaryText),
                      maxLines: 10,
                      decoration: InputDecoration(
                        labelText: 'Content Text (English)',
                        labelStyle: TextStyle(color: secondaryText),
                        hintText: 'Enter the content in English...',
                        hintStyle: TextStyle(color: hintText),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ImageUploadField(
                      controller: mediaUrlController,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      hintText: hintText,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: linkUrlController,
                      style: TextStyle(color: primaryText),
                      decoration: InputDecoration(
                        labelText: 'External Link URL (optional)',
                        labelStyle: TextStyle(color: secondaryText),
                        hintText: 'https://...',
                        hintStyle: TextStyle(color: hintText),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Mood tags (for personalized recommendations)',
                        style: TextStyle(color: secondaryText, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: allMoodTags.map((tag) {
                        final selected = selectedMoodTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: selected,
                          onSelected: (v) => setDialogState(() {
                            if (v) {
                              selectedMoodTags.add(tag);
                            } else {
                              selectedMoodTags.remove(tag);
                            }
                          }),
                          backgroundColor: isDark
                              ? Colors.white12
                              : AppColors.borderLight,
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
                          labelStyle: TextStyle(
                            color: selected ? AppColors.primary : primaryText,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Published',
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isPublished
                            ? 'Visible to users in the app'
                            : 'Saved as draft — NOT visible in the app',
                        style: TextStyle(
                          color: isPublished
                              ? AppColors.success
                              : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      value: isPublished,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setDialogState(() => isPublished = v),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      value: notifyUsers,
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setDialogState(() => notifyUsers = v ?? false),
                      title: Text(
                        'Notify all users',
                        style: TextStyle(color: primaryText, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Push + bell entry to every user when saved.',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                        ),
                      ),
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
                      categoryController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Title and Category are required'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  final newContent = AppContent(
                    id: content?.id ?? '',
                    title: titleController.text.trim(),
                    titleEn: titleEnController.text.trim(),
                    category: categoryController.text.trim(),
                    type: type,
                    contentText: descriptionController.text.trim().isNotEmpty
                        ? descriptionController.text.trim()
                        : null,
                    contentTextEn:
                        descriptionEnController.text.trim().isNotEmpty
                        ? descriptionEnController.text.trim()
                        : null,
                    mediaUrl: mediaUrlController.text.trim().isNotEmpty
                        ? mediaUrlController.text.trim()
                        : null,
                    linkUrl: linkUrlController.text.trim().isNotEmpty
                        ? linkUrlController.text.trim()
                        : null,
                    isPublished: isPublished,
                    moodTags: selectedMoodTags.toList(),
                    createdAt: content?.createdAt ?? DateTime.now(),
                  );

                  if (isEditing) {
                    await ref
                        .read(adminContentProvider.notifier)
                        .updateContent(newContent, notifyUsers: notifyUsers);
                  } else {
                    await ref
                        .read(adminContentProvider.notifier)
                        .addContent(newContent, notifyUsers: notifyUsers);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishAllDrafts(List<AppContent> all) async {
    final drafts = all.where((c) => !c.isPublished).toList();
    if (drafts.isEmpty) return;
    final notifier = ref.read(adminContentProvider.notifier);
    for (final draft in drafts) {
      await notifier.updateContent(draft.copyWith(isPublished: true));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${drafts.length} item(s) published'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _deleteContent(String id) async {
    final outerTheme = Theme.of(context);
    final isDark = outerTheme.brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
    final primaryText = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Theme(
          data: outerTheme,
          child: AlertDialog(
            backgroundColor: dialogBg,
            title: Text('Confirm Delete', style: TextStyle(color: primaryText)),
            content: Text(
              'Are you sure you want to delete this content item? This action cannot be undone.',
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
          ),
        );
      },
    );
    if (confirm == true) {
      await ref.read(adminContentProvider.notifier).deleteContent(id);
    }
  }
}

// ---------------------------------------------------------------------------
// Rich-text formatting toolbar
// ---------------------------------------------------------------------------
class _RichTextToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Color iconColor;

  const _RichTextToolbar({
    required this.controller,
    this.focusNode,
    required this.iconColor,
  });

  void _restoreFocus() {
    focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeadingButton(
            label: 'H1',
            controller: controller,
            focusNode: focusNode,
            level: 1,
            color: iconColor,
          ),
          _HeadingButton(
            label: 'H2',
            controller: controller,
            focusNode: focusNode,
            level: 2,
            color: iconColor,
          ),
          _HeadingButton(
            label: 'H3',
            controller: controller,
            focusNode: focusNode,
            level: 3,
            color: iconColor,
          ),
          IconButton(
            tooltip: 'Bold (**text**)',
            icon: Icon(Icons.format_bold, color: iconColor, size: 20),
            onPressed: () {
              wrapSelection(controller, '**', '**');
              _restoreFocus();
            },
          ),
          IconButton(
            tooltip: 'Italic (*text*)',
            icon: Icon(Icons.format_italic, color: iconColor, size: 20),
            onPressed: () {
              wrapSelection(controller, '*', '*');
              _restoreFocus();
            },
          ),
          IconButton(
            tooltip: 'Quote (> text)',
            icon: Icon(Icons.format_quote, color: iconColor, size: 20),
            onPressed: () {
              prefixLine(controller, '> ');
              _restoreFocus();
            },
          ),
          IconButton(
            tooltip: 'Numbered list',
            icon: Icon(Icons.format_list_numbered, color: iconColor, size: 20),
            onPressed: () {
              prefixLine(controller, '1. ');
              _restoreFocus();
            },
          ),
        ],
      ),
    );
  }
}

/// A compact text button that applies a heading level to the current line.
class _HeadingButton extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int level;
  final Color color;

  const _HeadingButton({
    required this.label,
    required this.controller,
    this.focusNode,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Heading $level (${'#' * level} text)',
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () {
          setHeadingLevel(controller, level);
          focusNode?.requestFocus();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageUploadField extends StatefulWidget {
  final TextEditingController controller;
  final Color primaryText;
  final Color secondaryText;
  final Color hintText;
  final Color borderColor;

  const _ImageUploadField({
    required this.controller,
    required this.primaryText,
    required this.secondaryText,
    required this.hintText,
    required this.borderColor,
  });

  @override
  State<_ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<_ImageUploadField> {
  bool _uploading = false;
  double _progress = 0;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() {
      _error = null;
      _uploading = true;
      _progress = 0;
    });
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';
      final ref = FirebaseStorage.instance.ref('content_images/$ts.$ext');
      final bytes = await picked.readAsBytes();
      final task = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      task.snapshotEvents.listen((s) {
        if (!mounted) return;
        if (s.totalBytes > 0) {
          setState(() => _progress = s.bytesTransferred / s.totalBytes);
        }
      });
      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();
      if (!mounted) return;
      setState(() {
        widget.controller.text = url;
        _uploading = false;
        _progress = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Upload failed: $e';
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.controller.text.trim();
    final hasImage =
        url.isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                style: TextStyle(color: widget.primaryText),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Media / Image URL',
                  labelStyle: TextStyle(color: widget.secondaryText),
                  hintText: 'Upload an image or paste a URL',
                  hintStyle: TextStyle(color: widget.hintText),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: widget.borderColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.upload_rounded, size: 18),
              label: Text(_uploading ? 'Uploading…' : 'Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_uploading)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              backgroundColor: widget.borderColor,
              color: AppColors.primary,
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        if (hasImage) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 60,
                alignment: Alignment.center,
                color: widget.borderColor,
                child: Text(
                  'Preview unavailable',
                  style: TextStyle(color: widget.secondaryText, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
