import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';
import '../services/token_storage_service.dart';
import '../../therapist_portal/models/therapist_profile.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/presence_service.dart';
import '../../admin/providers/activity_log_provider.dart';
import '../../../core/services/zego_call_service.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../routes/app_router.dart' show navigatorKey;
import '../../therapist_portal/widgets/post_call_notes_dialog.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/providers/handoff_provider.dart';
import '../../mood/providers/mood_tracker_provider.dart';
import '../../engagement/providers/streak_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../subscription/providers/subscription_provider.dart';
import '../../crisis/providers/crisis_alerts_provider.dart';
import '../../admin/providers/risk_alerts_provider.dart';

/// Authentication status enum
enum AuthStatus {
  initial, // App just launched, checking auth state
  authenticated, // User is logged in
  unauthenticated, // User is logged out
  profileIncomplete, // User logged in but needs to complete profile
}

/// Immutable authentication state
class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool isLoading;
  final bool isGoogleSigningIn;
  final bool isPhoneSigningIn;
  final UserRole? userRole;
  final TherapistApprovalStatus? therapistStatus;
  final String? verificationId;
  final String? pendingPhoneNumber;

  /// Set when a sign-in attempt fails because the email is already
  /// linked to a different auth provider (e.g. "Phone", "Google").
  final String? existingProvider;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
    this.isGoogleSigningIn = false,
    this.isPhoneSigningIn = false,
    this.userRole,
    this.therapistStatus,
    this.verificationId,
    this.pendingPhoneNumber,
    this.existingProvider,
  });

  /// Create a copy of this state with optional field updates
  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    bool? isLoading,
    bool? isGoogleSigningIn,
    bool? isPhoneSigningIn,
    UserRole? userRole,
    TherapistApprovalStatus? therapistStatus,
    String? verificationId,
    String? pendingPhoneNumber,
    String? existingProvider,
    bool clearError = false,
    bool clearTherapistStatus = false,
    bool clearVerification = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      isGoogleSigningIn: isGoogleSigningIn ?? this.isGoogleSigningIn,
      isPhoneSigningIn: isPhoneSigningIn ?? this.isPhoneSigningIn,
      userRole: userRole ?? this.userRole,
      therapistStatus: clearTherapistStatus
          ? null
          : (therapistStatus ?? this.therapistStatus),
      verificationId: clearVerification
          ? null
          : (verificationId ?? this.verificationId),
      pendingPhoneNumber: clearVerification
          ? null
          : (pendingPhoneNumber ?? this.pendingPhoneNumber),
      existingProvider: clearError
          ? null
          : (existingProvider ?? this.existingProvider),
    );
  }

  /// Helper getters
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsProfileCompletion => status == AuthStatus.profileIncomplete;
  bool get isInitial => status == AuthStatus.initial;

  /// Role-based helpers
  bool get isTherapist => userRole == UserRole.therapist;
  bool get isAdmin => userRole == UserRole.admin;
  bool get isRegularUser => userRole == UserRole.user || userRole == null;

  /// Therapist status helpers
  bool get isApprovedTherapist =>
      isTherapist && therapistStatus == TherapistApprovalStatus.approved;
  bool get isPendingTherapist =>
      isTherapist && therapistStatus == TherapistApprovalStatus.pending;
  bool get isRejectedTherapist =>
      isTherapist && therapistStatus == TherapistApprovalStatus.rejected;
  bool get isSuspendedTherapist =>
      isTherapist && therapistStatus == TherapistApprovalStatus.suspended;
}

