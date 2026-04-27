import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

const _kPages = [
  _PageMeta(id: 'privacy_policy', labelAr: 'سياسة الخصوصية', labelEn: 'Privacy Policy', icon: Icons.privacy_tip_outlined),
  _PageMeta(id: 'terms_of_service', labelAr: 'شروط الخدمة', labelEn: 'Terms of Service', icon: Icons.gavel_rounded),
  _PageMeta(id: 'about_us', labelAr: 'من نحن', labelEn: 'About Us', icon: Icons.info_outline_rounded),
  _PageMeta(id: 'faq', labelAr: 'الأسئلة الشائعة', labelEn: 'FAQ', icon: Icons.help_outline_rounded),
];

class _PageMeta {
  final String id;
  final String labelAr;
  final String labelEn;
  final IconData icon;
  const _PageMeta({required this.id, required this.labelAr, required this.labelEn, required this.icon});
}

class StaticPagesScreen extends ConsumerStatefulWidget {
  const StaticPagesScreen({super.key});

  @override
  ConsumerState<StaticPagesScreen> createState() => _StaticPagesScreenState();
}

class _StaticPagesScreenState extends ConsumerState<StaticPagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kPages.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : AppColors.textPrimary);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Static Pages', style: TextStyle(color: textColor)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor:
              isDark ? Colors.white54 : AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: _kPages
              .map((p) => Tab(
                    child: Row(
                      children: [
                        Icon(p.icon, size: 16),
                        const SizedBox(width: 6),
                        Text(p.labelEn),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _kPages
            .map((p) => _PageEditor(page: p, isDark: isDark, textColor: textColor))
            .toList(),
      ),
    );
  }
}

class _PageEditor extends StatefulWidget {
  final _PageMeta page;
  final bool isDark;
  final Color textColor;

  const _PageEditor({required this.page, required this.isDark, required this.textColor});

  @override
  State<_PageEditor> createState() => _PageEditorState();
}

class _PageEditorState extends State<_PageEditor> {
  final _arController = TextEditingController();
  final _enController = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('static_pages')
          .doc(widget.page.id)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _arController.text = data['content_ar'] ?? '';
        _enController.text = data['content_en'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('static_pages')
          .doc(widget.page.id)
          .set({
        'content_ar': _arController.text.trim(),
        'content_en': _enController.text.trim(),
        'label_ar': widget.page.labelAr,
        'label_en': widget.page.labelEn,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.page.labelEn} saved'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _arController.dispose();
    _enController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    final isDark = widget.isDark;
    final textColor = widget.textColor;
    final borderColor = isDark ? Colors.white24 : AppColors.border;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            color: isDark
                ? AppColors.surfaceGlass.withValues(alpha: 0.6)
                : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.page.icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.page.labelAr,
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ ${widget.page.labelEn}',
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Arabic Content',
                    style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _arController,
                  maxLines: 12,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'أدخل المحتوى بالعربية هنا...',
                    hintStyle:
                        TextStyle(color: textColor.withValues(alpha: 0.3)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary)),
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.withValues(alpha: 0.04),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 20),
                Text('English Content',
                    style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _enController,
                  maxLines: 12,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter content in English here...',
                    hintStyle:
                        TextStyle(color: textColor.withValues(alpha: 0.3)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor)),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary)),
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.withValues(alpha: 0.04),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_saving ? 'Saving…' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
