import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/language_provider.dart';
import '../models/therapist.dart';

class TherapyIntakeSheet extends ConsumerStatefulWidget {
  final TherapyType selectedType;
  final Function(List<String> issues, String note) onConfirm;

  const TherapyIntakeSheet({
    super.key,
    required this.selectedType,
    required this.onConfirm,
  });
  @override
  ConsumerState<TherapyIntakeSheet> createState() => _TherapyIntakeSheetState();
}

class _TherapyIntakeSheetState extends ConsumerState<TherapyIntakeSheet> {
  final _noteController = TextEditingController();
  final Set<String> _selectedIssues = {};

  Map<String, String> _getCommonIssues(S s) => {
    'Anxiety': s.issueAnxiety,
    'Depression': s.issueDepression,
    'Stress': s.issueStress,
    'Relationships': s.issueRelationships,
    'Trauma': s.issueTrauma,
    'Family': s.issueFamily,
    'Work': s.issueWork,
    'Grief': s.issueGrief,
    'Self-esteem': s.issueSelfEsteem,
    'Sleep': s.issueSleep,
  };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                s.intakeTitle,
                style: AppTypography.headingMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.intakeSubtitle,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              Wrap(
                spacing: 8,
                runSpacing: 12,
                children: _getCommonIssues(s).entries.map((entry) {
                  final isSelected = _selectedIssues.contains(entry.key);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedIssues.add(entry.key);
                        } else {
                          _selectedIssues.remove(entry.key);
                        }
                      });
                    },
                    checkmarkColor: Colors.white,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark
                        ? AppColors.backgroundDark
                        : Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.textPrimary),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey[300]!,
                        width: isSelected ? 0 : 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              Text(
                s.intakeNoteLabel,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: s.intakeNoteHint,
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.backgroundDark
                      : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onConfirm(
                      _selectedIssues.toList(),
                      _noteController.text.trim(),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    s.findTherapist,
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
