import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../routes/app_routes.dart';

// ─── Pure-Dart Helpers (top-level so they are unit-testable) ────────────────

/// Risk level → sort rank (higher = shown first).
int riskRank(String level) {
  switch (level.toLowerCase()) {
    case 'critical':
      return 4;
    case 'high':
      return 3;
    case 'moderate':
      return 2;
    case 'low':
      return 1;
    default:
      return 0;
  }
}

/// Trend → sort rank (higher = shown first).
int trendRank(String trend) {
  switch (trend.toLowerCase()) {
    case 'declining':
      return 2;
    case 'stable':
      return 1;
    case 'improving':
      return 0;
    default:
      return 0;
  }
}

/// Compare two user maps for table sort order:
/// primary: riskLevel desc, secondary: trend desc.
int compareUsers(Map<String, dynamic> a, Map<String, dynamic> b) {
  final riskA = riskRank(a['riskLevel'] as String? ?? '');
  final riskB = riskRank(b['riskLevel'] as String? ?? '');
  if (riskA != riskB) return riskB - riskA; // desc
  final trendA = trendRank(a['trend'] as String? ?? '');
  final trendB = trendRank(b['trend'] as String? ?? '');
  return trendB - trendA; // desc
}

/// Human-readable relative time from a [DateTime].
String relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  final days = diff.inDays;
  return days == 1 ? '1 day ago' : '$days days ago';
}

// ─── Mood/Trend display helpers ─────────────────────────────────────────────

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

IconData _trendIcon(String trend) {
  switch (trend.toLowerCase()) {
    case 'declining':
      return Icons.trending_down_rounded;
    case 'improving':
      return Icons.trending_up_rounded;
    default:
      return Icons.trending_flat_rounded;
  }
}

Color _trendColor(String trend) {
  switch (trend.toLowerCase()) {
    case 'declining':
      return AppColors.riskCritical;
    case 'improving':
      return AppColors.success;
    default:
      return AppColors.warning;
  }
}

Color _riskColor(String level) {
  switch (level.toLowerCase()) {
    case 'critical':
      return AppColors.riskCritical;
    case 'high':
      return AppColors.riskHigh;
    case 'moderate':
      return AppColors.riskModerate;
    case 'low':
      return AppColors.riskLow;
    default:
      return AppColors.textMuted;
  }
}

// ─── Filter options ──────────────────────────────────────────────────────────

const _filterOptions = ['All', 'Low', 'Moderate', 'High', 'Critical'];

// ─── Screen ─────────────────────────────────────────────────────────────────

class AiAnalyticsScreen extends ConsumerStatefulWidget {
  const AiAnalyticsScreen({super.key});

  @override
  ConsumerState<AiAnalyticsScreen> createState() => _AiAnalyticsScreenState();
}

class _AiAnalyticsScreenState extends ConsumerState<AiAnalyticsScreen> {
  // State
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _allUsers = [];
  Map<String, dynamic>? _summary;
  String? _nextCursor;
  String _activeFilter = 'All';
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // ─── Data Fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchUsers({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('analyzeAllUsers');

      final payload = <String, dynamic>{'pageSize': 200};
      if (loadMore && _nextCursor != null) {
        payload['cursor'] = _nextCursor;
      }

      final result = await callable.call(payload);
      final raw = result.data;
      final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

      final incoming = (data['users'] as List<dynamic>? ?? [])
          .map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .toList();

      // Sort incoming by risk desc, then trend desc
      incoming.sort(compareUsers);

