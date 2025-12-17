import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_user.dart';

/// Repository for handling all Firebase authentication operations
class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
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
  /// Throws [FirebaseAuthException] or [Exception] on failure
  Future<AuthUser> signInWithGoogle() async {
    try {
      // Sign out first to force account selection
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception('Google sign in failed: user is null');
      }

      return AuthUser.fromFirebaseUser(user);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Google sign in error: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Sign out from both Firebase and Google
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out error: $e');
    }
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
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
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

  /// Update user phone number
  /// Requires phone verification
  Future<void> updatePhoneNumber(String phoneNumber) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Phone number update requires SMS verification
      // This is a placeholder - full implementation would require
      // managing phone verification codes
      await user.updatePhoneNumber(
        firebase_auth.PhoneAuthProvider.credential(
          verificationId: '',
          smsCode: '',
        ),
      );
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Phone number update error: $e');
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
        default:
          return exception.message ?? 'Authentication error occurred';
      }
    }
    return exception.toString();
  }
}
