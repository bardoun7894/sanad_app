import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

enum AuthProvider { email, google, apple, phone, anonymous }

/// User role for role-based access control
enum UserRole {
  user, // Regular app user (client)
  therapist, // Therapist
  admin, // Administrator
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
  final UserRole role;

  // New fields for progressive profiling
  final String? whatsappNumber;
  final Map<String, dynamic>? matchingPreferences;
  final bool whatsappConsent;
  final bool isProfileComplete; // From database flag

  // Assigned therapist (set by admin for Premium/VIP tiers)
  final String? assignedTherapistId;
  final String? assignedTherapistName;

  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.phoneNumber,
    required this.createdAt,
    required this.provider,
    this.role = UserRole.user,
    this.whatsappNumber,
    this.matchingPreferences,
    this.whatsappConsent = false,
    this.isProfileComplete = false,
    this.assignedTherapistId,
    this.assignedTherapistName,
  });

  /// Helper getters for role checking
  bool get isTherapist => role == UserRole.therapist;
  bool get isAdmin => role == UserRole.admin;
  bool get isRegularUser => role == UserRole.user;
  bool get isGuest => provider == AuthProvider.anonymous;

  /// Factory constructor from Firebase User
  factory AuthUser.fromFirebaseUser(
    firebase_auth.User user, {
    Map<String, dynamic>? additionalData,
  }) {
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName:
          user.displayName ??
          additionalData?['display_name'] ??
          additionalData?['name'],
      photoUrl: user.photoURL ??
          _normalizeAvatarUrl(additionalData?['avatar_url'] as String?),
      emailVerified: user.emailVerified,
      phoneNumber: user.phoneNumber ?? additionalData?['phone'],
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      provider: user.isAnonymous
          ? AuthProvider.anonymous
          : _getProviderFromProviders(user.providerData),
      whatsappNumber: additionalData?['whatsapp_number'],
      matchingPreferences: additionalData?['matching_preferences'] != null
          ? Map<String, dynamic>.from(
              additionalData!['matching_preferences'] as Map,
            )
          : null,
      whatsappConsent: additionalData?['whatsapp_ads_consent'] ?? false,
      isProfileComplete: additionalData?['has_complete_profile'] ?? false,
      assignedTherapistId: additionalData?['assigned_therapist_id'],
      assignedTherapistName: additionalData?['assigned_therapist_name'],
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
    UserRole? role,
    String? whatsappNumber,
    Map<String, dynamic>? matchingPreferences,
    bool? whatsappConsent,
    bool? isProfileComplete,
    String? assignedTherapistId,
    String? assignedTherapistName,
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
      role: role ?? this.role,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      matchingPreferences: matchingPreferences ?? this.matchingPreferences,
      whatsappConsent: whatsappConsent ?? this.whatsappConsent,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      assignedTherapistId: assignedTherapistId ?? this.assignedTherapistId,
      assignedTherapistName: assignedTherapistName ?? this.assignedTherapistName,
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
      'role': role.name,
      'whatsappNumber': whatsappNumber,
      'matchingPreferences': matchingPreferences,
      'whatsappConsent': whatsappConsent,
      'profileCompletionPercentage': profileCompletionPercentage,
      'hasCompleteProfile': isProfileComplete || hasCompleteProfile,
      'isProfileComplete': isProfileComplete,
      'assignedTherapistId': assignedTherapistId,
      'assignedTherapistName': assignedTherapistName,
    };
  }

  /// Deserialization from JSON
  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      emailVerified: json['emailVerified'] == true,
      phoneNumber: json['phoneNumber'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      provider: AuthProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AuthProvider.email,
      ),
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.user,
      ),
      whatsappNumber: json['whatsappNumber'] as String?,
      matchingPreferences: json['matchingPreferences'] != null
          ? Map<String, dynamic>.from(json['matchingPreferences'] as Map)
          : null,
      whatsappConsent: json['whatsappConsent'] == true,
      isProfileComplete: json['isProfileComplete'] == true,
      assignedTherapistId: json['assignedTherapistId'] as String?,
      assignedTherapistName: json['assignedTherapistName'] as String?,
    );
  }

  /// Check if profile is complete based on required steps
  bool get hasCompleteProfile {
    return isProfileComplete || profileCompletionPercentage >= 1.0;
  }

  /// Calculate profile completion percentage for progress tracking
  double get profileCompletionPercentage {
    if (isGuest || isProfileComplete) return 1.0;

    int totalSteps = 3; // Name, Phone/WhatsApp, Matching Prefs
    int completedSteps = 0;

    // Step 1: Basic Info (Name)
    if (displayName != null && displayName!.trim().isNotEmpty) {
      completedSteps += 1;
    }

    // Step 2: Contact Info (Phone/WhatsApp)
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      completedSteps += 1;
    }

    // Step 3: Matching Preferences
    if (matchingPreferences != null && matchingPreferences!.isNotEmpty) {
      completedSteps += 1;
    }

    return completedSteps / totalSteps;
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
        case 'phone':
          return AuthProvider.phone;
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
      'AuthUser(uid: $uid, email: $email, displayName: $displayName, provider: ${provider.name}, role: ${role.name}, completion: ${(profileCompletionPercentage * 100).toInt()}%)';

  // Legacy avatar_url values point at assets/images/avatars/avatar_N.svg;
  // only the .png variants ship now. Rewrite at the data boundary so every
  // consumer is safe.
  static String? _normalizeAvatarUrl(String? url) {
    if (url == null) return null;
    if (url.startsWith('assets/images/avatars/avatar_') &&
        url.toLowerCase().endsWith('.svg')) {
      return url.replaceFirst(RegExp(r'\.svg$', caseSensitive: false), '.png');
    }
    return url;
  }
}
