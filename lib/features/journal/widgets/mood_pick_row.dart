import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../mood/models/mood_enums.dart';

/// Horizontal row of selectable mood emoji chips (optional per-entry mood).
class MoodPickRow extends StatelessWidget {
  final MoodType? selected;
  final ValueChanged<MoodType?> onChanged;

  const MoodPickRow({super.key, required this.selected, required this.onChanged});

  Color _bg(MoodType m) {
    switch (m) {
      case MoodType.happy:
        return AppColors.moodHappy;
      case MoodType.calm:
        return AppColors.moodCalm;
      case MoodType.anxious:
        return AppColors.moodAnxious;
      case MoodType.sad:
        return AppColors.moodSad;
      case MoodType.angry:
        return AppColors.moodAngry;
      case MoodType.tired:
        return AppColors.moodTired;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MoodType.values.map((m) {
          final isSel = selected == m;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(isSel ? null : m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? _bg(m) : _bg(m).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      MoodTypeExtension.emoji(m),
                      style: const TextStyle(fontSize: 20),
                    ),
                    if (isSel) ...[
                      const SizedBox(width: 6),
                      Text(
                        MoodTypeExtension.label(m),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
