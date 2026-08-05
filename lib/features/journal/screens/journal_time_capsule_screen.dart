import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../l10n/journal_strings.dart';
import '../providers/journal_provider.dart';
import '../widgets/journal_entry_card.dart';

class JournalTimeCapsuleScreen extends ConsumerWidget {
  const JournalTimeCapsuleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider).language;
    final js = JournalStrings(lang);
    final state = ref.watch(journalProvider);
    final bg = isDark ? AppColors.journalBgDark : AppColors.journalBgLight;

    final now = DateTime.now();
    final capsule = state.entries
        .where((e) =>
            e.createdAt.month == now.month &&
            e.createdAt.day == now.day &&
            e.createdAt.year < now.year)
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(js.timeCapsule),
      ),
      body: capsule.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing3xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 64,
                      color: AppColors.journalAccent.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      js.noCapsule,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppTheme.spacingXl),
              children: [
                Text(
                  js.timeCapsuleSubtitle,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                ...capsule.map((e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingXs,
                          ),
                          child: Text(
                            _agoLabel(js, now, e.createdAt),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.journalAccent,
                            ),
                          ),
                        ),
                        JournalEntryCard(
                          entry: e,
                          localeCode: lang.code,
                          onTap: () =>
                              context.push(AppRoutes.journalNew, extra: e),
                        ),
                      ],
                    )),
              ],
            ),
    );
  }

  String _agoLabel(JournalStrings js, DateTime now, DateTime then) {
    final years = now.year - then.year;
    if (years <= 1) return js.yearAgo;
    return js.yearsAgo(years);
  }
}
