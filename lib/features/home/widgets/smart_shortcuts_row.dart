import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../routes/app_routes.dart';

class SmartShortcutsRow extends ConsumerWidget {
  const SmartShortcutsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S(ref.watch(languageProvider).language);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          Expanded(
            child: _buildShortcut(
              context,
              icon: Icons.search_rounded,
              label: s.findTherapist,
              color: Colors.blue,
              onTap: () => context.push(AppRoutes.therapists),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildShortcut(
              context,
              icon: Icons.assignment_outlined,
              label: s.selfTests,
              color: Colors.purple,
              onTap: () => context.push(AppRoutes.psychologicalTests),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildShortcut(
              context,
              icon: Icons.workspace_premium_rounded,
              label: s.premium,
              color: Colors.amber,
              onTap: () => context.push(AppRoutes.subscription),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildShortcut(
              context,
              icon: Icons.people_outline_rounded,
              label: s.community,
              color: Colors.green,
              onTap: () => context.push(AppRoutes.community),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcut(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
