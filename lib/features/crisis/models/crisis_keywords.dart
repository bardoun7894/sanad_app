class CrisisDetectionResult {
  final bool isCrisis;
  final String severity; // 'critical', 'high', 'none'
  final List<String> matchedKeywords;
  final String detectedLanguage;

  const CrisisDetectionResult({
    required this.isCrisis,
    required this.severity,
    this.matchedKeywords = const [],
    this.detectedLanguage = 'unknown',
  });

  static const CrisisDetectionResult none = CrisisDetectionResult(
    isCrisis: false,
    severity: 'none',
  );
}

class CrisisKeywords {
  // Tier 1: Critical/Immediate - Explicit self-harm keywords
  // These bypass AI confirmation and trigger instant response
  static const Map<String, List<String>> criticalKeywords = {
    'ar': [
      'انتحار',
      'اقتل نفسي',
      'أقتل نفسي',
      'أريد الموت',
      'أنهي حياتي',
      'انهي حياتي',
      'جرح نفسي',
      'أجرح نفسي',
      'إيذاء النفس',
      'ايذاء النفس',
      'سأنتحر',
      'قررت الانتحار',
      'أريد أن أموت',
      'اريد ان اموت',
      'لا أريد أن أعيش',
      'لا اريد ان اعيش',
      'أفضل لو كنت ميتاً',
      'افضل لو كنت ميتا',
      'سأقطع شراييني',
      'الحبوب المنومة',
      'جرعة زائدة',
    ],
    'en': [
      'suicide',
      'kill myself',
      'end my life',
      'want to die',
      "don't want to live",
      'dont want to live',
      'hurt myself',
      'self harm',
      'self-harm',
      'cutting myself',
      'overdose',
      'no reason to live',
      'better off dead',
      'ending it all',
      'slit my wrists',
      'jump off',
      'hang myself',
      'take my life',
      'plan to die',
    ],
    'fr': [
      'suicide',
      'me tuer',
      'en finir',
      'envie de mourir',
      'plus envie de vivre',
      'me faire du mal',
      'automutilation',
      'me couper',
      'overdose',
      'mettre fin à mes jours',
      'sauter du pont',
      'me pendre',
      'pas de raison de vivre',
      'mieux mort',
    ],
  };

  // Tier 2: High/Needs Confirmation - Ambiguous distress indicators
  // These are sent through but trigger background AI confirmation
  static const Map<String, List<String>> highKeywords = {
    'ar': [
      'لا فائدة من الحياة',
      'الحياة لا تستحق',
      'لا أحد يهتم',
      'لا احد يهتم',
      'أنا وحيد تماماً',
      'انا وحيد تماما',
      'لا أمل',
      'لا امل',
      'اليأس',
      'كل شيء ضدي',
      'لا أستطيع التحمل',
      'لا استطيع التحمل',
      'أريد أن أختفي',
      'اريد ان اختفي',
      'تعبت من الحياة',
      'مرهق نفسياً',
    ],
    'en': [
      'no point in living',
      'life is not worth',
      'nobody cares',
      'completely alone',
      'no hope',
      'hopeless',
      'despair',
      'everything is against me',
      "can't take it anymore",
      'cant take it anymore',
      'want to disappear',
      'tired of living',
      'mentally exhausted',
      'given up',
      'nothing matters',
      'wish i was never born',
    ],
    'fr': [
      'aucun sens à la vie',
      'la vie ne vaut pas',
      'personne ne se soucie',
      'complètement seul',
      'aucun espoir',
      'désespoir',
      'tout est contre moi',
      'je ne peux plus supporter',
      'vouloir disparaître',
      'fatigué de vivre',
      'épuisé mentalement',
      'j\'ai abandonné',
      'rien n\'a d\'importance',
    ],
  };

  /// Analyze a message for crisis keywords.
  /// Returns a [CrisisDetectionResult] with severity and matched keywords.
  static CrisisDetectionResult analyze(String message) {
    final lowerMessage = message.toLowerCase();

    // Check Tier 1 (Critical) keywords first
    final criticalMatches = <String>[];
    String detectedLang = 'unknown';

    for (final entry in criticalKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          criticalMatches.add(keyword);
          detectedLang = entry.key;
        }
      }
    }

    if (criticalMatches.isNotEmpty) {
      return CrisisDetectionResult(
        isCrisis: true,
        severity: 'critical',
        matchedKeywords: criticalMatches,
        detectedLanguage: detectedLang,
      );
    }

    // Check Tier 2 (High) keywords
    final highMatches = <String>[];

    for (final entry in highKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          highMatches.add(keyword);
          detectedLang = entry.key;
        }
      }
    }

    if (highMatches.isNotEmpty) {
      return CrisisDetectionResult(
        isCrisis: true,
        severity: 'high',
        matchedKeywords: highMatches,
        detectedLanguage: detectedLang,
      );
    }

    return CrisisDetectionResult.none;
  }
}
