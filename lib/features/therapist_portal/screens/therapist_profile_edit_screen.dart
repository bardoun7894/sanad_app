import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../therapists/models/therapist.dart';
import '../models/therapist_profile.dart';
import '../services/therapist_auth_service.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';

/// Provider for therapist auth service
final therapistAuthServiceProvider = Provider<TherapistAuthService>((ref) {
  return TherapistAuthService();
});

/// Provider for current therapist profile stream
final therapistProfileStreamProvider = StreamProvider<TherapistProfile?>((ref) {
  final authState = ref.watch(authProvider);
  final service = ref.watch(therapistAuthServiceProvider);

  if (authState.user?.uid == null) {
    return Stream.value(null);
  }

  return service.getProfileStream(authState.user!.uid);
});

/// Screen for editing therapist profile
class TherapistProfileEditScreen extends ConsumerStatefulWidget {
  const TherapistProfileEditScreen({super.key});

  @override
  ConsumerState<TherapistProfileEditScreen> createState() =>
      _TherapistProfileEditScreenState();
}

class _TherapistProfileEditScreenState
    extends ConsumerState<TherapistProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceController = TextEditingController();

  // Selected values
  List<Specialty> _selectedSpecialties = [];
  List<SessionType> _selectedSessionTypes = [];
  List<String> _selectedLanguages = [];
  List<String> _qualifications = [];
  String _currency = 'SAR';
  bool _isActive = false;
  String? _photoUrl;

  // State
  bool _isLoading = false;
  bool _isInitialized = false;
  Uint8List? _newPhotoBytes;

  // Available languages
  final List<String> _availableLanguages = [
    'Arabic',
    'English',
    'French',
    'Spanish',
    'German',
    'Turkish',
    'Urdu',
  ];

  // Available currencies
  final List<String> _currencies = ['SAR', 'USD', 'EUR', 'GBP', 'AED'];

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _initializeForm(TherapistProfile profile) {
    if (_isInitialized) return;

    _nameController.text = profile.name;
    _titleController.text = profile.title ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _bioController.text = profile.bio ?? '';
    _priceController.text = profile.sessionPrice.toString();
    _experienceController.text = profile.yearsExperience.toString();

    _selectedSpecialties = List.from(profile.specialties);
    _selectedSessionTypes = List.from(profile.sessionTypes);
    _selectedLanguages = List.from(profile.languages);
    _qualifications = List.from(profile.qualifications);
    _currency = profile.currency;
    _isActive = profile.isActive;
    _photoUrl = profile.photoUrl;

    _isInitialized = true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newPhotoBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final s = ref.read(stringsProvider);
      final authState = ref.read(authProvider);
      final service = ref.read(therapistAuthServiceProvider);

      if (authState.user?.uid == null) {
        throw Exception(s.somethingWentWrong);
      }

      // Upload photo if new file selected
      if (_newPhotoBytes != null) {
        await service.uploadProfilePhoto(authState.user!.uid, _newPhotoBytes!);
      }

      final updateData = {
        'name': _nameController.text.trim(),
        'title': _titleController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'specialties': _selectedSpecialties.map((s) => s.name).toList(),
        'session_types': _selectedSessionTypes
            .map((t) => t.firestoreValue)
            .toList(),
        'languages': _selectedLanguages,
        'qualifications': _qualifications,
        'session_price': double.tryParse(_priceController.text) ?? 0,
        'currency': _currency,
        'years_experience': int.tryParse(_experienceController.text) ?? 0,
        'is_active': _isActive,
      };

      await service.updateProfile(authState.user!.uid, updateData);

      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileUpdated),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        final s = ref.read(stringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addQualification() {
    final controller = TextEditingController();
    final s = ref.read(stringsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.addQualification),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: s.qualificationHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _qualifications.add(controller.text.trim());
                });
              }
              Navigator.pop(context);
            },
            child: Text(s.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final profileAsync = ref.watch(therapistProfileStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(s.editProfile),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: _saveProfile,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  s.save,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingStateWidget(),
        error: (error, stack) => ErrorStateWidget(
          message: s.errorLoadingData,
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(therapistProfileStreamProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(s.profileNotFound));
          }

          _initializeForm(profile);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Photo Section
                _buildPhotoSection(s),
                const SizedBox(height: 32),

                // Basic Info Section
                _buildSectionCard(
                  title: s.basicInformation,
                  icon: Icons.person_outline,
                  children: [
                    _buildNameField(s),
                    const SizedBox(height: 16),
                    _buildTitleField(s),
                    const SizedBox(height: 16),
                    _buildPhoneField(s),
                  ],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Bio Section
                _buildSectionCard(
                  title: s.bio,
                  icon: Icons.article_outlined,
                  children: [_buildBioField(s)],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Specialties & Expertise
                _buildSectionCard(
                  title: s.specialties,
                  icon: Icons.psychology_outlined,
                  children: [
                    Text(
                      s.expertiseSelect,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSpecialtiesSelector(s),
                  ],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Session Types
                _buildSectionCard(
                  title: s.sessionTypes,
                  icon: Icons.call_outlined,
                  children: [_buildSessionTypesSelector(s)],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Languages
                _buildSectionCard(
                  title: s.languages,
                  icon: Icons.language,
                  children: [_buildLanguagesSelector(s)],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Qualifications
                _buildSectionCard(
                  title: s.qualifications,
                  icon: Icons.school_outlined,
                  children: [_buildQualificationsList(s, isDark)],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Pricing & Experience
                _buildSectionCard(
                  title: s.pricing,
                  icon: Icons.work_outline,
                  children: [
                    _buildPricingFields(s),
                    const SizedBox(height: 16),
                    _buildExperienceField(s),
                  ],
                  isDark: isDark,
                ),
                const SizedBox(height: 20),

                // Availability Toggle
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      s.availableForBookings,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _isActive ? s.youAreOnline : s.youAreOffline,
                        style: TextStyle(
                          color: _isActive
                              ? Colors.green
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                    activeThumbColor: AppColors.primary,
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isActive ? Icons.visibility : Icons.visibility_off,
                        color: _isActive
                            ? Colors.green
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPhotoSection(S s) {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : Colors.grey[200],
                  backgroundImage: _newPhotoBytes != null
                      ? MemoryImage(_newPhotoBytes!)
                      : (_photoUrl != null ? NetworkImage(_photoUrl!) : null),
                  child: _newPhotoBytes == null && _photoUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 60,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.tapToChangePhoto,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    IconData? prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey[500], size: 20)
          : null,
      filled: true,
      fillColor: isDark ? Colors.black26 : Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: Colors.grey[600]),
      alignLabelWithHint: true,
    );
  }

  Widget _buildNameField(S s) {
    return TextFormField(
      controller: _nameController,
      decoration: _inputDecoration(
        s.fullName,
        prefixIcon: Icons.person_outline,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return s.nameRequired;
        return null;
      },
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildTitleField(S s) {
    return TextFormField(
      controller: _titleController,
      decoration: _inputDecoration(
        s.professionalTitle,
        hint: s.professionalTitleHint,
        prefixIcon: Icons.badge_outlined,
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildPhoneField(S s) {
    return TextFormField(
      controller: _phoneController,
      decoration: _inputDecoration(
        s.phoneNumber,
        prefixIcon: Icons.phone_outlined,
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildBioField(S s) {
    return TextFormField(
      controller: _bioController,
      decoration: _inputDecoration(s.bio, hint: s.bioHint),
      maxLines: 5,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildSpecialtiesSelector(S s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Specialty.values.map((specialty) {
        final isSelected = _selectedSpecialties.contains(specialty);
        return FilterChip(
          label: Text(
            SpecialtyData.getLabel(specialty, strings: s),
            style: TextStyle(
              color: isSelected ? AppColors.primary : null,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
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
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.primary.withValues(alpha: 0.1),
          checkmarkColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildSessionTypesSelector(S s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SessionType.values.map((type) {
        final isSelected = _selectedSessionTypes.contains(type);
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                SessionTypeData.getIcon(type),
                size: 16,
                color: isSelected ? AppColors.primary : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                SessionTypeData.getLabel(type, strings: s),
                style: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSessionTypes.add(type);
              } else {
                _selectedSessionTypes.remove(type);
              }
            });
          },
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.primary.withValues(alpha: 0.1),
          checkmarkColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildLanguagesSelector(S s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableLanguages.map((language) {
        final isSelected = _selectedLanguages.contains(language);
        return FilterChip(
          label: Text(
            language,
            style: TextStyle(
              color: isSelected ? AppColors.primary : null,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedLanguages.add(language);
              } else {
                _selectedLanguages.remove(language);
              }
            });
          },
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.primary.withValues(alpha: 0.1),
          checkmarkColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQualificationsList(S s, bool isDark) {
    return Column(
      children: [
        if (_qualifications.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              s.noQualifications,
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ..._qualifications.asMap().entries.map((entry) {
          final index = entry.key;
          final qualification = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey[200]!,
              ),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.verified_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              title: Text(
                qualification,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: Colors.grey[400],
                onPressed: () {
                  setState(() {
                    _qualifications.removeAt(index);
                  });
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addQualification,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(s.addQualification),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingFields(S s) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _priceController,
            decoration: _inputDecoration(
              s.sessionPrice,
              prefixIcon: Icons.attach_money_rounded,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) return s.priceRequired;
              final price = double.tryParse(value);
              if (price == null || price <= 0) return s.invalidPrice;
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: _inputDecoration(s.currencyLabel),
            items: _currencies.map((currency) {
              return DropdownMenuItem(value: currency, child: Text(currency));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _currency = value);
            },
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            dropdownColor: Theme.of(context).cardColor,
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceField(S s) {
    return TextFormField(
      controller: _experienceController,
      decoration: _inputDecoration(
        s.yearsOfExperience,
        prefixIcon: Icons.timeline_rounded,
        hint: s.experienceHint,
      ).copyWith(suffixText: s.years),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return s.experienceRequired;
        final years = int.tryParse(value);
        if (years == null || years < 0) return s.invalidExperience;
        return null;
      },
    );
  }
}
