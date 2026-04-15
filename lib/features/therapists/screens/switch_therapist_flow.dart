import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/theme/app_colors.dart';
import 'package:sanad_app/core/theme/app_typography.dart';
import 'package:sanad_app/core/widgets/sanad_button.dart';
import '../models/therapist.dart';

class SwitchTherapistFlow extends ConsumerStatefulWidget {
  final Therapist currentTherapist;

  const SwitchTherapistFlow({super.key, required this.currentTherapist});

  @override
  ConsumerState<SwitchTherapistFlow> createState() =>
      _SwitchTherapistFlowState();
}

class _SwitchTherapistFlowState extends ConsumerState<SwitchTherapistFlow> {
  int _currentStep = 0;
  String? _selectedReason;
  final List<Specialty> _selectedSpecialties = [];
  String? _preferredGender;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.switchTherapist),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
            _handleSwitch();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, controls) {
          return Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Row(
              children: [
                Expanded(
                  child: SanadButton(
                    onPressed: controls.onStepContinue,
                    text: _currentStep == 2 ? s.switchConfirm : s.next,
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controls.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(s.back),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Reason
          Step(
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            title: const Text(''),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.whySwitch, style: AppTypography.headingSmall),
                const SizedBox(height: 24),
                _buildReasonTile(s.reasonNotHappy, 'communication'),
                _buildReasonTile(s.reasonPrice, 'price'),
                _buildReasonTile(s.reasonAvailability, 'availability'),
                _buildReasonTile(s.reasonOther, 'other'),
              ],
            ),
          ),
          // Step 2: Preferences
          Step(
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            title: const Text(''),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.primaryGoals, style: AppTypography.headingSmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        Specialty.anxiety,
                        Specialty.depression,
                        Specialty.relationships,
                        Specialty.trauma,
                        Specialty.stress,
                      ].map((specialty) {
                        final isSelected = _selectedSpecialties.contains(
                          specialty,
                        );
                        return FilterChip(
                          label: Text(
                            SpecialtyData.getLabel(specialty, strings: s),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSpecialties.add(specialty);
                              } else {
                                _selectedSpecialties.remove(specialty);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                ),
                const SizedBox(height: 32),
                Text(s.preferredGender, style: AppTypography.headingSmall),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildGenderButton(s.male, 'male'),
                    const SizedBox(width: 12),
                    _buildGenderButton(s.female, 'female'),
                    const SizedBox(width: 12),
                    _buildGenderButton(s.any, 'any'),
                  ],
                ),
              ],
            ),
          ),
          // Step 3: Confirmation
          Step(
            isActive: _currentStep >= 2,
            title: const Text(''),
            content: Column(
              children: [
                const Icon(
                  Icons.sync_problem_rounded,
                  size: 64,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 24),
                Text(
                  '${s.switchTherapist}?',
                  style: AppTypography.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  s.switchProcessMessage,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonTile(String title, String value) {
    final isSelected = _selectedReason == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.05)
            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
        value: value,
        groupValue: _selectedReason,
        onChanged: (val) => setState(() => _selectedReason = val),
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildGenderButton(String label, String value) {
    final isSelected = _preferredGender == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _preferredGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? Colors.white : null,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _handleSwitch() async {
    // Show success snackbar and pop
    final s = ref.read(stringsProvider);

    // In a real app, you would call a service to update the user's connection status
    // and store the feedback/new preferences.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.switchSuccess),
        backgroundColor: AppColors.success,
      ),
    );

    context.pop();
  }
}