/// State notifier for managing authentication
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final TokenStorageService _tokenStorage;
  final FirebaseFirestore _firestore;
  final Ref _ref;
  final ActivityLogService _activityLogService = ActivityLogService();
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  AuthNotifier(
    this._authRepository,
    this._tokenStorage,
    this._ref, {
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       super(const AuthState()) {
    _initialize();
  }

  /// Initialize auth by checking stored user and listening to Firebase changes
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check for stored user first
      final storedUser = await _tokenStorage.getStoredUser();

      // Listen to Firebase auth state changes
      _authStateSubscription = _authRepository.authStateChanges.listen(
        _onAuthStateChanged,
      );

      // If we have a stored user, set it immediately (optimistic)
      if (storedUser != null) {
        state = state.copyWith(
          status: _getAuthStatus(storedUser),
          user: storedUser,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
        );
      }
    } catch (e, st) {
      debugPrint('Error initializing auth: $e');
      debugPrintStack(stackTrace: st);
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  /// Handle Firebase auth state changes
  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    // Cancel existing user document subscription if any
    await _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (firebaseUser != null) {
      // Fetch Firestore user data FIRST so we have profile completion status
      Map<String, dynamic>? firestoreData;
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        firestoreData = userDoc.data();
      } catch (e, st) {
        debugPrint('Error fetching user doc in auth state change: $e');
        debugPrintStack(stackTrace: st);
      }

      // Start listening to the user document in Firestore for real-time role changes
      _userDocSubscription = _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .listen((snapshot) {
            _syncStateFromSnapshot(firebaseUser, snapshot);
          });

      // Create AuthUser WITH Firestore data so isProfileComplete is accurate
      final authUser = AuthUser.fromFirebaseUser(
        firebaseUser,
        additionalData: firestoreData,
      );

      // Register for push notifications
      try {
        // Request permission first
        final permissionGranted = await FCMService().requestPermission();
        debugPrint('FCM Permission granted: $permissionGranted');

        // Register user for notifications
        await FCMService().registerUser(firebaseUser.uid);
      } catch (e, st) {
        debugPrint('Error registering for FCM: $e');
        debugPrintStack(stackTrace: st);
      }

      // Start presence tracking — writes is_online + last_seen on the user
      // doc so chat partners see a real online indicator.
      try {
        await PresenceService.instance.start(firebaseUser.uid);
      } catch (e) {
        debugPrint('Error starting presence: $e');
      }

      // Check custom claims first (more secure and faster)
      UserRole? userRole;
      TherapistApprovalStatus? therapistStatus;

      try {
        final idTokenResult = await firebaseUser.getIdTokenResult(true);
        final claims = idTokenResult.claims;

        if (claims != null) {
          // Check admin claim
          if (claims['admin'] == true) {
            userRole = UserRole.admin;
            debugPrint('✓ Admin role from custom claims');
          }
          // Check therapist claim
          else if (claims['therapist'] == true) {
            userRole = UserRole.therapist;
            final statusStr = claims['approvalStatus'] as String?;
            if (statusStr != null) {
              therapistStatus = TherapistApprovalStatusX.fromString(statusStr);
            }
            debugPrint('✓ Therapist role from custom claims');
          }
          // Check role claim as fallback
          else if (claims['role'] != null) {
            userRole = _parseRole(claims['role'] as String?);
            debugPrint('✓ Role from custom claims: ${claims['role']}');
          }
        }
      } catch (e, st) {
        debugPrint('Error getting custom claims: $e');
        debugPrintStack(stackTrace: st);
      }

      // If no claims found, fetch from Firestore
      if (userRole == null) {
        final roleData = await _syncUserData(firebaseUser);
        userRole = roleData['role'] as UserRole?;
        therapistStatus ??=
            roleData['therapistStatus'] as TherapistApprovalStatus?;
      }

      // Update authUser with role
      final updatedUser = authUser.copyWith(role: userRole ?? UserRole.user);
      await _tokenStorage.saveUser(updatedUser);

      // Only set userRole from custom claims - otherwise preserve what listener set
      // This prevents race condition where we overwrite the role from Firestore listener
      final effectiveRole = userRole ?? state.userRole;
      // Use the latest state from Firestore listener if it already has profile data,
      // to avoid overwriting a correct 'authenticated' status with 'profileIncomplete'
      final effectiveStatus =
          (state.user?.isProfileComplete == true &&
              _getAuthStatus(updatedUser) == AuthStatus.profileIncomplete)
          ? state.status
          : _getAuthStatus(updatedUser);
      state = state.copyWith(
        status: effectiveStatus,
        user: updatedUser,
        userRole: effectiveRole,
        therapistStatus: therapistStatus,
        isLoading: false,
        isGoogleSigningIn: false,
      );

      // Initialize Zego call invitation service for the authenticated user
      try {
        final s = _ref.read(stringsProvider);
        await ZegoCallService.instance.init(
          userId: updatedUser.uid,
          userName: updatedUser.displayName ?? updatedUser.uid,
          callNotificationsChannelName: s.callNotifications,
          onCallCompleted: (callID) {
            debugPrint(
              'AuthProvider: Call completed, booking $callID auto-completed',
            );
            // Show post-call notes dialog for therapists
            final authState = _ref.read(authProvider);
            if (authState.isTherapist) {
              final context = navigatorKey.currentContext;
              if (context != null) {
                PostCallNotesDialog.show(context, callID);
              }
            }
          },
        );
      } catch (e, st) {
        debugPrint('ZegoCallService init failed: $e');
        debugPrintStack(stackTrace: st);
      }
    } else {
      // Unregistering from FCM is now handled in signOut() to ensure we have permissions.
      // If the session expired naturally, we can't unregister anyway due to security rules.

      /* 
      // Original code removed to prevent permission denied errors
      try {
        await FCMService().unregisterUser();
      } catch (e, st) {
        debugPrint('Error unregistering from FCM: $e');
        debugPrintStack(stackTrace: st);
      }
      */

      await _tokenStorage.clearUser();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Sync the state from a Firestore document snapshot (Real-time)
  Future<void> _syncStateFromSnapshot(
    firebase_auth.User firebaseUser,
    DocumentSnapshot snapshot,
  ) async {
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final role = _parseRole(data['role'] as String?);
    var therapistStatus = _parseTherapistStatus(
      data['therapist_status'] as String?,
    );

    // If therapist, ensure we have the most up-to-date approval status
    if (role == UserRole.therapist) {
      // We could add a second listener for the therapists collection if needed,
      // but for now we rely on the synced field in the users collection.
    }

    final authUser = AuthUser.fromFirebaseUser(
      firebaseUser,
      additionalData: data,
    ).copyWith(role: role);
    await _tokenStorage.saveUser(authUser);

    state = state.copyWith(
      status: _getAuthStatus(authUser),
      user: authUser,
      userRole: role,
      therapistStatus: therapistStatus,
      isLoading: false,
    );
  }

  /// Sync user data with Firestore (create if new, update if existing)
  Future<Map<String, dynamic>> _syncUserData(
    firebase_auth.User firebaseUser,
  ) async {
    try {
      final userRef = _firestore.collection('users').doc(firebaseUser.uid);
      final userDoc = await userRef.get();
      final userData = userDoc.data();

      // Check if migration is needed (not migrated yet)
      // Skip migration if user already has a valid role set
      final existingRole = userData?['role'] as String?;
      final needsMigration =
          (userData == null || userData['migrated_at'] == null) &&
          (existingRole == null || existingRole == 'user');

      if (needsMigration) {
        final oldProfileDoc = await _firestore
            .collection('user_profiles')
            .doc(firebaseUser.uid)
            .get();

        if (oldProfileDoc.exists && oldProfileDoc.data() != null) {
          final oldData = oldProfileDoc.data()!;

          // Determine role and status, preferring existing user data or verifying if needed
          var roleStr =
              oldData['role'] ?? userData?['role'] ?? UserRole.user.name;
          var statusStr =
              oldData['therapist_status'] ?? userData?['therapist_status'];

          if (roleStr == UserRole.therapist.name) {
            try {
              final therapistDoc = await _firestore
                  .collection('therapists')
                  .doc(firebaseUser.uid)
                  .get();
              if (therapistDoc.exists) {
                statusStr = therapistDoc.data()?['approval_status'];
              }
            } catch (e, st) {
              debugPrint(
                'Error verifying therapist status during migration: $e',
              );
              debugPrintStack(stackTrace: st);
            }
          }

          final migratedData = {
            ...oldData,
            'email': firebaseUser.email ?? oldData['email'],
            'name': firebaseUser.displayName ?? oldData['name'],
            'avatar_url': firebaseUser.photoURL ?? oldData['avatar_url'],
            'last_login': FieldValue.serverTimestamp(),
            'migrated_at': FieldValue.serverTimestamp(),
            'role': roleStr,
            'therapist_status': statusStr,
          };

          await userRef.set(migratedData, SetOptions(merge: true));
          return {
            'role': _parseRole(migratedData['role'] as String?),
            'therapistStatus': _parseTherapistStatus(
              migratedData['therapist_status'] as String?,
            ),
          };
        }
      }

      if (userDoc.exists) {
        final data = userDoc.data();
        var role = _parseRole(data?['role'] as String?);
        var therapistStatus = _parseTherapistStatus(
          data?['therapist_status'] as String?,
        );

        // If user is a therapist, verify status from therapists collection
        if (role == UserRole.therapist) {
          final therapistDoc = await _firestore
              .collection('therapists')
              .doc(firebaseUser.uid)
              .get();

          if (therapistDoc.exists) {
            final tData = therapistDoc.data();
            final actualStatus = _parseTherapistStatus(
              tData?['approval_status'] as String?,
            );

            // Sync if different
            if (actualStatus != therapistStatus) {
              await userRef.update({
                'therapist_status': tData?['approval_status'],
              });
              therapistStatus = actualStatus;
            }
          }
        }

        // Update existing user's last login and sync basic info
        await userRef.update({
          'last_login': FieldValue.serverTimestamp(),
          'email': firebaseUser.email,
          if (firebaseUser.displayName != null)
            'name': firebaseUser.displayName,
          if (firebaseUser.photoURL != null)
            'avatar_url': firebaseUser.photoURL,
        });

        return {'role': role, 'therapistStatus': therapistStatus};
      }

      // Create new user document
      final userName = firebaseUser.displayName ?? 'User';
      final providerName = AuthUser.fromFirebaseUser(
        firebaseUser,
      ).provider.name;
      final newUser = {
        'email': firebaseUser.email,
        'name': userName,
        'avatar_url': firebaseUser.photoURL,
        'phone': firebaseUser.phoneNumber,
        'role': UserRole.user.name,
        'auth_provider': providerName,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
        'settings': {
          'notifications_enabled': true,
          'daily_reminders': true,
          'mood_tracking_reminders': true,
          'reminder_time': '09:00',
          'dark_mode': false,
          'language': 'English',
        },
      };

      await userRef.set(newUser);

      // Log activity for new user registration
      try {
        await _activityLogService.logUserRegistered(
          userId: firebaseUser.uid,
          userName: userName,
        );
      } catch (e, st) {
        debugPrint('Failed to log registration activity: $e');
        debugPrintStack(stackTrace: st);
      }

      return {'role': UserRole.user, 'therapistStatus': null};
    } catch (e, st) {
      debugPrint('Error syncing user data: $e');
      debugPrintStack(stackTrace: st);
      return {'role': UserRole.user, 'therapistStatus': null};
    }
  }

  UserRole _parseRole(String? roleStr) {
    if (roleStr == null) return UserRole.user;
    final normalized = roleStr.toLowerCase().trim();
    return UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == normalized,
      orElse: () => UserRole.user,
    );
  }

  TherapistApprovalStatus? _parseTherapistStatus(String? statusStr) {
    if (statusStr == null) return null;
    return TherapistApprovalStatusX.fromString(statusStr);
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.signInWithEmail(email, password);
      // State will be updated by authStateChanges listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
        status: AuthStatus.unauthenticated,
      );
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.signUpWithEmail(email, password);
      // Send email verification (Google/Apple users are auto-verified)
      await _authRepository.sendEmailVerification();
      // User should complete profile next
      // State will be updated by authStateChanges listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isGoogleSigningIn: true, clearError: true);

    try {
      final result = await _authRepository.signInWithGoogle();
      if (result == null) {
        // User cancelled — silently reset loading state
        state = state.copyWith(isGoogleSigningIn: false);
        return;
      }
      // State will be updated by authStateChanges listener
    } on firebase_auth.FirebaseAuthException catch (e) {
      final providerMsg = await _handleAccountExistsError(e);
      if (providerMsg != null) {
        state = state.copyWith(
          isGoogleSigningIn: false,
          existingProvider: providerMsg.$1,
          errorMessage: providerMsg.$2,
        );
        return;
      }
      state = state.copyWith(
        isGoogleSigningIn: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    } catch (e) {
      state = state.copyWith(
        isGoogleSigningIn: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    }
  }

  /// Convert Firebase sign-in method IDs to user-friendly names
  String? _friendlyProviderName(List<String> methods) {
    if (methods.isEmpty) return null;
    for (final m in methods) {
      switch (m) {
        case 'phone':
          return 'Phone';
        case 'password':
          return 'Email/Password';
        case 'google.com':
          return 'Google';
        case 'apple.com':
          return 'Apple';
      }
    }
    return null; // Unknown provider — use generic message
  }

  /// Shared handler for account-exists-with-different-credential errors.
  /// Returns (providerName, errorMessage) if handled, null otherwise.
  Future<(String?, String)?> _handleAccountExistsError(
    firebase_auth.FirebaseAuthException e,
  ) async {
    if (e.code != 'account-exists-with-different-credential') return null;

    final email = e.email;
    String? existingProviderName;
    if (email != null) {
      try {
        final methods = await _authRepository.fetchSignInMethodsForEmail(email);
        existingProviderName = _friendlyProviderName(methods);
      } catch (fetchError) {
        debugPrint('fetchSignInMethodsForEmail failed: $fetchError');
      }
    }

    final message = existingProviderName != null
        ? 'This email is already linked to a $existingProviderName account. Please sign in with $existingProviderName instead.'
        : 'This email is already registered with a different sign-in method.';

    return (existingProviderName, message);
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _authRepository.signInWithApple();
      if (result == null) {
        // User cancelled — silently reset loading state
        state = state.copyWith(isLoading: false);
        return;
      }
      // State will be updated by authStateChanges listener
    } on firebase_auth.FirebaseAuthException catch (e) {
      final providerMsg = await _handleAccountExistsError(e);
      if (providerMsg != null) {
        state = state.copyWith(
          isLoading: false,
          existingProvider: providerMsg.$1,
          errorMessage: providerMsg.$2,
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    }
  }

  /// Sign in anonymously
  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.signInAnonymously();
      // State will be updated by authStateChanges listener
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    }
  }

  /// Sign in with phone number - sends OTP
  Future<void> signInWithPhone(String phoneNumber) async {
    state = state.copyWith(
      isPhoneSigningIn: true,
      clearError: true,
      pendingPhoneNumber: phoneNumber,
    );

    try {
      await _authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted:
            (firebase_auth.PhoneAuthCredential credential) async {
              // Auto-verification on Android
              try {
                final authUser = await _authRepository.signInWithCredential(
                  credential,
                );
                state = state.copyWith(
                  status: _getAuthStatus(authUser),
                  user: authUser,
                  isPhoneSigningIn: false,
                );
              } catch (e) {
                state = state.copyWith(
                  isPhoneSigningIn: false,
                  errorMessage: AuthRepository.mapFirebaseException(e),
                );
              }
            },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          state = state.copyWith(
            isPhoneSigningIn: false,
            errorMessage: AuthRepository.mapFirebaseException(e),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            isPhoneSigningIn: false,
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isPhoneSigningIn: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    }
  }

  /// Verify OTP code
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
    bool isSignUp = false,
    String? firstName,
    String? lastName,
    String? whatsappNumber,
    bool? whatsappConsent,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final authUser = await _authRepository.signInWithPhoneCredential(
        verificationId,
        smsCode,
      );

      // If sign up, update profile with name
      final firebaseUser = _authRepository.currentFirebaseUser;
      if (isSignUp && firebaseUser != null) {
        final displayName = [
          firstName,
          lastName,
        ].where((s) => s != null && s.isNotEmpty).join(' ');
        if (displayName.isNotEmpty) {
          await firebaseUser.updateDisplayName(displayName);
        }

        // Save to Firestore
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'first_name': firstName,
          'last_name': lastName,
          'phone': state.pendingPhoneNumber,
          if (whatsappNumber != null && whatsappNumber.isNotEmpty)
            'whatsapp_number': whatsappNumber,
          'whatsapp_consent': whatsappConsent ?? false,
          'role': UserRole.user.name,
          'auth_provider': AuthProvider.phone.name,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Log activity for new user registration
        try {
          await _activityLogService.logUserRegistered(
            userId: firebaseUser.uid,
            userName: displayName.isNotEmpty ? displayName : 'User',
          );
        } catch (e, st) {
          debugPrint('Failed to log registration activity: $e');
          debugPrintStack(stackTrace: st);
        }
      }

      state = state.copyWith(
        status: _getAuthStatus(authUser),
        user: authUser,
        isLoading: false,
        clearVerification: true,
      );
      // Auth state listener will also catch this and sync extra data (role, etc.)
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
      rethrow;
    }
  }

  /// Resend OTP
  Future<void> resendOtp(String phoneNumber) async {
    await signInWithPhone(phoneNumber);
  }

  /// Sign up with phone (send OTP first)
  Future<void> signUpWithPhone({
    required String phoneNumber,
    required String firstName,
    required String lastName,
  }) async {
    // Store info for after OTP verification
    state = state.copyWith(pendingPhoneNumber: phoneNumber);

    // Store user info in temporary location for use after verification
    await _tokenStorage.savePendingRegistration(
      phoneNumber: phoneNumber,
      firstName: firstName,
      lastName: lastName,
    );

    // Send OTP
    await signInWithPhone(phoneNumber);
  }

  /// Complete user profile after signup
  Future<void> completeProfile({
    required String displayName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    Map<String, dynamic>? matchingPreferences,
    String? avatarUrl,
  }) async {
    if (state.user == null) {
      state = state.copyWith(errorMessage: 'No user logged in');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Update Firebase user profile
      await _authRepository.updateProfile(displayName: displayName);

      // Extract WhatsApp data from matching preferences to save at top level
      final whatsappNumber =
          matchingPreferences?.remove('whatsapp_number') as String?;
      final whatsappConsent =
          matchingPreferences?.remove('whatsapp_ads_consent') as bool?;

      // Create the updated user first to calculate completion percentage dynamically
      AuthUser? updatedUser;
      if (state.user != null) {
        updatedUser = state.user!.copyWith(
          displayName: displayName,
          phoneNumber: phoneNumber,
          whatsappNumber: whatsappNumber,
          whatsappConsent: whatsappConsent,
          matchingPreferences: matchingPreferences,
          photoUrl: avatarUrl ?? state.user!.photoUrl,
          isProfileComplete: true,
        );
      }

      // Update Firestore
      await _firestore.collection('users').doc(state.user!.uid).set({
        'display_name': displayName,
        if (phoneNumber != null) 'phone': phoneNumber,
        if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
        if (whatsappConsent != null) 'whatsapp_ads_consent': whatsappConsent,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (dateOfBirth != null)
          'date_of_birth': Timestamp.fromDate(dateOfBirth),
        if (gender != null) 'gender': gender,
        if (matchingPreferences != null)
          'matching_preferences': matchingPreferences,
        'has_complete_profile': true,
        if (updatedUser != null)
          'profile_completion_percentage':
              updatedUser.profileCompletionPercentage,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // If we have the current user, update the local state
      if (updatedUser != null) {
        await _tokenStorage.saveUser(updatedUser);

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: updatedUser,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      // 1. Cancel user document subscription FIRST to prevent permission-denied
      //    errors once Firebase Auth becomes null
      await _userDocSubscription?.cancel();
      _userDocSubscription = null;

      // 2. Uninitialize Zego call invitation service
      try {
        await ZegoCallService.instance.uninit();
      } catch (e) {
        debugPrint('Error uninitializing Zego during logout: $e');
      }

      // 3. Unregister FCM token while we still have permissions
      try {
        await FCMService().unregisterUser();
      } catch (e) {
        debugPrint('Error unregistering FCM token during logout: $e');
      }

      // 3b. Mark offline + tear down presence observer.
      try {
        await PresenceService.instance.stop();
      } catch (e) {
        debugPrint('Error stopping presence: $e');
      }

      // 4. Clear stored user from token storage
      try {
        await _tokenStorage.clearUser();
      } catch (e) {
        debugPrint('Error clearing stored user: $e');
      }

      // 5. Sign out of Firebase Auth + Google
      await _authRepository.signOut();

      // 6. Immediately set state to unauthenticated so router reacts without
      //    waiting for Firebase auth listener (which can be delayed)
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      debugPrint('Logout error: $e');
      // Even if logout fails, force state to unauthenticated locally
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Password reset email sent. Check your inbox.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Determine auth status based on user profile completion
  AuthStatus _getAuthStatus(AuthUser user) {
    // Anonymous users are always authenticated (skip profile completion)
    if (user.provider == AuthProvider.anonymous) {
      return AuthStatus.authenticated;
    }

    if (user.hasCompleteProfile) {
      return AuthStatus.authenticated;
    } else {
      return AuthStatus.profileIncomplete;
    }
  }

  /// Cleanup
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final tokenStorageProvider = Provider<TokenStorageService>((ref) {
  throw UnimplementedError(
    'TokenStorageService must be overridden in main.dart',
  );
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(repository, tokenStorage, ref);
});

/// Helper provider to select just the authentication status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});

/// Helper provider to select if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Helper provider to select the current user
final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Helper provider to get user role
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).userRole;
});

/// Helper provider to check if user is a therapist
final isTherapistProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isTherapist;
});

