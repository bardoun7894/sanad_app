import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/journal_lock_provider.dart';
import 'journal_home_screen.dart';
import 'journal_lock_screen.dart';

/// Entry point for /journal. Shows the lock screen when a PIN is set and the
/// session is locked; otherwise the journal home.
class JournalGate extends ConsumerWidget {
  const JournalGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(journalLockProvider);
    if (lock.isLocked) {
      return const JournalLockScreen();
    }
    return const JournalHomeScreen();
  }
}
