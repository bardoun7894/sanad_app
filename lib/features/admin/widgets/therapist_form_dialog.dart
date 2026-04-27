import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../therapist_portal/models/therapist_profile.dart';
import '../../therapists/models/therapist.dart';

/// A shared form dialog used for both creating and editing a therapist profile.
///
/// Pass [therapist] to pre-fill for edit mode; leave null for create mode.
/// [onSaved] is called with the resulting [TherapistProfile] when the form
/// is submitted and validated successfully.
class TherapistFormDialog extends StatefulWidget {
  const TherapistFormDialog({
    super.key,
    this.therapist,
    required this.onSaved,
  });

  /// Null → create mode. Non-null → edit mode with pre-filled fields.
  final TherapistProfile? therapist;
  final void Function(TherapistProfile) onSaved;

  @override
  State<TherapistFormDialog> createState() => _TherapistFormDialogState();
}

class _TherapistFormDialogState extends State<TherapistFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  late final TextEditingController _yearsController;
  late final TextEditingController _rateController;
  final TextEditingController _specialtyInputController =
      TextEditingController();
  final TextEditingController _languageInputController =
      TextEditingController();

  // State
  String? _photoUrl;
  XFile? _pickedPhoto;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;
  TherapistApprovalStatus _approvalStatus = TherapistApprovalStatus.pending;
  List<String> _specialties = [];
  List<String> _languages = [];

  bool get _isEditMode => widget.therapist != null;

  @override
  void initState() {
    super.initState();
    final t = widget.therapist;
    _nameController = TextEditingController(text: t?.name ?? '');
    _emailController = TextEditingController(text: t?.email ?? '');
    _bioController = TextEditingController(text: t?.bio ?? '');
    _yearsController =
        TextEditingController(text: t != null ? '${t.yearsExperience}' : '');
    _rateController =
        TextEditingController(text: t != null ? '${t.sessionPrice}' : '');
    _photoUrl = t?.photoUrl;
    _approvalStatus = t?.approvalStatus ?? TherapistApprovalStatus.pending;
    _specialties = t?.specialties.map((s) => s.name).toList() ?? [];
    _languages = List<String>.from(t?.languages ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _yearsController.dispose();
    _rateController.dispose();
    _specialtyInputController.dispose();
    _languageInputController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Photo upload
  // -------------------------------------------------------------------------

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;

    setState(() {
      _pickedPhoto = file;
      _isUploadingPhoto = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('therapist_photos/$timestamp.jpg');

      await ref.putFile(File(file.path));
      final url = await ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _photoUrl = url;
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Map specialty strings back to Specialty enum values
    final specialtyList = _specialties
        .map((s) => Specialty.values.firstWhere(
              (spec) => spec.name.toLowerCase() == s.toLowerCase(),
              orElse: () => Specialty.anxiety,
            ))
        .toList();

    final years = int.tryParse(_yearsController.text.trim()) ?? 0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;

    final profile = TherapistProfile(
      id: widget.therapist?.id ?? '',
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      photoUrl: _photoUrl,
      specialties: specialtyList,
      languages: _languages,
      yearsExperience: years,
      sessionPrice: rate,
      approvalStatus: _approvalStatus,
      isActive:
          widget.therapist?.isActive ?? false,
      rating: widget.therapist?.rating ?? 0.0,
      reviewCount: widget.therapist?.reviewCount ?? 0,
      createdAt: widget.therapist?.createdAt ?? DateTime.now(),
      approvedAt: widget.therapist?.approvedAt,
      approvedBy: widget.therapist?.approvedBy,
      sessionTypes: widget.therapist?.sessionTypes ?? const [],
      therapyTypes: widget.therapist?.therapyTypes ??
          const [TherapyType.individual],
      currency: widget.therapist?.currency ?? 'SAR',
      qualifications: widget.therapist?.qualifications ?? const [],
    );

    widget.onSaved(profile);
    Navigator.of(context).pop();
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.adminSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.adminBorder : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(isDark),
              Divider(
                height: 1,
                color: isDark ? AppColors.adminBorder : AppColors.border,
              ),
              // Scrollable form body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        _label('Full Name *', isDark),
                        const SizedBox(height: 6),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: _textField(
                            controller: _nameController,
                            hint: 'الاسم الكامل / Full name',
                            isDark: isDark,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Name is required'
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        _label('Email *', isDark),
                        const SizedBox(height: 6),
                        _textField(
                          controller: _emailController,
                          hint: 'therapist@example.com',
                          isDark: isDark,
                          readOnly: _isEditMode,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Photo
                        _label('Profile Photo', isDark),
                        const SizedBox(height: 6),
                        _buildPhotoRow(isDark),
                        const SizedBox(height: 16),

                        // Bio
                        _label('Bio', isDark),
                        const SizedBox(height: 6),
                        _textField(
                          controller: _bioController,
                          hint: 'Professional background and approach...',
                          isDark: isDark,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),

                        // Specialties
                        _label('Specialties', isDark),
                        const SizedBox(height: 6),
                        _buildChipInput(
                          inputController: _specialtyInputController,
                          chips: _specialties,
                          hint: 'e.g. anxiety',
                          isDark: isDark,
                          onAdd: () {
                            final v =
                                _specialtyInputController.text.trim();
                            if (v.isNotEmpty && !_specialties.contains(v)) {
                              setState(() => _specialties.add(v));
                              _specialtyInputController.clear();
                            }
                          },
                          onRemove: (s) =>
                              setState(() => _specialties.remove(s)),
                        ),
                        const SizedBox(height: 16),

                        // Languages
                        _label('Languages', isDark),
                        const SizedBox(height: 6),
                        _buildChipInput(
                          inputController: _languageInputController,
                          chips: _languages,
                          hint: 'e.g. Arabic',
                          isDark: isDark,
                          onAdd: () {
                            final v =
                                _languageInputController.text.trim();
                            if (v.isNotEmpty && !_languages.contains(v)) {
                              setState(() => _languages.add(v));
                              _languageInputController.clear();
                            }
                          },
                          onRemove: (s) =>
                              setState(() => _languages.remove(s)),
                        ),
                        const SizedBox(height: 16),

                        // Years of experience + Hourly rate (row)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _label('Years Exp.', isDark),
                                  const SizedBox(height: 6),
                                  _textField(
                                    controller: _yearsController,
                                    hint: '0',
                                    isDark: isDark,
                                    keyboardType:
                                        TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _label('Session Rate (SAR)', isDark),
                                  const SizedBox(height: 6),
                                  _textField(
                                    controller: _rateController,
                                    hint: '0.0',
                                    isDark: isDark,
                                    keyboardType:
                                        const TextInputType
                                            .numberWithOptions(
                                              decimal: true,
                                            ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Approval Status
                        _label('Approval Status', isDark),
                        const SizedBox(height: 6),
                        _buildStatusDropdown(isDark),
                      ],
                    ),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.adminBorder : AppColors.border,
              ),
              // Footer buttons
              _buildFooter(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sub-widgets
  // -------------------------------------------------------------------------

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _isEditMode ? 'Edit Therapist' : 'Add Therapist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textMuted,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoRow(bool isDark) {
    return Row(
      children: [
        // Avatar preview
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: _photoUrl != null && _pickedPhoto == null
              ? NetworkImage(_photoUrl!)
              : _pickedPhoto != null
                  ? FileImage(File(_pickedPhoto!.path)) as ImageProvider
                  : null,
          child: (_photoUrl == null && _pickedPhoto == null)
              ? const Icon(Icons.person, color: AppColors.primary, size: 28)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                icon: _isUploadingPhoto
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_rounded, size: 16),
                label: Text(
                  _isUploadingPhoto ? 'Uploading...' : 'Upload Photo',
                  style: const TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_photoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Photo uploaded',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChipInput({
    required TextEditingController inputController,
    required List<String> chips,
    required String hint,
    required bool isDark,
    required VoidCallback onAdd,
    required void Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _textField(
                controller: inputController,
                hint: hint,
                isDark: isDark,
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: chips
                .map(
                  (chip) => FilterChip(
                    label: Text(
                      chip,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: false,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => onRemove(chip),
                    onSelected: (_) {},
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    selectedColor: AppColors.primary.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                    ),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TherapistApprovalStatus>(
          value: _approvalStatus,
          isExpanded: true,
          dropdownColor:
              isDark ? AppColors.adminSurface : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 14,
          ),
          items: TherapistApprovalStatus.values
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _approvalStatus = v);
          },
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _isSaving || _isUploadingPhoto ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_isEditMode ? 'Save Changes' : 'Create Therapist'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Widget _label(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.adminTextSecondary : AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.adminTextSecondary : AppColors.textMuted,
        ),
        filled: true,
        fillColor: readOnly
            ? (isDark
                ? AppColors.adminBorder.withValues(alpha: 0.3)
                : AppColors.borderLight)
            : (isDark
                ? AppColors.adminGlass.withValues(alpha: 0.3)
                : AppColors.background),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.border,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.statusDanger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  String _statusLabel(TherapistApprovalStatus status) {
    switch (status) {
      case TherapistApprovalStatus.pending:
        return 'Pending Review';
      case TherapistApprovalStatus.approved:
        return 'Approved';
      case TherapistApprovalStatus.rejected:
        return 'Rejected';
      case TherapistApprovalStatus.suspended:
        return 'Suspended';
    }
  }
}
