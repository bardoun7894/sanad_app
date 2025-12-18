import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_strings.dart';
import 'app_strings_en.dart';
import 'app_strings_fr.dart';

enum AppLanguage { arabic, english, french }

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
  LanguageNotifier() : super(LanguageState.arabic()); // Default to Arabic

  void setLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.arabic:
        state = LanguageState.arabic();
        break;
      case AppLanguage.english:
        state = LanguageState.english();
        break;
      case AppLanguage.french:
        state = LanguageState.french();
        break;
    }
  }

  void toggleLanguage() {
    if (state.language == AppLanguage.arabic) {
      state = LanguageState.english();
    } else {
      state = LanguageState.arabic();
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>(
  (ref) => LanguageNotifier(),
);

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
  String get contactSupport => _getString(
    AppStrings.contactSupport,
    AppStringsEn.contactSupport,
    AppStringsFr.contactSupport,
  );
  String get getHelpFromTeam => _getString(
    AppStrings.getHelpFromTeam,
    AppStringsEn.getHelpFromTeam,
    AppStringsFr.getHelpFromTeam,
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

  // Sample data
  String get sampleQuote => _getString(
    AppStrings.sampleQuote,
    AppStringsEn.sampleQuote,
    AppStringsFr.sampleQuote,
  );
  String get sampleQuoteAuthor => _getString(
    AppStrings.sampleQuoteAuthor,
    AppStringsEn.sampleQuoteAuthor,
    AppStringsFr.sampleQuoteAuthor,
  );
  String get sampleUserName => _getString(
    AppStrings.sampleUserName,
    AppStringsEn.sampleUserName,
    AppStringsFr.sampleUserName,
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
  String get completedStatus => _getString(
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
  String get premiumFeatures => _getString(
    AppStrings.premiumFeatures,
    AppStringsEn.premiumFeatures,
    AppStringsFr.premiumFeatures,
  );
  String get unlimitedSessions => _getString(
    AppStrings.unlimitedSessions,
    AppStringsEn.unlimitedSessions,
    AppStringsFr.unlimitedSessions,
  );
  String get prioritySupport => _getString(
    AppStrings.prioritySupport,
    AppStringsEn.prioritySupport,
    AppStringsFr.prioritySupport,
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
  String get payNow => _getString(
    AppStrings.payNow,
    AppStringsEn.payNow,
    AppStringsFr.payNow,
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
  String get all => _getString(
    AppStrings.all,
    AppStringsEn.all,
    AppStringsFr.all,
  );
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
  String get amount => _getString(
    AppStrings.amount,
    AppStringsEn.amount,
    AppStringsFr.amount,
  );
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
  String get reject => _getString(
    AppStrings.reject,
    AppStringsEn.reject,
    AppStringsFr.reject,
  );
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
  String get reason => _getString(
    AppStrings.reason,
    AppStringsEn.reason,
    AppStringsFr.reason,
  );
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
  String get userId => _getString(
    AppStrings.userId,
    AppStringsEn.userId,
    AppStringsFr.userId,
  );
  String get userName => _getString(
    AppStrings.name,
    AppStringsEn.name,
    AppStringsFr.name,
  );
}

/// Provider for localized strings
final stringsProvider = Provider<S>((ref) {
  final langState = ref.watch(languageProvider);
  return S(langState.language);
});
