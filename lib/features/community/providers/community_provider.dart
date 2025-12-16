import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';

class CommunityState {
  final List<Post> posts;
  final PostCategory? selectedCategory;
  final bool isLoading;

  const CommunityState({
    this.posts = const [],
    this.selectedCategory,
    this.isLoading = false,
  });

  List<Post> get filteredPosts {
    if (selectedCategory == null) return posts;
    return posts.where((p) => p.category == selectedCategory).toList();
  }

  CommunityState copyWith({
    List<Post>? posts,
    PostCategory? selectedCategory,
    bool? isLoading,
    bool clearCategory = false,
  }) {
    return CommunityState(
      posts: posts ?? this.posts,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  CommunityNotifier() : super(const CommunityState()) {
    _loadSamplePosts();
  }

  void _loadSamplePosts() {
    final now = DateTime.now();

    final samplePosts = [
      Post(
        id: '1',
        author: const Author(
          id: 'user1',
          name: 'Sarah M.',
          isAnonymous: false,
        ),
        content: 'Today I finally managed to go outside for a walk after struggling with anxiety for weeks. Small steps matter! 🌱',
        category: PostCategory.anxiety,
        createdAt: now.subtract(const Duration(hours: 2)),
        reactions: {
          ReactionType.heart: 24,
          ReactionType.support: 18,
          ReactionType.strength: 12,
        },
        comments: [
          Comment(
            id: 'c1',
            author: const Author(id: 'user2', name: 'Ahmed K.'),
            content: 'So proud of you! Every step counts.',
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      Post(
        id: '2',
        author: const Author(
          id: 'user3',
          name: 'Anonymous',
          isAnonymous: true,
        ),
        content: 'Does anyone else feel like they\'re just going through the motions? I\'ve been feeling disconnected from everything lately. Would love to hear how others cope.',
        category: PostCategory.depression,
        createdAt: now.subtract(const Duration(hours: 5)),
        reactions: {
          ReactionType.hug: 31,
          ReactionType.relate: 28,
          ReactionType.support: 15,
        },
        comments: [
          Comment(
            id: 'c2',
            author: const Author(id: 'user4', name: 'Layla H.'),
            content: 'You\'re not alone in this. I find that small routines help me feel more grounded.',
            createdAt: now.subtract(const Duration(hours: 4)),
          ),
          Comment(
            id: 'c3',
            author: const Author(id: 'user5', name: 'Omar S.'),
            content: 'Journaling has helped me reconnect with my feelings. Sending you strength.',
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      Post(
        id: '3',
        author: const Author(
          id: 'user6',
          name: 'Nora A.',
        ),
        content: 'Reminder: It\'s okay to set boundaries with people you love. Your mental health comes first. 💙',
        category: PostCategory.selfCare,
        createdAt: now.subtract(const Duration(hours: 8)),
        reactions: {
          ReactionType.heart: 89,
          ReactionType.support: 42,
          ReactionType.strength: 37,
        },
      ),
      Post(
        id: '4',
        author: const Author(
          id: 'user7',
          name: 'Khalid R.',
        ),
        content: 'Just completed my first therapy session. I was so nervous but it went better than expected. If you\'re hesitant, just take that first step!',
        category: PostCategory.motivation,
        createdAt: now.subtract(const Duration(days: 1)),
        reactions: {
          ReactionType.heart: 156,
          ReactionType.support: 78,
          ReactionType.strength: 64,
        },
        comments: [
          Comment(
            id: 'c4',
            author: const Author(id: 'user8', name: 'Fatima J.'),
            content: 'This is so inspiring! I\'ve been putting it off for months.',
            createdAt: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),
      Post(
        id: '5',
        author: const Author(
          id: 'user9',
          name: 'Anonymous',
          isAnonymous: true,
        ),
        content: 'Having trouble communicating with my partner about my mental health struggles. They want to help but don\'t always understand. Any advice?',
        category: PostCategory.relationships,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        reactions: {
          ReactionType.hug: 22,
          ReactionType.relate: 45,
          ReactionType.support: 33,
        },
        comments: [
          Comment(
            id: 'c5',
            author: const Author(id: 'user10', name: 'Maha T.'),
            content: 'Try sharing articles or resources with them. Sometimes it helps when they can read about it from a professional perspective.',
            createdAt: now.subtract(const Duration(days: 1, hours: 2)),
          ),
        ],
      ),
      Post(
        id: '6',
        author: const Author(
          id: 'user11',
          name: 'Yusuf B.',
        ),
        content: 'Three things I\'m grateful for today:\n1. The warm sunshine\n2. A good cup of coffee\n3. This supportive community\n\nWhat are you grateful for?',
        category: PostCategory.general,
        createdAt: now.subtract(const Duration(days: 2)),
        reactions: {
          ReactionType.heart: 67,
          ReactionType.support: 23,
        },
      ),
    ];

    state = state.copyWith(posts: samplePosts);
  }

  void setCategory(PostCategory? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void addPost(String content, PostCategory category, {bool isAnonymous = false}) {
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: Author(
        id: 'current_user',
        name: isAnonymous ? 'Anonymous' : 'You',
        isAnonymous: isAnonymous,
      ),
      content: content,
      category: category,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(posts: [newPost, ...state.posts]);
  }

  void toggleReaction(String postId, ReactionType reactionType) {
    final posts = state.posts.map((post) {
      if (post.id != postId) return post;

      final userReactions = Set<ReactionType>.from(post.userReactions);
      final reactions = Map<ReactionType, int>.from(post.reactions);

      if (userReactions.contains(reactionType)) {
        userReactions.remove(reactionType);
        reactions[reactionType] = (reactions[reactionType] ?? 1) - 1;
        if (reactions[reactionType] == 0) reactions.remove(reactionType);
      } else {
        userReactions.add(reactionType);
        reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;
      }

      return post.copyWith(
        userReactions: userReactions,
        reactions: reactions,
      );
    }).toList();

    state = state.copyWith(posts: posts);
  }

  void toggleBookmark(String postId) {
    final posts = state.posts.map((post) {
      if (post.id != postId) return post;
      return post.copyWith(isBookmarked: !post.isBookmarked);
    }).toList();

    state = state.copyWith(posts: posts);
  }

  void addComment(String postId, String content) {
    final posts = state.posts.map((post) {
      if (post.id != postId) return post;

      final newComment = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        author: const Author(id: 'current_user', name: 'You'),
        content: content,
        createdAt: DateTime.now(),
      );

      return post.copyWith(comments: [...post.comments, newComment]);
    }).toList();

    state = state.copyWith(posts: posts);
  }
}

final communityProvider = StateNotifierProvider<CommunityNotifier, CommunityState>(
  (ref) => CommunityNotifier(),
);
