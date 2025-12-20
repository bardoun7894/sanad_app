import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/auth_user.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_profile.dart';

class ProfileState {
  final UserProfile? user;
  final ProfileStats stats;
  final bool isLoading;
  final bool isEditing;

  const ProfileState({
    this.user,
    this.stats = const ProfileStats(),
    this.isLoading = false,
    this.isEditing = false,
  });

  ProfileState copyWith({
    UserProfile? user,
    ProfileStats? stats,
    bool? isLoading,
    bool? isEditing,
  }) {
    return ProfileState(
      user: user ?? this.user,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  void syncWithAuth(AuthUser? authUser) {
    if (authUser == null) {
      state = state.copyWith(user: null);
      return;
    }

    // Preserve existing settings/stats if user ID matches (e.g. simple profile update)
    // Otherwise create new profile for new user login
    final currentProfile = state.user;
    if (currentProfile != null && currentProfile.id == authUser.uid) {
      state = state.copyWith(
        user: currentProfile.copyWith(
          name: authUser.displayName ?? currentProfile.name,
          email: authUser.email,
          phone: authUser.phoneNumber ?? currentProfile.phone,
          avatarUrl: authUser.photoUrl ?? currentProfile.avatarUrl,
        ),
      );
    } else {
      // New user login - initialize with auth data and default settings
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
        // In a real app, we would fetch stats from a repository here
        stats: const ProfileStats(),
      );
    }
  }

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
  }) {
    if (state.user == null) return;

    state = state.copyWith(
      user: state.user!.copyWith(
        name: name,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
      ),
    );
  }

  void updateSettings(ProfileSettings settings) {
    if (state.user == null) return;

    state = state.copyWith(user: state.user!.copyWith(settings: settings));
  }

  void toggleNotifications(bool value) {
    if (state.user == null) return;

    state = state.copyWith(
      user: state.user!.copyWith(
        settings: state.user!.settings.copyWith(notificationsEnabled: value),
      ),
    );
  }

  void toggleDailyReminders(bool value) {
    if (state.user == null) return;

    state = state.copyWith(
      user: state.user!.copyWith(
        settings: state.user!.settings.copyWith(dailyReminders: value),
      ),
    );
  }

  void toggleMoodReminders(bool value) {
    if (state.user == null) return;

    state = state.copyWith(
      user: state.user!.copyWith(
        settings: state.user!.settings.copyWith(moodTrackingReminders: value),
      ),
    );
  }

  void toggleDarkMode(bool value) {
    if (state.user == null) return;

    state = state.copyWith(
      user: state.user!.copyWith(
        settings: state.user!.settings.copyWith(darkMode: value),
      ),
    );
  }

  void toggleAnonymous(bool value) {
    if (state.user == null) return;

    state = state.copyWith(
      user: state.user!.copyWith(
        settings: state.user!.settings.copyWith(anonymousInCommunity: value),
      ),
    );
  }

  void setLanguage(String language) {
    if (state.user == null) return;

    state = state.copyWith(
      user: state.user!.copyWith(
        settings: state.user!.settings.copyWith(language: language),
      ),
    );
  }

  void setEditing(bool value) {
    state = state.copyWith(isEditing: value);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final notifier = ProfileNotifier();

  // Listen for auth changes to sync profile
  ref.listen<AuthUser?>(currentUserProvider, (previous, next) {
    notifier.syncWithAuth(next);
  });

  // Initial sync
  final user = ref.read(currentUserProvider);
  notifier.syncWithAuth(user);

  return notifier;
});
