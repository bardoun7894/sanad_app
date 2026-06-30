import 'dart:async';
import 'package:flutter/material.dart';
import '../mood/models/mood_enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/services/soft_update_service.dart';
import '../../core/widgets/login_prompt.dart';
import '../../routes/app_routes.dart';
import '../auth/providers/auth_provider.dart';
import '../subscription/providers/subscription_provider.dart';
import '../subscription/providers/feature_gating_provider.dart';
import '../subscription/models/subscription_status.dart';
import '../mood/widgets/mood_selector.dart';
import '../mood/widgets/log_mood_sheet.dart';
import '../mood/providers/mood_tracker_provider.dart';
import '../profile/providers/profile_provider.dart';
import '../content/models/content_models.dart';
import '../content/providers/content_provider.dart';
import '../content/providers/youtube_provider.dart';
import '../content/screens/content_detail_screen.dart';
import '../content/screens/youtube_player_screen.dart';
import '../notifications/providers/notification_provider.dart';
import 'providers/home_provider.dart';
import 'providers/recommendation_provider.dart';
import 'widgets/recommendation_card.dart';

import '../../core/widgets/loading_state_widget.dart';
import 'widgets/greeting_header.dart';
import 'widgets/profile_progress_card.dart';
// import 'widgets/smart_shortcuts_row.dart'; // Removed
import 'widgets/progress_insights_row.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/daily_challenge_card.dart';
import 'widgets/session_card.dart';
import 'widgets/chat_cta_card.dart';
import '../engagement/providers/streak_provider.dart';
import '../engagement/widgets/achievement_unlocked_sheet.dart';
import '../engagement/models/achievement.dart';
import '../therapist_chat/providers/therapist_chat_access_provider.dart';

