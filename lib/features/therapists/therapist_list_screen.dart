import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';
import '../../routes/app_router.dart';
import 'models/therapist.dart';
import 'providers/therapist_provider.dart';
import 'widgets/therapist_card.dart';

class TherapistListScreen extends ConsumerStatefulWidget {
  const TherapistListScreen({super.key});

  @override
  ConsumerState<TherapistListScreen> createState() => _TherapistListScreenState();
}

class _TherapistListScreenState extends ConsumerState<TherapistListScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(therapistProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _Header(
              onBack: () => Navigator.of(context).pop(),
              onFilter: () => setState(() => _showFilters = !_showFilters),
              hasActiveFilters: state.selectedSpecialty != null ||
                  state.selectedSessionType != null,
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
              child: _SearchBar(
                controller: _searchController,
                onChanged: (query) {
                  ref.read(therapistProvider.notifier).setSearchQuery(query);
                },
                isDark: isDark,
              ),
            ),

            // Filters
            if (_showFilters) ...[
              const SizedBox(height: 16),
              _FilterSection(
                selectedSpecialty: state.selectedSpecialty,
                selectedSessionType: state.selectedSessionType,
                onSpecialtySelected: (specialty) {
                  ref.read(therapistProvider.notifier).setSpecialty(specialty);
                },
                onSessionTypeSelected: (type) {
                  ref.read(therapistProvider.notifier).setSessionType(type);
                },
                onClearFilters: () {
                  ref.read(therapistProvider.notifier).clearFilters();
                  _searchController.clear();
                },
              ),
            ],

            const SizedBox(height: 16),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
              child: Row(
                children: [
                  Text(
                    '${state.filteredTherapists.length} ${s.therapistsFound}',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  if (state.filteredTherapists.any((t) => t.isAvailableToday))
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.availableToday,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Therapist list
            Expanded(
              child: state.filteredTherapists.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXl,
                      ),
                      itemCount: state.filteredTherapists.length,
                      itemBuilder: (context, index) {
                        final therapist = state.filteredTherapists[index];
                        return TherapistCard(
                          therapist: therapist,
                          onTap: () {
                            ref.read(selectedTherapistProvider.notifier).state =
                                therapist;
                            context.push(AppRoutes.therapistProfile);
                          },
                          onBookNow: () {
                            ref.read(selectedTherapistProvider.notifier).state =
                                therapist;
                            context.push(AppRoutes.therapistProfile);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onFilter;
  final bool hasActiveFilters;

  const _Header({
    required this.onBack,
    required this.onFilter,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();
    final s = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: 20,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              s.findTherapist,
              style: AppTypography.headingMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: onFilter,
                icon: Icon(
                  Icons.tune_rounded,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textDark : AppColors.textLight,
        ),
        decoration: InputDecoration(
          hintText: s.searchTherapist,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends ConsumerWidget {
  final Specialty? selectedSpecialty;
  final SessionType? selectedSessionType;
  final Function(Specialty?) onSpecialtySelected;
  final Function(SessionType?) onSessionTypeSelected;
  final VoidCallback onClearFilters;

  const _FilterSection({
    required this.selectedSpecialty,
    required this.selectedSessionType,
    required this.onSpecialtySelected,
    required this.onSessionTypeSelected,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Specialty filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Row(
            children: [
              Text(
                s.specialties,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const Spacer(),
              if (selectedSpecialty != null || selectedSessionType != null)
                GestureDetector(
                  onTap: onClearFilters,
                  child: Text(
                    s.categoryAll,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
            children: Specialty.values.map((specialty) {
              final isSelected = selectedSpecialty == specialty;
              final color = SpecialtyData.getColor(specialty);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSpecialtySelected(specialty);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? color.withValues(alpha: 0.3) : color)
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                    ),
                    child: Text(
                      SpecialtyData.getLabel(specialty, strings: s),
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.white)
                            : AppColors.textMuted,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Session type filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Text(
            s.sessionTypes,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? Colors.white : AppColors.textLight,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Row(
            children: SessionType.values.map((type) {
              final isSelected = selectedSessionType == type;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSessionTypeSelected(type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.primary)
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(AppTheme.radius2xl),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          SessionTypeData.getIcon(type),
                          size: 16,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.white)
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          SessionTypeData.getLabel(type, strings: s),
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.white)
                                : AppColors.textMuted,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.softBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.noTherapistsFound,
              style: AppTypography.headingSmall.copyWith(
                color: isDark ? Colors.white : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.adjustFilters,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
