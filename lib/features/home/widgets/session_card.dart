import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final String dateTime;
  final String? therapistName;
  final String? sessionType;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onTap;
  final bool isEmpty;
  final bool isLoading;

  const SessionCard({
    super.key,
    required this.title,
    required this.dateTime,
    this.therapistName,
    this.sessionType,
    this.onCalendarTap,
    this.onTap,
    this.isEmpty = false,
    this.isLoading = false,
  });

  IconData get _sessionIcon {
    switch (sessionType) {
      case 'audio':
        return Icons.phone_outlined;
      case 'chat':
        return Icons.chat_outlined;
      case 'video':
      default:
        return Icons.videocam_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _buildLoadingState(isDark);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Session type icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isEmpty
                        ? (isDark ? Colors.grey.withValues(alpha: 0.2) : Colors.grey.shade100)
                        : (isDark
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.softBlue),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isEmpty ? AppColors.textMuted : AppColors.primary).withValues(alpha: 0.15),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  isEmpty ? Icons.event_busy_outlined : _sessionIcon,
                  size: 18,
                  color: isEmpty ? AppColors.textMuted : AppColors.primary,
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (therapistName != null && !isEmpty) ...[
                    Text(
                      therapistName!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                  ],
                  Text(
                    dateTime,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Calendar button or book button
            GestureDetector(
              onTap: isEmpty ? onTap : onCalendarTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isEmpty
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : (isDark
                          ? AppColors.surfaceDark
                          : AppColors.backgroundLight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEmpty ? Icons.add : Icons.calendar_today_outlined,
                  size: 18,
                  color: isEmpty
                      ? AppColors.primary
                      : (isDark ? AppColors.textMuted : AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Shimmer icon placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
