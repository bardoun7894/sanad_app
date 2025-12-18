import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/theme/app_colors.dart';
import 'package:sanad_app/core/theme/app_typography.dart';
import 'package:sanad_app/core/widgets/sanad_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    // Listen for errors
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        _showErrorSnackbar(context, next.errorMessage!);
      }
    });

    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),

                  // Header
                  Text(
                    s.completeProfile,
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.helpUsKnowYou,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Full name field (required)
                  AuthTextField(
                    controller: _nameController,
                    label: s.fullName,
                    hint: s.enterFullName,
                    prefixIcon: Icon(
                      Icons.person_outlined,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.fieldRequired;
                      }
                      if (value.length < 2) {
                        return s.nameTooShort;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Phone number field (optional)
                  AuthTextField(
                    controller: _phoneController,
                    label: s.phoneNumber,
                    hint: s.enterPhoneNumber,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Date of birth (optional)
                  InkWell(
                    onTap: () => _showDatePicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark.withOpacity(0.5)
                            : AppColors.surfaceLight,
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark.withOpacity(0.5)
                              : AppColors.borderLight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedLight,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? _formatDate(_selectedDate!)
                                  : s.dateOfBirth,
                              style: AppTypography.bodyMedium.copyWith(
                                color: _selectedDate != null
                                    ? (isDark
                                          ? AppColors.textLight
                                          : AppColors.textDark)
                                    : (isDark
                                          ? AppColors.textMuted
                                          : AppColors.textMutedLight),
                              ),
                            ),
                          ),
                          if (_selectedDate != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = null;
                                });
                              },
                              child: Icon(
                                Icons.close,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textMutedLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Gender dropdown (optional)
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    hint: Text(s.gender),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark.withOpacity(0.5)
                          : AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark.withOpacity(0.5)
                              : AppColors.borderLight,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.wc_outlined,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedLight,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(value: 'male', child: Text(s.male)),
                      DropdownMenuItem(value: 'female', child: Text(s.female)),
                      DropdownMenuItem(value: 'other', child: Text(s.other)),
                      DropdownMenuItem(
                        value: 'prefer_not_to_say',
                        child: Text(s.preferNotToSay),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),

                  const SizedBox(height: 40),

                  // Continue button
                  SanadButton(
                    onPressed: _handleProfileCompletion,
                    text: s.continueText,
                    isLoading: authState.isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Skip for now
                  TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () {
                            // Navigate to home without completing profile
                            // This will be handled by router redirect
                            ref
                                .read(authProvider.notifier)
                                .completeProfile(
                                  displayName: _nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : 'User',
                                );
                          },
                    child: Text(s.skipForNow),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleProfileCompletion() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authProvider.notifier)
          .completeProfile(
            displayName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.isNotEmpty
                ? _phoneController.text.trim()
                : null,
            dateOfBirth: _selectedDate,
            gender: _selectedGender,
          );
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
