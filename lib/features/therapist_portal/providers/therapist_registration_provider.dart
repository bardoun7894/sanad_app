import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../therapists/models/therapist.dart';
import '../models/therapist_profile.dart';
import '../services/therapist_auth_service.dart';
import '../../auth/providers/auth_provider.dart';

/// State for therapist registration flow
class TherapistRegistrationState {
  final bool isLoading;
  final bool isSubmitted;
  final TherapistApprovalStatus? status;
  final String? errorMessage;
  final int currentStep;
  final TherapistRegistrationData registrationData;

  const TherapistRegistrationState({
    this.isLoading = false,
    this.isSubmitted = false,
    this.status,
    this.errorMessage,
    this.currentStep = 0,
    this.registrationData = const TherapistRegistrationData(),
  });

  TherapistRegistrationState copyWith({
    bool? isLoading,
    bool? isSubmitted,
    TherapistApprovalStatus? status,
    String? errorMessage,
    int? currentStep,
    TherapistRegistrationData? registrationData,
    bool clearError = false,
  }) {
    return TherapistRegistrationState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentStep: currentStep ?? this.currentStep,
      registrationData: registrationData ?? this.registrationData,
    );
  }

  /// Check if current step is complete
  bool get isCurrentStepComplete {
    switch (currentStep) {
      case 0:
        return registrationData.isStep1Complete;
      case 1:
        return registrationData.isStep2Complete;
      case 2:
        return registrationData.isStep3Complete;
      default:
        return false;
    }
  }

  /// Check if all steps are complete
  bool get isAllStepsComplete =>
      registrationData.isStep1Complete &&
      registrationData.isStep2Complete &&
      registrationData.isStep3Complete;
}

/// Data class to hold registration form data
class TherapistRegistrationData {
  // Step 1: Basic Info
  final String name;
  final String title;
  final String bio;
  final String? phoneNumber;

  // Step 2: Professional Details
  final List<Specialty> specialties;
  final List<String> languages;
  final List<String> qualifications;
  final int yearsExperience;

  // Step 3: Session Info
  final List<SessionType> sessionTypes;
  final double sessionPrice;
  final String currency;

  // Optional
  final String? licenseDocumentUrl;
  final String? photoUrl;

  const TherapistRegistrationData({
    this.name = '',
    this.title = '',
    this.bio = '',
    this.phoneNumber,
    this.specialties = const [],
    this.languages = const [],
    this.qualifications = const [],
    this.yearsExperience = 0,
    this.sessionTypes = const [],
    this.sessionPrice = 0.0,
    this.currency = 'USD',
    this.licenseDocumentUrl,
    this.photoUrl,
  });

  TherapistRegistrationData copyWith({
    String? name,
    String? title,
    String? bio,
    String? phoneNumber,
    List<Specialty>? specialties,
    List<String>? languages,
    List<String>? qualifications,
    int? yearsExperience,
    List<SessionType>? sessionTypes,
    double? sessionPrice,
    String? currency,
    String? licenseDocumentUrl,
    String? photoUrl,
  }) {
    return TherapistRegistrationData(
      name: name ?? this.name,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      specialties: specialties ?? this.specialties,
      languages: languages ?? this.languages,
      qualifications: qualifications ?? this.qualifications,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      sessionTypes: sessionTypes ?? this.sessionTypes,
      sessionPrice: sessionPrice ?? this.sessionPrice,
      currency: currency ?? this.currency,
      licenseDocumentUrl: licenseDocumentUrl ?? this.licenseDocumentUrl,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  /// Validation for Step 1
  bool get isStep1Complete =>
      name.isNotEmpty && title.isNotEmpty && bio.length >= 50;

  /// Validation for Step 2
  bool get isStep2Complete =>
      specialties.isNotEmpty &&
      languages.isNotEmpty &&
      yearsExperience > 0;

  /// Validation for Step 3
  bool get isStep3Complete =>
      sessionTypes.isNotEmpty && sessionPrice > 0;
}

/// State notifier for therapist registration
class TherapistRegistrationNotifier extends StateNotifier<TherapistRegistrationState> {
  final TherapistAuthService _authService;
  final String _userId;
  final String _userEmail;

  TherapistRegistrationNotifier(
    this._authService,
    this._userId,
    this._userEmail,
  ) : super(const TherapistRegistrationState()) {
    _checkExistingStatus();
  }

  /// Check if user already has a pending registration
  Future<void> _checkExistingStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final status = await _authService.getTherapistStatus(_userId);
      if (status != TherapistApprovalStatus.pending) {
        state = state.copyWith(
          isLoading: false,
          status: status,
          isSubmitted: status != TherapistApprovalStatus.pending,
        );
      } else {
        // Check if there's an existing profile
        final profile = await _authService.getProfile(_userId);
        if (profile != null) {
          state = state.copyWith(
            isLoading: false,
            status: profile.approvalStatus,
            isSubmitted: true,
          );
        } else {
          state = state.copyWith(isLoading: false);
        }
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to check registration status',
      );
    }
  }

  /// Refresh status from server
  Future<void> refreshStatus() async {
    await _checkExistingStatus();
  }

  /// Go to next step
  void nextStep() {
    if (state.currentStep < 2 && state.isCurrentStepComplete) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Go to previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Go to specific step
  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Update Step 1 data
  void updateStep1({
    String? name,
    String? title,
    String? bio,
    String? phoneNumber,
  }) {
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(
        name: name,
        title: title,
        bio: bio,
        phoneNumber: phoneNumber,
      ),
      clearError: true,
    );
  }