// Simple state provider for selected mood
final selectedMoodProvider = StateProvider<MoodType?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _profileCompletionPromptTimer;
  bool _hasShownExpirationPrompt = false;

  @override
  void initState() {
    super.initState();
    _startProfileCompletionTimer();
    // Enforce a MANDATORY, blocking update when the store has a newer build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SoftUpdateService.enforceMandatoryUpdate(
          context, ref.read(stringsProvider));
    });
  }

  @override
  void dispose() {
    _profileCompletionPromptTimer?.cancel();
    super.dispose();
  }

  void _startProfileCompletionTimer() {
    // Wait 2 minutes before prompting the user
    _profileCompletionPromptTimer = Timer(const Duration(minutes: 2), () {
      if (!mounted) return;
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user != null &&
          !user.isGuest &&
          user.profileCompletionPercentage < 1.0) {
        _showProfileCompletionPrompt();
      }
    });
  }

  void _showProfileCompletionPrompt() {
    final s = ref.read(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing2xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing2xl),
            Icon(
              Icons.person_add_alt_1_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              s.completeProfile,
              style: AppTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              s.helpUsKnowYou, // Fallback to existing translation
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing2xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.pop();
                  context.push(AppRoutes.profileCompletion);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  s.completeProfile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                s.skipForNow,
                style: AppTypography.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.textMuted
                      : AppColors.textMutedLight,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  void _showAchievementIfUnlocked(List<String>? newAchievements) {
    if (newAchievements == null || newAchievements.isEmpty || !mounted) return;

    // Show the first new achievement
    final achievementId = newAchievements.first;
    final achievement = AchievementDefinitions.getById(
      achievementId,
      isUnlocked: true,
    );
    if (achievement != null) {
      AchievementUnlockedSheet.show(context, achievement);
    }
  }

  Future<void> _handleMoodSelected(MoodType mood) async {
    final authState = ref.read(authProvider);
    final s = ref.read(stringsProvider);

    // Check if user is authenticated and not a guest
    final isGuest = authState.user?.isGuest ?? false;
    if (!authState.isAuthenticated || isGuest) {
      // Show login prompt for guests
      final shouldLogin = await showLoginPrompt(
        context,
        feature: s.moodTrackingTools,
        description: s.loginToTrackMood,
      );

      if (shouldLogin == true && mounted) {
        context.push(AppRoutes.login);
      }
      return;
    }

    // User is authenticated - show log mood sheet
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => LogMoodSheet(
          initialMood: mood,
          onSave: (selectedMood, note) async {
            // Save state
            ref.read(selectedMoodProvider.notifier).state = selectedMood;

            // Log to provider
            await ref
                .read(moodTrackerProvider.notifier)
                .logMood(selectedMood, note: note);

            // Update streak
            await ref.read(streakProvider.notifier).recordMoodLog();

            // Success feedback is handled inside the sheet animation
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for subscription expiration
    ref.listen(subscriptionStatusProvider, (previous, current) {
      if (!_hasShownExpirationPrompt &&
          current.state == SubscriptionState.expired) {
        _hasShownExpirationPrompt = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showExpirationPrompt();
          }
        });
      }
    });

    final selectedMood = ref.watch(selectedMoodProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    final dailyQuoteAsync = ref.watch(dailyQuoteProvider);

    // Get current user and profile data
    final currentUser = ref.watch(currentUserProvider);
    final profileState = ref.watch(profileProvider);
    final userProfile = profileState.user;

    // Get display name with fallback chain
    String? emailPrefix;
    final email = currentUser?.email;
    if (email != null) {
      emailPrefix = email.split('@').first;
    }
    final userName =
        userProfile?.name ??
        currentUser?.displayName ??
        emailPrefix ??
        s.guestUser;
    final avatarUrl = userProfile?.avatarUrl ?? currentUser?.photoUrl;

    // Get notifications and mood state
    final notificationCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header with time-based greeting and streak
              GreetingHeader(
                userName: userName,
                avatarUrl: avatarUrl,
                notificationCount: notificationCount,
                onNotificationTap: () => context.push(AppRoutes.notifications),
                onAvatarTap: () => context.push(AppRoutes.profile),
                isPremium: isPremium,
                subscriptionTier: ref.watch(subscriptionTierProvider),
              ),

              if (currentUser != null &&
                  currentUser.profileCompletionPercentage < 1.0 &&
                  !currentUser.isGuest)
                ProfileProgressCard(
                  progress: currentUser.profileCompletionPercentage,
                  onDismiss:
                      null, // Keep it persistent for now to ensure they complete it
                ),

              // Assigned-therapist CTA — single-line link surfacing the
              // user's therapist on the home screen so admin-assigned
              // patients can reach the chat in one tap.
              if (currentUser != null &&
                  (currentUser.assignedTherapistId ?? '').isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXl,
                  ),
                  child: _AssignedTherapistCta(
                    therapistId: currentUser.assignedTherapistId!,
                    cachedName: currentUser.assignedTherapistName ?? '',
                    userId: currentUser.uid,
                    isDark: isDark,
                  ),
                ),
              ],

              const SizedBox(height: AppTheme.spacingXl),

              // Progress Insights Row (Moved to top for better engagement)
              const ProgressInsightsRow(),

              const SizedBox(height: AppTheme.spacing2xl),

              MoodSelector(
                selectedMood: selectedMood,
                onMoodSelected: _handleMoodSelected,
                onViewHistory: () => context.push(AppRoutes.moodTracker),
              ),

              const SizedBox(height: AppTheme.spacing2xl),

              // Daily Challenge Card
              DailyChallengeCard(
                onComplete: () {
                  // Check for new achievements after completing challenge
                  final streakData = ref.read(streakProvider);
                  _showAchievementIfUnlocked(
                    streakData.achievements.isNotEmpty
                        ? [streakData.achievements.last]
                        : null,
                  );
                },
              ),

              const SizedBox(height: AppTheme.spacing2xl),

              // Daily Quote Card with Data
              dailyQuoteAsync.when(
                data: (quote) => quote != null
                    ? DailyQuoteCard(
                        quote: quote.localizedText(context),
                        author: quote.localizedAuthor(context),
                        onShareTap: () {
                          Share.share(
                            '${quote.localizedText(context)}\n\n- ${quote.localizedAuthor(context)}\n\n${s.sharedViaSanad}',
                          );
                        },
                      )
                    : const SizedBox.shrink(),
                loading: () => const LoadingStateWidget(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppTheme.spacing2xl),

              // Mood-Based Recommendations Section (اخترنا لك)
              _ContentSectionHeader(
                icon: Icons.auto_awesome_rounded,
                iconColor: AppColors.primary,
                title: s.recommendedForYou,
                onViewAll: () {},
                isDark: isDark,
                s: s,
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Mood-Based Recommendations — daily random mix of articles,
              // podcasts and videos refreshed every 24 hours.
              ref
                  .watch(moodBasedRecommendationsProvider)
                  .when(
                    data: (recommendations) {
                      if (recommendations.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: recommendations
                            .map(
                              (content) => RecommendationCard(
                                content: content,
                                onTap: () =>
                                    _showContentDetail(context, content),
                              ),
                            )
                            .toList(),
                      );
                    },
                    loading: () => const LoadingStateWidget(),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  ),

              const SizedBox(height: AppTheme.spacing2xl),

              // Upcoming Session Card (from Firestore)
              ref
                  .watch(nextUpcomingSessionProvider)
                  .when(
                    data: (session) => session != null
                        ? SessionCard(
                            title: s.upcomingSession,
                            dateTime: session.formattedDateTimeAr,
                            therapistName: session.therapistName,
                            sessionType: session.sessionType,
                            onTap: () => context.push(AppRoutes.bookings),
                          )
                        : SessionCard(
                            title: s.upcomingSession,
                            dateTime: s.noUpcomingSessions,
                            isEmpty: true,
                            onTap: () => context.push(AppRoutes.therapists),
                          ),
                    loading: () => const SessionCard(
                      title: '',
                      dateTime: '',
                      isLoading: true,
                    ),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  ),

              const SizedBox(height: AppTheme.spacing2xl),

              // ─── Blog Section ─────────────────────────────────
              _ContentSectionHeader(
                icon: Icons.article_rounded,
                iconColor: Colors.orange,
                title: s.blog,
                onViewAll: () => context.push(AppRoutes.blog),
                isDark: isDark,
                s: s,
              ),
              ref
                  .watch(blogProvider)
                  .when(
                    data: (articles) {
                      if (articles.isEmpty) return const SizedBox.shrink();
                      final preview = articles.take(3).toList();
                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXl,
                          ),
                          itemCount: preview.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) => _ContentPreviewCard(
                            item: preview[index],
                            width: 260,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ContentDetailScreen(item: preview[index]),
                              ),
                            ),
                            isDark: isDark,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

              const SizedBox(height: AppTheme.spacing2xl),

              // ─── Podcast Section ──────────────────────────────
              _ContentSectionHeader(
                icon: Icons.podcasts_rounded,
                iconColor: Colors.red,
                title: s.podcast,
                onViewAll: () => context.push(AppRoutes.sanadPodcast),
                isDark: isDark,
                s: s,
              ),
              ref
                  .watch(sanadPodcastProvider)
                  .when(
                    data: (podcasts) {
                      if (podcasts.isEmpty) return const SizedBox.shrink();
                      final preview = podcasts.take(3).toList();
                      return SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXl,
                          ),
                          itemCount: preview.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) => _ContentPreviewCard(
                            item: preview[index],
                            width: 220,
                            onTap: () =>
                                _showContentDetail(context, preview[index]),
                            isDark: isDark,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

              const SizedBox(height: AppTheme.spacing2xl),

              // ─── Sanad Tube Section ───────────────────────────
              _ContentSectionHeader(
                icon: Icons.play_circle_rounded,
                iconColor: Colors.redAccent,
                title: 'سند تيوب',
                onViewAll: () => context.push(AppRoutes.sanadTube),
                isDark: isDark,
                s: s,
              ),
              ref
                  .watch(sanadTubeProvider)
                  .when(
                    data: (videos) {
                      if (videos.isEmpty) return const SizedBox.shrink();
                      final preview = videos.take(3).toList();
                      return SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXl,
                          ),
                          itemCount: preview.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) => _ContentPreviewCard(
                            item: preview[index],
                            width: 240,
                            onTap: () =>
                                _showContentDetail(context, preview[index]),
                            isDark: isDark,
                            showPlayIcon: true,
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

              const SizedBox(height: AppTheme.spacing2xl),

              // Premium upgrade CTA for free users
              if (!isPremium) ...{
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXl,
                  ),
                  child: GestureDetector(
                    onTap: () => context.push('/subscription'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.upgradeToPremium,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.unlimitedChatAndTherapyCalls,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              },

              const SizedBox(height: AppTheme.spacing2xl),

              // Chat CTA Card (moved to end)
              ChatCtaCard(onStartChat: () => context.push(AppRoutes.chat)),

              const SizedBox(height: 100.0),
            ],
          ),
        ),
      ),
    );
  }

  void _showContentDetail(BuildContext context, ContentItem content) {
    // For YouTube content, open in-app player (with external fallback in app bar)
    if (content.isYouTubeVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YouTubePlayerScreen(content: content),
        ),
      );
      return;
    }

    // Navigate to full content detail page for all other content
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContentDetailScreen(item: content)),
    );
  }

  void _showExpirationPrompt() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.read(stringsProvider);
    final isArabic = ref.read(languageProvider).language == AppLanguage.arabic;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isArabic ? 'انتهت صلاحية الاشتراك' : 'Subscription Expired',
                style: AppTypography.headingSmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          isArabic
              ? 'لقد انتهت صلاحية اشتراكك المميز. يرجى التجديد للاستمرار في الاستمتاع بالميزات اللا محدودة.'
              : 'Your premium subscription has expired. Please renew to continue enjoying unlimited features.',
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(s.cancel, style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              s.upgradeToPremium,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with icon, title, and "View All" button
class _ContentSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onViewAll;
  final bool isDark;
  final dynamic s;

  const _ContentSectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onViewAll,
    required this.isDark,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
        child: Row(
          children: [
            // Icon container — matches session/challenge card icon containers
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 22)),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            // Title — matches headingMedium (16px W700) used across the app
            Text(
              title,
              style: AppTypography.headingMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            // View All — matches bodySmall pattern with primary accent
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
                child: Text(
                  s.viewAll,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scroll content preview card — matches app card patterns
/// (24px radius, surfaceDark/surfaceLight, AppShadows-style shadow)
class _ContentPreviewCard extends StatelessWidget {
  final ContentItem item;
  final double width;
  final VoidCallback onTap;
  final bool isDark;
  final bool showPlayIcon;

  const _ContentPreviewCard({
    required this.item,
    required this.width,
    required this.onTap,
    required this.isDark,
    this.showPlayIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : const Color(0xFF64748B).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            if (!isDark)
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.thumbnailUrl != null &&
                      item.thumbnailUrl!.isNotEmpty)
                    Image.network(
                      item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),
                  // Gradient fade at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight)
                                .withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (showPlayIcon)
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  // Duration badge
                  if (item.formattedDuration.isNotEmpty)
                    Positioned(
                      top: AppTheme.spacingSm,
                      left: AppTheme.spacingSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXs,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 10,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              item.formattedDuration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Title & category
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.localizedTitle(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (item.category != null && item.category!.isNotEmpty)
                      Text(
                        item.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E3A5F), AppColors.surfaceDark]
              : [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.03),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          showPlayIcon ? Icons.videocam_outlined : Icons.article_outlined,
          size: 32,
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _AssignedTherapistCta extends ConsumerWidget {
  final String therapistId;
  final String cachedName;
  final String userId;
  final bool isDark;

  const _AssignedTherapistCta({
    required this.therapistId,
    required this.cachedName,
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatAccess = ref
            .watch(therapistChatAccessProvider(therapistId))
            .valueOrNull ??
        TherapistChatAccess.full;
    // Gate: only render this card when the user has at least one paid
    // booking with this therapist. In-memory filter on a single-field
    // equality query (`client_id`) keeps this index-free.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('client_id', isEqualTo: userId)
          .snapshots(),
      builder: (context, paidSnap) {
        if (!paidSnap.hasData) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        DateTime? nextSession;
        for (final doc in paidSnap.data!.docs) {
          final data = doc.data();
          if (data['therapist_id'] != therapistId) continue;
          if (data['payment_status'] != 'paid') continue;
          final ts = data['scheduled_time'];
          if (ts is Timestamp) {
            final dt = ts.toDate();
            if (dt.isAfter(now)) {
              if (nextSession == null || dt.isBefore(nextSession)) {
                nextSession = dt;
              }
            }
          }
        }

        // Show the card whenever the patient actually has chat access to this
        // therapist — i.e. user_access == 'full' (paid booking, premium, OR an
        // admin assignment). Previously this was gated on a paid booking, which
        // hid the card from admin-assigned free patients (the bookings stream
        // above is now only used to compute the next-session subtitle).
        if (chatAccess == TherapistChatAccess.none) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('therapists')
              .doc(therapistId)
              .snapshots(),
          builder: (context, snap) {
            String name = cachedName;
            String photo = '';
            if (snap.hasData && snap.data!.exists) {
              final d = snap.data!.data() ?? const {};
              final live =
                  (d['name'] ?? d['display_name'] ?? d['full_name'] ?? '')
                      .toString();
              if (live.isNotEmpty) name = live;
              photo = (d['photo_url'] ?? d['avatar_url'] ?? '').toString();
            }
            if (name.isEmpty) name = 'Your therapist';

            final subtitle = nextSession != null
                ? _formatNextSession(nextSession)
                : 'Tap to continue chat';

            return Material(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (chatAccess == TherapistChatAccess.none) {
                    final s = ref.read(stringsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.chatLockedPayPrompt)),
                    );
                    return;
                  }
                  context.push('/chat/therapist/${therapistId}_$userId');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.18),
                        backgroundImage:
                            photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty
                            ? Text(
                                name.characters.isNotEmpty
                                    ? name.characters.first.toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: AppTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chat_bubble_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _formatNextSession(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays >= 1) {
      return 'Next session in ${diff.inDays}d';
    }
    if (diff.inHours >= 1) {
      return 'Next session in ${diff.inHours}h';
    }
    if (diff.inMinutes >= 1) {
      return 'Starting in ${diff.inMinutes}m';
    }
    return 'Starting soon';
  }
}
