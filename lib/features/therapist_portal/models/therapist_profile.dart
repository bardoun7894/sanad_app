import 'package:cloud_firestore/cloud_firestore.dart';
import '../../therapists/models/therapist.dart';

/// Approval status for therapist registration
enum TherapistApprovalStatus {
  pending, // Awaiting admin review
  approved, // Approved by admin - can access dashboard
  rejected, // Rejected by admin
  suspended, // Temporarily suspended
}

/// Extension methods for TherapistApprovalStatus
extension TherapistApprovalStatusX on TherapistApprovalStatus {
  String get name {
    switch (this) {
      case TherapistApprovalStatus.pending:
        return 'pending';
      case TherapistApprovalStatus.approved:
        return 'approved';
      case TherapistApprovalStatus.rejected:
        return 'rejected';
      case TherapistApprovalStatus.suspended:
        return 'suspended';
    }
  }

  static TherapistApprovalStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return TherapistApprovalStatus.approved;
      case 'rejected':
        return TherapistApprovalStatus.rejected;
      case 'suspended':
        return TherapistApprovalStatus.suspended;
      case 'pending':
      default:
        return TherapistApprovalStatus.pending;
    }
  }
}

/// Therapist profile model for the therapist portal
/// This represents a therapist's full profile including registration data
class TherapistProfile {
  final String id; // Same as Firebase Auth UID
  final String email;
  final String name;
  // Multi-language name variants (empty string = not set)
  final String nameAr;
  final String nameEn;
  final String nameFr;
  final String? title;
  // Multi-language title variants (empty string = not set)
  final String titleAr;
  final String titleEn;
  final String titleFr;
  final String? bio;
  // Multi-language bio variants (empty string = not set)
  final String bioAr;
  final String bioEn;
  final String bioFr;
  final String? photoUrl;
  final List<Specialty> specialties;
  final List<SessionType> sessionTypes;
  final List<TherapyType> therapyTypes;
  final List<String> languages;
  final List<String> qualifications;
  final double sessionPrice;
  final String currency;
  final int yearsExperience;
  final TherapistApprovalStatus approvalStatus;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final String? licenseDocumentUrl;
  final String? phoneNumber;

  const TherapistProfile({
    required this.id,
    required this.email,
    required this.name,
    this.nameAr = '',
    this.nameEn = '',
    this.nameFr = '',
    this.title,
    this.titleAr = '',
    this.titleEn = '',
    this.titleFr = '',
    this.bio,
    this.bioAr = '',
    this.bioEn = '',
    this.bioFr = '',
    this.photoUrl,
    this.specialties = const [],
    this.sessionTypes = const [],
    this.therapyTypes = const [TherapyType.individual],
    this.languages = const [],
    this.qualifications = const [],
    this.sessionPrice = 0.0,
    this.currency = 'SAR',
    this.yearsExperience = 0,
    this.approvalStatus = TherapistApprovalStatus.pending,
    this.isActive = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.licenseDocumentUrl,
    this.phoneNumber,
  });

