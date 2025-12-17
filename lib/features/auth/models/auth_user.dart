import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

enum AuthProvider {
  email,
  google,
  apple,
  anonymous,
}

/// User model created from Firebase Auth user
class AuthUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final String? phoneNumber;
  final DateTime createdAt;
  final AuthProvider provider;

  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.phoneNumber,
    required this.createdAt,
    required this.provider,
  });

  /// Factory constructor from Firebase User
  factory AuthUser.fromFirebaseUser(firebase_auth.User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
      phoneNumber: user.phoneNumber,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      provider: _getProviderFromProviders(user.providerData),
    );
  }

  /// Create a copy of this user with optional field updates
  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    String? phoneNumber,
    DateTime? createdAt,
    AuthProvider? provider,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      provider: provider ?? this.provider,
    );
  }

  /// Serialization to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'provider': provider.name,
    };
  }

  /// Deserialization from JSON
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? false,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      provider: AuthProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AuthProvider.email,
      ),
    );
  }

  /// Check if profile is complete (has required fields)
  bool get hasCompleteProfile {
    return displayName != null && displayName!.isNotEmpty;
  }

  /// Helper method to determine provider type from Firebase provider data
  static AuthProvider _getProviderFromProviders(
    List<firebase_auth.UserInfo> providers,
  ) {
    if (providers.isEmpty) return AuthProvider.email;

    for (final provider in providers) {
      switch (provider.providerId) {
        case 'google.com':
          return AuthProvider.google;
        case 'apple.com':
          return AuthProvider.apple;
        case 'password':
          return AuthProvider.email;
        default:
          continue;
      }
    }

    return AuthProvider.email;
  }

  @override
  String toString() =>
      'AuthUser(uid: $uid, email: $email, displayName: $displayName, provider: ${provider.name})';
}
