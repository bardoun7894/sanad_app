import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Interactive star rating widget
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showValue;
  final int? reviewCount;
  final MainAxisAlignment alignment;
  final void Function(int)? onRatingChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.showValue = false,
    this.reviewCount,
    this.alignment = MainAxisAlignment.start,
    this.onRatingChanged,
  });

  /// Small display version for cards
  const RatingStars.small({
    super.key,
    required this.rating,
    this.reviewCount,
  }) : size = 16.0,
       activeColor = null,
       inactiveColor = null,
       showValue = true,
       alignment = MainAxisAlignment.start,
       onRatingChanged = null;

  /// Large interactive version for input
  const RatingStars.interactive({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40.0,
  }) : activeColor = null,
       inactiveColor = null,
       showValue = false,
       reviewCount = null,
       alignment = MainAxisAlignment.center;

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? Colors.amber;
    final inactive = inactiveColor ?? Colors.grey.shade300;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        // Stars
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            final isFullStar = rating >= starNumber;
            final isHalfStar = rating >= starNumber - 0.5 && rating < starNumber;

            Widget star;
            if (isFullStar) {
              star = Icon(Icons.star_rounded, color: active, size: size);
            } else if (isHalfStar) {
              star = Icon(Icons.star_half_rounded, color: active, size: size);
            } else {
              star = Icon(Icons.star_border_rounded, color: inactive, size: size);
            }

            if (onRatingChanged != null) {
              return GestureDetector(
                onTap: () => onRatingChanged!(starNumber),
                child: star,
              );
            }

            return star;
          }),
        ),

        // Rating value and count
        if (showValue || reviewCount != null) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: TextStyle(
                fontSize: size * 0.5,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
