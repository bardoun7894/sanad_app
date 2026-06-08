import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';
import 'app_strings_en.dart';
import 'app_strings_fr.dart';
import 'language_preference_service.dart';

enum AppLanguage { arabic, english, french }

extension AppLanguageCode on AppLanguage {
  /// Returns the ISO 639-1 code for this language ('ar', 'en', 'fr').
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.french:
        return 'fr';
      case AppLanguage.arabic:
        return 'ar';
    }
  }
}

class LanguageState {
  final AppLanguage language;
  final Locale locale;
  final bool isRtl;

  const LanguageState({
    required this.language,
    required this.locale,
    required this.isRtl,
  });

  factory LanguageState.arabic() => const LanguageState(
    language: AppLanguage.arabic,
    locale: Locale('ar', 'SA'),
    isRtl: true,
  );

  factory LanguageState.english() => const LanguageState(
    language: AppLanguage.english,
    locale: Locale('en', 'US'),
    isRtl: false,
  );

  factory LanguageState.french() => const LanguageState(
    language: AppLanguage.french,
    locale: Locale('fr', 'FR'),
    isRtl: false,
  );

  String get displayName {
    switch (language) {
      case AppLanguage.arabic:
        return 'العربية';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.french:
        return 'Français';
    }
  }

  LanguageState copyWith({AppLanguage? language, Locale? locale, bool? isRtl}) {
    return LanguageState(
      language: language ?? this.language,
      locale: locale ?? this.locale,
      isRtl: isRtl ?? this.isRtl,
    );
  }
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  final LanguagePreferenceService? _prefs;

  LanguageNotifier({LanguagePreferenceService? prefs, AppLanguage? initial})
      : _prefs = prefs,
        super(_stateFor(initial ?? AppLanguage.arabic));

  static LanguageState _stateFor(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.arabic:
        return LanguageState.arabic();
      case AppLanguage.english:
        return LanguageState.english();
      case AppLanguage.french:
        return LanguageState.french();
    }
  }

  void setLanguage(AppLanguage language) {
    state = _stateFor(language);
    // Persist so the choice survives app restart.
    _prefs?.saveLanguage(language);
  }

  void toggleLanguage() {
    final next = state.language == AppLanguage.arabic
        ? AppLanguage.english
        : AppLanguage.arabic;
    setLanguage(next);
  }
}

/// Default provider — used until main.dart overrides it with a notifier
/// wired to the persisted preference. The override is what makes the user's
/// chosen language survive cold start.
final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>(
  (ref) => LanguageNotifier(),
);

/// Riverpod provider for the preference service. Bound by main.dart at
/// startup via overrideWithValue.
final languagePreferenceServiceProvider =
    Provider<LanguagePreferenceService?>((ref) => null);

/// Localized strings accessor - returns strings based on current language
class S {
  final AppLanguage language;

  S(this.language);

  String _getString(String arabic, String english, String french) {
    switch (language) {
      case AppLanguage.arabic:
        return arabic;
      case AppLanguage.english:
        return english;
      case AppLanguage.french:
        return french;
    }
  }

  // App name
  String get appName => _getString(
    AppStrings.appName,
    AppStringsEn.appName,
    AppStringsFr.appName,
  );

  String get appSlogan => _getString(
    AppStrings.appSlogan,
    AppStringsEn.appSlogan,
    AppStringsFr.appSlogan,
  );

  String get dualName => _getString(
    AppStrings.dualName,
    AppStringsEn.dualName,
    AppStringsFr.dualName,
  );

  String get enterDualName => _getString(
    AppStrings.enterDualName,
    AppStringsEn.enterDualName,
    AppStringsFr.enterDualName,
  );

  String get phoneNumberMandatory => _getString(
    AppStrings.phoneNumberMandatory,
    AppStringsEn.phoneNumberMandatory,
    AppStringsFr.phoneNumberMandatory,
  );

  String get agreeToWhatsApp => _getString(
    AppStrings.agreeToWhatsApp,
    AppStringsEn.agreeToWhatsApp,
    AppStrings.agreeToWhatsApp, // Fallback for French
  );

  String get hasWhatsAppOnSameNumber => _getString(
    AppStrings.hasWhatsAppOnSameNumber,
    AppStringsEn.hasWhatsAppOnSameNumber,
    AppStrings.hasWhatsAppOnSameNumber,
  );

  String get noWhatsAppOnSameNumber => _getString(
    AppStrings.noWhatsAppOnSameNumber,
    AppStringsEn.noWhatsAppOnSameNumber,
    AppStrings.noWhatsAppOnSameNumber,
  );

  String get enterWhatsAppNumber => _getString(
    AppStrings.enterWhatsAppNumber,
    AppStringsEn.enterWhatsAppNumber,
    AppStrings.enterWhatsAppNumber,
  );

  String get sameNumber => _getString(
    AppStrings.sameNumber,
    AppStringsEn.sameNumber,
    AppStrings.sameNumber,
  );

  String get joinSession => _getString(
    AppStrings.joinSession,
    AppStringsEn.joinSession,
    AppStringsFr.joinSession,
  );

  String get therapistWillCallYou => _getString(
    AppStrings.therapistWillCallYou,
    AppStringsEn.therapistWillCallYou,
    AppStringsFr.therapistWillCallYou,
  );

  String get callAvailableInMin => _getString(
    AppStrings.callAvailableInMin,
    AppStringsEn.callAvailableInMin,
    AppStringsFr.callAvailableInMin,
  );

  String get sessionWindowEnded => _getString(
    AppStrings.sessionWindowEnded,
    AppStringsEn.sessionWindowEnded,
    AppStringsFr.sessionWindowEnded,
  );

  String get callClient => _getString(
    AppStrings.callClient,
    AppStringsEn.callClient,
    AppStringsFr.callClient,
  );

  String get chatLockedUntilAccept => _getString(
    AppStrings.chatLockedUntilAccept,
    AppStringsEn.chatLockedUntilAccept,
    AppStringsFr.chatLockedUntilAccept,
  );

  String get chatLockedPayPrompt => _getString(
    AppStrings.chatLockedPayPrompt,
    AppStringsEn.chatLockedPayPrompt,
    AppStringsFr.chatLockedPayPrompt,
  );

  String get chatReadOnlyBanner => _getString(
    AppStrings.chatReadOnlyBanner,
    AppStringsEn.chatReadOnlyBanner,
    AppStringsFr.chatReadOnlyBanner,
  );

  String get differentNumber => _getString(
    AppStrings.differentNumber,
    AppStringsEn.differentNumber,
    AppStrings.differentNumber,
  );

  String get rememberMe => _getString(
    AppStrings.rememberMe,
    AppStringsEn.rememberMe,
    AppStrings.rememberMe,
  );

  // Common
  String get loading => _getString(
    AppStrings.loading,
    AppStringsEn.loading,
    AppStringsFr.loading,
  );
  String get error =>
      _getString(AppStrings.error, AppStringsEn.error, AppStringsFr.error);
  String get retry =>
      _getString(AppStrings.retry, AppStringsEn.retry, AppStringsFr.retry);
  String get cancel =>
      _getString(AppStrings.cancel, AppStringsEn.cancel, AppStringsFr.cancel);
  String get save =>
      _getString(AppStrings.save, AppStringsEn.save, AppStringsFr.save);
  String get done =>
      _getString(AppStrings.done, AppStringsEn.done, AppStringsFr.done);
  String get bankTransferRequestSentTitle => _getString(
        AppStrings.bankTransferRequestSentTitle,
        AppStringsEn.bankTransferRequestSentTitle,
        AppStringsFr.bankTransferRequestSentTitle,
      );
  String get bankTransferRequestSentBody => _getString(
        AppStrings.bankTransferRequestSentBody,
        AppStringsEn.bankTransferRequestSentBody,
        AppStringsFr.bankTransferRequestSentBody,
      );
  String get awaitingPaymentConfirmation => _getString(
        AppStrings.awaitingPaymentConfirmation,
        AppStringsEn.awaitingPaymentConfirmation,
        AppStringsFr.awaitingPaymentConfirmation,
      );
  String get next =>
      _getString(AppStrings.next, AppStringsEn.next, AppStringsFr.next);
  String get back =>
      _getString(AppStrings.back, AppStringsEn.back, AppStringsFr.back);
  String get close =>
      _getString(AppStrings.close, AppStringsEn.close, AppStringsFr.close);
  String get search =>
      _getString(AppStrings.search, AppStringsEn.search, AppStringsFr.search);
  String get seeAll =>
      _getString(AppStrings.seeAll, AppStringsEn.seeAll, AppStringsFr.seeAll);
  String get comingSoon => _getString(
    AppStrings.comingSoon,
    AppStringsEn.comingSoon,
    AppStringsFr.comingSoon,
  );

  // Bottom Navigation
  String get navHome => _getString(
    AppStrings.navHome,
    AppStringsEn.navHome,
    AppStringsFr.navHome,
  );
  String get navTherapists => _getString(
    AppStrings.navTherapists,
    AppStringsEn.navTherapists,
    AppStringsFr.navTherapists,
  );
  String get navCommunity => _getString(
    AppStrings.navCommunity,
    AppStringsEn.navCommunity,
    AppStringsFr.navCommunity,
  );
  String get navProfile => _getString(
    AppStrings.navProfile,
    AppStringsEn.navProfile,
    AppStringsFr.navProfile,
  );

  String get navMore => _getString(
    AppStrings.navMore,
    AppStringsEn.navMore,
    AppStringsFr.navMore,
  );

  // Home Screen
  String get greeting => _getString(
    AppStrings.greeting,
    AppStringsEn.greeting,
    AppStringsFr.greeting,
  );
  String get howAreYouFeeling => _getString(
    AppStrings.howAreYouFeeling,
    AppStringsEn.howAreYouFeeling,
    AppStringsFr.howAreYouFeeling,
  );
  String get viewMoodHistory => _getString(
    AppStrings.viewMoodHistory,
    AppStringsEn.viewMoodHistory,
    AppStringsFr.viewMoodHistory,
  );
  String get recommendedForYou => _getString(
    AppStrings.recommendedForYou,
    AppStringsEn.recommendedForYou,
    AppStringsFr.recommendedForYou,
  );
  String get upcomingSession => _getString(
    AppStrings.upcomingSession,
    AppStringsEn.upcomingSession,
    AppStringsFr.upcomingSession,
  );
  String get noUpcomingSessions => _getString(
    AppStrings.noUpcomingSessions,
    AppStringsEn.noUpcomingSessions,
    AppStringsFr.noUpcomingSessions,
  );
  String get needToTalk => _getString(
    AppStrings.needToTalk,
    AppStringsEn.needToTalk,
    AppStringsFr.needToTalk,
  );
  String get specialistsAvailable => _getString(
    AppStrings.specialistsAvailable,
    AppStringsEn.specialistsAvailable,
    AppStringsFr.specialistsAvailable,
  );
  String get chatWithAI => _getString(
    AppStrings.chatWithAI,
    AppStringsEn.chatWithAI,
    AppStringsFr.chatWithAI,
  );
  String get startChat => _getString(
    AppStrings.startChat,
    AppStringsEn.startChat,
    AppStringsFr.startChat,
  );
  String get startInstantChat => _getString(
    AppStrings.startInstantChat,
    AppStringsEn.startInstantChat,
    AppStringsFr.startInstantChat,
  );

  // Moods
  String get moodHappy => _getString(
    AppStrings.moodHappy,
    AppStringsEn.moodHappy,
    AppStringsFr.moodHappy,
  );
  String get moodCalm => _getString(
    AppStrings.moodCalm,
    AppStringsEn.moodCalm,
    AppStringsFr.moodCalm,
  );
  String get moodAnxious => _getString(
    AppStrings.moodAnxious,
    AppStringsEn.moodAnxious,
    AppStringsFr.moodAnxious,
  );
  String get moodSad => _getString(
    AppStrings.moodSad,
    AppStringsEn.moodSad,
    AppStringsFr.moodSad,
  );
  String get moodAngry => _getString(
    AppStrings.moodAngry,
    AppStringsEn.moodAngry,
    AppStringsFr.moodAngry,
  );
  String get moodTired => _getString(
    AppStrings.moodTired,
    AppStringsEn.moodTired,
    AppStringsFr.moodTired,
  );

  // Mood Tracker
  String get moodTracker => _getString(
    AppStrings.moodTracker,
    AppStringsEn.moodTracker,
    AppStringsFr.moodTracker,
  );
  String get todaysMood => _getString(
    AppStrings.todaysMood,
    AppStringsEn.todaysMood,
    AppStringsFr.todaysMood,
  );
  String get logYourMood => _getString(
    AppStrings.logYourMood,
    AppStringsEn.logYourMood,
    AppStringsFr.logYourMood,
  );
  String get logMood => _getString(
    AppStrings.logMood,
    AppStringsEn.logMood,
    AppStringsFr.logMood,
  );
  String get logMyMood => _getString(
    AppStrings.logMyMood,
    AppStringsEn.logMyMood,
    AppStringsFr.logMyMood,
  );
  String get howDoYouFeel => _getString(
    AppStrings.howDoYouFeel,
    AppStringsEn.howDoYouFeel,
    AppStringsFr.howDoYouFeel,
  );
  String get howAreYouFeelingToday => _getString(
    AppStrings.howAreYouFeelingToday,
    AppStringsEn.howAreYouFeelingToday,
    AppStringsFr.howAreYouFeelingToday,
  );
  String get selectMoodAndNote => _getString(
    AppStrings.selectMoodAndNote,
    AppStringsEn.selectMoodAndNote,
    AppStringsFr.selectMoodAndNote,
  );
  String get takeAMoment => _getString(
    AppStrings.takeAMoment,
    AppStringsEn.takeAMoment,
    AppStringsFr.takeAMoment,
  );
  String get addNote => _getString(
    AppStrings.addNote,
    AppStringsEn.addNote,
    AppStringsFr.addNote,
  );
  String get notePlaceholder => _getString(
    AppStrings.notePlaceholder,
    AppStringsEn.notePlaceholder,
    AppStringsFr.notePlaceholder,
  );
  String get moodLogged => _getString(
    AppStrings.moodLogged,
    AppStringsEn.moodLogged,
    AppStringsFr.moodLogged,
  );
  String get keepTracking => _getString(
    AppStrings.keepTracking,
    AppStringsEn.keepTracking,
    AppStringsFr.keepTracking,
  );
  String get weeklyOverview => _getString(
    AppStrings.weeklyOverview,
    AppStringsEn.weeklyOverview,
    AppStringsFr.weeklyOverview,
  );
  String get recentHistory => _getString(
    AppStrings.recentHistory,
    AppStringsEn.recentHistory,
    AppStringsFr.recentHistory,
  );
  String get monthlyReport => _getString(
    AppStrings.monthlyReport,
    AppStringsEn.monthlyReport,
    AppStringsFr.monthlyReport,
  );
  String get viewMonthlyReport => _getString(
    AppStrings.viewMonthlyReport,
    AppStringsEn.viewMonthlyReport,
    AppStringsFr.viewMonthlyReport,
  );
  String get completionRate => _getString(
    AppStrings.completionRate,
    AppStringsEn.completionRate,
    AppStringsFr.completionRate,
  );
  String get daysLogged => _getString(
    AppStrings.daysLogged,
    AppStringsEn.daysLogged,
    AppStringsFr.daysLogged,
  );
  String get moodDistribution => _getString(
    AppStrings.moodDistribution,
    AppStringsEn.moodDistribution,
    AppStringsFr.moodDistribution,
  );
  String get dominantMood => _getString(
    AppStrings.dominantMood,
    AppStringsEn.dominantMood,
    AppStringsFr.dominantMood,
  );
  String get moodCalendar => _getString(
    AppStrings.moodCalendar,
    AppStringsEn.moodCalendar,
    AppStringsFr.moodCalendar,
  );
  String get youLoggedMood => _getString(
    AppStrings.youLoggedMood,
    AppStringsEn.youLoggedMood,
    AppStringsFr.youLoggedMood,
  );
  String get outOf =>
      _getString(AppStrings.outOf, AppStringsEn.outOf, AppStringsFr.outOf);
  String get noMoodToday => _getString(
    AppStrings.noMoodToday,
    AppStringsEn.noMoodToday,
    AppStringsFr.noMoodToday,
  );
  String get noMoodEntries => _getString(
    AppStrings.noMoodEntries,
    AppStringsEn.noMoodEntries,
    AppStringsFr.noMoodEntries,
  );
  String get startTracking => _getString(
    AppStrings.startTracking,
    AppStringsEn.startTracking,
    AppStringsFr.startTracking,
  );
  String get tapToLog => _getString(
    AppStrings.tapToLog,
    AppStringsEn.tapToLog,
    AppStringsFr.tapToLog,
  );
  String get thisWeek => _getString(
    AppStrings.thisWeek,
    AppStringsEn.thisWeek,
    AppStringsFr.thisWeek,
  );

  String get thisMonth => _getString(
    AppStrings.thisMonth,
    AppStringsEn.thisMonth,
    AppStringsFr.thisMonth,
  );

  String get week =>
      _getString(AppStrings.week, AppStringsEn.week, AppStringsFr.week);

  String get history => _getString(
    AppStrings.history,
    AppStringsEn.history,
    AppStringsFr.history,
  );

  String get journalEntry => _getString(
    AppStrings.journalEntry,
    AppStringsEn.journalEntry,
    AppStringsFr.journalEntry,
  );
  String get howWasYourDay => _getString(
    AppStrings.howWasYourDay,
    AppStringsEn.howWasYourDay,
    AppStringsFr.howWasYourDay,
  );
  String get journalPrompt => _getString(
    AppStrings.journalPrompt,
    AppStringsEn.journalPrompt,
    AppStringsFr.journalPrompt,
  );
  String get selectPrompt => _getString(
    AppStrings.selectPrompt,
    AppStringsEn.selectPrompt,
    AppStringsFr.selectPrompt,
  );
  String get promptGratitude => _getString(
    AppStrings.promptGratitude,
    AppStringsEn.promptGratitude,
    AppStringsFr.promptGratitude,
  );
  String get promptChallenge => _getString(
    AppStrings.promptChallenge,
    AppStringsEn.promptChallenge,
    AppStringsFr.promptChallenge,
  );
  String get promptAnxiety => _getString(
    AppStrings.promptAnxiety,
    AppStringsEn.promptAnxiety,
    AppStringsFr.promptAnxiety,
  );
  String get promptWin => _getString(
    AppStrings.promptWin,
    AppStringsEn.promptWin,
    AppStringsFr.promptWin,
  );
  String get saveJournal => _getString(
    AppStrings.saveJournal,
    AppStringsEn.saveJournal,
    AppStringsFr.saveJournal,
  );
  String get journalSaved => _getString(
    AppStrings.journalSaved,
    AppStringsEn.journalSaved,
    AppStringsFr.journalSaved,
  );
  String get writeMore => _getString(
    AppStrings.writeMore,
    AppStringsEn.writeMore,
    AppStringsFr.writeMore,
  );

  // Switch Therapist
  String get switchTherapist => _getString(
    AppStrings.switchTherapist,
    AppStringsEn.switchTherapist,
    AppStringsFr.switchTherapist,
  );
  String get whySwitch => _getString(
    AppStrings.whySwitch,
    AppStringsEn.whySwitch,
    AppStringsFr.whySwitch,
  );
  String get reasonNotHappy => _getString(
    AppStrings.reasonNotHappy,
    AppStringsEn.reasonNotHappy,
    AppStringsFr.reasonNotHappy,
  );
  String get reasonPrice => _getString(
    AppStrings.reasonPrice,
    AppStringsEn.reasonPrice,
    AppStringsFr.reasonPrice,
  );
  String get reasonAvailability => _getString(
    AppStrings.reasonAvailability,
    AppStringsEn.reasonAvailability,
    AppStringsFr.reasonAvailability,
  );
  String get reasonOther => _getString(
    AppStrings.reasonOther,
    AppStringsEn.reasonOther,
    AppStringsFr.reasonOther,
  );
  String get rematchMe => _getString(
    AppStrings.rematchMe,
    AppStringsEn.rematchMe,
    AppStringsFr.rematchMe,
  );
  String get browseTherapists => _getString(
    AppStrings.browseTherapists,
    AppStringsEn.browseTherapists,
    AppStringsFr.browseTherapists,
  );
  String get switchConfirm => _getString(
    AppStrings.switchConfirm,
    AppStringsEn.switchConfirm,
    AppStringsFr.switchConfirm,
  );
  String get switchSuccess => _getString(
    AppStrings.switchSuccess,
    AppStringsEn.switchSuccess,
    AppStringsFr.switchSuccess,
  );

  // Enhanced Onboarding
  String get matchingQuestionnaire => _getString(
    AppStrings.matchingQuestionnaire,
    AppStringsEn.matchingQuestionnaire,
    AppStringsFr.matchingQuestionnaire,
  );
  String get culturalBackground => _getString(
    AppStrings.culturalBackground,
    AppStringsEn.culturalBackground,
    AppStringsFr.culturalBackground,
  );
  String get primaryGoals => _getString(
    AppStrings.primaryGoals,
    AppStringsEn.primaryGoals,
    AppStringsFr.primaryGoals,
  );
  String get relationshipStatus => _getString(
    AppStrings.relationshipStatus,
    AppStringsEn.relationshipStatus,
    AppStringsFr.relationshipStatus,
  );
  String get medicalHistory => _getString(
    AppStrings.medicalHistory,
    AppStringsEn.medicalHistory,
    AppStringsFr.medicalHistory,
  );
  String get preferredGender => _getString(
    AppStrings.preferredGender,
    AppStringsEn.preferredGender,
    AppStringsFr.preferredGender,
  );
  String get religiousPreference => _getString(
    AppStrings.religiousPreference,
    AppStringsEn.religiousPreference,
    AppStringsFr.religiousPreference,
  );

  // Daily Quote
  String get dailyQuote => language == AppLanguage.arabic
      ? AppStrings.dailyQuote
      : (language == AppLanguage.french
            ? AppStringsFr.dailyQuote
            : AppStringsEn.dailyQuote);
  String get dailyTip => language == AppLanguage.arabic
      ? AppStrings.dailyTip
      : (language == AppLanguage.french
            ? AppStringsFr.dailyTip
            : AppStringsEn.dailyTip);
  String get shareQuote => language == AppLanguage.arabic
      ? AppStrings.shareQuote
      : (language == AppLanguage.french
            ? AppStringsFr.shareQuote
            : AppStringsEn.shareQuote);
  String get shareThisQuote => language == AppLanguage.arabic
      ? AppStrings.shareThisQuote
      : (language == AppLanguage.french
            ? AppStringsFr.shareThisQuote
            : AppStringsEn.shareThisQuote);
  String get sharedViaSanad => _getString(
    AppStrings.sharedViaSanad,
    AppStringsEn.sharedViaSanad,
    AppStringsFr.sharedViaSanad,
  );

  // Chat
  String get chatTitle => _getString(
    AppStrings.chatTitle,
    AppStringsEn.chatTitle,
    AppStringsFr.chatTitle,
  );
  String get chatSubtitle => _getString(
    AppStrings.chatSubtitle,
    AppStringsEn.chatSubtitle,
    AppStringsFr.chatSubtitle,
  );
  String get typeMessage => _getString(
    AppStrings.typeMessage,
    AppStringsEn.typeMessage,
    AppStringsFr.typeMessage,
  );
  String get send =>
      _getString(AppStrings.send, AppStringsEn.send, AppStringsFr.send);
  String get talkToTherapist => _getString(
    AppStrings.talkToTherapist,
    AppStringsEn.talkToTherapist,
    AppStringsFr.talkToTherapist,
  );
  String get aiDisclaimer => _getString(
    AppStrings.aiDisclaimer,
    AppStringsEn.aiDisclaimer,
    AppStringsFr.aiDisclaimer,
  );
  String get sanadSupport => _getString(
    AppStrings.sanadSupport,
    AppStringsEn.sanadSupport,
    AppStringsFr.sanadSupport,
  );
  String get online =>
      _getString(AppStrings.online, AppStringsEn.online, AppStringsFr.online);
  String get connectWithProfessional => _getString(
    AppStrings.connectWithProfessional,
    AppStringsEn.connectWithProfessional,
    AppStringsFr.connectWithProfessional,
  );
  String get continueChatting => _getString(
    AppStrings.continueChatting,
    AppStringsEn.continueChatting,
    AppStringsFr.continueChatting,
  );
  String get quickResponses => _getString(
    AppStrings.quickResponses,
    AppStringsEn.quickResponses,
    AppStringsFr.quickResponses,
  );

  // Quick Replies
  String get quickReplyAnxious => _getString(
    AppStrings.quickReplyAnxious,
    AppStringsEn.quickReplyAnxious,
    AppStringsFr.quickReplyAnxious,
  );
  String get quickReplySad => _getString(
    AppStrings.quickReplySad,
    AppStringsEn.quickReplySad,
    AppStringsFr.quickReplySad,
  );
  String get quickReplyStressed => _getString(
    AppStrings.quickReplyStressed,
    AppStringsEn.quickReplyStressed,
    AppStringsFr.quickReplyStressed,
  );
  String get quickReplyTalk => _getString(
    AppStrings.quickReplyTalk,
    AppStringsEn.quickReplyTalk,
    AppStringsFr.quickReplyTalk,
  );
  String get quickReplyHelp => _getString(
    AppStrings.quickReplyHelp,
    AppStringsEn.quickReplyHelp,
    AppStringsFr.quickReplyHelp,
  );

  // Community
  String get community => _getString(
    AppStrings.community,
    AppStringsEn.community,
    AppStringsFr.community,
  );
  String get newPost => _getString(
    AppStrings.newPost,
    AppStringsEn.newPost,
    AppStringsFr.newPost,
  );
  String get shareWithCommunity => _getString(
    AppStrings.shareWithCommunity,
    AppStringsEn.shareWithCommunity,
    AppStringsFr.shareWithCommunity,
  );
  String get yourThoughtsMatter => _getString(
    AppStrings.yourThoughtsMatter,
    AppStringsEn.yourThoughtsMatter,
    AppStringsFr.yourThoughtsMatter,
  );
  String get whatsOnYourMind => _getString(
    AppStrings.whatsOnYourMind,
    AppStringsEn.whatsOnYourMind,
    AppStringsFr.whatsOnYourMind,
  );
  String get sharePlaceholder => _getString(
    AppStrings.sharePlaceholder,
    AppStringsEn.sharePlaceholder,
    AppStringsFr.sharePlaceholder,
  );
  String get postAnonymously => _getString(
    AppStrings.postAnonymously,
    AppStringsEn.postAnonymously,
    AppStringsFr.postAnonymously,
  );
  String get nameHidden => _getString(
    AppStrings.nameHidden,
    AppStringsEn.nameHidden,
    AppStringsFr.nameHidden,
  );
  String get sharePost => _getString(
    AppStrings.sharePost,
    AppStringsEn.sharePost,
    AppStringsFr.sharePost,
  );
  String get postShared => _getString(
    AppStrings.postShared,
    AppStringsEn.postShared,
    AppStringsFr.postShared,
  );
  String get thankYouSharing => _getString(
    AppStrings.thankYouSharing,
    AppStringsEn.thankYouSharing,
    AppStringsFr.thankYouSharing,
  );
  String get react =>
      _getString(AppStrings.react, AppStringsEn.react, AppStringsFr.react);
  String get comment => _getString(
    AppStrings.comment,
    AppStringsEn.comment,
    AppStringsFr.comment,
  );
  String get comments => _getString(
    AppStrings.comments,
    AppStringsEn.comments,
    AppStringsFr.comments,
  );
  String get commenting => _getString(
    AppStrings.commenting,
    AppStringsEn.commenting,
    AppStringsFr.commenting,
  );
  String get loginToComment => _getString(
    AppStrings.loginToComment,
    AppStringsEn.loginToComment,
    AppStringsFr.loginToComment,
  );
  String get noComments => _getString(
    AppStrings.noComments,
    AppStringsEn.noComments,
    AppStringsFr.noComments,
  );
  String get beFirstSupport => _getString(
    AppStrings.beFirstSupport,
    AppStringsEn.beFirstSupport,
    AppStringsFr.beFirstSupport,
  );
  String get addComment => _getString(
    AppStrings.addComment,
    AppStringsEn.addComment,
    AppStringsFr.addComment,
  );
  String get postsFound => _getString(
    AppStrings.postsFound,
    AppStringsEn.postsFound,
    AppStringsFr.postsFound,
  );
  String get noPosts => _getString(
    AppStrings.noPosts,
    AppStringsEn.noPosts,
    AppStringsFr.noPosts,
  );
  String get beFirstShare => _getString(
    AppStrings.beFirstShare,
    AppStringsEn.beFirstShare,
    AppStringsFr.beFirstShare,
  );
  String get category => _getString(
    AppStrings.category,
    AppStringsEn.category,
    AppStringsFr.category,
  );

  // Community Categories
  String get categoryAll => _getString(
    AppStrings.categoryAll,
    AppStringsEn.categoryAll,
    AppStringsFr.categoryAll,
  );
  String get categoryGeneral => _getString(
    AppStrings.categoryGeneral,
    AppStringsEn.categoryGeneral,
    AppStringsFr.categoryGeneral,
  );
  String get categoryAnxiety => _getString(
    AppStrings.categoryAnxiety,
    AppStringsEn.categoryAnxiety,
    AppStringsFr.categoryAnxiety,
  );
  String get categoryDepression => _getString(
    AppStrings.categoryDepression,
    AppStringsEn.categoryDepression,
    AppStringsFr.categoryDepression,
  );
  String get categoryRelationships => _getString(
    AppStrings.categoryRelationships,
    AppStringsEn.categoryRelationships,
    AppStringsFr.categoryRelationships,
  );
  String get categorySelfCare => _getString(
    AppStrings.categorySelfCare,
    AppStringsEn.categorySelfCare,
    AppStringsFr.categorySelfCare,
  );
  String get categoryMotivation => _getString(
    AppStrings.categoryMotivation,
    AppStringsEn.categoryMotivation,
    AppStringsFr.categoryMotivation,
  );

  // Reactions
  String get reactionLove => _getString(
    AppStrings.reactionLove,
    AppStringsEn.reactionLove,
    AppStringsFr.reactionLove,
  );
  String get reactionSupport => _getString(
    AppStrings.reactionSupport,
    AppStringsEn.reactionSupport,
    AppStringsFr.reactionSupport,
  );
  String get reactionHug => _getString(
    AppStrings.reactionHug,
    AppStringsEn.reactionHug,
    AppStringsFr.reactionHug,
  );
  String get reactionStrength => _getString(
    AppStrings.reactionStrength,
    AppStringsEn.reactionStrength,
    AppStringsFr.reactionStrength,
  );
  String get reactionRelate => _getString(
    AppStrings.reactionRelate,
    AppStringsEn.reactionRelate,
    AppStringsFr.reactionRelate,
  );

  // Therapists
  String get findTherapist => _getString(
    AppStrings.findTherapist,
    AppStringsEn.findTherapist,
    AppStringsFr.findTherapist,
  );

