import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/content_share_utils.dart';
import '../../../content/models/content_models.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ExerciseContentCard extends StatelessWidget {
  final ContentItem content;
  final VoidCallback onTap;

  const ExerciseContentCard({
    super.key,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasThumbnail =
        content.thumbnailUrl != null && content.thumbnailUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingXl,
        vertical: AppTheme.spacingXs,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2333) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : const Color(0xFF64748B).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              if (!isDark)
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  if (hasThumbnail)
                    Image.network(
                      content.thumbnailUrl!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(isDark),
                    )
                  else
                    _buildPlaceholderImage(isDark),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? const Color(0xFF1C2333) : Colors.white)
                                .withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.spa_rounded,
                            color: Colors.green,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            content.category ?? 'تمرين',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (content.formattedDuration.isNotEmpty)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 11,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              content.formattedDuration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.localizedTitle(context),
                      style: AppTypography.headingSmall.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content.localizedDescription(context),
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.5,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'ابدأ الآن',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ShareIcon(
                          icon: Icons.share_outlined,
                          onTap: () => ContentShareUtils.shareContent(content),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        _ShareIcon(
                          icon: Icons.chat_outlined,
                          useFaWhatsapp: true,
                          color: const Color(0xFF25D366),
                          onTap: () =>
                              ContentShareUtils.shareViaWhatsApp(content),
                          isDark: isDark,
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

  Widget _buildPlaceholderImage(bool isDark) {
    return Container(
      height: 170,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF312E81), const Color(0xFF1C2333)]
              : [
                  Colors.green.withValues(alpha: 0.12),
                  Colors.green.withValues(alpha: 0.04),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center_outlined,
          size: 40,
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _ShareIcon extends StatelessWidget {
  final IconData icon;
  final bool useFaWhatsapp;
  final Color? color;
  final VoidCallback onTap;
  final bool isDark;

  const _ShareIcon({
    required this.icon,
    this.useFaWhatsapp = false,
    this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor =
        color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
            width: 0.5,
          ),
        ),
        child: Center(
          child: useFaWhatsapp
              ? FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: iconColor)
              : Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}
