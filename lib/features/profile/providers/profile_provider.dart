import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileState {
  final UserProfile? user;
  final ProfileStats stats;
  final bool isLoading;
  final bool isEditing;
  final bool isSaving;
  final String? error;

  const ProfileState({
    this.user,
    this.stats = const ProfileStats(),
    this.isLoading = false,
    this.isEditing = false,
    this.isSaving = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? user,
    ProfileStats? stats,
    bool? isLoading,
    bool? isEditing,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _service;

  ProfileNotifier(this._service) : super(const ProfileState());

  Future<void> syncWithAuth(AuthUser? authUser) async {
    if (authUser == null) {
      state = state.copyWith(user: null, stats: const ProfileStats());
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Try to load existing profile from Firestore
      final existingProfile = await _service.getUserProfile(authUser.uid);

      if (existingProfile != null) {
        state = state.copyWith(user: existingProfile, isLoading: false);
      } else {
        // Create new profile from auth data
        final newProfile = UserProfile(
          id: authUser.uid,
          name: authUser.displayName ?? authUser.email.split('@')[0],
          email: authUser.email,
          phone: authUser.phoneNumber,
          avatarUrl: authUser.photoUrl,
          createdAt: authUser.createdAt,
          settings: const ProfileSettings(),
        );

        // Save to Firestore
        await _service.saveUserProfile(newProfile);
        state = state.copyWith(user: newProfile, isLoading: false);
      }

      // Fetch real stats
      _loadStats(authUser.uid);
    } catch (e) {
      // Fallback to auth data on error
      state = state.copyWith(
        user: UserProfile(
          id: authUser.uid,
          name: authUser.displayName ?? authUser.email.split('@')[0],
          email: authUser.email,
          phone: authUser.phoneNumber,
          avatarUrl: authUser.photoUrl,
          createdAt: authUser.createdAt,
          settings: const ProfileSettings(),
        ),
        isLoading: false,
        error: 'Failed to load profile: $e',
      );
    }
  }

  Future<void> _loadStats(String userId) async {
    try {
      final stats = await _service.getProfileStats(userId);
      state = state.copyWith(stats: stats);
    } catch (e) {
      // Keep existing stats on error
    }
  }

  Future<void> refreshStats() async {
    final userId = state.user?.id;
    if (userId != null) {
      await _loadStats(userId);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    if (state.user == null) return;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      // If the avatar is a freshly picked local file, upload it to Storage
      // first and persist the resulting download URL — never store file:// in
      // Firestore (it won't survive across devices or app reinstalls).
      String? resolvedAvatarUrl = avatarUrl;
      if (avatarUrl != null && avatarUrl.startsWith('file://')) {
        try {
          final localPath = avatarUrl.replaceFirst('file://', '');
          final bytes = await File(localPath).readAsBytes();
          final storage = StorageService();
          resolvedAvatarUrl = await storage.uploadFile(
            path: 'profile_photos/${state.user!.id}.jpg',
            data: bytes,
            contentType: 'image/jpeg',
          );
        } catch (e) {
          debugPrint('Avatar upload failed, keeping previous: $e');
          resolvedAvatarUrl = state.user!.avatarUrl;
        }
      }

      final updatedProfile = state.user!.copyWith(
        name: name,
        email: email,
        phone: phone,
        avatarUrl: resolvedAvatarUrl,
        dateOfBirth: dateOfBirth,
        gender: gender,
      );

      // Save to Firestore
      await _service.saveUserProfile(updatedProfile);
      state = state.copyWith(user: updatedProfile, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update profile: $e',
      );
    }
  }

  Future<void> updateSettings(ProfileSettings settings) async {
    if (state.user == null) return;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      // Save to Firestore
      await _service.updateSettings(state.user!.id, settings);
      state = state.copyWith(
        user: state.user!.copyWith(settings: settings),
        isSaving: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to update settings: $e',
      );
    }
  }

  Future<void> toggleNotifications(bool value) async {
    if (state.user == null) return;

    final newSettings = state.user!.settings.copyWith(
      notificationsEnabled: value,
    );

    // Optimistic update
    state = state.copyWith(user: state.user!.copyWith(settings: newSettings));

    // Persist to Firestore
    try {
      await _service.updateSettings(state.user!.id, newSettings);
    } catch (e) {
      // Revert on error
      final revertSettings = state.user!.settings.copyWith(
        notificationsEnabled: !value,
      );
      state = state.copyWith(
        user: state.user!.copyWith(settings: revertSettings),
        error: 'Failed to update notifications setting',
      );
    }
  }

  Future<void> toggleDailyReminders(bool value) async {
    if (state.user == null) return;

    final newSettings = state.user!.settings.copyWith(dailyReminders: value);
    state = state.copyWith(user: state.user!.copyWith(settings: newSettings));

    try {
      await _service.updateSettings(state.user!.id, newSettings);
    } catch (e) {
      // Revert on error
      final revertSettings = state.user!.settings.copyWith(
        dailyReminders: !value,
      );
      state = state.copyWith(
        user: state.user!.copyWith(settings: revertSettings),
        error: 'Failed to update daily reminders setting',
      );
    }
  }

  Future<void> toggleMoodReminders(bool value) async {
    if (state.user == null) return;

    final newSettings = state.user!.settings.copyWith(
      moodTrackingReminders: value,
    );
    state = state.copyWith(user: state.user!.copyWith(settings: newSettings));

    try {
      await _service.updateSettings(state.user!.id, newSettings);
    } catch (e) {
      final revertSettings = state.user!.settings.copyWith(
        moodTrackingReminders: !value,
      );
      state = state.copyWith(
        user: state.user!.copyWith(settings: revertSettings),
        error: 'Failed to update mood reminders setting',
      );
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    if (state.user == null) return;

    final newSettings = state.user!.settings.copyWith(darkMode: value);
    state = state.copyWith(user: state.user!.copyWith(settings: newSettings));

    try {
      await _service.updateSettings(state.user!.id, newSettings);
    } catch (e) {
      final revertSettings = state.user!.settings.copyWith(darkMode: !value);
      state = state.copyWith(
        user: state.user!.copyWith(settings: revertSettings),
        error: 'Failed to update dark mode setting',
      );
    }
  }

  Future<void> toggleAnonymous(bool value) async {
    if (state.user == null) return;

    final newSettings = state.user!.settings.copyWith(
      anonymousInCommunity: value,
    );
    state = state.copyWith(user: state.user!.copyWith(settings: newSettings));

    try {
      await _service.updateSettings(state.user!.id, newSettings);
    } catch (e) {
      final revertSettings = state.user!.settings.copyWith(
        anonymousInCommunity: !value,
      );
      state = state.copyWith(
        user: state.user!.copyWith(settings: revertSettings),
        error: 'Failed to update anonymous setting',
      );
    }
  }

  Future<void> setLanguage(String language) async {
    if (state.user == null) return;

    final oldLanguage = state.user!.settings.language;
    final newSettings = state.user!.settings.copyWith(language: language);
    state = state.copyWith(user: state.user!.copyWith(settings: newSettings));

    try {
      await _service.updateSettings(state.user!.id, newSettings);
    } catch (e) {
      final revertSettings = state.user!.settings.copyWith(
        language: oldLanguage,
      );
      state = state.copyWith(
        user: state.user!.copyWith(settings: revertSettings),
        error: 'Failed to update language setting',
      );
    }
  }

  void setEditing(bool value) {
    state = state.copyWith(isEditing: value);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final service = ref.watch(profileServiceProvider);
  final notifier = ProfileNotifier(service);

  // Listen for auth changes to sync profile
  ref.listen<AuthUser?>(currentUserProvider, (previous, next) {
    notifier.syncWithAuth(next);
  });

  // Initial sync
  final user = ref.read(currentUserProvider);
  notifier.syncWithAuth(user);

  return notifier;
});

/// Provider for just the profile stats (useful for dashboard displays)
final profileStatsProvider = Provider<ProfileStats>((ref) {
  return ref.watch(profileProvider).stats;
});
