import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';

enum ChatMode { ai, admin, therapist }

class ChatHeader extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onEscalate;
  final ChatMode chatMode;
  final String? therapistName;
  final bool isOnline;

  const ChatHeader({
    super.key,
    required this.onBack,
    required this.onEscalate,
    this.chatMode = ChatMode.ai,
    this.therapistName,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),

            // Avatar and info
            _buildAvatar(),
            const SizedBox(width: 12),

            // Title and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(s),
                    style: AppTypography.headingSmall.copyWith(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? AppColors.success : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(s),
                        style: AppTypography.caption.copyWith(
                          color: isOnline ? AppColors.success : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Escalate button (only show for AI mode)
            if (chatMode == ChatMode.ai)
              _EscalateButton(onTap: onEscalate, strings: s),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    switch (chatMode) {
      case ChatMode.ai:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.psychology_rounded,
            size: 24,
            color: Colors.white,
          ),
        );

      case ChatMode.admin:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.support_agent_rounded,
            size: 24,
            color: AppColors.primary,
          ),
        );

      case ChatMode.therapist:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: therapistName != null && therapistName!.isNotEmpty
              ? Center(
                  child: Text(
                    therapistName![0].toUpperCase(),
                    style: AppTypography.headingSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                )
              : Icon(Icons.person_rounded, size: 24, color: AppColors.success),
        );
    }
  }

  String _getTitle(S s) {
    switch (chatMode) {
      case ChatMode.ai:
        return s.sanadSupport;
      case ChatMode.admin:
        return s.supportTeam;
      case ChatMode.therapist:
        return therapistName ?? s.therapist;
    }
  }

  String _getStatusText(S s) {
    if (!isOnline) return s.offlineStatus;

    switch (chatMode) {
      case ChatMode.ai:
        return s.online;
      case ChatMode.admin:
        return s.availableStatus;
      case ChatMode.therapist:
        return s.onlineStatus;
    }
  }
}

class _EscalateButton extends StatelessWidget {
  final VoidCallback onTap;
  final S strings;

  const _EscalateButton({required this.onTap, required this.strings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.success.withValues(alpha: 0.2)
              : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 18, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              strings.humanEscalation,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
