import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../repositories/community_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/providers/activity_log_provider.dart';
import '../../../core/l10n/language_provider.dart';

class CommunityState {
  final List<Post> posts;
  final PostCategory? selectedCategory;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMorePosts;
  final String? error;
  final DocumentSnapshot? lastDocument;

  const CommunityState({
    this.posts = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMorePosts = true,
    this.error,
    this.lastDocument,
  });

  List<Post> get filteredPosts {
    if (selectedCategory == null) return posts;
    return posts.where((p) => p.category == selectedCategory).toList();
  }

  CommunityState copyWith({
    List<Post>? posts,
    PostCategory? selectedCategory,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMorePosts,
    String? error,
    DocumentSnapshot? lastDocument,
    bool clearCategory = false,
    bool clearError = false,
    bool clearLastDocument = false,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMorePosts: hasMorePosts ?? this.hasMorePosts,
      error: clearError ? null : (error ?? this.error),
      lastDocument: clearLastDocument ? null : (lastDocument ?? this.lastDocument),
    );
  }
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  final CommunityRepository _repository;
  final Ref _ref;
  StreamSubscription? _subscription;
  static const int _pageSize = 20;

  CommunityNotifier(this._repository, this._ref)
    : super(const CommunityState()) {
    _init();
  }

  void _init() {
    state = state.copyWith(isLoading: true, clearError: true);
    _subscription = _repository.getPostsStream(limit: _pageSize).listen(
      (result) async {
        final posts = result.posts;
        final lastDoc = result.lastDocument;

        // Load user reactions and bookmarks for all posts
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser != null && posts.isNotEmpty) {
          final postIds = posts.map((p) => p.id).toList();

          // Load user reactions and bookmarks in parallel
          final results = await Future.wait([
            _repository.getUserReactionsForPosts(postIds, currentUser.uid),
            _repository.getUserBookmarks(currentUser.uid),
          ]);

          final userReactions = results[0] as Map<String, Set<ReactionType>>;
          final userBookmarks = results[1] as Set<String>;

          // Update posts with user's reactions and bookmarks
          final updatedPosts = posts.map((post) {
            final reactions = userReactions[post.id] ?? {};
            final isBookmarked = userBookmarks.contains(post.id);
            return post.copyWith(
              userReactions: reactions,
              isBookmarked: isBookmarked,
            );
          }).toList();

          state = state.copyWith(
            posts: updatedPosts,
            isLoading: false,
            lastDocument: lastDoc,
            hasMorePosts: posts.length >= _pageSize,
          );
        } else {
          state = state.copyWith(
            posts: posts,
            isLoading: false,
            lastDocument: lastDoc,
            hasMorePosts: posts.length >= _pageSize,
          );
        }
      },
      onError: (e) {
        final s = S(_ref.read(languageProvider).language);
        state = state.copyWith(
          isLoading: false,
          error: '${s.errorLoadingData}: $e',
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Refresh posts by re-subscribing to the stream
  void refreshPosts() {
    _subscription?.cancel();
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearLastDocument: true,
      hasMorePosts: true,
    );
    _init();
  }

  /// Load more posts for pagination
  Future<void> loadMorePosts() async {
    if (state.isLoadingMore || !state.hasMorePosts || state.lastDocument == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.getMorePosts(
        state.lastDocument!,
        limit: _pageSize,
      );

      final newPosts = result.posts;
      final lastDoc = result.lastDocument;

      // Load user reactions for new posts
      final currentUser = _ref.read(currentUserProvider);
      List<Post> updatedNewPosts = newPosts;

      if (currentUser != null && newPosts.isNotEmpty) {
        final postIds = newPosts.map((p) => p.id).toList();
        final userReactions = await _repository.getUserReactionsForPosts(
          postIds,
          currentUser.uid,
        );
        final userBookmarks = await _repository.getUserBookmarks(currentUser.uid);

        updatedNewPosts = newPosts.map((post) {
          final reactions = userReactions[post.id] ?? {};
          final isBookmarked = userBookmarks.contains(post.id);
          return post.copyWith(
            userReactions: reactions,
            isBookmarked: isBookmarked,
          );
        }).toList();
      }

      state = state.copyWith(
        posts: [...state.posts, ...updatedNewPosts],
        isLoadingMore: false,
        lastDocument: lastDoc,
        hasMorePosts: newPosts.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
      debugPrint('Error loading more posts: $e');
    }
  }

  void setCategory(PostCategory? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  Future<void> addPost(
    String content,
    PostCategory category, {
    bool isAnonymous = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final currentUser = _ref.read(currentUserProvider);

      await _repository.addPost(
        content,
        category,
        isAnonymous: isAnonymous,
        authorId: currentUser?.uid,
        authorName: currentUser?.displayName ?? 'User',
      );

      // Log activity
      try {
        if (currentUser != null) {
          await _ref
              .read(activityLogServiceProvider)
              .logPostCreated(
                userId: currentUser.uid,
                userName: currentUser.displayName ?? 'User',
              );
        }
      } catch (e, st) {
        debugPrint('Failed to log post activity: $e');
        debugPrintStack(stackTrace: st);
      }

      // Posts will automatically refresh via stream subscription
    } catch (e) {
      final s = S(_ref.read(languageProvider).language);
      state = state.copyWith(isLoading: false, error: '${s.errorOccurred}: $e');
    }
  }

  Future<void> toggleReaction(String postId, ReactionType reactionType) async {
    final currentUser = _ref.read(currentUserProvider);

    // Optimistic update
    final posts = state.posts.map((post) {
      if (post.id != postId) return post;

      final userReactions = Set<ReactionType>.from(post.userReactions);
      final reactions = Map<ReactionType, int>.from(post.reactions);
      final isAdding = !userReactions.contains(reactionType);

      if (!isAdding) {
        userReactions.remove(reactionType);
        reactions[reactionType] = (reactions[reactionType] ?? 1) - 1;
        if (reactions[reactionType] == 0) reactions.remove(reactionType);
      } else {
        userReactions.add(reactionType);
        reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;
      }

      // Fire and forget repo call with user info for notifications
      _repository.toggleReaction(
        postId,
        reactionType,
        isAdding,
        reactorId: currentUser?.uid,
        reactorName: currentUser?.displayName,
      );

      return post.copyWith(userReactions: userReactions, reactions: reactions);
    }).toList();

    state = state.copyWith(posts: posts);
  }

  Future<void> toggleBookmark(String postId) async {
    final user = _ref.read(authProvider).user;
    if (user == null) {
      final s = S(_ref.read(languageProvider).language);
      // Require authentication for bookmarks
      state = state.copyWith(error: s.loginRequired);
      return;
    }

    final posts = state.posts.map((post) {
      if (post.id != postId) return post;

      final isBookmarked = !post.isBookmarked;
      // Fire and forget repo call
      _repository.toggleBookmark(postId, user.uid, isBookmarked);

      return post.copyWith(isBookmarked: isBookmarked);
    }).toList();

    state = state.copyWith(posts: posts);
  }

  Future<void> addComment(String postId, String content) async {
    final user = _ref.read(authProvider).user;
    if (user == null) {
      final s = S(_ref.read(languageProvider).language);
      // Require authentication for comments
      state = state.copyWith(error: s.loginToComment);
      return;
    }

    // Fire and forget repo call
    await _repository.addComment(
      postId,
      content,
      authorId: user.uid,
      authorName: user.displayName ?? 'User',
    );

    // Optimistic update
    final posts = state.posts.map((post) {
      if (post.id != postId) return post;

      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        author: Author(id: user.uid, name: user.displayName ?? 'User'),
        content: content,
        createdAt: DateTime.now(),
      );

      return post.copyWith(comments: [...post.comments, newComment]);
    }).toList();

    state = state.copyWith(posts: posts);
  }
}

final communityProvider =
    StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
      final repository = ref.watch(communityRepositoryProvider);
      return CommunityNotifier(repository, ref);
    });

final postCommentsProvider = StreamProvider.family<List<Comment>, String>((
  ref,
  postId,
) {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getComments(postId);
});
