import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/community/models/post.dart';

void main() {
  final now = DateTime(2026, 2, 15, 10, 30);

  group('Author', () {
    test('creates with required fields', () {
      const author = Author(id: 'author-1', name: 'Test User');

      expect(author.id, 'author-1');
      expect(author.name, 'Test User');
      expect(author.avatarUrl, isNull);
      expect(author.isAnonymous, isFalse);
    });

    test('displayName returns name for non-anonymous', () {
      const author = Author(id: 'author-1', name: 'Test User');

      expect(author.displayName, 'Test User');
    });

    test('displayName returns Anonymous for anonymous', () {
      const author = Author(
        id: 'author-1',
        name: 'Test User',
        isAnonymous: true,
      );

      expect(author.displayName, 'Anonymous');
    });

    test('toMap serializes correctly', () {
      const author = Author(
        id: 'author-1',
        name: 'Test',
        avatarUrl: 'https://example.com/avatar.png',
        isAnonymous: true,
      );

      final map = author.toMap();

      expect(map['id'], 'author-1');
      expect(map['name'], 'Test');
      expect(map['avatar_url'], 'https://example.com/avatar.png');
      expect(map['is_anonymous'], true);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 'author-1',
        'name': 'Test',
        'avatar_url': 'https://example.com/avatar.png',
        'is_anonymous': false,
      };

      final author = Author.fromMap(map);

      expect(author.id, 'author-1');
      expect(author.name, 'Test');
      expect(author.isAnonymous, isFalse);
    });
  });

  group('Post', () {
    final testAuthor = Author(id: 'a1', name: 'Author');

    test('creates with required fields', () {
      final post = Post(
        id: 'post-1',
        author: testAuthor,
        content: 'Test content',
        category: PostCategory.general,
        createdAt: now,
      );

      expect(post.id, 'post-1');
      expect(post.content, 'Test content');
      expect(post.category, PostCategory.general);
      expect(post.totalReactions, 0);
      expect(post.commentCount, 0);
      expect(post.isBookmarked, isFalse);
      expect(post.reportCount, 0);
    });

    test('totalReactions sums all reactions', () {
      final post = Post(
        id: 'post-1',
        author: testAuthor,
        content: 'Test',
        category: PostCategory.general,
        createdAt: now,
        reactions: {
          ReactionType.heart: 5,
          ReactionType.hug: 3,
          ReactionType.support: 2,
        },
      );

      expect(post.totalReactions, 10);
    });

    test('commentCount prefers commentsCount over list length', () {
      final post = Post(
        id: 'post-1',
        author: testAuthor,
        content: 'Test',
        category: PostCategory.general,
        createdAt: now,
        commentsCount: 10,
      );

      expect(post.commentCount, 10);
    });

    test('copyWith creates updated copy', () {
      final post = Post(
        id: 'post-1',
        author: testAuthor,
        content: 'Original',
        category: PostCategory.general,
        createdAt: now,
      );

      final updated = post.copyWith(
        content: 'Updated',
        category: PostCategory.anxiety,
        isBookmarked: true,
      );

      expect(updated.content, 'Updated');
      expect(updated.category, PostCategory.anxiety);
      expect(updated.isBookmarked, isTrue);
      expect(updated.id, 'post-1');
      expect(post.content, 'Original');
    });
  });

  group('PostCategory', () {
    test('has expected values', () {
      expect(PostCategory.values.length, 6);
      expect(PostCategory.general.name, 'general');
      expect(PostCategory.anxiety.name, 'anxiety');
      expect(PostCategory.depression.name, 'depression');
      expect(PostCategory.relationships.name, 'relationships');
      expect(PostCategory.selfCare.name, 'selfCare');
      expect(PostCategory.motivation.name, 'motivation');
    });
  });

  group('ReactionType', () {
    test('has expected values', () {
      expect(ReactionType.values.length, 5);
      expect(ReactionType.heart.name, 'heart');
      expect(ReactionType.support.name, 'support');
      expect(ReactionType.hug.name, 'hug');
      expect(ReactionType.strength.name, 'strength');
      expect(ReactionType.relate.name, 'relate');
    });
  });

  group('ReactionData', () {
    test('getEmoji returns correct emoji', () {
      expect(ReactionData.getEmoji(ReactionType.heart), '❤️');
      expect(ReactionData.getEmoji(ReactionType.support), '🙏');
      expect(ReactionData.getEmoji(ReactionType.hug), '🤗');
      expect(ReactionData.getEmoji(ReactionType.strength), '💪');
      expect(ReactionData.getEmoji(ReactionType.relate), '🤝');
    });

    test('getLabel returns English default', () {
      expect(ReactionData.getLabel(ReactionType.heart), 'Love');
      expect(ReactionData.getLabel(ReactionType.support), 'Support');
      expect(ReactionData.getLabel(ReactionType.hug), 'Hug');
      expect(ReactionData.getLabel(ReactionType.strength), 'Strength');
      expect(ReactionData.getLabel(ReactionType.relate), 'Relate');
    });
  });

  group('PostCategoryData', () {
    test('getLabel returns English default', () {
      expect(PostCategoryData.getLabel(PostCategory.general), 'General');
      expect(PostCategoryData.getLabel(PostCategory.anxiety), 'Anxiety');
      expect(PostCategoryData.getLabel(PostCategory.selfCare), 'Self Care');
    });
  });
}