  String get myBookings => _getString(
    AppStrings.myBookings,
    AppStringsEn.myBookings,
    'Mes rendez-vous',
  );
  String get searchTherapist => _getString(
    AppStrings.searchTherapist,
    AppStringsEn.searchTherapist,
    AppStringsFr.searchTherapist,
  );
  String get therapistsFound => _getString(
    AppStrings.therapistsFound,
    AppStringsEn.therapistsFound,
    AppStringsFr.therapistsFound,
  );
  String get noTherapistsFound => _getString(
    AppStrings.noTherapistsFound,
    AppStringsEn.noTherapistsFound,
    AppStringsFr.noTherapistsFound,
  );
  String get adjustFilters => _getString(
    AppStrings.adjustFilters,
    AppStringsEn.adjustFilters,
    AppStringsFr.adjustFilters,
  );
  String get availableToday => _getString(
    AppStrings.availableToday,
    AppStringsEn.availableToday,
    AppStringsFr.availableToday,
  );
  String get bookNow => _getString(
    AppStrings.bookNow,
    AppStringsEn.bookNow,
    AppStringsFr.bookNow,
  );
  String get perSession => _getString(
    AppStrings.perSession,
    AppStringsEn.perSession,
    AppStringsFr.perSession,
  );
  String get yearsExp => _getString(
    AppStrings.yearsExp,
    AppStringsEn.yearsExp,
    AppStringsFr.yearsExp,
  );
  String get reviews => _getString(
    AppStrings.reviews,
    AppStringsEn.reviews,
    AppStringsFr.reviews,
  );
  String get patients => _getString(
    AppStrings.patients,
    AppStringsEn.patients,
    AppStringsFr.patients,
  );

  // Therapist Specialties
  String get specialtyAnxiety => _getString(
    AppStrings.specialtyAnxiety,
    AppStringsEn.specialtyAnxiety,
    AppStringsFr.specialtyAnxiety,
  );
  String get specialtyDepression => _getString(
    AppStrings.specialtyDepression,
    AppStringsEn.specialtyDepression,
    AppStringsFr.specialtyDepression,
  );
  String get specialtyTrauma => _getString(
    AppStrings.specialtyTrauma,
    AppStringsEn.specialtyTrauma,
    AppStringsFr.specialtyTrauma,
  );
  String get specialtyRelationships => _getString(
    AppStrings.specialtyRelationships,
    AppStringsEn.specialtyRelationships,
    AppStringsFr.specialtyRelationships,
  );
  String get specialtyStress => _getString(
    AppStrings.specialtyStress,
    AppStringsEn.specialtyStress,
    AppStringsFr.specialtyStress,
  );
  String get specialtySelfEsteem => _getString(
    AppStrings.specialtySelfEsteem,
    AppStringsEn.specialtySelfEsteem,
    AppStringsFr.specialtySelfEsteem,
  );
  String get specialtyGrief => _getString(
    AppStrings.specialtyGrief,
    AppStringsEn.specialtyGrief,
    AppStringsFr.specialtyGrief,
  );
  String get specialtyAddiction => _getString(
    AppStrings.specialtyAddiction,
    AppStringsEn.specialtyAddiction,
    AppStringsFr.specialtyAddiction,
  );

  // Session Types
  String get sessionVideo => _getString(
    AppStrings.sessionVideo,
    AppStringsEn.sessionVideo,
    AppStringsFr.sessionVideo,
  );
  String get sessionAudio => _getString(
    AppStrings.sessionAudio,
    AppStringsEn.sessionAudio,
    AppStringsFr.sessionAudio,
  );
  String get sessionChat => _getString(
    AppStrings.sessionChat,
    AppStringsEn.sessionChat,
    AppStringsFr.sessionChat,
  );

  // Therapist Profile
  String get about =>
      _getString(AppStrings.about, AppStringsEn.about, AppStringsFr.about);
  String get specialties => _getString(
    AppStrings.specialties,
    AppStringsEn.specialties,
    AppStringsFr.specialties,
  );
  String get sessionTypes => _getString(
    AppStrings.sessionTypes,
    AppStringsEn.sessionTypes,
    AppStringsFr.sessionTypes,
  );
  String get languages => _getString(
    AppStrings.languages,
    AppStringsEn.languages,
    AppStringsFr.languages,
  );
  String get qualifications => _getString(
    AppStrings.qualifications,
    AppStringsEn.qualifications,
    AppStringsFr.qualifications,
  );
  String get bookSession => _getString(
    AppStrings.bookSession,
    AppStringsEn.bookSession,
    AppStringsFr.bookSession,
  );
  String get therapistNotFound => _getString(
    AppStrings.therapistNotFound,
    AppStringsEn.therapistNotFound,
    AppStringsFr.therapistNotFound,
  );
  String get seeAllReviews => _getString(
    AppStrings.seeAllReviews,
    AppStringsEn.seeAllReviews,
    AppStringsFr.seeAllReviews,
  );
  String get years =>
      _getString(AppStrings.years, AppStringsEn.years, AppStringsFr.years);

  // Booking
  String get bookASession => _getString(
    AppStrings.bookASession,
    AppStringsEn.bookASession,
    AppStringsFr.bookASession,
  );
  String get withTherapist => _getString(
    AppStrings.withTherapist,
    AppStringsEn.withTherapist,
    AppStringsFr.withTherapist,
  );
  String get selectDate => _getString(
    AppStrings.selectDate,
    AppStringsEn.selectDate,
    AppStringsFr.selectDate,
  );
  String get selectTime => _getString(
    AppStrings.selectTime,
    AppStringsEn.selectTime,
    AppStringsFr.selectTime,
  );
  String get selectSessionType => _getString(
    AppStrings.selectSessionType,
    AppStringsEn.selectSessionType,
    AppStringsFr.selectSessionType,
  );
  String get howToConnect => _getString(
    AppStrings.howToConnect,
    AppStringsEn.howToConnect,
    AppStringsFr.howToConnect,
  );
  String get confirmBooking => _getString(
    AppStrings.confirmBooking,
    AppStringsEn.confirmBooking,
    AppStringsFr.confirmBooking,
  );
  String get reviewBooking => _getString(
    AppStrings.reviewBooking,
    AppStringsEn.reviewBooking,
    AppStringsFr.reviewBooking,
  );
  String get bookingSummary => _getString(
    AppStrings.bookingSummary,
    AppStringsEn.bookingSummary,
    AppStringsFr.bookingSummary,
  );
  String get therapist => _getString(
    AppStrings.therapist,
    AppStringsEn.therapist,
    AppStringsFr.therapist,
  );
  String get date =>
      _getString(AppStrings.date, AppStringsEn.date, AppStringsFr.date);
  String get time =>
      _getString(AppStrings.time, AppStringsEn.time, AppStringsFr.time);
  String get type =>
      _getString(AppStrings.type, AppStringsEn.type, AppStringsFr.type);
  String get total =>
      _getString(AppStrings.total, AppStringsEn.total, AppStringsFr.total);
  String get price =>
      _getString(AppStrings.price, AppStringsEn.price, AppStringsFr.price);
  String get paymentNote => _getString(
    AppStrings.paymentNote,
    AppStringsEn.paymentNote,
    AppStringsFr.paymentNote,
  );
  String get confirmAndPay => _getString(
    AppStrings.confirmAndPay,
    AppStringsEn.confirmAndPay,
    AppStringsFr.confirmAndPay,
  );
  String get bookingConfirmed => _getString(
    AppStrings.bookingConfirmed,
    AppStringsEn.bookingConfirmed,
    AppStringsFr.bookingConfirmed,
  );
  String get sessionBooked => _getString(
    AppStrings.sessionBooked,
    AppStringsEn.sessionBooked,
    AppStringsFr.sessionBooked,
  );
  String get sessionScheduled => _getString(
    AppStrings.sessionScheduled,
    AppStringsEn.sessionScheduled,
    AppStringsFr.sessionScheduled,
  );
  String get confirmationEmail => _getString(
    AppStrings.confirmationEmail,
    AppStringsEn.confirmationEmail,
    AppStringsFr.confirmationEmail,
  );
  String get selected => _getString(
    AppStrings.selected,
    AppStringsEn.selected,
    AppStringsFr.selected,
  );
  String get unavailable => _getString(
    AppStrings.unavailable,
    AppStringsEn.unavailable,
    AppStringsFr.unavailable,
  );

  // Profile
  String get profile => _getString(
    AppStrings.profile,
    AppStringsEn.profile,
    AppStringsFr.profile,
  );
  String get editProfile => _getString(
    AppStrings.editProfile,
    AppStringsEn.editProfile,
    AppStringsFr.editProfile,
  );
  String get fullName => _getString(
    AppStrings.fullName,
    AppStringsEn.fullName,
    AppStringsFr.fullName,
  );
  String get email =>
      _getString(AppStrings.email, AppStringsEn.email, AppStringsFr.email);
  String get phoneNumber => _getString(
    AppStrings.phoneNumber,
    AppStringsEn.phoneNumber,
    AppStringsFr.phoneNumber,
  );
  String get saveChanges => _getString(
    AppStrings.saveChanges,
    AppStringsEn.saveChanges,
    AppStringsFr.saveChanges,
  );
  String get quickActions => _getString(
    AppStrings.quickActions,
    AppStringsEn.quickActions,
    AppStringsFr.quickActions,
  );
  String get customizePlusButton => _getString(
    AppStrings.customizePlusButton,
    AppStringsEn.customizePlusButton,
    AppStringsFr.customizePlusButton,
  );

  // Profile Stats
  String get sessions => _getString(
    AppStrings.sessions,
    AppStringsEn.sessions,
    AppStringsFr.sessions,
  );
  String get moods =>
      _getString(AppStrings.moods, AppStringsEn.moods, AppStringsFr.moods);
  String get dayStreak => _getString(
    AppStrings.dayStreak,
    AppStringsEn.dayStreak,
    AppStringsFr.dayStreak,
  );
  String get posts =>
      _getString(AppStrings.posts, AppStringsEn.posts, AppStringsFr.posts);

  // Settings
  String get markAllAsRead => language == AppLanguage.english
      ? 'Mark all as read'
      : (language == AppLanguage.arabic
            ? 'تحديد الكل كمقروء'
            : 'Tout marquer comme lu');
  String get clearAll => language == AppLanguage.english
      ? 'Clear all'
      : (language == AppLanguage.arabic ? 'مسح الكل' : 'Tout effacer');
  String get notifications => _getString(
    AppStrings.notifications,
    AppStringsEn.notifications,
    AppStringsFr.notifications,
  );
  String get pushNotifications => _getString(
    AppStrings.pushNotifications,
    AppStringsEn.pushNotifications,
    AppStringsFr.pushNotifications,
  );
  String get receiveAlerts => _getString(
    AppStrings.receiveAlerts,
    AppStringsEn.receiveAlerts,
    AppStringsFr.receiveAlerts,
  );
  String get dailyReminders => _getString(
    AppStrings.dailyReminders,
    AppStringsEn.dailyReminders,
    AppStringsFr.dailyReminders,
  );
  String get morningCheckins => _getString(
    AppStrings.morningCheckins,
    AppStringsEn.morningCheckins,
    AppStringsFr.morningCheckins,
  );
  String get moodReminders => _getString(
    AppStrings.moodReminders,
    AppStringsEn.moodReminders,
    AppStringsFr.moodReminders,
  );
  String get dailyMoodPrompts => _getString(
    AppStrings.dailyMoodPrompts,
    AppStringsEn.dailyMoodPrompts,
    AppStringsFr.dailyMoodPrompts,
  );
  String get preferences => _getString(
    AppStrings.preferences,
    AppStringsEn.preferences,
    AppStringsFr.preferences,
  );
  String get darkMode => _getString(
    AppStrings.darkMode,
    AppStringsEn.darkMode,
    AppStringsFr.darkMode,
  );
  String get switchDarkTheme => _getString(
    AppStrings.switchDarkTheme,
    AppStringsEn.switchDarkTheme,
    AppStringsFr.switchDarkTheme,
  );
  String get languageLabel => _getString(
    AppStrings.language,
    AppStringsEn.language,
    AppStringsFr.language,
  );
  String get selectLanguage => _getString(
    AppStrings.selectLanguage,
    AppStringsEn.selectLanguage,
    AppStringsFr.selectLanguage,
  );
  String get anonymousInCommunity => _getString(
    AppStrings.anonymousInCommunity,
    AppStringsEn.anonymousInCommunity,
    AppStringsFr.anonymousInCommunity,
  );
  String get anonymous => _getString(
    AppStrings.anonymous,
    AppStringsEn.anonymous,
    AppStringsFr.anonymous,
  );
  String get hideNameInPosts => _getString(
    AppStrings.hideNameInPosts,
    AppStringsEn.hideNameInPosts,
    AppStringsFr.hideNameInPosts,
  );

  // Languages
  String get english => _getString(
    AppStrings.english,
    AppStringsEn.english,
    AppStringsFr.english,
  );
  String get arabic =>
      _getString(AppStrings.arabic, AppStringsEn.arabic, AppStringsFr.arabic);
  String get french =>
      _getString(AppStrings.french, AppStringsEn.french, AppStringsFr.french);

  // Support
  String get support => _getString(
    AppStrings.support,
    AppStringsEn.support,
    AppStringsFr.support,
  );
  String get helpCenter => _getString(
    AppStrings.helpCenter,
    AppStringsEn.helpCenter,
    AppStringsFr.helpCenter,
  );
  String get faqsAndArticles => _getString(
    AppStrings.faqsAndArticles,
    AppStringsEn.faqsAndArticles,
    AppStringsFr.faqsAndArticles,
  );
  String get faqBookSessionQ => _getString(
    AppStrings.faqBookSessionQ,
    AppStringsEn.faqBookSessionQ,
    AppStringsFr.faqBookSessionQ,
  );
  String get faqBookSessionA => _getString(
    AppStrings.faqBookSessionA,
    AppStringsEn.faqBookSessionA,
    AppStringsFr.faqBookSessionA,
  );
  String get faqPrivacyQ => _getString(
    AppStrings.faqPrivacyQ,
    AppStringsEn.faqPrivacyQ,
    AppStringsFr.faqPrivacyQ,
  );
  String get faqPrivacyA => _getString(
    AppStrings.faqPrivacyA,
    AppStringsEn.faqPrivacyA,
    AppStringsFr.faqPrivacyA,
  );
  String get faqAiChatQ => _getString(
    AppStrings.faqAiChatQ,
    AppStringsEn.faqAiChatQ,
    AppStringsFr.faqAiChatQ,
  );
  String get faqAiChatA => _getString(
    AppStrings.faqAiChatA,
    AppStringsEn.faqAiChatA,
    AppStringsFr.faqAiChatA,
  );
  String get faqSubscriptionPlansQ => _getString(
    AppStrings.faqSubscriptionPlansQ,
    AppStringsEn.faqSubscriptionPlansQ,
    AppStringsFr.faqSubscriptionPlansQ,
  );
  String get faqSubscriptionPlansA => _getString(
    AppStrings.faqSubscriptionPlansA,
    AppStringsEn.faqSubscriptionPlansA,
    AppStringsFr.faqSubscriptionPlansA,
  );
  String get faqCancelSubscriptionQ => _getString(
    AppStrings.faqCancelSubscriptionQ,
    AppStringsEn.faqCancelSubscriptionQ,
    AppStringsFr.faqCancelSubscriptionQ,
  );
  String get faqCancelSubscriptionA => _getString(
    AppStrings.faqCancelSubscriptionA,
    AppStringsEn.faqCancelSubscriptionA,
    AppStringsFr.faqCancelSubscriptionA,
  );
  String get faqBecomeTherapistQ => _getString(
    AppStrings.faqBecomeTherapistQ,
    AppStringsEn.faqBecomeTherapistQ,
    AppStringsFr.faqBecomeTherapistQ,
  );
  String get faqBecomeTherapistA => _getString(
    AppStrings.faqBecomeTherapistA,
    AppStringsEn.faqBecomeTherapistA,
    AppStringsFr.faqBecomeTherapistA,
  );
  String get faqCrisisQ => _getString(
    AppStrings.faqCrisisQ,
    AppStringsEn.faqCrisisQ,
    AppStringsFr.faqCrisisQ,
  );
  String get faqCrisisA => _getString(
    AppStrings.faqCrisisA,
    AppStringsEn.faqCrisisA,
    AppStringsFr.faqCrisisA,
  );
  String get contactSupport => _getString(
    AppStrings.contactSupport,
    AppStringsEn.contactSupport,
    AppStringsFr.contactSupport,
  );
  String get contactSanadTherapySupport => _getString(
    AppStrings.contactSanadTherapySupport,
    AppStringsEn.contactSanadTherapySupport,
    AppStringsFr.contactSanadTherapySupport,
  );
  String get similarArticles => _getString(
    AppStrings.similarArticles,
    AppStringsEn.similarArticles,
    AppStringsFr.similarArticles,
  );
  String get noSimilarArticlesFound => _getString(
    AppStrings.noSimilarArticlesFound,
    AppStringsEn.noSimilarArticlesFound,
    AppStringsFr.noSimilarArticlesFound,
  );
  String get supportCtaHeadline => _getString(
    AppStrings.supportCtaHeadline,
    AppStringsEn.supportCtaHeadline,
    AppStringsFr.supportCtaHeadline,
  );
  String get supportCtaSubtitle => _getString(
    AppStrings.supportCtaSubtitle,
    AppStringsEn.supportCtaSubtitle,
    AppStringsFr.supportCtaSubtitle,
  );
  String get supportCtaButton => _getString(
    AppStrings.supportCtaButton,
    AppStringsEn.supportCtaButton,
    AppStringsFr.supportCtaButton,
  );
  String get supportCtaAvailable247 => _getString(
    AppStrings.supportCtaAvailable247,
    AppStringsEn.supportCtaAvailable247,
    AppStringsFr.supportCtaAvailable247,
  );
  String get supportCtaConfidential => _getString(
    AppStrings.supportCtaConfidential,
    AppStringsEn.supportCtaConfidential,
    AppStringsFr.supportCtaConfidential,
  );
  String get supportCtaTrustLine => _getString(
    AppStrings.supportCtaTrustLine,
    AppStringsEn.supportCtaTrustLine,
    AppStringsFr.supportCtaTrustLine,
  );
  String get supportCallFailed => _getString(
    AppStrings.supportCallFailed,
    AppStringsEn.supportCallFailed,
    AppStringsFr.supportCallFailed,
  );
  String get supportPhoneCopied => _getString(
    AppStrings.supportPhoneCopied,
    AppStringsEn.supportPhoneCopied,
    AppStringsFr.supportPhoneCopied,
  );
  String get supportPhoneCopyAction => _getString(
    AppStrings.supportPhoneCopyAction,
    AppStringsEn.supportPhoneCopyAction,
    AppStringsFr.supportPhoneCopyAction,
  );
  String get getHelpFromTeam => _getString(
    AppStrings.getHelpFromTeam,
    AppStringsEn.getHelpFromTeam,
    AppStringsFr.getHelpFromTeam,
  );
  String get complaintsAndSuggestions => _getString(
    AppStrings.complaintsAndSuggestions,
    AppStringsEn.complaintsAndSuggestions,
    AppStringsFr.complaintsAndSuggestions,
  );
  String get shareYourFeedbackOnWhatsApp => _getString(
    AppStrings.shareYourFeedbackOnWhatsApp,
    AppStringsEn.shareYourFeedbackOnWhatsApp,
    AppStringsFr.shareYourFeedbackOnWhatsApp,
  );
  String get privacyPolicy => _getString(
    AppStrings.privacyPolicy,
    AppStringsEn.privacyPolicy,
    AppStringsFr.privacyPolicy,
  );
  String get termsOfService => _getString(
    AppStrings.termsOfService,
    AppStringsEn.termsOfService,
    AppStringsFr.termsOfService,
  );
  String get knowYourRights => _getString(
    AppStrings.knowYourRights,
    AppStringsEn.knowYourRights,
    AppStringsFr.knowYourRights,
  );
  String get becomeTherapist => _getString(
    AppStrings.becomeTherapist,
    AppStringsEn.becomeTherapist,
    AppStringsFr.becomeTherapist,
  );
  String get becomeTherapistDesc => _getString(
    AppStrings.becomeTherapistDesc,
    AppStringsEn.becomeTherapistDesc,
    AppStringsFr.becomeTherapistDesc,
  );

  // Account
  String get account => _getString(
    AppStrings.account,
    AppStringsEn.account,
    AppStringsFr.account,
  );
  String get logOut =>
      _getString(AppStrings.logOut, AppStringsEn.logOut, AppStringsFr.logOut);
  String get logOutConfirm => _getString(
    AppStrings.logOutConfirm,
    AppStringsEn.logOutConfirm,
    AppStringsFr.logOutConfirm,
  );
  String get loggingOut => _getString(
    AppStrings.loggingOut,
    AppStringsEn.loggingOut,
    AppStringsFr.loggingOut,
  );

  // Time
  String get justNow => _getString(
    AppStrings.justNow,
    AppStringsEn.justNow,
    AppStringsFr.justNow,
  );
  String get minutesAgo => _getString(
    AppStrings.minutesAgo,
    AppStringsEn.minutesAgo,
    AppStringsFr.minutesAgo,
  );
  String get hoursAgo => _getString(
    AppStrings.hoursAgo,
    AppStringsEn.hoursAgo,
    AppStringsFr.hoursAgo,
  );
  String get daysAgo => _getString(
    AppStrings.daysAgo,
    AppStringsEn.daysAgo,
    AppStringsFr.daysAgo,
  );
  String get today =>
      _getString(AppStrings.today, AppStringsEn.today, AppStringsFr.today);
  String get tomorrow => _getString(
    AppStrings.tomorrow,
    AppStringsEn.tomorrow,
    AppStringsFr.tomorrow,
  );
  String get yesterday => _getString(
    AppStrings.yesterday,
    AppStringsEn.yesterday,
    AppStringsFr.yesterday,
  );

  // Days
  String get monday =>
      _getString(AppStrings.monday, AppStringsEn.monday, AppStringsFr.monday);
  String get tuesday => _getString(
    AppStrings.tuesday,
    AppStringsEn.tuesday,
    AppStringsFr.tuesday,
  );
  String get wednesday => _getString(
    AppStrings.wednesday,
    AppStringsEn.wednesday,
    AppStringsFr.wednesday,
  );
  String get thursday => _getString(
    AppStrings.thursday,
    AppStringsEn.thursday,
    AppStringsFr.thursday,
  );
  String get friday =>
      _getString(AppStrings.friday, AppStringsEn.friday, AppStringsFr.friday);
  String get saturday => _getString(
    AppStrings.saturday,
    AppStringsEn.saturday,
    AppStringsFr.saturday,
  );
  String get sunday =>
      _getString(AppStrings.sunday, AppStringsEn.sunday, AppStringsFr.sunday);

  // Short Days
  String get mon =>
      _getString(AppStrings.mon, AppStringsEn.mon, AppStringsFr.mon);
  String get tue =>
      _getString(AppStrings.tue, AppStringsEn.tue, AppStringsFr.tue);
  String get wed =>
      _getString(AppStrings.wed, AppStringsEn.wed, AppStringsFr.wed);
  String get thu =>
      _getString(AppStrings.thu, AppStringsEn.thu, AppStringsFr.thu);
  String get fri =>
      _getString(AppStrings.fri, AppStringsEn.fri, AppStringsFr.fri);
  String get sat =>
      _getString(AppStrings.sat, AppStringsEn.sat, AppStringsFr.sat);
  String get sun =>
      _getString(AppStrings.sun, AppStringsEn.sun, AppStringsFr.sun);

  // Months
  String get january => _getString(
    AppStrings.january,
    AppStringsEn.january,
    AppStringsFr.january,
  );
  String get february => _getString(
    AppStrings.february,
    AppStringsEn.february,
    AppStringsFr.february,
  );
  String get march =>
      _getString(AppStrings.march, AppStringsEn.march, AppStringsFr.march);
  String get april =>
      _getString(AppStrings.april, AppStringsEn.april, AppStringsFr.april);
  String get may =>
      _getString(AppStrings.may, AppStringsEn.may, AppStringsFr.may);
  String get june =>
      _getString(AppStrings.june, AppStringsEn.june, AppStringsFr.june);
  String get july =>
      _getString(AppStrings.july, AppStringsEn.july, AppStringsFr.july);
  String get august =>
      _getString(AppStrings.august, AppStringsEn.august, AppStringsFr.august);
  String get september => _getString(
    AppStrings.september,
    AppStringsEn.september,
    AppStringsFr.september,
  );
  String get october => _getString(
    AppStrings.october,
    AppStringsEn.october,
    AppStringsFr.october,
  );
  String get november => _getString(
    AppStrings.november,
    AppStringsEn.november,
    AppStringsFr.november,
  );
  String get december => _getString(
    AppStrings.december,
    AppStringsEn.december,
    AppStringsFr.december,
  );

  // Meditation
  String get meditation => _getString(
    AppStrings.meditation,
    AppStringsEn.meditation,
    AppStringsFr.meditation,
  );
  String get breatheDeeply => _getString(
    AppStrings.breatheDeeply,
    AppStringsEn.breatheDeeply,
    AppStringsFr.breatheDeeply,
  );
  String get shortSession => _getString(
    AppStrings.shortSession,
    AppStringsEn.shortSession,
    AppStringsFr.shortSession,
  );

  // Psychological Tests
  String get psychologicalTests => _getString(
    AppStrings.psychologicalTests,
    AppStringsEn.psychologicalTests,
    AppStringsFr.psychologicalTests,
  );
  String get depressionTest => _getString(
    AppStrings.depressionTest,
    AppStringsEn.depressionTest,
    AppStringsFr.depressionTest,
  );
  String get depressionTestDesc => _getString(
    AppStrings.depressionTestDesc,
    AppStringsEn.depressionTestDesc,
    AppStringsFr.depressionTestDesc,
  );
  String get anxietyTest => _getString(
    AppStrings.anxietyTest,
    AppStringsEn.anxietyTest,
    AppStringsFr.anxietyTest,
  );
  String get anxietyTestDesc => _getString(
    AppStrings.anxietyTestDesc,
    AppStringsEn.anxietyTestDesc,
    AppStringsFr.anxietyTestDesc,
  );
  String get stressTest => _getString(
    AppStrings.stressTest,
    AppStringsEn.stressTest,
    AppStringsFr.stressTest,
  );
  String get stressTestDesc => _getString(
    AppStrings.stressTestDesc,
    AppStringsEn.stressTestDesc,
    AppStringsFr.stressTestDesc,
  );
  String get minutes5 => _getString(
    AppStrings.minutes5,
    AppStringsEn.minutes5,
    AppStringsFr.minutes5,
  );
  String get minutes3 => _getString(
    AppStrings.minutes3,
    AppStringsEn.minutes3,
    AppStringsFr.minutes3,
  );
  String get questions9 => _getString(
    AppStrings.questions9,
    AppStringsEn.questions9,
    AppStringsFr.questions9,
  );
  String get questions7 => _getString(
    AppStrings.questions7,
    AppStringsEn.questions7,
    AppStringsFr.questions7,
  );
  String get questions10 => _getString(
    AppStrings.questions10,
    AppStringsEn.questions10,
    AppStringsFr.questions10,
  );
  String get startTest => _getString(
    AppStrings.startTest,
    AppStringsEn.startTest,
    AppStringsFr.startTest,
  );

  // Errors
  String get somethingWentWrong => _getString(
    AppStrings.somethingWentWrong,
    AppStringsEn.somethingWentWrong,
    AppStringsFr.somethingWentWrong,
  );
  String get tryAgain => _getString(
    AppStrings.tryAgain,
    AppStringsEn.tryAgain,
    AppStringsFr.tryAgain,
  );
  String get noInternet => _getString(
    AppStrings.noInternet,
    AppStringsEn.noInternet,
    AppStringsFr.noInternet,
  );
  String get sessionExpired => _getString(
    AppStrings.sessionExpired,
    AppStringsEn.sessionExpired,
    AppStringsFr.sessionExpired,
  );
  String get errorOccurred => _getString(
    AppStrings.errorOccurred,
    AppStringsEn.errorOccurred,
    AppStringsFr.errorOccurred,
  );
  String get errorLoadingData => _getString(
    AppStrings.errorLoadingData,
    AppStringsEn.errorLoadingData,
    AppStringsFr.errorLoadingData,
  );

  // Crisis Support
  String get crisisSupport => _getString(
    AppStrings.crisisSupport,
    AppStringsEn.crisisSupport,
    AppStringsFr.crisisSupport,
  );
  String get crisisMessage => _getString(
    AppStrings.crisisMessage,
    AppStringsEn.crisisMessage,
    AppStringsFr.crisisMessage,
  );
  String get talkToSomeone => _getString(
    AppStrings.talkToSomeone,
    AppStringsEn.talkToSomeone,
    AppStringsFr.talkToSomeone,
  );

  // Welcome & Onboarding
  String get welcomeToSanad => _getString(
    AppStrings.welcomeToSanad,
    AppStringsEn.welcomeToSanad,
    AppStringsFr.welcomeToSanad,
  );
  String get welcomeSubtitle => _getString(
    AppStrings.welcomeSubtitle,
    AppStringsEn.welcomeSubtitle,
    AppStringsFr.welcomeSubtitle,
  );
  String get getStarted => _getString(
    AppStrings.getStarted,
    AppStringsEn.getStarted,
    AppStringsFr.getStarted,
  );
  String get continueAsGuest => _getString(
    AppStrings.continueAsGuest,
    AppStringsEn.continueAsGuest,
    AppStringsFr.continueAsGuest,
  );
  String get alreadyHaveAccount => _getString(
    AppStrings.alreadyHaveAccount,
    AppStringsEn.alreadyHaveAccount,
    AppStringsFr.alreadyHaveAccount,
  );
  String get dontHaveAccount => _getString(
    AppStrings.dontHaveAccount,
    AppStringsEn.dontHaveAccount,
    AppStringsFr.dontHaveAccount,
  );
  String get onboardingTitle1 => _getString(
    AppStrings.onboardingTitle1,
    AppStringsEn.onboardingTitle1,
    AppStringsFr.onboardingTitle1,
  );
  String get onboardingDesc1 => _getString(
    AppStrings.onboardingDesc1,
    AppStringsEn.onboardingDesc1,
    AppStringsFr.onboardingDesc1,
  );
  String get onboardingTitle2 => _getString(
    AppStrings.onboardingTitle2,
    AppStringsEn.onboardingTitle2,
    AppStringsFr.onboardingTitle2,
  );
  String get onboardingDesc2 => _getString(
    AppStrings.onboardingDesc2,
    AppStringsEn.onboardingDesc2,
    AppStringsFr.onboardingDesc2,
  );
  String get onboardingTitle3 => _getString(
    AppStrings.onboardingTitle3,
    AppStringsEn.onboardingTitle3,
    AppStringsFr.onboardingTitle3,
  );
  String get onboardingDesc3 => _getString(
    AppStrings.onboardingDesc3,
    AppStringsEn.onboardingDesc3,
    AppStringsFr.onboardingDesc3,
  );
  String get onboardingTitle4 => _getString(
    AppStrings.onboardingTitle4,
    AppStringsEn.onboardingTitle4,
    AppStringsFr.onboardingTitle4,
  );
  String get onboardingDesc4 => _getString(
    AppStrings.onboardingDesc4,
    AppStringsEn.onboardingDesc4,
    AppStringsFr.onboardingDesc4,
  );
  String get skip =>
      _getString(AppStrings.skip, AppStringsEn.skip, AppStringsFr.skip);

  // Authentication
  String get signIn =>
      _getString(AppStrings.signIn, AppStringsEn.signIn, AppStringsFr.signIn);
  String get signUp =>
      _getString(AppStrings.signUp, AppStringsEn.signUp, AppStringsFr.signUp);
  String get signInWithEmail => _getString(
    AppStrings.signInWithEmail,
    AppStringsEn.signInWithEmail,
    AppStringsFr.signInWithEmail,
  );
  String get signUpWithEmail => _getString(
    AppStrings.signUpWithEmail,
    AppStringsEn.signUpWithEmail,
    AppStringsFr.signUpWithEmail,
  );

