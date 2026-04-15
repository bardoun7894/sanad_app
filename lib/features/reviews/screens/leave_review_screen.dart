import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sanad_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../widgets/rating_stars.dart';

/// Screen for leaving a review after a therapy session
class LeaveReviewScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String therapistId;
  final String therapistName;
  final String? therapistPhoto;

  const LeaveReviewScreen({
    super.key,
    required this.bookingId,
    required this.therapistId,
    required this.therapistName,
    this.therapistPhoto,
  });

  @override
  ConsumerState<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends ConsumerState<LeaveReviewScreen> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _hasExistingReview = false;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  Future<void> _checkExistingReview() async {
    final existing = await ref
        .read(reviewProvider.notifier)
        .getBookingReview(widget.bookingId);

    if (existing != null && mounted) {
      setState(() {
        _hasExistingReview = true;
        _selectedRating = existing.starCount;
        _commentController.text = existing.comment ?? '';
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final userId = authState.user?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to leave a review'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(reviewProvider.notifier).submitReview(
          therapistId: widget.therapistId,
          userId: userId,
          bookingId: widget.bookingId,
          rating: _selectedRating.toDouble(),
          comment: _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your review!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.leaveReview),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Therapist info
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: widget.therapistPhoto != null
                  ? NetworkImage(widget.therapistPhoto!)
                  : null,
              child: widget.therapistPhoto == null
                  ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.therapistName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              s.howWasYourSession,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Rating stars
            Text(
              s.tapToRate,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            RatingStars.interactive(
              rating: _selectedRating.toDouble(),
              onRatingChanged: (rating) {
                setState(() {
                  _selectedRating = rating;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingLabel(_selectedRating, s),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _selectedRating > 0 ? AppColors.primary : Colors.grey,
              ),
            ),

            const SizedBox(height: 32),

            // Comment input
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                s.additionalComments,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: s.shareYourExperience,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Error message
            if (reviewState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reviewState.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit button
            SanadButton(
              onPressed: reviewState.isSubmitting ? null : _submitReview,
              text: _hasExistingReview ? s.updateReview : s.submitReview,
              isLoading: reviewState.isSubmitting,
            ),

            const SizedBox(height: 16),

            // Skip button
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(
                s.skipForNow,
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating, dynamic s) {
    switch (rating) {
      case 1:
        return s.ratingPoor;
      case 2:
        return s.ratingFair;
      case 3:
        return s.ratingGood;
      case 4:
        return s.ratingVeryGood;
      case 5:
        return s.ratingExcellent;
      default:
        return '';
    }
  }
}

// The authUserIdProvider is defined in auth_provider.dart
// This screen uses ref.read(authProvider).user?.uid instead
