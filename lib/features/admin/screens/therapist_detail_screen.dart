import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/skeuomorphic_button.dart';
import '../../therapist_portal/models/therapist_profile.dart';
import '../providers/admin_therapist_provider.dart';
import '../widgets/therapist_form_dialog.dart';
import '../../auth/providers/auth_provider.dart';

class TherapistDetailScreen extends ConsumerStatefulWidget {
  final TherapistProfile therapist;

  const TherapistDetailScreen({super.key, required this.therapist});

  @override
  ConsumerState<TherapistDetailScreen> createState() =>
      _TherapistDetailScreenState();
}

class _TherapistDetailScreenState extends ConsumerState<TherapistDetailScreen> {
  final _rejectionController = TextEditingController();
  bool _isProcessing = false;

  void _handleApprove() async {
    setState(() => _isProcessing = true);
    try {
      final authState = ref.read(authProvider);
      final adminId = authState.user?.uid ?? 'unknown';
      await ref
          .read(adminTherapistProvider.notifier)
          .approveTherapist(widget.therapist.id, adminId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error approving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Reject Therapist'),
          content: TextField(
            controller: _rejectionController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _handleReject(),
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleReject() async {
    final reason = _rejectionController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please provide a reason')));
      return;
    }

    Navigator.pop(context);
    setState(() => _isProcessing = true);
    try {
      final authState = ref.read(authProvider);
      final adminId = authState.user?.uid ?? 'unknown';
      await ref
          .read(adminTherapistProvider.notifier)
          .rejectTherapist(widget.therapist.id, reason, adminId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showBlockUnblockDialog() {
    final isCurrentlyActive = widget.therapist.isActive;
    final action = isCurrentlyActive ? 'Block' : 'Unblock';
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark =
            Theme.of(dialogContext).brightness == Brightness.dark;
        final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
        final primaryText = isDark ? Colors.white : AppColors.textPrimary;
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(
            '$action this therapist?',
            style: TextStyle(color: primaryText),
          ),
          content: Text(
            isCurrentlyActive
                ? 'Blocking will prevent this therapist from accepting new bookings.'
                : 'Unblocking will allow this therapist to accept bookings again.',
            style: TextStyle(color: primaryText.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel',
                  style: TextStyle(color: primaryText.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                action,
                style: TextStyle(
                  color: isCurrentlyActive
                      ? AppColors.error
                      : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed != true) return;
      setState(() => _isProcessing = true);
      try {
        final adminId = ref.read(authProvider).user?.uid ?? 'unknown';
        await ref
            .read(adminTherapistProvider.notifier)
            .setTherapistActive(
              widget.therapist.id,
              !isCurrentlyActive,
              adminId,
            );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    });
  }

  void _showSuspendDialog() => _showStatusActionDialog(
        title: 'Suspend this therapist?',
        body:
            'Suspension is stronger than blocking — the therapist cannot log in '
            'or accept bookings until reactivated.',
        confirmLabel: 'Suspend',
        confirmColor: Colors.orange,
        action: (adminId) => ref
            .read(adminTherapistProvider.notifier)
            .suspendTherapist(widget.therapist.id, adminId),
      );

  void _showReactivateDialog() => _showStatusActionDialog(
        title: 'Reactivate this therapist?',
        body:
            'The therapist will return to approved status and can resume bookings.',
        confirmLabel: 'Reactivate',
        confirmColor: AppColors.success,
        action: (adminId) => ref
            .read(adminTherapistProvider.notifier)
            .reactivateTherapist(widget.therapist.id, adminId),
      );

  void _showStatusActionDialog({
    required String title,
    required String body,
    required String confirmLabel,
    required Color confirmColor,
    required Future<void> Function(String adminId) action,
  }) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final dialogBg = isDark ? AppColors.adminSurface : Colors.white;
        final primaryText = isDark ? Colors.white : AppColors.textPrimary;
        return AlertDialog(
          backgroundColor: dialogBg,
          title: Text(title, style: TextStyle(color: primaryText)),
          content: Text(body,
              style: TextStyle(color: primaryText.withValues(alpha: 0.7))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel',
                  style:
                      TextStyle(color: primaryText.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                confirmLabel,
                style: TextStyle(
                    color: confirmColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed != true) return;
      setState(() => _isProcessing = true);
      try {
        final adminId = ref.read(authProvider).user?.uid ?? 'unknown';
        await action(adminId);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final isMobile = AdminResponsive.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Therapist Detail"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Therapist',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => TherapistFormDialog(
                therapist: widget.therapist,
                onSaved: (updated) {
                  final adminId =
                      ref.read(authProvider).user?.uid ?? '';
                  ref
                      .read(adminTherapistProvider.notifier)
                      .updateTherapist(updated, adminId);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              widget.therapist.isActive
                  ? Icons.block_rounded
                  : Icons.check_circle_outline,
              color: widget.therapist.isActive ? AppColors.error : AppColors.success,
            ),
            tooltip: widget.therapist.isActive
                ? 'Block Therapist'
                : 'Unblock Therapist',
            onPressed: _isProcessing ? null : _showBlockUnblockDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More actions',
            onSelected: (value) {
              if (_isProcessing) return;
              if (value == 'suspend') _showSuspendDialog();
              if (value == 'reactivate') _showReactivateDialog();
            },
            itemBuilder: (_) {
              final isSuspended = widget.therapist.approvalStatus ==
                  TherapistApprovalStatus.suspended;
              return [
                if (!isSuspended)
                  const PopupMenuItem(
                    value: 'suspend',
                    child: ListTile(
                      leading: Icon(Icons.pause_circle_outline,
                          color: Colors.orange),
                      title: Text('Suspend therapist'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (isSuspended)
                  const PopupMenuItem(
                    value: 'reactivate',
                    child: ListTile(
                      leading: Icon(Icons.play_circle_outline,
                          color: Colors.green),
                      title: Text('Reactivate therapist'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AdminResponsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: widget.therapist.photoUrl != null
                        ? NetworkImage(widget.therapist.photoUrl!)
                        : null,
                    child: widget.therapist.photoUrl == null
                        ? Text(
                            widget.therapist.name.isNotEmpty
                                ? widget.therapist.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  SizedBox(width: isMobile ? 12 : 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.therapist.name,
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.therapist.title ?? 'Therapist',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusBadge(widget.therapist.approvalStatus),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 900;

                final leftColumn = Column(
                  children: [
                    _buildSection(
                      "Professional Bio",
                      Text(
                        widget.therapist.bio ?? 'No bio provided',
                        style: TextStyle(color: textColor, height: 1.5),
                      ),
                      textColor,
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      "Experience & Qualifications",
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _InfoRow(
                            "Years of Exp",
                            "${widget.therapist.yearsExperience} years",
                            textColor,
                          ),
                          _InfoRow(
                            "Qualifications",
                            widget.therapist.qualifications.join(", "),
                            textColor,
                          ),
                          _InfoRow(
                            "Specialties",
                            widget.therapist.specialties
                                .map((s) => s.name)
                                .join(", "),
                            textColor,
                          ),
                        ],
                      ),
                      textColor,
                    ),
                  ],
                );

                final rightColumn = Column(
                  children: [
                    _buildSection(
                      "Contact Info",
                      Column(
                        children: [
                          _InfoRow("Email", widget.therapist.email, textColor),
                          _InfoRow(
                            "Phone",
                            widget.therapist.phoneNumber ?? 'Not provided',
                            textColor,
                          ),
                        ],
                      ),
                      textColor,
                    ),
                    const SizedBox(height: 24),
                    if (widget.therapist.licenseDocumentUrl != null)
                      SkeuomorphicButton(
                        onPressed: () => launchUrl(
                          Uri.parse(widget.therapist.licenseDocumentUrl!),
                        ),
                        baseColor: AppColors.primary,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 18),
                            SizedBox(width: 8),
                            Text("View License"),
                          ],
                        ),
                      ),
                  ],
                );

                if (narrow) {
                  return Column(
                    children: [
                      leftColumn,
                      const SizedBox(height: 24),
                      rightColumn,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: leftColumn),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: rightColumn),
                  ],
                );
              },
            ),

            const SizedBox(height: 48),

            if (widget.therapist.approvalStatus ==
                TherapistApprovalStatus.pending)
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 640;
                  if (narrow) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SkeuomorphicButton(
                            onPressed: _isProcessing ? null : _handleApprove,
                            baseColor: AppColors.success,
                            child: _isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text("Approve Therapist"),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SkeuomorphicButton(
                            onPressed: _isProcessing ? null : _showRejectDialog,
                            baseColor: AppColors.error,
                            child: const Text("Reject Application"),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: SkeuomorphicButton(
                          onPressed: _isProcessing ? null : _handleApprove,
                          baseColor: AppColors.success,
                          child: _isProcessing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Approve Therapist"),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SkeuomorphicButton(
                          onPressed: _isProcessing ? null : _showRejectDialog,
                          baseColor: AppColors.error,
                          child: const Text("Reject Application"),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content, Color textColor) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TherapistApprovalStatus status) {
    Color color = switch (status) {
      TherapistApprovalStatus.pending => Colors.orange,
      TherapistApprovalStatus.approved => Colors.green,
      TherapistApprovalStatus.rejected => Colors.red,
      TherapistApprovalStatus.suspended => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color textColor;

  const _InfoRow(this.label, this.value, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: textColor, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
