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

enum SessionType {
  video,
  audio,
  chat,
}

class SessionTypeData {
  static String getLabel(SessionType type, {S? strings}) {
    // Use provided strings or default to English if not provided
    final s = strings;

    return switch (type) {
      SessionType.video => s?.sessionVideo ?? 'Video Call',
      SessionType.audio => s?.sessionAudio ?? 'Audio Call',
      SessionType.chat => s?.sessionChat ?? 'Chat Session',
    };
  }

  static IconData getIcon(SessionType type) {
    return switch (type) {
      SessionType.video => Icons.videocam_outlined,
      SessionType.audio => Icons.call_outlined,
      SessionType.chat => Icons.chat_outlined,
    };
  }
}

class TimeSlot {
  final DateTime dateTime;
  final bool isAvailable;

  const TimeSlot({
    required this.dateTime,
    this.isAvailable = true,
  });
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
