import '../config/store_profile.dart';
import 'app_strings.dart';

/// Coaching-wording layer applied on iOS only (see [isAppleCoachingBuild]).
/// Rewrites already-resolved strings; the source strings are untouched.
class CoachingWording {
  CoachingWording._();

  /// Therapist-portal / registration strings that are not patient-facing.
  static final Set<String> _excludedArabic = {
    AppStrings.therapistDashboard,
    AppStrings.registerAsTherapist,
    AppStrings.therapistRegistration,
    AppStrings.egClinicalPsychologist,
    AppStrings.becomeTherapist,
    AppStrings.becomeTherapistDesc,
    AppStrings.bankAccountHolder,
    // AI consent, data-processing and safety copy: meaning must not change.
    AppStrings.aiPatientConsentRequired,
    AppStrings.aiPrivacyProcessorsTitle,
    AppStrings.aiPrivacyProcessorsBody,
    AppStrings.aiPrivacyAccessTitle,
    AppStrings.aiPrivacyAccessBody,
    AppStrings.aiDisclaimer,
    AppStrings.therapistDisclaimer,
    AppStrings.mentalHealthWarning,
  };

  static bool isExcluded(String arabic) => _excludedArabic.contains(arabic);

  static String apply(String value, String lang, String arabicSource) {
    if (!isAppleCoachingBuild || isExcluded(arabicSource)) return value;
    if (value.contains('Sanad Therapy')) {
      return value
          .split('Sanad Therapy')
          .map((p) => apply(p, lang, arabicSource))
          .join('Sanad Therapy');
    }
    switch (lang) {
      case 'ar':
        return _run(value, _ar);
      case 'en':
        return _run(value, _en);
      default:
        return _run(value, _fr);
    }
  }

  /// For hard-coded literals whose language is not known: Arabic is detected
  /// by script, otherwise English then French rules are tried.
  static String any(String value) {
    if (!isAppleCoachingBuild) return value;
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
      return apply(value, 'ar', value);
    }
    return apply(apply(value, 'en', value), 'fr', value);
  }

  static String _run(String v, List<_Rule> rules) {
    for (final r in rules) {
      v = v.replaceAllMapped(r.pattern, r.build);
    }
    return v;
  }

  static final List<_Rule> _ar = [
    _Rule.s(r'معالج(?:اً|ا)? نفسي(?:اً|ا)? معتمد', 'كوتش معتمد'),
    _Rule.s(r'معالج(?:اً|ا)? نفسي(?:اً|ا)?', 'كوتش'),
    _Rule.s(r'معالج مرخص', 'كوتش معتمد'),
    _Rule.s(r'مكتبة موارد العلاج', 'مكتبة موارد التطوير الذاتي'),
    _Rule.s(r'الاختبارات النفسية', 'اختبارات التقييم الذاتي'),
    _Rule.s(r'اختبارات ومقاييس نفسية', 'اختبارات ومقاييس تقييم ذاتي'),
    _Rule.s(r'اختبارات نفسية', 'اختبارات تقييم ذاتي'),
    _Rule.s(r'إرشاد زواجي', 'كوتشينج العلاقات'),
    _Rule.s(r'الإرشاد الزواجي', 'كوتشينج العلاقات'),
    _Rule.s(r'الصحة النفسية', 'العافية والتطوير الذاتي'),
    _Rule.s(r'الطوارئ النفسية', 'الطوارئ'),
    _Rule.s(r'الدعم النفسي', 'دعم التطوير الشخصي'),
    _Rule.s(r'دعم نفسي', 'دعم التطوير الشخصي'),
    _Rule.s(r'أسلوبك العلاجي', 'أسلوبك في الكوتشينج'),
    _Rule.s(r'خطة علاج', 'خطة كوتشينج'),
    _Rule.s(r'(ال)?معالجين', r'$1كوتشز', raw: true),
    _Rule.s(r'(ال)?معالجون(ا)?', r'$1كوتشز', raw: true),
    _Rule.s(r'معالج(?![ةت])', 'كوتش'),
    _Rule.s(r'علاجي(?:ة|ا|اً)?', 'كوتشينج'),
    _Rule.s(r'العلاج', 'الكوتشينج'),
    _Rule.s(r'علاج', 'كوتشينج'),
  ];

  static final List<_Rule> _en = [
    _Rule.s(r'psychological tests?', 'self-assessments', ci: true),
    _Rule.s(r'mental health', 'wellbeing', ci: true),
    _Rule.s(r'licensed (?:therapist|psychologist)', 'certified coach'),
    _Rule.s(r'Licensed (?:therapist|psychologist)', 'Certified coach'),
    _Rule.s(r'therapists', 'coaches'),
    _Rule.s(r'Therapists', 'Coaches'),
    _Rule.s(r'therapist', 'coach'),
    _Rule.s(r'Therapist', 'Coach'),
    _Rule.s(r'therapy', 'coaching'),
    _Rule.s(r'Therapy', 'Coaching'),
    _Rule.s(r'psychologists?', 'coach'),
    _Rule.s(r'treatment plan', 'coaching plan'),
  ];

  static final List<_Rule> _fr = [
    _Rule.s(r'tests psychologiques', 'auto-évaluations'),
    _Rule.s(r'Tests psychologiques', 'Auto-évaluations'),
    _Rule.s(r'santé mentale', 'bien-être'),
    _Rule.s(r'thérapeutes', 'coachs'),
    _Rule.s(r'Thérapeutes', 'Coachs'),
    _Rule.s(r'thérapeutique', 'de coaching'),
    _Rule.s(r'thérapeute', 'coach'),
    _Rule.s(r'Thérapeute', 'Coach'),
    _Rule.s(r'thérapie', 'coaching'),
    _Rule.s(r'Thérapie', 'Coaching'),
    _Rule.s(r'psychologue', 'coach'),
    _Rule.s(r'plan de traitement', 'plan de coaching'),
    _Rule.s(r'Plan de traitement', 'Plan de coaching'),
    _Rule.s(r'échelles psychologiques', 'échelles d\'auto-évaluation'),
  ];
}

class _Rule {
  final RegExp pattern;
  final String replacement;
  _Rule(this.pattern, this.replacement);

  factory _Rule.s(String p, String r, {bool ci = false, bool raw = false}) =>
      _Rule(RegExp(p, caseSensitive: !ci, unicode: true), r);

  String build(Match m) {
    var out = replacement;
    for (var i = 1; i <= m.groupCount; i++) {
      out = out.replaceAll('\$$i', m.group(i) ?? '');
    }
    return out;
  }
}