  String get signInWithGoogle => _getString(
    AppStrings.signInWithGoogle,
    AppStringsEn.signInWithGoogle,
    AppStringsFr.signInWithGoogle,
  );
  String get signInWithApple => _getString(
    AppStrings.signInWithApple,
    AppStringsEn.signInWithApple,
    AppStringsFr.signInWithApple,
  );
  String get google =>
      _getString(AppStrings.google, AppStringsEn.google, AppStringsFr.google);
  String get apple =>
      _getString(AppStrings.apple, AppStringsEn.apple, AppStringsFr.apple);
  String get enterEmail => _getString(
    AppStrings.enterEmail,
    AppStringsEn.enterEmail,
    AppStringsFr.enterEmail,
  );
  String get enterPassword => _getString(
    AppStrings.enterPassword,
    AppStringsEn.enterPassword,
    AppStringsFr.enterPassword,
  );
  String get continueText => _getString(
    AppStrings.continueText,
    AppStringsEn.continueText,
    AppStringsFr.continueText,
  );
  String get orContinueWith => _getString(
    AppStrings.orContinueWith,
    AppStringsEn.orContinueWith,
    AppStringsFr.orContinueWith,
  );
  String get password => _getString(
    AppStrings.password,
    AppStringsEn.password,
    AppStringsFr.password,
  );
  String get confirmPassword => _getString(
    AppStrings.confirmPassword,
    AppStringsEn.confirmPassword,
    AppStringsFr.confirmPassword,
  );
  String get forgotPassword => _getString(
    AppStrings.forgotPassword,
    AppStringsEn.forgotPassword,
    AppStringsFr.forgotPassword,
  );
  String get resetPassword => _getString(
    AppStrings.resetPassword,
    AppStringsEn.resetPassword,
    AppStringsFr.resetPassword,
  );
  String get sendResetLink => _getString(
    AppStrings.sendResetLink,
    AppStringsEn.sendResetLink,
    AppStringsFr.sendResetLink,
  );
  String get checkYourEmail => _getString(
    AppStrings.checkYourEmail,
    AppStringsEn.checkYourEmail,
    AppStringsFr.checkYourEmail,
  );
  String get resetEmailSent => _getString(
    AppStrings.resetEmailSent,
    AppStringsEn.resetEmailSent,
    AppStringsFr.resetEmailSent,
  );
  String get enterEmailReset => _getString(
    AppStrings.enterEmailReset,
    AppStringsEn.enterEmailReset,
    AppStringsFr.enterEmailReset,
  );
  String get followEmailInstructions => _getString(
    AppStrings.followEmailInstructions,
    AppStringsEn.followEmailInstructions,
    AppStringsFr.followEmailInstructions,
  );
  String get createAccount => _getString(
    AppStrings.createAccount,
    AppStringsEn.createAccount,
    AppStringsFr.createAccount,
  );
  String get agreeToTerms => _getString(
    AppStrings.agreeToTerms,
    AppStringsEn.agreeToTerms,
    AppStringsFr.agreeToTerms,
  );
  String get andText =>
      _getString(AppStrings.and, AppStringsEn.and, AppStringsFr.and);
  String get welcomeBack => _getString(
    AppStrings.welcomeBack,
    AppStringsEn.welcomeBack,
    AppStringsFr.welcomeBack,
  );
  String get signInToContinue => _getString(
    AppStrings.signInToContinue,
    AppStringsEn.signInToContinue,
    AppStringsFr.signInToContinue,
  );
  String get joinSanad => _getString(
    AppStrings.joinSanad,
    AppStringsEn.joinSanad,
    AppStringsFr.joinSanad,
  );
  String get orSignUpWith => _getString(
    AppStrings.orSignUpWith,
    AppStringsEn.orSignUpWith,
    AppStringsFr.orSignUpWith,
  );
  String get backToLogin => _getString(
    AppStrings.backToLogin,
    AppStringsEn.backToLogin,
    AppStringsFr.backToLogin,
  );
  String get completeProfile => _getString(
    AppStrings.completeProfile,
    AppStringsEn.completeProfile,
    AppStringsFr.completeProfile,
  );
  String get helpUsKnowYou => _getString(
    AppStrings.helpUsKnowYou,
    AppStringsEn.helpUsKnowYou,
    AppStringsFr.helpUsKnowYou,
  );
  String get enterFullName => _getString(
    AppStrings.enterFullName,
    AppStringsEn.enterFullName,
    AppStringsFr.enterFullName,
  );
  String get enterPhoneNumber => _getString(
    AppStrings.enterPhoneNumber,
    AppStringsEn.enterPhoneNumber,
    AppStringsFr.enterPhoneNumber,
  );
  String get dateOfBirth => _getString(
    AppStrings.dateOfBirth,
    AppStringsEn.dateOfBirth,
    AppStringsFr.dateOfBirth,
  );
  String get gender =>
      _getString(AppStrings.gender, AppStringsEn.gender, AppStringsFr.gender);
  String get male =>
      _getString(AppStrings.male, AppStringsEn.male, AppStringsFr.male);
  String get female =>
      _getString(AppStrings.female, AppStringsEn.female, AppStringsFr.female);
  String get other =>
      _getString(AppStrings.other, AppStringsEn.other, AppStringsFr.other);
  String get any =>
      _getString(AppStrings.any, AppStringsEn.any, AppStringsFr.any);
  String get veryImportant => _getString(
    AppStrings.veryImportant,
    AppStringsEn.veryImportant,
    AppStringsFr.veryImportant,
  );
  String get somewhatImportant => _getString(
    AppStrings.somewhatImportant,
    AppStringsEn.somewhatImportant,
    AppStringsFr.somewhatImportant,
  );
  String get notImportant => _getString(
    AppStrings.notImportant,
    AppStringsEn.notImportant,
    AppStringsFr.notImportant,
  );
  String get single =>
      _getString(AppStrings.single, AppStringsEn.single, AppStringsFr.single);
  String get married => _getString(
    AppStrings.married,
    AppStringsEn.married,
    AppStringsFr.married,
  );
  String get divorced => _getString(
    AppStrings.divorced,
    AppStringsEn.divorced,
    AppStringsFr.divorced,
  );
  String get widowed => _getString(
    AppStrings.widowed,
    AppStringsEn.widowed,
    AppStringsFr.widowed,
  );
  String get selectOption => _getString(
    AppStrings.selectOption,
    AppStringsEn.selectOption,
    AppStringsFr.selectOption,
  );
  String get preferNotToSay => _getString(
    AppStrings.preferNotToSay,
    AppStringsEn.preferNotToSay,
    AppStringsFr.preferNotToSay,
  );
  String get skipForNow => _getString(
    AppStrings.skipForNow,
    AppStringsEn.skipForNow,
    AppStringsFr.skipForNow,
  );

  // Validation Messages
  String get fieldRequired => _getString(
    AppStrings.fieldRequired,
    AppStringsEn.fieldRequired,
    AppStringsFr.fieldRequired,
  );
  String get invalidEmail => _getString(
    AppStrings.invalidEmail,
    AppStringsEn.invalidEmail,
    AppStringsFr.invalidEmail,
  );
  String get passwordTooShort => _getString(
    AppStrings.passwordTooShort,
    AppStringsEn.passwordTooShort,
    AppStringsFr.passwordTooShort,
  );
  String get passwordsDoNotMatch => _getString(
    AppStrings.passwordsDoNotMatch,
    AppStringsEn.passwordsDoNotMatch,
    AppStringsFr.passwordsDoNotMatch,
  );
  String get invalidPhone => _getString(
    AppStrings.invalidPhone,
    AppStringsEn.invalidPhone,
    AppStringsFr.invalidPhone,
  );
  String get nameTooShort => _getString(
    AppStrings.nameTooShort,
    AppStringsEn.nameTooShort,
    AppStringsFr.nameTooShort,
  );
  String get enterFullDualName => _getString(
    AppStrings.enterFullDualName,
    AppStringsEn.enterFullDualName,
    AppStringsFr.enterFullDualName,
  );

  // Phone Authentication & OTP
  String get safeSpaceForMentalHealth => _getString(
    AppStrings.safeSpaceForMentalHealth,
    AppStringsEn.safeSpaceForMentalHealth,
    AppStringsFr.safeSpaceForMentalHealth,
  );
  String get invalidPhoneNumber => _getString(
    AppStrings.invalidPhoneNumber,
    AppStringsEn.invalidPhoneNumber,
    AppStringsFr.invalidPhoneNumber,
  );
  String get createNewAccount => _getString(
    AppStrings.createNewAccount,
    AppStringsEn.createNewAccount,
    AppStringsFr.createNewAccount,
  );
  String get dataSecureEncrypted => _getString(
    AppStrings.dataSecureEncrypted,
    AppStringsEn.dataSecureEncrypted,
    AppStringsFr.dataSecureEncrypted,
  );
  String get verifyPhoneNumber => _getString(
    AppStrings.verifyPhoneNumber,
    AppStringsEn.verifyPhoneNumber,
    AppStringsFr.verifyPhoneNumber,
  );
  String get enterOtpSentTo => _getString(
    AppStrings.enterOtpSentTo,
    AppStringsEn.enterOtpSentTo,
    AppStringsFr.enterOtpSentTo,
  );
  String get didntReceiveCode => _getString(
    AppStrings.didntReceiveCode,
    AppStringsEn.didntReceiveCode,
    AppStringsFr.didntReceiveCode,
  );
  String get resend =>
      _getString(AppStrings.resend, AppStringsEn.resend, AppStringsFr.resend);
  String get resendIn => _getString(
    AppStrings.resendIn,
    AppStringsEn.resendIn,
    AppStringsFr.resendIn,
  );
  String get seconds => _getString(
    AppStrings.seconds,
    AppStringsEn.seconds,
    AppStringsFr.seconds,
  );
  String get verify =>
      _getString(AppStrings.verify, AppStringsEn.verify, AppStringsFr.verify);
  String get firstName => _getString(
    AppStrings.firstName,
    AppStringsEn.firstName,
    AppStringsFr.firstName,
  );
  String get lastName => _getString(
    AppStrings.lastName,
    AppStringsEn.lastName,
    AppStringsFr.lastName,
  );
  String get enterFirstName => _getString(
    AppStrings.enterFirstName,
    AppStringsEn.enterFirstName,
    AppStringsFr.enterFirstName,
  );
  String get enterLastName => _getString(
    AppStrings.enterLastName,
    AppStringsEn.enterLastName,
    AppStringsFr.enterLastName,
  );

  // Success Messages
  String get profileUpdated => _getString(
    AppStrings.profileUpdated,
    AppStringsEn.profileUpdated,
    AppStringsFr.profileUpdated,
  );
  String get settingsSaved => _getString(
    AppStrings.settingsSaved,
    AppStringsEn.settingsSaved,
    AppStringsFr.settingsSaved,
  );
  String get message => _getString(
    AppStrings.message,
    AppStringsEn.message,
    AppStringsFr.message,
  );
  String get messages => _getString(
    AppStrings.messages,
    AppStringsEn.messages,
    AppStringsFr.messages,
  );
  String get connectWithCareTeam => _getString(
    AppStrings.connectWithCareTeam,
    AppStringsEn.connectWithCareTeam,
    AppStringsFr.connectWithCareTeam,
  );
  String get searchConversations => _getString(
    AppStrings.searchConversations,
    AppStringsEn.searchConversations,
    AppStringsFr.searchConversations,
  );
  String get messageSent => _getString(
    AppStrings.messageSent,
    AppStringsEn.messageSent,
    AppStringsFr.messageSent,
  );
  String get commentAdded => _getString(
    AppStrings.commentAdded,
    AppStringsEn.commentAdded,
    AppStringsFr.commentAdded,
  );
  String get reactionAdded => _getString(
    AppStrings.reactionAdded,
    AppStringsEn.reactionAdded,
    AppStringsFr.reactionAdded,
  );
  String get bookmarkAdded => _getString(
    AppStrings.bookmarkAdded,
    AppStringsEn.bookmarkAdded,
    AppStringsFr.bookmarkAdded,
  );
  String get bookmarkRemoved => _getString(
    AppStrings.bookmarkRemoved,
    AppStringsEn.bookmarkRemoved,
    AppStringsFr.bookmarkRemoved,
  );

  // Inspirational Quotes
  String get quote1 =>
      _getString(AppStrings.quote1, AppStringsEn.quote1, AppStringsFr.quote1);
  String get quote2 =>
      _getString(AppStrings.quote2, AppStringsEn.quote2, AppStringsFr.quote2);
  String get quote3 =>
      _getString(AppStrings.quote3, AppStringsEn.quote3, AppStringsFr.quote3);
  String get quote4 =>
      _getString(AppStrings.quote4, AppStringsEn.quote4, AppStringsFr.quote4);
  String get quote5 =>
      _getString(AppStrings.quote5, AppStringsEn.quote5, AppStringsFr.quote5);
  String get quote6 =>
      _getString(AppStrings.quote6, AppStringsEn.quote6, AppStringsFr.quote6);
  String get quote7 =>
      _getString(AppStrings.quote7, AppStringsEn.quote7, AppStringsFr.quote7);
  String get quote8 =>
      _getString(AppStrings.quote8, AppStringsEn.quote8, AppStringsFr.quote8);
  String get quote9 =>
      _getString(AppStrings.quote9, AppStringsEn.quote9, AppStringsFr.quote9);
  String get quote10 => _getString(
    AppStrings.quote10,
    AppStringsEn.quote10,
    AppStringsFr.quote10,
  );

  // Mental Health Tips
  String get tipOfTheDay => _getString(
    AppStrings.tipOfTheDay,
    AppStringsEn.tipOfTheDay,
    AppStringsFr.tipOfTheDay,
  );
  String get tip1 =>
      _getString(AppStrings.tip1, AppStringsEn.tip1, AppStringsFr.tip1);
  String get tip2 =>
      _getString(AppStrings.tip2, AppStringsEn.tip2, AppStringsFr.tip2);
  String get tip3 =>
      _getString(AppStrings.tip3, AppStringsEn.tip3, AppStringsFr.tip3);
  String get tip4 =>
      _getString(AppStrings.tip4, AppStringsEn.tip4, AppStringsFr.tip4);
  String get tip5 =>
      _getString(AppStrings.tip5, AppStringsEn.tip5, AppStringsFr.tip5);
  String get tip6 =>
      _getString(AppStrings.tip6, AppStringsEn.tip6, AppStringsFr.tip6);
  String get tip7 =>
      _getString(AppStrings.tip7, AppStringsEn.tip7, AppStringsFr.tip7);
  String get tip8 =>
      _getString(AppStrings.tip8, AppStringsEn.tip8, AppStringsFr.tip8);

  // Encouragement Messages
  String get youAreDoingGreat => _getString(
    AppStrings.youAreDoingGreat,
    AppStringsEn.youAreDoingGreat,
    AppStringsFr.youAreDoingGreat,
  );
  String get keepGoing => _getString(
    AppStrings.keepGoing,
    AppStringsEn.keepGoing,
    AppStringsFr.keepGoing,
  );
  String get proudOfYou => _getString(
    AppStrings.proudOfYou,
    AppStringsEn.proudOfYou,
    AppStringsFr.proudOfYou,
  );
  String get oneStepAtATime => _getString(
    AppStrings.oneStepAtATime,
    AppStringsEn.oneStepAtATime,
    AppStringsFr.oneStepAtATime,
  );
  String get youAreNotAlone => _getString(
    AppStrings.youAreNotAlone,
    AppStringsEn.youAreNotAlone,
    AppStringsFr.youAreNotAlone,
  );
  String get itsOkayToNotBeOkay => _getString(
    AppStrings.itsOkayToNotBeOkay,
    AppStringsEn.itsOkayToNotBeOkay,
    AppStringsFr.itsOkayToNotBeOkay,
  );
  String get everyDayIsNewStart => _getString(
    AppStrings.everyDayIsNewStart,
    AppStringsEn.everyDayIsNewStart,
    AppStringsFr.everyDayIsNewStart,
  );
  String get believeInYourself => _getString(
    AppStrings.believeInYourself,
    AppStringsEn.believeInYourself,
    AppStringsFr.believeInYourself,
  );
  String get youMatter => _getString(
    AppStrings.youMatter,
    AppStringsEn.youMatter,
    AppStringsFr.youMatter,
  );
  String get takeItEasy => _getString(
    AppStrings.takeItEasy,
    AppStringsEn.takeItEasy,
    AppStringsFr.takeItEasy,
  );

  // Empty States
  String get noNotifications => _getString(
    AppStrings.noNotifications,
    AppStringsEn.noNotifications,
    AppStringsFr.noNotifications,
  );
  String get noNotificationsDesc => _getString(
    AppStrings.noNotificationsDesc,
    AppStringsEn.noNotificationsDesc,
    AppStringsFr.noNotificationsDesc,
  );
  String get noSessions => _getString(
    AppStrings.noSessions,
    AppStringsEn.noSessions,
    AppStringsFr.noSessions,
  );
  String get noSessionsDesc => _getString(
    AppStrings.noSessionsDesc,
    AppStringsEn.noSessionsDesc,
    AppStringsFr.noSessionsDesc,
  );
  String get noBookmarks => _getString(
    AppStrings.noBookmarks,
    AppStringsEn.noBookmarks,
    AppStringsFr.noBookmarks,
  );
  String get noBookmarksDesc => _getString(
    AppStrings.noBookmarksDesc,
    AppStringsEn.noBookmarksDesc,
    AppStringsFr.noBookmarksDesc,
  );
  String get noResults => _getString(
    AppStrings.noResults,
    AppStringsEn.noResults,
    AppStringsFr.noResults,
  );
  String get tryDifferentSearch => _getString(
    AppStrings.tryDifferentSearch,
    AppStringsEn.tryDifferentSearch,
    AppStringsFr.tryDifferentSearch,
  );

  // Confirmation Dialogs
  String get areYouSure => _getString(
    AppStrings.areYouSure,
    AppStringsEn.areYouSure,
    AppStringsFr.areYouSure,
  );
  String get deletePost => _getString(
    AppStrings.deletePost,
    AppStringsEn.deletePost,
    AppStringsFr.deletePost,
  );
  String get deletePostConfirm => _getString(
    AppStrings.deletePostConfirm,
    AppStringsEn.deletePostConfirm,
    AppStringsFr.deletePostConfirm,
  );
  String get deleteComment => _getString(
    AppStrings.deleteComment,
    AppStringsEn.deleteComment,
    AppStringsFr.deleteComment,
  );
  String get deleteCommentConfirm => _getString(
    AppStrings.deleteCommentConfirm,
    AppStringsEn.deleteCommentConfirm,
    AppStringsFr.deleteCommentConfirm,
  );
  String get cancelBooking => _getString(
    AppStrings.cancelBooking,
    AppStringsEn.cancelBooking,
    AppStringsFr.cancelBooking,
  );
  String get cancelBookingConfirm => _getString(
    AppStrings.cancelBookingConfirm,
    AppStringsEn.cancelBookingConfirm,
    AppStringsFr.cancelBookingConfirm,
  );
  String get yes =>
      _getString(AppStrings.yes, AppStringsEn.yes, AppStringsFr.yes);
  String get no => _getString(AppStrings.no, AppStringsEn.no, AppStringsFr.no);
  String get delete =>
      _getString(AppStrings.delete, AppStringsEn.delete, AppStringsFr.delete);
  String get confirm => _getString(
    AppStrings.confirm,
    AppStringsEn.confirm,
    AppStringsFr.confirm,
  );

  // Session Status
  String get upcomingStatus => _getString(
    AppStrings.upcoming,
    AppStringsEn.upcoming,
    AppStringsFr.upcoming,
  );
  String get completed => _getString(
    AppStrings.completed,
    AppStringsEn.completed,
    AppStringsFr.completed,
  );
  String get cancelledStatus => _getString(
    AppStrings.cancelled,
    AppStringsEn.cancelled,
    AppStringsFr.cancelled,
  );
  String get inProgressStatus => _getString(
    AppStrings.inProgress,
    AppStringsEn.inProgress,
    AppStringsFr.inProgress,
  );
  String get rescheduled => _getString(
    AppStrings.rescheduled,
    AppStringsEn.rescheduled,
    AppStringsFr.rescheduled,
  );

  // Ratings & Reviews
  String get rateYourExperience => _getString(
    AppStrings.rateYourExperience,
    AppStringsEn.rateYourExperience,
    AppStringsFr.rateYourExperience,
  );
  String get howWasYourSession => _getString(
    AppStrings.howWasYourSession,
    AppStringsEn.howWasYourSession,
    AppStringsFr.howWasYourSession,
  );
  String get writeReview => _getString(
    AppStrings.writeReview,
    AppStringsEn.writeReview,
    AppStringsFr.writeReview,
  );
  String get submitReview => _getString(
    AppStrings.submitReview,
    AppStringsEn.submitReview,
    AppStringsFr.submitReview,
  );
  String get thankYouForReview => _getString(
    AppStrings.thankYouForReview,
    AppStringsEn.thankYouForReview,
    AppStringsFr.thankYouForReview,
  );
  String get yourFeedbackMatters => _getString(
    AppStrings.yourFeedbackMatters,
    AppStringsEn.yourFeedbackMatters,
    AppStringsFr.yourFeedbackMatters,
  );
  String get leaveReview => _getString(
    AppStrings.leaveReview,
    AppStringsEn.leaveReview,
    AppStringsFr.leaveReview,
  );
  String get tapToRate => _getString(
    AppStrings.tapToRate,
    AppStringsEn.tapToRate,
    AppStringsFr.tapToRate,
  );
  String get additionalComments => _getString(
    AppStrings.additionalComments,
    AppStringsEn.additionalComments,
    AppStringsFr.additionalComments,
  );
  String get shareYourExperience => _getString(
    AppStrings.shareYourExperience,
    AppStringsEn.shareYourExperience,
    AppStringsFr.shareYourExperience,
  );
  String get updateReview => _getString(
    AppStrings.updateReview,
    AppStringsEn.updateReview,
    AppStringsFr.updateReview,
  );
  String get ratingPoor => _getString(
    AppStrings.ratingPoor,
    AppStringsEn.ratingPoor,
    AppStringsFr.ratingPoor,
  );
  String get ratingFair => _getString(
    AppStrings.ratingFair,
    AppStringsEn.ratingFair,
    AppStringsFr.ratingFair,
  );
  String get ratingGood => _getString(
    AppStrings.ratingGood,
    AppStringsEn.ratingGood,
    AppStringsFr.ratingGood,
  );
  String get ratingVeryGood => _getString(
    AppStrings.ratingVeryGood,
    AppStringsEn.ratingVeryGood,
    AppStringsFr.ratingVeryGood,
  );
  String get ratingExcellent => _getString(
    AppStrings.ratingExcellent,
    AppStringsEn.ratingExcellent,
    AppStringsFr.ratingExcellent,
  );

  // Subscription & Premium
  String get premium => _getString(
    AppStrings.premium,
    AppStringsEn.premium,
    AppStringsFr.premium,
  );
  String get upgradeToPremium => _getString(
    AppStrings.upgradeToPremium,
    AppStringsEn.upgradeToPremium,
    AppStringsFr.upgradeToPremium,
  );
  String get signUpToContinue => _getString(
    AppStrings.signUpToContinue,
    AppStringsEn.signUpToContinue,
    AppStringsFr.signUpToContinue,
  );
  String get upgradeToContinue => _getString(
    AppStrings.upgradeToContinue,
    AppStringsEn.upgradeToContinue,
    AppStringsFr.upgradeToContinue,
  );
  String get guestLimitMessage => _getString(
    AppStrings.guestLimitMessage,
    AppStringsEn.guestLimitMessage,
    AppStringsFr.guestLimitMessage,
  );
  String get freeLimitMessage => _getString(
    AppStrings.freeLimitMessage,
    AppStringsEn.freeLimitMessage,
    AppStringsFr.freeLimitMessage,
  );
  String get unlimitedSessions => _getString(
    AppStrings.unlimitedSessions,
    AppStringsEn.unlimitedSessions,
    AppStringsFr.unlimitedSessions,
  );
  String get exclusiveContent => _getString(
    AppStrings.exclusiveContent,
    AppStringsEn.exclusiveContent,
    AppStringsFr.exclusiveContent,
  );
  String get freeTrialDays => _getString(
    AppStrings.freeTrialDays,
    AppStringsEn.freeTrialDays,
    AppStringsFr.freeTrialDays,
  );
  String get subscribe => _getString(
    AppStrings.subscribe,
    AppStringsEn.subscribe,
    AppStringsFr.subscribe,
  );
  String get restorePurchase => _getString(
    AppStrings.restorePurchase,
    AppStringsEn.restorePurchase,
    AppStringsFr.restorePurchase,
  );

  // Accessibility
  String get accessibility => _getString(
    AppStrings.accessibility,
    AppStringsEn.accessibility,
    AppStringsFr.accessibility,
  );
  String get textSize => _getString(
    AppStrings.textSize,
    AppStringsEn.textSize,
    AppStringsFr.textSize,
  );
  String get increasedContrast => _getString(
    AppStrings.increasedContrast,
    AppStringsEn.increasedContrast,
    AppStringsFr.increasedContrast,
  );
  String get reduceMotion => _getString(
    AppStrings.reduceMotion,
    AppStringsEn.reduceMotion,
    AppStringsFr.reduceMotion,
  );
  String get screenReader => _getString(
    AppStrings.screenReader,
    AppStringsEn.screenReader,
    AppStringsFr.screenReader,
  );

  // Time-specific greetings
  String get goodMorning => _getString(
    AppStrings.goodMorning,
    AppStringsEn.goodMorning,
    AppStringsFr.goodMorning,
  );
  String get goodAfternoon => _getString(
    AppStrings.goodAfternoon,
    AppStringsEn.goodAfternoon,
    AppStringsFr.goodAfternoon,
  );
  String get goodEvening => _getString(
    AppStrings.goodEvening,
    AppStringsEn.goodEvening,
    AppStringsFr.goodEvening,
  );
  String get goodNight => _getString(
    AppStrings.goodNight,
    AppStringsEn.goodNight,
    AppStringsFr.goodNight,
  );

  // Cultural phrases
  String get bismillah => _getString(
    AppStrings.bismillah,
    AppStringsEn.bismillah,
    AppStringsFr.bismillah,
  );
  String get alhamdulillah => _getString(
    AppStrings.alhamdulillah,
    AppStringsEn.alhamdulillah,
    AppStringsFr.alhamdulillah,
  );
  String get inshallah => _getString(
    AppStrings.inshallah,
    AppStringsEn.inshallah,
    AppStringsFr.inshallah,
  );
  String get jazakAllah => _getString(
    AppStrings.jazakAllah,
    AppStringsEn.jazakAllah,
    AppStringsFr.jazakAllah,
  );
  String get barakAllah => _getString(
    AppStrings.barakAllah,
    AppStringsEn.barakAllah,
    AppStringsFr.barakAllah,
  );

  // Payment Flow Screens
  String get paypalPayment => _getString(
    AppStrings.paypalPayment,
    AppStringsEn.paypalPayment,
    AppStringsFr.paypalPayment,
  );
  String get paypalSecure => _getString(
    AppStrings.paypalSecure,
    AppStringsEn.paypalSecure,
    AppStringsFr.paypalSecure,
  );
  String get paypalRedirect => _getString(
    AppStrings.paypalRedirect,
    AppStringsEn.paypalRedirect,
    AppStringsFr.paypalRedirect,
  );

  String get paymentMethod => _getString(
    AppStrings.paymentMethod,
    AppStringsEn.paymentMethod,
    AppStringsFr.paymentMethod,
  );
  String get creditCard => _getString(
    AppStrings.creditCard,
    AppStringsEn.creditCard,
    AppStringsFr.creditCard,
  );
  String get bankTransfer => _getString(
    AppStrings.bankTransfer,
    AppStringsEn.bankTransfer,
    AppStringsFr.bankTransfer,
  );
  String get bankTransferLockedCaption => _getString(
    AppStrings.bankTransferLockedCaption,
    AppStringsEn.bankTransferLockedCaption,
    AppStringsFr.bankTransferLockedCaption,
  );
  String get unlockBankTransfer => _getString(
    AppStrings.unlockBankTransfer,
    AppStringsEn.unlockBankTransfer,
    AppStringsFr.unlockBankTransfer,
  );
  String get bankTransferAlreadyUnlocked => _getString(
    AppStrings.bankTransferAlreadyUnlocked,
    AppStringsEn.bankTransferAlreadyUnlocked,
    AppStringsFr.bankTransferAlreadyUnlocked,
  );
  String get unlockBankTransferConfirm => _getString(
    AppStrings.unlockBankTransferConfirm,
    AppStringsEn.unlockBankTransferConfirm,
    AppStringsFr.unlockBankTransferConfirm,
  );
  String get googlePayment => _getString(
    AppStrings.googlePayment,
    AppStringsEn.googlePayment,
    AppStringsFr.googlePayment,
  );
  String get applePayment => _getString(
    AppStrings.applePayment,
    AppStringsEn.applePayment,
    AppStringsFr.applePayment,
  );

  String get securePayment => _getString(
    AppStrings.securePayment,
    AppStringsEn.securePayment,
    AppStringsFr.securePayment,
  );

  String get pay =>
      _getString(AppStrings.pay, AppStringsEn.pay, AppStringsFr.pay);

  // Subscription Plans
  String get planWeeklyTitle => _getString(
    AppStrings.planWeeklyTitle,
    AppStringsEn.planWeeklyTitle,
    AppStringsFr.planWeeklyTitle,
  );
  String get planWeeklyDesc => _getString(
    AppStrings.planWeeklyDesc,
    AppStringsEn.planWeeklyDesc,
    AppStringsFr.planWeeklyDesc,
  );
  String get planBasicTitle => _getString(
    AppStrings.planBasicTitle,
    AppStringsEn.planBasicTitle,
    AppStringsFr.planBasicTitle,
  );
  String get planBasicDesc => _getString(
    AppStrings.planBasicDesc,
    AppStringsEn.planBasicDesc,
    AppStringsFr.planBasicDesc,
  );
  String get planPremiumTitle => _getString(
    AppStrings.planPremiumTitle,
    AppStringsEn.planPremiumTitle,
    AppStringsFr.planPremiumTitle,
  );
  String get planPremiumDesc => _getString(
    AppStrings.planPremiumDesc,
    AppStringsEn.planPremiumDesc,
    AppStringsFr.planPremiumDesc,
  );
  String get planVipTitle => _getString(
    AppStrings.planVipTitle,
    AppStringsEn.planVipTitle,
    AppStringsFr.planVipTitle,
  );
  String get planVipDesc => _getString(
    AppStrings.planVipDesc,
    AppStringsEn.planVipDesc,
    AppStringsFr.planVipDesc,
  );

  // Subscription Features
  String get featureTextChat => _getString(
    AppStrings.featureTextChat,
    AppStringsEn.featureTextChat,
    AppStringsFr.featureTextChat,
  );
  String get feature247Support => _getString(
    AppStrings.feature247Support,
    AppStringsEn.feature247Support,
    AppStringsFr.feature247Support,
  );
  String get featureDailyReminders => _getString(
    AppStrings.featureDailyReminders,
    AppStringsEn.featureDailyReminders,
    AppStringsFr.featureDailyReminders,
  );
  String get featureAiAssistant => _getString(
    AppStrings.featureAiAssistant,
    AppStringsEn.featureAiAssistant,
    AppStringsFr.featureAiAssistant,
  );

