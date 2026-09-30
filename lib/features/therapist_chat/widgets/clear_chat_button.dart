import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/language_provider.dart';
import '../providers/therapist_chat_provider.dart';

/// Clear action for conversation list entries; never removes the thread.
class ClearChatButton extends ConsumerStatefulWidget {
  final String chatId;

  const ClearChatButton({super.key, required this.chatId});

  @override
  ConsumerState<ClearChatButton> createState() => _ClearChatButtonState();
}

class _ClearChatButtonState extends ConsumerState<ClearChatButton> {
  bool _busy = false;
  bool _confirming = false;

  Future<void> _confirmClear() async {
    if (_busy || _confirming) return;
    final messenger = ScaffoldMessenger.of(context);
    final s = ref.read(stringsProvider);
    setState(() => _confirming = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.clearChatConfirmTitle),
          content: Text(s.clearChatConfirmBody),
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
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      await ref.read(therapistChatServiceProvider).clearChat(widget.chatId);
      if (!messenger.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(s.clearChatSuccess)));
    } catch (_) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(s.clearChatError), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return IconButton(
      tooltip: s.clearChat,
      color: Colors.red,
      onPressed: _busy || _confirming ? null : _confirmClear,
      icon: _busy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: s.loading,
              ),
            )
          : const Icon(Icons.delete_outline),
    );
  }
}
