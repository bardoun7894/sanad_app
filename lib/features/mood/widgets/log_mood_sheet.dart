import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import 'mood_selector.dart';

class LogMoodSheet extends StatefulWidget {
  final Function(MoodType mood, String? note) onSave;
  final MoodType? initialMood;

  const LogMoodSheet({
    super.key,
    required this.onSave,
    this.initialMood,
  });

  @override
  State<LogMoodSheet> createState() => _LogMoodSheetState();
}

class _LogMoodSheetState extends State<LogMoodSheet> {
  MoodType? _selectedMood;
  final _noteController = TextEditingController();
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveMood() {
    if (_selectedMood == null) return;

    HapticFeedback.mediumImpact();
    widget.onSave(_selectedMood!, _noteController.text.isEmpty ? null : _noteController.text);

    setState(() {
      _showSuccess = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showSuccess) {
      return _SuccessAnimation(isDark: isDark);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'How are you feeling?',
                style: AppTypography.displaySmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your mood and add an optional note',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // Mood options
              _MoodGrid(
                selectedMood: _selectedMood,
                onMoodSelected: (mood) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedMood = mood;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Note input
              Text(
                'Add a note (optional)',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLength: 280,
                  maxLines: 3,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind?',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SanadButton(
                text: 'Log Mood',
                icon: Icons.check_rounded,
                onPressed: _selectedMood != null ? _saveMood : null,
                isFullWidth: true,
                size: SanadButtonSize.large,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodGrid extends StatelessWidget {
  final MoodType? selectedMood;
  final Function(MoodType) onMoodSelected;

  const _MoodGrid({
    required this.selectedMood,
    required this.onMoodSelected,
  });

  static const List<_MoodOption> moods = [
    _MoodOption(MoodType.happy, '😊', 'Happy', AppColors.moodHappy),
    _MoodOption(MoodType.calm, '😌', 'Calm', AppColors.moodCalm),
    _MoodOption(MoodType.tired, '😴', 'Tired', AppColors.moodTired),
    _MoodOption(MoodType.anxious, '😨', 'Anxious', AppColors.moodAnxious),
    _MoodOption(MoodType.sad, '😢', 'Sad', AppColors.moodSad),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: moods.map((mood) {
        final isSelected = selectedMood == mood.type;

        return GestureDetector(
          onTap: () => onMoodSelected(mood.type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 48 - 24) / 3,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? mood.color.withValues(alpha: 0.3)
                      : mood.color)
                  : (isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isSelected
                    ? mood.color
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  mood.emoji,
                  style: TextStyle(fontSize: isSelected ? 32 : 28),
                ),
                const SizedBox(height: 8),
                Text(
                  mood.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.textLight)
                        : AppColors.textMuted,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MoodOption {
  final MoodType type;
  final String emoji;
  final String label;
  final Color color;

  const _MoodOption(this.type, this.emoji, this.label, this.color);
}

class _SuccessAnimation extends StatefulWidget {
  final bool isDark;

  const _SuccessAnimation({required this.isDark});

  @override
  State<_SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<_SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mood Logged!',
              style: AppTypography.headingMedium.copyWith(
                color: widget.isDark ? Colors.white : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep tracking to see your patterns',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
