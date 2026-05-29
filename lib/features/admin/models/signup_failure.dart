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
