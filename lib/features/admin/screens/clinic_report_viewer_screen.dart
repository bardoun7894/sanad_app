import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../utils/report_pdf.dart';

class ClinicReportViewerScreen extends ConsumerStatefulWidget {
  final String userId;

  const ClinicReportViewerScreen({super.key, required this.userId});

  @override
  ConsumerState<ClinicReportViewerScreen> createState() =>
      _ClinicReportViewerScreenState();
}

class _ClinicReportViewerScreenState
    extends ConsumerState<ClinicReportViewerScreen> {
  String? _selectedReportId;
  bool _exporting = false;

  Future<void> _exportPdf(Map<String, dynamic> data) async {
    final s = ref.read(stringsProvider);
    final markdown = data['markdown'] as String? ?? '';
    if (markdown.isEmpty || _exporting) return;
    setState(() => _exporting = true);
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      final u = userSnap.data() ?? const <String, dynamic>{};
      final first = (u['first_name'] as String? ?? '').trim();
      final last = (u['last_name'] as String? ?? '').trim();
      final joined = '$first $last'.trim();
      final name = joined.isNotEmpty
          ? joined
          : (u['name'] as String? ?? u['display_name'] as String? ?? '');
      final locale = data['locale'] as String? ?? 'ar';
      final bytes = await ReportPdf.build(
        markdown: markdown,
        locale: locale,
        patientName: name,
        nameLabel: s.reportPatientName,
      );
      final start = data['startDate'] as String?;
      final end = data['endDate'] as String?;
      final period = (start != null && end != null) ? '_${start}_$end' : '';
      await Printing.sharePdf(bytes: bytes, filename: 'sanad_report$period.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.reportPdfFailed}: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.adminSurface : Colors.grey.shade50,
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get(),
          builder: (context, snap) {
            String title = 'Patient Report';
            if (snap.hasData && snap.data!.exists) {
              final data = snap.data!.data() as Map<String, dynamic>;
              title = data['name'] ??
                  data['display_name'] ??
                  'Patient Report';
            }
            return Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            );
          },
        ),
        backgroundColor: isDark ? AppColors.adminSurface : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('reports')
            .orderBy('generatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading reports: ${snapshot.error}',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState(s, isDark);
          }

          // Auto-select the first report if none selected yet
          final activeId = _selectedReportId ?? docs.first.id;
          final activeDoc = docs.firstWhere(
            (d) => d.id == activeId,
            orElse: () => docs.first,
          );
          final activeData = activeDoc.data() as Map<String, dynamic>;

          return Column(
            children: [
              // Report selector bar
              _buildSelectorBar(isDark, s, docs, activeId),

              // Report content
              Expanded(
                child: _buildReportContent(isDark, activeData),
              ),

              // Footer metadata
              _buildFooter(isDark, activeData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(dynamic s, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: isDark ? Colors.white38 : Colors.black26,
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

  Widget _buildSelectorBar(
    bool isDark,
    dynamic s,
    List<QueryDocumentSnapshot> docs,
    String activeId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminGlass : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: activeId,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.adminGlass : Colors.white,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: isDark ? Colors.white54 : AppColors.textSecondary,
                ),
                items: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = data['generatedAt'] as Timestamp?;
                  final dateStr = ts != null
                      ? DateFormat('MMM d, yyyy – HH:mm').format(ts.toDate())
                      : 'Unknown date';
                  final locale = data['locale'] as String? ?? '';
                  final start = data['startDate'] as String?;
                  final end = data['endDate'] as String?;
                  final period =
                      (start != null && end != null) ? '  ($start → $end)' : '';
                  final label = locale.isNotEmpty
                      ? '$dateStr [$locale]$period'
                      : '$dateStr$period';
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    setState(() => _selectedReportId = id);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Download as PDF
          _exporting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  color: AppColors.primary,
                  tooltip: s.reportDownloadPdf as String,
                  onPressed: () {
                    final selectedDoc = docs.firstWhere(
                      (d) => d.id == activeId,
                      orElse: () => docs.first,
                    );
                    _exportPdf(selectedDoc.data() as Map<String, dynamic>);
                  },
                ),
          // Copy to clipboard button
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            tooltip: 'Copy to clipboard',
            onPressed: () {
              final selectedDoc = docs.firstWhere(
                (d) => d.id == activeId,
                orElse: () => docs.first,
              );
              final markdown = (selectedDoc.data()
                      as Map<String, dynamic>)['markdown'] as String? ??
                  '';
              Clipboard.setData(ClipboardData(text: markdown));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report copied to clipboard')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(bool isDark, Map<String, dynamic> data) {
    final markdown = data['markdown'] as String? ?? '';
    final isRtl = (data['locale'] as String? ?? '') == 'ar';

    if (markdown.isEmpty) {
      return Center(
        child: Text(
          'No content in this report.',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
        ),
      );
    }

    final styleSheet = MarkdownStyleSheet(
      p: AppTypography.bodyMedium.copyWith(
        color: isDark ? Colors.white70 : AppColors.textSecondary,
        height: 1.7,
      ),
      h1: AppTypography.headingLarge.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      h2: AppTypography.headingMedium.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      h3: AppTypography.headingSmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      strong: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      em: AppTypography.bodyMedium.copyWith(
        fontStyle: FontStyle.italic,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      listBullet: AppTypography.bodyMedium.copyWith(
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      blockquote: AppTypography.bodyMedium.copyWith(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
      code: AppTypography.bodyMedium.copyWith(
        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Directionality(
        textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['ai_used'] == false)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ref.read(stringsProvider).reportBasicNoConsentNote,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            MarkdownBody(
              data: markdown,
              styleSheet: styleSheet,
              selectable: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark, Map<String, dynamic> data) {
    final ts = data['generatedAt'] as Timestamp?;
    final dateStr = ts != null
        ? DateFormat('MMM d, yyyy – HH:mm').format(ts.toDate())
        : 'Unknown';
    final model = data['model'] as String? ?? 'Unknown model';
    final tokensUsed = data['tokensUsed'] as int?;

    final footerText = tokensUsed != null
        ? 'Generated $dateStr  •  Model: $model  •  $tokensUsed tokens'
        : 'Generated $dateStr  •  Model: $model';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminGlass : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.adminBorder : AppColors.borderLight,
          ),
        ),
      ),
      child: Text(
        footerText,
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.adminTextSecondary : AppColors.textSecondary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
