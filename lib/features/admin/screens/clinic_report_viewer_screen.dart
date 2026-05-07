import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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
                  final label = locale.isNotEmpty
                      ? '$dateStr [$locale]'
                      : dateStr;
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
        child: MarkdownBody(
          data: markdown,
          styleSheet: styleSheet,
          selectable: true,
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
