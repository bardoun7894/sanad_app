import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/post.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  final Function(String content, PostCategory category, bool isAnonymous)
  onPost;

  const CreatePostSheet({super.key, required this.onPost});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _contentController = TextEditingController();
  PostCategory _selectedCategory = PostCategory.general;
  bool _isAnonymous = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submitPost() {
    if (_contentController.text.trim().isEmpty) return;

    HapticFeedback.mediumImpact();
    widget.onPost(
      _contentController.text.trim(),
      _selectedCategory,
      _isAnonymous,
    );

    setState(() {
      _showSuccess = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    if (_showSuccess) {
      return _SuccessView(isDark: isDark, strings: s);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Text(
                    s.shareWithCommunity,
                    style: AppTypography.headingMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.textLight,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.yourThoughtsMatter,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              // Category selector
              Text(
                s.category,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PostCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  final color = PostCategoryData.getColor(category);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? color.withValues(alpha: 0.3) : color)
                            : (isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.backgroundLight),
                        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PostCategoryData.getIcon(category),
                            size: 16,
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.white)
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            PostCategoryData.getLabel(category, strings: s),
                            style: AppTypography.labelSmall.copyWith(
                              color: isSelected
                                  ? (isDark ? Colors.white : Colors.white)
                                  : AppColors.textMuted,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Content input
              Text(
                s.whatsOnYourMind,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLength: 280,
                  maxLines: 5,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                  decoration: InputDecoration(
                    hintText: s.sharePlaceholder,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    counterStyle: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),

              // Anonymous toggle
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isAnonymous = !_isAnonymous;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isAnonymous
                        ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : AppColors.softBlue)
                        : (isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: _isAnonymous
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isAnonymous
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isAnonymous
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_outlined,
                          size: 20,
                          color: _isAnonymous
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.postAnonymously,
                              style: AppTypography.labelLarge.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textLight,
                              ),
                            ),
                            Text(
                              s.nameHidden,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _isAnonymous
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _isAnonymous
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Post button
              SanadButton(
                text: s.sharePost,
                icon: Icons.send_rounded,
                onPressed: _contentController.text.trim().isNotEmpty
                    ? _submitPost
                    : null,
                isFullWidth: true,
                size: SanadButtonSize.large,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatefulWidget {
  final bool isDark;
  final S strings;

  const _SuccessView({required this.isDark, required this.strings});

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.strings.postShared,
              style: AppTypography.headingMedium.copyWith(
                color: widget.isDark ? Colors.white : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.strings.thankYouSharing,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
