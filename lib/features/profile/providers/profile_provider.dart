import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  ProfileNotifier() : super(const ProfileState()) {
    _loadSampleProfile();
  }

  void _loadSampleProfile() {
    final sampleUser = UserProfile(
      id: 'user_1',
      name: 'Sarah Mohamed',
      email: 'sarah.mohamed@email.com',
      phone: '+966 50 123 4567',
      dateOfBirth: DateTime(1995, 3, 15),
      gender: 'Female',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      settings: const ProfileSettings(
        notificationsEnabled: true,
        dailyReminders: true,
        moodTrackingReminders: true,
        reminderTime: '09:00',
        darkMode: false,
        language: 'English',
        anonymousInCommunity: false,
        shareProgress: true,
      ),
    );

    const sampleStats = ProfileStats(
      totalSessions: 8,
      moodEntriesCount: 32,
      streakDays: 7,
      communityPosts: 5,
    );

    state = state.copyWith(user: sampleUser, stats: sampleStats);
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

    state = state.copyWith(
      user: state.user!.copyWith(settings: settings),
    );
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

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(),
);
