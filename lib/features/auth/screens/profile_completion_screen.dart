import 'package:flutter/material.dart';
import '../../../core/utils/file_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sanad_app/core/l10n/language_provider.dart';
import 'package:sanad_app/core/theme/app_colors.dart';
import 'package:sanad_app/core/theme/app_typography.dart';
import 'package:sanad_app/core/widgets/sanad_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/phone_input_field.dart';
import '../../therapists/models/therapist.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1: Basic Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  CountryCode _selectedCountryCode = countryCodes.first;
  CountryCode _selectedWhatsAppCountryCode = countryCodes.first;
  bool _whatsAppSameAsPhone = true;
  bool _agreedToWhatsAppAds = false;

  // Page 2: Matching Part 1
  final List<Specialty> _selectedGoals = [];

  // Page 3: Matching Part 2
  String? _preferredTherapistGender;
  String? _relationshipStatus;
  final _medicalHistoryController = TextEditingController();

  // Avatar Selection
  int? _selectedAvatarIndex;
  String? _customAvatarUrl;
  late final PageController _avatarPageController = PageController(
    viewportFraction: 0.42,
    initialPage: 0,
  );

  @override
  void initState() {
    super.initState();
    // Pre-fill user data if available from Auth (e.g., Google login)
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      if (authState.user!.displayName != null) {
        _nameController.text = authState.user!.displayName!;
      }
      if (authState.user!.phoneNumber != null) {
        _phoneController.text = authState.user!.phoneNumber!;
      }
    }
  }

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
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        context.go('/');
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false;
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentPage > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                )
              : null,
          title: Text(
            '${_currentPage + 1} / 3',
            style: AppTypography.labelLarge.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress tracking
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 3,
                  backgroundColor: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 6,
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildBasicInfoPage(context, s, isDark),
                    _buildMatchingPart1Page(context, s, isDark),
                    _buildMatchingPart2Page(context, s, isDark, authState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage(BuildContext context, S s, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.completeProfile, style: AppTypography.headingLarge),
            const SizedBox(height: 8),
            Text(
              s.helpUsKnowYou,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: _nameController,
              label: s.dualName,
              hint: s.enterDualName,
              prefixIcon: const Icon(Icons.person_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) return s.fieldRequired;
                if (value.length < 2) return s.nameTooShort;
                return null;
              },
            ),
            const SizedBox(height: 16),
            PhoneInputField(
              controller: _phoneController,
              label: s.phoneNumberMandatory,
              hint: s.enterPhoneNumber,
              initialCountry: _selectedCountryCode,
              onCountryChanged: (country) {
                setState(() => _selectedCountryCode = country);
              },
              validator: (value) {
                if (value == null || value.isEmpty) return s.fieldRequired;
                if (value.length < 8) return s.fieldRequired;
                return null;
              },
            ),
            const SizedBox(height: 16),

            // WhatsApp Section
            _buildWhatsAppSection(s, isDark),
            const SizedBox(height: 16),

            // Avatar Selection Section
            Text(
              'اختر صورة شخصية (إجباري)', // TODO: Use localized string if available, falling back to Arabic per screenshot context
              style: AppTypography.headingSmall,
            ),
            const SizedBox(height: 12),
            _buildAvatarSelection(isDark),
            if (_selectedAvatarIndex == null &&
                _customAvatarUrl ==
                    null) // Show a validation message conditionally or just rely on form validation logic later
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'يرجى اختيار صورة شخصية للمتابعة', // TODO: Localize
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),

            _buildDatePicker(context, s, isDark),
            const SizedBox(height: 16),
            _buildGenderDropdown(s, isDark),
            const SizedBox(height: 40),
            SanadButton(
              onPressed: () {
                if (_formKey.currentState!.validate() &&
                    (_selectedAvatarIndex != null ||
                        _customAvatarUrl != null)) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else if (_selectedAvatarIndex == null &&
                    _customAvatarUrl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('يرجى اختيار صورة شخصية'), // TODO: Localize
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              text: s.next,
            ),
            // Skip button removed because phone number is strictly required now.
          ],
        ),
      ),
    );
  }

  Widget _buildMatchingPart1Page(BuildContext context, S s, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.matchingQuestionnaire, style: AppTypography.headingLarge),
          const SizedBox(height: 8),
          Text(s.primaryGoals, style: AppTypography.headingSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Specialty.values.map((specialty) {
              final isSelected = _selectedGoals.contains(specialty);
              return FilterChip(
                label: Text(SpecialtyData.getLabel(specialty, strings: s)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGoals.add(specialty);
                    } else {
                      _selectedGoals.remove(specialty);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),

          // Removed Cultural Background Question
          const SizedBox(height: 40),
          SanadButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            text: s.next,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingPart2Page(
    BuildContext context,
    S s,
    bool isDark,
    AuthState authState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.preferredGender, style: AppTypography.headingSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChoiceButton(
                s.male,
                'male',
                _preferredTherapistGender,
                (v) => setState(() => _preferredTherapistGender = v),
              ),
              const SizedBox(width: 12),
              _buildChoiceButton(
                s.female,
                'female',
                _preferredTherapistGender,
                (v) => setState(() => _preferredTherapistGender = v),
              ),
              const SizedBox(width: 12),
              _buildChoiceButton(
                s.any,
                'any',
                _preferredTherapistGender,
                (v) => setState(() => _preferredTherapistGender = v),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(s.relationshipStatus, style: AppTypography.headingSmall),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _relationshipStatus,
            hint: Text(s.selectOption),
            decoration: _getInputDecoration(
              isDark,
              prefixIcon: const Icon(Icons.favorite_outline),
            ),
            items: [
              DropdownMenuItem(value: 'single', child: Text(s.single)),
              DropdownMenuItem(value: 'married', child: Text(s.married)),
              DropdownMenuItem(value: 'divorced', child: Text(s.divorced)),
              DropdownMenuItem(value: 'widowed', child: Text(s.widowed)),
            ],
            onChanged: (v) => setState(() => _relationshipStatus = v),
          ),
          const SizedBox(height: 32),
          Text(s.medicalHistory, style: AppTypography.headingSmall),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _medicalHistoryController,
            label: s.medicalHistory,
            hint: s.optional,
            maxLines: 3,
          ),
          const SizedBox(height: 40),
          SanadButton(
            onPressed: _handleProfileCompletion,
            text: s.completeProfile,
            isLoading: authState.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSelection(bool isDark) {
    const totalAvatars = 64;
    final currentIndex = _selectedAvatarIndex ?? 0;

    return Column(
      children: [
        // Custom uploaded image preview (overrides carousel selection)
        if (_customAvatarUrl != null)
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: buildFileImageWidget(
                _customAvatarUrl!.replaceFirst('file://', ''),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, size: 48),
              ),
            ),
          )
        else
          // Horizontal slide carousel — swipe to browse 64 avatars
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _avatarPageController,
              itemCount: totalAvatars,
              onPageChanged: (index) {
                setState(() {
                  _selectedAvatarIndex = index;
                  _customAvatarUrl = null;
                });
              },
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _avatarPageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_avatarPageController.position.haveDimensions) {
                      value = (_avatarPageController.page ?? 0) - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                    } else if (index == currentIndex) {
                      value = 1.0;
                    } else {
                      value = 0.7;
                    }
                    return Center(
                      child: Transform.scale(scale: value, child: child),
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      _avatarPageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index == currentIndex
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: index == currentIndex
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: CircleAvatar(
                        backgroundColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        radius: 60,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/avatars/avatar_${index + 1}.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        // Position indicator
        if (_customAvatarUrl == null)
          Text(
            '${currentIndex + 1} / $totalAvatars',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () async {
            final picker = ImagePicker();
            final image = await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              setState(() {
                _customAvatarUrl = 'file://${image.path}';
                _selectedAvatarIndex = null;
              });
            }
          },
          icon: const Icon(Icons.upload_rounded),
          label: const Text('Upload Image'),
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, S s, bool isDark) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1930),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withOpacity(0.5)
              : AppColors.surfaceLight,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 20),
            const SizedBox(width: 12),
            Text(
              _selectedDate != null
                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                  : s.dateOfBirth,
              style: AppTypography.bodyMedium.copyWith(
                color: _selectedDate != null
                    ? null
                    : (isDark ? AppColors.textMuted : AppColors.textMutedLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(S s, bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      hint: Text(s.gender),
      decoration: _getInputDecoration(
        isDark,
        prefixIcon: const Icon(Icons.wc_outlined),
      ),
      items: [
        DropdownMenuItem(value: 'male', child: Text(s.male)),
        DropdownMenuItem(value: 'female', child: Text(s.female)),
        DropdownMenuItem(value: 'other', child: Text(s.other)),
      ],
      onChanged: (v) => setState(() => _selectedGender = v),
    );
  }

  InputDecoration _getInputDecoration(bool isDark, {Widget? prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: isDark
          ? AppColors.surfaceDark.withOpacity(0.5)
          : AppColors.surfaceLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.borderDark.withOpacity(0.5)
              : AppColors.borderLight,
        ),
      ),
      prefixIcon: prefixIcon,
    );
  }

  Widget _buildChoiceButton(
    String label,
    String value,
    String? groupValue,
    Function(String) onTap,
  ) {
    final isSelected = groupValue == value;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppSection(S s, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1F0F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SvgPicture.asset(
                  'assets/icons/whatsapp.svg',
                  width: 18,
                  height: 18,
                  placeholderBuilder: (_) =>
                      const Icon(Icons.message, color: Colors.green, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.hasWhatsAppOnSameNumber,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildWhatsAppRadio(
                  title: s.sameNumber,
                  selected: _whatsAppSameAsPhone,
                  onTap: () => setState(() => _whatsAppSameAsPhone = true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildWhatsAppRadio(
                  title: s.differentNumber,
                  selected: !_whatsAppSameAsPhone,
                  onTap: () => setState(() => _whatsAppSameAsPhone = false),
                ),
              ),
            ],
          ),
          if (!_whatsAppSameAsPhone) ...[
            const SizedBox(height: 12),
            PhoneInputField(
              controller: _whatsappController,
              label: '',
              hint: s.enterWhatsAppNumber,
              initialCountry: _selectedWhatsAppCountryCode,
              onCountryChanged: (country) {
                setState(() => _selectedWhatsAppCountryCode = country);
              },
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE1F0F5)),
          CheckboxListTile(
            value: _agreedToWhatsAppAds,
            onChanged: (val) =>
                setState(() => _agreedToWhatsAppAds = val ?? false),
            title: Text(
              s.agreeToWhatsApp,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textMuted : Colors.black54,
                height: 1.3,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.green,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppRadio({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: selected ? Colors.green : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? Colors.green.shade800 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleProfileCompletion() {
    // Determine WhatsApp number
    final rawPhone = _phoneController.text.trim();
    final phone = rawPhone.isNotEmpty
        ? '${_selectedCountryCode.dialCode}$rawPhone'
        : '';
    final rawWhatsApp = _whatsappController.text.trim();
    final whatsappNumber = _whatsAppSameAsPhone
        ? phone
        : (rawWhatsApp.isNotEmpty
              ? '${_selectedWhatsAppCountryCode.dialCode}$rawWhatsApp'
              : '');

    final matchingPrefs = {
      'goals': _selectedGoals.map((e) => e.name).toList(),
      'preferred_therapist_gender': _preferredTherapistGender,
      'relationship_status': _relationshipStatus,
      'medical_history': _medicalHistoryController.text.trim(),
      if (whatsappNumber.isNotEmpty) 'whatsapp_number': whatsappNumber,
      'whatsapp_ads_consent': _agreedToWhatsAppAds,
    };

    String? avatarUrl;
    if (_customAvatarUrl != null) {
      avatarUrl = _customAvatarUrl;
    } else if (_selectedAvatarIndex != null) {
      avatarUrl =
          'assets/images/avatars/avatar_${_selectedAvatarIndex! + 1}.png';
    }

    ref
        .read(authProvider.notifier)
        .completeProfile(
          displayName: _nameController.text.trim(),
          phoneNumber: phone.isNotEmpty ? phone : null,
          dateOfBirth: _selectedDate,
          gender: _selectedGender,
          matchingPreferences: matchingPrefs,
          avatarUrl: avatarUrl,
        );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _medicalHistoryController.dispose();
    _pageController.dispose();
    _avatarPageController.dispose();
    super.dispose();
  }
}
