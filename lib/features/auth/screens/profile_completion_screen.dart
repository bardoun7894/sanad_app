import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
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
import '../models/auth_user.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import 'package:country_picker/country_picker.dart';
import '../utils/phone_number_utils.dart';
import '../widgets/phone_input_field.dart';
import '../../therapists/models/therapist.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  // Debounced partial-save so a user who drops off mid-wizard keeps progress.
  Timer? _autosaveTimer;
  final _pageController = PageController();
  int _currentPage = 0;

  // Page 1: Basic Info — name is split into two mandatory fields.
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  Country _selectedCountryCode = Country.parse('SA');
  Country _selectedWhatsAppCountryCode = Country.parse('SA');
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
    WidgetsBinding.instance.addObserver(this);
    // Pre-fill user data if available from Auth (e.g., Google login)
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      // Pre-fill from an existing display name (e.g. Google) by splitting on
      // the first space: first token → first name, the rest → last name.
      final existingName = authState.user!.displayName?.trim();
      if (existingName != null && existingName.isNotEmpty) {
        final parts = existingName.split(RegExp(r'\s+'));
        _firstNameController.text = parts.first;
        if (parts.length > 1) {
          _lastNameController.text = parts.sublist(1).join(' ');
        }
      }
      if (authState.user!.phoneNumber != null) {
        // Firebase Auth numbers are full E.164 ("+971..."); split them so the
        // dial code lands in the selector and only the local part in the
        // field — otherwise every save prepends the default code again and
        // produces "+966+971...".
        final e164 = authState.user!.phoneNumber!;
        final countries = CountryService().getAll();
        final split = PhoneNumberUtils.splitE164(
          e164,
          countries.map((c) => c.phoneCode),
        );
        if (split != null) {
          _selectedCountryCode =
              countries.firstWhere((c) => c.phoneCode == split.dialCode);
          _phoneController.text = split.local;
        } else {
          _phoneController.text = e164;
        }
      }
    }
    // Autosave partial progress as the user types.
    _firstNameController.addListener(_scheduleAutosave);
    _lastNameController.addListener(_scheduleAutosave);
    _phoneController.addListener(_scheduleAutosave);
    _whatsappController.addListener(_scheduleAutosave);
    _medicalHistoryController.addListener(_scheduleAutosave);

    // Rehydrate any previously-saved/autosaved profile from Firestore so a
    // returning user (the gate re-prompted them) sees their data instead of a
    // blank form. Without this they "fill from scratch every time".
    _hydrateFromSavedProfile();
  }

  /// Load the user's existing users/{uid} doc and pre-fill every field the
  /// autosave + final save persist (gender, DOB, goals, therapist gender,
  /// relationship, medical history, whatsapp, avatar). Auth-only prefill in
  /// initState covers just name/phone, so without this returning users lose
  /// everything else. Best-effort: never blocks the form on a read failure.
  Future<void> _hydrateFromSavedProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted || !snap.exists) return;
      final d = snap.data();
      if (d == null) return;

      final countries = CountryService().getAll();

      // Name — only fill when still empty so an async Firestore read can never
      // overwrite what the user is actively typing or the initState Auth split.
      final firstName = (d['first_name'] as String?)?.trim();
      final lastName = (d['last_name'] as String?)?.trim();
      if (firstName != null &&
          firstName.isNotEmpty &&
          _firstNameController.text.isEmpty) {
        _firstNameController.text = firstName;
      }
      if (lastName != null &&
          lastName.isNotEmpty &&
          _lastNameController.text.isEmpty) {
        _lastNameController.text = lastName;
      }

      // Phone — critical for Google users (Auth record carries no phone).
      final phone = (d['phone'] as String?)?.trim();
      if (phone != null && phone.isNotEmpty && _phoneController.text.isEmpty) {
        final split = PhoneNumberUtils.splitE164(
          phone,
          countries.map((c) => c.phoneCode),
        );
        if (split != null) {
          _selectedCountryCode =
              countries.firstWhere((c) => c.phoneCode == split.dialCode);
          _phoneController.text = split.local;
        } else {
          _phoneController.text = phone;
        }
      }

      // WhatsApp — same-as-phone when it matches, otherwise a separate number.
      final whatsapp = (d['whatsapp_number'] as String?)?.trim();
      if (whatsapp != null && whatsapp.isNotEmpty) {
        if (phone != null && whatsapp == phone) {
          _whatsAppSameAsPhone = true;
        } else {
          _whatsAppSameAsPhone = false;
          final split = PhoneNumberUtils.splitE164(
            whatsapp,
            countries.map((c) => c.phoneCode),
          );
          if (split != null) {
            _selectedWhatsAppCountryCode =
                countries.firstWhere((c) => c.phoneCode == split.dialCode);
            _whatsappController.text = split.local;
          } else {
            _whatsappController.text = whatsapp;
          }
        }
      }

      if (d['whatsapp_ads_consent'] is bool) {
        _agreedToWhatsAppAds = d['whatsapp_ads_consent'] as bool;
      }

      // Date of birth.
      final dob = d['date_of_birth'];
      if (dob is Timestamp) _selectedDate = dob.toDate();

      // Gender.
      final gender = d['gender'] as String?;
      if (gender != null && gender.isNotEmpty) _selectedGender = gender;

      // Avatar: either a built-in asset ("…/avatar_N.png" → index N-1) or a
      // previously-uploaded custom image (https URL) — restore whichever it is
      // so the mandatory-avatar check isn't falsely blocked on return.
      final avatarUrl = d['avatar_url'] as String?;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        final m = RegExp(r'avatar_(\d+)\.png').firstMatch(avatarUrl);
        if (m != null) {
          final n = int.tryParse(m.group(1)!);
          if (n != null && n > 0) _selectedAvatarIndex = n - 1;
        } else if (avatarUrl.startsWith('http')) {
          _customAvatarUrl = avatarUrl;
        }
      }

      // Matching preferences (goals / therapist gender / relationship / notes).
      final mp = d['matching_preferences'];
      if (mp is Map) {
        final goals = mp['goals'];
        if (goals is List) {
          _selectedGoals.clear();
          for (final g in goals) {
            for (final sp in Specialty.values) {
              if (sp.name == g) {
                _selectedGoals.add(sp);
                break;
              }
            }
          }
        }
        final ptg = mp['preferred_therapist_gender'] as String?;
        if (ptg != null && ptg.isNotEmpty) _preferredTherapistGender = ptg;
        final rel = mp['relationship_status'] as String?;
        if (rel != null && rel.isNotEmpty) _relationshipStatus = rel;
        final med = mp['medical_history'] as String?;
        if (med != null && med.isNotEmpty) _medicalHistoryController.text = med;
      }

      if (mounted) setState(() {});
    } catch (e) {
      // Best-effort prefill; a read failure just leaves the Auth-only prefill.
      debugPrint('profile rehydrate failed (non-fatal): $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Flush immediately when the app is backgrounded/closed so progress isn't
    // lost if the user never reaches the final "Complete Profile" button.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _autosaveTimer?.cancel();
      _autosaveNow();
    }
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 1200), _autosaveNow);
  }

  /// Best-effort partial save to users/{uid}. Never sets has_complete_profile
  /// (only the final completeProfile step does that), uses the same field keys
  /// the final save + admin reader expect, and merges so it never clobbers.
  Future<void> _autosaveNow() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(_buildPartialProfile(), SetOptions(merge: true));
    } catch (_) {
      // Autosave is best-effort; ignore failures (final save still persists).
    }
  }

  Map<String, dynamic> _buildPartialProfile() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final name = [firstName, lastName].where((p) => p.isNotEmpty).join(' ').trim();
    final phone = PhoneNumberUtils.composeE164(
      _selectedCountryCode.phoneCode,
      _phoneController.text.trim(),
    );
    final whatsapp = _whatsAppSameAsPhone
        ? phone
        : PhoneNumberUtils.composeE164(
            _selectedWhatsAppCountryCode.phoneCode,
            _whatsappController.text.trim(),
          );

    // Only persist a built-in avatar asset; a custom file:// path can't be
    // saved without uploading the image first.
    String? avatarUrl;
    if (_selectedAvatarIndex != null) {
      avatarUrl = 'assets/images/avatars/avatar_${_selectedAvatarIndex! + 1}.png';
    }

    // NOTE: whatsapp_ads_consent is deliberately NOT autosaved. It defaults to
    // false, and writing it on every partial save would overwrite a consent the
    // user previously granted (a marketing-consent reset — GDPR-sensitive)
    // before hydration restores the true value. It is written only by the final
    // completeProfile() submit, which carries the user's explicit choice.
    final map = <String, dynamic>{
      'profile_autosaved_at': FieldValue.serverTimestamp(),
    };
    if (name.isNotEmpty) {
      map['display_name'] = name;
      map['name'] = name;
    }
    if (firstName.isNotEmpty) map['first_name'] = firstName;
    if (lastName.isNotEmpty) map['last_name'] = lastName;
    if (phone.isNotEmpty) map['phone'] = phone;
    if (whatsapp.isNotEmpty) map['whatsapp_number'] = whatsapp;
    if (_selectedDate != null) {
      map['date_of_birth'] = Timestamp.fromDate(_selectedDate!);
    }
    if (_selectedGender != null) map['gender'] = _selectedGender;
    if (avatarUrl != null) map['avatar_url'] = avatarUrl;

    final matching = <String, dynamic>{
      if (_selectedGoals.isNotEmpty)
        'goals': _selectedGoals.map((e) => e.name).toList(),
      if (_preferredTherapistGender != null)
        'preferred_therapist_gender': _preferredTherapistGender,
      if (_relationshipStatus != null)
        'relationship_status': _relationshipStatus,
      if (_medicalHistoryController.text.trim().isNotEmpty)
        'medical_history': _medicalHistoryController.text.trim(),
    };
    if (matching.isNotEmpty) map['matching_preferences'] = matching;

    map['profile_completion_percentage'] = _completionPercent(
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    return map;
  }

  int _completionPercent({
    required String name,
    required String phone,
    String? avatarUrl,
  }) {
    final checks = <bool>[
      name.isNotEmpty,
      phone.isNotEmpty,
      avatarUrl != null,
      _selectedDate != null,
      _selectedGender != null,
      _selectedGoals.isNotEmpty,
      _preferredTherapistGender != null,
      _relationshipStatus != null,
    ];
    final filled = checks.where((b) => b).length;
    return ((filled / checks.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final isGoogleUser = authState.user?.provider == AuthProvider.google;

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
          // LTR so the counter doesn't render as "3 / 1" in Arabic RTL.
          title: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${_currentPage + 1} / 3',
              style: AppTypography.labelLarge.copyWith(
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
              ),
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
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                    _autosaveNow();
                  },
                  children: [
                    _buildBasicInfoPage(context, s, isDark, isGoogleUser),
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

  Widget _buildBasicInfoPage(BuildContext context, S s, bool isDark, bool isGoogleUser) {
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
              controller: _firstNameController,
              label: s.firstName,
              hint: s.firstName,
              prefixIcon: const Icon(Icons.person_outlined),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return s.fieldRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _lastNameController,
              label: s.lastName,
              hint: s.lastName,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return s.fieldRequired;
                }
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
                final hasAvatar =
                    _selectedAvatarIndex != null || _customAvatarUrl != null;
                // WhatsApp is mandatory: satisfied by "same as phone" OR an
                // explicitly entered number.
                final hasWhatsApp = _whatsAppSameAsPhone ||
                    _whatsappController.text.trim().isNotEmpty;

                if (!_formKey.currentState!.validate()) return;
                if (!hasAvatar) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('يرجى اختيار صورة شخصية'), // TODO: Localize
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (_selectedGender == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${s.gender}: ${s.fieldRequired}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                // DOB is mandatory at the final step — enforce it here too so a
                // user can't advance and then get bounced back from page 3.
                if (_selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${s.dateOfBirth}: ${s.fieldRequired}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                if (!hasWhatsApp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('واتساب: ${s.fieldRequired}'), // TODO: Localize
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
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
                  _scheduleAutosave();
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
              // Mandatory: at least one goal must be chosen before continuing.
              if (_selectedGoals.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${s.primaryGoals}: ${s.fieldRequired}'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
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
                (v) {
                  setState(() => _preferredTherapistGender = v);
                  _scheduleAutosave();
                },
              ),
              const SizedBox(width: 12),
              _buildChoiceButton(
                s.female,
                'female',
                _preferredTherapistGender,
                (v) {
                  setState(() => _preferredTherapistGender = v);
                  _scheduleAutosave();
                },
              ),
              const SizedBox(width: 12),
              _buildChoiceButton(
                s.any,
                'any',
                _preferredTherapistGender,
                (v) {
                  setState(() => _preferredTherapistGender = v);
                  _scheduleAutosave();
                },
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
            onChanged: (v) {
              setState(() => _relationshipStatus = v);
              _scheduleAutosave();
            },
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
                _scheduleAutosave();
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
          // LTR so the counter doesn't render as "64 / 1" in Arabic RTL.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${currentIndex + 1} / $totalAvatars',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
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
        if (picked != null) {
          setState(() => _selectedDate = picked);
          _scheduleAutosave();
        }
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
      onChanged: (v) {
        setState(() => _selectedGender = v);
        _scheduleAutosave();
      },
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

  /// Show a blocking error and jump back to the page holding the missing
  /// field so the user can fix it. All registration fields are mandatory.
  void _failValidation(String message, int page) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
    if (_currentPage != page) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleProfileCompletion() {
    final s = ref.read(stringsProvider);

    // ── Mandatory-field gate (client requirement: registration completes once,
    // and every step is required — nothing can be skipped). Page indices:
    // 0 = basic info, 1 = goals, 2 = preferences.
    final firstNameRaw = _firstNameController.text.trim();
    final lastNameRaw = _lastNameController.text.trim();
    if (firstNameRaw.isEmpty || lastNameRaw.isEmpty) {
      return _failValidation('${s.fullName}: ${s.fieldRequired}', 0);
    }
    if (_phoneController.text.trim().isEmpty) {
      return _failValidation('${s.phoneNumber}: ${s.fieldRequired}', 0);
    }
    final hasWhatsApp =
        _whatsAppSameAsPhone || _whatsappController.text.trim().isNotEmpty;
    if (!hasWhatsApp) {
      return _failValidation('واتساب: ${s.fieldRequired}', 0);
    }
    if (_selectedAvatarIndex == null && _customAvatarUrl == null) {
      return _failValidation('${s.fieldRequired}', 0);
    }
    if (_selectedDate == null) {
      return _failValidation('${s.dateOfBirth}: ${s.fieldRequired}', 0);
    }
    if (_selectedGender == null) {
      return _failValidation('${s.gender}: ${s.fieldRequired}', 0);
    }
    if (_selectedGoals.isEmpty) {
      return _failValidation('${s.primaryGoals}: ${s.fieldRequired}', 1);
    }
    if (_preferredTherapistGender == null) {
      return _failValidation('${s.preferredGender}: ${s.fieldRequired}', 2);
    }
    if (_relationshipStatus == null) {
      return _failValidation('${s.relationshipStatus}: ${s.fieldRequired}', 2);
    }

    // Determine WhatsApp number
    final phone = PhoneNumberUtils.composeE164(
      _selectedCountryCode.phoneCode,
      _phoneController.text.trim(),
    );
    final whatsappNumber = _whatsAppSameAsPhone
        ? phone
        : PhoneNumberUtils.composeE164(
            _selectedWhatsAppCountryCode.phoneCode,
            _whatsappController.text.trim(),
          );

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

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName =
        [firstName, lastName].where((p) => p.isNotEmpty).join(' ').trim();

    ref
        .read(authProvider.notifier)
        .completeProfile(
          displayName: fullName,
          firstName: firstName.isNotEmpty ? firstName : null,
          lastName: lastName.isNotEmpty ? lastName : null,
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
    WidgetsBinding.instance.removeObserver(this);
    _autosaveTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _medicalHistoryController.dispose();
    _pageController.dispose();
    _avatarPageController.dispose();
    super.dispose();
  }
}
