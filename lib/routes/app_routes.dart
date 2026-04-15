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
  static const String therapySelection = '/therapy-selection';
  static const String psychologicalTests = '/psychological-tests';
  static const String blog = '/blog';
  static const String podcast = '/podcast';
  static const String exercises = '/exercises';
  static const String bookings = '/bookings';
  static const String callHistory = '/call-history';

  // Static pages routes
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String aboutSanad = '/about-sanad';

  // Payment routes
  static const String subscription = '/subscription';
  static const String paymentMethod = '/payment-method';
  static const String googlePayPayment = '/google-pay-payment';
  static const String paypalPayment = '/paypal-payment';
  static const String cardPayment = '/card-payment';
  static const String applePayPayment = '/apple-pay';
  static const String bankTransfer = '/bank-transfer';
  static const String receiptUpload = '/receipt-upload';
  static const String paymentSuccess = '/payment-success';

  // Crisis routes
  static const String crisisResponse = '/crisis-response';

  // Hybrid chat routes
  static const String hybridChat = '/chat/hybrid';

  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminVerifications = '/admin/verifications';
  static const String adminDataManagement = '/admin/data-management';
  static const String adminCrisisAlerts = '/admin/crisis-alerts';

  // Therapist portal routes
  static const String therapistRegister = '/therapist/register';
  static const String therapistPending = '/therapist/pending';
  static const String therapistRejected = '/therapist/rejected';
  static const String therapistDashboard = '/therapist/dashboard';
  static const String therapistProfileEdit = '/therapist/profile';
  static const String therapistAvailability = '/therapist/availability';
  static const String therapistBookings = '/therapist/bookings';
  static const String therapistBookingDetail = '/therapist/booking';
  static const String therapistMessages = '/therapist/messages';
  static const String therapistChatDetail = '/therapist/messages/:chatId';
  static const String therapistSettings = '/therapist/settings';

  // User chat routes
  static const String userSupportChat = '/chat/support';
  static const String userTherapistChat = '/chat/therapist/:chatId';

  // OTP verification route
  static const String otpVerification = '/otp-verification';

  // Review route
  static const String leaveReview = '/leave-review';

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
    otpVerification,
    privacyPolicy,
    termsOfService,
    aboutSanad,
  ];

  // Protected routes (require login)
  static const List<String> protectedRoutes = [
    chat,
    moodTracker,
    profile,
    notifications,
    subscription,
    paymentMethod,
    paypalPayment,
    bankTransfer,
    receiptUpload,
    paymentSuccess,
    adminVerifications,
    userSupportChat,
    userTherapistChat,
  ];

  // Therapist portal routes (require therapist role)
  static const List<String> therapistRoutes = [
    therapistRegister,
    therapistPending,
    therapistRejected,
    therapistDashboard,
    therapistProfileEdit,
    therapistAvailability,
    therapistBookings,
    therapistBookingDetail,
    therapistMessages,
    therapistChatDetail,
    therapistSettings,
  ];

  /// Check if a route is public (accessible without login)
  static bool isPublicRoute(String path) {
    return publicRoutes.any(
      (route) => path == route || path.startsWith('/auth'),
    );
  }

  /// Check if a route is a therapist portal route
  static bool isTherapistRoute(String path) {
    return path.startsWith('/therapist/');
  }
}
