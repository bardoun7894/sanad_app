import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/quick_reply.dart';

class QuickReplySheet extends StatelessWidget {
  final Function(String) onReplySelected;

  const QuickReplySheet({super.key, required this.onReplySelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final replies = QuickReply.defaults;

    // Group replies by category
    final groupedReplies = <String, List<QuickReply>>{};
    for (var reply in replies) {
      if (!groupedReplies.containsKey(reply.category)) {
        groupedReplies[reply.category] = [];
      }
      groupedReplies[reply.category]!.add(reply);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Responses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // List of categories and chips
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: groupedReplies.length,
              itemBuilder: (context, index) {
                final category = groupedReplies.keys.elementAt(index);
                final categoryReplies = groupedReplies[category]!;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categoryReplies.map((reply) {
                          return ActionChip(
                            label: Text(reply.label),
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.grey[100],
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () {
                              onReplySelected(reply.text);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
