import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/crisis_alert.dart';
import '../providers/crisis_alerts_provider.dart';

/// Admin bottom sheet for crisis alert actions:
/// Acknowledge, Assign to therapist, Resolve, Mark as False Positive.
class CrisisAlertActionSheet extends ConsumerStatefulWidget {
  final CrisisAlert alert;
  final String currentAdminId;

  const CrisisAlertActionSheet({
    super.key,
    required this.alert,
    required this.currentAdminId,
  });

  @override
  ConsumerState<CrisisAlertActionSheet> createState() =>
      _CrisisAlertActionSheetState();
}

class _CrisisAlertActionSheetState
    extends ConsumerState<CrisisAlertActionSheet> {
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actions = ref.read(crisisAlertActionsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${s.crisisAlertActions}: ${widget.alert.userName}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.crisisSeverity}: ${widget.alert.severity.name.toUpperCase()} | ${s.crisisStatus}: ${widget.alert.status.name}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            if (widget.alert.triggeredText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                ),
                child: Text(
                  '"${widget.alert.triggeredText}"',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Action buttons based on current status
            if (widget.alert.status == CrisisAlertStatus.newAlert)
              _ActionButton(
                icon: Icons.check_circle_outline,
                label: s.crisisAcknowledgeAction,
                color: Colors.orange,
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await actions.acknowledge(
                    alertId: widget.alert.id,
                    acknowledgedBy: widget.currentAdminId,
                  );
                  if (mounted) Navigator.pop(context);
                },
              ),
            if (widget.alert.status == CrisisAlertStatus.newAlert ||
                widget.alert.status == CrisisAlertStatus.acknowledged)
              _ActionButton(
                icon: Icons.person_add_rounded,
                label: s.crisisAssignTherapist,
                color: Colors.blue,
                isLoading: _isLoading,
                onPressed: () {
                  // TODO: Show therapist picker dialog
                  Navigator.pop(context);
                },
              ),
            if (widget.alert.isActive) ...[
              _ActionButton(
                icon: Icons.check_rounded,
                label: s.crisisResolve,
                color: Colors.green,
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await actions.resolve(
                    alertId: widget.alert.id,
                    resolvedBy: widget.currentAdminId,
                    notes: _notesController.text.isNotEmpty
                        ? _notesController.text
                        : null,
                  );
                  if (mounted) Navigator.pop(context);
                },
              ),
              _ActionButton(
                icon: Icons.cancel_outlined,
                label: s.crisisFalsePositive,
                color: Colors.grey,
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() => _isLoading = true);
                  await actions.markFalsePositive(
                    alertId: widget.alert.id,
                    markedBy: widget.currentAdminId,
                    notes: _notesController.text.isNotEmpty
                        ? _notesController.text
                        : null,
                  );
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: s.crisisResolutionNotes,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color),
          label: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
