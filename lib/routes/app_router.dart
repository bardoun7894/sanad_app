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
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/profile_completion_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/subscription/screens/subscription_screen.dart';
import '../features/subscription/screens/payment_method_screen.dart';
import '../features/subscription/screens/card_payment_screen.dart';
import '../features/subscription/screens/bank_transfer_screen.dart';
import '../features/subscription/screens/receipt_upload_screen.dart';
import '../features/subscription/screens/payment_success_screen.dart';
import '../features/admin/screens/verification_list_screen.dart';
import '../core/widgets/quick_actions_menu.dart';
import '../core/widgets/login_prompt.dart';
import '../core/models/quick_action_config.dart';
import '../core/providers/quick_actions_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/language_provider.dart';
import '../features/notifications/notification_screen.dart';
import '../features/splash/splash_screen.dart';

// Route names
class AppRoutes {
  // Auth routes
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String forgotPassword = '/auth/forgot-password';
  static const String profileCompletion = '/auth/profile-completion';

  // App routes
  static const String splash = '/splash';
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

  // Payment routes
  static const String subscription = '/subscription';
  static const String paymentMethod = '/payment-method';
  static const String cardPayment = '/card-payment';
  static const String bankTransfer = '/bank-transfer';
  static const String receiptUpload = '/receipt-upload';
  static const String paymentSuccess = '/payment-success';

  // Admin routes
  static const String adminVerifications = '/admin/verifications';

  // Public routes (accessible without login)
  static const List<String> publicRoutes = [
    splash,
    home,
    therapists,
    therapistProfile,
    community,
    login,
    signup,
    forgotPassword,
  ];

  // Protected routes (require login)
  static const List<String> protectedRoutes = [
    chat,
    moodTracker,
    profile,
    notifications,
    subscription,
    paymentMethod,
    cardPayment,
    bankTransfer,
    receiptUpload,
    paymentSuccess,
    adminVerifications,
  ];

  /// Check if a route is public (accessible without login)
  static bool isPublicRoute(String path) {
    return publicRoutes.any(
      (route) => path == route || path.startsWith('/auth'),
    );
  }
}

/// Helper class for GoRouter refresh on auth state changes

/// Router configuration with auth guards
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentLocation = state.uri.path;
      final isAuthRoute = currentLocation.startsWith('/auth');
      final isPublicRoute = AppRoutes.isPublicRoute(currentLocation);

      // Allow guest users to access public routes
      if (authState.status == AuthStatus.unauthenticated) {
        // If trying to access protected route, redirect to login
        if (!isPublicRoute && !isAuthRoute) {
          return AppRoutes.login;
        }
        // Allow access to public routes and auth routes
        return null;
      }

      // Redirect authenticated users with incomplete profile
      if (authState.status == AuthStatus.profileIncomplete &&
          currentLocation != AppRoutes.profileCompletion) {
        return AppRoutes.profileCompletion;
      }

      // Redirect authenticated users away from auth screens
      if (authState.status == AuthStatus.authenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash route
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes (public)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileCompletion,
        name: 'profileCompletion',
        builder: (context, state) => const ProfileCompletionScreen(),
      ),

      // App routes (protected)
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
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

      // Payment routes
      GoRoute(
        path: AppRoutes.subscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethod,
        name: 'paymentMethod',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentMethodScreen(product: extra?['product']);
        },
      ),
      GoRoute(
        path: AppRoutes.cardPayment,
        name: 'cardPayment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CardPaymentScreen(product: extra?['product']);
        },
      ),
      GoRoute(
        path: AppRoutes.bankTransfer,
        name: 'bankTransfer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BankTransferScreen(product: extra?['product']);
        },
      ),
      GoRoute(
        path: AppRoutes.receiptUpload,
        name: 'receiptUpload',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ReceiptUploadScreen(paymentId: extra?['paymentId'] ?? '');
        },
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        name: 'paymentSuccess',
        builder: (context, state) => const PaymentSuccessScreen(),
      ),

      // Admin routes
      GoRoute(
        path: AppRoutes.adminVerifications,
        name: 'adminVerifications',
        builder: (context, state) => const VerificationListScreen(),
      ),
    ],
  );

  // Trigger refresh when auth state changes
  ref.listen(authProvider, (_, _) {
    router.refresh();
  });

  return router;
});

// Main scaffold with bottom navigation
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const HomeScreen(),
    const TherapistListScreen(),
    const SizedBox(), // Placeholder - center button shows menu instead
    const CommunityScreen(),
    _buildProfileScreen(),
  ];

  /// Build profile screen - shows guest screen if not authenticated
  Widget _buildProfileScreen() {
    final authState = ref.watch(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      return const ProfileScreen();
    }
    return const _GuestProfileScreen();
  }

  /// Check if user is authenticated
  bool get _isAuthenticated {
    final authState = ref.read(authProvider);
    return authState.status == AuthStatus.authenticated;
  }

  /// Handle tab selection with guest mode check
  void _onTabSelected(int index) {
    // Profile tab requires login
    if (index == 4 && !_isAuthenticated) {
      final s = ref.read(stringsProvider);
      showLoginPrompt(
        context,
        feature: s.navProfile,
        description: s.loginToViewProfile,
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
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
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: isActive ? activeColor : inactiveColor),
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
  void _executeAction(QuickActionType type) async {
    HapticFeedback.mediumImpact();
    final s = ref.read(stringsProvider);

    // Actions that require authentication
    final authRequiredActions = [
      QuickActionType.logMood,
      QuickActionType.startChat,
      QuickActionType.newPost,
      QuickActionType.bookSession,
      QuickActionType.moodHistory,
    ];

    // Check authentication for protected actions
    if (authRequiredActions.contains(type) && !_isAuthenticated) {
      String feature;
      String description;

      switch (type) {
        case QuickActionType.logMood:
        case QuickActionType.moodHistory:
          feature = s.moodTracker;
          description = s.loginToTrackMood;
          break;
        case QuickActionType.startChat:
          feature = s.chatTitle;
          description = s.loginToChat;
          break;
        case QuickActionType.newPost:
          feature = s.community;
          description = s.loginToPost;
          break;
        case QuickActionType.bookSession:
          feature = s.navTherapists;
          description = s.loginToBook;
          break;
        default:
          feature = '';
          description = '';
      }

      await showLoginPrompt(
        context,
        feature: feature,
        description: description,
      );
      return;
    }

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
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
        break;

      case QuickActionType.newPost:
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => CreatePostSheet(
            onPost: (content, category, isAnonymous) {
              ref
                  .read(communityProvider.notifier)
                  .addPost(content, category, isAnonymous: isAnonymous);
            },
          ),
        );
        break;

      case QuickActionType.bookSession:
        setState(() => _currentIndex = 1); // Go to Therapists tab
        break;

      case QuickActionType.moodHistory:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MoodTrackerScreen()));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              s.talkToSomeone,
              style: const TextStyle(color: Colors.white),
            ),
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
          child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
        ),
      ),
    );
  }
}

/// Guest profile screen shown when user is not logged in
class _GuestProfileScreen extends ConsumerWidget {
  const _GuestProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF3F6F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Guest avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Welcome text
              Text(
                s.guestWelcome,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                s.guestDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.textDark : AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    s.signIn,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sign up button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.signup),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    s.createAccount,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Explore as guest text
              Text(
                s.exploreAsGuest,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder screen for tabs that aren't implemented yet
