import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/l10n/language_provider.dart';
import '../models/content_models.dart';
import '../providers/content_provider.dart';
import 'content_detail_screen.dart';
import '../../../core/widgets/loading_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.exercises,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: exercisesAsync.when(
        loading: () => LoadingStateWidget(message: s.loadingContent),
        error: (e, _) => ErrorStateWidget(
          message: s.errorLoadingData,
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(exercisesProvider),
        ),
        data: (exercises) {
          if (exercises.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.fitness_center_outlined,
              message: s.noContentYet,
              description: s.contentComingSoon,
              iconColor: Colors.green,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(exercisesProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: exercises.length,
              itemBuilder: (context, index) =>
                  _buildExerciseCard(context, exercises[index], isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ContentItem item,
    bool isDark,
  ) {
    final hasThumbnail =
        item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ContentDetailScreen(item: item)),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasThumbnail)
                    Image.network(
                      item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildPlaceholderImage(isDark),
                    )
                  else
                    _buildPlaceholderImage(isDark),
                  if (item.formattedDuration.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 10,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.formattedDuration,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category!,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      item.localizedTitle(context),
                      style: AppTypography.headingSmall.copyWith(
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Flexible(
                      child: Text(
                        item.localizedDescription(context),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildPlaceholderImage(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF312E81), const Color(0xFF1F2937)]
              : [
                  Colors.green.withValues(alpha: 0.12),
                  Colors.green.withValues(alpha: 0.04),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.fitness_center_outlined,
          size: 32,
          color: Colors.green.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
