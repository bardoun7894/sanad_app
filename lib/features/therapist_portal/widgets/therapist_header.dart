import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../routes/app_routes.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/therapist_profile.dart';

class TherapistHeader extends ConsumerWidget {
  final TherapistProfile? profile;
  final bool isOnline;
  final VoidCallback onToggleOnline;
  final VoidCallback onProfileTap;

  const TherapistHeader({
    super.key,
    required this.profile,
    required this.isOnline,
    required this.onToggleOnline,
    required this.onProfileTap,
  });

  String _getTimeBasedGreeting(S s) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return s.goodMorning;
    } else if (hour < 17) {
      return s.goodAfternoon;
    } else if (hour < 21) {
      return s.goodEvening;
    } else {
      return s.goodNight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = _getTimeBasedGreeting(s);

    final initial = (profile?.name ?? '').isNotEmpty
        ? profile!.name[0].toUpperCase()
        : 'T';

    return Row(
      children: [
        // Avatar and greeting
        Expanded(
          child: GestureDetector(
            onTap: onProfileTap,
            child: Row(
              children: [
                _buildAvatar(isDark, initial),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile?.name ?? 'Dr. Therapist',
                        style: AppTypography.headingMedium.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Online Toggle and Notifications
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusToggle(context, s, isDark),
            const SizedBox(width: 12),
            _buildNotificationButton(context, ref, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar(bool isDark, String initial) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.softBlue,
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.white,
          width: 2,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: profile?.photoUrl != null
          ? ClipOval(
              child: Image.network(
                profile!.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitial(initial),
              ),
            )
          : _buildInitial(initial),
    );
  }

  Widget _buildInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: AppTypography.headingMedium.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildStatusToggle(BuildContext context, S s, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? const Color(0xFF4ADE80) : Colors.grey,
              boxShadow: isOnline
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: isOnline,
              onChanged: (_) => onToggleOnline(),
              activeThumbColor: const Color(0xFF4ADE80),
              activeTrackColor: const Color(0xFF4ADE80).withValues(alpha: 0.2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.notifications),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.notifications_outlined,
                size: 24,
                color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.backgroundDark : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
