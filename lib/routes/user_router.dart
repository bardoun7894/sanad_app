// User-only router — no admin routes.
// Used by lib/main_user.dart for the Play Store build.
// The full router (including admin) lives in app_router.dart.
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/chat/chat_screen.dart';
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
import '../features/therapist_portal/models/therapist_profile.dart';
import '../features/therapist_chat/screens/therapist_chat_list_screen.dart';
import '../features/therapist_chat/screens/therapist_chat_detail_screen.dart';
import '../features/therapist_chat/screens/user_therapist_chat_screen.dart';
import '../features/therapist_chat/models/therapist_chat.dart';
import '../features/chat/screens/user_support_chat_screen.dart';
import '../features/crisis/screens/crisis_response_screen.dart';
import '../features/chat/screens/hybrid_chat_screen.dart';
import '../features/more/faq_screen.dart';
import '../features/more/static_page_screen.dart';
import '../features/reviews/screens/leave_review_screen.dart';
import '../features/notifications/notification_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/insights/insights_screen.dart';
import '../features/common/screens/maintenance_screen.dart';
import '../core/providers/system_settings_provider.dart';
import 'app_routes.dart';
import 'app_router.dart' show MainScaffold;
export 'app_routes.dart';

/// Router refresh listenable for user app
class UserAuthRefreshListenable extends ChangeNotifier {
  UserAuthRefreshListenable(Ref ref) {
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
      if (prevMode != nextMode) {
        notifyListeners();
      }
    });
  }
}

/// Global navigator key (re-exported so main_user.dart can use it)
final userNavigatorKey = GlobalKey<NavigatorState>();

/// User-only router provider (no admin routes)
final userRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = UserAuthRefreshListenable(ref);

  final router = GoRouter(
    navigatorKey: userNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentLocation = state.uri.path;
      final isAuthRoute = currentLocation.startsWith('/auth');
      final isPublicRoute = AppRoutes.isPublicRoute(currentLocation);
      final isTherapistRoute = AppRoutes.isTherapistRoute(currentLocation);
      final isSplash = currentLocation == AppRoutes.splash;

      if (isSplash) return null;

      // Maintenance mode: block non-admin users
      if (currentLocation != AppRoutes.maintenance) {
        final settings = ref.read(systemSettingsProvider).valueOrNull;
        if (settings?.maintenanceMode == true && !authState.isAdmin) {
          return AppRoutes.maintenance;
        }
      }

      if (authState.status == AuthStatus.initial) {
        if (isPublicRoute || isAuthRoute) return null;
        return null;
      }

      if (authState.status == AuthStatus.unauthenticated) {
        if (!isPublicRoute && !isAuthRoute) return AppRoutes.login;
        return null;
      }

      if (authState.status == AuthStatus.profileIncomplete) {
        if (currentLocation == AppRoutes.community ||
            currentLocation == AppRoutes.subscription ||
            currentLocation == AppRoutes.chat ||
            currentLocation == AppRoutes.userSupportChat ||
            currentLocation.startsWith('/chat/')) {
          return AppRoutes.profileCompletion;
        }
      }

      if (isTherapistRoute && authState.status == AuthStatus.authenticated) {
        final isTherapist = authState.isTherapist;
        final therapistStatus = authState.therapistStatus;

        if (!isTherapist) {
          if (currentLocation == AppRoutes.therapistRegister) return null;
          return AppRoutes.home;
        }

        if (therapistStatus == TherapistApprovalStatus.pending) {
          if (currentLocation != AppRoutes.therapistPending) {
            return AppRoutes.therapistPending;
          }
        } else if (therapistStatus == TherapistApprovalStatus.rejected) {
          if (currentLocation != AppRoutes.therapistRejected) {
            return AppRoutes.therapistRejected;
          }
        } else if (therapistStatus == TherapistApprovalStatus.approved) {
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

      // Admin users land on home in the user app (no admin routes available)
      if (authState.status == AuthStatus.authenticated &&
          authState.isAdmin &&
          currentLocation == AppRoutes.home) {
        return null;
      }

      if (authState.status == AuthStatus.profileIncomplete && isAuthRoute) {
        return AppRoutes.profileCompletion;
      }

      if (authState.status == AuthStatus.authenticated) {
        if (isAuthRoute ||
            currentLocation == AppRoutes.login ||
            currentLocation == AppRoutes.signup) {
          if (authState.isApprovedTherapist) {
            return AppRoutes.therapistDashboard;
          }
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: [
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

      // Auth routes
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

      // App routes
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

      // Hybrid chat
      GoRoute(
        path: AppRoutes.hybridChat,
        name: 'hybridChat',
        builder: (context, state) => const HybridChatScreen(),
      ),

      // Crisis response
      GoRoute(
        path: AppRoutes.crisisResponse,
        name: 'crisisResponse',
        builder: (context, state) => const CrisisResponseScreen(),
      ),

      // Review
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

      // Therapist portal
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

      // Therapist messages
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

      // User therapist chat
      GoRoute(
        path: '/chat/therapist/:chatId',
        name: 'userTherapistChat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId'] ?? '';
          final thread = state.extra as TherapistChatThread?;
          return UserTherapistChatScreen(chatId: chatId, initialThread: thread);
        },
      ),

      // User support chat
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

      // AI Insights — user-facing (protected)
      GoRoute(
        path: AppRoutes.insights,
        name: 'insights',
        builder: (context, state) => const InsightsScreen(),
      ),
    ],
  );

  ref.listen(authProvider, (_, _) {
    router.refresh();
  });

  return router;
});
