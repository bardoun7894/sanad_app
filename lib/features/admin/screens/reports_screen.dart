import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = AdminResponsive.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: AdminResponsive.pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.adminReports,
                  style: TextStyle(
                    fontSize: isMobile ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.adminReportsSubtitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  AppStrings.adminReportTemplates,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900
                        ? 3
                        : (constraints.maxWidth > 640 ? 2 : 1);
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _ReportCard(
                          title: AppStrings.adminMonthlySummary,
                          description: AppStrings.adminMonthlySummaryDesc,
                          icon: Icons.summarize_rounded,
                          color: AppColors.primary,
                          isDark: isDark,
                          onGenerate: () => _generateMonthlySummary(),
                        ),
                        _ReportCard(
                          title: AppStrings.adminPatientActivity,
                          description: AppStrings.adminPatientActivityDesc,
                          icon: Icons.people_alt_rounded,
                          color: AppColors.statusInfo,
                          isDark: isDark,
                          onGenerate: () => _generatePatientActivity(),
                        ),
                        _ReportCard(
                          title: AppStrings.adminClinicianReport,
                          description: AppStrings.adminClinicianReportDesc,
                          icon: Icons.medical_services_rounded,
                          color: AppColors.statusSuccess,
                          isDark: isDark,
                          onGenerate: () => _generateClinicianReport(),
                        ),
                        _ReportCard(
                          title: AppStrings.adminFinancialReport,
                          description: AppStrings.adminFinancialReportDesc,
                          icon: Icons.payments_rounded,
                          color: AppColors.statusWarning,
                          isDark: isDark,
                          onGenerate: () => _generateFinancialReport(),
                        ),
                        _ReportCard(
                          title: AppStrings.adminRiskAssessment,
                          description: AppStrings.adminRiskAssessmentDesc,
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.statusDanger,
                          isDark: isDark,
                          onGenerate: () => _generateRiskReport(),
                        ),
                        _ReportCard(
                          title: AppStrings.adminCustomReport,
                          description: AppStrings.adminCustomReportDesc,
                          icon: Icons.tune_rounded,
                          color: AppColors.statusPending,
                          isDark: isDark,
                          onGenerate: () => _showCustomReportDialog(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  AppStrings.adminRecentReports,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _RecentReportsList(isDark: isDark),
              ],
            ),
          ),
          if (_generating)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text('Generating report…'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generateMonthlySummary() async {
    setState(() => _generating = true);
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthStartTs = Timestamp.fromDate(monthStart);

      final results = await Future.wait([
        _firestore
            .collection('users')
            .where('created_at', isGreaterThanOrEqualTo: monthStartTs)
            .count()
            .get(),
        _firestore
            .collection('bookings')
            .where('created_at', isGreaterThanOrEqualTo: monthStartTs)
            .count()
            .get(),
        _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'completed')
            .where('created_at', isGreaterThanOrEqualTo: monthStartTs)
            .count()
            .get(),
        _firestore
            .collection('mood_entries')
            .where('created_at', isGreaterThanOrEqualTo: monthStartTs)
            .count()
            .get(),
      ]);

      final newUsers = results[0].count ?? 0;
      final bookings = results[1].count ?? 0;
      final completed = results[2].count ?? 0;
      final moods = results[3].count ?? 0;

      final month = _monthName(now.month);
      if (!mounted) return;
      _showReportDialog(
        title: 'Monthly Summary — $month ${now.year}',
        rows: [
          ['Metric', 'Value'],
          ['New Users', '$newUsers'],
          ['Total Bookings', '$bookings'],
          ['Completed Sessions', '$completed'],
          ['Mood Entries Logged', '$moods'],
          [
            'Session Completion Rate',
            bookings > 0 ? '${(completed / bookings * 100).toStringAsFixed(1)}%' : 'N/A'
          ],
        ],
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generatePatientActivity() async {
    setState(() => _generating = true);
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthStartTs = Timestamp.fromDate(monthStart);

      final results = await Future.wait([
        _firestore.collection('users').count().get(),
        _firestore
            .collection('users')
            .where('is_premium', isEqualTo: true)
            .count()
            .get(),
        _firestore
            .collection('mood_entries')
            .where('created_at', isGreaterThanOrEqualTo: monthStartTs)
            .count()
            .get(),
        _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'completed')
            .count()
            .get(),
      ]);

      final total = results[0].count ?? 0;
      final premium = results[1].count ?? 0;
      final moods = results[2].count ?? 0;
      final sessions = results[3].count ?? 0;

      if (!mounted) return;
      _showReportDialog(
        title: 'Patient Activity Report',
        rows: [
          ['Metric', 'Value'],
          ['Total Patients', '$total'],
          ['Premium Subscribers', '$premium'],
          ['Free Users', '${total - premium}'],
          ['Mood Entries This Month', '$moods'],
          ['Total Completed Sessions', '$sessions'],
        ],
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generateClinicianReport() async {
    setState(() => _generating = true);
    try {
      final results = await Future.wait([
        _firestore.collection('therapists').count().get(),
        _firestore
            .collection('therapists')
            .where('is_approved', isEqualTo: true)
            .count()
            .get(),
        _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'completed')
            .count()
            .get(),
        _firestore
            .collection('bookings')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
      ]);

      final total = results[0].count ?? 0;
      final approved = results[1].count ?? 0;
      final completed = results[2].count ?? 0;
      final pending = results[3].count ?? 0;

      if (!mounted) return;
      _showReportDialog(
        title: 'Clinician Report',
        rows: [
          ['Metric', 'Value'],
          ['Total Therapists', '$total'],
          ['Approved Therapists', '$approved'],
          ['Pending Approval', '${total - approved}'],
          ['Completed Sessions (all time)', '$completed'],
          ['Pending Bookings', '$pending'],
        ],
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generateFinancialReport() async {
    setState(() => _generating = true);
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthStartTs = Timestamp.fromDate(monthStart);

      final results = await Future.wait([
        _firestore
            .collection('payment_verifications')
            .where('status', isEqualTo: 'approved')
            .count()
            .get(),
        _firestore
            .collection('payment_verifications')
            .where('status', isEqualTo: 'approved')
            .where('submitted_at', isGreaterThanOrEqualTo: monthStartTs)
            .count()
            .get(),
        _firestore
            .collection('users')
            .where('is_premium', isEqualTo: true)
            .count()
            .get(),
      ]);

      final totalApproved = results[0].count ?? 0;
      final thisMonth = results[1].count ?? 0;
      final activeSubs = results[2].count ?? 0;
      final month = _monthName(now.month);

      if (!mounted) return;
      _showReportDialog(
        title: 'Financial Report — $month ${now.year}',
        rows: [
          ['Metric', 'Value'],
          ['Active Subscriptions', '$activeSubs'],
          ['Payments Approved (this month)', '$thisMonth'],
          ['Total Payments Approved (all time)', '$totalApproved'],
        ],
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _generateRiskReport() async {
    setState(() => _generating = true);
    try {
      final crisisSnap = await _firestore
          .collection('crisis_alerts')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      final totalAlerts = crisisSnap.docs.length;
      final resolved = crisisSnap.docs
          .where((d) => (d.data()['resolved'] ?? false) == true)
          .length;
      final unresolved = totalAlerts - resolved;

      if (!mounted) return;
      _showReportDialog(
        title: 'Risk Assessment Report',
        rows: [
          ['Metric', 'Value'],
          ['Total Crisis Alerts (recent 50)', '$totalAlerts'],
          ['Resolved', '$resolved'],
          ['Unresolved / Active', '$unresolved'],
        ],
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showReportDialog({
    required String title,
    required List<List<String>> rows,
  }) {
    final csvLines = rows.map((r) => r.join(', ')).join('\n');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < rows.length; i++)
                  Container(
                    color: i == 0
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : (i.isEven
                            ? Colors.transparent
                            : Colors.black.withValues(alpha: 0.03)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(rows[i][0],
                                style: TextStyle(
                                    fontWeight: i == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal))),
                        Text(rows[i][1],
                            style: TextStyle(
                                fontWeight: i == 0
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: i == 0
                                    ? AppColors.primary
                                    : null)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvLines));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard as CSV')),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy CSV'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCustomReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.adminCustomReport),
        content: const Text(AppStrings.adminCustomReportComingSoon),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error generating report: $e'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onGenerate;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark
                      ? AppColors.adminTextSecondary
                      : AppColors.textSecondary,
                ),
                onPressed: () {},
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.adminTextSecondary
                  : AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                elevation: 0,
              ),
              child: const Text(AppStrings.adminGenerate),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentReportsList extends StatelessWidget {
  final bool isDark;

  const _RecentReportsList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final recentReports = [
      {
        'name': 'Monthly Summary — Current Month',
        'type': 'Monthly Summary',
        'date': DateTime.now().subtract(const Duration(hours: 1)),
        'format': 'CSV',
      },
      {
        'name': 'Clinician Performance Report',
        'type': 'Clinician Report',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'format': 'CSV',
      },
      {
        'name': 'Patient Activity Report',
        'type': 'Patient Activity',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'format': 'CSV',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.adminGlass.withValues(alpha: 0.3)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentReports.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.adminBorder : AppColors.borderLight,
        ),
        itemBuilder: (context, index) {
          final report = recentReports[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.table_chart_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              report['name'] as String,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '${report['type']} • ${_formatDate(report['date'] as DateTime)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.adminTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.visibility_rounded,
                    color: isDark
                        ? AppColors.adminTextSecondary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {},
                  tooltip: AppStrings.adminView,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 1) return 'Just now';
    if (diff.inDays == 0) return AppStrings.adminToday;
    if (diff.inDays == 1) return AppStrings.adminYesterday;
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
