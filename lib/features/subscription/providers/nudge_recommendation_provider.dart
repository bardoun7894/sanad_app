import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/language_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../mood/models/mood_enums.dart';
import '../../profile/services/profile_service.dart';
import '../../therapists/models/therapist.dart';
import '../../therapists/providers/therapist_provider.dart';
import '../../mood/providers/mood_tracker_provider.dart';

/// A personalized recommendation used to build the subscription nudge.
///
/// One of [mood]/[interest] drives [reasonLine] (the emotional hook), and
/// [therapist] is the best-rated specialist matching that signal — the
/// "reward" the user gets for subscribing/booking.
class NudgeRecommendation {
  final MoodType? mood;
  final String? interest; // canonical English issue key
  final Therapist? therapist;
  final String reasonLine;

  const NudgeRecommendation({
    this.mood,
    this.interest,
    this.therapist,
    required this.reasonLine,
  });
}

/// Persisted therapy interests for the signed-in user (empty if none/guest).
final userInterestsProvider = FutureProvider<List<String>>((ref) async {
  final uid = ref.watch(currentUserProvider)?.uid;
  if (uid == null) return const [];
  return ref.watch(profileServiceProvider).getInterests(uid);
});

/// Map a canonical intake issue key to a therapist [Specialty].
/// Mirrors `TherapistNotifier._mapIssueToSpecialty`.
Specialty? _issueToSpecialty(String issue) {
  switch (issue.toLowerCase()) {
    case 'anxiety':
      return Specialty.anxiety;
    case 'depression':
      return Specialty.depression;
    case 'stress':
    case 'work':
      return Specialty.stress;
    case 'relationships':
    case 'family':
      return Specialty.relationships;
    case 'trauma':
      return Specialty.trauma;
    case 'grief':
      return Specialty.grief;
    case 'self-esteem':
      return Specialty.selfEsteem;
    default:
      return null;
  }
}

/// Map a (negative) mood to the specialty most likely to help. Positive moods
/// (happy/calm) return null — we don't guilt-trip a user who feels good.
Specialty? _moodToSpecialty(MoodType mood) {
  switch (mood) {
    case MoodType.anxious:
      return Specialty.anxiety;
    case MoodType.sad:
      return Specialty.depression;
    case MoodType.angry:
    case MoodType.tired:
      return Specialty.stress;
    case MoodType.happy:
    case MoodType.calm:
      return null;
  }
}

String _moodLabel(MoodType mood, S s) {
  switch (mood) {
    case MoodType.happy:
      return s.moodHappy;
    case MoodType.calm:
      return s.moodCalm;
    case MoodType.anxious:
      return s.moodAnxious;
    case MoodType.sad:
      return s.moodSad;
    case MoodType.angry:
      return s.moodAngry;
    case MoodType.tired:
      return s.moodTired;
  }
}

Therapist? _bestForSpecialty(List<Therapist> therapists, Specialty? specialty) {
  if (therapists.isEmpty) return null;
  final pool = specialty == null
      ? therapists
      : therapists.where((t) => t.specialties.contains(specialty)).toList();
  final list = pool.isEmpty ? therapists : pool;
  final sorted = List<Therapist>.from(list)
    ..sort((a, b) => b.rating.compareTo(a.rating));
  return sorted.first;
}

/// Builds the personalized nudge. Prefers an explicit interest, then a negative
/// mood trend, then falls back to a generic (still-capped) upsell.
final nudgeRecommendationProvider = Provider<NudgeRecommendation>((ref) {
  final s = ref.watch(stringsProvider);
  final therapists = ref.watch(therapistProvider).therapists;
  final interests = ref.watch(userInterestsProvider).valueOrNull ?? const [];
  final moodState = ref.watch(moodTrackerProvider);
  final mood = moodState.dominantMood ?? moodState.todayEntry?.mood;

  // 1) Interest-driven.
  for (final issue in interests) {
    final specialty = _issueToSpecialty(issue);
    if (specialty != null) {
      final label = SpecialtyData.getLabel(specialty, strings: s);
      return NudgeRecommendation(
        interest: issue,
        therapist: _bestForSpecialty(therapists, specialty),
        reasonLine: '${s.nudgeBecauseYouCareAbout} $label',
      );
    }
  }

  // 2) Mood-driven (negative moods only).
  if (mood != null) {
    final specialty = _moodToSpecialty(mood);
    if (specialty != null) {
      return NudgeRecommendation(
        mood: mood,
        therapist: _bestForSpecialty(therapists, specialty),
        reasonLine: '${s.nudgeBecauseYouFelt} ${_moodLabel(mood, s)}',
      );
    }
  }

  // 3) Generic fallback — still shows a top therapist as the reward.
  return NudgeRecommendation(
    therapist: _bestForSpecialty(therapists, null),
    reasonLine: s.nudgeGenericTitle,
  );
});
