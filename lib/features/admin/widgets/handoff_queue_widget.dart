import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../chat/models/chat_handoff.dart';
import '../../chat/providers/handoff_provider.dart';

/// Admin dashboard widget showing pending handoff requests waiting for
/// therapist assignment.
///
/// Watches [pendingHandoffsProvider] for real-time updates. Each card shows
/// the user name, trigger reason, and time elapsed since the request.
class HandoffQueueWidget extends ConsumerWidget {
  const HandoffQueueWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pendingAsync = ref.watch(pendingHandoffsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.transfer_within_a_station_rounded,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Text(
                  'Pending Handoffs',
                  style: AppTypography.headingSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                pendingAsync.when(
                  data: (handoffs) => handoffs.isNotEmpty
                      ? _CountBadge(count: handoffs.length)
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => ref.invalidate(pendingHandoffsProvider),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),

          // Content
          pendingAsync.when(
            data: (handoffs) {
              if (handoffs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 36,
                          color: AppColors.success.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No pending handoffs',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: handoffs.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                itemBuilder: (context, index) {
                  return _HandoffCard(
                    handoff: handoffs[index],
                    isDark: isDark,
                    onTap: () {
                      // Navigate to the handoff assignment screen
                      context.push('/admin/handoff/${handoffs[index].id}');
                    },
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Error loading handoffs',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Count Badge ────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Handoff Card ───────────────────────────────────────────────────────────

class _HandoffCard extends StatelessWidget {
  final ChatHandoff handoff;
  final bool isDark;
  final VoidCallback onTap;

  const _HandoffCard({
    required this.handoff,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(handoff.createdAt);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _triggerColor().withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  handoff.userName.isNotEmpty
                      ? handoff.userName[0].toUpperCase()
                      : '?',
                  style: AppTypography.headingSmall.copyWith(
                    color: _triggerColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          handoff.userName,
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatElapsed(elapsed),
                        style: AppTypography.caption.copyWith(
                          color: elapsed.inMinutes > 5
                              ? AppColors.warning
                              : AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TriggerChip(
                        trigger: handoff.triggerReason,
                        isDark: isDark,
                      ),
                      if (handoff.riskLevel != null) ...[
                        const SizedBox(width: 6),
                        _RiskChip(
                          riskLevel: handoff.riskLevel!,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                  if (handoff.aiSummary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      handoff.aiSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Arrow
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _triggerColor() {
    switch (handoff.triggerReason) {
      case HandoffTrigger.crisis:
        return AppColors.error;
      case HandoffTrigger.userRequest:
        return AppColors.info;
      case HandoffTrigger.moodPattern:
        return AppColors.warning;
      case HandoffTrigger.aiLowConfidence:
        return AppColors.statusPending;
    }
  }

  String _formatElapsed(Duration elapsed) {
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    return '${elapsed.inDays}d ago';
  }
}

// ── Trigger Chip ───────────────────────────────────────────────────────────

class _TriggerChip extends StatelessWidget {
  final HandoffTrigger trigger;
  final bool isDark;

  const _TriggerChip({required this.trigger, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 10, color: _color()),
          const SizedBox(width: 4),
          Text(
            _label(),
            style: AppTypography.labelSmall.copyWith(
              color: _color(),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _label() {
    switch (trigger) {
      case HandoffTrigger.crisis:
        return 'Crisis';
      case HandoffTrigger.userRequest:
        return 'User Request';
      case HandoffTrigger.moodPattern:
        return 'Mood Pattern';
      case HandoffTrigger.aiLowConfidence:
        return 'AI Uncertain';
    }
  }

  IconData _icon() {
    switch (trigger) {
      case HandoffTrigger.crisis:
        return Icons.warning_amber_rounded;
      case HandoffTrigger.userRequest:
        return Icons.person_rounded;
      case HandoffTrigger.moodPattern:
        return Icons.mood_bad_rounded;
      case HandoffTrigger.aiLowConfidence:
        return Icons.psychology_alt_rounded;
    }
  }

  Color _color() {
    switch (trigger) {
      case HandoffTrigger.crisis:
        return AppColors.error;
      case HandoffTrigger.userRequest:
        return AppColors.info;
      case HandoffTrigger.moodPattern:
        return AppColors.warning;
      case HandoffTrigger.aiLowConfidence:
        return AppColors.statusPending;
    }
  }
}

// ── Risk Chip ──────────────────────────────────────────────────────────────

class _RiskChip extends StatelessWidget {
  final String riskLevel;
  final bool isDark;

  const _RiskChip({required this.riskLevel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = _riskColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        riskLevel.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _riskColor() {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return AppColors.riskCritical;
      case 'high':
        return AppColors.riskHigh;
      case 'moderate':
        return AppColors.riskModerate;
      case 'low':
      default:
        return AppColors.riskLow;
    }
  }
}
