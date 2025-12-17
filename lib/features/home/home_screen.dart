import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';
import '../../routes/app_router.dart';
import '../mood/widgets/mood_selector.dart';
import 'widgets/header.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/session_card.dart';
import 'widgets/meditation_card.dart';
import 'widgets/chat_cta_card.dart';

// Simple state provider for selected mood
final selectedMoodProvider = StateProvider<MoodType?>((ref) => null);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMood = ref.watch(selectedMoodProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              HomeHeader(
                userName: s.sampleUserName,
                notificationCount: 1,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Mood Selector
              MoodSelector(
                selectedMood: selectedMood,
                onMoodSelected: (mood) {
                  ref.read(selectedMoodProvider.notifier).state = mood;
                },
                onViewHistory: () => context.push(AppRoutes.moodTracker),
              ),

              const SizedBox(height: AppTheme.spacing2xl),

              // Daily Quote Card
              DailyQuoteCard(
                quote: s.sampleQuote,
                author: s.sampleQuoteAuthor,
              ),

              const SizedBox(height: AppTheme.spacing2xl),

              // Recommendations Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
                child: Text(
                  s.recommendedForYou,
                  style: AppTypography.headingMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textLight,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Upcoming Session Card
              SessionCard(
                title: s.upcomingSession,
                dateTime: '${s.thursday}، 5:00 م',
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // Meditation Card
              MeditationCard(
                title: s.breatheDeeply,
                description: s.shortSession,
                category: s.meditation,
                imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400',
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Chat CTA Card
              ChatCtaCard(
                onStartChat: () => context.push(AppRoutes.chat),
              ),

              const SizedBox(height: AppTheme.spacing3xl),
            ],
          ),
        ),
      ),
    );
  }
}
