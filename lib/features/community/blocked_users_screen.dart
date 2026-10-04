import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/language_provider.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/community_safety_provider.dart';

/// Lists blocked users with an Unblock action. Only generic labels are shown
/// so blocking an anonymous author never reveals who they are.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final blocked = ref.watch(blockedUserIdsProvider).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.blockedUsers)),
      body: blocked.isEmpty
          ? Center(child: Text(s.noBlockedUsers))
          : ListView.separated(
              itemCount: blocked.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.block_rounded),
                title: Text('${s.blockedUserLabel} ${i + 1}'),
                trailing: TextButton(
                  onPressed: () {
                    final uid = ref.read(authProvider).user?.uid;
                    if (uid == null) return;
                    ref
                        .read(communitySafetyServiceProvider)
                        .unblockUser(uid, blocked[i]);
                  },
                  child: Text(s.unblockUser),
                ),
              ),
            ),
    );
  }
}
