import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../providers/hybrid_chat_provider.dart';

/// Compact banner at the top of the hybrid chat showing the current mode.
///
/// - AI mode: blue icon + "AI Assistant" text
/// - Therapist mode: green icon + therapist name from activeHandoff
class ChatModeIndicator extends ConsumerWidget {
  const ChatModeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final hybridState = ref.watch(hybridChatProvider);

    final isAiMode = hybridState.currentMode == 'ai';
    final therapistName = hybridState.activeHandoff?.therapistName;

    final Color accentColor = isAiMode ? AppColors.info : AppColors.success;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(hybridState.currentMode),
        height: 32,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: isDark ? 0.20 : 0.08),
              accentColor.withValues(alpha: isDark ? 0.08 : 0.02),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border(
            bottom: BorderSide(
              color: accentColor.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAiMode ? Icons.psychology_rounded : Icons.person_rounded,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              isAiMode ? s.aiAssistant : (therapistName ?? 'Live Therapist'),
              style: AppTypography.labelSmall.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
