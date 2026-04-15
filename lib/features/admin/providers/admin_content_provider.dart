import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cms_models.dart';

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

  Future<void> addQuote(DailyQuote quote) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('daily_quotes').add(quote.toMap());
      await loadQuotes(); // Refresh
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateQuote(DailyQuote quote) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore
          .collection('daily_quotes')
          .doc(quote.id)
          .update(quote.toMap());
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

  Future<void> addContent(AppContent content) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('content').add(content.toMap());
      await loadContent();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteContent(String contentId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('content').doc(contentId).delete();
      await loadContent();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateContent(AppContent content) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore
          .collection('content')
          .doc(content.id)
          .update(content.toMap());
      await loadContent();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- Daily Challenges ---

  Future<void> loadChallenges() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snapshot = await _firestore
          .collection('daily_challenges')
          .orderBy('order')
          .get();
      final challenges = snapshot.docs
          .map((doc) => DailyChallenge.fromFirestore(doc))
          .toList();
      state = state.copyWith(isLoading: false, challenges: challenges);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addChallenge(DailyChallenge challenge) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore.collection('daily_challenges').add(challenge.toMap());
      await loadChallenges();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateChallenge(DailyChallenge challenge) async {
    state = state.copyWith(isLoading: true);
    try {
      await _firestore
          .collection('daily_challenges')
          .doc(challenge.id)
          .update(challenge.toMap());
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
