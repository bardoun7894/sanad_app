import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/mood/mood_tracker_screen.dart';
import '../features/mood/widgets/log_mood_sheet.dart';
import '../features/mood/providers/mood_tracker_provider.dart';
import '../features/community/community_screen.dart';
import '../features/community/widgets/create_post_sheet.dart';
import '../features/community/providers/community_provider.dart';
import '../features/therapists/therapist_list_screen.dart';
import '../features/therapists/therapist_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../core/widgets/quick_actions_menu.dart';
import '../core/models/quick_action_config.dart';
import '../core/providers/quick_actions_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/language_provider.dart';

// Route names
class AppRoutes {
  static const String home = '/';
  static const String schedule = '/schedule';
  static const String add = '/add';
  static const String content = '/content';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String moodTracker = '/mood-tracker';
  static const String community = '/community';
  static const String therapists = '/therapists';
  static const String therapistProfile = '/therapist-profile';
}

// Router configuration
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const MainScaffold(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      name: 'notifications',
      builder: (context, state) => const _PlaceholderScreen(title: 'Notifications'),
    ),
    GoRoute(
      path: AppRoutes.chat,
      name: 'chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.moodTracker,
      name: 'moodTracker',
      builder: (context, state) => const MoodTrackerScreen(),
    ),
    GoRoute(
      path: AppRoutes.community,
      name: 'community',
      builder: (context, state) => const CommunityScreen(),
    ),
    GoRoute(
      path: AppRoutes.therapists,
      name: 'therapists',
      builder: (context, state) => const TherapistListScreen(),
    ),
    GoRoute(
      path: AppRoutes.therapistProfile,
      name: 'therapistProfile',
      builder: (context, state) => const TherapistProfileScreen(),
    ),
  ],
);

// Main scaffold with bottom navigation
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TherapistListScreen(),
    SizedBox(), // Placeholder - center button shows menu instead
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2937)
            : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -8),
            blurRadius: 30,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'الرئيسية',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.medical_services_outlined,
                label: 'المعالجين',
                index: 1,
              ),
              _buildCenterButton(),
              _buildNavItem(
                icon: Icons.people_outline_rounded,
                label: 'المجتمع',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'الملف',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    const activeColor = Color(0xFF2563EB);
    const inactiveColor = Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Execute a specific action type
  void _executeAction(QuickActionType type) {
    HapticFeedback.mediumImpact();

    switch (type) {
      case QuickActionType.logMood:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => LogMoodSheet(
            onSave: (mood, note) {
              ref.read(moodTrackerProvider.notifier).logMood(mood, note: note);
            },
          ),
        );
        break;

      case QuickActionType.startChat:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
        break;

      case QuickActionType.newPost:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => CreatePostSheet(
            onPost: (content, category, isAnonymous) {
              ref.read(communityProvider.notifier).addPost(
                content,
                category,
                isAnonymous: isAnonymous,
              );
            },
          ),
        );
        break;

      case QuickActionType.bookSession:
        setState(() => _currentIndex = 1); // Go to Therapists tab
        break;

      case QuickActionType.moodHistory:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MoodTrackerScreen()),
        );
        break;

      case QuickActionType.findTherapist:
        setState(() => _currentIndex = 1); // Go to Therapists tab
        break;

      case QuickActionType.emergency:
        _showEmergencyDialog();
        break;
    }
  }

  void _showEmergencyDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.read(stringsProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Icon(Icons.emergency_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.crisisSupport,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          s.crisisMessage,
          style: TextStyle(
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.close),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeAction(QuickActionType.startChat);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(s.talkToSomeone, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsMenu() {
    HapticFeedback.mediumImpact();
    final state = ref.read(quickActionsProvider);

    final actions = state.visibleActions.map((config) {
      return QuickAction(
        label: QuickActionConfig.getLabel(config.type),
        icon: QuickActionConfig.getIcon(config.type),
        color: QuickActionConfig.getColor(config.type),
        onTap: () => _executeAction(config.type),
      );
    }).toList();

    showQuickActionsMenu(context, actions);
  }

  Widget _buildCenterButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(quickActionsProvider);

    return GestureDetector(
      onTap: () => _executeAction(state.primaryAction),
      onLongPress: _showQuickActionsMenu,
      child: Transform.translate(
        offset: const Offset(0, -24),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              width: 4,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Placeholder screen for tabs that aren't implemented yet
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF3F6F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 64,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
