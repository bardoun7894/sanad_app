import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/providers/system_settings_provider.dart';
import '../../therapists/models/therapist.dart';
import '../models/therapist_profile.dart';
import '../providers/therapist_registration_provider.dart';

class TherapistRegistrationScreen extends ConsumerStatefulWidget {
  const TherapistRegistrationScreen({super.key});

  @override
  ConsumerState<TherapistRegistrationScreen> createState() =>
      _TherapistRegistrationScreenState();
}

class _TherapistRegistrationScreenState
    extends ConsumerState<TherapistRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step 1 controllers
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 controllers
  final _qualificationController = TextEditingController();

  // Step 3 controllers
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _qualificationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(therapistRegistrationProvider);
    final notifier = ref.read(therapistRegistrationProvider.notifier);
    final strings = ref.watch(stringsProvider);
    final settingsAsync = ref.watch(systemSettingsProvider);

    // Self-signup gate — when admin has disabled the flag, deeplinks land
    // on a "contact admin" page instead of the multi-step form.
    final selfSignupEnabled = settingsAsync.maybeWhen(
      data: (s) => s.enableTherapistApplication,
      orElse: () => false,
    );
    if (!selfSignupEnabled && !state.isSubmitted) {
      return _buildSelfSignupDisabledScreen(context, strings);
    }

    // If already submitted, show pending screen
    if (state.isSubmitted) {
      return _buildSubmittedScreen(context, state, strings);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.therapistRegistration),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(context, state.currentStep),

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildCurrentStep(context, state, notifier, strings),
              ),
            ),
          ),

          // Bottom navigation
          _buildBottomNavigation(context, state, notifier, strings),
        ],
      ),
    );
  }

  Widget _buildSelfSignupDisabledScreen(
    BuildContext context,
    dynamic strings,
  ) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology_outlined,
                  size: 72, color: AppColors.primary.withValues(alpha: 0.7)),
              const SizedBox(height: 24),
              Text(
                'Therapist registration is closed',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'New therapists are onboarded by the Sanad team. '
                'Please contact us if you would like to join.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: List.generate(3, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.primary
                        : isCurrent
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.grey.shade200,
                    border: isCurrent
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.primary
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(
    BuildContext context,
    TherapistRegistrationState state,
    TherapistRegistrationNotifier notifier,
    S strings,
  ) {
    switch (state.currentStep) {
      case 0:
        return _buildStep1(context, state, notifier, strings);
      case 1:
        return _buildStep2(context, state, notifier, strings);
      case 2:
        return _buildStep3(context, state, notifier, strings);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(
    BuildContext context,
    TherapistRegistrationState state,
    TherapistRegistrationNotifier notifier,
    S strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.basicInformation,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          strings.tellUsAboutYourself,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Name field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: strings.fullName,
            hintText: strings.enterFullName,
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return strings.pleaseEnterName;
            }
            return null;
          },
          onChanged: (value) => notifier.updateStep1(name: value),
        ),
        const SizedBox(height: 16),

        // Title field
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: strings.professionalTitle,
            hintText: strings.egClinicalPsychologist,
            prefixIcon: const Icon(Icons.work_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return strings.pleaseEnterTitle;
            }
            return null;
          },
          onChanged: (value) => notifier.updateStep1(title: value),
        ),
        const SizedBox(height: 16),

        // Bio field
        TextFormField(
          controller: _bioController,
          decoration: InputDecoration(
            labelText: strings.bio,
            hintText: strings.describeProfessionalBackground,
            prefixIcon: const Icon(Icons.description_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 4,
          maxLength: 500,
          validator: (value) {
            if (value == null || value.length < 50) {
              return strings.bioMinLength;
            }
            return null;
          },
          onChanged: (value) => notifier.updateStep1(bio: value),
        ),
        const SizedBox(height: 16),

        // Phone field (optional)
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: '${strings.phoneNumber} (${strings.optional})',
            hintText: strings.enterPhoneNumber,
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => notifier.updateStep1(phoneNumber: value),
        ),
      ],
    );
  }

  Widget _buildStep2(
    BuildContext context,
    TherapistRegistrationState state,
    TherapistRegistrationNotifier notifier,
    S strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.professionalDetails,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          strings.shareExpertise,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Specialties
        Text(
          strings.specialties,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Specialty.values.map((specialty) {
            final isSelected = state.registrationData.specialties.contains(
              specialty,
            );
            return FilterChip(
              label: Text(SpecialtyData.getLabel(specialty, strings: strings)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.addSpecialty(specialty);
                } else {
                  notifier.removeSpecialty(specialty);
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Languages
        Text(strings.languages, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['العربية', 'English', 'Français'].map((language) {
            final isSelected = state.registrationData.languages.contains(
              language,
            );
            return FilterChip(
              label: Text(language),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.addLanguage(language);
                } else {
                  notifier.removeLanguage(language);
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Years of experience
        Text(
          strings.yearsOfExperience,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: state.registrationData.yearsExperience.toDouble(),
                min: 0,
                max: 30,
                divisions: 30,
                label:
                    '${state.registrationData.yearsExperience} ${strings.years}',
                onChanged: (value) {
                  notifier.updateStep2(yearsExperience: value.toInt());
                },
              ),
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${state.registrationData.yearsExperience}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Qualifications
        Text(
          strings.qualifications,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _qualificationController,
                decoration: InputDecoration(
                  hintText: strings.addQualification,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                if (_qualificationController.text.isNotEmpty) {
                  notifier.addQualification(_qualificationController.text);
                  _qualificationController.clear();
                }
              },
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              iconSize: 32,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: state.registrationData.qualifications.map((q) {
            return Chip(
              label: Text(q),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => notifier.removeQualification(q),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3(
    BuildContext context,
    TherapistRegistrationState state,
    TherapistRegistrationNotifier notifier,
    S strings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.sessionInformation,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          strings.defineSessionDetails,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Session types
        Text(
          strings.sessionTypes,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SessionType.values.map((type) {
            final isSelected = state.registrationData.sessionTypes.contains(
              type,
            );
            return FilterChip(
              avatar: Icon(
                SessionTypeData.getIcon(type),
                size: 18,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
              label: Text(SessionTypeData.getLabel(type, strings: strings)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.addSessionType(type);
                } else {
                  notifier.removeSessionType(type);
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Session price
        Text(
          strings.sessionPrice,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return strings.pleaseEnterPrice;
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return strings.invalidPrice;
                  }
                  return null;
                },
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 0.0;
                  notifier.updateStep3(sessionPrice: price);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: state.registrationData.currency,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['USD', 'SAR', 'EUR'].map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    notifier.updateStep3(currency: value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Terms notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.registrationReviewNotice,
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    TherapistRegistrationState state,
    TherapistRegistrationNotifier notifier,
    S strings,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (state.currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => notifier.previousStep(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(strings.previous),
                ),
              ),
            if (state.currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: state.currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        if (state.currentStep < 2) {
                          if (_formKey.currentState?.validate() ?? false) {
                            notifier.nextStep();
                          }
                        } else {
                          if (_formKey.currentState?.validate() ?? false) {
                            notifier.submitRegistration();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        state.currentStep < 2
                            ? strings.next
                            : strings.submitRegistration,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedScreen(
    BuildContext context,
    TherapistRegistrationState state,
    S strings,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.registrationStatus),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state.status == TherapistApprovalStatus.pending
                    ? Icons.hourglass_empty
                    : state.status == TherapistApprovalStatus.approved
                    ? Icons.check_circle
                    : Icons.error,
                size: 80,
                color: state.status == TherapistApprovalStatus.pending
                    ? Colors.orange
                    : state.status == TherapistApprovalStatus.approved
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                state.status == TherapistApprovalStatus.pending
                    ? strings.registrationPending
                    : state.status == TherapistApprovalStatus.approved
                    ? strings.registrationApproved
                    : strings.registrationRejected,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                state.status == TherapistApprovalStatus.pending
                    ? strings.registrationPendingDesc
                    : state.status == TherapistApprovalStatus.approved
                    ? strings.registrationApprovedDesc
                    : strings.registrationRejectedDesc,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (state.status == TherapistApprovalStatus.approved)
                ElevatedButton(
                  onPressed: () => context.go('/therapist/dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(strings.goToDashboard),
                ),
              if (state.status == TherapistApprovalStatus.pending)
                OutlinedButton(
                  onPressed: () => ref
                      .read(therapistRegistrationProvider.notifier)
                      .refreshStatus(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(strings.checkStatus),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
