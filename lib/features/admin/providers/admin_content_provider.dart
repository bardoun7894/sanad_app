import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/cms_models.dart';
import '../services/admin_chat_service.dart';

class AdminContentState {
  final bool isLoading;
  final String? error;
  final List<DailyQuote> quotes;
  final List<AppContent> contentList;
  final List<DailyChallenge> challenges;

  const AdminContentState({
    this.isLoading = false,
    this.error,
    this.quotes = const [],
    this.contentList = const [],
    this.challenges = const [],
  });

  AdminContentState copyWith({
    bool? isLoading,
    String? error,
    List<DailyQuote>? quotes,
    List<AppContent>? contentList,
    List<DailyChallenge>? challenges,
  }) {
    return AdminContentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      quotes: quotes ?? this.quotes,
      contentList: contentList ?? this.contentList,
      challenges: challenges ?? this.challenges,
    );
  }
}

class AdminContentNotifier extends StateNotifier<AdminContentState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminContentNotifier() : super(const AdminContentState());

  /// Bump the shared content-revision doc so user-app listeners refetch.
  /// Best-effort — never throws upward.
  Future<void> _bumpContentRevision() async {
    try {
      await _firestore.collection('meta').doc('content_revision').set({
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Never break a write because the signaling doc failed.
    }
  }

  /// Broadcast a content-event notification to every user.
  ///
  /// Best-effort: a failure here never aborts the underlying write. Used
  /// from the add*/update* flows when the admin opted in via the
  /// "Notify all users" checkbox on the form.
  Future<void> _maybeBroadcast({
    required bool notify,
    required String title,
    required String body,
    String? actionRoute,
  }) async {
    if (!notify) return;
    try {
      await AdminChatService().broadcastNotificationToAllUsers(
        title: title,
        body: body,
        actionRoute: actionRoute,
      );
    } catch (e) {
      debugPrint('[AdminContent] notification broadcast failed: $e');
    }
  }

  // --- Quotes ---

  Future<void> loadQuotes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snapshot = await _firestore
          .collection('daily_quotes')
          .orderBy('publish_date', descending: true)
          .get();
      final quotes = snapshot.docs
          .map((doc) => DailyQuote.fromFirestore(doc))
          .toList();
      state = state.copyWith(isLoading: false, quotes: quotes);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addQuote(DailyQuote quote, {bool notifyUsers = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('daily_quotes').add(quote.toMap());
      await _maybeBroadcast(
        notify: notifyUsers,
        title: 'اقتباس جديد',
        body: quote.text,
        actionRoute: '/home',
      );
      await loadQuotes(); // Refresh
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateQuote(DailyQuote quote, {bool notifyUsers = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore
          .collection('daily_quotes')
          .doc(quote.id)
          .update(quote.toMap());
      await _maybeBroadcast(
        notify: notifyUsers,
        title: 'تحديث الاقتباس',
        body: quote.text,
        actionRoute: '/home',
      );
      await loadQuotes();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteQuote(String quoteId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('daily_quotes').doc(quoteId).delete();
      await loadQuotes();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- Content (Articles/Recommendations) ---

  Future<void> loadContent() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snapshot = await _firestore
          .collection('content')
          .orderBy('created_at', descending: true)
          .get();
      final content = snapshot.docs
          .map((doc) => AppContent.fromFirestore(doc))
          .toList();
      state = state.copyWith(isLoading: false, contentList: content);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addContent(AppContent content, {bool notifyUsers = false}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('content').add(content.toMap());
      await _bumpContentRevision();
      await _maybeBroadcast(
        notify: notifyUsers,
        title: _newContentTitle(content),
        body: content.title,
        actionRoute: _routeForContent(content),
      );
      await loadContent();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteContent(String contentId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('content').doc(contentId).delete();
      await _bumpContentRevision();
      await loadContent();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateContent(
    AppContent content, {
    bool notifyUsers = false,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore
          .collection('content')
          .doc(content.id)
          .update(content.toMap());
      await _bumpContentRevision();
      await _maybeBroadcast(
        notify: notifyUsers,
        title: _updateContentTitle(content),
        body: content.title,
        actionRoute: _routeForContent(content),
      );
      await loadContent();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  String _newContentTitle(AppContent c) {
    switch (c.type) {
      case ContentType.article:
        return 'مقال جديد';
      case ContentType.exercise:
        return 'تمرين جديد';
      case ContentType.video:
        return 'فيديو جديد';
    }
  }

  String _updateContentTitle(AppContent c) {
    switch (c.type) {
      case ContentType.article:
        return 'تم تحديث مقال';
      case ContentType.exercise:
        return 'تم تحديث تمرين';
      case ContentType.video:
        return 'تم تحديث فيديو';
    }
  }

  String _routeForContent(AppContent c) {
    switch (c.type) {
      case ContentType.article:
        return '/blog';
      case ContentType.exercise:
        return '/exercises';
      case ContentType.video:
        return '/sanad-tube';
    }
  }

  // --- Daily Challenges ---

  Future<void> loadChallenges() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Do NOT use orderBy('order') in the query: Firestore silently drops
      // documents missing the field, which hid every seeded challenge that
      // lacked an `order` value from the admin list. Fetch all and sort
      // client-side instead (fromFirestore reads a missing `order` as 0, so
      // unordered seeds cluster first; tiebreak by id for stable display).
      final snapshot = await _firestore.collection('daily_challenges').get();
      final challenges = snapshot.docs
          .map((doc) => DailyChallenge.fromFirestore(doc))
          .toList()
        ..sort((a, b) {
          if (a.order != b.order) return a.order.compareTo(b.order);
          return a.id.compareTo(b.id);
        });
      state = state.copyWith(isLoading: false, challenges: challenges);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addChallenge(
    DailyChallenge challenge, {
    bool notifyUsers = false,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('daily_challenges').add(challenge.toMap());
      await _maybeBroadcast(
        notify: notifyUsers,
        title: 'تحدٍ جديد',
        body: challenge.title,
        actionRoute: '/home',
      );
      await loadChallenges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateChallenge(
    DailyChallenge challenge, {
    bool notifyUsers = false,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore
          .collection('daily_challenges')
          .doc(challenge.id)
          .update(challenge.toMap());
      await _maybeBroadcast(
        notify: notifyUsers,
        title: 'تم تحديث التحدي',
        body: challenge.title,
        actionRoute: '/home',
      );
      await loadChallenges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('daily_challenges').doc(challengeId).delete();
      await loadChallenges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load all content types at once
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        loadQuotes(),
        loadContent(),
        loadChallenges(),
      ]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminContentProvider =
    StateNotifierProvider<AdminContentNotifier, AdminContentState>((ref) {
      return AdminContentNotifier();
    });
