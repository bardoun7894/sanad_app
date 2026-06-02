import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/signup_failure.dart';
import '../providers/signup_failures_provider.dart';

/// Admin view: who is stuck during signup and why.
///
/// Two sections:
///   1. Hard failures — writes to users/{uid} that errored out client-side.
///      Captured in the `signup_failures` Firestore collection by
///      [_writeUserDocSafe] in auth_provider.dart.
///   2. Incomplete profiles — users who got past auth but never finished the
///      profile completion screen (has_complete_profile == false).
class AdminSignupHealthScreen extends ConsumerStatefulWidget {
  const AdminSignupHealthScreen({super.key});

  @override
  ConsumerState<AdminSignupHealthScreen> createState() =>
      _AdminSignupHealthScreenState();
}

class _AdminSignupHealthScreenState
    extends ConsumerState<AdminSignupHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(signupFailuresProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupFailuresProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: state.isLoading
                ? null
                : () => ref.read(signupFailuresProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _ErrorView(error: state.error!, onRetry: () {
                  ref.read(signupFailuresProvider.notifier).load();
                })
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(signupFailuresProvider.notifier).load(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SummaryRow(
                        failureCount: state.failures.length,
                        incompleteCount: state.incompleteProfiles.length,
                      ),
                      const SizedBox(height: 16),
                      _BackfillCard(
                        onDryRun: () => _runBackfill(context, dryRun: true),
                        onApply: () => _runBackfill(context, dryRun: false),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Hard failures (${state.failures.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Users whose profile write errored out. The reason is captured below.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (state.failures.isEmpty)
                        const _EmptyHint(
                            text: 'No active failures. New ones will appear here automatically.'),
                      ...state.failures.map((f) => _FailureTile(
                            failure: f,
                            onResolve: () => ref
                                .read(signupFailuresProvider.notifier)
                                .markResolved(f.uid),
                            onDismiss: () => ref
                                .read(signupFailuresProvider.notifier)
                                .dismiss(f.uid),
                          )),
                      const SizedBox(height: 32),
                      Text(
                        'Incomplete profiles (${state.incompleteProfiles.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Users authenticated but never finished profile completion.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (state.incompleteProfiles.isEmpty)
                        const _EmptyHint(
                            text: 'No incomplete profiles right now.'),
                      ...state.incompleteProfiles.map((f) => _FailureTile(
                            failure: f,
                            showActions: false,
                          )),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Future<void> _runBackfill(BuildContext context,
      {required bool dryRun}) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(dryRun ? 'Running dry-run...' : 'Applying backfill...'),
      duration: const Duration(seconds: 30),
    ));
    try {
      final stats = await ref
          .read(signupFailuresProvider.notifier)
          .runBackfill(dryRun: dryRun);
      messenger.hideCurrentSnackBar();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(dryRun ? 'Backfill dry-run result' : 'Backfill complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: stats.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${e.key}: ${e.value}'),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Backfill failed: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }
}

class _BackfillCard extends StatelessWidget {
  final VoidCallback onDryRun;
  final VoidCallback onApply;
  const _BackfillCard({required this.onDryRun, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_sync, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Reconcile Auth ↔ Firestore',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Finds Firebase Auth users without a Firestore profile and seeds '
              'the missing docs from Auth metadata. Safe to re-run.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Dry run'),
                  onPressed: onDryRun,
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run backfill'),
                  onPressed: onApply,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int failureCount;
  final int incompleteCount;
  const _SummaryRow({
    required this.failureCount,
    required this.incompleteCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Hard failures',
            value: failureCount.toString(),
            color: failureCount > 0
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            icon: Icons.error_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Incomplete profiles',
            value: incompleteCount.toString(),
            color: theme.colorScheme.tertiary,
            icon: Icons.hourglass_empty,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureTile extends StatelessWidget {
  final SignupFailure failure;
  final VoidCallback? onResolve;
  final VoidCallback? onDismiss;
  final bool showActions;

  const _FailureTile({
    required this.failure,
    this.onResolve,
    this.onDismiss,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final whenText = failure.attemptedAt != null
        ? DateFormat('MMM d, HH:mm').format(failure.attemptedAt!)
        : '—';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    failure.uid,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  whenText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _Pill(text: failure.stageLabel, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                if (failure.errorCode != null)
                  _Pill(
                    text: failure.errorCode!,
                    color: theme.colorScheme.error,
                  ),
                if (failure.platform != null) ...[
                  const SizedBox(width: 6),
                  _Pill(
                    text: failure.platform!,
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              failure.error,
              style: theme.textTheme.bodySmall,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (failure.attemptedFields.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Fields attempted: ${failure.attemptedFields.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (showActions) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: onResolve,
                    child: const Text('Mark resolved'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