      setState(() {
        if (loadMore) {
          _allUsers.addAll(incoming);
          _allUsers.sort(compareUsers); // re-sort merged list
        } else {
          _allUsers = incoming;
        }
        _summary = data['summary'] != null
            ? Map<String, dynamic>.from(data['summary'] as Map)
            : null;
        _nextCursor = data['nextCursor'] as String?;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  // ─── Filtered view ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredUsers {
    if (_activeFilter == 'All') return _allUsers;
    return _allUsers
        .where((u) =>
            (u['riskLevel'] as String? ?? '').toLowerCase() ==
            _activeFilter.toLowerCase())
        .toList();
  }

  // ─── Generate report for a single user ─────────────────────────────────────

  Future<void> _generateReport(
    BuildContext ctx,
    String userId,
  ) async {
    final s = ref.read(stringsProvider);
    final locale = ref.read(languageProvider).locale.languageCode;

    if (!ctx.mounted) return;

    showModalBottomSheet<void>(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                s.reportGenerating,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('generateUserReport');
      await callable.call({'userId': userId, 'locale': locale});

      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      ctx.push('${AppRoutes.adminPatientReports}?userId=$userId');
    } catch (e) {
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop();
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Failed to generate report: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.adminTextPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.adminTextSecondary : AppColors.textSecondary;
    final cardBg = isDark ? AppColors.adminGlass : Colors.white;
    final borderColor =
        isDark ? AppColors.adminBorder : AppColors.borderLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? _buildError(context, s, textPrimary)
              : _buildContent(
                  context,
                  s,
                  isDark,
                  textPrimary,
                  textSecondary,
                  cardBg,
                  borderColor,
                ),
    );
  }

  Widget _buildError(BuildContext context, dynamic s, Color textPrimary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Error',
            textAlign: TextAlign.center,
            style: TextStyle(color: textPrimary),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(s.retry ?? 'Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic s,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader(context, s, isDark, textPrimary),
          ),

          // ── Summary Cards ────────────────────────────────────────────────────
          if (_summary != null)
            SliverToBoxAdapter(
              child: _buildSummaryCards(
                  context, s, isDark, textPrimary, textSecondary, cardBg, borderColor),
            ),

          // ── Filter Chips ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildFilterRow(context, s, isDark, textSecondary),
          ),

          // ── Table ─────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildTable(
                context, s, isDark, textPrimary, textSecondary, cardBg, borderColor),
          ),

          // ── Load more ─────────────────────────────────────────────────────────
          if (_nextCursor != null)
            SliverToBoxAdapter(
              child: _buildLoadMoreButton(context, s),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, dynamic s, bool isDark, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.aiAnalytics,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.analyzeAll,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ── Summary Cards ────────────────────────────────────────────────────────────

  Widget _buildSummaryCards(
    BuildContext context,
    dynamic s,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    final byRisk = _summary?['byRisk'] as Map? ?? {};
    final high = (byRisk['high'] as num? ?? 0).toInt();
    final critical = (byRisk['critical'] as num? ?? 0).toInt();
    final total = (_summary?['total'] as num? ?? 0).toInt();
    final active7d = (_summary?['activeLoggers7d'] as num? ?? 0).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total Users',
              value: total.toString(),
              icon: Icons.people_rounded,
              color: AppColors.primary,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: s.highRiskCount,
              value: (high + critical).toString(),
              icon: Icons.warning_amber_rounded,
              color: AppColors.riskHigh,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: s.activeLoggers7d,
              value: active7d.toString(),
              icon: Icons.show_chart_rounded,
              color: AppColors.success,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: s.criticalRiskCount,
              value: critical.toString(),
              icon: Icons.crisis_alert_rounded,
              color: AppColors.riskCritical,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              hasCriticalBorder: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chips ─────────────────────────────────────────────────────────────

  Widget _buildFilterRow(
      BuildContext context, dynamic s, bool isDark, Color textSecondary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: _filterOptions.map((filter) {
          final isActive = _activeFilter == filter;
          Color chipColor;
          switch (filter) {
            case 'Low':
              chipColor = AppColors.riskLow;
              break;
            case 'Moderate':
              chipColor = AppColors.riskModerate;
              break;
            case 'High':
              chipColor = AppColors.riskHigh;
              break;
            case 'Critical':
              chipColor = AppColors.riskCritical;
              break;
            default:
              chipColor = AppColors.primary;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isActive,
              onSelected: (_) => setState(() => _activeFilter = filter),
              selectedColor: chipColor.withValues(alpha: 0.2),
              checkmarkColor: chipColor,
              labelStyle: TextStyle(
                color: isActive ? chipColor : textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              side: BorderSide(
                color: isActive
                    ? chipColor.withValues(alpha: 0.6)
                    : (isDark ? AppColors.adminBorder : AppColors.borderLight),
              ),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────────

  Widget _buildTable(
    BuildContext context,
    dynamic s,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color borderColor,
  ) {
    final users = _filteredUsers;

    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Text(
            'No users match this filter.',
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        clipBehavior: Clip.hardEdge,
        // LayoutBuilder outside the horizontal scroll so constraints.maxWidth
        // is the Container's bounded width, not ∞.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.backgroundLight,
            ),
            dividerThickness: 1,
            dataRowMinHeight: 52,
            dataRowMaxHeight: 68,
            columnSpacing: 20,
            horizontalMargin: 16,
            columns: [
              DataColumn(
                label: Text('Name',
                    style: _headerStyle(isDark, textSecondary)),
              ),
              DataColumn(
                label: Text('Email',
                    style: _headerStyle(isDark, textSecondary)),
              ),
              DataColumn(
                label: Text(_stringOrKey(s, 'lastMood'),
                    style: _headerStyle(isDark, textSecondary)),
              ),
              DataColumn(
                label: Text('Trend', style: _headerStyle(isDark, textSecondary)),
              ),
              DataColumn(
                label: Text('Risk', style: _headerStyle(isDark, textSecondary)),
              ),
              DataColumn(
                label: Text(_stringOrKey(s, 'lastMood') + ' date',
                    style: _headerStyle(isDark, textSecondary)),
              ),
              DataColumn(
                label: Text(_stringOrKey(s, 'totalEntries'),
                    style: _headerStyle(isDark, textSecondary)),
              ),
              DataColumn(
                label: Text('Actions',
                    style: _headerStyle(isDark, textSecondary)),
              ),
            ],
            rows: users.map((user) {
              return _buildRow(
                  context, user, s, isDark, textPrimary, textSecondary);
            }).toList(),
          ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _headerStyle(bool isDark, Color textSecondary) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: textSecondary,
      letterSpacing: 0.5,
    );
  }

  // Safely grab a getter from s, fall back to the key name
  String _stringOrKey(dynamic s, String key) {
    try {
      switch (key) {
        case 'lastMood':
          return s.lastMood as String;
        case 'totalEntries':
          return s.totalEntries as String;
        default:
          return key;
      }
    } catch (_) {
      return key;
    }
  }

  DataRow _buildRow(
    BuildContext context,
    Map<String, dynamic> user,
    dynamic s,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final userId = user['userId'] as String? ?? '';
    final name = user['name'] as String? ?? '—';
    final email = user['email'] as String? ?? '—';
    final mood = user['dominantMood'] as String? ?? '';
    final trend = user['trend'] as String? ?? 'stable';
    final risk = user['riskLevel'] as String? ?? 'low';
    final totalEntries = user['totalMoodEntries'] as int? ?? 0;

    final lastMoodTs = user['lastMoodAt'];
    String lastMoodStr = '—';
    if (lastMoodTs != null) {
      try {
        final dt = lastMoodTs is num
            ? DateTime.fromMillisecondsSinceEpoch(lastMoodTs.toInt())
            : DateTime.parse(lastMoodTs as String);
        lastMoodStr = relativeTime(dt);
      } catch (_) {
        lastMoodStr = '—';
      }
    }

    final riskColor = _riskColor(risk);

    return DataRow(
      cells: [
        // Name
        DataCell(
          SizedBox(
            width: 120,
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: textPrimary, fontSize: 13),
            ),
          ),
        ),

        // Email
        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ),
        ),

        // Dominant Mood
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_moodEmoji(mood), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                mood.isEmpty ? '—' : _capitalize(mood),
                style: TextStyle(fontSize: 12, color: textPrimary),
              ),
            ],
          ),
        ),

        // Trend
        DataCell(
          Icon(
            _trendIcon(trend),
            color: _trendColor(trend),
            size: 20,
          ),
        ),

        // Risk Level chip
        DataCell(
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: riskColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              _capitalize(risk),
              style: TextStyle(
                color: riskColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ),

        // Last mood date
        DataCell(
          Text(
            lastMoodStr,
            style: TextStyle(color: textSecondary, fontSize: 12),
          ),
        ),

        // Total entries
        DataCell(
          Text(
            totalEntries.toString(),
            style: TextStyle(color: textPrimary, fontSize: 13),
          ),
        ),

        // Actions
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Generate Report
              Tooltip(
                message: s.generateReport,
                child: TextButton.icon(
                  onPressed: () => _generateReport(context, userId),
                  icon: const Icon(Icons.summarize_rounded, size: 16),
                  label: const Text('Report'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                ),
              ),

              // View Profile
              Tooltip(
                message: s.viewProfile,
                child: TextButton.icon(
                  onPressed: () =>
                      context.push('/admin/users/$userId'),
                  icon: const Icon(Icons.person_rounded, size: 16),
                  label: const Text('Profile'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark
                            ? AppColors.adminTextSecondary
                            : AppColors.textSecondary,
                    textStyle: const TextStyle(fontSize: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                  ),
                ),
              ),

              // Overflow menu: Block / Unblock + Delete
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 16),
                tooltip: 'More actions',
                onSelected: (value) {
                  if (value == 'block') {
                    _confirmBlockUser(context, userId, user, s);
                  } else if (value == 'delete') {
                    _confirmDeleteUser(context, userId, user, s);
                  }
                },
                itemBuilder: (_) {
                  final isBlocked =
                      (user['is_blocked'] as bool?) ?? false;
                  return [
                    PopupMenuItem<String>(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(
                            isBlocked
                                ? Icons.lock_open_rounded
                                : Icons.block_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isBlocked ? s.unblockUser : s.blockUser,
                            style:
                                TextStyle(color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_forever_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.deleteUser,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Block / Unblock user ─────────────────────────────────────────────────────

  Future<void> _confirmBlockUser(
    BuildContext ctx,
    String userId,
    Map<String, dynamic> user,
    dynamic s,
  ) async {
    final isBlocked = (user['is_blocked'] as bool?) ?? false;
    final confirmText =
        isBlocked ? s.unblockUserConfirm as String : s.blockUserConfirm as String;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isBlocked ? s.unblockUser as String : s.blockUser as String),
        content: Text(confirmText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(s.cancel as String),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: Text(
                isBlocked ? s.unblockUser as String : s.blockUser as String),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('setUserBlocked');
      await callable.call({'userId': userId, 'blocked': !isBlocked});

      if (!mounted) return;
      // Update local state
      setState(() {
        final idx = _allUsers.indexWhere((u) => u['userId'] == userId);
        if (idx != -1) {
          _allUsers[idx] = Map<String, dynamic>.from(_allUsers[idx])
            ..['is_blocked'] = !isBlocked;
        }
      });
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
              isBlocked ? s.userUnblocked as String : s.userBlocked as String),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Delete user ──────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteUser(
    BuildContext ctx,
    String userId,
    Map<String, dynamic> user,
    dynamic s,
  ) async {
    bool understood = false;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(s.deleteUser as String),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.deleteUserConfirm as String),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: understood,
                    activeColor: AppColors.error,
                    onChanged: (v) =>
                        setDialogState(() => understood = v ?? false),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.iUnderstand as String)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: Text(s.cancel as String),
            ),
            ElevatedButton(
              onPressed: understood
                  ? () => Navigator.of(dialogCtx).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(s.deleteUser as String),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    // Show progress sheet
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: ctx,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.error),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                s.deleting as String,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('deleteUserAccount');
      await callable.call({'userId': userId});

      if (!mounted) return;
      Navigator.of(ctx).pop(); // dismiss progress sheet

      // Remove from local state
      setState(() {
        _allUsers.removeWhere((u) => u['userId'] == userId);
      });

      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(s.userDeleted as String),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(ctx).pop(); // dismiss progress sheet
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ── Load more ─────────────────────────────────────────────────────────────────

  Widget _buildLoadMoreButton(BuildContext context, dynamic s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: _loadingMore
            ? const CircularProgressIndicator(color: AppColors.primary)
            : OutlinedButton.icon(
                onPressed: () => _fetchUsers(loadMore: true),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(s.loadMore),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Stat Card Widget ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool hasCriticalBorder;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    this.hasCriticalBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCriticalBorder
              ? AppColors.riskCritical.withValues(alpha: 0.5)
              : borderColor,
          width: hasCriticalBorder ? 1.5 : 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
