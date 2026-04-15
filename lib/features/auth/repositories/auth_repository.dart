import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/auth_user.dart';

/// Repository for handling all Firebase authentication operations
class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Stream of Firebase auth state changes
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  /// Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Sign in with email and password
  /// Throws [FirebaseAuthException] on failure
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign in failed: user is null');
      }

      return AuthUser.fromFirebaseUser(user);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error during sign in: $e');
    }
  }

  /// Sign up with email and password
  /// Throws [FirebaseAuthException] on failure
  Future<AuthUser> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Sign up failed: user is null');
      }

      return AuthUser.fromFirebaseUser(user);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Unexpected error during sign up: $e');
    }
  }

  /// Sign in with Google
  /// Returns null if user cancels the sign-in flow.
  /// Throws [FirebaseAuthException] on Firebase errors.
  Future<AuthUser?> signInWithGoogle() async {
    try {
      firebase_auth.UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = firebase_auth.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        await _googleSignIn.signOut();

        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return null;
        }

        final googleAuth = await googleUser.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _firebaseAuth.signInWithCredential(credential);
      }

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Google sign in failed: user is null');
      }

      return AuthUser.fromFirebaseUser(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Web popup closed or iOS provider cancelled by user
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'web-context-cancelled') {
        return null;
      }
      rethrow;
    } catch (e) {
      throw Exception('Google sign in error: $e');
    }
  }

  /// Sign in with Apple
  /// Returns null if user cancels the sign-in flow.
  /// Throws [FirebaseAuthException] on Firebase errors.
  Future<AuthUser?> signInWithApple() async {
    try {
      firebase_auth.UserCredential userCredential;

      if (kIsWeb) {
        // On web, use Firebase's built-in Apple provider
        final appleProvider = firebase_auth.AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');

        userCredential = await _firebaseAuth.signInWithPopup(appleProvider);
      } else {
        // On iOS/macOS, use sign_in_with_apple package
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
        );

        // Create OAuthCredential from the Apple ID token
        final oauthCredential = firebase_auth.OAuthProvider('apple.com')
            .credential(
              idToken: appleCredential.identityToken,
              accessToken: appleCredential.authorizationCode,
            );

        userCredential = await _firebaseAuth.signInWithCredential(
          oauthCredential,
        );

        // Update display name from Apple if available (first login only)
        final user = userCredential.user;
        if (user != null && user.displayName == null) {
          final givenName = appleCredential.givenName ?? '';
          final familyName = appleCredential.familyName ?? '';
          final fullName = [
            givenName,
            familyName,
          ].where((n) => n.isNotEmpty).join(' ');

          if (fullName.isNotEmpty) {
            await user.updateDisplayName(fullName);
          }
        }
      }

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Apple sign in failed: user is null');
      }

      return AuthUser.fromFirebaseUser(user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // User cancelled — not an error
        return null;
      }
      throw Exception('Apple sign in error: ${e.message}');
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Web popup closed by user
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'web-context-cancelled') {
        return null;
      }
      rethrow;
    } catch (e) {
      throw Exception('Apple sign in error: $e');
    }
  }

  /// Sign in anonymously
  Future<AuthUser> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = credential.user;

      if (user == null) {
        throw Exception('Anonymous sign in failed: user is null');
      }

      return AuthUser.fromFirebaseUser(user);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Anonymous sign in error: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Sign out from both Firebase and Google
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Sign out error: $e');
    }
  }

  /// Fetch sign-in methods for an email address.
  /// Used to tell users which provider they originally signed up with.
  /// Note: Deprecated by Firebase for email enumeration protection,
  /// but no replacement exists for this use case yet.
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    // ignore: deprecated_member_use
    return _firebaseAuth.fetchSignInMethodsForEmail(email.trim());
  }

  /// Send password reset email
  /// Throws [FirebaseAuthException] on failure
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Password reset error: $e');
    }
  }

  /// Update user profile information (display name, photo URL)
  /// Throws [FirebaseAuthException] on failure
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      await user.updateDisplayName(displayName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Profile update error: $e');
    }
  }

  /// Verify phone number (sends SMS code)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(firebase_auth.PhoneAuthCredential)
    verificationCompleted,
    required void Function(firebase_auth.FirebaseAuthException)
    verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      throw Exception('Phone verification error: $e');
    }
  }

  /// Sign in with phone credential (SMS code)
  Future<AuthUser> signInWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      return await signInWithCredential(credential);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Phone sign in error: $e');
    }
  }

  /// Sign in with generic credential
  Future<AuthUser> signInWithCredential(
    firebase_auth.AuthCredential credential,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Sign in failed: user is null');
      }

      return AuthUser.fromFirebaseUser(user);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Sign in with credential error: $e');
    }
  }

  /// Update user phone number with verification
  /// Note: This triggers the SMS verification flow. Actual update happens
  /// when user provides the SMS code via `updatePhoneNumberCredential`.
  Future<void> updatePhoneNumber({
    required String phoneNumber,
    required void Function(firebase_auth.PhoneAuthCredential)
    verificationCompleted,
    required void Function(firebase_auth.FirebaseAuthException)
    verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Phone update error: $e');
    }
  }

  /// Complete phone number update with credential
  Future<void> completePhoneUpdate(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await user.updatePhoneNumber(credential);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Phone verification error: $e');
    }
  }

  /// Verify email
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Email verification error: $e');
    }
  }

  /// Check if user email is verified
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Reload user from Firebase
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to reload user: $e');
    }
  }

  /// Map Firebase auth exception to user-friendly message
  static String mapFirebaseException(dynamic exception) {
    if (exception is firebase_auth.FirebaseAuthException) {
      switch (exception.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'email-already-in-use':
          return 'Email is already registered';
        case 'account-exists-with-different-credential':
          return 'An account already exists with a different sign-in method';
        case 'weak-password':
          return 'Password is too weak (at least 6 characters)';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'User account has been disabled';
        case 'too-many-requests':
          return 'Too many login attempts. Please try again later';
        case 'operation-not-allowed':
          return 'This operation is not allowed';
        case 'network-request-failed':
          return 'Network error. Please check your connection';
        case 'invalid-verification-code':
          return 'Invalid SMS code. Please check and try again';
        case 'invalid-verification-id':
          return 'Invalid verification session. Please try again';
        case 'captcha-check-failed':
          return 'Safety check failed. Please try again';
        case 'invalid-phone-number':
          return 'The phone number entered is invalid';
        case 'quota-exceeded':
          return 'Sms quota exceeded. Please try again later';
        default:
          // Handle BILLING_NOT_ENABLED and other internal errors
          final msg = exception.message ?? '';
          if (msg.contains('BILLING_NOT_ENABLED')) {
            return 'خدمة التحقق عبر الهاتف غير متاحة حالياً. يرجى التواصل مع الدعم الفني.';
          }
          return exception.message ?? 'Authentication error occurred';
      }
    }
    // Handle non-FirebaseAuthException errors (e.g. FirebaseException)
    final errorStr = exception.toString();
    if (errorStr.contains('BILLING_NOT_ENABLED')) {
      return 'خدمة التحقق عبر الهاتف غير متاحة حالياً. يرجى التواصل مع الدعم الفني.';
    }
    return errorStr;
  }
}
