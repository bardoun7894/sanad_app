import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = false;
    final isMobile = AdminResponsive.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: AdminResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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

            // Report Templates Grid
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
                      description:
                          AppStrings.adminMonthlySummaryDesc,
                      icon: Icons.summarize_rounded,
                      color: AppColors.primary,
                      isDark: isDark,
                      onGenerate: () =>
                          _generateReport(context, 'Monthly Summary'),
                    ),
                    _ReportCard(
                      title: AppStrings.adminPatientActivity,
                      description: AppStrings.adminPatientActivityDesc,
                      icon: Icons.people_alt_rounded,
                      color: AppColors.statusInfo,
                      isDark: isDark,
                      onGenerate: () =>
                          _generateReport(context, 'Patient Activity'),
                    ),
                    _ReportCard(
                      title: AppStrings.adminClinicianReport,
                      description:
                          AppStrings.adminClinicianReportDesc,
                      icon: Icons.medical_services_rounded,
                      color: AppColors.statusSuccess,
                      isDark: isDark,
                      onGenerate: () =>
                          _generateReport(context, 'Clinician Report'),
                    ),
                    _ReportCard(
                      title: AppStrings.adminFinancialReport,
                      description: AppStrings.adminFinancialReportDesc,
                      icon: Icons.payments_rounded,
                      color: AppColors.statusWarning,
                      isDark: isDark,
                      onGenerate: () =>
                          _generateReport(context, 'Financial Report'),
                    ),
                    _ReportCard(
                      title: AppStrings.adminRiskAssessment,
                      description: AppStrings.adminRiskAssessmentDesc,
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.statusDanger,
                      isDark: isDark,
                      onGenerate: () =>
                          _generateReport(context, 'Risk Assessment'),
                    ),
                    _ReportCard(
                      title: AppStrings.adminCustomReport,
                      description:
                          AppStrings.adminCustomReportDesc,
                      icon: Icons.tune_rounded,
                      color: AppColors.statusPending,
                      isDark: isDark,
                      onGenerate: () => _showCustomReportDialog(context),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Recent Reports
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
    );
  }

  void _generateReport(BuildContext context, String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $reportName...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showCustomReportDialog(BuildContext context) {
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
        'name': 'Monthly Summary - December 2024',
        'type': 'Monthly Summary',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'format': 'PDF',
      },
      {
        'name': 'Clinician Performance Report',
        'type': 'Clinician Report',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'format': 'PDF',
      },
      {
        'name': 'Q4 Financial Report',
        'type': 'Financial Report',
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
              child: Icon(
                report['format'] == 'PDF'
                    ? Icons.picture_as_pdf_rounded
                    : Icons.table_chart_rounded,
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
                    Icons.download_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () {},
                  tooltip: AppStrings.adminDownload,
                ),
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
    if (diff.inDays == 0) return AppStrings.adminToday;
    if (diff.inDays == 1) return AppStrings.adminYesterday;
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