  String get featureAllWeekly => _getString(
    AppStrings.featureAllWeekly,
    AppStringsEn.featureAllWeekly,
    AppStringsFr.featureAllWeekly,
  );
  String get featurePeriodicTests => _getString(
    AppStrings.featurePeriodicTests,
    AppStringsEn.featurePeriodicTests,
    AppStringsFr.featurePeriodicTests,
  );
  String get featureWeeklyReports => _getString(
    AppStrings.featureWeeklyReports,
    AppStringsEn.featureWeeklyReports,
    AppStringsFr.featureWeeklyReports,
  );
  String get featureFastResponse => _getString(
    AppStrings.featureFastResponse,
    AppStringsEn.featureFastResponse,
    AppStringsFr.featureFastResponse,
  );

  String get featureAllBasic => _getString(
    AppStrings.featureAllBasic,
    AppStringsEn.featureAllBasic,
    AppStringsFr.featureAllBasic,
  );
  String get featureDirectTherapist => _getString(
    AppStrings.featureDirectTherapist,
    AppStringsEn.featureDirectTherapist,
    AppStringsFr.featureDirectTherapist,
  );
  String get featureFreeSession => _getString(
    AppStrings.featureFreeSession,
    AppStringsEn.featureFreeSession,
    AppStringsFr.featureFreeSession,
  );
  String get featureWhatsappSupport => _getString(
    AppStrings.featureWhatsappSupport,
    AppStringsEn.featureWhatsappSupport,
    AppStringsFr.featureWhatsappSupport,
  );
  String get featureExclusiveContent => _getString(
    AppStrings.featureExclusiveContent,
    AppStringsEn.featureExclusiveContent,
    AppStringsFr.featureExclusiveContent,
  );

  String get featureAllPremium => _getString(
    AppStrings.featureAllPremium,
    AppStringsEn.featureAllPremium,
    AppStringsFr.featureAllPremium,
  );
  String get featureThreeSessions => _getString(
    AppStrings.featureThreeSessions,
    AppStringsEn.featureThreeSessions,
    AppStringsFr.featureThreeSessions,
  );
  String get featurePriorityEmergency => _getString(
    AppStrings.featurePriorityEmergency,
    AppStringsEn.featurePriorityEmergency,
    AppStringsFr.featurePriorityEmergency,
  );
  String get featureCustomPlan => _getString(
    AppStrings.featureCustomPlan,
    AppStringsEn.featureCustomPlan,
    AppStringsFr.featureCustomPlan,
  );
  String get featureAllWorkshops => _getString(
    AppStrings.featureAllWorkshops,
    AppStringsEn.featureAllWorkshops,
    AppStringsFr.featureAllWorkshops,
  );

  String get bankTransferWhatsApp => _getString(
    AppStrings.bankTransferWhatsApp,
    AppStringsEn.bankTransferWhatsApp,
    AppStringsFr.bankTransferWhatsApp,
  );
  String get payHere => _getString(
    AppStrings.payHere,
    AppStringsEn.payHere,
    AppStringsFr.payHere,
  );
  String get manualVerification => _getString(
    AppStrings.manualVerification,
    AppStringsEn.manualVerification,
    AppStringsFr.manualVerification,
  );
  String get accountHolder => _getString(
    AppStrings.accountHolder,
    AppStringsEn.accountHolder,
    AppStringsFr.accountHolder,
  );
  String get accountNumber => _getString(
    AppStrings.accountNumber,
    AppStringsEn.accountNumber,
    AppStringsFr.accountNumber,
  );
  String get enterCardNumber => _getString(
    AppStrings.enterCardNumber,
    AppStringsEn.enterCardNumber,
    AppStringsFr.enterCardNumber,
  );
  String get invalidCardNumber => _getString(
    AppStrings.invalidCardNumber,
    AppStringsEn.invalidCardNumber,
    AppStringsFr.invalidCardNumber,
  );

  // Bank Transfer Specific
  String get bankTransferInstructions => _getString(
    AppStrings.bankTransferInstructions,
    AppStringsEn.bankTransferInstructions,
    AppStringsFr.bankTransferInstructions,
  );
  String get bankTransferInfo => _getString(
    AppStrings.bankTransferInfo,
    AppStringsEn.bankTransferInfo,
    AppStringsFr.bankTransferInfo,
  );
  String get bankDetails => _getString(
    AppStrings.bankDetails,
    AppStringsEn.bankDetails,
    AppStringsFr.bankDetails,
  );
  String get referenceCode => _getString(
    AppStrings.referenceCode,
    AppStringsEn.referenceCode,
    AppStringsFr.referenceCode,
  );
  String get bankTransferWarning => _getString(
    AppStrings.bankTransferWarning,
    AppStringsEn.bankTransferWarning,
    AppStringsFr.bankTransferWarning,
  );
  String get paymentSent => _getString(
    AppStrings.paymentSent,
    AppStringsEn.paymentSent,
    AppStringsFr.paymentSent,
  );
  String get copiedToClipboard => _getString(
    AppStrings.copiedToClipboard,
    AppStringsEn.copiedToClipboard,
    AppStringsFr.copiedToClipboard,
  );

  String get bankAccountName => _getString(
    AppStrings.bankAccountName,
    AppStringsEn.bankAccountName,
    AppStringsFr.bankAccountName,
  );
  String get bankAccountNumber => _getString(
    AppStrings.bankAccountNumber,
    AppStringsEn.bankAccountNumber,
    AppStringsFr.bankAccountNumber,
  );
  String get bankAccountHolder => _getString(
    AppStrings.bankAccountHolder,
    AppStringsEn.bankAccountHolder,
    AppStringsFr.bankAccountHolder,
  );
  String get bankSwiftCode => _getString(
    AppStrings.bankSwiftCode,
    AppStringsEn.bankSwiftCode,
    AppStringsFr.bankSwiftCode,
  );
  String get bankIban => _getString(
    AppStrings.bankIban,
    AppStringsEn.bankIban,
    AppStringsFr.bankIban,
  );
  String get supportWhatsAppNumber => _getString(
    AppStrings.supportWhatsAppNumber,
    AppStringsEn.supportWhatsAppNumber,
    AppStringsFr.supportWhatsAppNumber,
  );

  String get bankTransferMessage => _getString(
    AppStrings.bankTransferMessage,
    AppStringsEn.bankTransferMessage,
    AppStringsFr.bankTransferMessage,
  );

  // Receipt Upload
  String get receiptUpload => _getString(
    AppStrings.receiptUpload,
    AppStringsEn.receiptUpload,
    AppStringsFr.receiptUpload,
  );
  String get uploadReceiptInfo => _getString(
    AppStrings.uploadReceiptInfo,
    AppStringsEn.uploadReceiptInfo,
    AppStringsFr.uploadReceiptInfo,
  );
  String get dragDropReceipt => _getString(
    AppStrings.dragDropReceipt,
    AppStringsEn.dragDropReceipt,
    AppStringsFr.dragDropReceipt,
  );
  String get orClickBrowse => _getString(
    AppStrings.orClickBrowse,
    AppStringsEn.orClickBrowse,
    AppStringsFr.orClickBrowse,
  );
  String get maxUploadSize => _getString(
    AppStrings.maxUploadSize,
    AppStringsEn.maxUploadSize,
    AppStringsFr.maxUploadSize,
  );
  String get receiptSelected => _getString(
    AppStrings.receiptSelected,
    AppStringsEn.receiptSelected,
    AppStringsFr.receiptSelected,
  );
  String get changeReceipt => _getString(
    AppStrings.changeReceipt,
    AppStringsEn.changeReceipt,
    AppStringsFr.changeReceipt,
  );
  String get acceptedFormats => _getString(
    AppStrings.acceptedFormats,
    AppStringsEn.acceptedFormats,
    AppStringsFr.acceptedFormats,
  );
  String get acceptedFormatsList => _getString(
    AppStrings.acceptedFormatsList,
    AppStringsEn.acceptedFormatsList,
    AppStringsFr.acceptedFormatsList,
  );
  String get receiptInfo => _getString(
    AppStrings.receiptInfo,
    AppStringsEn.receiptInfo,
    AppStringsFr.receiptInfo,
  );
  String get receiptVerificationTerms => _getString(
    AppStrings.receiptVerificationTerms,
    AppStringsEn.receiptVerificationTerms,
    AppStringsFr.receiptVerificationTerms,
  );
  String get submitVerification => _getString(
    AppStrings.submitVerification,
    AppStringsEn.submitVerification,
    AppStringsFr.submitVerification,
  );

  // Payment Success
  String get paymentSuccessful => _getString(
    AppStrings.paymentSuccessful,
    AppStringsEn.paymentSuccessful,
    AppStringsFr.paymentSuccessful,
  );
  String get paymentFailed => _getString(
    AppStrings.paymentFailed,
    AppStringsEn.paymentFailed,
    AppStringsFr.paymentFailed,
  );
  String get paymentSuccessMessage => _getString(
    AppStrings.paymentSuccessMessage,
    AppStringsEn.paymentSuccessMessage,
    AppStringsFr.paymentSuccessMessage,
  );
  String get nextSteps => _getString(
    AppStrings.nextSteps,
    AppStringsEn.nextSteps,
    AppStringsFr.nextSteps,
  );
  String get startChatting => _getString(
    AppStrings.startChatting,
    AppStringsEn.startChatting,
    AppStringsFr.startChatting,
  );
  String get bookTherapyCall => _getString(
    AppStrings.bookTherapyCall,
    AppStringsEn.bookTherapyCall,
    AppStringsFr.bookTherapyCall,
  );
  String get accessMoodTracking => _getString(
    AppStrings.accessMoodTracking,
    AppStringsEn.accessMoodTracking,
    AppStringsFr.accessMoodTracking,
  );
  String get payNow =>
      _getString(AppStrings.payNow, AppStringsEn.payNow, AppStringsFr.payNow);
  String get completePayment => _getString(
    AppStrings.completePayment,
    AppStringsEn.completePayment,
    AppStringsFr.completePayment,
  );
  String get paymentDeadline => _getString(
    AppStrings.paymentDeadline,
    AppStringsEn.paymentDeadline,
    AppStringsFr.paymentDeadline,
  );
  String get bookingExpired => _getString(
    AppStrings.bookingExpired,
    AppStringsEn.bookingExpired,
    AppStringsFr.bookingExpired,
  );
  String get selectPaymentMethod => _getString(
    AppStrings.selectPaymentMethod,
    AppStringsEn.selectPaymentMethod,
    AppStringsFr.selectPaymentMethod,
  );
  String get googlePay => _getString(
    AppStrings.googlePay,
    AppStringsEn.googlePay,
    AppStringsFr.googlePay,
  );
  String get paymentSecure => _getString(
    AppStrings.paymentSecure,
    AppStringsEn.paymentSecure,
    AppStringsFr.paymentSecure,
  );
  String get enabled => _getString(
    AppStrings.enabled,
    AppStringsEn.enabled,
    AppStringsFr.enabled,
  );
  String get disabled => _getString(
    AppStrings.disabled,
    AppStringsEn.disabled,
    AppStringsFr.disabled,
  );

  // Google Pay Payment
  String get googlePaySecure => _getString(
    AppStrings.googlePaySecure,
    AppStringsEn.googlePaySecure,
    AppStringsFr.googlePaySecure,
  );
  String get googlePayRedirect => _getString(
    AppStrings.googlePayRedirect,
    AppStringsEn.googlePayRedirect,
    AppStringsFr.googlePayRedirect,
  );
  String get continueToGooglePay => _getString(
    AppStrings.continueToGooglePay,
    AppStringsEn.continueToGooglePay,
    AppStringsFr.continueToGooglePay,
  );

  // Cash Payment
  String get cashPaymentInfo => _getString(
    AppStrings.cashPaymentInfo,
    AppStringsEn.cashPaymentInfo,
    AppStringsFr.cashPaymentInfo,
  );
  String get confirmCashPayment => _getString(
    AppStrings.confirmCashPayment,
    AppStringsEn.confirmCashPayment,
    AppStringsFr.confirmCashPayment,
  );
  String get paymentCancelled => _getString(
    AppStrings.paymentCancelled,
    AppStringsEn.paymentCancelled,
    AppStringsFr.paymentCancelled,
  );
  String get cancelPayment => _getString(
    AppStrings.cancelPayment,
    AppStringsEn.cancelPayment,
    AppStringsFr.cancelPayment,
  );
  String get cancelPaymentConfirm => _getString(
    AppStrings.cancelPaymentConfirm,
    AppStringsEn.cancelPaymentConfirm,
    AppStringsFr.cancelPaymentConfirm,
  );

  // Admin Dashboard
  String get accessDenied => _getString(
    AppStrings.accessDenied,
    AppStringsEn.accessDenied,
    AppStringsFr.accessDenied,
  );
  String get adminOnlyAccess => _getString(
    AppStrings.adminOnlyAccess,
    AppStringsEn.adminOnlyAccess,
    AppStringsFr.adminOnlyAccess,
  );
  String get paymentVerifications => _getString(
    AppStrings.paymentVerifications,
    AppStringsEn.paymentVerifications,
    AppStringsFr.paymentVerifications,
  );
  String get pending => _getString(
    AppStrings.pending,
    AppStringsEn.pending,
    AppStringsFr.pending,
  );
  String get approved => _getString(
    AppStrings.approved,
    AppStringsEn.approved,
    AppStringsFr.approved,
  );
  String get rejected => _getString(
    AppStrings.rejected,
    AppStringsEn.rejected,
    AppStringsFr.rejected,
  );
  String get all =>
      _getString(AppStrings.all, AppStringsEn.all, AppStringsFr.all);
  String get noVerifications => _getString(
    AppStrings.noVerifications,
    AppStringsEn.noVerifications,
    AppStringsFr.noVerifications,
  );
  String get noPendingVerifications => _getString(
    AppStrings.noPendingVerifications,
    AppStringsEn.noPendingVerifications,
    AppStringsFr.noPendingVerifications,
  );
  String get noApprovedVerifications => _getString(
    AppStrings.noApprovedVerifications,
    AppStringsEn.noApprovedVerifications,
    AppStringsFr.noApprovedVerifications,
  );
  String get noRejectedVerifications => _getString(
    AppStrings.noRejectedVerifications,
    AppStringsEn.noRejectedVerifications,
    AppStringsFr.noRejectedVerifications,
  );
  String get noVerificationsYet => _getString(
    AppStrings.noVerificationsYet,
    AppStringsEn.noVerificationsYet,
    AppStringsFr.noVerificationsYet,
  );
  String get userInformation => _getString(
    AppStrings.userInformation,
    AppStringsEn.userInformation,
    AppStringsFr.userInformation,
  );
  String get paymentDetails => _getString(
    AppStrings.paymentDetails,
    AppStringsEn.paymentDetails,
    AppStringsFr.paymentDetails,
  );
  String get product => _getString(
    AppStrings.product,
    AppStringsEn.product,
    AppStringsFr.product,
  );
  String get amount =>
      _getString(AppStrings.amount, AppStringsEn.amount, AppStringsFr.amount);
  String get submittedAt => _getString(
    AppStrings.submittedAt,
    AppStringsEn.submittedAt,
    AppStringsFr.submittedAt,
  );
  String get reviewReceipt => _getString(
    AppStrings.reviewReceipt,
    AppStringsEn.reviewReceipt,
    AppStringsFr.reviewReceipt,
  );
  String get receiptImage => _getString(
    AppStrings.receiptImage,
    AppStringsEn.receiptImage,
    AppStringsFr.receiptImage,
  );
  String get tapToZoom => _getString(
    AppStrings.tapToZoom,
    AppStringsEn.tapToZoom,
    AppStringsFr.tapToZoom,
  );
  String get failedToLoadImage => _getString(
    AppStrings.failedToLoadImage,
    AppStringsEn.failedToLoadImage,
    AppStringsFr.failedToLoadImage,
  );
  String get noReceiptUploaded => _getString(
    AppStrings.noReceiptUploaded,
    AppStringsEn.noReceiptUploaded,
    AppStringsFr.noReceiptUploaded,
  );
  String get approvePayment => _getString(
    AppStrings.approvePayment,
    AppStringsEn.approvePayment,
    AppStringsFr.approvePayment,
  );
  String get rejectPayment => _getString(
    AppStrings.rejectPayment,
    AppStringsEn.rejectPayment,
    AppStringsFr.rejectPayment,
  );
  String get reviewDetails => _getString(
    AppStrings.reviewDetails,
    AppStringsEn.reviewDetails,
    AppStringsFr.reviewDetails,
  );
  String get reviewedAt => _getString(
    AppStrings.reviewedAt,
    AppStringsEn.reviewedAt,
    AppStringsFr.reviewedAt,
  );
  String get reviewedBy => _getString(
    AppStrings.reviewedBy,
    AppStringsEn.reviewedBy,
    AppStringsFr.reviewedBy,
  );
  String get confirmApproval => _getString(
    AppStrings.confirmApproval,
    AppStringsEn.confirmApproval,
    AppStringsFr.confirmApproval,
  );
  String get approvalConfirmationMessage => _getString(
    AppStrings.approvalConfirmationMessage,
    AppStringsEn.approvalConfirmationMessage,
    AppStringsFr.approvalConfirmationMessage,
  );
  String get approve => _getString(
    AppStrings.approve,
    AppStringsEn.approve,
    AppStringsFr.approve,
  );
  String get reject =>
      _getString(AppStrings.reject, AppStringsEn.reject, AppStringsFr.reject);
  String get paymentApproved => _getString(
    AppStrings.paymentApproved,
    AppStringsEn.paymentApproved,
    AppStringsFr.paymentApproved,
  );
  String get paymentRejected => _getString(
    AppStrings.paymentRejected,
    AppStringsEn.paymentRejected,
    AppStringsFr.paymentRejected,
  );
  String get reason =>
      _getString(AppStrings.reason, AppStringsEn.reason, AppStringsFr.reason);
  String get rejectionReasonPrompt => _getString(
    AppStrings.rejectionReasonPrompt,
    AppStringsEn.rejectionReasonPrompt,
    AppStringsFr.rejectionReasonPrompt,
  );
  String get enterRejectionReason => _getString(
    AppStrings.enterRejectionReason,
    AppStringsEn.enterRejectionReason,
    AppStringsFr.enterRejectionReason,
  );
  String get userId =>
      _getString(AppStrings.userId, AppStringsEn.userId, AppStringsFr.userId);
  String get userName =>
      _getString(AppStrings.name, AppStringsEn.name, AppStringsFr.name);
  String get name =>
      _getString(AppStrings.name, AppStringsEn.name, AppStringsFr.name);

  // Additional Subscription & Payment getters
  String get subscription => _getString(
    AppStrings.subscription,
    AppStringsEn.subscription,
    AppStringsFr.subscription,
  );
  String get unlimitedChat => _getString(
    AppStrings.unlimitedChat,
    AppStringsEn.unlimitedChat,
    AppStringsFr.unlimitedChat,
  );
  String get chatWithAiAndTherapists => _getString(
    'دردشة غير محدودة مع الذكاء الاصطناعي والمعالجين',
    'Unlimited chat with AI and therapists',
    'Chat illimité avec l\'IA et les thérapeutes',
  );
  String get subscriptionRequired => _getString(
    AppStrings.subscriptionRequired,
    AppStringsEn.subscriptionRequired,
    AppStringsFr.subscriptionRequired,
  );
  String get subscribeToBook => _getString(
    AppStrings.subscribeToBook,
    AppStringsEn.subscribeToBook,
    AppStringsFr.subscribeToBook,
  );

  String get maybeLater => _getString(
    AppStrings.maybeLater,
    AppStringsEn.maybeLater,
    AppStringsFr.maybeLater,
  );
  String get unlimitedChatAndTherapyCalls => _getString(
    'رسائل غير محدودة ومكالمات علاجية',
    'Unlimited messaging and therapy calls',
    'Messagerie illimitée et appels thérapeutiques',
  );
  String get bankName => _getString(
    AppStrings.bankName,
    AppStringsEn.bankName,
    AppStringsFr.bankName,
  );
  String get swiftCode => _getString(
    AppStrings.swiftCode,
    AppStringsEn.swiftCode,
    AppStringsFr.swiftCode,
  );
  String get iban =>
      _getString(AppStrings.iban, AppStringsEn.iban, AppStringsFr.iban);
  String get cardholderName => _getString(
    AppStrings.cardholderName,
    AppStringsEn.cardholderName,
    AppStringsFr.cardholderName,
  );
  String get cardNumber => _getString(
    AppStrings.cardNumber,
    AppStringsEn.cardNumber,
    AppStringsFr.cardNumber,
  );
  String get expiryDate => _getString(
    AppStrings.expiryDate,
    AppStringsEn.expiryDate,
    AppStringsFr.expiryDate,
  );
  String get cvv =>
      _getString(AppStrings.cvv, AppStringsEn.cvv, AppStringsFr.cvv);
  String get billingStatement => _getString(
    AppStrings.billingStatement,
    AppStringsEn.billingStatement,
    AppStringsFr.billingStatement,
  );
  String get processingPayment => _getString(
    AppStrings.processingPayment,
    AppStringsEn.processingPayment,
    AppStringsFr.processingPayment,
  );
  String get cashPayment => _getString(
    AppStrings.cashPayment,
    AppStringsEn.cashPayment,
    AppStringsFr.cashPayment,
  );
  String get cashPaymentDesc => _getString(
    AppStrings.cashPaymentDesc,
    AppStringsEn.cashPaymentDesc,
    AppStringsFr.cashPaymentDesc,
  );
  String get choosePaymentMethod => _getString(
    AppStrings.choosePaymentMethod,
    AppStringsEn.choosePaymentMethod,
    AppStringsFr.choosePaymentMethod,
  );
  String get autoRenewalStatement => _getString(
    AppStrings.autoRenewalStatement,
    AppStringsEn.autoRenewalStatement,
    AppStringsFr.autoRenewalStatement,
  );
  String get verificationPending => _getString(
    AppStrings.verificationPending,
    AppStringsEn.verificationPending,
    AppStringsFr.verificationPending,
  );
  String get paymentPending => _getString(
    AppStrings.paymentPending,
    AppStringsEn.paymentPending,
    AppStringsFr.paymentPending,
  );
  String get renewalDate => _getString(
    AppStrings.renewalDate,
    AppStringsEn.renewalDate,
    AppStringsFr.renewalDate,
  );
  String get status =>
      _getString(AppStrings.status, AppStringsEn.status, AppStringsFr.status);
  String get subscriptionActive => _getString(
    AppStrings.subscriptionActive,
    AppStringsEn.subscriptionActive,
    AppStringsFr.subscriptionActive,
  );
  String get subscriptionFree => _getString(
    AppStrings.subscriptionFree,
    AppStringsEn.subscriptionFree,
    AppStringsFr.subscriptionFree,
  );
  String get subscriptionHistory => _getString(
    AppStrings.subscriptionHistory,
    AppStringsEn.subscriptionHistory,
    AppStringsFr.subscriptionHistory,
  );
  String get premiumPlan => _getString(
    AppStrings.premiumPlan,
    AppStringsEn.premiumPlan,
    AppStringsFr.premiumPlan,
  );
  String get viewPastPayments => _getString(
    AppStrings.viewPastPayments,
    AppStringsEn.viewPastPayments,
    AppStringsFr.viewPastPayments,
  );
  String get autoRenewal => _getString(
    AppStrings.autoRenewal,
    AppStringsEn.autoRenewal,
    AppStringsFr.autoRenewal,
  );
  String get paymentHelp => _getString(
    AppStrings.paymentHelp,
    AppStringsEn.paymentHelp,
    AppStringsFr.paymentHelp,
  );
  String get subscriptionExpired => _getString(
    AppStrings.subscriptionExpired,
    AppStringsEn.subscriptionExpired,
    AppStringsFr.subscriptionExpired,
  );
  String get therapistDisclaimer => _getString(
    AppStrings.therapistDisclaimer,
    AppStringsEn.therapistDisclaimer,
    AppStringsFr.therapistDisclaimer,
  );
  String get cancelSubscription => _getString(
    AppStrings.cancelSubscription,
    AppStringsEn.cancelSubscription,
    AppStringsFr.cancelSubscription,
  );
  String get cancelKeepsAccessUntil => _getString(
    AppStrings.cancelKeepsAccessUntil,
    AppStringsEn.cancelKeepsAccessUntil,
    AppStringsFr.cancelKeepsAccessUntil,
  );
  String get cancelNoExpiryNotice => _getString(
    AppStrings.cancelNoExpiryNotice,
    AppStringsEn.cancelNoExpiryNotice,
    AppStringsFr.cancelNoExpiryNotice,
  );
  String get subscriptionCancelledUntil => _getString(
    AppStrings.subscriptionCancelledUntil,
    AppStringsEn.subscriptionCancelledUntil,
    AppStringsFr.subscriptionCancelledUntil,
  );
  String get subscriptionCancelled => _getString(
    AppStrings.subscriptionCancelled,
    AppStringsEn.subscriptionCancelled,
    AppStringsFr.subscriptionCancelled,
  );
  // New key: friendly fallback shown when subscription cancellation fails.
  String get subscriptionCancelError => _getString(
    AppStrings.subscriptionCancelError,
    AppStringsEn.subscriptionCancelError,
    AppStringsFr.subscriptionCancelError,
  );
  String get validUntil => _getString(
    AppStrings.validUntil,
    AppStringsEn.validUntil,
    AppStringsFr.validUntil,
  );
  String get autoRenewOff => _getString(
    AppStrings.autoRenewOff,
    AppStringsEn.autoRenewOff,
    AppStringsFr.autoRenewOff,
  );
  String get premiumOnly => _getString(
    AppStrings.premiumOnly,
    AppStringsEn.premiumOnly,
    AppStringsFr.premiumOnly,
  );

  String get whatsAppSupport => _getString(
    AppStrings.whatsAppSupport,
    AppStringsEn.whatsAppSupport,
    AppStringsFr.whatsAppSupport,
  );
  String get paymentIssue => _getString(
    AppStrings.paymentIssue,
    AppStringsEn.paymentIssue,
    AppStringsFr.paymentIssue,
  );

  // Subscription Plan Strings
  String get choosePlan => _getString(
    AppStrings.choosePlan,
    AppStringsEn.choosePlan,
    AppStringsFr.choosePlan,
  );
  String get month =>
      _getString(AppStrings.month, AppStringsEn.month, AppStringsFr.month);
  String get hour =>
      _getString(AppStrings.hour, AppStringsEn.hour, AppStringsFr.hour);
  String get cancelAnytime => _getString(
    AppStrings.cancelAnytime,
    AppStringsEn.cancelAnytime,
    AppStringsFr.cancelAnytime,
  );
  String get popular => _getString(
    AppStrings.popular,
    AppStringsEn.popular,
    AppStringsFr.popular,
  );
  String get bestValue => _getString(
    AppStrings.bestValue,
    AppStringsEn.bestValue,
    AppStringsFr.bestValue,
  );
  String get premiumFeatures => _getString(
    AppStrings.premiumFeatures,
    AppStringsEn.premiumFeatures,
    AppStringsFr.premiumFeatures,
  );
  String get prioritySupport => _getString(
    AppStrings.prioritySupport,
    AppStringsEn.prioritySupport,
    AppStringsFr.prioritySupport,
  );
  String get chatSubscription => _getString(
    AppStrings.chatSubscription,
    AppStringsEn.chatSubscription,
    AppStringsFr.chatSubscription,
  );
  String get chatSubscriptionDesc => _getString(
    AppStrings.chatSubscriptionDesc,
    AppStringsEn.chatSubscriptionDesc,
    AppStringsFr.chatSubscriptionDesc,
  );
  String get therapyCall => _getString(
    AppStrings.therapyCall,
    AppStringsEn.therapyCall,
    AppStringsFr.therapyCall,
  );
  String get therapyCallDesc => _getString(
    AppStrings.therapyCallDesc,
    AppStringsEn.therapyCallDesc,
    AppStringsFr.therapyCallDesc,
  );
  String get unlimitedChatAI => _getString(
    AppStrings.unlimitedChatAI,
    AppStringsEn.unlimitedChatAI,
    AppStringsFr.unlimitedChatAI,
  );
  String get moodTrackingTools => _getString(
    AppStrings.moodTrackingTools,
    AppStringsEn.moodTrackingTools,
    AppStringsFr.moodTrackingTools,
  );
  String get therapyLibrary => _getString(
    AppStrings.therapyLibrary,
    AppStringsEn.therapyLibrary,
    AppStringsFr.therapyLibrary,
  );
  String get chatWithTherapist => _getString(
    AppStrings.chatWithTherapist,
    AppStringsEn.chatWithTherapist,
    AppStringsFr.chatWithTherapist,
  );
  String get therapySessions => _getString(
    AppStrings.therapySessions,
    AppStringsEn.therapySessions,
    AppStringsFr.therapySessions,
  );
  String get videoAudioCalls => _getString(
    AppStrings.videoAudioCalls,
    AppStringsEn.videoAudioCalls,
    AppStringsFr.videoAudioCalls,
  );
  String get flexibleBooking => _getString(
    AppStrings.flexibleBooking,
    AppStringsEn.flexibleBooking,
    AppStringsFr.flexibleBooking,
  );
  String get payOnlyForUsed => _getString(
    AppStrings.payOnlyForUsed,
    AppStringsEn.payOnlyForUsed,
    AppStringsFr.payOnlyForUsed,
  );
  String get planWeekly => _getString(
    AppStrings.planWeekly,
    AppStringsEn.planWeekly,
    AppStringsFr.planWeekly,
  );
  String get planBasic => _getString(
    AppStrings.planBasic,
    AppStringsEn.planBasic,
    AppStringsFr.planBasic,
  );
  String get planPremium => _getString(
    AppStrings.planPremium,
    AppStringsEn.planPremium,
    AppStringsFr.planPremium,
  );
  String get planElite => _getString(
    AppStrings.planElite,
    AppStringsEn.planElite,
    AppStringsFr.planElite,
  );
  String get psychTests => _getString(
    AppStrings.psychTests,
    AppStringsEn.psychTests,
    AppStringsFr.psychTests,
  );

  String get psychTestsRequireSubscription => _getString(
    AppStrings.psychTestsRequireSubscription,
    AppStringsEn.psychTestsRequireSubscription,
    AppStringsFr.psychTestsRequireSubscription,
  );

  String get moreFeatures => _getString(
    AppStrings.moreFeatures,
    AppStringsEn.moreFeatures,
    AppStringsFr.moreFeatures,
  );

  // Guest Mode & Auth aliases
  // These provide easier access to common guest-related strings
  String get login => signIn; // Alias for signIn
  String get chat => _getString(
    AppStrings.chatTitle,
    AppStringsEn.chatTitle,
    AppStringsFr.chatTitle,
  );

  String get loginRequired => _getString(
    AppStrings.loginRequired,
    AppStringsEn.loginRequired,
    AppStringsFr.loginRequired,
  );
  String get loginToAccess => _getString(
    AppStrings.loginToAccess,
    AppStringsEn.loginToAccess,
    AppStringsFr.loginToAccess,
  );
  String get guestUser => _getString(
    AppStrings.guestUser,
    AppStringsEn.guestUser,
    AppStringsFr.guestUser,
  );
  String get loginToChat => _getString(
    AppStrings.loginToChat,
    AppStringsEn.loginToChat,
    AppStringsFr.loginToChat,
  );
  String get loginToTrackMood => _getString(
    AppStrings.loginToTrackMood,
    AppStringsEn.loginToTrackMood,
    AppStringsFr.loginToTrackMood,
  );

