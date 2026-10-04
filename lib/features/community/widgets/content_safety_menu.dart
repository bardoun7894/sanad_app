import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/community_safety_provider.dart';
import '../services/community_safety_service.dart';

String reportReasonLabel(ReportReason reason, S s) => switch (reason) {
  ReportReason.spam => s.reportReasonSpam,
  ReportReason.harassment => s.reportReasonHarassment,
  ReportReason.selfHarm => s.reportReasonSelfHarm,
  ReportReason.inappropriate => s.reportReasonInappropriate,
  ReportReason.other => s.reportReasonOther,
};

/// "..." menu with Report and (for other people's content) Block user.
class ContentSafetyMenu extends ConsumerWidget {
  final ReportTargetType targetType;
  final String postId;
  final String? commentId;
  final String authorId;

  /// Called after the content was reported or its author blocked.
  final VoidCallback? onDone;

  const ContentSafetyMenu({
    super.key,
    required this.targetType,
    required this.postId,
    this.commentId,
    required this.authorId,
    this.onDone,
  });

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final reason = await showModalBottomSheet<ReportReason>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                targetType == ReportTargetType.post
                    ? s.reportPost
                    : s.reportComment,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            for (final r in ReportReason.values)
              ListTile(
                title: Text(reportReasonLabel(r, s)),
                onTap: () => Navigator.pop(ctx, r),
              ),
          ],
        ),
      ),
    );
    if (reason == null) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(communitySafetyServiceProvider)
          .reportContent(
            targetType: targetType,
            postId: postId,
            commentId: commentId,
            reportedUserId: authorId,
            reporterId: user.uid,
            reason: reason,
          );
      if (targetType == ReportTargetType.post) {
        ref.read(hiddenPostIdsProvider.notifier).update((v) => {...v, postId});
      } else {
        ref
            .read(hiddenCommentIdsProvider.notifier)
            .update((v) => {...v, commentId!});
      }
      messenger?.showSnackBar(SnackBar(content: Text(s.reportThanks)));
      onDone?.call();
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(s.reportFailed)));
    }
  }

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.blockUser),
        content: Text(s.blockUserCommunityConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.blockUser,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(communitySafetyServiceProvider)
          .blockUser(user.uid, authorId);
      messenger?.showSnackBar(SnackBar(content: Text(s.userBlocked)));
      onDone?.call();
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(s.reportFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final me = ref.watch(authProvider).user;
    // Guests cannot report/block (no account to store it on).
    if (me == null || me.isGuest || me.uid == authorId) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
      padding: EdgeInsets.zero,
      tooltip: '',
      onSelected: (v) {
        if (v == 'report') _report(context, ref);
        if (v == 'block') _block(context, ref);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                const Icon(Icons.flag_outlined, size: 20),
                const SizedBox(width: 8),
                Text(s.report),
              ],
            ),
          ),
        PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                const Icon(Icons.block_rounded, size: 20),
                const SizedBox(width: 8),
                Text(s.blockUser),
              ],
            ),
          ),
      ],
    );
  }
}