  /// Update Step 2 data
  void updateStep2({
    List<Specialty>? specialties,
    List<String>? languages,
    List<String>? qualifications,
    int? yearsExperience,
  }) {
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(
        specialties: specialties,
        languages: languages,
        qualifications: qualifications,
        yearsExperience: yearsExperience,
      ),
      clearError: true,
    );
  }

  /// Update Step 3 data
  void updateStep3({
    List<SessionType>? sessionTypes,
    double? sessionPrice,
    String? currency,
  }) {
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(
        sessionTypes: sessionTypes,
        sessionPrice: sessionPrice,
        currency: currency,
      ),
      clearError: true,
    );
  }

  /// Add a specialty
  void addSpecialty(Specialty specialty) {
    if (!state.registrationData.specialties.contains(specialty)) {
      final updated = [...state.registrationData.specialties, specialty];
      state = state.copyWith(
        registrationData: state.registrationData.copyWith(specialties: updated),
      );
    }
  }

  /// Remove a specialty
  void removeSpecialty(Specialty specialty) {
    final updated = state.registrationData.specialties
        .where((s) => s != specialty)
        .toList();
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(specialties: updated),
    );
  }

  /// Add a session type
  void addSessionType(SessionType type) {
    if (!state.registrationData.sessionTypes.contains(type)) {
      final updated = [...state.registrationData.sessionTypes, type];
      state = state.copyWith(
        registrationData: state.registrationData.copyWith(sessionTypes: updated),
      );
    }
  }

  /// Remove a session type
  void removeSessionType(SessionType type) {
    final updated = state.registrationData.sessionTypes
        .where((s) => s != type)
        .toList();
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(sessionTypes: updated),
    );
  }

  /// Add a language
  void addLanguage(String language) {
    if (!state.registrationData.languages.contains(language)) {
      final updated = [...state.registrationData.languages, language];
      state = state.copyWith(
        registrationData: state.registrationData.copyWith(languages: updated),
      );
    }
  }

  /// Remove a language
  void removeLanguage(String language) {
    final updated = state.registrationData.languages
        .where((l) => l != language)
        .toList();
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(languages: updated),
    );
  }

  /// Add a qualification
  void addQualification(String qualification) {
    if (qualification.isNotEmpty &&
        !state.registrationData.qualifications.contains(qualification)) {
      final updated = [...state.registrationData.qualifications, qualification];
      state = state.copyWith(
        registrationData: state.registrationData.copyWith(qualifications: updated),
      );
    }
  }

  /// Remove a qualification
  void removeQualification(String qualification) {
    final updated = state.registrationData.qualifications
        .where((q) => q != qualification)
        .toList();
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(qualifications: updated),
    );
  }

  /// Update photo URL
  void updatePhotoUrl(String? url) {
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(photoUrl: url),
    );
  }

  /// Update license document URL
  void updateLicenseUrl(String? url) {
    state = state.copyWith(
      registrationData: state.registrationData.copyWith(licenseDocumentUrl: url),
    );
  }

  /// Submit registration
  Future<void> submitRegistration() async {
    if (!state.isAllStepsComplete) {
      state = state.copyWith(
        errorMessage: 'Please complete all required fields',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = state.registrationData;
      final profile = TherapistProfile(
        id: _userId,
        email: _userEmail,
        name: data.name,
        title: data.title,
        bio: data.bio,
        phoneNumber: data.phoneNumber,
        specialties: data.specialties,
        sessionTypes: data.sessionTypes,
        languages: data.languages,
        qualifications: data.qualifications,
        yearsExperience: data.yearsExperience,
        sessionPrice: data.sessionPrice,
        currency: data.currency,
        photoUrl: data.photoUrl,
        licenseDocumentUrl: data.licenseDocumentUrl,
        approvalStatus: TherapistApprovalStatus.pending,
        isActive: false,
        rating: 0.0,
        reviewCount: 0,
        createdAt: DateTime.now(),
      );

      await _authService.submitRegistration(profile);

      state = state.copyWith(
        isLoading: false,
        isSubmitted: true,
        status: TherapistApprovalStatus.pending,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit registration: ${e.toString()}',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset form
  void resetForm() {
    state = const TherapistRegistrationState();
  }
}

// Providers
final therapistAuthServiceProvider = Provider<TherapistAuthService>((ref) {
  return TherapistAuthService();
});

final therapistRegistrationProvider = StateNotifierProvider<
    TherapistRegistrationNotifier, TherapistRegistrationState>((ref) {
  final authState = ref.watch(authProvider);
  final authService = ref.watch(therapistAuthServiceProvider);

  final userId = authState.user?.uid ?? '';
  final userEmail = authState.user?.email ?? '';

  return TherapistRegistrationNotifier(authService, userId, userEmail);
});

/// Helper provider to check registration status
final therapistRegistrationStatusProvider = Provider<TherapistApprovalStatus?>((ref) {
  return ref.watch(therapistRegistrationProvider).status;
});

/// Helper provider to check if registration is submitted
final isRegistrationSubmittedProvider = Provider<bool>((ref) {
  return ref.watch(therapistRegistrationProvider).isSubmitted;
});