/// Helper provider to check if user is an admin
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAdmin;
});

/// Helper provider to check if user is an approved therapist
final isApprovedTherapistProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isApprovedTherapist;
});

/// Helper provider to get therapist approval status
final therapistStatusProvider = Provider<TherapistApprovalStatus?>((ref) {
  return ref.watch(authProvider).therapistStatus;
});

/// Centralized sign-out that cancels ALL Firestore streams before signing out.
///
/// Without this, active Firestore listeners throw permission-denied errors
/// because they keep listening after Firebase Auth becomes null.
///
/// Every logout call site MUST use this instead of calling signOut() directly.
final signOutAndCleanupProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    // 1. Invalidate all user-scoped providers BEFORE signing out
    //    This cancels their Firestore stream subscriptions while auth is still valid.
    try {
      ref.invalidate(chatProvider);
      ref.invalidate(moodTrackerProvider);
      ref.invalidate(streakProvider);
      ref.invalidate(communityProvider);
      ref.invalidate(notificationProvider);
      ref.invalidate(subscriptionProvider);
      ref.invalidate(pendingHandoffsProvider);
      ref.invalidate(userHandoffsProvider);
      ref.invalidate(therapistHandoffsProvider);
      ref.invalidate(activeCrisisAlertsProvider);
      ref.invalidate(riskAlertsProvider);
      ref.invalidate(recentActivityProvider);
    } catch (e) {
      debugPrint('Error invalidating providers during logout: $e');
    }

    // 2. Small delay to let Riverpod dispose the streams
    await Future.delayed(const Duration(milliseconds: 150));

    // 3. Now sign out (auth becomes null safely with no active listeners)
    await ref.read(authProvider.notifier).signOut();
  };
});
