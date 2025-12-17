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
  final bool isBookmarked;

  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.category,
    required this.createdAt,
    this.reactions = const {},
    this.userReactions = const {},
    this.comments = const [],
    this.isBookmarked = false,
  });

  int get totalReactions =>
      reactions.values.fold(0, (sum, count) => sum + count);
  int get commentCount => comments.length;

  Post copyWith({
    String? id,
    Author? author,
    String? content,
    PostCategory? category,
    DateTime? createdAt,
    Map<ReactionType, int>? reactions,
    Set<ReactionType>? userReactions,
    List<Comment>? comments,
    bool? isBookmarked,
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
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
