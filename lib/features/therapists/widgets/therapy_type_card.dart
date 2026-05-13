import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/therapist.dart';

class TherapyTypeCard extends ConsumerWidget {
  final TherapyType type;
  final bool isSelected;
  final VoidCallback onTap;

  const TherapyTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = TherapyTypeData.getColor(type);

    final isSelectedEffective = isSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelectedEffective
            ? (isDark
                  ? color.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.08))
            : (isDark ? AppColors.surfaceDark : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelectedEffective
              ? color
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isSelectedEffective ? 1.5 : 1,
        ),
        boxShadow: isSelectedEffective
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Icon Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelectedEffective
                        ? color
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    TherapyTypeData.getIcon(type),
                    size: 18,
                    color: isSelectedEffective ? Colors.white : color,
                  ),
                ),
                const SizedBox(width: 12),

                // Text Content
                Expanded(
                  child: Text(
                    TherapyTypeData.getLabel(type, strings: s),
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: isSelectedEffective
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),

                // Check circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelectedEffective ? 22 : 0,
                  height: isSelectedEffective ? 22 : 0,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: isSelectedEffective
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
