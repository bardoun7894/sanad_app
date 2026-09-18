import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../l10n/journal_strings.dart';
import '../providers/journal_lock_provider.dart';
import '../providers/journal_provider.dart';
import '../widgets/journal_entry_card.dart';

class JournalHomeScreen extends ConsumerStatefulWidget {
  const JournalHomeScreen({super.key});

  @override
  ConsumerState<JournalHomeScreen> createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends ConsumerState<JournalHomeScreen> {
  String _search = '';
  String? _tagFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(languageProvider).language;
    final js = JournalStrings(lang);
    final state = ref.watch(journalProvider);

    final bg = isDark ? AppColors.journalBgDark : AppColors.journalBgLight;

    final filtered = state.entries.where((e) {
      final matchesSearch = _search.isEmpty ||
          e.body.toLowerCase().contains(_search.toLowerCase());
      final matchesTag = _tagFilter == null || e.tags.contains(_tagFilter);
      return matchesSearch && matchesTag;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(js.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(js),
          ),
        ],
      ),
      floatingActionButton: state.entries.isEmpty
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => context.push(AppRoutes.journalNew),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: state.isLoading && state.entries.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.entries.isEmpty
              ? _EmptyState(js: js)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingXl,
                        AppTheme.spacingSm,
                        AppTheme.spacingXl,
                        AppTheme.spacingSm,
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: js.searchHint,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.journalSurfaceDark
                              : AppColors.journalSurfaceLight,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    if (state.allTags.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXl,
                          ),
                          children: [
                            _TagChip(
                              label: js.all,
                              selected: _tagFilter == null,
                              onTap: () => setState(() => _tagFilter = null),
                            ),
                            ...state.allTags.map(
                              (t) => _TagChip(
                                label: '#$t',
                                selected: _tagFilter == t,
                                onTap: () => setState(
                                  () => _tagFilter = _tagFilter == t ? null : t,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.spacingXl,
                          AppTheme.spacingMd,
                          AppTheme.spacingXl,
                          100,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final entry = filtered[i];
                          return JournalEntryCard(
                            entry: entry,
                            localeCode: lang.code,
                            onTap: () => context.push(
                              AppRoutes.journalNew,
                              extra: entry,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _openSettings(JournalStrings js) {
    final lock = ref.read(journalLockProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.lock_outline),
              title: Text(js.enableLock),
              value: lock.isEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: (v) async {
                Navigator.pop(context);
                if (v) {
                  // Go set a PIN (setup mode).
                  context.push(AppRoutes.journalLock, extra: true);
                } else {
                  await ref.read(journalLockProvider.notifier).disableLock();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_toggle_off),
              title: Text(js.timeCapsule),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.journalCapsule);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(js.insights),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.journalInsights);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final JournalStrings js;
  const _EmptyState({required this.js});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing3xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 72,
              color: AppColors.journalAccent.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            Text(
              js.privateSpace,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              js.privateSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppTheme.spacing3xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                ),
                icon: Icon(
                  Icons.add,
                  color: isDark ? Colors.black : Colors.white,
                ),
                label: Text(
                  js.newEntry,
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => context.push(AppRoutes.journalNew),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
