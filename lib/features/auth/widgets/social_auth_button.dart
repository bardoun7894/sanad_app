import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sanad_app/core/theme/app_colors.dart';
import 'package:sanad_app/core/theme/app_typography.dart';

/// Button for social authentication (Google, Apple, etc.)
class SocialAuthButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isGoogle;

  const SocialAuthButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isGoogle = true,
  });

  Widget _buildIcon(bool isDark) {
    // Use Icon widgets as fallback for missing SVGs
    if (icon.contains('google')) {
      return SvgPicture.asset(
        icon,
        width: 20,
        height: 20,
      );
    } else if (icon.contains('apple')) {
      return Icon(
        Icons.apple,
        size: 24,
        color: isDark ? AppColors.textLight : AppColors.textDark,
      );
    }
    return SvgPicture.asset(
      icon,
      width: 20,
      height: 20,
      colorFilter: ColorFilter.mode(
        isDark ? AppColors.textLight : AppColors.textDark,
        BlendMode.srcIn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? AppColors.textLight
                              : AppColors.textDark,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIcon(isDark),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textLight
                                : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
