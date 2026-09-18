import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/language_provider.dart';

/// Admin-editable writing prompts. This is the ONLY journal-related data that
/// lives in the cloud — the prompts are generic questions, never user content.
/// Collection: `journaling_prompts` (docs: question, question_en, order,
/// is_active). Mirrors the daily_challenges CMS pattern.
class JournalPrompt {
  final String id;
  final String question;
  final String questionEn;
  final int order;

  const JournalPrompt({
    required this.id,
    required this.question,
    required this.questionEn,
    this.order = 0,
  });

  String localized(AppLanguage lang) {
    if (lang == AppLanguage.arabic) return question;
    return questionEn.isNotEmpty ? questionEn : question;
  }
}

/// Fetches active prompts (server-first) and sorts by `order` CLIENT-SIDE to
/// avoid Firestore silently dropping docs missing the orderBy field.
final journalPromptsProvider = FutureProvider<List<JournalPrompt>>((ref) async {
  try {
    final snap = await FirebaseFirestore.instance
        .collection('journaling_prompts')
        .where('is_active', isEqualTo: true)
        .get();
    final prompts = snap.docs.map((d) {
      final data = d.data();
      return JournalPrompt(
        id: d.id,
        question: (data['question'] as String?) ?? '',
        questionEn: (data['question_en'] as String?) ?? '',
        order: (data['order'] as num?)?.toInt() ?? 0,
      );
    }).where((p) => p.question.isNotEmpty).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return prompts;
  } catch (_) {
    return const [];
  }
});

/// The prompt to surface today — deterministic by day-of-year so it feels like
/// a stable "سؤال اليوم" and rotates through the admin's list.
final promptOfTheDayProvider = Provider<JournalPrompt?>((ref) {
  final async = ref.watch(journalPromptsProvider);
  return async.maybeWhen(
    data: (prompts) {
      if (prompts.isEmpty) return null;
      final now = DateTime.now();
      final dayOfYear =
          now.difference(DateTime(now.year, 1, 1)).inDays;
      return prompts[dayOfYear % prompts.length];
    },
    orElse: () => null,
  );
});
