import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../routes/app_routes.dart';

// ── Mood helper constants ──────────────────────────────────────────────────

const _kMoodEmojis = {
  0: '😊', // happy
  1: '😌', // calm
  2: '😰', // anxious
  3: '😢', // sad
  4: '😠', // angry
  5: '😴', // tired
};

Color _moodColorFromInt(int? moodInt) {
  switch (moodInt) {
    case 0:
      return AppColors.success;
    case 1:
      return const Color(0xFF6EC6CA);
    case 2:
      return AppColors.warning;
    case 3:
      return const Color(0xFF90A4AE);
    case 4:
      return AppColors.error;
    case 5:
      return const Color(0xFFB39DDB);
    default:
      return AppColors.borderLight;
  }
}

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late final Future<Map<String, dynamic>> _patternsFuture;

  @override
  void initState() {
    super.initState();
    _patternsFuture = _fetchPatterns();
  }

  Future<Map<String, dynamic>> _fetchPatterns() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) throw Exception('Not authenticated');
    final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('analyzeUserPatterns');
    final result = await callable.call({'userId': uid});
    final data = result.data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          s.myInsights,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _patternsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return _buildError(s, isDark);
          }
          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return _buildEmpty(s, isDark);
          }
          return _buildContent(s, isDark, data);
        },
      ),
    );
  }

  Widget _buildError(dynamic s, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              s.error as String,
              style: AppTypography.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _patternsFuture = _fetchPatterns();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.retry as String),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(dynamic s, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              s.noPatternsYet as String,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white54 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(dynamic s, bool isDark, Map<String, dynamic> data) {
    final trend = data['trend'] as String? ?? 'stable';
    final dominantMood = data['dominantMood'] as String? ?? '';
    final lowStreak = (data['lowStreak'] as num?)?.toInt() ?? 0;
    final noteThemes = (data['noteThemes'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Extended pattern fields
    final timeOfDayRaw = _safeCastMap(data['timeOfDay']);
    final dayOfWeekRaw = _safeCastMap(data['dayOfWeek']);
    final loggingGap = (data['loggingGap'] as num?)?.toInt() ?? 0;
    final noteSentimentRaw = _safeCastMap(data['noteSentiment']);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dominant mood card
          if (dominantMood.isNotEmpty)
            _InsightCard(
              isDark: isDark,
              child: Row(
                children: [
                  Text(
                    _moodEmoji(dominantMood),
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your dominant mood this month',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.adminTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _moodLabel(dominantMood),
                          style: AppTypography.headingSmall.copyWith(
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Trend card
          _InsightCard(
            isDark: isDark,
            child: Row(
              children: [
                Icon(
                  _trendIcon(trend),
                  color: _trendColor(trend),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trend',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.adminTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _trendLabel(trend, s),
                        style: AppTypography.headingSmall.copyWith(
                          color: _trendColor(trend),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Low-streak warning card
          if (lowStreak >= 3) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We noticed several low days lately — consider talking to a therapist.',
                          style: AppTypography.bodyMedium.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => context.push(AppRoutes.therapists),
                          child: const Text('Talk to a therapist'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Note themes chips
          if (noteThemes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Topics from your notes',
              style: AppTypography.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: noteThemes
                  .map(
                    (theme) => Chip(
                      label: Text(
                        theme,
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      backgroundColor: isDark
                          ? AppColors.adminGlass
                          : AppColors.borderLight,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],

          // ── Extended pattern sections ──────────────────────────────────

          // Time of day
          if (timeOfDayRaw != null) ...[
            const SizedBox(height: 24),
            _SectionHeader(label: s.timeOfDay as String, isDark: isDark),
            const SizedBox(height: 8),
            _InsightCard(
              isDark: isDark,
              child: _TimeOfDayBars(data: timeOfDayRaw, s: s, isDark: isDark),
            ),
          ],

          // Day of week heatmap
          if (dayOfWeekRaw != null) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: s.dayOfWeek as String, isDark: isDark),
            const SizedBox(height: 8),
            _InsightCard(
              isDark: isDark,
              child: _DayOfWeekHeatmap(data: dayOfWeekRaw, isDark: isDark),
            ),
          ],

          // Logging gap warning
          if (loggingGap > 5) ...[
            const SizedBox(height: 16),
            _LoggingGapWarning(
              loggingGap: loggingGap,
              s: s,
              isDark: isDark,
              onLogMood: () => context.push(AppRoutes.moodTracker),
            ),
          ],

          // Note sentiment
          if (noteSentimentRaw != null) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: s.noteSentiment as String, isDark: isDark),
            const SizedBox(height: 8),
            _InsightCard(
              isDark: isDark,
              child: _NoteSentimentBars(
                data: noteSentimentRaw,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Safely cast a dynamic value to Map<String, dynamic>? without runtime type errors.
  /// Firebase Functions returns `_Map<Object?, Object?>` which can't be cast directly.
  Map<String, dynamic>? _safeCastMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'calm':
        return '😌';
      case 'anxious':
        return '😰';
      case 'sad':
        return '😢';
      case 'angry':
        return '😠';
      case 'tired':
        return '😴';
      default:
        return '😐';
    }
  }

  String _moodLabel(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return 'Happy';
      case 'calm':
        return 'Calm';
      case 'anxious':
        return 'Anxious';
      case 'sad':
        return 'Sad';
      case 'angry':
        return 'Angry';
      case 'tired':
        return 'Tired';
      default:
        return mood;
    }
  }

  String _trendLabel(String trend, dynamic s) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return s.trendImproving as String;
      case 'declining':
        return s.trendDeclining as String;
      default:
        return s.trendStable as String;
    }
  }

  IconData _trendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up_rounded;
      case 'declining':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color _trendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return AppColors.success;
      case 'declining':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }
}

// ---------------------------------------------------------------------------
// _SectionHeader — consistent section title used by extended sections
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.headingSmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TimeOfDayBars — 4 horizontal mini-bars for morning/afternoon/evening/night
// ---------------------------------------------------------------------------
class _TimeOfDayBars extends StatelessWidget {
  const _TimeOfDayBars({
    required this.data,
    required this.s,
    required this.isDark,
  });

  final Map<String, dynamic> data;
  final dynamic s;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final slots = [
      (s.morning as String, data['morning']),
      (s.afternoon as String, data['afternoon']),
      (s.evening as String, data['evening']),
      (s.night as String, data['night']),
    ];

    final maxVal = slots
        .map((e) => (e.$2 as num?)?.toDouble() ?? 0.0)
        .fold<double>(0.0, (a, b) => a > b ? a : b);

    return Column(
      children: slots.map((slot) {
        final label = slot.$1;
        final val = (slot.$2 as num?)?.toInt();
        final frac = (maxVal > 0 && val != null) ? val / maxVal : 0.0;
        final emoji = _kMoodEmojis[val] ?? '—';
        final barColor = _moodColorFromInt(val);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                val != null ? emoji : '—',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// _DayOfWeekHeatmap — 7 colored dots Mon–Sun
// ---------------------------------------------------------------------------
class _DayOfWeekHeatmap extends StatelessWidget {
  const _DayOfWeekHeatmap({required this.data, required this.isDark});

  final Map<String, dynamic> data;
  final bool isDark;

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(_dayKeys.length, (i) {
        final val = (data[_dayKeys[i]] as num?)?.toInt();
        final color = _moodColorFromInt(val);
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: val != null
                    ? color.withValues(alpha: 0.85)
                    : (isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
                shape: BoxShape.circle,
              ),
              child: val != null
                  ? Center(
                      child: Text(
                        _kMoodEmojis[val] ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _dayLabels[i],
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// _LoggingGapWarning — soft warning when loggingGap > 5
// ---------------------------------------------------------------------------
class _LoggingGapWarning extends StatelessWidget {
  const _LoggingGapWarning({
    required this.loggingGap,
    required this.s,
    required this.isDark,
    required this.onLogMood,
  });

  final int loggingGap;
  final dynamic s;
  final bool isDark;
  final VoidCallback onLogMood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$loggingGap ${s.days as String} — ${(s.loggingGap as String).toLowerCase()} — '
                  'daily logging unlocks better insights.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onLogMood,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  child: const Text('Log mood'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NoteSentimentBars — two horizontal bars: positive vs negative
// ---------------------------------------------------------------------------
class _NoteSentimentBars extends StatelessWidget {
  const _NoteSentimentBars({required this.data, required this.isDark});

  final Map<String, dynamic> data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final positive = (data['positive'] as num?)?.toInt() ?? 0;
    final negative = (data['negative'] as num?)?.toInt() ?? 0;
    final total = positive + negative;
    final posFrac = total > 0 ? positive / total : 0.0;
    final negFrac = total > 0 ? negative / total : 0.0;

    return Column(
      children: [
        _SentimentRow(
          label: '😊',
          fraction: posFrac.clamp(0.0, 1.0),
          color: AppColors.success,
          count: positive,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _SentimentRow(
          label: '😢',
          fraction: negFrac.clamp(0.0, 1.0),
          color: AppColors.error,
          count: negative,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _SentimentRow extends StatelessWidget {
  const _SentimentRow({
    required this.label,
    required this.fraction,
    required this.color,
    required this.count,
    required this.isDark,
  });

  final String label;
  final double fraction;
  final Color color;
  final int count;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _InsightCard — shared card wrapper
// ---------------------------------------------------------------------------
class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}
