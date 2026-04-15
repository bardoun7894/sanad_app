import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/l10n/language_provider.dart';

/// Dialog shown after a call ends to prompt the therapist for session notes.
class PostCallNotesDialog extends ConsumerStatefulWidget {
  final String bookingId;

  const PostCallNotesDialog({super.key, required this.bookingId});

  /// Show the dialog using any BuildContext (e.g., from a global navigator key).
  static Future<void> show(BuildContext context, String bookingId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PostCallNotesDialog(bookingId: bookingId),
    );
  }

  @override
  ConsumerState<PostCallNotesDialog> createState() =>
      _PostCallNotesDialogState();
}

class _PostCallNotesDialogState extends ConsumerState<PostCallNotesDialog> {
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    if (_notesController.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
            'private_notes': _notesController.text.trim(),
            'updated_at': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('PostCallNotesDialog: Failed to save notes: $e');
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.sessionCompletedSuccessfully,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.addSessionNotes,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: s.addSessionNotes,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(s.skip),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveNotes,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.saveNotes),
        ),
      ],
    );
  }
}
