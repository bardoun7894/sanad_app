import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_action_config.dart';
import '../providers/quick_actions_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class QuickActionsSettingsSheet extends ConsumerWidget {
  const QuickActionsSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickActionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.softBlue,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: AppTypography.headingMedium.copyWith(
                              color: isDark ? Colors.white : AppColors.textLight,
                            ),
                          ),
                          Text(
                            'Customize your + button menu',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(quickActionsProvider.notifier).resetToDefaults();
                      },
                      child: Text(
                        'Reset',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _QuickActionsPreview(
                  actions: state.visibleActions,
                  isDark: isDark,
                ),
              ),

              const SizedBox(height: 24),

              // Actions list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Text(
                      'Available Actions',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toggle actions on/off. Drag to reorder.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // All available action types
                    ...QuickActionType.values.map((type) {
                      final config = state.actions.firstWhere(
                        (a) => a.type == type,
                        orElse: () => QuickActionConfig(
                          type: type,
                          isEnabled: false,
                          order: 999,
                        ),
                      );

                      return _ActionConfigItem(
                        type: type,
                        isEnabled: config.isEnabled,
                        isDark: isDark,
                        onToggle: () {
                          HapticFeedback.lightImpact();
                          ref.read(quickActionsProvider.notifier).toggleAction(type);
                        },
                      );
                    }),

                    const SizedBox(height: 24),

                    // Primary action setting
                    _PrimaryActionSetting(
                      currentPrimary: state.primaryAction,
                      isDark: isDark,
                      onChanged: (type) {
                        ref.read(quickActionsProvider.notifier).setPrimaryAction(type);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Max visible setting
                    _MaxVisibleSetting(
                      currentValue: state.maxVisibleActions,
                      isDark: isDark,
                      onChanged: (value) {
                        ref.read(quickActionsProvider.notifier).setMaxVisible(value);
                      },
                    ),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionsPreview extends StatelessWidget {
  final List<QuickActionConfig> actions;
  final bool isDark;

  const _QuickActionsPreview({
    required this.actions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Preview',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (actions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No actions enabled',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((config) {
                final color = QuickActionConfig.getColor(config.type);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        QuickActionConfig.getIcon(config.type),
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        QuickActionConfig.getLabel(config.type),
                        style: AppTypography.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ActionConfigItem extends StatelessWidget {
  final QuickActionType type;
  final bool isEnabled;
  final bool isDark;
  final VoidCallback onToggle;

  const _ActionConfigItem({
    required this.type,
    required this.isEnabled,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = QuickActionConfig.getColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isEnabled
              ? color.withValues(alpha: 0.3)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: ListTile(
        onTap: onToggle,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isEnabled
                ? (isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1))
                : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            QuickActionConfig.getIcon(type),
            color: isEnabled ? color : AppColors.textMuted,
          ),
        ),
        title: Text(
          QuickActionConfig.getLabel(type),
          style: AppTypography.labelLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textLight,
          ),
        ),
        subtitle: Text(
          QuickActionConfig.getDescription(type),
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        trailing: Switch.adaptive(
          value: isEnabled,
          onChanged: (_) => onToggle(),
          activeColor: color,
        ),
      ),
    );
  }
}

class _MaxVisibleSetting extends StatelessWidget {
  final int currentValue;
  final bool isDark;
  final Function(int) onChanged;

  const _MaxVisibleSetting({
    required this.currentValue,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Max Visible Actions',
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  '$currentValue',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [2, 3, 4, 5, 6].map((value) {
              final isSelected = currentValue == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onChanged(value);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textDark : AppColors.textLight),
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionSetting extends StatelessWidget {
  final QuickActionType currentPrimary;
  final bool isDark;
  final Function(QuickActionType) onChanged;

  const _PrimaryActionSetting({
    required this.currentPrimary,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Action (Tap)',
                      style: AppTypography.labelLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textLight,
                      ),
                    ),
                    Text(
                      'Long-press for more options',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: QuickActionType.values.map((type) {
              final isSelected = currentPrimary == type;
              final color = QuickActionConfig.getColor(type);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChanged(type);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? color.withValues(alpha: 0.3) : color)
                        : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        QuickActionConfig.getIcon(type),
                        size: 18,
                        color: isSelected ? (isDark ? Colors.white : Colors.white) : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        QuickActionConfig.getLabel(type),
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? (isDark ? Colors.white : Colors.white) : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Helper to show settings
void showQuickActionsSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QuickActionsSettingsSheet(),
  );
}
