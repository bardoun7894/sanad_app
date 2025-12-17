import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/therapist.dart';

class TherapistCard extends ConsumerWidget {
  final Therapist therapist;
  final VoidCallback onTap;
  final VoidCallback? onBookNow;

  const TherapistCard({
    super.key,
    required this.therapist,
    required this.onTap,
    this.onBookNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.softBlue,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    child: therapist.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            child: Image.network(
                              therapist.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                            ),
                          )
                        : _buildAvatarPlaceholder(),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                therapist.name,
                                style: AppTypography.headingSmall.copyWith(
                                  color: isDark ? Colors.white : AppColors.textLight,
                                ),
                              ),
                            ),
                            if (therapist.isAvailableToday)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          therapist.title,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Rating and experience
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.moodHappy,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              therapist.rating.toStringAsFixed(1),
                              style: AppTypography.labelMedium.copyWith(
                                color: isDark ? Colors.white : AppColors.textLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              ' (${therapist.reviewCount})',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.work_outline_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${therapist.yearsExperience} ${s.years}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Specialties
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: therapist.specialties.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final specialty = therapist.specialties[index];
                    final color = SpecialtyData.getColor(specialty);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? color.withValues(alpha: 0.2)
                            : color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                      ),
                      child: Text(
                        SpecialtyData.getLabel(specialty, strings: s),
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Divider
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        therapist.formattedPrice,
                        style: AppTypography.headingSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        s.perSession,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Availability
                  if (therapist.nextAvailable != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: therapist.isAvailableToday
                            ? AppColors.success.withValues(alpha: 0.1)
                            : (isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: therapist.isAvailableToday
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            therapist.nextAvailable!,
                            style: AppTypography.caption.copyWith(
                              color: therapist.isAvailableToday
                                  ? AppColors.success
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Book button
                  GestureDetector(
                    onTap: onBookNow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Text(
                        s.bookNow,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Center(
      child: Text(
        therapist.name.split(' ').map((e) => e[0]).take(2).join(),
        style: AppTypography.headingMedium.copyWith(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// Compact version for horizontal lists
class TherapistCardCompact extends ConsumerWidget {
  final Therapist therapist;
  final VoidCallback onTap;

  const TherapistCardCompact({
    super.key,
    required this.therapist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.softBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    therapist.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              therapist.name,
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Title
            Text(
              therapist.title,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Rating
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.moodHappy,
                ),
                const SizedBox(width: 4),
                Text(
                  therapist.rating.toStringAsFixed(1),
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white : AppColors.textLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  therapist.formattedPrice,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
