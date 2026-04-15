import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';

enum Specialty {
  anxiety,
  depression,
  trauma,
  relationships,
  stress,
  selfEsteem,
  grief,
  addiction,
}

class SpecialtyData {
  static String getLabel(Specialty specialty, {S? strings}) {
    // Use provided strings or default to English if not provided
    final s = strings;

    return switch (specialty) {
      Specialty.anxiety => s?.specialtyAnxiety ?? 'Anxiety',
      Specialty.depression => s?.specialtyDepression ?? 'Depression',
      Specialty.trauma => s?.specialtyTrauma ?? 'Trauma & PTSD',
      Specialty.relationships => s?.specialtyRelationships ?? 'Relationships',
      Specialty.stress => s?.specialtyStress ?? 'Stress Management',
      Specialty.selfEsteem => s?.specialtySelfEsteem ?? 'Self-Esteem',
      Specialty.grief => s?.specialtyGrief ?? 'Grief & Loss',
      Specialty.addiction => s?.specialtyAddiction ?? 'Addiction',
    };
  }

  static IconData getIcon(Specialty specialty) {
    return switch (specialty) {
      Specialty.anxiety => Icons.psychology_outlined,
      Specialty.depression => Icons.cloud_outlined,
      Specialty.trauma => Icons.healing_outlined,
      Specialty.relationships => Icons.favorite_outline_rounded,
      Specialty.stress => Icons.spa_outlined,
      Specialty.selfEsteem => Icons.self_improvement_outlined,
      Specialty.grief => Icons.sentiment_dissatisfied_outlined,
      Specialty.addiction => Icons.smoke_free_outlined,
    };
  }

  static Color getColor(Specialty specialty) {
    return switch (specialty) {
      Specialty.anxiety => AppColors.moodAnxious,
      Specialty.depression => AppColors.moodSad,
      Specialty.trauma => const Color(0xFFEF4444),
      Specialty.relationships => const Color(0xFFEC4899),
      Specialty.stress => AppColors.moodCalm,
      Specialty.selfEsteem => AppColors.moodHappy,
      Specialty.grief => const Color(0xFF8B5CF6),
      Specialty.addiction => const Color(0xFF14B8A6),
    };
  }
}

enum TherapyType { individual, couples, teen }

class TherapyTypeData {
  static String getLabel(TherapyType type, {S? strings}) {
    final s = strings;
    return switch (type) {
      TherapyType.individual => s?.therapyIndividual ?? 'Individual Therapy',
      TherapyType.couples => s?.therapyCouples ?? 'Couples Therapy',
      TherapyType.teen => s?.therapyTeen ?? 'Teen Therapy',
    };
  }

  static String getDescription(TherapyType type, {S? strings}) {
    final s = strings;
    return switch (type) {
      TherapyType.individual =>
        s?.therapyIndividualDesc ??
            'Private sessions with a certified therapist',
      TherapyType.couples =>
        s?.therapyCouplesDesc ?? 'Improve relationships and resolve conflicts',
      TherapyType.teen =>
        s?.therapyTeenDesc ?? 'Specialized support for ages 13-18',
    };
  }

  static IconData getIcon(TherapyType type) {
    return switch (type) {
      TherapyType.individual => Icons.person_rounded,
      TherapyType.couples => Icons.favorite_rounded,
      TherapyType.teen => Icons.sentiment_satisfied_alt_rounded,
    };
  }

  static String getAsset(TherapyType type) {
    return switch (type) {
      TherapyType.individual => 'assets/images/individual_therapy.png',
      TherapyType.couples => 'assets/images/couples_therapy.png',
      TherapyType.teen => 'assets/images/teen_therapy.png',
    };
  }

  static Color getColor(TherapyType type) {
    return switch (type) {
      TherapyType.individual => AppColors.primary,
      TherapyType.couples => const Color(0xFFE11D48), // Rose-600
      TherapyType.teen => const Color(0xFFD97706), // Amber-600
    };
  }
}

enum SessionType { audio, chat, inPerson }

/// Maps Dart enum names to canonical Firestore snake_case values.
extension SessionTypeFirestore on SessionType {
  /// The canonical Firestore field value (snake_case).
  /// Always use this instead of `.name` when writing to Firestore.
  String get firestoreValue => switch (this) {
    SessionType.audio => 'audio',
    SessionType.chat => 'chat',
    SessionType.inPerson => 'in_person',
  };

  /// Parse a Firestore value back to a [SessionType].
  /// Accepts both legacy `inPerson` and canonical `in_person`.
  /// Unknown values (e.g. 'video') map to `audio`.
  static SessionType fromFirestore(String? value) => switch (value) {
    'audio' => SessionType.audio,
    'chat' => SessionType.chat,
    'in_person' || 'inPerson' => SessionType.inPerson,
    _ => SessionType.audio,
  };
}

class SessionTypeData {
  static String getLabel(SessionType type, {S? strings}) {
    final s = strings;

    return switch (type) {
      SessionType.audio => s?.sessionAudio ?? 'Audio Call',
      SessionType.chat => s?.sessionChat ?? 'Chat Session',
      SessionType.inPerson => s?.sessionInPerson ?? 'In-Person Session',
    };
  }

  static IconData getIcon(SessionType type) {
    return switch (type) {
      SessionType.audio => Icons.call_outlined,
      SessionType.chat => Icons.chat_outlined,
      SessionType.inPerson => Icons.location_on_outlined,
    };
  }
}

class TimeSlot {
  final DateTime dateTime;
  final bool isAvailable;

  const TimeSlot({required this.dateTime, this.isAvailable = true});
}

class Review {
  final String id;
  final String authorName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class Therapist {
  final String id;
  final String name;
  final String title;
  final String? imageUrl;
  final String bio;
  final List<Specialty> specialties;
  final List<SessionType> sessionTypes;
  final List<TherapyType> therapyTypes;
  final double rating;
  final int reviewCount;
  final int yearsExperience;
  final double sessionPrice;
  final String currency;
  final List<String> languages;
  final List<String> qualifications;
  final List<Review> reviews;
  final bool isAvailableToday;
  final String? nextAvailable;

  const Therapist({
    required this.id,
    required this.name,
    required this.title,
    this.imageUrl,
    required this.bio,
    required this.specialties,
    required this.sessionTypes,
    this.therapyTypes = const [TherapyType.individual], // Default to individual
    required this.rating,
    required this.reviewCount,
    required this.yearsExperience,
    required this.sessionPrice,
    this.currency = 'SAR',
    required this.languages,
    required this.qualifications,
    this.reviews = const [],
    this.isAvailableToday = false,
    this.nextAvailable,
  });

  String get formattedPrice => '$sessionPrice $currency';
}

class Booking {
  final String id;
  final Therapist therapist;
  final DateTime dateTime;
  final SessionType sessionType;
  final String status; // pending, confirmed, completed, cancelled

  const Booking({
    required this.id,
    required this.therapist,
    required this.dateTime,
    required this.sessionType,
    required this.status,
  });
}