  // Therapy Types
  String get selectTherapyType => _getString(
    AppStrings.selectTherapyType,
    AppStringsEn.selectTherapyType,
    AppStringsFr.selectTherapyType,
  );
  String get selectTherapyTypeSubtitle => _getString(
    AppStrings.selectTherapyTypeSubtitle,
    AppStringsEn.selectTherapyTypeSubtitle,
    AppStringsFr.selectTherapyTypeSubtitle,
  );
  String get therapyIndividual => _getString(
    AppStrings.therapyIndividual,
    AppStringsEn.therapyIndividual,
    AppStringsFr.therapyIndividual,
  );
  String get therapyIndividualDesc => _getString(
    AppStrings.therapyIndividualDesc,
    AppStringsEn.therapyIndividualDesc,
    AppStringsFr.therapyIndividualDesc,
  );
  String get therapyCouples => _getString(
    AppStrings.therapyCouples,
    AppStringsEn.therapyCouples,
    AppStringsFr.therapyCouples,
  );
  String get therapyCouplesDesc => _getString(
    AppStrings.therapyCouplesDesc,
    AppStringsEn.therapyCouplesDesc,
    AppStringsFr.therapyCouplesDesc,
  );
  String get therapyTeen => _getString(
    AppStrings.therapyTeen,
    AppStringsEn.therapyTeen,
    AppStringsFr.therapyTeen,
  );
  String get therapyTeenDesc => _getString(
    AppStrings.therapyTeenDesc,
    AppStringsEn.therapyTeenDesc,
    AppStringsFr.therapyTeenDesc,
  );
  String get select =>
      _getString(AppStrings.select, AppStringsEn.select, AppStringsFr.select);
  String get startTherapyJourney => _getString(
    AppStrings.startTherapyJourney,
    AppStringsEn.startTherapyJourney,
    AppStringsFr.startTherapyJourney,
  );
  String get chooseRightSupport => _getString(
    AppStrings.chooseRightSupport,
    AppStringsEn.chooseRightSupport,
    AppStringsFr.chooseRightSupport,
  );
  String get loginToBook => _getString(
    AppStrings.loginToBook,
    AppStringsEn.loginToBook,
    AppStringsFr.loginToBook,
  );
  String get loginToPost => _getString(
    AppStrings.loginToPost,
    AppStringsEn.loginToPost,
    AppStringsFr.loginToPost,
  );
  String get loginToViewProfile => _getString(
    AppStrings.loginToViewProfile,
    AppStringsEn.loginToViewProfile,
    AppStringsFr.loginToViewProfile,
  );
  String get exploreAsGuest => _getString(
    AppStrings.exploreAsGuest,
    AppStringsEn.exploreAsGuest,
    AppStringsFr.exploreAsGuest,
  );
  String get guestWelcome => _getString(
    AppStrings.guestWelcome,
    AppStringsEn.guestWelcome,
    AppStringsFr.guestWelcome,
  );
  String get guestDescription => _getString(
    AppStrings.guestDescription,
    AppStringsEn.guestDescription,
    AppStringsFr.guestDescription,
  );

  // Quick Actions
  String get qaLogMood => _getString(
    AppStrings.qaLogMood,
    AppStringsEn.qaLogMood,
    AppStringsFr.qaLogMood,
  );
  String get qaStartChat => _getString(
    AppStrings.qaStartChat,
    AppStringsEn.qaStartChat,
    AppStringsFr.qaStartChat,
  );
  String get qaNewPost => _getString(
    AppStrings.qaNewPost,
    AppStringsEn.qaNewPost,
    AppStringsFr.qaNewPost,
  );
  String get qaBookSession => _getString(
    AppStrings.qaBookSession,
    AppStringsEn.qaBookSession,
    AppStringsFr.qaBookSession,
  );
  String get qaMoodHistory => _getString(
    AppStrings.qaMoodHistory,
    AppStringsEn.qaMoodHistory,
    AppStringsFr.qaMoodHistory,
  );
  String get qaFindTherapist => _getString(
    AppStrings.qaFindTherapist,
    AppStringsEn.qaFindTherapist,
    AppStringsFr.qaFindTherapist,
  );
  String get qaCrisisSupport => _getString(
    AppStrings.qaCrisisSupport,
    AppStringsEn.qaCrisisSupport,
    AppStringsFr.qaCrisisSupport,
  );
  String get qaLogMoodDesc => _getString(
    AppStrings.qaLogMoodDesc,
    AppStringsEn.qaLogMoodDesc,
    AppStringsFr.qaLogMoodDesc,
  );
  String get qaStartChatDesc => _getString(
    AppStrings.qaStartChatDesc,
    AppStringsEn.qaStartChatDesc,
    AppStringsFr.qaStartChatDesc,
  );
  String get qaNewPostDesc => _getString(
    AppStrings.qaNewPostDesc,
    AppStringsEn.qaNewPostDesc,
    AppStringsFr.qaNewPostDesc,
  );
  String get qaBookSessionDesc => _getString(
    AppStrings.qaBookSessionDesc,
    AppStringsEn.qaBookSessionDesc,
    AppStringsFr.qaBookSessionDesc,
  );
  String get qaMoodHistoryDesc => _getString(
    AppStrings.qaMoodHistoryDesc,
    AppStringsEn.qaMoodHistoryDesc,
    AppStringsFr.qaMoodHistoryDesc,
  );
  String get qaFindTherapistDesc => _getString(
    AppStrings.qaFindTherapistDesc,
    AppStringsEn.qaFindTherapistDesc,
    AppStringsFr.qaFindTherapistDesc,
  );
  String get qaCrisisSupportDesc => _getString(
    AppStrings.qaCrisisSupportDesc,
    AppStringsEn.qaCrisisSupportDesc,
    AppStringsFr.qaCrisisSupportDesc,
  );

  // Quick Actions Settings
  String get reset =>
      _getString(AppStrings.reset, AppStringsEn.reset, AppStringsFr.reset);
  String get preview => _getString(
    AppStrings.preview,
    AppStringsEn.preview,
    AppStringsFr.preview,
  );
  String get noActionsEnabled => _getString(
    AppStrings.noActionsEnabled,
    AppStringsEn.noActionsEnabled,
    AppStringsFr.noActionsEnabled,
  );
  String get availableActions => _getString(
    AppStrings.availableActions,
    AppStringsEn.availableActions,
    AppStringsFr.availableActions,
  );
  String get toggleActionsDesc => _getString(
    AppStrings.toggleActionsDesc,
    AppStringsEn.toggleActionsDesc,
    AppStringsFr.toggleActionsDesc,
  );
  String get maxVisibleActionsLabel => _getString(
    AppStrings.maxVisibleActionsLabel,
    AppStringsEn.maxVisibleActionsLabel,
    AppStringsFr.maxVisibleActionsLabel,
  );
  String get primaryActionLabel => _getString(
    AppStrings.primaryActionLabel,
    AppStringsEn.primaryActionLabel,
    AppStringsFr.primaryActionLabel,
  );
  String get longPressDesc => _getString(
    AppStrings.longPressDesc,
    AppStringsEn.longPressDesc,
    AppStringsFr.longPressDesc,
  );

  // Therapist Portal - Registration
  String get registerAsTherapist => _getString(
    AppStrings.registerAsTherapist,
    AppStringsEn.registerAsTherapist,
    AppStringsFr.registerAsTherapist,
  );
  String get therapistRegistration => _getString(
    AppStrings.therapistRegistration,
    AppStringsEn.therapistRegistration,
    AppStringsFr.therapistRegistration,
  );
  String get basicInformation => _getString(
    AppStrings.basicInformation,
    AppStringsEn.basicInformation,
    AppStringsFr.basicInformation,
  );
  String get professionalDetails => _getString(
    AppStrings.professionalDetails,
    AppStringsEn.professionalDetails,
    AppStringsFr.professionalDetails,
  );
  String get sessionInfo => _getString(
    AppStrings.sessionInfo,
    AppStringsEn.sessionInfo,
    AppStringsFr.sessionInfo,
  );
  String get professionalTitle => _getString(
    AppStrings.professionalTitle,
    AppStringsEn.professionalTitle,
    AppStringsFr.professionalTitle,
  );
  String get professionalTitleHint => _getString(
    AppStrings.professionalTitleHint,
    AppStringsEn.professionalTitleHint,
    AppStringsFr.professionalTitleHint,
  );
  String get yourBio => _getString(
    AppStrings.yourBio,
    AppStringsEn.yourBio,
    AppStringsFr.yourBio,
  );
  String get bioHint => _getString(
    AppStrings.bioHint,
    AppStringsEn.bioHint,
    AppStringsFr.bioHint,
  );
  String get bioMinLength => _getString(
    AppStrings.bioMinLength,
    AppStringsEn.bioMinLength,
    AppStringsFr.bioMinLength,
  );
  String get yearsOfExperience => _getString(
    AppStrings.yearsOfExperience,
    AppStringsEn.yearsOfExperience,
    AppStringsFr.yearsOfExperience,
  );
  String get selectSpecialties => _getString(
    AppStrings.selectSpecialties,
    AppStringsEn.selectSpecialties,
    AppStringsFr.selectSpecialties,
  );
  String get selectLanguages => _getString(
    AppStrings.selectLanguages,
    AppStringsEn.selectLanguages,
    AppStringsFr.selectLanguages,
  );
  String get addQualification => _getString(
    AppStrings.addQualification,
    AppStringsEn.addQualification,
    AppStringsFr.addQualification,
  );
  // Note: qualifications getter already defined earlier
  String get selectSessionTypes => _getString(
    AppStrings.selectSessionTypes,
    AppStringsEn.selectSessionTypes,
    AppStringsFr.selectSessionTypes,
  );
  String get sessionPricing => _getString(
    AppStrings.sessionPricing,
    AppStringsEn.sessionPricing,
    AppStringsFr.sessionPricing,
  );
  String get pricePerSession => _getString(
    AppStrings.pricePerSession,
    AppStringsEn.pricePerSession,
    AppStringsFr.pricePerSession,
  );
  String get currencyLabel => _getString(
    AppStrings.currency,
    AppStringsEn.currency,
    AppStringsFr.currency,
  );
  String get uploadLicense => _getString(
    AppStrings.uploadLicense,
    AppStringsEn.uploadLicense,
    AppStringsFr.uploadLicense,
  );
  String get licenseOptional => _getString(
    AppStrings.licenseOptional,
    AppStringsEn.licenseOptional,
    AppStringsFr.licenseOptional,
  );
  String get submitRegistration => _getString(
    AppStrings.submitRegistration,
    AppStringsEn.submitRegistration,
    AppStringsFr.submitRegistration,
  );
  String get registrationSubmitted => _getString(
    AppStrings.registrationSubmitted,
    AppStringsEn.registrationSubmitted,
    AppStringsFr.registrationSubmitted,
  );

  // Therapist Portal - Approval Status
  String get awaitingApproval => _getString(
    AppStrings.awaitingApproval,
    AppStringsEn.awaitingApproval,
    AppStringsFr.awaitingApproval,
  );
  String get pendingApprovalDesc => _getString(
    AppStrings.pendingApprovalDesc,
    AppStringsEn.pendingApprovalDesc,
    AppStringsFr.pendingApprovalDesc,
  );
  String get estimatedReviewTime => _getString(
    AppStrings.estimatedReviewTime,
    AppStringsEn.estimatedReviewTime,
    AppStringsFr.estimatedReviewTime,
  );
  String get notifyWhenReviewed => _getString(
    AppStrings.notifyWhenReviewed,
    AppStringsEn.notifyWhenReviewed,
    AppStringsFr.notifyWhenReviewed,
  );
  String get checkStatus => _getString(
    AppStrings.checkStatus,
    AppStringsEn.checkStatus,
    AppStringsFr.checkStatus,
  );
  String get returnToApp => _getString(
    AppStrings.returnToApp,
    AppStringsEn.returnToApp,
    AppStringsFr.returnToApp,
  );
  String get registrationRejected => _getString(
    AppStrings.registrationRejected,
    AppStringsEn.registrationRejected,
    AppStringsFr.registrationRejected,
  );
  String get rejectionDesc => _getString(
    AppStrings.rejectionDesc,
    AppStringsEn.rejectionDesc,
    AppStringsFr.rejectionDesc,
  );
  String get contactSupportForDetails => _getString(
    AppStrings.contactSupportForDetails,
    AppStringsEn.contactSupportForDetails,
    AppStringsFr.contactSupportForDetails,
  );
  // Note: contactSupport getter already defined earlier

  // Therapist Portal - Dashboard
  String get therapistDashboard => _getString(
    AppStrings.therapistDashboard,
    AppStringsEn.therapistDashboard,
    AppStringsFr.therapistDashboard,
  );
  // Note: online getter already defined earlier
  String get offline => _getString(
    AppStrings.offline,
    AppStringsEn.offline,
    AppStringsFr.offline,
  );
  String get todaysSessions => _getString(
    AppStrings.todaysSessions,
    AppStringsEn.todaysSessions,
    AppStringsFr.todaysSessions,
  );
  String get pendingRequests => _getString(
    AppStrings.pendingRequests,
    AppStringsEn.pendingRequests,
    AppStringsFr.pendingRequests,
  );
  // Note: completed getter already defined earlier
  String get todaysSchedule => _getString(
    AppStrings.todaysSchedule,
    AppStringsEn.todaysSchedule,
    AppStringsFr.todaysSchedule,
  );
  String get noSessionsToday => _getString(
    AppStrings.noSessionsToday,
    AppStringsEn.noSessionsToday,
    AppStringsFr.noSessionsToday,
  );
  // Note: quickActions getter already defined earlier
  String get availability => _getString(
    AppStrings.availability,
    AppStringsEn.availability,
    AppStringsFr.availability,
  );
  String get allBookings => _getString(
    AppStrings.allBookings,
    AppStringsEn.allBookings,
    AppStringsFr.allBookings,
  );
  String get manageAvailability => _getString(
    AppStrings.manageAvailability,
    AppStringsEn.manageAvailability,
    AppStringsFr.manageAvailability,
  );
  String get viewAll => _getString(
    AppStrings.viewAll,
    AppStringsEn.viewAll,
    AppStringsFr.viewAll,
  );
  String get autoGenerate => _getString(
    AppStrings.autoGenerate,
    AppStringsEn.autoGenerate,
    AppStringsFr.autoGenerate,
  );
  String get autoGenerateDesc => _getString(
    AppStrings.autoGenerateDesc,
    AppStringsEn.autoGenerateDesc,
    AppStringsFr.autoGenerateDesc,
  );
  String get numberOfWeeks => _getString(
    AppStrings.numberOfWeeks,
    AppStringsEn.numberOfWeeks,
    AppStringsFr.numberOfWeeks,
  );
  String get weeks =>
      _getString(AppStrings.weeks, AppStringsEn.weeks, AppStringsFr.weeks);
  String get generate => _getString(
    AppStrings.generate,
    AppStringsEn.generate,
    AppStringsFr.generate,
  );
  String get generated => _getString(
    AppStrings.generated,
    AppStringsEn.generated,
    AppStringsFr.generated,
  );
  String get slots =>
      _getString(AppStrings.slots, AppStringsEn.slots, AppStringsFr.slots);
  String get workingHours => _getString(
    AppStrings.workingHours,
    AppStringsEn.workingHours,
    AppStringsFr.workingHours,
  );
  String get timeSlots => _getString(
    AppStrings.timeSlots,
    AppStringsEn.timeSlots,
    AppStringsFr.timeSlots,
  );
  String get noSlotsForDay => _getString(
    AppStrings.noSlotsForDay,
    AppStringsEn.noSlotsForDay,
    AppStringsFr.noSlotsForDay,
  );
  String get setWorkingHours => _getString(
    AppStrings.setWorkingHours,
    AppStringsEn.setWorkingHours,
    AppStringsFr.setWorkingHours,
  );
  String get setWorkingHoursDesc => _getString(
    AppStrings.setWorkingHoursDesc,
    AppStringsEn.setWorkingHoursDesc,
    AppStringsFr.setWorkingHoursDesc,
  );
  String get setWorkingHoursFirst => _getString(
    AppStrings.setWorkingHoursFirst,
    AppStringsEn.setWorkingHoursFirst,
    AppStringsFr.setWorkingHoursFirst,
  );
  String get addTimeSlot => _getString(
    AppStrings.addTimeSlot,
    AppStringsEn.addTimeSlot,
    AppStringsFr.addTimeSlot,
  );
  String get startTime => _getString(
    AppStrings.startTime,
    AppStringsEn.startTime,
    AppStringsFr.startTime,
  );
  String get endTime => _getString(
    AppStrings.endTime,
    AppStringsEn.endTime,
    AppStringsFr.endTime,
  );
  String get add =>
      _getString(AppStrings.add, AppStringsEn.add, AppStringsFr.add);
  String get invalidTimeRange => _getString(
    AppStrings.invalidTimeRange,
    AppStringsEn.invalidTimeRange,
    AppStringsFr.invalidTimeRange,
  );
  String get slotAdded => _getString(
    AppStrings.slotAdded,
    AppStringsEn.slotAdded,
    AppStringsFr.slotAdded,
  );
  String get deleteSlot => _getString(
    AppStrings.deleteSlot,
    AppStringsEn.deleteSlot,
    AppStringsFr.deleteSlot,
  );
  String get deleteSlotConfirm => _getString(
    AppStrings.deleteSlotConfirm,
    AppStringsEn.deleteSlotConfirm,
    AppStringsFr.deleteSlotConfirm,
  );
  String get slotDeleted => _getString(
    AppStrings.slotDeleted,
    AppStringsEn.slotDeleted,
    AppStringsFr.slotDeleted,
  );
  String get available => _getString(
    AppStrings.available,
    AppStringsEn.available,
    AppStringsFr.available,
  );
  String get past =>
      _getString(AppStrings.past, AppStringsEn.past, AppStringsFr.past);
  String get workingHoursSaved => _getString(
    AppStrings.workingHoursSaved,
    AppStringsEn.workingHoursSaved,
    AppStringsFr.workingHoursSaved,
  );
  String get clearDay => _getString(
    AppStrings.clearDay,
    AppStringsEn.clearDay,
    AppStringsFr.clearDay,
  );
  String get dayClear => _getString(
    AppStrings.dayClear,
    AppStringsEn.dayClear,
    AppStringsFr.dayClear,
  );

  // Therapist Portal - Bookings
  String get bookings => _getString(
    AppStrings.bookings,
    AppStringsEn.bookings,
    AppStringsFr.bookings,
  );
  String get dashboard => _getString(
    AppStrings.dashboard,
    AppStringsEn.dashboard,
    AppStringsFr.dashboard,
  );
  String get acceptBooking => _getString(
    AppStrings.acceptBooking,
    AppStringsEn.acceptBooking,
    AppStringsFr.acceptBooking,
  );
  String get rejectBooking => _getString(
    AppStrings.rejectBooking,
    AppStringsEn.rejectBooking,
    AppStringsFr.rejectBooking,
  );
  String get rejectBookingConfirm => _getString(
    AppStrings.rejectBookingConfirm,
    AppStringsEn.rejectBookingConfirm,
    AppStringsFr.rejectBookingConfirm,
  );
  // Note: reason getter already defined earlier
  String get optionalReason => _getString(
    AppStrings.optionalReason,
    AppStringsEn.optionalReason,
    AppStringsFr.optionalReason,
  );
  // Note: reject getter already defined earlier
  String get completeSession => _getString(
    AppStrings.completeSession,
    AppStringsEn.completeSession,
    AppStringsFr.completeSession,
  );
  String get markNoShow => _getString(
    AppStrings.markNoShow,
    AppStringsEn.markNoShow,
    AppStringsFr.markNoShow,
  );
  String get sessionNotes => _getString(
    AppStrings.sessionNotes,
    AppStringsEn.sessionNotes,
    AppStringsFr.sessionNotes,
  );
  String get clientInfo => _getString(
    AppStrings.clientInfo,
    AppStringsEn.clientInfo,
    AppStringsFr.clientInfo,
  );
  String get bookingDetails => _getString(
    AppStrings.bookingDetails,
    AppStringsEn.bookingDetails,
    AppStringsFr.bookingDetails,
  );
  String get bookingNotFound => _getString(
    AppStrings.bookingNotFound,
    AppStringsEn.bookingNotFound,
    AppStringsFr.bookingNotFound,
  );
  String get bookingAccepted => _getString(
    AppStrings.bookingAccepted,
    AppStringsEn.bookingAccepted,
    AppStringsFr.bookingAccepted,
  );
  String get bookingRejected => _getString(
    AppStrings.bookingRejected,
    AppStringsEn.bookingRejected,
    AppStringsFr.bookingRejected,
  );
  String get sessionCompleted => _getString(
    AppStrings.sessionCompleted,
    AppStringsEn.sessionCompleted,
    AppStringsFr.sessionCompleted,
  );
  String get noPendingBookings => _getString(
    AppStrings.noPendingBookings,
    AppStringsEn.noPendingBookings,
    AppStringsFr.noPendingBookings,
  );
  String get noConfirmedBookings => _getString(
    AppStrings.noConfirmedBookings,
    AppStringsEn.noConfirmedBookings,
    AppStringsFr.noConfirmedBookings,
  );
  String get noCompletedBookings => _getString(
    AppStrings.noCompletedBookings,
    AppStringsEn.noCompletedBookings,
    AppStringsFr.noCompletedBookings,
  );
  String get noCancelledBookings => _getString(
    AppStrings.noCancelledBookings,
    AppStringsEn.noCancelledBookings,
    AppStringsFr.noCancelledBookings,
  );
  String get noBookingsYet => _getString(
    AppStrings.noBookingsYet,
    AppStringsEn.noBookingsYet,
    AppStringsFr.noBookingsYet,
  );
  String get enterCancellationReason => _getString(
    AppStrings.enterCancellationReason,
    AppStringsEn.enterCancellationReason,
    AppStringsFr.enterCancellationReason,
  );
  String get pleaseEnterReason => _getString(
    AppStrings.pleaseEnterReason,
    AppStringsEn.pleaseEnterReason,
    AppStringsFr.pleaseEnterReason,
  );
  String get bookingCancelled => _getString(
    AppStrings.bookingCancelled,
    AppStringsEn.bookingCancelled,
    AppStringsFr.bookingCancelled,
  );
  String get completeSessionConfirm => _getString(
    AppStrings.completeSessionConfirm,
    AppStringsEn.completeSessionConfirm,
    AppStringsFr.completeSessionConfirm,
  );
  String get markNoShowConfirm => _getString(
    AppStrings.markNoShowConfirm,
    AppStringsEn.markNoShowConfirm,
    AppStringsFr.markNoShowConfirm,
  );
  String get markedAsNoShow => _getString(
    AppStrings.markedAsNoShow,
    AppStringsEn.markedAsNoShow,
    AppStringsFr.markedAsNoShow,
  );
  String get notesSaved => _getString(
    AppStrings.notesSaved,
    AppStringsEn.notesSaved,
    AppStringsFr.notesSaved,
  );
  String get saveNotes => _getString(
    AppStrings.saveNotes,
    AppStringsEn.saveNotes,
    AppStringsFr.saveNotes,
  );
  String get addSessionNotes => _getString(
    AppStrings.addSessionNotes,
    AppStringsEn.addSessionNotes,
    AppStringsFr.addSessionNotes,
  );
  String get videoSession => _getString(
    AppStrings.videoSession,
    AppStringsEn.videoSession,
    AppStringsFr.videoSession,
  );
  String get audioSession => _getString(
    AppStrings.audioSession,
    AppStringsEn.audioSession,
    AppStringsFr.audioSession,
  );
  String get chatSession => _getString(
    AppStrings.chatSession,
    AppStringsEn.chatSession,
    AppStringsFr.chatSession,
  );
  String get inPersonSession => _getString(
    AppStrings.inPersonSession,
    AppStringsEn.inPersonSession,
    AppStringsFr.inPersonSession,
  );
  String get duration => _getString(
    AppStrings.duration,
    AppStringsEn.duration,
    AppStringsFr.duration,
  );
  String get minutes => _getString(
    AppStrings.minutes,
    AppStringsEn.minutes,
    AppStringsFr.minutes,
  );
  String get goBack =>
      _getString(AppStrings.goBack, AppStringsEn.goBack, AppStringsFr.goBack);
  String get cancellationReason => _getString(
    AppStrings.cancellationReason,
    AppStringsEn.cancellationReason,
    AppStringsFr.cancellationReason,
  );
  String get rejectionReason => _getString(
    AppStrings.rejectionReason,
    AppStringsEn.rejectionReason,
    AppStringsFr.rejectionReason,
  );
  String get noShow =>
      _getString(AppStrings.noShow, AppStringsEn.noShow, AppStringsFr.noShow);
  String get awaitingPayment => _getString(
    AppStrings.awaitingPayment,
    AppStringsEn.awaitingPayment,
    AppStringsFr.awaitingPayment,
  );
  String get booked =>
      _getString(AppStrings.booked, AppStringsEn.booked, AppStringsFr.booked);
  String get accept =>
      _getString(AppStrings.accept, AppStringsEn.accept, AppStringsFr.accept);
  String get decline => _getString(
    AppStrings.decline,
    AppStringsEn.decline,
    AppStringsFr.decline,
  );
  String get callLabel => _getString(
    AppStrings.callLabel,
    AppStringsEn.callLabel,
    AppStringsFr.callLabel,
  );
  String get complete => _getString(
    AppStrings.complete,
    AppStringsEn.complete,
    AppStringsFr.complete,
  );
  String get audio =>
      _getString(AppStrings.audio, AppStringsEn.audio, AppStringsFr.audio);
  String get inPerson => _getString(
    AppStrings.inPerson,
    AppStringsEn.inPerson,
    AppStringsFr.inPerson,
  );
  String get last4WeeksTrend => _getString(
    AppStrings.last4WeeksTrend,
    AppStringsEn.last4WeeksTrend,
    AppStringsFr.last4WeeksTrend,
  );
  String get sessionDetails => _getString(
    AppStrings.sessionDetails,
    AppStringsEn.sessionDetails,
    AppStringsFr.sessionDetails,
  );

  // Therapist Portal Additional Getters
  String get tellUsAboutYourself => _getString(
    AppStrings.tellUsAboutYourself,
    AppStringsEn.tellUsAboutYourself,
    AppStringsFr.tellUsAboutYourself,
  );
  String get pleaseEnterName => _getString(
    AppStrings.pleaseEnterName,
    AppStringsEn.pleaseEnterName,
    AppStringsFr.pleaseEnterName,
  );
  String get egClinicalPsychologist => _getString(
    AppStrings.egClinicalPsychologist,
    AppStringsEn.egClinicalPsychologist,
    AppStringsFr.egClinicalPsychologist,
  );
  String get pleaseEnterTitle => _getString(
    AppStrings.pleaseEnterTitle,
    AppStringsEn.pleaseEnterTitle,
    AppStringsFr.pleaseEnterTitle,
  );
  String get bio =>
      _getString(AppStrings.bio, AppStringsEn.bio, AppStringsFr.bio);
  String get describeProfessionalBackground => _getString(
    AppStrings.describeProfessionalBackground,
    AppStringsEn.describeProfessionalBackground,
    AppStringsFr.describeProfessionalBackground,
  );
  String get optional => _getString(
    AppStrings.optional,
    AppStringsEn.optional,
    AppStringsFr.optional,
  );
  String get shareExpertise => _getString(
    AppStrings.shareExpertise,
    AppStringsEn.shareExpertise,
    AppStringsFr.shareExpertise,
  );
  String get sessionInformation => _getString(
    AppStrings.sessionInformation,
    AppStringsEn.sessionInformation,
    AppStringsFr.sessionInformation,
  );
  String get defineSessionDetails => _getString(
    AppStrings.defineSessionDetails,
    AppStringsEn.defineSessionDetails,
    AppStringsFr.defineSessionDetails,
  );
  String get sessionPrice => _getString(
    AppStrings.sessionPrice,
    AppStringsEn.sessionPrice,
    AppStringsFr.sessionPrice,
  );
  String get pleaseEnterPrice => _getString(
    AppStrings.pleaseEnterPrice,
    AppStringsEn.pleaseEnterPrice,
    AppStringsFr.pleaseEnterPrice,
  );
  String get invalidPrice => _getString(
    AppStrings.invalidPrice,
    AppStringsEn.invalidPrice,
    AppStringsFr.invalidPrice,
  );
  String get registrationReviewNotice => _getString(
    AppStrings.registrationReviewNotice,
    AppStringsEn.registrationReviewNotice,
    AppStringsFr.registrationReviewNotice,
  );
  String get registrationStatus => _getString(
    AppStrings.registrationStatus,
    AppStringsEn.registrationStatus,
    AppStringsFr.registrationStatus,
  );
  String get registrationPending => _getString(
    AppStrings.registrationPending,
    AppStringsEn.registrationPending,
    AppStringsFr.registrationPending,
  );
  String get registrationApproved => _getString(
    AppStrings.registrationApproved,
    AppStringsEn.registrationApproved,
    AppStringsFr.registrationApproved,
  );
  String get registrationPendingDesc => _getString(
    AppStrings.registrationPendingDesc,
    AppStringsEn.registrationPendingDesc,
    AppStringsFr.registrationPendingDesc,
  );
  String get registrationApprovedDesc => _getString(
    AppStrings.registrationApprovedDesc,
    AppStringsEn.registrationApprovedDesc,
    AppStringsFr.registrationApprovedDesc,
  );
  String get registrationRejectedDesc => _getString(
    AppStrings.registrationRejectedDesc,
    AppStringsEn.registrationRejectedDesc,
    AppStringsFr.registrationRejectedDesc,
  );
  String get goToDashboard => _getString(
    AppStrings.goToDashboard,
    AppStringsEn.goToDashboard,
    AppStringsFr.goToDashboard,
  );
  String get previous => _getString(
    AppStrings.previous,
    AppStringsEn.previous,
    AppStringsFr.previous,
  );
  String get sessionInPerson => _getString(
    AppStrings.sessionInPerson,
    AppStringsEn.sessionInPerson,
    AppStringsFr.sessionInPerson,
  );
  String get tapToChangePhoto => _getString(
    AppStrings.tapToChangePhoto,
    AppStringsEn.tapToChangePhoto,
    AppStringsFr.tapToChangePhoto,
  );
  String get qualificationHint => _getString(
    AppStrings.qualificationHint,
    AppStringsEn.qualificationHint,
    AppStringsFr.qualificationHint,
  );
  String get priceRequired => _getString(
    AppStrings.priceRequired,
    AppStringsEn.priceRequired,
    AppStringsFr.priceRequired,
  );
  String get experienceRequired => _getString(
    AppStrings.experienceRequired,
    AppStringsEn.experienceRequired,
    AppStringsFr.experienceRequired,
  );
  String get invalidExperience => _getString(
    AppStrings.invalidExperience,
    AppStringsEn.invalidExperience,
    AppStringsFr.invalidExperience,
  );
  String get availableForBookings => _getString(
    AppStrings.availableForBookings,
    AppStringsEn.availableForBookings,
    AppStringsFr.availableForBookings,
  );
  String get profileNotFound => _getString(
    AppStrings.profileNotFound,
    AppStringsEn.profileNotFound,
    AppStringsFr.profileNotFound,
  );
  String get nameRequired => _getString(
    AppStrings.nameRequired,
    AppStringsEn.nameRequired,
    AppStringsFr.nameRequired,
  );
  String get pricing => sessionPricing;
  String get experience => yearsOfExperience;
  String get confirmed => _getString(
    AppStrings.confirmed,
    AppStringsEn.confirmed,
    AppStringsFr.confirmed,
  );
  String get cancelled => _getString(
    AppStrings.cancelled,
    AppStringsEn.cancelled,
    AppStringsFr.cancelled,
  );
  String get youAreOnline => _getString(
    AppStrings.youAreOnline,
    AppStringsEn.youAreOnline,
    AppStringsFr.youAreOnline,
  );
  String get youAreOffline => _getString(
    AppStrings.youAreOffline,
    AppStringsEn.youAreOffline,
    AppStringsFr.youAreOffline,
  );
  String get sessionType => _getString(
    AppStrings.sessionType,
    AppStringsEn.sessionType,
    AppStringsFr.sessionType,
  );

