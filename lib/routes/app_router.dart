import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/home/home_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/screens/user_chat_list_screen.dart';
import '../features/mood/mood_tracker_screen.dart';
import '../features/community/community_screen.dart';
import '../features/therapists/therapist_list_screen.dart';
import '../features/therapists/therapist_profile_screen.dart';
import '../features/therapists/screens/therapy_selection_screen.dart';
import '../features/booking/screens/user_bookings_screen.dart';
import '../features/booking/screens/call/call_history_screen.dart';
import '../features/content/screens/psychological_tests_screen.dart';
import '../features/content/screens/blog_screen.dart';
import '../features/content/screens/podcast_screen.dart';
import '../features/content/screens/exercises_screen.dart';
import '../features/content/screens/all_content_screen.dart';
import '../features/content/providers/youtube_provider.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/profile_completion_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/more/more_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/subscription/screens/subscription_screen.dart';
import '../features/subscription/screens/payment_method_screen.dart';
import '../features/subscription/screens/apple_pay_screen.dart';
import '../features/subscription/screens/card_payment_screen.dart';
import '../features/subscription/screens/google_pay_screen.dart';
import '../features/subscription/screens/paypal_payment_screen.dart';
import '../features/subscription/screens/bank_transfer_screen.dart';
import '../features/subscription/screens/receipt_upload_screen.dart';
import '../features/subscription/screens/freemius_checkout_screen.dart';
import '../features/subscription/screens/payment_success_screen.dart';
import '../features/subscription/screens/subscription_history_screen.dart';
import '../features/subscription/models/subscription_product.dart';
import '../features/subscription/models/payment_route_args.dart';
import '../features/admin/screens/users_list_screen.dart';
import '../features/admin/screens/verification_list_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/cms/content_management_screen.dart';
import '../features/admin/screens/cms/quotes_management_screen.dart';
import '../features/admin/screens/cms/challenges_management_screen.dart';
import '../features/admin/screens/cms/faqs_management_screen.dart';
import '../features/admin/screens/cms/static_pages_screen.dart';
import '../features/admin/screens/therapists_list_screen.dart';
import '../features/admin/screens/therapist_detail_screen.dart';
import '../features/admin/screens/bookings_list_screen.dart';
import '../features/admin/screens/moderation_dashboard.dart';
import '../features/admin/screens/admin_settings_screen.dart';
import '../features/admin/screens/admin_chat_list_screen.dart';
import '../features/admin/screens/data_management_screen.dart';
import '../features/admin/screens/admin_chat_detail_screen.dart';
import '../features/admin/screens/payments_overview_screen.dart';
import '../features/admin/screens/analytics_screen.dart';
import '../features/admin/screens/reports_screen.dart';
import '../features/admin/screens/clinic_patient_profile_screen.dart';
import '../features/admin/services/admin_chat_service.dart'; // For type ChatThread
import '../features/therapist_portal/models/therapist_profile.dart'; // Import for casting extra
import '../features/admin/widgets/clinic_shell.dart';
import '../features/admin/screens/cms/psych_tests_management_screen.dart';

import '../core/theme/app_colors.dart';
import '../core/l10n/language_provider.dart';
import '../features/notifications/notification_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/reviews/screens/leave_review_screen.dart';
import '../features/therapist_portal/screens/therapist_registration_screen.dart';
import '../features/therapist_portal/screens/pending_approval_screen.dart';
import '../features/therapist_portal/screens/therapist_dashboard_screen.dart';
import '../features/therapist_portal/screens/therapist_bookings_screen.dart';
import '../features/therapist_portal/screens/therapist_assigned_patients_screen.dart';
import '../features/therapist_portal/screens/therapist_patient_detail_screen.dart';
import '../features/therapist_portal/screens/therapist_availability_screen.dart';
import '../features/therapist_portal/screens/booking_detail_screen.dart';
import '../features/therapist_portal/screens/therapist_profile_edit_screen.dart';
import '../features/therapist_portal/screens/therapist_settings_screen.dart';
import '../features/therapist_portal/models/therapist_booking.dart';
import '../features/therapist_chat/screens/therapist_chat_list_screen.dart';
import '../features/therapist_chat/screens/therapist_chat_detail_screen.dart';
import '../features/therapist_chat/screens/user_therapist_chat_screen.dart';
import '../features/therapist_chat/models/therapist_chat.dart';
import '../features/chat/screens/user_support_chat_screen.dart';
import '../features/crisis/screens/crisis_response_screen.dart';
import '../features/admin/screens/crisis_alerts_screen.dart';
import '../features/chat/screens/hybrid_chat_screen.dart';
import '../features/more/faq_screen.dart';
import '../features/more/static_page_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/admin/screens/clinic_report_viewer_screen.dart';
import '../features/admin/screens/ai_analytics_screen.dart';
import '../features/common/screens/maintenance_screen.dart';
import '../features/common/screens/force_update_screen.dart';
import '../core/providers/system_settings_provider.dart';
import '../core/services/app_version_gate.dart';
import 'app_routes.dart';
export 'app_routes.dart';

