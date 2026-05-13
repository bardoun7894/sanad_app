import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/language_provider.dart';

enum PostCategory {
  general,
  anxiety,
  depression,
  relationships,
  selfCare,
  motivation,
}

class PostCategoryData {
  static String getLabel(PostCategory category, {S? strings}) {
    final s = strings;
    return switch (category) {
      PostCategory.general => s?.categoryGeneral ?? 'General',
      PostCategory.anxiety => s?.categoryAnxiety ?? 'Anxiety',
      PostCategory.depression => s?.categoryDepression ?? 'Depression',
      PostCategory.relationships => s?.categoryRelationships ?? 'Relationships',
      PostCategory.selfCare => s?.categorySelfCare ?? 'Self Care',
      PostCategory.motivation => s?.categoryMotivation ?? 'Motivation',
    };
  }

  static IconData getIcon(PostCategory category) {
    return switch (category) {
      PostCategory.general => Icons.chat_bubble_outline_rounded,
      PostCategory.anxiety => Icons.psychology_outlined,
      PostCategory.depression => Icons.cloud_outlined,
      PostCategory.relationships => Icons.favorite_outline_rounded,
      PostCategory.selfCare => Icons.spa_outlined,
      PostCategory.motivation => Icons.lightbulb_outline_rounded,
    };
  }

  static Color getColor(PostCategory category) {
    return switch (category) {
      PostCategory.general => AppColors.primary,
      PostCategory.anxiety => AppColors.moodAnxious,
      PostCategory.depression => AppColors.moodSad,
      PostCategory.relationships => const Color(0xFFEC4899),
      PostCategory.selfCare => AppColors.moodCalm,
      PostCategory.motivation => AppColors.moodHappy,
    };
  }

  static Color getIconColor(PostCategory category) {
    return switch (category) {
      PostCategory.general => AppColors.primary,
      PostCategory.anxiety => AppColors.moodAnxiousIcon,
      PostCategory.depression => AppColors.moodSadIcon,
      PostCategory.relationships => const Color(0xFFEC4899),
      PostCategory.selfCare => AppColors.moodCalmIcon,
      PostCategory.motivation => AppColors.moodHappyIcon,
    };
  }
}

enum ReactionType { heart, support, hug, strength, relate }

class ReactionData {
  static String getEmoji(ReactionType type) {
    return switch (type) {
      ReactionType.heart => '❤️',
      ReactionType.support => '🙏',
      ReactionType.hug => '🤗',
      ReactionType.strength => '💪',
      ReactionType.relate => '🤝',
    };
  }

  static String getLabel(ReactionType type, {S? strings}) {
    final s = strings;
    return switch (type) {
      ReactionType.heart => s?.reactionLove ?? 'Love',
      ReactionType.support => s?.reactionSupport ?? 'Support',
      ReactionType.hug => s?.reactionHug ?? 'Hug',
      ReactionType.strength => s?.reactionStrength ?? 'Strength',
      ReactionType.relate => s?.reactionRelate ?? 'Relate',
    };
  }
}

class Author {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isAnonymous;

  const Author({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isAnonymous = false,
  });

  String get displayName => isAnonymous ? 'Anonymous' : name;
  factory Author.fromMap(Map<String, dynamic> map) {
    return Author(
      id: map['id'] ?? map['author_id'] ?? '',
      name: map['name'] ?? map['author_name'] ?? '',
      avatarUrl: map['avatar_url'],
      isAnonymous: map['is_anonymous'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'is_anonymous': isAnonymous,
    };
  }
}

class Comment {
  final String id;
  final Author author;
  final String content;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] ?? '',
      author: Author.fromMap(map['author'] ?? {}),
      content: map['content'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment.fromMap(data..['id'] = doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author': author.toMap(),
      'content': content,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

class Post {
  final String id;
  final Author author;
  final String content;
  final PostCategory category;
  final DateTime createdAt;
  final Map<ReactionType, int> reactions;
  final Set<ReactionType> userReactions;
  final List<Comment> comments;
  final int commentsCount;
  final bool isBookmarked;
  final int reportCount;

  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.category,
    required this.createdAt,
    this.reactions = const {},
    this.userReactions = const {},
    this.comments = const [],
    this.commentsCount = 0,
    this.isBookmarked = false,
    this.reportCount = 0,
  });

  int get totalReactions =>
      reactions.values.fold(0, (sum, count) => sum + count);
  int get commentCount => commentsCount > 0 ? commentsCount : comments.length;

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse reactions map: { 'heart': 5, 'hug': 2 }
    final reactionsData = data['reactions'] as Map<String, dynamic>? ?? {};
    final reactions = <ReactionType, int>{};
    reactionsData.forEach((key, value) {
      if (value is int && value > 0) {
        try {
          final type = ReactionType.values.firstWhere((e) => e.name == key);
          reactions[type] = value;
        } catch (_) {
          // Ignore unknown reaction types
        }
      }
    });

    return Post(
      id: doc.id,
      author: Author(
        id: data['author_id'] ?? 'unknown',
        name: data['author_name'] ?? 'Unknown',
        isAnonymous: data['is_anonymous'] ?? false,
        avatarUrl: data['author_avatar'],
      ),
      content: data['content'] ?? '',
      category: PostCategory.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (data['category'] as String? ?? '').toLowerCase(),
        orElse: () => PostCategory.general,
      ),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportCount: data['report_count'] ?? 0,
      reactions: reactions,
      commentsCount: data['comments_count'] ?? 0,
      // userReactions and comments are loaded separately by the provider/repo
      userReactions: const {},
      comments: const [],
      isBookmarked: false,
    );
  }

  // Adapted fromFirestore to match Seed Data structure
  factory Post.fromSeedData(Map<String, dynamic> data, String id) {
    return Post(
      id: id,
      author: Author(
        id: data['author_id'] ?? 'unknown',
        name: data['author_name'] ?? 'Unknown',
        isAnonymous: data['is_anonymous'] ?? false,
      ),
      content: data['content'] ?? '',
      category: PostCategory.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (data['category'] as String? ?? '').toLowerCase(),
        orElse: () => PostCategory.general,
      ),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reportCount: data['report_count'] ?? 0,
      commentsCount: data['comments_count'] ?? 0,
    );
  }

  Post copyWith({
    String? id,
    Author? author,
    String? content,
    PostCategory? category,
    DateTime? createdAt,
    Map<ReactionType, int>? reactions,
    Set<ReactionType>? userReactions,
    List<Comment>? comments,
    int? commentsCount,
    bool? isBookmarked,
    int? reportCount,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      reactions: reactions ?? this.reactions,
      userReactions: userReactions ?? this.userReactions,
      comments: comments ?? this.comments,
      commentsCount: commentsCount ?? this.commentsCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      reportCount: reportCount ?? this.reportCount,
    );
  }
}
