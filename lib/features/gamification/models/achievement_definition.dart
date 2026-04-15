/// Defines a gamification achievement with localized metadata
class AchievementDefinition {
  final String id;
  final String titleAr;
  final String titleEn;
  final String titleFr;
  final String descriptionAr;
  final String descriptionEn;
  final String descriptionFr;
  final String icon;
  final int xpReward;
  final String condition;

  const AchievementDefinition({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.titleFr,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.icon,
    required this.xpReward,
    required this.condition,
  });

  /// Returns the localized title based on locale code
  String getLocalizedTitle(String locale) {
    switch (locale) {
      case 'ar':
        return titleAr;
      case 'fr':
        return titleFr;
      default:
        return titleEn;
    }
  }

  /// Returns the localized description based on locale code
  String getLocalizedDescription(String locale) {
    switch (locale) {
      case 'ar':
        return descriptionAr;
      case 'fr':
        return descriptionFr;
      default:
        return descriptionEn;
    }
  }
}

/// Static registry of all gamification achievements
class AchievementDefinitions {
  AchievementDefinitions._();

  static const List<AchievementDefinition> all = [
    AchievementDefinition(
      id: 'first_mood_log',
      titleAr: 'الخطوة الأولى',
      titleEn: 'First Step',
      titleFr: 'Premier Pas',
      descriptionAr: 'سجّل حالتك المزاجية لأول مرة',
      descriptionEn: 'Logged your first mood',
      descriptionFr: 'Enregistrez votre premier humeur',
      icon: 'emoji_emotions',
      xpReward: 10,
      condition: 'Log mood for the first time',
    ),
    AchievementDefinition(
      id: 'week_streak',
      titleAr: 'محارب الأسبوع',
      titleEn: 'Week Warrior',
      titleFr: 'Guerrier de la Semaine',
      descriptionAr: 'حافظ على سلسلة 7 أيام متتالية',
      descriptionEn: 'Maintained a 7-day streak',
      descriptionFr: 'Maintenez une série de 7 jours',
      icon: 'local_fire_department',
      xpReward: 50,
      condition: 'Reach a 7-day activity streak',
    ),
    AchievementDefinition(
      id: 'month_streak',
      titleAr: 'بطل الشهر',
      titleEn: 'Monthly Champion',
      titleFr: 'Champion du Mois',
      descriptionAr: 'حافظ على سلسلة 30 يومًا متتالية',
      descriptionEn: 'Maintained a 30-day streak',
      descriptionFr: 'Maintenez une série de 30 jours',
      icon: 'military_tech',
      xpReward: 200,
      condition: 'Reach a 30-day activity streak',
    ),
    AchievementDefinition(
      id: 'first_chat',
      titleAr: 'أول محادثة',
      titleEn: 'First Chat',
      titleFr: 'Premier Chat',
      descriptionAr: 'أجريت أول محادثة مع الذكاء الاصطناعي',
      descriptionEn: 'Started your first AI chat',
      descriptionFr: 'Démarrez votre premier chat IA',
      icon: 'chat_bubble',
      xpReward: 10,
      condition: 'Send first message in AI chat',
    ),
    AchievementDefinition(
      id: 'first_session',
      titleAr: 'بداية شجاعة',
      titleEn: 'Brave Start',
      titleFr: 'Départ Courageux',
      descriptionAr: 'أكملت أول جلسة علاجية',
      descriptionEn: 'Completed your first therapy session',
      descriptionFr: 'Terminé votre première séance de thérapie',
      icon: 'psychology',
      xpReward: 30,
      condition: 'Complete first therapy session',
    ),
    AchievementDefinition(
      id: 'community_first',
      titleAr: 'صوت المجتمع',
      titleEn: 'Community Voice',
      titleFr: 'Voix Communautaire',
      descriptionAr: 'نشرت أول مشاركة في المجتمع',
      descriptionEn: 'Made your first community post',
      descriptionFr: 'Créez votre premier post communautaire',
      icon: 'forum',
      xpReward: 10,
      condition: 'Create first community post',
    ),
    AchievementDefinition(
      id: 'chapter_complete',
      titleAr: 'قارئ نشط',
      titleEn: 'Active Learner',
      titleFr: 'Apprenant Actif',
      descriptionAr: 'أكملت أول فصل في رحلة',
      descriptionEn: 'Completed your first journey chapter',
      descriptionFr: 'Terminé votre premier chapitre',
      icon: 'menu_book',
      xpReward: 25,
      condition: 'Complete first journey chapter',
    ),
    AchievementDefinition(
      id: 'journey_complete',
      titleAr: 'مسافر متمرّس',
      titleEn: 'Journey Master',
      titleFr: 'Maître du Voyage',
      descriptionAr: 'أكملت رحلة كاملة',
      descriptionEn: 'Completed an entire journey',
      descriptionFr: 'Terminé un voyage complet',
      icon: 'explore',
      xpReward: 100,
      condition: 'Complete all chapters of a journey',
    ),
    AchievementDefinition(
      id: 'level_5',
      titleAr: 'المستوى 5',
      titleEn: 'Level 5',
      titleFr: 'Niveau 5',
      descriptionAr: 'وصلت إلى المستوى الخامس',
      descriptionEn: 'Reached level 5',
      descriptionFr: 'Atteint le niveau 5',
      icon: 'star',
      xpReward: 50,
      condition: 'Reach level 5',
    ),
    AchievementDefinition(
      id: 'level_10',
      titleAr: 'المستوى 10',
      titleEn: 'Level 10',
      titleFr: 'Niveau 10',
      descriptionAr: 'وصلت إلى المستوى العاشر',
      descriptionEn: 'Reached level 10',
      descriptionFr: 'Atteint le niveau 10',
      icon: 'star_half',
      xpReward: 100,
      condition: 'Reach level 10',
    ),
    AchievementDefinition(
      id: 'level_25',
      titleAr: 'المستوى 25',
      titleEn: 'Level 25',
      titleFr: 'Niveau 25',
      descriptionAr: 'وصلت إلى المستوى الخامس والعشرين',
      descriptionEn: 'Reached level 25',
      descriptionFr: 'Atteint le niveau 25',
      icon: 'stars',
      xpReward: 250,
      condition: 'Reach level 25',
    ),
    AchievementDefinition(
      id: 'mood_master_30',
      titleAr: 'خبير المزاج',
      titleEn: 'Mood Master',
      titleFr: 'Maître de l\'Humeur',
      descriptionAr: 'سجّل حالتك المزاجية 30 مرة',
      descriptionEn: 'Logged your mood 30 times',
      descriptionFr: 'Enregistrez votre humeur 30 fois',
      icon: 'insights',
      xpReward: 75,
      condition: 'Log mood 30 times',
    ),
    AchievementDefinition(
      id: 'challenge_champion_7',
      titleAr: 'بطل التحديات',
      titleEn: 'Challenge Champion',
      titleFr: 'Champion des Défis',
      descriptionAr: 'أكملت 7 تحديات يومية',
      descriptionEn: 'Completed 7 daily challenges',
      descriptionFr: 'Terminé 7 défis quotidiens',
      icon: 'emoji_events',
      xpReward: 50,
      condition: 'Complete 7 daily challenges',
    ),
    AchievementDefinition(
      id: 'review_writer',
      titleAr: 'كاتب مراجعات',
      titleEn: 'Review Writer',
      titleFr: 'Rédacteur d\'Avis',
      descriptionAr: 'كتبت أول تقييم لمعالج',
      descriptionEn: 'Left your first therapist review',
      descriptionFr: 'Laissez votre premier avis',
      icon: 'rate_review',
      xpReward: 15,
      condition: 'Leave a therapist review',
    ),
    AchievementDefinition(
      id: 'social_butterfly_10',
      titleAr: 'فراشة اجتماعية',
      titleEn: 'Social Butterfly',
      titleFr: 'Papillon Social',
      descriptionAr: 'نشرت 10 مشاركات في المجتمع',
      descriptionEn: 'Made 10 community posts',
      descriptionFr: 'Créez 10 posts communautaires',
      icon: 'people',
      xpReward: 50,
      condition: 'Create 10 community posts',
    ),
  ];

  /// Get achievement definition by ID
  static AchievementDefinition? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all achievement IDs
  static List<String> get allIds => all.map((a) => a.id).toList();
}