  /// Create a copy with updated fields
  TherapistProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? nameAr,
    String? nameEn,
    String? nameFr,
    String? title,
    String? titleAr,
    String? titleEn,
    String? titleFr,
    String? bio,
    String? bioAr,
    String? bioEn,
    String? bioFr,
    String? photoUrl,
    List<Specialty>? specialties,
    List<SessionType>? sessionTypes,
    List<TherapyType>? therapyTypes,
    List<String>? languages,
    List<String>? qualifications,
    double? sessionPrice,
    String? currency,
    int? yearsExperience,
    TherapistApprovalStatus? approvalStatus,
    bool? isActive,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
    String? licenseDocumentUrl,
    String? phoneNumber,
  }) {
    return TherapistProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      nameFr: nameFr ?? this.nameFr,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      titleEn: titleEn ?? this.titleEn,
      titleFr: titleFr ?? this.titleFr,
      bio: bio ?? this.bio,
      bioAr: bioAr ?? this.bioAr,
      bioEn: bioEn ?? this.bioEn,
      bioFr: bioFr ?? this.bioFr,
      photoUrl: photoUrl ?? this.photoUrl,
      specialties: specialties ?? this.specialties,
      sessionTypes: sessionTypes ?? this.sessionTypes,
      therapyTypes: therapyTypes ?? this.therapyTypes,
      languages: languages ?? this.languages,
      qualifications: qualifications ?? this.qualifications,
      sessionPrice: sessionPrice ?? this.sessionPrice,
      currency: currency ?? this.currency,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      licenseDocumentUrl: licenseDocumentUrl ?? this.licenseDocumentUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  /// Create from JSON map (same as Firestore data)
  factory TherapistProfile.fromJson(Map<String, dynamic> json) {
    final legacyName = json['name'] as String? ?? '';
    final legacyBio = json['bio'] as String?;
    final legacyTitle = json['title'] as String?;
    return TherapistProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: legacyName,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameFr: json['name_fr'] as String? ?? '',
      title: legacyTitle,
      titleAr: json['title_ar'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      titleFr: json['title_fr'] as String? ?? '',
      bio: legacyBio,
      bioAr: json['bio_ar'] as String? ?? '',
      bioEn: json['bio_en'] as String? ?? '',
      bioFr: json['bio_fr'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      specialties: _parseSpecialties(json['specialties']),
      sessionTypes: _parseSessionTypes(json['session_types']),
      therapyTypes: _parseTherapyTypes(json['therapy_types']),
      languages: List<String>.from(json['languages'] ?? []),
      qualifications: List<String>.from(json['qualifications'] ?? []),
      sessionPrice: (json['session_price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'SAR',
      yearsExperience: json['years_experience'] as int? ?? 0,
      approvalStatus: TherapistApprovalStatusX.fromString(
        json['approval_status'] as String?,
      ),
      isActive: json['is_active'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      approvedAt: _parseDateTime(json['approved_at']),
      approvedBy: json['approved_by'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      licenseDocumentUrl: json['license_document_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  /// Create from Firestore document
  factory TherapistProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TherapistProfile(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      nameAr: data['name_ar'] as String? ?? '',
      nameEn: data['name_en'] as String? ?? '',
      nameFr: data['name_fr'] as String? ?? '',
      title: data['title'] as String?,
      titleAr: data['title_ar'] as String? ?? '',
      titleEn: data['title_en'] as String? ?? '',
      titleFr: data['title_fr'] as String? ?? '',
      bio: data['bio'] as String?,
      bioAr: data['bio_ar'] as String? ?? '',
      bioEn: data['bio_en'] as String? ?? '',
      bioFr: data['bio_fr'] as String? ?? '',
      photoUrl: data['photo_url'] as String?,
      specialties: _parseSpecialties(data['specialties']),
      sessionTypes: _parseSessionTypes(data['session_types']),
      therapyTypes: _parseTherapyTypes(data['therapy_types']),
      languages: List<String>.from(data['languages'] ?? []),
      qualifications: List<String>.from(data['qualifications'] ?? []),
      sessionPrice: (data['session_price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'SAR',
      yearsExperience: data['years_experience'] as int? ?? 0,
      approvalStatus: TherapistApprovalStatusX.fromString(
        data['approval_status'] as String?,
      ),
      isActive: data['is_active'] as bool? ?? false,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] as int? ?? 0,
      createdAt: _parseDateTime(data['created_at']) ?? DateTime.now(),
      approvedAt: _parseDateTime(data['approved_at']),
      approvedBy: data['approved_by'] as String?,
      rejectionReason: data['rejection_reason'] as String?,
      licenseDocumentUrl: data['license_document_url'] as String?,
      phoneNumber: data['phone_number'] as String?,
    );
  }

  /// Localized name — falls back to nameAr, then legacy name.
  String localizedName(String langCode) {
    final code = langCode.toLowerCase();
    if (code.startsWith('en') && nameEn.trim().isNotEmpty) return nameEn;
    if (code.startsWith('fr') && nameFr.trim().isNotEmpty) return nameFr;
    if (nameAr.trim().isNotEmpty) return nameAr;
    return name; // legacy fallback
  }

  /// Localized bio — falls back to bioAr, then legacy bio.
  String localizedBio(String langCode) {
    final code = langCode.toLowerCase();
    if (code.startsWith('en') && bioEn.trim().isNotEmpty) return bioEn;
    if (code.startsWith('fr') && bioFr.trim().isNotEmpty) return bioFr;
    if (bioAr.trim().isNotEmpty) return bioAr;
    return bio ?? ''; // legacy fallback
  }

  /// Localized title — falls back to titleAr, then legacy title.
  String localizedTitle(String langCode) {
    final code = langCode.toLowerCase();
    if (code.startsWith('en') && titleEn.trim().isNotEmpty) return titleEn;
    if (code.startsWith('fr') && titleFr.trim().isNotEmpty) return titleFr;
    if (titleAr.trim().isNotEmpty) return titleAr;
    return title ?? ''; // legacy fallback
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    // Legacy un-suffixed fields get the AR variant (or whatever non-empty value
    // exists) for backwards-compat with screens that haven't been updated.
    final legacyName = nameAr.trim().isNotEmpty ? nameAr : name;
    final legacyBioValue = bioAr.trim().isNotEmpty ? bioAr : (bio ?? '');
    final legacyTitleValue = titleAr.trim().isNotEmpty ? titleAr : (title ?? '');
    return {
      'email': email,
      'name': legacyName,
      'name_ar': nameAr,
      'name_en': nameEn,
      'name_fr': nameFr,
      'title': legacyTitleValue,
      'title_ar': titleAr,
      'title_en': titleEn,
      'title_fr': titleFr,
      'bio': legacyBioValue,
      'bio_ar': bioAr,
      'bio_en': bioEn,
      'bio_fr': bioFr,
      'photo_url': photoUrl,
      'specialties': specialties.map((s) => s.name).toList(),
      'session_types': sessionTypes.map((s) => s.firestoreValue).toList(),
      'therapy_types': therapyTypes.map((s) => s.name).toList(),
      'languages': languages,
      'qualifications': qualifications,
      'session_price': sessionPrice,
      'currency': currency,
      'years_experience': yearsExperience,
      'approval_status': approvalStatus.name,
      'is_active': isActive,
      'rating': rating,
      'review_count': reviewCount,
      'created_at': Timestamp.fromDate(createdAt),
      'approved_at': approvedAt != null
          ? Timestamp.fromDate(approvedAt!)
          : null,
      'approved_by': approvedBy,
      'rejection_reason': rejectionReason,
      'license_document_url': licenseDocumentUrl,
      'phone_number': phoneNumber,
    };
  }

  /// Convert to client-facing Therapist model
  Therapist toTherapist() {
    return Therapist(
      id: id,
      name: name,
      nameAr: nameAr,
      nameEn: nameEn,
      nameFr: nameFr,
      title: title ?? '',
      titleAr: titleAr,
      titleEn: titleEn,
      titleFr: titleFr,
      imageUrl: photoUrl,
      bio: bio ?? '',
      bioAr: bioAr,
      bioEn: bioEn,
      bioFr: bioFr,
      specialties: specialties,
      sessionTypes: sessionTypes,
      therapyTypes: therapyTypes,
      rating: rating,
      reviewCount: reviewCount,
      yearsExperience: yearsExperience,
      sessionPrice: sessionPrice,
      currency: currency,
      languages: languages,
      qualifications: qualifications,
      isAvailableToday: isActive,
    );
  }

  /// Helper to parse DateTime from Firestore
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Helper to parse specialties from Firestore
  static List<Specialty> _parseSpecialties(dynamic value) {
    if (value == null) return [];
    final list = value as List<dynamic>? ?? [];
    return list.map((s) {
      final str = s.toString().toLowerCase();
      // Handle Arabic mapping if needed, or other variations
      return Specialty.values.firstWhere(
        (spec) => spec.name.toLowerCase() == str,
        orElse: () => Specialty.anxiety, // Default fallback
      );
    }).toList();
  }

  /// Helper to parse session types from Firestore
  /// Accepts both legacy 'inPerson' and canonical 'in_person'.
  static List<SessionType> _parseSessionTypes(dynamic value) {
    if (value == null) return [];
    final list = value as List<dynamic>? ?? [];
    return list
        .map((s) => SessionTypeFirestore.fromFirestore(s as String?))
        .toSet()
        .toList();
  }

  /// Helper to parse therapy types from Firestore
  static List<TherapyType> _parseTherapyTypes(dynamic value) {
    // If missing from Firestore, default to ALL types to ensure visibility in filters
    // This fixes the issue where legacy data missing this field causes "No Therapists Found"
    if (value == null) {
      return [TherapyType.individual, TherapyType.couples, TherapyType.teen];
    }

    final list = value as List<dynamic>? ?? [];
    if (list.isEmpty) {
      return [TherapyType.individual, TherapyType.couples, TherapyType.teen];
    }

    return list
        .map(
          (s) => TherapyType.values.firstWhere(
            (type) => type.name == s,
            orElse: () => TherapyType.individual,
          ),
        )
        .toList();
  }

  /// Check if profile is complete for registration
  bool get isProfileComplete {
    return name.isNotEmpty &&
        email.isNotEmpty &&
        specialties.isNotEmpty &&
        sessionTypes.isNotEmpty &&
        bio != null &&
        bio!.isNotEmpty &&
        yearsExperience > 0 &&
        sessionPrice > 0;
  }

  /// Check if therapist can accept bookings
  bool get canAcceptBookings {
    return approvalStatus == TherapistApprovalStatus.approved && isActive;
  }

  @override
  String toString() {
    return 'TherapistProfile(id: $id, name: $name, status: ${approvalStatus.name}, isActive: $isActive)';
  }
}
