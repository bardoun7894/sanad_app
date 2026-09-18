import '../../../core/l10n/language_provider.dart';

/// Self-contained AR/EN/FR strings for the journal ("مذكرتي") feature.
/// Kept local (instead of the 7k-line global `S`) so the feature stays
/// cohesive and easy to maintain. Arabic is the base language.
class JournalStrings {
  final AppLanguage lang;
  const JournalStrings(this.lang);

  String _p(String ar, String en, String fr) {
    switch (lang) {
      case AppLanguage.arabic:
        return ar;
      case AppLanguage.english:
        return en;
      case AppLanguage.french:
        return fr;
    }
  }

  String get title => _p('مذكرتي', 'My Journal', 'Mon journal');
  String get privateSpace =>
      _p('مرحباً بك في مساحتك الخاصة', 'Welcome to your private space',
          'Bienvenue dans votre espace privé');
  String get privateSubtitle => _p(
      'اكتب ما في قلبك، دون حكم أو تصنيف.',
      'Write what is in your heart — no judgment.',
      'Écrivez ce que vous ressentez, sans jugement.');
  String get newEntry => _p('تدوينة جديدة', 'New entry', 'Nouvelle entrée');
  String get editEntry => _p('تعديل التدوينة', 'Edit entry', 'Modifier');
  String get searchHint =>
      _p('ابحث في مذكراتك...', 'Search your journal...', 'Rechercher...');
  String get all => _p('الكل', 'All', 'Tout');
  String get startWriting => _p('ابدأ الكتابة...', 'Start writing...', 'Commencez à écrire...');
  String get save => _p('حفظ', 'Save', 'Enregistrer');
  String get delete => _p('حذف', 'Delete', 'Supprimer');
  String get skip => _p('تخطي', 'Skip', 'Passer');
  String get tags => _p('وسوم', 'Tags', 'Étiquettes');
  String get addTag => _p('أضف وسماً', 'Add tag', 'Ajouter');
  String get howAreYouFeeling =>
      _p('كيف تشعر اليوم؟', 'How do you feel today?', "Comment vous sentez-vous ?");
  String get moodSubtitle => _p(
      'اختيار مشاعرك يساعدك على فهم نفسك أكثر',
      'Naming your feelings helps you understand yourself',
      'Nommer vos émotions vous aide à mieux vous comprendre');
  String get promptOfDay =>
      _p('سؤال اليوم (اختياري)', "Today's prompt (optional)", 'Question du jour (facultatif)');
  String get emptyTitle =>
      _p('لا توجد تدوينات بعد', 'No entries yet', 'Aucune entrée');
  String get emptySubtitle => _p(
      'ابدأ رحلتك بكتابة أول تدوينة',
      'Start your journey with your first entry',
      'Commencez avec votre première entrée');
  String get saved => _p('تم الحفظ', 'Saved', 'Enregistré');
  String get deleteConfirm => _p(
      'هل تريد حذف هذه التدوينة؟',
      'Delete this entry?',
      'Supprimer cette entrée ?');

  // Lock
  String get lockTitle => _p('قفل مذكرتي', 'Lock my journal', 'Verrouiller');
  String get enterPin =>
      _p('أدخل رمزك السري', 'Enter your PIN', 'Entrez votre code');
  String get setPin => _p('أنشئ رمزاً سرياً', 'Set a PIN', 'Créer un code');
  String get confirmPin =>
      _p('أعد إدخال الرمز', 'Re-enter your PIN', 'Confirmez le code');
  String get wrongPin =>
      _p('الرمز غير صحيح', 'Wrong PIN', 'Code incorrect');
  String get pinMismatch =>
      _p('الرمز غير متطابق', 'PINs do not match', 'Les codes ne correspondent pas');
  String get useBiometric =>
      _p('استخدم البصمة', 'Use biometrics', "Utiliser la biométrie");
  String get enableLock =>
      _p('تفعيل قفل المذكرة', 'Enable journal lock', 'Activer le verrou');
  String get disableLock =>
      _p('إلغاء القفل', 'Disable lock', 'Désactiver le verrou');

  // Time capsule
  String get timeCapsule =>
      _p('كبسولة الزمن', 'Time capsule', 'Capsule temporelle');
  String get timeCapsuleSubtitle => _p(
      'استرجع ما كتبته في مثل هذا اليوم',
      'Revisit what you wrote on this day',
      'Revivez ce que vous avez écrit ce jour-là');
  String get noCapsule => _p(
      'لا شيء من الماضي في مثل هذا اليوم بعد',
      'Nothing from past years on this day yet',
      "Rien des années passées pour aujourd'hui");
  String get yearAgo => _p('منذ سنة', 'A year ago', 'Il y a un an');
  String monthsAgo(int m) => _p('منذ $m أشهر', '$m months ago', 'Il y a $m mois');
  String yearsAgo(int y) => _p('منذ $y سنوات', '$y years ago', 'Il y a $y ans');

  // Insights
  String get insights =>
      _p('تحليلات المشاعر', 'Mood insights', 'Analyse des émotions');
  String get monthSummary => _p('ملخص الشهر', 'Monthly summary', 'Résumé du mois');
  String get smartNotes => _p('ملاحظات ذكية', 'Smart notes', 'Notes intelligentes');
  String get topWords =>
      _p('الكلمات الأكثر تكراراً', 'Most frequent words', 'Mots fréquents');
  String get entriesCount => _p('تدوينة', 'entries', 'entrées');
  String get noData => _p(
      'اكتب بعض التدوينات لرؤية تحليلاتك',
      'Write a few entries to see your insights',
      'Écrivez quelques entrées pour voir vos analyses');
  String get tryExercise =>
      _p('جرّب تمرين تنفّس', 'Try a breathing exercise', 'Essayez un exercice');
  String get aGentleReminder =>
      _p('تذكير لطيف', 'A gentle reminder', 'Un petit rappel');

  String get privateNote => _p(
      'كل التحليلات تتم على جهازك — لا يصل إليها أحد.',
      'All analysis runs on your device — no one else can see it.',
      'Toute analyse se fait sur votre appareil — personne d’autre n’y accède.');
}
