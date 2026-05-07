import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class FaqEntry {
  final String id;
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
  final int order;

  const FaqEntry({
    required this.id,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    required this.order,
  });

  factory FaqEntry.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return FaqEntry(
      id: doc.id,
      questionAr: (data['question_ar'] as String?) ?? '',
      questionEn: (data['question_en'] as String?) ?? '',
      answerAr: (data['answer_ar'] as String?) ?? '',
      answerEn: (data['answer_en'] as String?) ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  String question(bool isArabic) =>
      (isArabic ? questionAr : questionEn).trim().isNotEmpty
      ? (isArabic ? questionAr : questionEn)
      : (isArabic ? questionEn : questionAr);

  String answer(bool isArabic) =>
      (isArabic ? answerAr : answerEn).trim().isNotEmpty
      ? (isArabic ? answerAr : answerEn)
      : (isArabic ? answerEn : answerAr);
}

final faqListProvider = StreamProvider<List<FaqEntry>>((ref) {
  return FirebaseFirestore.instance
      .collection('faqs')
      .orderBy('order')
      .snapshots()
      .map((snap) => snap.docs.map(FaqEntry.fromDoc).toList());
});

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = ref.watch(languageProvider).language == AppLanguage.arabic;
    final faqAsync = ref.watch(faqListProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          s.faqs,
          style: AppTypography.headingLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: faqAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${s.errorLoading}\n$err',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 64,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.noFaqsYet,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _FaqTile(entry: entry, isArabic: isArabic, isDark: isDark);
            },
          );
        },
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final FaqEntry entry;
  final bool isArabic;
  final bool isDark;

  const _FaqTile({
    required this.entry,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border,
        ),
      ),
      child: Theme(
        data: Theme.of(
          context,
        ).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.primary,
          title: Text(
            entry.question(isArabic),
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: isArabic
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                entry.answer(isArabic),
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
