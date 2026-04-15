import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../therapists/models/therapist.dart';
import '../models/therapist_profile.dart';
import '../services/therapist_auth_service.dart';

/// State for therapist profile management
class TherapistProfileState {
  final TherapistProfile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const TherapistProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  /// Check if profile is loaded
  bool get hasProfile => profile != null;

  /// Check if therapist is approved
  bool get isApproved => profile?.approvalStatus == TherapistApprovalStatus.approved;

  /// Check if therapist is pending approval
  bool get isPending => profile?.approvalStatus == TherapistApprovalStatus.pending;

  /// Check if therapist is rejected
  bool get isRejected => profile?.approvalStatus == TherapistApprovalStatus.rejected;

  /// Check if therapist is suspended
  bool get isSuspended => profile?.approvalStatus == TherapistApprovalStatus.suspended;

  /// Check if therapist is active
  bool get isActive => profile?.isActive ?? false;

  /// Check if profile is complete for registration
  bool get isProfileComplete => profile?.isProfileComplete ?? false;

  /// Get rejection reason if available
  String? get rejectionReason => profile?.rejectionReason;

  TherapistProfileState copyWith({
    TherapistProfile? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearProfile = false,
  }) {
    return TherapistProfileState(
      profile: clearProfile ? null : (profile ?? this.profile),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Provider for managing therapist profile
class TherapistProfileNotifier extends StateNotifier<TherapistProfileState> {
  final TherapistAuthService _service;
  final String therapistId;
  StreamSubscription<TherapistProfile?>? _profileSubscription;

  TherapistProfileNotifier({
    required this.therapistId,
    TherapistAuthService? service,
  })  : _service = service ?? TherapistAuthService(),
        super(const TherapistProfileState()) {
    _init();
  }

  void _init() {
    _subscribeToProfile();
  }

  /// Subscribe to profile changes
  void _subscribeToProfile() {
    state = state.copyWith(isLoading: true, clearError: true);

    _profileSubscription?.cancel();
    _profileSubscription = _service.getProfileStream(therapistId).listen(
      (profile) {
        state = state.copyWith(profile: profile, isLoading: false);
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load profile: $error',
        );
      },
    );
  }

  /// Reload profile
  Future<void> reload() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _service.getProfile(therapistId);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: $e',
      );
    }
  }

  /// Update profile with a map of fields
  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      await _service.updateProfile(therapistId, data);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Profile updated successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update profile: $e',
      );
    }
  }

  /// Update profile with full TherapistProfile object
  Future<void> updateFullProfile(TherapistProfile profile) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      await _service.updateProfileFromModel(profile);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Profile updated successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update profile: $e',
      );
    }
  }

  /// Update name
  Future<void> updateName(String name) async {
    await updateProfile({'name': name});
  }

  /// Update title
  Future<void> updateTitle(String title) async {
    await updateProfile({'title': title});
  }

  /// Update bio
  Future<void> updateBio(String bio) async {
    await updateProfile({'bio': bio});
  }

  /// Update specialties
  Future<void> updateSpecialties(List<Specialty> specialties) async {
    await updateProfile({'specialties': specialties.map((s) => s.name).toList()});
  }

  /// Update session types
  Future<void> updateSessionTypes(List<SessionType> sessionTypes) async {
    await updateProfile({'session_types': sessionTypes.map((s) => s.firestoreValue).toList()});
  }

  /// Update languages
  Future<void> updateLanguages(List<String> languages) async {
    await updateProfile({'languages': languages});
  }

  /// Update qualifications
  Future<void> updateQualifications(List<String> qualifications) async {
    await updateProfile({'qualifications': qualifications});
  }

  /// Update session price
  Future<void> updateSessionPrice(double price, {String? currency}) async {
    final data = <String, dynamic>{'session_price': price};
    if (currency != null) {
      data['currency'] = currency;
    }
    await updateProfile(data);
  }

  /// Update years of experience
  Future<void> updateYearsExperience(int years) async {
    await updateProfile({'years_experience': years});
  }

  /// Update photo URL
  Future<void> updatePhotoUrl(String photoUrl) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      await _service.updatePhotoUrl(therapistId, photoUrl);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Photo updated successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update photo: $e',
      );
    }
  }

  /// Toggle active status
  Future<void> toggleActive() async {
    if (state.profile == null) return;

    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      final newStatus = !state.profile!.isActive;
      await _service.toggleActive(therapistId, newStatus);
      state = state.copyWith(
        isSaving: false,
        successMessage: newStatus ? 'You are now online' : 'You are now offline',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update status: $e',
      );
    }
  }

  /// Set active status explicitly
  Future<void> setActive(bool isActive) async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      await _service.toggleActive(therapistId, isActive);
      state = state.copyWith(
        isSaving: false,
        successMessage: isActive ? 'You are now online' : 'You are now offline',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update status: $e',
      );
    }
  }

  /// Update phone number
  Future<void> updatePhoneNumber(String phoneNumber) async {
    await updateProfile({'phone_number': phoneNumber});
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  /// Clear all messages
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}

/// Provider family for therapist profile by ID
final therapistProfileProvider = StateNotifierProvider.family<
    TherapistProfileNotifier, TherapistProfileState, String>(
  (ref, therapistId) => TherapistProfileNotifier(therapistId: therapistId),
);

/// Provider for the currently authenticated therapist's profile
/// This should be overridden in the app with the actual therapist ID
final currentTherapistProfileProvider =
    StateNotifierProvider<TherapistProfileNotifier, TherapistProfileState>(
  (ref) {
    // This should be overridden with the actual therapist ID
    throw UnimplementedError(
      'currentTherapistProfileProvider must be overridden with actual therapist ID',
    );
  },
);

/// Provider for therapist approval status only (lightweight)
final therapistApprovalStatusProvider =
    FutureProvider.family<TherapistApprovalStatus, String>((ref, therapistId) async {
  final service = TherapistAuthService();
  return await service.getTherapistStatus(therapistId);
});

/// Provider to check if user is an approved therapist
final isApprovedTherapistProvider =
    FutureProvider.family<bool, String>((ref, therapistId) async {
  final service = TherapistAuthService();
  return await service.isApprovedTherapist(therapistId);
});
