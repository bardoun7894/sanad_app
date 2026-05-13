import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../../core/l10n/language_provider.dart';

class ChatCtaCard extends ConsumerWidget {
  final VoidCallback? onStartChat;

  const ChatCtaCard({super.key, this.onStartChat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      padding: const EdgeInsets.all(20),
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
          // Icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.success.withValues(alpha: 0.15)
                      : const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.support_agent_rounded,
                size: 24,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            s.needToTalk,
            style: AppTypography.headingMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              s.specialistsAvailable,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // CTA Button
          SanadButton(
            text: s.startInstantChat,
            icon: Icons.chat_bubble_outline_rounded,
            onPressed: onStartChat,
            isFullWidth: true,
            size: SanadButtonSize.medium,
          ),
        ],
      ),
    );
  }
}
