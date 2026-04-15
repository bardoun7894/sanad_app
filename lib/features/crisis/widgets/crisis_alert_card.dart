import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/crisis_alert.dart';

class CrisisAlertCard extends ConsumerWidget {
  final CrisisAlert alert;
  final VoidCallback onTap;

  const CrisisAlertCard({super.key, required this.alert, required this.onTap});

  Color get _severityColor {
    switch (alert.severity) {
      case CrisisAlertSeverity.critical:
        return AppColors.riskCritical;
      case CrisisAlertSeverity.high:
        return AppColors.riskHigh;
      case CrisisAlertSeverity.moderate:
        return AppColors.riskModerate;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _severityColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: _severityColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Pulsing severity indicator for critical/new alerts
              if (alert.severity == CrisisAlertSeverity.critical &&
                  alert.status == CrisisAlertStatus.newAlert)
                _PulsingDot(color: _severityColor)
              else
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _severityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _SeverityBadge(
                          severity: alert.severity,
                          color: _severityColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _sourceIcon,
                          size: 12,
                          color: isDark
                              ? Colors.white54
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _sourceLabel(s),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        _StatusBadge(status: alert.status),
                      ],
                    ),
                    if (alert.matchedKeywords.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${s.crisisMatchedKeywords}: ${alert.matchedKeywords.take(3).join(", ")}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white38 : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _sourceIcon {
    switch (alert.source) {
      case CrisisAlertSource.aiChat:
        return Icons.smart_toy_rounded;
      case CrisisAlertSource.community:
        return Icons.groups_rounded;
      case CrisisAlertSource.moodLog:
        return Icons.mood_rounded;
    }
  }

  String _sourceLabel(dynamic s) {
    switch (alert.source) {
      case CrisisAlertSource.aiChat:
        return s.crisisSourceAiChat;
      case CrisisAlertSource.community:
        return s.crisisSourceCommunity;
      case CrisisAlertSource.moodLog:
        return s.crisisSourceMoodLog;
    }
  }
}

class _SeverityBadge extends StatelessWidget {
  final CrisisAlertSeverity severity;
  final Color color;

  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final CrisisAlertStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case CrisisAlertStatus.newAlert:
        return Colors.red;
      case CrisisAlertStatus.acknowledged:
        return Colors.orange;
      case CrisisAlertStatus.assigned:
        return Colors.blue;
      case CrisisAlertStatus.resolved:
        return Colors.green;
      case CrisisAlertStatus.falsePositive:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case CrisisAlertStatus.newAlert:
        return 'NEW';
      case CrisisAlertStatus.acknowledged:
        return 'ACK';
      case CrisisAlertStatus.assigned:
        return 'ASSIGNED';
      case CrisisAlertStatus.resolved:
        return 'RESOLVED';
      case CrisisAlertStatus.falsePositive:
        return 'FALSE +';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12,
          height: 40,
          alignment: Alignment.center,
          child: Container(
            width: 8 + (_controller.value * 4),
            height: 8 + (_controller.value * 4),
            decoration: BoxDecoration(
              color: widget.color.withValues(
                alpha: 0.5 + (_controller.value * 0.5),
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