  // Engagement & Insights
  String get moodTrend => _getString(
    AppStrings.moodTrend,
    AppStringsEn.moodTrend,
    AppStringsFr.moodTrend,
  );
  String get streak =>
      _getString(AppStrings.streak, AppStringsEn.streak, AppStringsFr.streak);
  String get day =>
      _getString(AppStrings.day, AppStringsEn.day, AppStringsFr.day);
  String get days =>
      _getString(AppStrings.days, AppStringsEn.days, AppStringsFr.days);
  String get challenges => _getString(
    AppStrings.challenges,
    AppStringsEn.challenges,
    AppStringsFr.challenges,
  );
  String get dailyChallenge => _getString(
    AppStrings.dailyChallenge,
    AppStringsEn.dailyChallenge,
    AppStringsFr.dailyChallenge,
  );
  String get startChallenge => _getString(
    AppStrings.startChallenge,
    AppStringsEn.startChallenge,
    AppStringsFr.startChallenge,
  );
  String get skipChallenge => _getString(
    AppStrings.skipChallenge,
    AppStringsEn.skipChallenge,
    AppStringsFr.skipChallenge,
  );
  String get challengeCompleted => _getString(
    AppStrings.challengeCompleted,
    AppStringsEn.challengeCompleted,
    AppStringsFr.challengeCompleted,
  );

  /// Returns a message for login prompt with feature name
  String loginToAccessFeature(String feature) {
    return '$loginToAccess $feature';
  }

  String get activeNow => _getString(
    AppStrings.activeNow,
    AppStringsEn.activeNow,
    AppStringsFr.activeNow,
  );
  String get away =>
      _getString(AppStrings.away, AppStringsEn.away, AppStringsFr.away);
  String get tapToChangeStatus => _getString(
    AppStrings.tapToChangeStatus,
    AppStringsEn.tapToChangeStatus,
    AppStringsFr.tapToChangeStatus,
  );

  String get revenue => _getString(
    AppStrings.revenue,
    AppStringsEn.revenue,
    AppStringsFr.revenue,
  );
  String get sessionsThisMonth => _getString(
    AppStrings.sessionsThisMonth,
    AppStringsEn.sessionsThisMonth,
    AppStringsFr.sessionsThisMonth,
  );
  String get activeClients => _getString(
    AppStrings.activeClients,
    AppStringsEn.activeClients,
    AppStringsFr.activeClients,
  );
  String get rating =>
      _getString(AppStrings.rating, AppStringsEn.rating, AppStringsFr.rating);

  String get urgentAlerts => _getString(
    AppStrings.urgentAlerts,
    AppStringsEn.urgentAlerts,
    AppStringsFr.urgentAlerts,
  );
  String get waitingQueue => _getString(
    AppStrings.waitingQueue,
    AppStringsEn.waitingQueue,
    AppStringsFr.waitingQueue,
  );
  String get reply =>
      _getString(AppStrings.reply, AppStringsEn.reply, AppStringsFr.reply);
  String get start =>
      _getString(AppStrings.start, AppStringsEn.start, AppStringsFr.start);

  String get avgRating => _getString(
    AppStrings.avgRating,
    AppStringsEn.avgRating,
    AppStringsFr.avgRating,
  );
  String get responseTime => _getString(
    AppStrings.responseTime,
    AppStringsEn.responseTime,
    AppStringsFr.responseTime,
  );
  String get completion => _getString(
    AppStrings.completion,
    AppStringsEn.completion,
    AppStringsFr.completion,
  );
  String get rebooking => _getString(
    AppStrings.rebooking,
    AppStringsEn.rebooking,
    AppStringsFr.rebooking,
  );

  String get hourAbbr => _getString(
    AppStrings.hourAbbr,
    AppStringsEn.hourAbbr,
    AppStringsFr.hourAbbr,
  );
  String get minuteAbbr => _getString(
    AppStrings.minuteAbbr,
    AppStringsEn.minuteAbbr,
    AppStringsFr.minuteAbbr,
  );
  String get yearAbbr => _getString(
    AppStrings.yearAbbr,
    AppStringsEn.yearAbbr,
    AppStringsFr.yearAbbr,
  );
  String get experienceHint => _getString(
    AppStrings.experienceHint,
    AppStringsEn.experienceHint,
    AppStringsFr.experienceHint,
  );

  String get expertiseSelect => _getString(
    AppStrings.expertiseSelect,
    AppStringsEn.expertiseSelect,
    AppStringsFr.expertiseSelect,
  );
  String get noQualifications => _getString(
    AppStrings.noQualifications,
    AppStringsEn.noQualifications,
    AppStringsFr.noQualifications,
  );

  // Intake Sheet & New Strings
  String get intakeTitle => _getString(
    AppStrings.intakeTitle,
    AppStringsEn.intakeTitle,
    AppStringsFr.intakeTitle,
  );
  String get intakeSubtitle => _getString(
    AppStrings.intakeSubtitle,
    AppStringsEn.intakeSubtitle,
    AppStringsFr.intakeSubtitle,
  );
  String get intakeNoteLabel => _getString(
    AppStrings.intakeNoteLabel,
    AppStringsEn.intakeNoteLabel,
    AppStringsFr.intakeNoteLabel,
  );
  String get intakeNoteHint => _getString(
    AppStrings.intakeNoteHint,
    AppStringsEn.intakeNoteHint,
    AppStringsFr.intakeNoteHint,
  );
  String get notifyWhatsApp => _getString(
    AppStrings.notifyWhatsApp,
    AppStringsEn.notifyWhatsApp,
    AppStringsFr.notifyWhatsApp,
  );
  String get requestBankDataWhatsApp => _getString(
    AppStrings.requestBankDataWhatsApp,
    AppStringsEn.requestBankDataWhatsApp,
    AppStringsFr.requestBankDataWhatsApp,
  );
  String get whatsappLaunchError => _getString(
    AppStrings.whatsappLaunchError,
    AppStringsEn.whatsappLaunchError,
    AppStringsFr.whatsappLaunchError,
  );
  String get switchProcessMessage => _getString(
    AppStrings.switchProcessMessage,
    AppStringsEn.switchProcessMessage,
    AppStringsFr.switchProcessMessage,
  );

  // Case-specific specialty mapping for intake
  String get issueAnxiety => specialtyAnxiety;
  String get issueDepression => specialtyDepression;
  String get issueStress => specialtyStress;
  String get issueRelationships => specialtyRelationships;
  String get issueTrauma => specialtyTrauma;
  String get issueGrief => specialtyGrief;
  String get issueSelfEsteem => specialtySelfEsteem;

  String get issueFamily => _getString(
    AppStrings.specialtyFamily,
    AppStringsEn.specialtyFamily,
    AppStringsFr.specialtyFamily,
  );
  String get issueWork => _getString(
    AppStrings.specialtyWork,
    AppStringsEn.specialtyWork,
    AppStringsFr.specialtyWork,
  );
  String get issueSleep => _getString(
    AppStrings.specialtySleep,
    AppStringsEn.specialtySleep,
    AppStringsFr.specialtySleep,
  );

  // Short Months
  String get jan =>
      _getString(AppStrings.jan, AppStringsEn.jan, AppStringsFr.jan);
  String get feb =>
      _getString(AppStrings.feb, AppStringsEn.feb, AppStringsFr.feb);
  String get mar =>
      _getString(AppStrings.mar, AppStringsEn.mar, AppStringsFr.mar);
  String get apr =>
      _getString(AppStrings.apr, AppStringsEn.apr, AppStringsFr.apr);
  String get mayShort => _getString(
    AppStrings.mayShort,
    AppStringsEn.mayShort,
    AppStringsFr.mayShort,
  );
  String get jun =>
      _getString(AppStrings.jun, AppStringsEn.jun, AppStringsFr.jun);
  String get jul =>
      _getString(AppStrings.jul, AppStringsEn.jul, AppStringsFr.jul);
  String get aug =>
      _getString(AppStrings.aug, AppStringsEn.aug, AppStringsFr.aug);
  String get sep =>
      _getString(AppStrings.sep, AppStringsEn.sep, AppStringsFr.sep);
  String get oct =>
      _getString(AppStrings.oct, AppStringsEn.oct, AppStringsFr.oct);
  String get nov =>
      _getString(AppStrings.nov, AppStringsEn.nov, AppStringsFr.nov);
  String get dec =>
      _getString(AppStrings.dec, AppStringsEn.dec, AppStringsFr.dec);

  // Charts & Analytics
  String get sessionVolume => _getString(
    AppStrings.sessionVolume,
    AppStringsEn.sessionVolume,
    AppStringsFr.sessionVolume,
  );
  String get earnings => _getString(
    AppStrings.earnings,
    AppStringsEn.earnings,
    AppStringsFr.earnings,
  );
  String get patientDistribution => _getString(
    AppStrings.patientDistribution,
    AppStringsEn.patientDistribution,
    AppStringsFr.patientDistribution,
  );
  String get noSessionData => _getString(
    AppStrings.noSessionData,
    AppStringsEn.noSessionData,
    AppStringsFr.noSessionData,
  );
  String get noEarningsData => _getString(
    AppStrings.noEarningsData,
    AppStringsEn.noEarningsData,
    AppStringsFr.noEarningsData,
  );
  String get noDistributionData => _getString(
    AppStrings.noDistributionData,
    AppStringsEn.noDistributionData,
    AppStringsFr.noDistributionData,
  );
  String get noClinicianData => _getString(
    AppStrings.noClinicianData,
    AppStringsEn.noClinicianData,
    AppStringsFr.noClinicianData,
  );
  String get current => _getString(
    AppStrings.current,
    AppStringsEn.current,
    AppStringsFr.current,
  );
  String get previousPeriod => _getString(
    AppStrings.previousPeriod,
    AppStringsEn.previousPeriod,
    AppStringsFr.previousPeriod,
  );
  String get quarter => _getString(
    AppStrings.quarter,
    AppStringsEn.quarter,
    AppStringsFr.quarter,
  );
  String get yearPeriod => _getString(
    AppStrings.yearPeriod,
    AppStringsEn.yearPeriod,
    AppStringsFr.yearPeriod,
  );
  String get custom =>
      _getString(AppStrings.custom, AppStringsEn.custom, AppStringsFr.custom);
  String get sessionTypeDistribution => _getString(
    AppStrings.sessionTypeDistribution,
    AppStringsEn.sessionTypeDistribution,
    AppStringsFr.sessionTypeDistribution,
  );
  String get ageGroup => _getString(
    AppStrings.ageGroup,
    AppStringsEn.ageGroup,
    AppStringsFr.ageGroup,
  );
  String get presentingIssue => _getString(
    AppStrings.presentingIssue,
    AppStringsEn.presentingIssue,
    AppStringsFr.presentingIssue,
  );
  String get session => _getString(
    AppStrings.session,
    AppStringsEn.session,
    AppStringsFr.session,
  );
  String get sessionsCountLabel => _getString(
    AppStrings.sessionsCountLabel,
    AppStringsEn.sessionsCountLabel,
    AppStringsFr.sessionsCountLabel,
  );
  String get individual => _getString(
    AppStrings.individual,
    AppStringsEn.individual,
    AppStringsFr.individual,
  );
  String get couples => _getString(
    AppStrings.couples,
    AppStringsEn.couples,
    AppStringsFr.couples,
  );
  String get family =>
      _getString(AppStrings.family, AppStringsEn.family, AppStringsFr.family);
  String get group =>
      _getString(AppStrings.group, AppStringsEn.group, AppStringsFr.group);

  // Admin Dashboard
  String get clinicOverview => _getString(
    AppStrings.clinicOverview,
    AppStringsEn.clinicOverview,
    AppStringsFr.clinicOverview,
  );
  String get clinicOverviewSubtitle => _getString(
    AppStrings.clinicOverviewSubtitle,
    AppStringsEn.clinicOverviewSubtitle,
    AppStringsFr.clinicOverviewSubtitle,
  );
  String get recentActivity => _getString(
    AppStrings.recentActivity,
    AppStringsEn.recentActivity,
    AppStringsFr.recentActivity,
  );
  String get errorLoadingStats => _getString(
    AppStrings.errorLoadingStats,
    AppStringsEn.errorLoadingStats,
    AppStringsFr.errorLoadingStats,
  );
  String get activeUsers => _getString(
    AppStrings.activeUsers,
    AppStringsEn.activeUsers,
    AppStringsFr.activeUsers,
  );
  String get criticalFlags => _getString(
    AppStrings.criticalFlags,
    AppStringsEn.criticalFlags,
    AppStringsFr.criticalFlags,
  );
  String get needsAttention => _getString(
    AppStrings.needsAttention,
    AppStringsEn.needsAttention,
    AppStringsFr.needsAttention,
  );
  String get allClear => _getString(
    AppStrings.allClear,
    AppStringsEn.allClear,
    AppStringsFr.allClear,
  );
  String get failedToLoadActivity => _getString(
    AppStrings.failedToLoadActivity,
    AppStringsEn.failedToLoadActivity,
    AppStringsFr.failedToLoadActivity,
  );
  String get noRecentActivity => _getString(
    AppStrings.noRecentActivity,
    AppStringsEn.noRecentActivity,
    AppStringsFr.noRecentActivity,
  );
  String get riskAlerts => _getString(
    AppStrings.riskAlerts,
    AppStringsEn.riskAlerts,
    AppStringsFr.riskAlerts,
  );
  String get failedToLoadAlerts => _getString(
    AppStrings.failedToLoadAlerts,
    AppStringsEn.failedToLoadAlerts,
    AppStringsFr.failedToLoadAlerts,
  );
  String get noHighRiskAlerts => _getString(
    AppStrings.noHighRiskAlerts,
    AppStringsEn.noHighRiskAlerts,
    AppStringsFr.noHighRiskAlerts,
  );
  String get riskLow => _getString(
    AppStrings.riskLow,
    AppStringsEn.riskLow,
    AppStringsFr.riskLow,
  );
  String get riskModerate => _getString(
    AppStrings.riskModerate,
    AppStringsEn.riskModerate,
    AppStringsFr.riskModerate,
  );
  String get riskHigh => _getString(
    AppStrings.riskHigh,
    AppStringsEn.riskHigh,
    AppStringsFr.riskHigh,
  );
  String get riskCritical => _getString(
    AppStrings.riskCritical,
    AppStringsEn.riskCritical,
    AppStringsFr.riskCritical,
  );
  String get moodDecliningFor => _getString(
    AppStrings.moodDecliningFor,
    AppStringsEn.moodDecliningFor,
    AppStringsFr.moodDecliningFor,
  );
  String get weeklyAgenda => _getString(
    AppStrings.weeklyAgenda,
    AppStringsEn.weeklyAgenda,
    AppStringsFr.weeklyAgenda,
  );
  String get noAppointmentsThisWeek => _getString(
    AppStrings.noAppointmentsThisWeek,
    AppStringsEn.noAppointmentsThisWeek,
    AppStringsFr.noAppointmentsThisWeek,
  );
  String get newPatient => _getString(
    AppStrings.newPatient,
    AppStringsEn.newPatient,
    AppStringsFr.newPatient,
  );
  String get scheduleSession => _getString(
    AppStrings.scheduleSession,
    AppStringsEn.scheduleSession,
    AppStringsFr.scheduleSession,
  );
  String get addClinician => _getString(
    AppStrings.addClinician,
    AppStringsEn.addClinician,
    AppStringsFr.addClinician,
  );
  String get createInvoice => _getString(
    AppStrings.createInvoice,
    AppStringsEn.createInvoice,
    AppStringsFr.createInvoice,
  );
  String get markAllRead => _getString(
    AppStrings.markAllRead,
    AppStringsEn.markAllRead,
    AppStringsFr.markAllRead,
  );
  String get viewAllNotifications => _getString(
    AppStrings.viewAllNotifications,
    AppStringsEn.viewAllNotifications,
    AppStringsFr.viewAllNotifications,
  );
  String get aiAssistant => _getString(
    AppStrings.aiAssistant,
    AppStringsEn.aiAssistant,
    AppStringsFr.aiAssistant,
  );
  String get aiAssistantSubtitle => _getString(
    AppStrings.aiAssistantSubtitle,
    AppStringsEn.aiAssistantSubtitle,
    AppStringsFr.aiAssistantSubtitle,
  );
  String get analyzingData => _getString(
    AppStrings.analyzingData,
    AppStringsEn.analyzingData,
    AppStringsFr.analyzingData,
  );
  String get getAiInsights => _getString(
    AppStrings.getAiInsights,
    AppStringsEn.getAiInsights,
    AppStringsFr.getAiInsights,
  );
  String get summarizeOperations => _getString(
    AppStrings.summarizeOperations,
    AppStringsEn.summarizeOperations,
    AppStringsFr.summarizeOperations,
  );
  String get generateSummary => _getString(
    AppStrings.generateSummary,
    AppStringsEn.generateSummary,
    AppStringsFr.generateSummary,
  );
  String get askFollowUpQuestion => _getString(
    AppStrings.askFollowUpQuestion,
    AppStringsEn.askFollowUpQuestion,
    AppStringsFr.askFollowUpQuestion,
  );
  String get aiInsights => _getString(
    AppStrings.aiInsights,
    AppStringsEn.aiInsights,
    AppStringsFr.aiInsights,
  );
  String get aiNotConfigured => _getString(
    AppStrings.aiNotConfigured,
    AppStringsEn.aiNotConfigured,
    AppStringsFr.aiNotConfigured,
  );
  String get aiConfigureHint => _getString(
    AppStrings.aiConfigureHint,
    AppStringsEn.aiConfigureHint,
    AppStringsFr.aiConfigureHint,
  );

  String get newChat => _getString(
    AppStrings.newChat,
    AppStringsEn.newChat,
    AppStringsFr.newChat,
  );

  // Missing getters added for Booking Screen
  String get upcoming => _getString(
    AppStrings.upcoming,
    AppStringsEn.upcoming,
    AppStringsFr.upcoming,
  );

  String get tabHistory => _getString(
    AppStrings.tabHistory,
    AppStringsEn.history,
    AppStringsFr.history,
  );

  String get noSessionHistory => _getString(
    AppStrings.noSessionsDesc,
    AppStringsEn.noSessionsDesc,
    AppStringsFr.noSessionsDesc,
  );

  // Admin Sidebar & Navigation
  String get sidebarMain => _getString(
    AppStrings.sidebarMain,
    AppStringsEn.sidebarMain,
    AppStringsFr.sidebarMain,
  );

  String get sidebarCommunication => _getString(
    AppStrings.sidebarCommunication,
    AppStringsEn.sidebarCommunication,
    AppStringsFr.sidebarCommunication,
  );

  String get sidebarInsights => _getString(
    AppStrings.sidebarInsights,
    AppStringsEn.sidebarInsights,
    AppStringsFr.sidebarInsights,
  );

  String get sidebarSystem => _getString(
    AppStrings.sidebarSystem,
    AppStringsEn.sidebarSystem,
    AppStringsFr.sidebarSystem,
  );

  String get sidebarUsers => _getString(
    AppStrings.sidebarUsers,
    AppStringsEn.sidebarUsers,
    AppStringsFr.sidebarUsers,
  );

  String get sidebarClinicians => _getString(
    AppStrings.sidebarClinicians,
    AppStringsEn.sidebarClinicians,
    AppStringsFr.sidebarClinicians,
  );

  String get sidebarAppointments => _getString(
    AppStrings.sidebarAppointments,
    AppStringsEn.sidebarAppointments,
    AppStringsFr.sidebarAppointments,
  );

  String get sidebarSupportChat => _getString(
    AppStrings.sidebarSupportChat,
    AppStringsEn.sidebarSupportChat,
    AppStringsFr.sidebarSupportChat,
  );

  String get sidebarReports => _getString(
    AppStrings.sidebarReports,
    AppStringsEn.sidebarReports,
    AppStringsFr.sidebarReports,
  );

  String get sidebarBilling => _getString(
    AppStrings.sidebarBilling,
    AppStringsEn.sidebarBilling,
    AppStringsFr.sidebarBilling,
  );

  String get sidebarDataManagement => _getString(
    AppStrings.sidebarDataManagement,
    AppStringsEn.sidebarDataManagement,
    AppStringsFr.sidebarDataManagement,
  );

  // Admin Profile Menu
  String get administrator => _getString(
    AppStrings.administrator,
    AppStringsEn.administrator,
    AppStringsFr.administrator,
  );

  String get myProfile => _getString(
    AppStrings.myProfile,
    AppStringsEn.myProfile,
    AppStringsFr.myProfile,
  );

  String get helpAndSupport => _getString(
    AppStrings.helpAndSupport,
    AppStringsEn.helpAndSupport,
    AppStringsFr.helpAndSupport,
  );

  String get signOut => _getString(
    AppStrings.signOut,
    AppStringsEn.signOut,
    AppStringsFr.signOut,
  );

  // Admin Search
  String get searchUsersCliniciansDot => _getString(
    AppStrings.searchUsersCliniciansDot,
    AppStringsEn.searchUsersCliniciansDot,
    AppStringsFr.searchUsersCliniciansDot,
  );

  String get noResultsFound => _getString(
    AppStrings.noResultsFound,
    AppStringsEn.noResultsFound,
    AppStringsFr.noResultsFound,
  );

  String get labelPatient => _getString(
    AppStrings.labelPatient,
    AppStringsEn.labelPatient,
    AppStringsFr.labelPatient,
  );

  String get labelClinician => _getString(
    AppStrings.labelClinician,
    AppStringsEn.labelClinician,
    AppStringsFr.labelClinician,
  );

  String get labelAppointment => _getString(
    AppStrings.labelAppointment,
    AppStringsEn.labelAppointment,
    AppStringsFr.labelAppointment,
  );

  // Admin Settings
  String get systemSettings => _getString(
    AppStrings.systemSettings,
    AppStringsEn.systemSettings,
    AppStringsFr.systemSettings,
  );

  String get manageGlobalConfig => _getString(
    AppStrings.manageGlobalConfig,
    AppStringsEn.manageGlobalConfig,
    AppStringsFr.manageGlobalConfig,
  );

  String get systemStatus => _getString(
    AppStrings.systemStatus,
    AppStringsEn.systemStatus,
    AppStringsFr.systemStatus,
  );

  String get appConfiguration => _getString(
    AppStrings.appConfiguration,
    AppStringsEn.appConfiguration,
    AppStringsFr.appConfiguration,
  );

  String get maintenanceMode => _getString(
    AppStrings.maintenanceMode,
    AppStringsEn.maintenanceMode,
    AppStringsFr.maintenanceMode,
  );

  String get maintenanceModeDesc => _getString(
    AppStrings.maintenanceModeDesc,
    AppStringsEn.maintenanceModeDesc,
    AppStringsFr.maintenanceModeDesc,
  );

  String get therapistApplications => _getString(
    AppStrings.therapistApplications,
    AppStringsEn.therapistApplications,
    AppStringsFr.therapistApplications,
  );

  String get therapistApplicationsDesc => _getString(
    AppStrings.therapistApplicationsDesc,
    AppStringsEn.therapistApplicationsDesc,
    AppStringsFr.therapistApplicationsDesc,
  );

  String get minimumAppVersion => _getString(
    AppStrings.minimumAppVersion,
    AppStringsEn.minimumAppVersion,
    AppStringsFr.minimumAppVersion,
  );

  String get minimumAppVersionDesc => _getString(
    AppStrings.minimumAppVersionDesc,
    AppStringsEn.minimumAppVersionDesc,
    AppStringsFr.minimumAppVersionDesc,
  );

  String get supportEmailSetting => _getString(
    AppStrings.supportEmailSetting,
    AppStringsEn.supportEmailSetting,
    AppStringsFr.supportEmailSetting,
  );

  String get supportEmailDesc => _getString(
    AppStrings.supportEmailDesc,
    AppStringsEn.supportEmailDesc,
    AppStringsFr.supportEmailDesc,
  );

  String get editTitle => _getString(
    AppStrings.editTitle,
    AppStringsEn.editTitle,
    AppStringsFr.editTitle,
  );

  String get settingSavedSuccess => _getString(
    AppStrings.settingSavedSuccess,
    AppStringsEn.settingSavedSuccess,
    AppStringsFr.settingSavedSuccess,
  );

  String get errorSavingSetting => _getString(
    AppStrings.errorSavingSetting,
    AppStringsEn.errorSavingSetting,
    AppStringsFr.errorSavingSetting,
  );

  String get dailyQuotes => _getString(
    AppStrings.dailyQuotes,
    AppStringsEn.dailyQuotes,
    AppStringsFr.dailyQuotes,
  );

  String get analytics => _getString(
    AppStrings.analytics,
    AppStringsEn.analytics,
    AppStringsFr.analytics,
  );

  String get appSettings => _getString(
    AppStrings.appSettings,
    AppStringsEn.appSettings,
    AppStringsFr.appSettings,
  );

  String get content => _getString(
    AppStrings.content,
    AppStringsEn.content,
    AppStringsFr.content,
  );

  // More Screen / Shared
  String get selfTests => _getString(
    AppStrings.selfTests,
    AppStringsEn.selfTests,
    AppStringsFr.selfTests,
  );

  String get services => _getString(
    AppStrings.services,
    AppStringsEn.services,
    AppStringsFr.services,
  );

  String get blog =>
      _getString(AppStrings.blog, AppStringsEn.blog, AppStringsFr.blog);

  String get podcast => _getString(
    AppStrings.podcast,
    AppStringsEn.podcast,
    AppStringsFr.podcast,
  );

  String get exercises => _getString(
    AppStrings.exercises,
    AppStringsEn.exercises,
    AppStringsFr.exercises,
  );

  String get noContentYet => _getString(
    AppStrings.noContentYet,
    AppStringsEn.noContentYet,
    AppStringsFr.noContentYet,
  );

  String get contentComingSoon => _getString(
    AppStrings.contentComingSoon,
    AppStringsEn.contentComingSoon,
    AppStringsFr.contentComingSoon,
  );

  String get listenNow => _getString(
    AppStrings.listenNow,
    AppStringsEn.listenNow,
    AppStringsFr.listenNow,
  );

  String get watchNow => _getString(
    AppStrings.watchNow,
    AppStringsEn.watchNow,
    AppStringsFr.watchNow,
  );

  String get startExercise => _getString(
    AppStrings.startExercise,
    AppStringsEn.startExercise,
    AppStringsFr.startExercise,
  );

  String get readMore => _getString(
    AppStrings.readMore,
    AppStringsEn.readMore,
    AppStringsFr.readMore,
  );

  String get questionN => _getString(
    AppStrings.questionN,
    AppStringsEn.questionN,
    AppStringsFr.questionN,
  );

  String get finishTest => _getString(
    AppStrings.finishTest,
    AppStringsEn.finishTest,
    AppStringsFr.finishTest,
  );

  String get testResult => _getString(
    AppStrings.testResult,
    AppStringsEn.testResult,
    AppStringsFr.testResult,
  );

  String get yourScore => _getString(
    AppStrings.yourScore,
    AppStringsEn.yourScore,
    AppStringsFr.yourScore,
  );

  String get interpretationLabel => _getString(
    AppStrings.interpretationLabel,
    AppStringsEn.interpretationLabel,
    AppStringsFr.interpretationLabel,
  );

  String get testDisclaimer => _getString(
    AppStrings.testDisclaimer,
    AppStringsEn.testDisclaimer,
    AppStringsFr.testDisclaimer,
  );

  String get subscriptionPackages => _getString(
    AppStrings.subscriptionPackages,
    AppStringsEn.subscriptionPackages,
    AppStringsFr.subscriptionPackages,
  );

  String get themeLabel => _getString(
    AppStrings.themeLabel,
    AppStringsEn.themeLabel,
    AppStringsFr.themeLabel,
  );

  // User Bookings
  String get scheduledSessionsAppearHere => _getString(
    AppStrings.scheduledSessionsAppearHere,
    AppStringsEn.scheduledSessionsAppearHere,
    AppStringsFr.scheduledSessionsAppearHere,
  );

  String get pastSessionsArchivedHere => _getString(
    AppStrings.pastSessionsArchivedHere,
    AppStringsEn.pastSessionsArchivedHere,
    AppStringsFr.pastSessionsArchivedHere,
  );

  // ─── M5: Admin UX Strings ───────────────────────────────────────────

