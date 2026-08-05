import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/language_provider.dart';
import '../../mood/models/mood_enums.dart';

/// A supportive, admin-authored advice line for one mood.
class MoodAdviceEntry {
  final String mood; // MoodType.name
  final String advice;
  final String adviceEn;

  const MoodAdviceEntry({
    required this.mood,
    required this.advice,
    required this.adviceEn,
  });

  String localized(AppLanguage lang) {
    if (lang == AppLanguage.arabic) return advice;
    return adviceEn.isNotEmpty ? adviceEn : advice;
  }
}

/// Reads the `mood_advice` collection (active docs only) into a mood→advice map.
final moodAdviceProvider =
    FutureProvider<Map<String, MoodAdviceEntry>>((ref) async {
  try {
    final snap = await FirebaseFirestore.instance.collection('mood_advice').get();
    final map = <String, MoodAdviceEntry>{};
    for (final d in snap.docs) {
      final data = d.data();
      if (data['is_active'] == false) continue;
      final advice = (data['advice'] as String?) ?? '';
      if (advice.isEmpty) continue;
      map[d.id] = MoodAdviceEntry(
        mood: d.id,
        advice: advice,
        adviceEn: (data['advice_en'] as String?) ?? '',
      );
    }
    return map;
  } catch (_) {
    return const {};
  }
});

/// Moods that should offer a calming-exercise CTA alongside the advice.
const negativeMoods = {
  MoodType.anxious,
  MoodType.sad,
  MoodType.angry,
  MoodType.tired,
};
