import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/language_provider.dart';
import '../providers/therapist_chat_provider.dart';

/// Therapist-only action that hides a chat from the therapist's own list.
/// Messages and the patient's view are left untouched.
class RemoveChatButton extends ConsumerWidget {
  final String chatId;

  const RemoveChatButton({super.key, required this.chatId});

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final s = ref.read(stringsProvider);
    final service = ref.read(therapistChatServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.removeChatFromList),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.clearChatDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await service.hideChatForTherapist(chatId);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text(s.clearChatError), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return IconButton(
      tooltip: s.clearChatDelete,
      color: Colors.red,
      onPressed: () => _confirmRemove(context, ref),
      icon: const Icon(Icons.delete_outline),
    );
  }
}