  String get adminUsers => _getString(
    AppStrings.adminUsers,
    AppStringsEn.adminUsers,
    AppStringsFr.adminUsers,
  );
  String get adminUsersOf => _getString(
    AppStrings.adminUsersOf,
    AppStringsEn.adminUsersOf,
    AppStringsFr.adminUsersOf,
  );
  String get adminUsersCount => _getString(
    AppStrings.adminUsersCount,
    AppStringsEn.adminUsersCount,
    AppStringsFr.adminUsersCount,
  );
  String get adminClinicians => _getString(
    AppStrings.adminClinicians,
    AppStringsEn.adminClinicians,
    AppStringsFr.adminClinicians,
  );
  String get adminAppointments => _getString(
    AppStrings.adminAppointments,
    AppStringsEn.adminAppointments,
    AppStringsFr.adminAppointments,
  );
  String get adminReports => _getString(
    AppStrings.adminReports,
    AppStringsEn.adminReports,
    AppStringsFr.adminReports,
  );
  String get adminReportsSubtitle => _getString(
    AppStrings.adminReportsSubtitle,
    AppStringsEn.adminReportsSubtitle,
    AppStringsFr.adminReportsSubtitle,
  );
  String get adminReportTemplates => _getString(
    AppStrings.adminReportTemplates,
    AppStringsEn.adminReportTemplates,
    AppStringsFr.adminReportTemplates,
  );
  String get adminCommunityModeration => _getString(
    AppStrings.adminCommunityModeration,
    AppStringsEn.adminCommunityModeration,
    AppStringsFr.adminCommunityModeration,
  );
  String get adminReviewModerate => _getString(
    AppStrings.adminReviewModerate,
    AppStringsEn.adminReviewModerate,
    AppStringsFr.adminReviewModerate,
  );
  String get adminDataManagement => _getString(
    AppStrings.adminDataManagement,
    AppStringsEn.adminDataManagement,
    AppStringsFr.adminDataManagement,
  );
  String get adminManageAppData => _getString(
    AppStrings.adminManageAppData,
    AppStringsEn.adminManageAppData,
    AppStringsFr.adminManageAppData,
  );
  String get adminFirestoreData => _getString(
    AppStrings.adminFirestoreData,
    AppStringsEn.adminFirestoreData,
    AppStringsFr.adminFirestoreData,
  );
  String get adminManageViaCMS => _getString(
    AppStrings.adminManageViaCMS,
    AppStringsEn.adminManageViaCMS,
    AppStringsFr.adminManageViaCMS,
  );
  String get adminUseCMSScreens => _getString(
    AppStrings.adminUseCMSScreens,
    AppStringsEn.adminUseCMSScreens,
    AppStringsFr.adminUseCMSScreens,
  );
  String get adminQuotesViaCMS => _getString(
    AppStrings.adminQuotesViaCMS,
    AppStringsEn.adminQuotesViaCMS,
    AppStringsFr.adminQuotesViaCMS,
  );
  String get adminContentViaCMS => _getString(
    AppStrings.adminContentViaCMS,
    AppStringsEn.adminContentViaCMS,
    AppStringsFr.adminContentViaCMS,
  );
  String get adminChallengesViaCMS => _getString(
    AppStrings.adminChallengesViaCMS,
    AppStringsEn.adminChallengesViaCMS,
    AppStringsFr.adminChallengesViaCMS,
  );
  String get adminUsersViaManagement => _getString(
    AppStrings.adminUsersViaManagement,
    AppStringsEn.adminUsersViaManagement,
    AppStringsFr.adminUsersViaManagement,
  );
  String get adminTherapistsViaManagement => _getString(
    AppStrings.adminTherapistsViaManagement,
    AppStringsEn.adminTherapistsViaManagement,
    AppStringsFr.adminTherapistsViaManagement,
  );
  String get adminExport => _getString(
    AppStrings.adminExport,
    AppStringsEn.adminExport,
    AppStringsFr.adminExport,
  );
  String get adminRefresh => _getString(
    AppStrings.adminRefresh,
    AppStringsEn.adminRefresh,
    AppStringsFr.adminRefresh,
  );
  String get adminNewBooking => _getString(
    AppStrings.adminNewBooking,
    AppStringsEn.adminNewBooking,
    AppStringsFr.adminNewBooking,
  );
  String get adminApprove => _getString(
    AppStrings.adminApprove,
    AppStringsEn.adminApprove,
    AppStringsFr.adminApprove,
  );
  String get adminReject => _getString(
    AppStrings.adminReject,
    AppStringsEn.adminReject,
    AppStringsFr.adminReject,
  );
  String get adminRefund => _getString(
    AppStrings.adminRefund,
    AppStringsEn.adminRefund,
    AppStringsFr.adminRefund,
  );
  String get adminFlag => _getString(
    AppStrings.adminFlag,
    AppStringsEn.adminFlag,
    AppStringsFr.adminFlag,
  );
  String get adminDelete => _getString(
    AppStrings.adminDelete,
    AppStringsEn.adminDelete,
    AppStringsFr.adminDelete,
  );
  String get adminFeatureComingSoon => _getString(
    AppStrings.adminFeatureComingSoon,
    AppStringsEn.adminFeatureComingSoon,
    AppStringsFr.adminFeatureComingSoon,
  );
  String get adminExportComingSoon => _getString(
    AppStrings.adminExportComingSoon,
    AppStringsEn.adminExportComingSoon,
    AppStringsFr.adminExportComingSoon,
  );
  String get adminNewBookingComingSoon => _getString(
    AppStrings.adminNewBookingComingSoon,
    AppStringsEn.adminNewBookingComingSoon,
    AppStringsFr.adminNewBookingComingSoon,
  );
  String get adminPaymentsOverview => _getString(
    AppStrings.adminPaymentsOverview,
    AppStringsEn.adminPaymentsOverview,
    AppStringsFr.adminPaymentsOverview,
  );
  String get adminPaymentApproved => _getString(
    AppStrings.adminPaymentApproved,
    AppStringsEn.adminPaymentApproved,
    AppStringsFr.adminPaymentApproved,
  );
  String get adminPaymentRejected => _getString(
    AppStrings.adminPaymentRejected,
    AppStringsEn.adminPaymentRejected,
    AppStringsFr.adminPaymentRejected,
  );
  String get adminRefundProcessed => _getString(
    AppStrings.adminRefundProcessed,
    AppStringsEn.adminRefundProcessed,
    AppStringsFr.adminRefundProcessed,
  );
  String get adminConfirmApprove => _getString(
    AppStrings.adminConfirmApprove,
    AppStringsEn.adminConfirmApprove,
    AppStringsFr.adminConfirmApprove,
  );
  String get adminConfirmReject => _getString(
    AppStrings.adminConfirmReject,
    AppStringsEn.adminConfirmReject,
    AppStringsFr.adminConfirmReject,
  );
  String get adminConfirmRefund => _getString(
    AppStrings.adminConfirmRefund,
    AppStringsEn.adminConfirmRefund,
    AppStringsFr.adminConfirmRefund,
  );
  String get adminTotal => _getString(
    AppStrings.adminTotal,
    AppStringsEn.adminTotal,
    AppStringsFr.adminTotal,
  );
  String get adminToday => _getString(
    AppStrings.adminToday,
    AppStringsEn.adminToday,
    AppStringsFr.adminToday,
  );
  String get adminUpcoming => _getString(
    AppStrings.adminUpcoming,
    AppStringsEn.adminUpcoming,
    AppStringsFr.adminUpcoming,
  );
  String get adminActive => _getString(
    AppStrings.adminActive,
    AppStringsEn.adminActive,
    AppStringsFr.adminActive,
  );
  String get adminPending => _getString(
    AppStrings.adminPending,
    AppStringsEn.adminPending,
    AppStringsFr.adminPending,
  );
  String get adminAll => _getString(
    AppStrings.adminAll,
    AppStringsEn.adminAll,
    AppStringsFr.adminAll,
  );
  String get adminCompleted => _getString(
    AppStrings.adminCompleted,
    AppStringsEn.adminCompleted,
    AppStringsFr.adminCompleted,
  );
  String get adminCancelled => _getString(
    AppStrings.adminCancelled,
    AppStringsEn.adminCancelled,
    AppStringsFr.adminCancelled,
  );
  String get adminSearchByClientName => _getString(
    AppStrings.adminSearchByClientName,
    AppStringsEn.adminSearchByClientName,
    AppStringsFr.adminSearchByClientName,
  );
  String get adminSearchByNameOrEmail => _getString(
    AppStrings.adminSearchByNameOrEmail,
    AppStringsEn.adminSearchByNameOrEmail,
    AppStringsFr.adminSearchByNameOrEmail,
  );
  String get adminAllRoles => _getString(
    AppStrings.adminAllRoles,
    AppStringsEn.adminAllRoles,
    AppStringsFr.adminAllRoles,
  );
  String get adminAllStatus => _getString(
    AppStrings.adminAllStatus,
    AppStringsEn.adminAllStatus,
    AppStringsFr.adminAllStatus,
  );
  String get adminAllTypes => _getString(
    AppStrings.adminAllTypes,
    AppStringsEn.adminAllTypes,
    AppStringsFr.adminAllTypes,
  );
  String get adminNoPaymentsFound => _getString(
    AppStrings.adminNoPaymentsFound,
    AppStringsEn.adminNoPaymentsFound,
    AppStringsFr.adminNoPaymentsFound,
  );
  String get adminNoUsersFound => _getString(
    AppStrings.adminNoUsersFound,
    AppStringsEn.adminNoUsersFound,
    AppStringsFr.adminNoUsersFound,
  );
  String get adminNoAppointmentsFound => _getString(
    AppStrings.adminNoAppointmentsFound,
    AppStringsEn.adminNoAppointmentsFound,
    AppStringsFr.adminNoAppointmentsFound,
  );
  String get adminAdjustFilters => _getString(
    AppStrings.adminAdjustFilters,
    AppStringsEn.adminAdjustFilters,
    AppStringsFr.adminAdjustFilters,
  );
  String get adminVerificationPending => _getString(
    AppStrings.adminVerificationPending,
    AppStringsEn.adminVerificationPending,
    AppStringsFr.adminVerificationPending,
  );
  String get adminVerificationApproved => _getString(
    AppStrings.adminVerificationApproved,
    AppStringsEn.adminVerificationApproved,
    AppStringsFr.adminVerificationApproved,
  );
  String get adminVerificationRejected => _getString(
    AppStrings.adminVerificationRejected,
    AppStringsEn.adminVerificationRejected,
    AppStringsFr.adminVerificationRejected,
  );
  String get adminVerificationAll => _getString(
    AppStrings.adminVerificationAll,
    AppStringsEn.adminVerificationAll,
    AppStringsFr.adminVerificationAll,
  );

  // Reports Screen
  String get adminMonthlySummary => _getString(
    AppStrings.adminMonthlySummary,
    AppStringsEn.adminMonthlySummary,
    AppStringsFr.adminMonthlySummary,
  );
  String get adminMonthlySummaryDesc => _getString(
    AppStrings.adminMonthlySummaryDesc,
    AppStringsEn.adminMonthlySummaryDesc,
    AppStringsFr.adminMonthlySummaryDesc,
  );
  String get adminPatientActivity => _getString(
    AppStrings.adminPatientActivity,
    AppStringsEn.adminPatientActivity,
    AppStringsFr.adminPatientActivity,
  );
  String get adminPatientActivityDesc => _getString(
    AppStrings.adminPatientActivityDesc,
    AppStringsEn.adminPatientActivityDesc,
    AppStringsFr.adminPatientActivityDesc,
  );
  String get adminClinicianReport => _getString(
    AppStrings.adminClinicianReport,
    AppStringsEn.adminClinicianReport,
    AppStringsFr.adminClinicianReport,
  );
  String get adminClinicianReportDesc => _getString(
    AppStrings.adminClinicianReportDesc,
    AppStringsEn.adminClinicianReportDesc,
    AppStringsFr.adminClinicianReportDesc,
  );
  String get adminFinancialReport => _getString(
    AppStrings.adminFinancialReport,
    AppStringsEn.adminFinancialReport,
    AppStringsFr.adminFinancialReport,
  );
  String get adminFinancialReportDesc => _getString(
    AppStrings.adminFinancialReportDesc,
    AppStringsEn.adminFinancialReportDesc,
    AppStringsFr.adminFinancialReportDesc,
  );
  String get adminRiskAssessment => _getString(
    AppStrings.adminRiskAssessment,
    AppStringsEn.adminRiskAssessment,
    AppStringsFr.adminRiskAssessment,
  );
  String get adminRiskAssessmentDesc => _getString(
    AppStrings.adminRiskAssessmentDesc,
    AppStringsEn.adminRiskAssessmentDesc,
    AppStringsFr.adminRiskAssessmentDesc,
  );
  String get adminCustomReport => _getString(
    AppStrings.adminCustomReport,
    AppStringsEn.adminCustomReport,
    AppStringsFr.adminCustomReport,
  );
  String get adminCustomReportDesc => _getString(
    AppStrings.adminCustomReportDesc,
    AppStringsEn.adminCustomReportDesc,
    AppStringsFr.adminCustomReportDesc,
  );
  String get adminRecentReports => _getString(
    AppStrings.adminRecentReports,
    AppStringsEn.adminRecentReports,
    AppStringsFr.adminRecentReports,
  );
  String get adminGenerating => _getString(
    AppStrings.adminGenerating,
    AppStringsEn.adminGenerating,
    AppStringsFr.adminGenerating,
  );
  String get adminCustomReportComingSoon => _getString(
    AppStrings.adminCustomReportComingSoon,
    AppStringsEn.adminCustomReportComingSoon,
    AppStringsFr.adminCustomReportComingSoon,
  );
  String get adminGenerate => _getString(
    AppStrings.adminGenerate,
    AppStringsEn.adminGenerate,
    AppStringsFr.adminGenerate,
  );
  String get adminDownload => _getString(
    AppStrings.adminDownload,
    AppStringsEn.adminDownload,
    AppStringsFr.adminDownload,
  );
  String get adminView => _getString(
    AppStrings.adminView,
    AppStringsEn.adminView,
    AppStringsFr.adminView,
  );
  String get adminDaysAgo => _getString(
    AppStrings.adminDaysAgo,
    AppStringsEn.adminDaysAgo,
    AppStringsFr.adminDaysAgo,
  );
  String get adminYesterday => _getString(
    AppStrings.adminYesterday,
    AppStringsEn.adminYesterday,
    AppStringsFr.adminYesterday,
  );

  // ─── API Keys Settings ────────────────────────────────────────────────
  String get apiKeysTitle => _getString(
    AppStrings.apiKeysTitle,
    AppStringsEn.apiKeysTitle,
    AppStringsFr.apiKeysTitle,
  );
  String get apiKeysSubtitle => _getString(
    AppStrings.apiKeysSubtitle,
    AppStringsEn.apiKeysSubtitle,
    AppStringsFr.apiKeysSubtitle,
  );
  String get openaiApiKey => _getString(
    AppStrings.openaiApiKey,
    AppStringsEn.openaiApiKey,
    AppStringsFr.openaiApiKey,
  );
  String get openaiApiKeyDesc => _getString(
    AppStrings.openaiApiKeyDesc,
    AppStringsEn.openaiApiKeyDesc,
    AppStringsFr.openaiApiKeyDesc,
  );
  String get geminiApiKey => _getString(
    AppStrings.geminiApiKey,
    AppStringsEn.geminiApiKey,
    AppStringsFr.geminiApiKey,
  );
  String get geminiApiKeyDesc => _getString(
    AppStrings.geminiApiKeyDesc,
    AppStringsEn.geminiApiKeyDesc,
    AppStringsFr.geminiApiKeyDesc,
  );
  String get zegoAppId => _getString(
    AppStrings.zegoAppId,
    AppStringsEn.zegoAppId,
    AppStringsFr.zegoAppId,
  );
  String get zegoAppIdDesc => _getString(
    AppStrings.zegoAppIdDesc,
    AppStringsEn.zegoAppIdDesc,
    AppStringsFr.zegoAppIdDesc,
  );
  String get zegoAppSign => _getString(
    AppStrings.zegoAppSign,
    AppStringsEn.zegoAppSign,
    AppStringsFr.zegoAppSign,
  );
  String get zegoAppSignDesc => _getString(
    AppStrings.zegoAppSignDesc,
    AppStringsEn.zegoAppSignDesc,
    AppStringsFr.zegoAppSignDesc,
  );
  String get zegoToken => _getString(
    AppStrings.zegoToken,
    AppStringsEn.zegoToken,
    AppStringsFr.zegoToken,
  );
  String get zegoTokenDesc => _getString(
    AppStrings.zegoTokenDesc,
    AppStringsEn.zegoTokenDesc,
    AppStringsFr.zegoTokenDesc,
  );
  String get fcmVapidKey => _getString(
    AppStrings.fcmVapidKey,
    AppStringsEn.fcmVapidKey,
    AppStringsFr.fcmVapidKey,
  );
  String get fcmVapidKeyDesc => _getString(
    AppStrings.fcmVapidKeyDesc,
    AppStringsEn.fcmVapidKeyDesc,
    AppStringsFr.fcmVapidKeyDesc,
  );
  String get paypalClientId => _getString(
    AppStrings.paypalClientId,
    AppStringsEn.paypalClientId,
    AppStringsFr.paypalClientId,
  );
  String get paypalClientIdDesc => _getString(
    AppStrings.paypalClientIdDesc,
    AppStringsEn.paypalClientIdDesc,
    AppStringsFr.paypalClientIdDesc,
  );
  String get paypalSecret => _getString(
    AppStrings.paypalSecret,
    AppStringsEn.paypalSecret,
    AppStringsFr.paypalSecret,
  );
  String get paypalSecretDesc => _getString(
    AppStrings.paypalSecretDesc,
    AppStringsEn.paypalSecretDesc,
    AppStringsFr.paypalSecretDesc,
  );
  String get freemiusSecretKey => _getString(
    AppStrings.freemiusSecretKey,
    AppStringsEn.freemiusSecretKey,
    AppStringsFr.freemiusSecretKey,
  );
  String get freemiusSecretKeyDesc => _getString(
    AppStrings.freemiusSecretKeyDesc,
    AppStringsEn.freemiusSecretKeyDesc,
    AppStringsFr.freemiusSecretKeyDesc,
  );
  String get freemiusBearerToken => _getString(
    AppStrings.freemiusBearerToken,
    AppStringsEn.freemiusBearerToken,
    AppStringsFr.freemiusBearerToken,
  );
  String get freemiusBearerTokenDesc => _getString(
    AppStrings.freemiusBearerTokenDesc,
    AppStringsEn.freemiusBearerTokenDesc,
    AppStringsFr.freemiusBearerTokenDesc,
  );
  String get freemiusProductId => _getString(
    AppStrings.freemiusProductId,
    AppStringsEn.freemiusProductId,
    AppStringsFr.freemiusProductId,
  );
  String get freemiusProductIdDesc => _getString(
    AppStrings.freemiusProductIdDesc,
    AppStringsEn.freemiusProductIdDesc,
    AppStringsFr.freemiusProductIdDesc,
  );
  String get apiKeyConfigured => _getString(
    AppStrings.apiKeyConfigured,
    AppStringsEn.apiKeyConfigured,
    AppStringsFr.apiKeyConfigured,
  );
  String get apiKeyNotConfigured => _getString(
    AppStrings.apiKeyNotConfigured,
    AppStringsEn.apiKeyNotConfigured,
    AppStringsFr.apiKeyNotConfigured,
  );
  String get apiKeysSaved => _getString(
    AppStrings.apiKeysSaved,
    AppStringsEn.apiKeysSaved,
    AppStringsFr.apiKeysSaved,
  );
  String get apiKeysError => _getString(
    AppStrings.apiKeysError,
    AppStringsEn.apiKeysError,
    AppStringsFr.apiKeysError,
  );
  String get apiKeyReveal => _getString(
    AppStrings.apiKeyReveal,
    AppStringsEn.apiKeyReveal,
    AppStringsFr.apiKeyReveal,
  );
  String get apiKeyHide => _getString(
    AppStrings.apiKeyHide,
    AppStringsEn.apiKeyHide,
    AppStringsFr.apiKeyHide,
  );
  String get saveAllKeys => _getString(
    AppStrings.saveAllKeys,
    AppStringsEn.saveAllKeys,
    AppStringsFr.saveAllKeys,
  );

  // Crisis Detection
  String get crisisYouMatter => _getString(
    AppStrings.crisisYouMatter,
    AppStringsEn.crisisYouMatter,
    AppStringsFr.crisisYouMatter,
  );
  String get crisisNotAlone => _getString(
    AppStrings.crisisNotAlone,
    AppStringsEn.crisisNotAlone,
    AppStringsFr.crisisNotAlone,
  );
  String get crisisHelplines => _getString(
    AppStrings.crisisHelplines,
    AppStringsEn.crisisHelplines,
    AppStringsFr.crisisHelplines,
  );
  String get crisisInAppHelp => _getString(
    AppStrings.crisisInAppHelp,
    AppStringsEn.crisisInAppHelp,
    AppStringsFr.crisisInAppHelp,
  );
  String get crisisInAppHelpDesc => _getString(
    AppStrings.crisisInAppHelpDesc,
    AppStringsEn.crisisInAppHelpDesc,
    AppStringsFr.crisisInAppHelpDesc,
  );
  String get crisisAcknowledge => _getString(
    AppStrings.crisisAcknowledge,
    AppStringsEn.crisisAcknowledge,
    AppStringsFr.crisisAcknowledge,
  );
  String get crisisBannerMessage => _getString(
    AppStrings.crisisBannerMessage,
    AppStringsEn.crisisBannerMessage,
    AppStringsFr.crisisBannerMessage,
  );
  String get crisisGetHelp => _getString(
    AppStrings.crisisGetHelp,
    AppStringsEn.crisisGetHelp,
    AppStringsFr.crisisGetHelp,
  );
  String get crisisAlerts => _getString(
    AppStrings.crisisAlerts,
    AppStringsEn.crisisAlerts,
    AppStringsFr.crisisAlerts,
  );
  String get crisisAlertsTitle => _getString(
    AppStrings.crisisAlertsTitle,
    AppStringsEn.crisisAlertsTitle,
    AppStringsFr.crisisAlertsTitle,
  );
  String get crisisActiveAlerts => _getString(
    AppStrings.crisisActiveAlerts,
    AppStringsEn.crisisActiveAlerts,
    AppStringsFr.crisisActiveAlerts,
  );
  String get crisisAllAlerts => _getString(
    AppStrings.crisisAllAlerts,
    AppStringsEn.crisisAllAlerts,
    AppStringsFr.crisisAllAlerts,
  );
  String get crisisNoActiveAlerts => _getString(
    AppStrings.crisisNoActiveAlerts,
    AppStringsEn.crisisNoActiveAlerts,
    AppStringsFr.crisisNoActiveAlerts,
  );
  String get crisisNoAlerts => _getString(
    AppStrings.crisisNoAlerts,
    AppStringsEn.crisisNoAlerts,
    AppStringsFr.crisisNoAlerts,
  );
  String get crisisAlertActions => _getString(
    AppStrings.crisisAlertActions,
    AppStringsEn.crisisAlertActions,
    AppStringsFr.crisisAlertActions,
  );
  String get crisisSeverity => _getString(
    AppStrings.crisisSeverity,
    AppStringsEn.crisisSeverity,
    AppStringsFr.crisisSeverity,
  );
  String get crisisStatus => _getString(
    AppStrings.crisisStatus,
    AppStringsEn.crisisStatus,
    AppStringsFr.crisisStatus,
  );
  String get crisisAcknowledgeAction => _getString(
    AppStrings.crisisAcknowledgeAction,
    AppStringsEn.crisisAcknowledgeAction,
    AppStringsFr.crisisAcknowledgeAction,
  );
  String get crisisAssignTherapist => _getString(
    AppStrings.crisisAssignTherapist,
    AppStringsEn.crisisAssignTherapist,
    AppStringsFr.crisisAssignTherapist,
  );
  String get crisisResolve => _getString(
    AppStrings.crisisResolve,
    AppStringsEn.crisisResolve,
    AppStringsFr.crisisResolve,
  );
  String get crisisFalsePositive => _getString(
    AppStrings.crisisFalsePositive,
    AppStringsEn.crisisFalsePositive,
    AppStringsFr.crisisFalsePositive,
  );
  String get crisisResolutionNotes => _getString(
    AppStrings.crisisResolutionNotes,
    AppStringsEn.crisisResolutionNotes,
    AppStringsFr.crisisResolutionNotes,
  );
  String get crisisMatchedKeywords => _getString(
    AppStrings.crisisMatchedKeywords,
    AppStringsEn.crisisMatchedKeywords,
    AppStringsFr.crisisMatchedKeywords,
  );
  String get crisisSourceAiChat => _getString(
    AppStrings.crisisSourceAiChat,
    AppStringsEn.crisisSourceAiChat,
    AppStringsFr.crisisSourceAiChat,
  );
  String get crisisSourceCommunity => _getString(
    AppStrings.crisisSourceCommunity,
    AppStringsEn.crisisSourceCommunity,
    AppStringsFr.crisisSourceCommunity,
  );
  String get crisisSourceMoodLog => _getString(
    AppStrings.crisisSourceMoodLog,
    AppStringsEn.crisisSourceMoodLog,
    AppStringsFr.crisisSourceMoodLog,
  );

  // ─── Loading / Error / Empty State Strings ──────────────────────────────
  String get loadingPosts => _getString(
    AppStringsAsync.loadingPosts,
    AppStringsEnAsync.loadingPosts,
    AppStringsFrAsync.loadingPosts,
  );
  String get loadingContent => _getString(
    AppStringsAsync.loadingContent,
    AppStringsEnAsync.loadingContent,
    AppStringsFrAsync.loadingContent,
  );
  String get loadingData => _getString(
    AppStringsAsync.loadingData,
    AppStringsEnAsync.loadingData,
    AppStringsFrAsync.loadingData,
  );
  String get errorLoadingPosts => _getString(
    AppStringsAsync.errorLoadingPosts,
    AppStringsEnAsync.errorLoadingPosts,
    AppStringsFrAsync.errorLoadingPosts,
  );
  String get tapToRetry => _getString(
    AppStringsAsync.tapToRetry,
    AppStringsEnAsync.tapToRetry,
    AppStringsFrAsync.tapToRetry,
  );
  String get pullToRefresh => _getString(
    AppStringsAsync.pullToRefresh,
    AppStringsEnAsync.pullToRefresh,
    AppStringsFrAsync.pullToRefresh,
  );
  String get noPostsInCategory => _getString(
    AppStringsAsync.noPostsInCategory,
    AppStringsEnAsync.noPostsInCategory,
    AppStringsFrAsync.noPostsInCategory,
  );
  String get loadingMore => _getString(
    AppStringsAsync.loadingMore,
    AppStringsEnAsync.loadingMore,
    AppStringsFrAsync.loadingMore,
  );

  // Call History
  String get callHistory => _getString(
    AppStrings.callHistory,
    AppStringsEn.callHistory,
    AppStringsFr.callHistory,
  );
  String get missedCall => _getString(
    AppStrings.missedCall,
    AppStringsEn.missedCall,
    AppStringsFr.missedCall,
  );
  String get incomingCall => _getString(
    AppStrings.incomingCall,
    AppStringsEn.incomingCall,
    AppStringsFr.incomingCall,
  );
  String get outgoingCall => _getString(
    AppStrings.outgoingCall,
    AppStringsEn.outgoingCall,
    AppStringsFr.outgoingCall,
  );
  String get callDuration => _getString(
    AppStrings.callDuration,
    AppStringsEn.callDuration,
    AppStringsFr.callDuration,
  );
  String get noCallHistory => _getString(
    AppStrings.noCallHistory,
    AppStringsEn.noCallHistory,
    AppStringsFr.noCallHistory,
  );
  String get noCallHistoryDesc => _getString(
    AppStrings.noCallHistoryDesc,
    AppStringsEn.noCallHistoryDesc,
    AppStringsFr.noCallHistoryDesc,
  );
  String get callDeclined => _getString(
    AppStrings.callDeclined,
    AppStringsEn.callDeclined,
    AppStringsFr.callDeclined,
  );
  String get callRinging => _getString(
    AppStrings.callRinging,
    AppStringsEn.callRinging,
    AppStringsFr.callRinging,
  );
  String get callingUser => _getString(
    AppStrings.callingUser,
    AppStringsEn.callingUser,
    AppStringsFr.callingUser,
  );
  String get incomingCallFrom => _getString(
    AppStrings.incomingCallFrom,
    AppStringsEn.incomingCallFrom,
    AppStringsFr.incomingCallFrom,
  );

  String get callNotifications => _getString(
    AppStrings.callNotifications,
    AppStringsEn.callNotifications,
    AppStringsFr.callNotifications,
  );

  String get trendImproving => _getString(
    AppStrings.trendImproving,
    AppStringsEn.trendImproving,
    AppStringsFr.trendImproving,
  );
  String get trendDeclining => _getString(
    AppStrings.trendDeclining,
    AppStringsEn.trendDeclining,
    AppStringsFr.trendDeclining,
  );
  String get trendStable => _getString(
    AppStrings.trendStable,
    AppStringsEn.trendStable,
    AppStringsFr.trendStable,
  );
  String get morning => _getString(
    AppStrings.morning,
    AppStringsEn.morning,
    AppStringsFr.morning,
  );
  String get afternoon => _getString(
    AppStrings.afternoon,
    AppStringsEn.afternoon,
    AppStringsFr.afternoon,
  );
  String get evening => _getString(
    AppStrings.evening,
    AppStringsEn.evening,
    AppStringsFr.evening,
  );
  String get night => _getString(
    AppStrings.night,
    AppStringsEn.night,
    AppStringsFr.night,
  );
  String get noDataAvailable => _getString(
    AppStrings.noDataAvailable,
    AppStringsEn.noDataAvailable,
    AppStringsFr.noDataAvailable,
  );

  // Therapist assignment (admin)
  String get assignedTherapist => _getString(
    AppStrings.assignedTherapist,
    AppStringsEn.assignedTherapist,
    AppStringsFr.assignedTherapist,
  );
  String get selectTherapist => _getString(
    AppStrings.selectTherapist,
    AppStringsEn.selectTherapist,
    AppStringsFr.selectTherapist,
  );
  String get noApprovedTherapists => _getString(
    AppStrings.noApprovedTherapists,
    AppStringsEn.noApprovedTherapists,
    AppStringsFr.noApprovedTherapists,
  );
  String get failedLoadTherapists => _getString(
    AppStrings.failedLoadTherapists,
    AppStringsEn.failedLoadTherapists,
    AppStringsFr.failedLoadTherapists,
  );
  String get assignLabel => _getString(
    AppStrings.assign,
    AppStringsEn.assign,
    AppStringsFr.assign,
  );
  String get changeLabel => _getString(
    AppStrings.change,
    AppStringsEn.change,
    AppStringsFr.change,
  );
  String get removeLabel => _getString(
    AppStrings.remove,
    AppStringsEn.remove,
    AppStringsFr.remove,
  );
  String get assignedTherapistSuccess => _getString(
    AppStrings.assignedTherapistSuccess,
    AppStringsEn.assignedTherapistSuccess,
    AppStringsFr.assignedTherapistSuccess,
  );
  String get removeTherapistSuccess => _getString(
    AppStrings.removeTherapistSuccess,
    AppStringsEn.removeTherapistSuccess,
    AppStringsFr.removeTherapistSuccess,
  );

  // Assigned patients (therapist view)
  String get myAssignedPatients => _getString(
    AppStrings.myAssignedPatients,
    AppStringsEn.myAssignedPatients,
    AppStringsFr.myAssignedPatients,
  );
  String get noAssignedPatients => _getString(
    AppStrings.noAssignedPatients,
    AppStringsEn.noAssignedPatients,
    AppStringsFr.noAssignedPatients,
  );
  String get noAssignedPatientsHint => _getString(
    AppStrings.noAssignedPatientsHint,
    AppStringsEn.noAssignedPatientsHint,
    AppStringsFr.noAssignedPatientsHint,
  );
  String get chatNotCreated => _getString(
    AppStrings.chatNotCreated,
    AppStringsEn.chatNotCreated,
    AppStringsFr.chatNotCreated,
  );
  String get joinedPrefix => _getString(
    AppStrings.joinedPrefix,
    AppStringsEn.joinedPrefix,
    AppStringsFr.joinedPrefix,
  );
  String get patientsLabel => _getString(
    AppStrings.navPatients,
    AppStringsEn.navPatients,
    AppStringsFr.navPatients,
  );

