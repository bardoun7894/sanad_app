import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../routes/app_routes.dart';
import '../../booking/screens/user_bookings_screen.dart';
import '../models/therapist.dart';
import '../widgets/therapy_type_card.dart';
import '../providers/therapist_provider.dart';
import '../widgets/therapy_intake_sheet.dart';

class TherapySelectionScreen extends ConsumerStatefulWidget {
  const TherapySelectionScreen({super.key});

  @override
  ConsumerState<TherapySelectionScreen> createState() =>
      _TherapySelectionScreenState();
}

class _TherapySelectionScreenState extends ConsumerState<TherapySelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for external tab switch requests (e.g. from booking completion)
    ref.listen(bookingsTabTriggerProvider, (previous, next) {
      if (next != null) {
        _tabController.animateTo(next);
        // Reset the trigger
        ref.read(bookingsTabTriggerProvider.notifier).state = null;
      }
    });

    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.selectTherapyType),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            Tab(text: s.findTherapist),
            Tab(text: s.myBookings),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe to avoid accidental switch
        children: const [_SelectionContent(), UserBookingsScreen(embed: true)],
      ),
    );
  }
}

class _SelectionContent extends ConsumerStatefulWidget {
  const _SelectionContent();

  @override
  ConsumerState<_SelectionContent> createState() => _SelectionContentState();
}

class _SelectionContentState extends ConsumerState<_SelectionContent> {
  TherapyType? _selectedType;

  void _showIntakeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TherapyIntakeSheet(
        selectedType: _selectedType!,
        onConfirm: (issues, note) {
          // Set filters in provider
          ref
              .read(therapistProvider.notifier)
              .clearFilters(); // Clear previous filters first
          ref.read(therapistProvider.notifier).setTherapyType(_selectedType);
          ref.read(therapistProvider.notifier).setIntakeData(issues, note);

          // Navigate to therapist list
          context.push(AppRoutes.therapists);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.selectTherapyTypeSubtitle,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ...TherapyType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Hero(
                      tag: 'therapy_card_${type.name}',
                      child: TherapyTypeCard(
                        type: type,
                        isSelected: _selectedType == type,
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                // Add extra padding at bottom specifically for scrolling
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // Fixed bottom button
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedType != null ? _showIntakeSheet : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  s.continueText,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
