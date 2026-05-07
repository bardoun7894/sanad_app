import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class FaqsManagementScreen extends ConsumerStatefulWidget {
  const FaqsManagementScreen({super.key});

  @override
  ConsumerState<FaqsManagementScreen> createState() =>
      _FaqsManagementScreenState();
}

class _FaqsManagementScreenState extends ConsumerState<FaqsManagementScreen> {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('faqs');

  Future<void> _showEditor({DocumentSnapshot<Map<String, dynamic>>? doc}) {
    return showDialog(
      context: context,
      builder: (_) => _FaqEditorDialog(doc: doc, collection: _col),
    );
  }

  Future<void> _confirmDelete(String id, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete FAQ'),
        content: Text('Are you sure you want to delete "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _col.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : AppColors.textPrimary);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('FAQs', style: TextStyle(color: textColor)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add FAQ'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: textColor),
                ),
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    size: 64,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No FAQs yet — tap "Add FAQ" to create one.',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final qAr = (data['question_ar'] as String?) ?? '';
              final qEn = (data['question_en'] as String?) ?? '';
              final aAr = (data['answer_ar'] as String?) ?? '';
              final aEn = (data['answer_en'] as String?) ?? '';
              final order = (data['order'] as num?)?.toInt() ?? index;

              return GlassCard(
                color: isDark
                    ? AppColors.surfaceGlass.withValues(alpha: 0.6)
                    : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$order',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _showEditor(doc: doc),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                          ),
                          onPressed: () => _confirmDelete(
                            doc.id,
                            qEn.isNotEmpty ? qEn : qAr,
                          ),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (qAr.isNotEmpty)
                      Text(
                        qAr,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    if (qEn.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        qEn,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (aAr.isNotEmpty)
                      Text(
                        aAr,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    if (aEn.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        aEn,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FaqEditorDialog extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>>? doc;
  final CollectionReference<Map<String, dynamic>> collection;

  const _FaqEditorDialog({required this.doc, required this.collection});

  @override
  State<_FaqEditorDialog> createState() => _FaqEditorDialogState();
}

class _FaqEditorDialogState extends State<_FaqEditorDialog> {
  late final TextEditingController _qArCtrl;
  late final TextEditingController _qEnCtrl;
  late final TextEditingController _aArCtrl;
  late final TextEditingController _aEnCtrl;
  late final TextEditingController _orderCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data();
    _qArCtrl = TextEditingController(
      text: (data?['question_ar'] as String?) ?? '',
    );
    _qEnCtrl = TextEditingController(
      text: (data?['question_en'] as String?) ?? '',
    );
    _aArCtrl = TextEditingController(
      text: (data?['answer_ar'] as String?) ?? '',
    );
    _aEnCtrl = TextEditingController(
      text: (data?['answer_en'] as String?) ?? '',
    );
    _orderCtrl = TextEditingController(
      text: ((data?['order'] as num?)?.toInt() ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _qArCtrl.dispose();
    _qEnCtrl.dispose();
    _aArCtrl.dispose();
    _aEnCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qAr = _qArCtrl.text.trim();
    final qEn = _qEnCtrl.text.trim();
    if (qAr.isEmpty && qEn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question (AR or EN) is required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final payload = {
        'question_ar': qAr,
        'question_en': qEn,
        'answer_ar': _aArCtrl.text.trim(),
        'answer_en': _aEnCtrl.text.trim(),
        'order': int.tryParse(_orderCtrl.text.trim()) ?? 0,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (widget.doc == null) {
        payload['created_at'] = FieldValue.serverTimestamp();
        await widget.collection.add(payload);
      } else {
        await widget.collection
            .doc(widget.doc!.id)
            .set(payload, SetOptions(merge: true));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.doc != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      title: Text(isEdit ? 'Edit FAQ' : 'Add FAQ'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _orderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Order (lower = first)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _qArCtrl,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'Question (Arabic)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aArCtrl,
                textDirection: TextDirection.rtl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Answer (Arabic)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _qEnCtrl,
                decoration: const InputDecoration(
                  labelText: 'Question (English)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aEnCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Answer (English)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: Text(_saving ? 'Saving…' : 'Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