// AppRoutes moved to app_routes.dart

/// Listenable for router refresh on auth state + system settings changes
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status ||
          previous?.userRole != next.userRole ||
          previous?.therapistStatus != next.therapistStatus) {
        notifyListeners();
      }
    });
    ref.listen(systemSettingsProvider, (previous, next) {
      final prevMode = previous?.valueOrNull?.maintenanceMode;
      final nextMode = next.valueOrNull?.maintenanceMode;
      final prevMin = previous?.valueOrNull?.minAppVersion;
      final nextMin = next.valueOrNull?.minAppVersion;
      if (prevMode != nextMode || prevMin != nextMin) {
        notifyListeners();
      }
    });
    // Re-evaluate the redirect once the device version has loaded.
    ref.listen(appVersionProvider, (previous, next) {
      if (previous != next) {
        notifyListeners();
      }
    });
  }
}

/// Global navigator key for context-less navigation (e.g., from notifications)
final navigatorKey = GlobalKey<NavigatorState>();

/// Router configuration with auth guards
final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = AuthRefreshListenable(ref);

  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentLocation = state.uri.path;
      final isAuthRoute = currentLocation.startsWith('/auth');
      final isPublicRoute = AppRoutes.isPublicRoute(currentLocation);
      final isTherapistRoute = AppRoutes.isTherapistRoute(currentLocation);
      final isSplash = currentLocation == AppRoutes.splash;

      // Always allow splash screen
      if (isSplash) {
        return null;
      }

      // Force update gate: blocks ALL users (including admins) when the
      // installed version is below min_app_version in Firestore.
      if (currentLocation != AppRoutes.forceUpdate) {
        final mustUpdate = ref.read(requiresUpdateProvider);
        if (mustUpdate) {
          return AppRoutes.forceUpdate;
        }
      }

      // Maintenance mode: block non-admin users
      if (currentLocation != AppRoutes.maintenance) {
        final settings = ref.read(systemSettingsProvider).valueOrNull;
        if (settings?.maintenanceMode == true && !authState.isAdmin) {
          return AppRoutes.maintenance;
        }
      }

      // Allow initial state to access public routes (during app startup)
      if (authState.status == AuthStatus.initial) {
        if (isPublicRoute || isAuthRoute) {
          return null;
        }
        // Don't redirect yet, wait for auth to initialize
        return null;
      }

      // Allow guest users to access public routes
      if (authState.status == AuthStatus.unauthenticated) {
        // If trying to access protected route, redirect to login
        if (!isPublicRoute && !isAuthRoute) {
          return AppRoutes.login;
        }
        // Allow access to public routes and auth routes
        return null;
      }

      // Handle profiles that are technically incomplete but give them access to the home screen
      // (We will prompt them within the Home screen instead of a forced redirect)
      if (authState.status == AuthStatus.profileIncomplete) {
        // Gated features: Community, Subscriptions, and Chat require a complete profile
        if (currentLocation == AppRoutes.community ||
            currentLocation == AppRoutes.subscription ||
            currentLocation == AppRoutes.chat ||
            currentLocation == AppRoutes.userSupportChat ||
            currentLocation.startsWith('/chat/')) {
          return AppRoutes.profileCompletion;
        }
        // No forced redirect for other routes like home
      }

      // Handle therapist portal routes
      if (isTherapistRoute && authState.status == AuthStatus.authenticated) {
        final isTherapist = authState.isTherapist;
        final therapistStatus = authState.therapistStatus;

        // Non-therapists trying to access therapist routes
        if (!isTherapist) {
          // Allow access to registration screen for anyone authenticated
          if (currentLocation == AppRoutes.therapistRegister) {
            return null;
          }
          return AppRoutes.home;
        }

        // Therapist status-based redirects
        if (therapistStatus == TherapistApprovalStatus.pending) {
          // Pending therapists can only access pending screen
          if (currentLocation != AppRoutes.therapistPending) {
            return AppRoutes.therapistPending;
          }
        } else if (therapistStatus == TherapistApprovalStatus.rejected) {
          // Rejected therapists can only access rejected screen
          if (currentLocation != AppRoutes.therapistRejected) {
            return AppRoutes.therapistRejected;
          }
        } else if (therapistStatus == TherapistApprovalStatus.approved) {
          // Approved therapists should not access pending/rejected screens
          if (currentLocation == AppRoutes.therapistPending ||
              currentLocation == AppRoutes.therapistRejected ||
              currentLocation == AppRoutes.therapistRegister) {
            return AppRoutes.therapistDashboard;
          }
        }

        return null;
      }

      // Redirect approved therapists from home to their dashboard
      if (authState.status == AuthStatus.authenticated &&
          authState.isApprovedTherapist &&
          currentLocation == AppRoutes.home) {
        return AppRoutes.therapistDashboard;
      }

      // Redirect admins from home to their dashboard
      if (authState.status == AuthStatus.authenticated &&
          authState.isAdmin &&
          currentLocation == AppRoutes.home) {
        return AppRoutes.adminDashboard;
      }

      // Redirect profileIncomplete users on auth screens to profile completion
      if (authState.status == AuthStatus.profileIncomplete && isAuthRoute) {
        return AppRoutes.profileCompletion;
      }

      // Redirect authenticated users away from auth screens
      if (authState.status == AuthStatus.authenticated) {
        if (isAuthRoute ||
            currentLocation == AppRoutes.login ||
            currentLocation == AppRoutes.signup) {
          // Determine target based on role
          if (authState.isAdmin) {
            return AppRoutes.adminDashboard;
          }
          if (authState.isApprovedTherapist) {
            return AppRoutes.therapistDashboard;
          }
          return AppRoutes.home;
        }
      }

      // 5. Admin route protection
      if (state.matchedLocation.startsWith('/admin')) {
        if (!authState.isAdmin) {
          return AppRoutes.home;
        }
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

      // Maintenance route (public, no auth required)
      GoRoute(
        path: AppRoutes.maintenance,
        name: 'maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),

      // Force update gate (public, blocks all users when version is too old)
      GoRoute(
        path: AppRoutes.forceUpdate,
        name: 'forceUpdate',
        builder: (context, state) => const ForceUpdateScreen(),
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
        path: AppRoutes.otpVerification,
        name: 'otpVerification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpVerificationScreen(
            phoneNumber: extra?['phoneNumber'] ?? '',
            verificationId: extra?['verificationId'] ?? '',
            isSignUp: extra?['isSignUp'] ?? false,
            firstName: extra?['firstName'],
            lastName: extra?['lastName'],
            whatsappNumber: extra?['whatsappNumber'],
            whatsappConsent: extra?['whatsappConsent'],
          );
        },
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
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
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
        path: AppRoutes.bookings,
        name: 'bookings',
        builder: (context, state) => const UserBookingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.callHistory,
        name: 'callHistory',
        builder: (context, state) => const CallHistoryScreen(),
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
      GoRoute(
        path: AppRoutes.therapySelection,
        name: 'therapySelection',
        builder: (context, state) => const TherapySelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.psychologicalTests,
        name: 'psychologicalTests',
        builder: (context, state) => const PsychologicalTestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.blog,
        name: 'blog',
        builder: (context, state) => const BlogScreen(),
      ),
      GoRoute(
        path: AppRoutes.podcast,
        name: 'podcast',
        builder: (context, state) => const PodcastScreen(),
      ),
      GoRoute(
        path: AppRoutes.exercises,
        name: 'exercises',
        builder: (context, state) => const ExercisesScreen(),
      ),
      GoRoute(
        path: AppRoutes.sanadTube,
        name: 'sanadTube',
        builder: (context, state) => AllContentScreen(
          title: 'سند تيوب',
          icon: Icons.play_circle_rounded,
          iconColor: Colors.redAccent,
          provider: sanadTubeProvider,
          isYouTube: true,
          showPlayIcon: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.sanadPodcast,
        name: 'sanadPodcast',
        builder: (context, state) => AllContentScreen(
          title: 'سند بودكاست',
          icon: Icons.podcasts_rounded,
          iconColor: Colors.red,
          provider: sanadPodcastProvider,
          isYouTube: true,
          showPlayIcon: true,
        ),
      ),

      // Static pages
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacyPolicy',
        builder: (context, state) =>
            const StaticPageScreen(pageType: StaticPageType.privacy),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        name: 'termsOfService',
        builder: (context, state) =>
            const StaticPageScreen(pageType: StaticPageType.terms),
      ),
      GoRoute(
        path: AppRoutes.knowYourRights,
        name: 'knowYourRights',
        builder: (context, state) =>
            const StaticPageScreen(pageType: StaticPageType.knowYourRights),
      ),
      GoRoute(
        path: AppRoutes.aboutSanad,
        name: 'aboutSanad',
        builder: (context, state) =>
            const StaticPageScreen(pageType: StaticPageType.about),
      ),
      GoRoute(
        path: AppRoutes.faqs,
        name: 'faqs',
        builder: (context, state) => const FaqScreen(),
      ),

      // Payment routes
      GoRoute(
        path: AppRoutes.subscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/subscription-history',
        name: 'subscriptionHistory',
        builder: (context, state) => const SubscriptionHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethod,
        name: 'paymentMethod',
        builder: (context, state) {
          final extra = state.extra;
          final product = extra is SubscriptionProduct
              ? extra
              : SubscriptionProduct.fromJson(extra as Map<String, dynamic>);
          return PaymentMethodScreen(product: product);
        },
      ),
      GoRoute(
        path: AppRoutes.googlePayPayment,
        name: 'googlePayPayment',
        builder: (context, state) {
          final args = PaymentRouteArgs.fromExtra(state.extra);
          return GooglePayScreen(
            product: args.product,
            bookingId: args.bookingId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paypalPayment,
        name: 'paypalPayment',
        builder: (context, state) {
          final args = PaymentRouteArgs.fromExtra(state.extra);
          return PayPalPaymentScreen(
            product: args.product,
            bookingId: args.bookingId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cardPayment,
        name: 'cardPayment',
        builder: (context, state) {
          final args = PaymentRouteArgs.fromExtra(state.extra);
          return CardPaymentScreen(product: args.product);
        },
      ),
      GoRoute(
        path: AppRoutes.applePayPayment,
        name: 'applePayPayment',
        builder: (context, state) {
          final args = PaymentRouteArgs.fromExtra(state.extra);
          return ApplePayScreen(
            product: args.product,
            bookingId: args.bookingId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.freemiusPayment,
        name: 'freemiusPayment',
        builder: (context, state) {
          final args = PaymentRouteArgs.fromExtra(state.extra);
          return FreemiusCheckoutScreen(
            product: args.product,
            bookingId: args.bookingId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bankTransfer,
        name: 'bankTransfer',
        builder: (context, state) {
          final extra = state.extra;
          final product = extra is SubscriptionProduct
              ? extra
              : SubscriptionProduct.fromJson(extra as Map<String, dynamic>);
          return BankTransferScreen(product: product);
        },
      ),
      GoRoute(
        path: AppRoutes.receiptUpload,
        name: 'receiptUpload',
        builder: (context, state) {
          final paymentId = state.extra as String? ?? '';
          return ReceiptUploadScreen(paymentId: paymentId);
        },
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        name: 'paymentSuccess',
        builder: (context, state) => const PaymentSuccessScreen(),
      ),

      // Hybrid chat route
      GoRoute(
        path: AppRoutes.hybridChat,
        name: 'hybridChat',
        builder: (context, state) => const HybridChatScreen(),
      ),

      // Crisis response route
      GoRoute(
        path: AppRoutes.crisisResponse,
        name: 'crisisResponse',
        builder: (context, state) => const CrisisResponseScreen(),
      ),

      // AI Insights — user-facing (protected, no admin chrome)
      GoRoute(
        path: AppRoutes.insights,
        name: 'insights',
        builder: (context, state) => const InsightsScreen(),
      ),

      // Review route
      GoRoute(
        path: AppRoutes.leaveReview,
        name: 'leaveReview',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return LeaveReviewScreen(
            bookingId: data?['bookingId'] ?? '',
            therapistId: data?['therapistId'] ?? '',
            therapistName: data?['therapistName'] ?? '',
            therapistPhoto: data?['therapistPhoto'],
            initialRating: data?['initialRating'] as int?,
          );
        },
      ),

      // Therapist portal routes
      GoRoute(
        path: AppRoutes.therapistRegister,
        name: 'therapistRegister',
        builder: (context, state) => const TherapistRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistPending,
        name: 'therapistPending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistRejected,
        name: 'therapistRejected',
        builder: (context, state) => const RejectedScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistDashboard,
        name: 'therapistDashboard',
        builder: (context, state) => const TherapistDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistPatients,
        name: 'therapistPatients',
        builder: (context, state) => const TherapistAssignedPatientsScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistPatientDetail,
        name: 'therapistPatientDetail',
        builder: (context, state) => TherapistPatientDetailScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.therapistProfileEdit,
        name: 'therapistProfileEdit',
        builder: (context, state) => const TherapistProfileEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistSettings,
        name: 'therapistSettings',
        builder: (context, state) => const TherapistSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistAvailability,
        name: 'therapistAvailability',
        builder: (context, state) => const TherapistAvailabilityScreen(),
      ),
      GoRoute(
        path: AppRoutes.therapistBookings,
        name: 'therapistBookings',
        builder: (context, state) => const TherapistBookingsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.therapistBookingDetail}/:id',
        name: 'therapistBookingDetail',
        builder: (context, state) {
          final bookingId = state.pathParameters['id'] ?? '';
          final booking = state.extra as TherapistBooking?;
          return BookingDetailScreen(
            bookingId: bookingId,
            initialBooking: booking,
          );
        },
      ),

      // Therapist Messages Routes
      GoRoute(
        path: AppRoutes.therapistMessages,
        name: 'therapistMessages',
        builder: (context, state) => const TherapistChatListScreen(),
      ),
      GoRoute(
        path: '/therapist/messages/:chatId',
        name: 'therapistChatDetail',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          final thread = state.extra as TherapistChatThread?;
          return TherapistChatDetailScreen(
            chatId: chatId,
            initialThread: thread,
          );
        },
      ),

      // User Therapist Chat Route
      GoRoute(
        path: '/chat/therapist/:chatId',
        name: 'userTherapistChat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          final thread = state.extra as TherapistChatThread?;
          return UserTherapistChatScreen(chatId: chatId, initialThread: thread);
        },
      ),

      // User Support Chat Route (for admin escalation)
      GoRoute(
        path: AppRoutes.userSupportChat,
        name: 'userSupportChat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return UserSupportChatScreen(
            aiContext: extra?['aiContext'] as String?,
          );
        },
      ),

      // Admin routes (Wrapped in AdminShell)
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            name: 'adminDashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminVerifications,
            name: 'adminVerifications',
            builder: (context, state) => const VerificationListScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminCrisisAlerts,
            name: 'adminCrisisAlerts',
            builder: (context, state) => const CrisisAlertsScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            name: 'adminUsers',
            builder: (context, state) => const UsersListScreen(),
            routes: [
              GoRoute(
                path: ':userId',
                name: 'adminUserDetails',
                builder: (context, state) {
                  final userId = state.pathParameters['userId'] ?? '';
                  return ClinicPatientProfileScreen(userId: userId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/payments',
            name: 'adminPayments',
            builder: (context, state) => const PaymentsOverviewScreen(),
          ),
          GoRoute(
            path: '/admin/cms/quotes',
            name: 'adminQuotes',
            builder: (context, state) => const QuotesManagementScreen(),
          ),
          GoRoute(
            path: '/admin/cms/content',
            name: 'adminContent',
            builder: (context, state) => const ContentManagementScreen(),
          ),
          GoRoute(
            path: '/admin/cms/challenges',
            name: 'adminChallenges',
            builder: (context, state) => const ChallengesManagementScreen(),
          ),
          GoRoute(
            path: '/admin/cms/pages',
            name: 'adminStaticPages',
            builder: (context, state) => const StaticPagesScreen(),
          ),
          GoRoute(
            path: '/admin/cms/faqs',
            name: 'adminFaqs',
            builder: (context, state) => const FaqsManagementScreen(),
          ),
          GoRoute(
            path: '/admin/cms/psych-tests',
            name: 'adminPsychTests',
            builder: (context, state) => const PsychTestsManagementScreen(),
          ),
          GoRoute(
            path: '/admin/therapists',
            name: 'adminTherapists',
            builder: (context, state) => const TherapistsListScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                name: 'adminTherapistDetail',
                builder: (context, state) {
                  final therapist = state.extra as TherapistProfile;
                  return TherapistDetailScreen(therapist: therapist);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/bookings',
            name: 'adminBookings',
            builder: (context, state) => const BookingsListScreen(),
          ),
          GoRoute(
            path: '/admin/community',
            name: 'adminCommunity',
            builder: (context, state) => const ModerationDashboard(),
          ),
          GoRoute(
            path: '/admin/settings',
            name: 'adminSettings',
            builder: (context, state) => const AdminSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/chat',
            name: 'adminChat',
            builder: (context, state) => const AdminChatListScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                name: 'adminChatDetail',
                builder: (context, state) {
                  final thread = state.extra as ChatThread;
                  return AdminChatDetailScreen(thread: thread);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.adminDataManagement,
            name: 'adminDataManagement',
            builder: (context, state) => const DataManagementScreen(),
          ),
          GoRoute(
            path: '/admin/analytics',
            name: 'adminAnalytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminAiAnalytics,
            name: 'adminAiAnalytics',
            builder: (context, state) => const AiAnalyticsScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            name: 'adminReports',
            builder: (context, state) => const ReportsScreen(),
          ),
          // AI — patient report viewer (/admin/patients/reports?userId=...)
          GoRoute(
            path: AppRoutes.adminPatientReports,
            name: 'adminPatientReports',
            builder: (context, state) {
              final userId =
                  state.uri.queryParameters['userId'] ?? '';
              return ClinicReportViewerScreen(userId: userId);
            },
          ),
        ],
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
    const TherapySelectionScreen(), // Selection screen as entry point to therapists
    const UserChatListScreen(),
    const CommunityScreen(),
    const MoreScreen(),
  ];

  /// Handle tab selection with guest mode check
  void _onTabSelected(int index) {
    // Profile tab requires login - moved to More Screen items
    // if (index == 4 && !_isAuthenticated) { ... }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavBar(s),
    );
  }

  Widget _buildBottomNavBar(dynamic s) {
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
                label: s.navHome,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.medical_services_outlined,
                label: s.navTherapists,
                index: 1,
              ),
              _buildFloatingMessageButton(),
              _buildNavItem(
                icon: Icons.people_outline_rounded,
                label: s.navCommunity,
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.menu_rounded,
                label: s.navMore,
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
    const activeColor = AppColors.primary;
    const inactiveColor = AppColors.navInactive;

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

  Widget _buildFloatingMessageButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _currentIndex == 2;

    return GestureDetector(
      onTap: () => _onTabSelected(2),
      child: Transform.translate(
        offset: const Offset(0, -24),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              width: 4,
            ),
          ),
          child: Icon(
            isActive
                ? Icons.chat_bubble_rounded
                : Icons.chat_bubble_outline_rounded,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
