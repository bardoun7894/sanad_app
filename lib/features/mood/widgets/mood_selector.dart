import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';

enum MoodType { happy, calm, neutral, anxious, sad, angry, tired }

class MoodData {
  final MoodType type;
  final String emoji;
  final String label;
  final Color backgroundColor;

  const MoodData({
    required this.type,
    required this.emoji,
    required this.label,
    required this.backgroundColor,
  });
}

class MoodSelector extends ConsumerWidget {
  final MoodType? selectedMood;
  final Function(MoodType) onMoodSelected;
  final VoidCallback? onViewHistory;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
    this.onViewHistory,
  });

  List<MoodData> _getMoods(S s) => [
    MoodData(
      type: MoodType.happy,
      emoji: '😊',
      label: s.moodHappy,
      backgroundColor: AppColors.moodHappy,
    ),
    MoodData(
      type: MoodType.calm,
      emoji: '😌',
      label: s.moodCalm,
      backgroundColor: AppColors.moodCalm,
    ),
    MoodData(
      type: MoodType.neutral,
      emoji: '😐',
      label: s.moodNeutral,
      backgroundColor: AppColors.softBlue, // Using a neutral color
    ),
    MoodData(
      type: MoodType.anxious,
      emoji: '😨',
      label: s.moodAnxious,
      backgroundColor: AppColors.moodAnxious,
    ),
    MoodData(
      type: MoodType.sad,
      emoji: '😢',
      label: s.moodSad,
      backgroundColor: AppColors.moodSad,
    ),
    MoodData(
      type: MoodType.angry,
      emoji: '😠',
      label: s.moodAngry,
      backgroundColor: AppColors.error, // Red for angry
    ),
    MoodData(
      type: MoodType.tired,
      emoji: '😴',
      label: s.moodTired,
      backgroundColor: AppColors.moodTired,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final moods = _getMoods(s);

    return Column(
      children: [
        Text(
          s.howAreYouFeeling,
          style: AppTypography.headingMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Wrap(
            spacing: 12,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: moods.map((mood) {
              return _MoodItem(
                mood: mood,
                isSelected: selectedMood == mood.type,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onMoodSelected(mood.type);
                },
              );
            }).toList(),
          ),
        ),
        if (onViewHistory != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          GestureDetector(
            onTap: onViewHistory,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  s.viewMoodHistory,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_back_ios_rounded, // RTL arrow direction
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodItem extends StatefulWidget {
  final MoodData mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodItem({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MoodItem> createState() => _MoodItemState();
}

class _MoodItemState extends State<_MoodItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_MoodItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isSelected ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? widget.mood.backgroundColor.withValues(alpha: 0.3)
                    : widget.mood.backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isSelected
                      ? widget.mood.backgroundColor
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: widget.mood.backgroundColor.withValues(
                            alpha: 0.5,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  widget.mood.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mood.label,
              style: AppTypography.labelSmall.copyWith(
                color: widget.isSelected
                    ? (isDark ? Colors.white : AppColors.textLight)
                    : AppColors.textMuted,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
