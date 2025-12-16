class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;
  final ProfileSettings settings;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
    this.settings = const ProfileSettings(),
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? gender,
    DateTime? createdAt,
    ProfileSettings? settings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      settings: settings ?? this.settings,
    );
  }
}

class ProfileSettings {
  final bool notificationsEnabled;
  final bool dailyReminders;
  final bool moodTrackingReminders;
  final String reminderTime;
  final bool darkMode;
  final String language;
  final bool anonymousInCommunity;
  final bool shareProgress;

  const ProfileSettings({
    this.notificationsEnabled = true,
    this.dailyReminders = true,
    this.moodTrackingReminders = true,
    this.reminderTime = '09:00',
    this.darkMode = false,
    this.language = 'English',
    this.anonymousInCommunity = false,
    this.shareProgress = false,
  });

  ProfileSettings copyWith({
    bool? notificationsEnabled,
    bool? dailyReminders,
    bool? moodTrackingReminders,
    String? reminderTime,
    bool? darkMode,
    String? language,
    bool? anonymousInCommunity,
    bool? shareProgress,
  }) {
    return ProfileSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      moodTrackingReminders: moodTrackingReminders ?? this.moodTrackingReminders,
      reminderTime: reminderTime ?? this.reminderTime,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
      anonymousInCommunity: anonymousInCommunity ?? this.anonymousInCommunity,
      shareProgress: shareProgress ?? this.shareProgress,
    );
  }
}

class ProfileStats {
  final int totalSessions;
  final int moodEntriesCount;
  final int streakDays;
  final int communityPosts;

  const ProfileStats({
    this.totalSessions = 0,
    this.moodEntriesCount = 0,
    this.streakDays = 0,
    this.communityPosts = 0,
  });
}
