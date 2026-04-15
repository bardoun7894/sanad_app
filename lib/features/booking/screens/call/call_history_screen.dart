import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/widgets/loading_state_widget.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/providers/auth_provider.dart';
import 'call_invite_service.dart';
import 'call_history_provider.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authUser = ref.watch(authProvider).user;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.callHistory)),
        body: Center(child: Text(s.loginRequired)),
      );
    }

    final historyState = ref.watch(callHistoryProvider(authUser.uid));

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          s.callHistory,
          style: AppTypography.headingLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(context, ref, historyState, authUser.uid, s, isDark),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CallHistoryState state,
    String userId,
    S s,
    bool isDark,
  ) {
    if (state.isLoading && state.calls.isEmpty) {
      return LoadingStateWidget(message: s.loading);
    }

    if (state.error != null && state.calls.isEmpty) {
      return ErrorStateWidget(
        message: s.errorLoadingData,
        retryLabel: s.retry,
        onRetry: () =>
            ref.read(callHistoryProvider(userId).notifier).refresh(),
      );
    }

    if (state.calls.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.call_rounded,
        message: s.noCallHistory,
        description: s.noCallHistoryDesc,
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(callHistoryProvider(userId).notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: state.calls.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.calls.length) {
            // Load more trigger
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(callHistoryProvider(userId).notifier)
                  .loadMore();
            });
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final call = state.calls[index];
          return _CallHistoryTile(
            call: call,
            currentUserId: userId,
            isDark: isDark,
            s: s,
          );
        },
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  final CallInvite call;
  final String currentUserId;
  final bool isDark;
  final S s;

  const _CallHistoryTile({
    required this.call,
    required this.currentUserId,
    required this.isDark,
    required this.s,
  });

  bool get _isOutgoing => call.callerId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final otherName = _isOutgoing ? call.calleeName : call.callerName;
    final statusInfo = _getStatusInfo();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF374151)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Call direction icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusInfo.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusInfo.icon,
                color: statusInfo.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        statusInfo.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: statusInfo.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (call.callDurationSeconds != null &&
                          call.callDurationSeconds! > 0) ...[
                        Text(
                          ' · ',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          _formatDuration(call.callDurationSeconds!),
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Timestamp
            Text(
              _formatTimestamp(call.createdAt),
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo() {
    switch (call.status) {
      case 'missed':
        return _StatusInfo(
          icon: Icons.call_missed_rounded,
          color: const Color(0xFFEF4444),
          label: s.missedCall,
        );
      case 'declined':
        return _StatusInfo(
          icon: Icons.call_end_rounded,
          color: const Color(0xFFEF4444),
          label: s.callDeclined,
        );
      case 'ended':
        if (_isOutgoing) {
          return _StatusInfo(
            icon: Icons.call_made_rounded,
            color: const Color(0xFF22C55E),
            label: s.outgoingCall,
          );
        } else {
          return _StatusInfo(
            icon: Icons.call_received_rounded,
            color: const Color(0xFF3B82F6),
            label: s.incomingCall,
          );
        }
      case 'accepted':
        return _StatusInfo(
          icon: Icons.call_rounded,
          color: const Color(0xFF22C55E),
          label: s.inProgressStatus,
        );
      case 'ringing':
        return _StatusInfo(
          icon: Icons.ring_volume_rounded,
          color: Colors.orange,
          label: s.callRinging,
        );
      case 'cancelled':
        return _StatusInfo(
          icon: Icons.call_end_rounded,
          color: const Color(0xFF94A3B8),
          label: s.cancelled,
        );
      default:
        if (_isOutgoing) {
          return _StatusInfo(
            icon: Icons.call_made_rounded,
            color: const Color(0xFF22C55E),
            label: s.outgoingCall,
          );
        } else {
          return _StatusInfo(
            icon: Icons.call_received_rounded,
            color: const Color(0xFF3B82F6),
            label: s.incomingCall,
          );
        }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(dt);
    } else if (diff.inDays == 1) {
      return s.yesterday;
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(dt);
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }
}

class _StatusInfo {
  final IconData icon;
  final Color color;
  final String label;

  const _StatusInfo({
    required this.icon,
    required this.color,
    required this.label,
  });
}
