import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/content_share_utils.dart';
import '../../../content/models/content_models.dart';

class TipContentCard extends StatelessWidget {
  final ContentItem content;
  final VoidCallback onTap;

  const TipContentCard({
    super.key,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXl,
        vertical: AppTheme.spacingXs,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF2D1B35) : const Color(0xFFFDF2F8),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF9D174D).withValues(alpha: 0.2)
                  : const Color(0xFFFBCFE8),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFFEC4899).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -25,
                bottom: -25,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFEC4899).withValues(alpha: 0.06)
                        : const Color(0xFFEC4899).withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFFBBF24).withValues(alpha: 0.08)
                        : const Color(0xFFFBBF24).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFFEC4899).withValues(alpha: 0.15)
                                : const Color(0xFFEC4899).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.lightbulb_rounded,
                            color: isDark
                                ? const Color(0xFFF472B6)
                                : const Color(0xFFDB2777),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          content.title.isEmpty ? 'نصيحة اليوم' : content.title,
                          style: AppTypography.headingSmall.copyWith(
                            color: isDark
                                ? const Color(0xFFF472B6)
                                : const Color(0xFFBE185D),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Body text
                    Text(
                      content.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFF1E293B),
                        fontSize: 15,
                        height: 1.7,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TipActionButton(
                          icon: Icons.share_outlined,
                          label: 'مشاركة',
                          onTap: () =>
                              ContentShareUtils.shareContent(content),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 12),
                        _TipActionButton(
                          icon: Icons.favorite_border_rounded,
                          label: 'أعجبني',
                          onTap: () =>
                              ContentShareUtils.shareViaWhatsApp(content),
                          isDark: isDark,
                          isPrimary: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPrimary;

  const _TipActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isPrimary
        ? const Color(0xFFEC4899)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary
              ? (isDark
                  ? const Color(0xFFEC4899).withValues(alpha: 0.12)
                  : const Color(0xFFEC4899).withValues(alpha: 0.08))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFFEC4899).withValues(alpha: 0.2)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0)),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: baseColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: baseColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