  // Therapist patient-detail screen
  String get tabOverview => _getString(
    AppStrings.tabOverview,
    AppStringsEn.tabOverview,
    AppStringsFr.tabOverview,
  );
  String get tabMood => _getString(
    AppStrings.tabMood,
    AppStringsEn.tabMood,
    AppStringsFr.tabMood,
  );
  String get tabTests => _getString(
    AppStrings.tabTests,
    AppStringsEn.tabTests,
    AppStringsFr.tabTests,
  );
  String get tabSessions => _getString(
    AppStrings.tabSessions,
    AppStringsEn.tabSessions,
    AppStringsFr.tabSessions,
  );
  String get latestMood => _getString(
    AppStrings.latestMood,
    AppStringsEn.latestMood,
    AppStringsFr.latestMood,
  );
  String get latestTest => _getString(
    AppStrings.latestTest,
    AppStringsEn.latestTest,
    AppStringsFr.latestTest,
  );
  String get completedSessionsLabel => _getString(
    AppStrings.completedSessions,
    AppStringsEn.completedSessions,
    AppStringsFr.completedSessions,
  );
  String get moodEntriesCount => _getString(
    AppStrings.moodEntriesCount,
    AppStringsEn.moodEntriesCount,
    AppStringsFr.moodEntriesCount,
  );
  String get testResultsCount => _getString(
    AppStrings.testResultsCount,
    AppStringsEn.testResultsCount,
    AppStringsFr.testResultsCount,
  );
  String get noMoodEntriesYet => _getString(
    AppStrings.noMoodEntriesYet,
    AppStringsEn.noMoodEntriesYet,
    AppStringsFr.noMoodEntriesYet,
  );
  String get noTestResultsYet => _getString(
    AppStrings.noTestResultsYet,
    AppStringsEn.noTestResultsYet,
    AppStringsFr.noTestResultsYet,
  );
  String get noSessionsYet => _getString(
    AppStrings.noSessionsYet,
    AppStringsEn.noSessionsYet,
    AppStringsFr.noSessionsYet,
  );
  String get noUpcomingSession => _getString(
    AppStrings.noUpcomingSession,
    AppStringsEn.noUpcomingSession,
    AppStringsFr.noUpcomingSession,
  );
  String get patientNotFound => _getString(
    AppStrings.patientNotFound,
    AppStringsEn.patientNotFound,
    AppStringsFr.patientNotFound,
  );
  String get signInRequired => _getString(
    AppStrings.signInRequired,
    AppStringsEn.signInRequired,
    AppStringsFr.signInRequired,
  );
  String get lastSeenJustNow => _getString(
    AppStrings.lastSeenJustNow,
    AppStringsEn.lastSeenJustNow,
    AppStringsFr.lastSeenJustNow,
  );
  String get _lastSeenMinTpl => _getString(
    AppStrings.lastSeenMinutesAgo,
    AppStringsEn.lastSeenMinutesAgo,
    AppStringsFr.lastSeenMinutesAgo,
  );
  String get _lastSeenHrTpl => _getString(
    AppStrings.lastSeenHoursAgo,
    AppStringsEn.lastSeenHoursAgo,
    AppStringsFr.lastSeenHoursAgo,
  );
  String get _lastSeenDayTpl => _getString(
    AppStrings.lastSeenDaysAgo,
    AppStringsEn.lastSeenDaysAgo,
    AppStringsFr.lastSeenDaysAgo,
  );
  String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return offlineStatus;
    final diff = DateTime.now().difference(lastSeen);
    if (diff < const Duration(minutes: 2)) return lastSeenJustNow;
    if (diff < const Duration(hours: 1)) {
      return _lastSeenMinTpl.replaceAll('{n}', '${diff.inMinutes}');
    }
    if (diff < const Duration(days: 1)) {
      return _lastSeenHrTpl.replaceAll('{n}', '${diff.inHours}');
    }
    return _lastSeenDayTpl.replaceAll('{n}', '${diff.inDays}');
  }

  String get aboutSanad => _getString(
    AppStrings.aboutSanad,
    AppStringsEn.aboutSanad,
    AppStringsFr.aboutSanad,
  );
  String get aiAnalytics => _getString(
    AppStrings.aiAnalytics,
    AppStringsEn.aiAnalytics,
    AppStringsFr.aiAnalytics,
  );
  String get analyzeAll => _getString(
    AppStrings.analyzeAll,
    AppStringsEn.analyzeAll,
    AppStringsFr.analyzeAll,
  );
  String get activeLoggers7d => _getString(
    AppStrings.activeLoggers7d,
    AppStringsEn.activeLoggers7d,
    AppStringsFr.activeLoggers7d,
  );
  String get criticalRiskCount => _getString(
    AppStrings.criticalRiskCount,
    AppStringsEn.criticalRiskCount,
    AppStringsFr.criticalRiskCount,
  );
  String get highRiskCount => _getString(
    AppStrings.highRiskCount,
    AppStringsEn.highRiskCount,
    AppStringsFr.highRiskCount,
  );
  String get lastMood => _getString(
    AppStrings.lastMood,
    AppStringsEn.lastMood,
    AppStringsFr.lastMood,
  );
  String get loadMore => _getString(
    AppStrings.loadMore,
    AppStringsEn.loadMore,
    AppStringsFr.loadMore,
  );
  String get totalEntries => _getString(
    AppStrings.totalEntries,
    AppStringsEn.totalEntries,
    AppStringsFr.totalEntries,
  );
  String get bookTherapistSession => _getString(
    AppStrings.bookTherapistSession,
    AppStringsEn.bookTherapistSession,
    AppStringsFr.bookTherapistSession,
  );
  String get chooseConnection => _getString(
    AppStrings.chooseConnection,
    AppStringsEn.chooseConnection,
    AppStringsFr.chooseConnection,
  );
  String get generalInquiries => _getString(
    AppStrings.generalInquiries,
    AppStringsEn.generalInquiries,
    AppStringsFr.generalInquiries,
  );
  String get helpUnderstandSituation => _getString(
    AppStrings.helpUnderstandSituation,
    AppStringsEn.helpUnderstandSituation,
    AppStringsFr.helpUnderstandSituation,
  );
  String get requiresActiveBooking => _getString(
    AppStrings.requiresActiveBooking,
    AppStringsEn.requiresActiveBooking,
    AppStringsFr.requiresActiveBooking,
  );
  String get shareConversationContext => _getString(
    AppStrings.shareConversationContext,
    AppStringsEn.shareConversationContext,
    AppStringsFr.shareConversationContext,
  );
  String get talkToHuman => _getString(
    AppStrings.talkToHuman,
    AppStringsEn.talkToHuman,
    AppStringsFr.talkToHuman,
  );
  String get allChats => _getString(
    AppStrings.allChats,
    AppStringsEn.allChats,
    AppStringsFr.allChats,
  );
  String get archiveChat => _getString(
    AppStrings.archiveChat,
    AppStringsEn.archiveChat,
    AppStringsFr.archiveChat,
  );
  String get atLeastOneLanguageRequired => _getString(
    AppStrings.atLeastOneLanguageRequired,
    AppStringsEn.atLeastOneLanguageRequired,
    AppStringsFr.atLeastOneLanguageRequired,
  );
  String get availableStatus => _getString(
    AppStrings.availableStatus,
    AppStringsEn.availableStatus,
    AppStringsFr.availableStatus,
  );
  String get selectATherapist => _getString(
    AppStrings.selectATherapist,
    AppStringsEn.selectATherapist,
    AppStringsFr.selectATherapist,
  );
  String get bookingPending => _getString(
    AppStrings.bookingPending,
    AppStringsEn.bookingPending,
    AppStringsFr.bookingPending,
  );
  String get sessionConfirmed => _getString(
    AppStrings.sessionConfirmed,
    AppStringsEn.sessionConfirmed,
    AppStringsFr.sessionConfirmed,
  );
  String get previousSession => _getString(
    AppStrings.previousSession,
    AppStringsEn.previousSession,
    AppStringsFr.previousSession,
  );
  String get benefitFromProfessional => _getString(
    AppStrings.benefitFromProfessional,
    AppStringsEn.benefitFromProfessional,
    AppStringsFr.benefitFromProfessional,
  );
  String get bioInArabic => _getString(
    AppStrings.bioInArabic,
    AppStringsEn.bioInArabic,
    AppStringsFr.bioInArabic,
  );
  String get bioInEnglish => _getString(
    AppStrings.bioInEnglish,
    AppStringsEn.bioInEnglish,
    AppStringsFr.bioInEnglish,
  );
  String get bioInFrench => _getString(
    AppStrings.bioInFrench,
    AppStringsEn.bioInFrench,
    AppStringsFr.bioInFrench,
  );
  String get blockUser => _getString(
    AppStrings.blockUser,
    AppStringsEn.blockUser,
    AppStringsFr.blockUser,
  );
  String get blockUserConfirm => _getString(
    AppStrings.blockUserConfirm,
    AppStringsEn.blockUserConfirm,
    AppStringsFr.blockUserConfirm,
  );
  String get bookingImpact => _getString(
    AppStrings.bookingImpact,
    AppStringsEn.bookingImpact,
    AppStringsFr.bookingImpact,
  );
  String get chatsWithTherapistsAppearHere => _getString(
    AppStrings.chatsWithTherapistsAppearHere,
    AppStringsEn.chatsWithTherapistsAppearHere,
    AppStringsFr.chatsWithTherapistsAppearHere,
  );
  String get clientsWillAppearHere => _getString(
    AppStrings.clientsWillAppearHere,
    AppStringsEn.clientsWillAppearHere,
    AppStringsFr.clientsWillAppearHere,
  );
  String get connectingWithTherapist => _getString(
    AppStrings.connectingWithTherapist,
    AppStringsEn.connectingWithTherapist,
    AppStringsFr.connectingWithTherapist,
  );
  String get contentEngagement => _getString(
    AppStrings.contentEngagement,
    AppStringsEn.contentEngagement,
    AppStringsFr.contentEngagement,
  );
  String get contextSharedWithSupport => _getString(
    AppStrings.contextSharedWithSupport,
    AppStringsEn.contextSharedWithSupport,
    AppStringsFr.contextSharedWithSupport,
  );
  String get dayOfWeek => _getString(
    AppStrings.dayOfWeek,
    AppStringsEn.dayOfWeek,
    AppStringsFr.dayOfWeek,
  );
  String get deleteUser => _getString(
    AppStrings.deleteUser,
    AppStringsEn.deleteUser,
    AppStringsFr.deleteUser,
  );
  String get deleteUserConfirm => _getString(
    AppStrings.deleteUserConfirm,
    AppStringsEn.deleteUserConfirm,
    AppStringsFr.deleteUserConfirm,
  );
  String get deleting => _getString(
    AppStrings.deleting,
    AppStringsEn.deleting,
    AppStringsFr.deleting,
  );
  String get emergencyAlertSent => _getString(
    AppStrings.emergencyAlertSent,
    AppStringsEn.emergencyAlertSent,
    AppStringsFr.emergencyAlertSent,
  );
  String get emergencyFlagConfirm => _getString(
    AppStrings.emergencyFlagConfirm,
    AppStringsEn.emergencyFlagConfirm,
    AppStringsFr.emergencyFlagConfirm,
  );
  String get ensureFirestoreIndexes => _getString(
    AppStrings.ensureFirestoreIndexes,
    AppStringsEn.ensureFirestoreIndexes,
    AppStringsFr.ensureFirestoreIndexes,
  );
  String get errorLoading => _getString(
    AppStrings.errorLoading,
    AppStringsEn.errorLoading,
    AppStringsFr.errorLoading,
  );
  String get errorLoadingMessages => _getString(
    AppStrings.errorLoadingMessages,
    AppStringsEn.errorLoadingMessages,
    AppStringsFr.errorLoadingMessages,
  );
  String get failedToInitiateCall => _getString(
    AppStrings.failedToInitiateCall,
    AppStringsEn.failedToInitiateCall,
    AppStringsFr.failedToInitiateCall,
  );
  String get failedToLoadAvailableTimes => _getString(
    AppStrings.failedToLoadAvailableTimes,
    AppStringsEn.failedToLoadAvailableTimes,
    AppStringsFr.failedToLoadAvailableTimes,
  );
  String get faqs => _getString(
    AppStrings.faqs,
    AppStringsEn.faqs,
    AppStringsFr.faqs,
  );
  String get general => _getString(
    AppStrings.general,
    AppStringsEn.general,
    AppStringsFr.general,
  );
  String get generateReport => _getString(
    AppStrings.generateReport,
    AppStringsEn.generateReport,
    AppStringsFr.generateReport,
  );
  String get humanEscalation => _getString(
    AppStrings.humanEscalation,
    AppStringsEn.humanEscalation,
    AppStringsFr.humanEscalation,
  );
  String get iUnderstand => _getString(
    AppStrings.iUnderstand,
    AppStringsEn.iUnderstand,
    AppStringsFr.iUnderstand,
  );
  String get licensedTherapist => _getString(
    AppStrings.licensedTherapist,
    AppStringsEn.licensedTherapist,
    AppStringsFr.licensedTherapist,
  );
  String get loggingGap => _getString(
    AppStrings.loggingGap,
    AppStringsEn.loggingGap,
    AppStringsFr.loggingGap,
  );
  String get lowStreakDays => _getString(
    AppStrings.lowStreakDays,
    AppStringsEn.lowStreakDays,
    AppStringsFr.lowStreakDays,
  );
  String get manageOngoingSessions => _getString(
    AppStrings.manageOngoingSessions,
    AppStringsEn.manageOngoingSessions,
    AppStringsFr.manageOngoingSessions,
  );
  String get myInsights => _getString(
    AppStrings.myInsights,
    AppStringsEn.myInsights,
    AppStringsFr.myInsights,
  );
  String get myPatients => _getString(
    AppStrings.myPatients,
    AppStringsEn.myPatients,
    AppStringsFr.myPatients,
  );
  String get nameInArabic => _getString(
    AppStrings.nameInArabic,
    AppStringsEn.nameInArabic,
    AppStringsFr.nameInArabic,
  );
  String get nameInEnglish => _getString(
    AppStrings.nameInEnglish,
    AppStringsEn.nameInEnglish,
    AppStringsFr.nameInEnglish,
  );
  String get nameInFrench => _getString(
    AppStrings.nameInFrench,
    AppStringsEn.nameInFrench,
    AppStringsFr.nameInFrench,
  );
  String get noAvailableSlots => _getString(
    AppStrings.noAvailableSlots,
    AppStringsEn.noAvailableSlots,
    AppStringsFr.noAvailableSlots,
  );
  String get noFaqsYet => _getString(
    AppStrings.noFaqsYet,
    AppStringsEn.noFaqsYet,
    AppStringsFr.noFaqsYet,
  );
  String get noMessagesYet => _getString(
    AppStrings.noMessagesYet,
    AppStringsEn.noMessagesYet,
    AppStringsFr.noMessagesYet,
  );
  String get noPatternsYet => _getString(
    AppStrings.noPatternsYet,
    AppStringsEn.noPatternsYet,
    AppStringsFr.noPatternsYet,
  );
  String get noteSentiment => _getString(
    AppStrings.noteSentiment,
    AppStringsEn.noteSentiment,
    AppStringsFr.noteSentiment,
  );
  String get offlineStatus => _getString(
    AppStrings.offlineStatus,
    AppStringsEn.offlineStatus,
    AppStringsFr.offlineStatus,
  );
  String get onlineStatus => _getString(
    AppStrings.onlineStatus,
    AppStringsEn.onlineStatus,
    AppStringsFr.onlineStatus,
  );
  String get personaCbt => _getString(
    AppStrings.personaCbt,
    AppStringsEn.personaCbt,
    AppStringsFr.personaCbt,
  );
  String get personaCbtDesc => _getString(
    AppStrings.personaCbtDesc,
    AppStringsEn.personaCbtDesc,
    AppStringsFr.personaCbtDesc,
  );
  String get personaCoach => _getString(
    AppStrings.personaCoach,
    AppStringsEn.personaCoach,
    AppStringsFr.personaCoach,
  );
  String get personaCoachDesc => _getString(
    AppStrings.personaCoachDesc,
    AppStringsEn.personaCoachDesc,
    AppStringsFr.personaCoachDesc,
  );
  String get personaCompanion => _getString(
    AppStrings.personaCompanion,
    AppStringsEn.personaCompanion,
    AppStringsFr.personaCompanion,
  );
  String get personaCompanionDesc => _getString(
    AppStrings.personaCompanionDesc,
    AppStringsEn.personaCompanionDesc,
    AppStringsFr.personaCompanionDesc,
  );
  String get personaCrisis => _getString(
    AppStrings.personaCrisis,
    AppStringsEn.personaCrisis,
    AppStringsFr.personaCrisis,
  );
  String get personaCrisisDesc => _getString(
    AppStrings.personaCrisisDesc,
    AppStringsEn.personaCrisisDesc,
    AppStringsFr.personaCrisisDesc,
  );
  String get personaMindfulness => _getString(
    AppStrings.personaMindfulness,
    AppStringsEn.personaMindfulness,
    AppStringsFr.personaMindfulness,
  );
  String get personaMindfulnessDesc => _getString(
    AppStrings.personaMindfulnessDesc,
    AppStringsEn.personaMindfulnessDesc,
    AppStringsFr.personaMindfulnessDesc,
  );
  String get pleaseLoginToContactSupport => _getString(
    AppStrings.pleaseLoginToContactSupport,
    AppStringsEn.pleaseLoginToContactSupport,
    AppStringsFr.pleaseLoginToContactSupport,
  );
  String get pleaseLoginToViewMessages => _getString(
    AppStrings.pleaseLoginToViewMessages,
    AppStringsEn.pleaseLoginToViewMessages,
    AppStringsFr.pleaseLoginToViewMessages,
  );
  String get pleaseWait => _getString(
    AppStrings.pleaseWait,
    AppStringsEn.pleaseWait,
    AppStringsFr.pleaseWait,
  );
  String get primaryComplaint => _getString(
    AppStrings.primaryComplaint,
    AppStringsEn.primaryComplaint,
    AppStringsFr.primaryComplaint,
  );
  String get refreshingSubscription => _getString(
    AppStrings.refreshingSubscription,
    AppStringsEn.refreshingSubscription,
    AppStringsFr.refreshingSubscription,
  );
  String get reportEmergency => _getString(
    AppStrings.reportEmergency,
    AppStringsEn.reportEmergency,
    AppStringsFr.reportEmergency,
  );
  String get reportGenerating => _getString(
    AppStrings.reportGenerating,
    AppStringsEn.reportGenerating,
    AppStringsFr.reportGenerating,
  );
  String get scheduled => _getString(
    AppStrings.scheduled,
    AppStringsEn.scheduled,
    AppStringsFr.scheduled,
  );
  String get searchPatients => _getString(
    AppStrings.searchPatients,
    AppStringsEn.searchPatients,
    AppStringsFr.searchPatients,
  );
  String get sendMessageSupportWillRespond => _getString(
    AppStrings.sendMessageSupportWillRespond,
    AppStringsEn.sendMessageSupportWillRespond,
    AppStringsFr.sendMessageSupportWillRespond,
  );
  String get sessionCompletedSuccessfully => _getString(
    AppStrings.sessionCompletedSuccessfully,
    AppStringsEn.sessionCompletedSuccessfully,
    AppStringsFr.sessionCompletedSuccessfully,
  );
  String get showLess => _getString(
    AppStrings.showLess,
    AppStringsEn.showLess,
    AppStringsFr.showLess,
  );
  String get showMore => _getString(
    AppStrings.showMore,
    AppStringsEn.showMore,
    AppStringsFr.showMore,
  );
  String get startConversation => _getString(
    AppStrings.startConversation,
    AppStringsEn.startConversation,
    AppStringsFr.startConversation,
  );
  String get startTheConversation => _getString(
    AppStrings.startTheConversation,
    AppStringsEn.startTheConversation,
    AppStringsFr.startTheConversation,
  );
  String get supportTeam => _getString(
    AppStrings.supportTeam,
    AppStringsEn.supportTeam,
    AppStringsFr.supportTeam,
  );
  String get supportWelcomeMessage => _getString(
    AppStrings.supportWelcomeMessage,
    AppStringsEn.supportWelcomeMessage,
    AppStringsFr.supportWelcomeMessage,
  );
  String get testTrajectory => _getString(
    AppStrings.testTrajectory,
    AppStringsEn.testTrajectory,
    AppStringsFr.testTrajectory,
  );
  String get therapistIsTyping => _getString(
    AppStrings.therapistIsTyping,
    AppStringsEn.therapistIsTyping,
    AppStringsFr.therapistIsTyping,
  );
  String get therapistWelcomeMessage => _getString(
    AppStrings.therapistWelcomeMessage,
    AppStringsEn.therapistWelcomeMessage,
    AppStringsFr.therapistWelcomeMessage,
  );
  String get therapistAssignmentWelcomeTemplate => _getString(
    AppStrings.therapistAssignmentWelcomeTemplate,
    AppStringsEn.therapistAssignmentWelcomeTemplate,
    AppStringsFr.therapistAssignmentWelcomeTemplate,
  );
  String get timeOfDay => _getString(
    AppStrings.timeOfDay,
    AppStringsEn.timeOfDay,
    AppStringsFr.timeOfDay,
  );
  String get titleInArabic => _getString(
    AppStrings.titleInArabic,
    AppStringsEn.titleInArabic,
    AppStringsFr.titleInArabic,
  );
  String get titleInEnglish => _getString(
    AppStrings.titleInEnglish,
    AppStringsEn.titleInEnglish,
    AppStringsFr.titleInEnglish,
  );
  String get titleInFrench => _getString(
    AppStrings.titleInFrench,
    AppStringsEn.titleInFrench,
    AppStringsFr.titleInFrench,
  );
  String get typeAMessage => _getString(
    AppStrings.typeAMessage,
    AppStringsEn.typeAMessage,
    AppStringsFr.typeAMessage,
  );
  String get typeYourMessage => _getString(
    AppStrings.typeYourMessage,
    AppStringsEn.typeYourMessage,
    AppStringsFr.typeYourMessage,
  );
  String get typingIndicator => _getString(
    AppStrings.typingIndicator,
    AppStringsEn.typingIndicator,
    AppStringsFr.typingIndicator,
  );
  String get unableToLoadMessages => _getString(
    AppStrings.unableToLoadMessages,
    AppStringsEn.unableToLoadMessages,
    AppStringsFr.unableToLoadMessages,
  );
  String get unblockUser => _getString(
    AppStrings.unblockUser,
    AppStringsEn.unblockUser,
    AppStringsFr.unblockUser,
  );
  String get unblockUserConfirm => _getString(
    AppStrings.unblockUserConfirm,
    AppStringsEn.unblockUserConfirm,
    AppStringsFr.unblockUserConfirm,
  );
  String get unlockChatAccess => _getString(
    AppStrings.unlockChatAccess,
    AppStringsEn.unlockChatAccess,
    AppStringsFr.unlockChatAccess,
  );
  String get unread => _getString(
    AppStrings.unread,
    AppStringsEn.unread,
    AppStringsFr.unread,
  );
  String get upgradeNow => _getString(
    AppStrings.upgradeNow,
    AppStringsEn.upgradeNow,
    AppStringsFr.upgradeNow,
  );
  String get upgradeToPremiumToReply => _getString(
    AppStrings.upgradeToPremiumToReply,
    AppStringsEn.upgradeToPremiumToReply,
    AppStringsFr.upgradeToPremiumToReply,
  );
  String get urgent => _getString(
    AppStrings.urgent,
    AppStringsEn.urgent,
    AppStringsFr.urgent,
  );
  String get userBlocked => _getString(
    AppStrings.userBlocked,
    AppStringsEn.userBlocked,
    AppStringsFr.userBlocked,
  );
  String get userDeleted => _getString(
    AppStrings.userDeleted,
    AppStringsEn.userDeleted,
    AppStringsFr.userDeleted,
  );
  String get userUnblocked => _getString(
    AppStrings.userUnblocked,
    AppStringsEn.userUnblocked,
    AppStringsFr.userUnblocked,
  );
  String get usuallyRespondsInHours => _getString(
    AppStrings.usuallyRespondsInHours,
    AppStringsEn.usuallyRespondsInHours,
    AppStringsFr.usuallyRespondsInHours,
  );
  String get viewBookings => _getString(
    AppStrings.viewBookings,
    AppStringsEn.viewBookings,
    AppStringsFr.viewBookings,
  );
  String get viewProfile => _getString(
    AppStrings.viewProfile,
    AppStringsEn.viewProfile,
    AppStringsFr.viewProfile,
  );
  String get weekendDip => _getString(
    AppStrings.weekendDip,
    AppStringsEn.weekendDip,
    AppStringsFr.weekendDip,
  );
  String get yearsOld => _getString(
    AppStrings.yearsOld,
    AppStringsEn.yearsOld,
    AppStringsFr.yearsOld,
  );
  String get yourTherapist => _getString(
    AppStrings.yourTherapist,
    AppStringsEn.yourTherapist,
    AppStringsFr.yourTherapist,
  );
  String get chooseAsMyTherapist => _getString(
    AppStrings.chooseAsMyTherapist,
    AppStringsEn.chooseAsMyTherapist,
    AppStringsFr.chooseAsMyTherapist,
  );
  String get switchToThisTherapist => _getString(
    AppStrings.switchToThisTherapist,
    AppStringsEn.switchToThisTherapist,
    AppStringsFr.switchToThisTherapist,
  );
  String get confirmChooseTherapistTitle => _getString(
    AppStrings.confirmChooseTherapistTitle,
    AppStringsEn.confirmChooseTherapistTitle,
    AppStringsFr.confirmChooseTherapistTitle,
  );
  String get confirmChooseTherapistBody => _getString(
    AppStrings.confirmChooseTherapistBody,
    AppStringsEn.confirmChooseTherapistBody,
    AppStringsFr.confirmChooseTherapistBody,
  );
  String get confirmSwitchTherapistTitle => _getString(
    AppStrings.confirmSwitchTherapistTitle,
    AppStringsEn.confirmSwitchTherapistTitle,
    AppStringsFr.confirmSwitchTherapistTitle,
  );
  String get confirmSwitchTherapistBody => _getString(
    AppStrings.confirmSwitchTherapistBody,
    AppStringsEn.confirmSwitchTherapistBody,
    AppStringsFr.confirmSwitchTherapistBody,
  );

  String get maintenanceTitle => _getString(
    AppStrings.maintenanceTitle,
    AppStringsEn.maintenanceTitle,
    AppStringsFr.maintenanceTitle,
  );

  String get maintenanceBody => _getString(
    AppStrings.maintenanceBody,
    AppStringsEn.maintenanceBody,
    AppStringsFr.maintenanceBody,
  );

  String get maintenanceEndedTitle => _getString(
    AppStrings.maintenanceEndedTitle,
    AppStringsEn.maintenanceEndedTitle,
    AppStringsFr.maintenanceEndedTitle,
  );

  String get maintenanceEndedBody => _getString(
    AppStrings.maintenanceEndedBody,
    AppStringsEn.maintenanceEndedBody,
    AppStringsFr.maintenanceEndedBody,
  );

  String get notifyWhenBack => _getString(
    AppStrings.notifyWhenBack,
    AppStringsEn.notifyWhenBack,
    AppStringsFr.notifyWhenBack,
  );

  String get notifySubscribed => _getString(
    AppStrings.notifySubscribed,
    AppStringsEn.notifySubscribed,
    AppStringsFr.notifySubscribed,
  );

  String get notifyAllOnMaintenanceEnd => _getString(
    AppStrings.notifyAllOnMaintenanceEnd,
    AppStringsEn.notifyAllOnMaintenanceEnd,
    AppStringsFr.notifyAllOnMaintenanceEnd,
  );

  String get maintenanceActive => _getString(
    AppStrings.maintenanceActive,
    AppStringsEn.maintenanceActive,
    AppStringsFr.maintenanceActive,
  );

  String get maintenanceWillBlockUsers => _getString(
    AppStrings.maintenanceWillBlockUsers,
    AppStringsEn.maintenanceWillBlockUsers,
    AppStringsFr.maintenanceWillBlockUsers,
  );

  // Force update screen
  String get forceUpdateTitle => _getString(
    AppStrings.forceUpdateTitle,
    AppStringsEn.forceUpdateTitle,
    AppStringsFr.forceUpdateTitle,
  );

  String get forceUpdateBody => _getString(
    AppStrings.forceUpdateBody,
    AppStringsEn.forceUpdateBody,
    AppStringsFr.forceUpdateBody,
  );

  String get forceUpdateButton => _getString(
    AppStrings.forceUpdateButton,
    AppStringsEn.forceUpdateButton,
    AppStringsFr.forceUpdateButton,
  );

  // App Gates section
  String get appGatesSectionTitle => _getString(
    AppStrings.appGatesSectionTitle,
    AppStringsEn.appGatesSectionTitle,
    AppStringsFr.appGatesSectionTitle,
  );

  String get appGatesSectionWarning => _getString(
    AppStrings.appGatesSectionWarning,
    AppStringsEn.appGatesSectionWarning,
    AppStringsFr.appGatesSectionWarning,
  );

  String get maintenanceEnableConfirmTitle => _getString(
    AppStrings.maintenanceEnableConfirmTitle,
    AppStringsEn.maintenanceEnableConfirmTitle,
    AppStringsFr.maintenanceEnableConfirmTitle,
  );

  String get maintenanceEnableConfirmBody => _getString(
    AppStrings.maintenanceEnableConfirmBody,
    AppStringsEn.maintenanceEnableConfirmBody,
    AppStringsFr.maintenanceEnableConfirmBody,
  );

  String get minVersionConfirmTitle => _getString(
    AppStrings.minVersionConfirmTitle,
    AppStringsEn.minVersionConfirmTitle,
    AppStringsFr.minVersionConfirmTitle,
  );

  String get minVersionConfirmBody => _getString(
    AppStrings.minVersionConfirmBody,
    AppStringsEn.minVersionConfirmBody,
    AppStringsFr.minVersionConfirmBody,
  );

  String get paymentTestMode => _getString(
    AppStrings.paymentTestMode,
    AppStringsEn.paymentTestMode,
    AppStringsFr.paymentTestMode,
  );

  String get paymentTestModeDesc => _getString(
    AppStrings.paymentTestModeDesc,
    AppStringsEn.paymentTestModeDesc,
    AppStringsFr.paymentTestModeDesc,
  );

  String get paymentTestEnableConfirmTitle => _getString(
    AppStrings.paymentTestEnableConfirmTitle,
    AppStringsEn.paymentTestEnableConfirmTitle,
    AppStringsFr.paymentTestEnableConfirmTitle,
  );

  String get paymentTestEnableConfirmBody => _getString(
    AppStrings.paymentTestEnableConfirmBody,
    AppStringsEn.paymentTestEnableConfirmBody,
    AppStringsFr.paymentTestEnableConfirmBody,
  );

  String get paypalVisibility => _getString(
    AppStrings.paypalVisibility,
    AppStringsEn.paypalVisibility,
    AppStringsFr.paypalVisibility,
  );

  String get paypalVisibilityDesc => _getString(
    AppStrings.paypalVisibilityDesc,
    AppStringsEn.paypalVisibilityDesc,
    AppStringsFr.paypalVisibilityDesc,
  );

  String get googlePayVisibility => _getString(
    AppStrings.googlePayVisibility,
    AppStringsEn.googlePayVisibility,
    AppStringsFr.googlePayVisibility,
  );

  String get googlePayVisibilityDesc => _getString(
    AppStrings.googlePayVisibilityDesc,
    AppStringsEn.googlePayVisibilityDesc,
    AppStringsFr.googlePayVisibilityDesc,
  );

  String get notifyUpdatePrompt => _getString(
    AppStrings.notifyUpdatePrompt,
    AppStringsEn.notifyUpdatePrompt,
    AppStringsFr.notifyUpdatePrompt,
  );

  String get notifyUpdateTitle => _getString(
    AppStrings.notifyUpdateTitle,
    AppStringsEn.notifyUpdateTitle,
    AppStringsFr.notifyUpdateTitle,
  );

  String get notifyUpdateBody => _getString(
    AppStrings.notifyUpdateBody,
    AppStringsEn.notifyUpdateBody,
    AppStringsFr.notifyUpdateBody,
  );

  String get notifyUpdateSent => _getString(
    AppStrings.notifyUpdateSent,
    AppStringsEn.notifyUpdateSent,
    AppStringsFr.notifyUpdateSent,
  );

  String get minVersionInvalid => _getString(
    AppStrings.minVersionInvalid,
    AppStringsEn.minVersionInvalid,
    AppStringsFr.minVersionInvalid,
  );

  String get currentPublishedVersion => _getString(
    AppStrings.currentPublishedVersion,
    AppStringsEn.currentPublishedVersion,
    AppStringsFr.currentPublishedVersion,
  );

  String get settingsLoadFailed => _getString(
    AppStrings.settingsLoadFailed,
    AppStringsEn.settingsLoadFailed,
    AppStringsFr.settingsLoadFailed,
  );

  String get settingsSaveFailed => _getString(
    AppStrings.settingsSaveFailed,
    AppStringsEn.settingsSaveFailed,
    AppStringsFr.settingsSaveFailed,
  );
}

/// Provider for localized strings
final stringsProvider = Provider<S>((ref) {
  final langState = ref.watch(languageProvider);
  return S(langState.language);
});
