import 'package:cloud_firestore/cloud_firestore.dart';

/// One failed signup write, surfaced in the admin dashboard so support can
/// see WHY a user got stuck and what stage of the flow they were in.
class SignupFailure {
  final String uid;
  final String stage;
  final String? errorCode;
  final String error;
  final List<String> attemptedFields;
  final String? platform;
  final DateTime? attemptedAt;
  final bool resolved;

  /// Best-effort display name (used for incomplete-profile rows where we have
  /// a users/{uid} doc with a name). Null for hard signup failures.
  final String? displayName;

  // Partial profile info captured by autosave — shown on incomplete-profile
  // rows so admins can see how far a user got and what's still missing.
  final String? email;
  final String? phone;
  final String? gender;
  final int? completionPercent;

  /// Human keys of the still-missing required fields (name/phone/avatar/etc.).
  final List<String> missingFields;

  const SignupFailure({
    required this.uid,
    required this.stage,
    this.errorCode,
    required this.error,
    this.attemptedFields = const [],
    this.platform,
    this.attemptedAt,
    this.resolved = false,
    this.displayName,
    this.email,
    this.phone,
    this.gender,
    this.completionPercent,
    this.missingFields = const [],
  });

  factory SignupFailure.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    return SignupFailure(
      uid: data['uid'] as String? ?? doc.id,
      stage: data['stage'] as String? ?? 'unknown',
      errorCode: data['error_code'] as String?,
      error: data['error'] as String? ?? 'Unknown error',
      attemptedFields:
          (data['attempted_fields'] as List?)?.whereType<String>().toList() ??
              const [],
      platform: data['platform'] as String?,
      attemptedAt: (data['attempted_at'] as Timestamp?)?.toDate(),
      resolved: data['resolved'] as bool? ?? false,
    );
  }

  /// Build an incomplete-profile row from a users/{uid} doc, surfacing the
  /// partial data autosave captured and computing what's still missing.
  factory SignupFailure.fromIncompleteUser(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    String? s(String k) {
      final v = data[k];
      return (v is String && v.trim().isNotEmpty) ? v : null;
    }

    final name = s('name') ?? s('display_name') ?? s('first_name');
    final phone = s('phone') ?? s('phone_number');
    final hasAvatar = s('avatar_url') != null;
    final hasDob = data['date_of_birth'] != null;
    final gender = s('gender');

    final missing = <String>[
      if (name == null) 'name',
      if (phone == null) 'phone',
      if (!hasAvatar) 'avatar',
      if (!hasDob) 'birth date',
      if (gender == null) 'gender',
    ];

    final pct = data['profile_completion_percentage'];

    return SignupFailure(
      uid: doc.id,
      stage: 'profile_incomplete',
      error: 'User signed up but never completed profile',
      attemptedAt: (data['created_at'] as Timestamp?)?.toDate(),
      platform: s('auth_provider'),
      attemptedFields: const [],
      displayName: name,
      email: s('email'),
      phone: phone,
      gender: gender,
      completionPercent: pct is num ? pct.toInt() : null,
      missingFields: missing,
    );
  }

  /// Human-friendly explanation of what stage failed.
  String get stageLabel {
    switch (stage) {
      case 'sync_user_data_create':
        return 'Creating user profile';
      case 'verify_otp_signup':
        return 'Saving signup details after OTP';
      case 'complete_profile':
        return 'Completing profile';
      default:
        return stage;
    }
  }
}
