import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../mood/models/mood_enums.dart';
import '../models/mood_alert.dart';
import '../providers/all_mood_feed_provider.dart';

// ---------------------------------------------------------------------------
// MoodFeedScreen — admin all-moods feed
// ---------------------------------------------------------------------------
// Shows ALL daily moods (positive / negative / neutral), newest-first.
// Color-coded: green (positive), red (negative), amber (neutral).
// Each row has a "Message" button that deep-links to /admin/chat/detail/:userId.
// DO NOT modify MoodAlertBell or mood_alerts_provider — those are separate.
// ---------------------------------------------------------------------------

class MoodFeedScreen extends ConsumerStatefulWidget {
  const MoodFeedScreen({super.key});

  @override
  ConsumerState<MoodFeedScreen> createState() => _MoodFeedScreenState();
}

class _MoodFeedScreenState extends ConsumerState<MoodFeedScreen> {
  /// null = "All", otherwise filter to a specific polarity.
  MoodPolarity? _filter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AdminResponsive.isMobile(context);
    final feedAsync = ref.watch(allMoodFeedProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // Page header
            // ----------------------------------------------------------------
            Padding(
              padding: AdminResponsive.pagePadding(context).copyWith(bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المشاعر',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'سجل المشاعر اليومية لجميع المستخدمين',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.adminTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --------------------------------------------------------
                  // Polarity filter chips
                  // --------------------------------------------------------
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'الكل',
                          selected: _filter == null,
                          color: AppColors.primary,
                          isDark: isDark,
                          onTap: () => setState(() => _filter = null),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'إيجابي',
                          selected: _filter == MoodPolarity.positive,
                          color: AppColors.statusSuccess,
                          isDark: isDark,
                          onTap: () => setState(
                            () => _filter = _filter == MoodPolarity.positive
                                ? null
                                : MoodPolarity.positive,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'سلبي',
                          selected: _filter == MoodPolarity.negative,
                          color: AppColors.statusDanger,
                          isDark: isDark,
                          onTap: () => setState(
                            () => _filter = _filter == MoodPolarity.negative
                                ? null
                                : MoodPolarity.negative,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'محايد',
                          selected: _filter == MoodPolarity.neutral,
                          color: AppColors.statusWarning,
                          isDark: isDark,
                          onTap: () => setState(
                            () => _filter = _filter == MoodPolarity.neutral
                                ? null
                                : MoodPolarity.neutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ----------------------------------------------------------------
            // Feed list
            // ----------------------------------------------------------------
            Expanded(
              child: feedAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'تعذّر تحميل المشاعر',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.adminTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (alerts) {
                  // Client-side filter
                  final filtered = _filter == null
                      ? alerts
                      : alerts
                          .where((a) => a.mood.polarity == _filter)
                          .toList();

                  if (filtered.isEmpty) {
                    return _EmptyState(isDark: isDark, filter: _filter);
                  }

                  return ListView.builder(
                    padding: AdminResponsive.pagePadding(context).copyWith(
                      top: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return _MoodRow(
                        entry: entry,
                        isDark: isDark,
                        onMessage: () => context.go(
                          '/admin/chat/detail/${entry.userId}',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Polarity filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.25 : 0.15)
              : (isDark
                    ? AppColors.adminGlass.withValues(alpha: 0.4)
                    : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? color
                : (isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual mood row
// ---------------------------------------------------------------------------

class _MoodRow extends StatelessWidget {
  final MoodAlert entry;
  final bool isDark;
  final VoidCallback onMessage;

  const _MoodRow({
    required this.entry,
    required this.isDark,
    required this.onMessage,
  });

  /// Resolve color for the polarity dot.
  Color _dotColor(MoodPolarity polarity) {
    switch (polarity) {
      case MoodPolarity.positive:
        return AppColors.statusSuccess; // green
      case MoodPolarity.negative:
        return AppColors.statusDanger; // red
      case MoodPolarity.neutral:
        return AppColors.statusWarning; // amber
    }
  }

  /// Fallback name: never show "User" — use Arabic "مستخدم" instead.
  String _displayName(String? userName) => userName ?? 'مستخدم';

  @override
  Widget build(BuildContext context) {
    final polarity = entry.mood.polarity;
    final dotColor = _dotColor(polarity);
    final emoji = MoodTypeExtension.emoji(entry.mood);
    final label = MoodTypeExtension.label(entry.mood);
    final name = _displayName(entry.userName);
    final ago = timeago.format(entry.date, locale: 'ar');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Polarity dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Mood emoji in a subtle chip
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        title: Text(
          '$label  ·  $name',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          ago,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.adminTextSecondary : AppColors.textSecondary,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.chat_bubble_outline_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          tooltip: 'مراسلة',
          onPressed: onMessage,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final MoodPolarity? filter;

  const _EmptyState({required this.isDark, required this.filter});

  String get _message {
    if (filter == null) return 'لا توجد مشاعر مسجّلة بعد';
    switch (filter!) {
      case MoodPolarity.positive:
        return 'لا توجد مشاعر إيجابية مسجّلة';
      case MoodPolarity.negative:
        return 'لا توجد مشاعر سلبية مسجّلة';
      case MoodPolarity.neutral:
        return 'لا توجد مشاعر محايدة مسجّلة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sentiment_neutral_rounded,
            size: 56,
            color: isDark
                ? AppColors.adminTextSecondary
                : AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            _message,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.adminTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
