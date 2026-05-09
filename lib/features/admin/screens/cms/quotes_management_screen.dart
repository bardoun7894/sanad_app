import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_content_provider.dart';
import '../../models/cms_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class QuotesManagementScreen extends ConsumerStatefulWidget {
  const QuotesManagementScreen({super.key});

  @override
  ConsumerState<QuotesManagementScreen> createState() =>
      _QuotesManagementScreenState();
}

class _QuotesManagementScreenState
    extends ConsumerState<QuotesManagementScreen> {
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
        title: Text('Quotes Management', style: TextStyle(color: textColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textColor),
            onPressed: () =>
                ref.read(adminContentProvider.notifier).loadQuotes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuoteDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: state.isLoading && state.quotes.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: state.quotes.length,
              itemBuilder: (context, index) {
                final quote = state.quotes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
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
            ),
    );
  }

  void _showQuoteDialog([DailyQuote? quote]) {
    final textController = TextEditingController(text: quote?.text);
    final textEnController = TextEditingController(text: quote?.textEn);
    final authorController = TextEditingController(text: quote?.author);
    final authorEnController = TextEditingController(text: quote?.authorEn);
    String category = quote?.category ?? 'General';
    bool notifyUsers = true;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
        final primaryText = isDark ? Colors.white : AppColors.textPrimary;
        final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;
        final borderColor = isDark ? AppColors.adminBorder : AppColors.border;
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text(
          quote == null ? 'Add Quote' : 'Edit Quote',
          style: TextStyle(color: primaryText),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: primaryText),
                  decoration: InputDecoration(
                    labelText: 'Quote (Arabic) *',
                    labelStyle: TextStyle(color: secondaryText),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textEnController,
                  maxLines: 3,
                  style: TextStyle(color: primaryText),
                  decoration: InputDecoration(
                    labelText: 'Quote (English)',
                    labelStyle: TextStyle(color: secondaryText),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorController,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: primaryText),
                  decoration: InputDecoration(
                    labelText: 'Author (Arabic)',
                    labelStyle: TextStyle(color: secondaryText),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorEnController,
                  style: TextStyle(color: primaryText),
                  decoration: InputDecoration(
                    labelText: 'Author (English)',
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
                  ].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
              onChanged: (v) => category = v!,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: notifyUsers,
                  activeColor: AppColors.primary,
                  onChanged: (v) =>
                      setLocal(() => notifyUsers = v ?? false),
                  title: Text(
                    'Notify all users',
                    style: TextStyle(color: primaryText, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Sends a push + bell entry to every user.',
                    style:
                        TextStyle(color: secondaryText, fontSize: 12),
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
          TextButton(
            onPressed: () async {
              final newQuote = DailyQuote(
                id: quote?.id ?? '',
                text: textController.text.trim(),
                textEn: textEnController.text.trim(),
                author: authorController.text.trim(),
                authorEn: authorEnController.text.trim(),
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
            child: const Text('Save'),
          ),
        ],
      ),
      );
      },
    );
  }

  void _deleteQuote(String id) async {
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
          'Are you sure you want to delete this quote?',
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
      await ref.read(adminContentProvider.notifier).deleteQuote(id);
    }
  }
}
