import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum QuickActionType {
  logMood,
  startChat,
  newPost,
  bookSession,
  moodHistory,
  findTherapist,
  emergency,
}

class QuickActionConfig {
  final QuickActionType type;
  final bool isEnabled;
  final int order;

  const QuickActionConfig({
    required this.type,
    this.isEnabled = true,
    this.order = 0,
  });

  QuickActionConfig copyWith({
    QuickActionType? type,
    bool? isEnabled,
    int? order,
  }) {
    return QuickActionConfig(
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }

  // Metadata for each action type
  static String getLabel(QuickActionType type, dynamic s) {
    return switch (type) {
      QuickActionType.logMood => s.qaLogMood,
      QuickActionType.startChat => s.qaStartChat,
      QuickActionType.newPost => s.qaNewPost,
      QuickActionType.bookSession => s.qaBookSession,
      QuickActionType.moodHistory => s.qaMoodHistory,
      QuickActionType.findTherapist => s.qaFindTherapist,
      QuickActionType.emergency => s.qaCrisisSupport,
    };
  }

  static String getDescription(QuickActionType type, dynamic s) {
    return switch (type) {
      QuickActionType.logMood => s.qaLogMoodDesc,
      QuickActionType.startChat => s.qaStartChatDesc,
      QuickActionType.newPost => s.qaNewPostDesc,
      QuickActionType.bookSession => s.qaBookSessionDesc,
      QuickActionType.moodHistory => s.qaMoodHistoryDesc,
      QuickActionType.findTherapist => s.qaFindTherapistDesc,
      QuickActionType.emergency => s.qaCrisisSupportDesc,
    };
  }

  static IconData getIcon(QuickActionType type) {
    return switch (type) {
      QuickActionType.logMood => Icons.mood_rounded,
      QuickActionType.startChat => Icons.chat_bubble_outline_rounded,
      QuickActionType.newPost => Icons.edit_note_rounded,
      QuickActionType.bookSession => Icons.calendar_today_rounded,
      QuickActionType.moodHistory => Icons.bar_chart_rounded,
      QuickActionType.findTherapist => Icons.person_search_rounded,
      QuickActionType.emergency => Icons.emergency_rounded,
    };
  }

  static Color getColor(QuickActionType type) {
    return switch (type) {
      QuickActionType.logMood => AppColors.moodHappy,
      QuickActionType.startChat => AppColors.primary,
      QuickActionType.newPost => AppColors.moodCalm,
      QuickActionType.bookSession => const Color(0xFFEC4899),
      QuickActionType.moodHistory => const Color(0xFF8B5CF6),
      QuickActionType.findTherapist => const Color(0xFF14B8A6),
      QuickActionType.emergency => const Color(0xFFEF4444),
    };
  }
}

// Default configuration
const defaultQuickActions = [
  QuickActionConfig(type: QuickActionType.logMood, order: 0),
  QuickActionConfig(type: QuickActionType.startChat, order: 1),
  QuickActionConfig(type: QuickActionType.newPost, order: 2),
  QuickActionConfig(type: QuickActionType.bookSession, order: 3),
];
