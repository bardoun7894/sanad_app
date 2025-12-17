import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/auth_user.dart';
import '../repositories/auth_repository.dart';
import '../services/token_storage_service.dart';

/// Authentication status enum
enum AuthStatus {
  initial,           // App just launched, checking auth state
  authenticated,     // User is logged in
  unauthenticated,   // User is logged out
  profileIncomplete, // User logged in but needs to complete profile
}

/// Immutable authentication state
class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;
  final bool isLoading;
  final bool isGoogleSigningIn;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.isLoading = false,
    this.isGoogleSigningIn = false,
  });

  /// Create a copy of this state with optional field updates
  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? errorMessage,
    bool? isLoading,
    bool? isGoogleSigningIn,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      isGoogleSigningIn: isGoogleSigningIn ?? this.isGoogleSigningIn,
    );
  }

  /// Helper getters
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsProfileCompletion => status == AuthStatus.profileIncomplete;
  bool get isInitial => status == AuthStatus.initial;
}

/// State notifier for managing authentication
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final TokenStorageService _tokenStorage;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  AuthNotifier(this._authRepository, this._tokenStorage)
      : super(const AuthState()) {
    _initialize();
  }

  /// Initialize auth by checking stored user and listening to Firebase changes
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Check for stored user first
      final storedUser = await _tokenStorage.getStoredUser();

      // Listen to Firebase auth state changes
      _authStateSubscription =
          _authRepository.authStateChanges.listen(_onAuthStateChanged);

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
    } catch (e) {
      print('Error initializing auth: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    }
  }

  /// Handle Firebase auth state changes
  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null) {
      final authUser = AuthUser.fromFirebaseUser(firebaseUser);
      await _tokenStorage.saveUser(authUser);

      state = state.copyWith(
        status: _getAuthStatus(authUser),
        user: authUser,
        isLoading: false,
        isGoogleSigningIn: false,
      );
    } else {
      await _tokenStorage.clearUser();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
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
      await _authRepository.signInWithGoogle();
      // State will be updated by authStateChanges listener
    } catch (e) {
      state = state.copyWith(
        isGoogleSigningIn: false,
        errorMessage: AuthRepository.mapFirebaseException(e),
      );
    }
  }

  /// Complete user profile after signup
  Future<void> completeProfile({
    required String displayName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    if (state.user == null) {
      state = state.copyWith(
        errorMessage: 'No user logged in',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Update Firebase user profile
      await _authRepository.updateProfile(displayName: displayName);

      // If we have the current user, update the local state
      if (state.user != null) {
        final updatedUser = state.user!.copyWith(
          displayName: displayName,
          phoneNumber: phoneNumber,
        );

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
      await _authRepository.signOut();
      // State will be updated by authStateChanges listener
    } catch (e) {
      state = state.copyWith(
        errorMessage: AuthRepository.mapFirebaseException(e),
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
  return AuthNotifier(repository, tokenStorage);
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
