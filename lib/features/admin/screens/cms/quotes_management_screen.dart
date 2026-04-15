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
    final authorController = TextEditingController(text: quote?.author);
    String category = quote?.category ?? 'General';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.adminSurface,
        title: Text(
          quote == null ? 'Add Quote' : 'Edit Quote',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Quote Text',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            TextField(
              controller: authorController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Author',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: category,
              dropdownColor: AppColors.adminSurface,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.white70),
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
          ],
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
                text: textController.text,
                author: authorController.text,
                category: category,
                publishDate: quote?.publishDate ?? DateTime.now(),
              );
              if (quote == null) {
                await ref
                    .read(adminContentProvider.notifier)
                    .addQuote(newQuote);
              } else {
                await ref
                    .read(adminContentProvider.notifier)
                    .updateQuote(newQuote);
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteQuote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.adminSurface,
        title: const Text(
          'Confirm Delete',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this quote?',
          style: TextStyle(color: Colors.white70),
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
    if (confirm == true) {
      await ref.read(adminContentProvider.notifier).deleteQuote(id);
    }
  }
}
