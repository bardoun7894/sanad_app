import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_cache_helper.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore;

  ProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user profile from Firestore
  Future<UserProfile?> getUserProfile(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .getCacheFirst();
    if (!doc.exists) return null;
    return _userProfileFromFirestore(doc);
  }

  /// Stream user profile updates
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? _userProfileFromFirestore(doc) : null);
  }

  /// Save or update user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await _firestore
        .collection('users')
        .doc(profile.id)
        .set(_userProfileToFirestore(profile), SetOptions(merge: true));
  }

  /// Update profile settings only
  Future<void> updateSettings(String userId, ProfileSettings settings) async {
    await _firestore.collection('users').doc(userId).set({
      'settings': _settingsToFirestore(settings),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get real profile stats from various collections
  Future<ProfileStats> getProfileStats(String userId) async {
    try {
      // Fetch stats in parallel
      final results = await Future.wait([
        _getCompletedSessionsCount(userId),
        _getMoodEntriesCount(userId),
        _getStreakDays(userId),
        _getCommunityPostsCount(userId),
      ]);

      return ProfileStats(
        totalSessions: results[0],
        moodEntriesCount: results[1],
        streakDays: results[2],
        communityPosts: results[3],
      );
    } catch (e) {
      // Return zeros on error
      return const ProfileStats();
    }
  }

  /// Get completed sessions count from bookings
  Future<int> _getCompletedSessionsCount(String userId) async {
    final snapshot = await _firestore
        .collection('bookings')
        .where('client_id', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get mood entries count
  Future<int> _getMoodEntriesCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_entries')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Calculate streak days (consecutive days with mood entries)
  Future<int> _getStreakDays(String userId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('mood_entries')
        .where('created_at', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .orderBy('created_at', descending: true)
        .limit(30)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    // Get unique dates
    final dates = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      // Handle both 'created_at' and 'date' fields as MoodEntry might use 'date'
      final timestamp =
          data['created_at'] as Timestamp? ?? data['date'] as Timestamp?;

      if (timestamp != null) {
        final date = timestamp.toDate();
        dates.add('${date.year}-${date.month}-${date.day}');
      }
    }

    // Count consecutive days from today
    int streak = 0;
    DateTime checkDate = now;

    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (dates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Allow missing today if it's early
        if (streak == 0 &&
            checkDate.year == now.year &&
            checkDate.month == now.month &&
            checkDate.day == now.day) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }

    return streak;
  }

  /// Get community posts count
  Future<int> _getCommunityPostsCount(String userId) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('author_id', isEqualTo: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Convert Firestore document to UserProfile
  UserProfile _userProfileFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserProfile(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      avatarUrl: _normalizeAvatarUrl(data['avatar_url'] as String?),
      dateOfBirth: (data['date_of_birth'] as Timestamp?)?.toDate(),
      gender: data['gender'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      settings: _settingsFromFirestore(
        data['settings'] as Map<String, dynamic>?,
      ),
      crisisMode: data['crisis_mode'] as bool? ?? false,
      crisisModeSetAt: (data['crisis_mode_set_at'] as Timestamp?)?.toDate(),
      crisisModeSetBy: data['crisis_mode_set_by'] as String?,
    );
  }

  /// Convert UserProfile to Firestore map
  Map<String, dynamic> _userProfileToFirestore(UserProfile profile) {
    return {
      'name': profile.name,
      'email': profile.email,
      'phone': profile.phone,
      'avatar_url': profile.avatarUrl,
      'date_of_birth': profile.dateOfBirth != null
          ? Timestamp.fromDate(profile.dateOfBirth!)
          : null,
      'gender': profile.gender,
      'created_at': Timestamp.fromDate(profile.createdAt),
      'settings': _settingsToFirestore(profile.settings),
      'crisis_mode': profile.crisisMode,
      if (profile.crisisModeSetAt != null)
        'crisis_mode_set_at': Timestamp.fromDate(profile.crisisModeSetAt!),
      if (profile.crisisModeSetBy != null)
        'crisis_mode_set_by': profile.crisisModeSetBy,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Convert Firestore map to ProfileSettings
  ProfileSettings _settingsFromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const ProfileSettings();

    return ProfileSettings(
      notificationsEnabled: data['notifications_enabled'] ?? true,
      dailyReminders: data['daily_reminders'] ?? true,
      moodTrackingReminders: data['mood_tracking_reminders'] ?? true,
      reminderTime: data['reminder_time'] ?? '09:00',
      darkMode: data['dark_mode'] ?? false,
      language: data['language'] ?? 'English',
      anonymousInCommunity: data['anonymous_in_community'] ?? false,
      shareProgress: data['share_progress'] ?? false,
    );
  }

  /// Convert ProfileSettings to Firestore map
  Map<String, dynamic> _settingsToFirestore(ProfileSettings settings) {
    return {
      'notifications_enabled': settings.notificationsEnabled,
      'daily_reminders': settings.dailyReminders,
      'mood_tracking_reminders': settings.moodTrackingReminders,
      'reminder_time': settings.reminderTime,
      'dark_mode': settings.darkMode,
      'language': settings.language,
      'anonymous_in_community': settings.anonymousInCommunity,
      'share_progress': settings.shareProgress,
    };
  }

  // Legacy avatar_url values point at assets/images/avatars/avatar_N.svg;
  // only the .png variants ship now. Rewrite at the data boundary so every
  // consumer is safe.
  static String? _normalizeAvatarUrl(String? url) {
    if (url == null) return null;
    if (url.startsWith('assets/images/avatars/avatar_') &&
        url.toLowerCase().endsWith('.svg')) {
      return url.replaceFirst(RegExp(r'\.svg$', caseSensitive: false), '.png');
    }
    return url;
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});
