import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../../notifications/services/notification_service.dart';
import '../../admin/providers/activity_log_provider.dart';

final communityRepositoryProvider = Provider((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return CommunityRepository(notificationService: notificationService);
});

/// Result class for paginated post queries
class PostsQueryResult {
  final List<Post> posts;
  final DocumentSnapshot? lastDocument;

  const PostsQueryResult({required this.posts, this.lastDocument});
}

class CommunityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService;
  final ActivityLogService _activityLogService = ActivityLogService();

  CommunityRepository({required NotificationService notificationService})
    : _notificationService = notificationService;

  /// Stream posts with pagination limit
  Stream<PostsQueryResult> getPostsStream({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs.map((doc) {
            return Post.fromFirestore(doc);
          }).toList();
          return PostsQueryResult(
            posts: posts,
            lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
          );
        });
  }

  /// Get more posts after the last document (cursor-based pagination)
  Future<PostsQueryResult> getMorePosts(
    DocumentSnapshot lastDocument, {
    int limit = 20,
  }) async {
    try {
      final query = await _firestore
          .collection('posts')
          .orderBy('created_at', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit)
          .get();

      final posts = query.docs.map((doc) {
        return Post.fromFirestore(doc);
      }).toList();

      return PostsQueryResult(
        posts: posts,
        lastDocument: query.docs.isNotEmpty ? query.docs.last : null,
      );
    } catch (e) {
      debugPrint('Error fetching more posts: $e');
      return const PostsQueryResult(posts: []);
    }
  }

  Future<List<Post>> getPosts() async {
    try {
      final query = await _firestore
          .collection('posts')
          .orderBy('created_at', descending: true)
          .get();

      return query.docs.map((doc) {
        return Post.fromFirestore(doc);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  Future<void> addPost(
    String content,
    PostCategory category, {
    bool isAnonymous = false,
    String? authorId,
    String? authorName,
  }) async {
    await _firestore.collection('posts').add({
      'content': content,
      'category': category.name, // Enum name (e.g., 'anxiety')
      'is_anonymous': isAnonymous,
      'author_id': authorId ?? 'unknown',
      'author_name': authorName ?? 'Unknown',
      'created_at': FieldValue.serverTimestamp(),
      'report_count': 0,
      'comments_count': 0,
      'reactions': {},
    });

    // Log activity (only if not anonymous for privacy)
    if (!isAnonymous && authorId != null && authorName != null) {
      try {
        await _activityLogService.logPostCreated(
          userId: authorId,
          userName: authorName,
        );
      } catch (e) {
        // Silently fail - activity logging shouldn't break post creation
        debugPrint('Failed to log post activity: $e');
      }
    }
  }

  Future<void> addComment(
    String postId,
    String content, {
    String authorId = 'unknown',
    String authorName = 'Unknown',
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);

    // Add the comment and update counter atomically
    final batch = _firestore.batch();
    final commentRef = postRef.collection('comments').doc();
    batch.set(commentRef, {
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {
      'comments_count': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    // Send notification to post author
    try {
      final postDoc = await postRef.get();
      if (postDoc.exists) {
        final postAuthorId = postDoc.data()?['author_id'] as String?;
        final isAnonymous = postDoc.data()?['is_anonymous'] as bool? ?? false;

        // Only notify if:
        // 1. Post author exists
        // 2. Commenter is not the post author
        // 3. Post is not anonymous (privacy consideration)
        if (postAuthorId != null && postAuthorId != authorId && !isAnonymous) {
          await _notificationService.createCommunityNotification(
            userId: postAuthorId,
            title: 'New comment on your post',
            body:
                '$authorName commented: "${content.length > 50 ? '${content.substring(0, 50)}...' : content}"',
            postId: postId,
            commenterId: authorId,
            isComment: true,
          );
        }
      }
    } catch (e) {
      // Don't fail the comment if notification fails
      debugPrint('Failed to send comment notification: $e');
    }
  }

  Future<void> toggleReaction(
    String postId,
    ReactionType reactionType,
    bool isAdding, {
    String? reactorId,
    String? reactorName,
  }) async {
    if (reactorId == null) return;

    // Update global count on post document
    final field = 'reactions.${reactionType.name}';
    await _firestore.collection('posts').doc(postId).update({
      field: FieldValue.increment(isAdding ? 1 : -1),
    });

    // Persist user's reaction in subcollection for per-user tracking
    final userReactionRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('user_reactions')
        .doc(reactorId);

    if (isAdding) {
      // Add this reaction type to user's reactions
      await userReactionRef.set({
        'reactions': FieldValue.arrayUnion([reactionType.name]),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Remove this reaction type from user's reactions
      await userReactionRef.set({
        'reactions': FieldValue.arrayRemove([reactionType.name]),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Send notification only when adding a reaction
    if (isAdding) {
      try {
        final postDoc = await _firestore.collection('posts').doc(postId).get();
        if (postDoc.exists) {
          final postAuthorId = postDoc.data()?['author_id'] as String?;
          final isAnonymous = postDoc.data()?['is_anonymous'] as bool? ?? false;

          // Only notify if:
          // 1. Post author exists
          // 2. Reactor is not the post author
          // 3. Post is not anonymous (privacy consideration)
          if (postAuthorId != null &&
              postAuthorId != reactorId &&
              !isAnonymous) {
            final reactionEmoji = _getReactionEmoji(reactionType);
            await _notificationService.createCommunityNotification(
              userId: postAuthorId,
              title: 'New reaction on your post',
              body:
                  '${reactorName ?? 'Someone'} reacted $reactionEmoji to your post',
              postId: postId,
              reactorId: reactorId,
              isComment: false,
            );
          }
        }
      } catch (e) {
        // Don't fail the reaction if notification fails
        debugPrint('Failed to send reaction notification: $e');
      }
    }
  }

  /// Get user's reactions for a specific post
  Future<Set<ReactionType>> getUserReactions(
    String postId,
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('user_reactions')
          .doc(userId)
          .get();

      if (!doc.exists) return {};

      final reactions = doc.data()?['reactions'] as List<dynamic>? ?? [];
      return reactions
          .map(
            (r) => ReactionType.values.firstWhere(
              (type) => type.name == r,
              orElse: () => ReactionType.heart,
            ),
          )
          .toSet();
    } catch (e) {
      debugPrint('Error getting user reactions: $e');
      return {};
    }
  }

  /// Get user's reactions for multiple posts (batch - parallel)
  Future<Map<String, Set<ReactionType>>> getUserReactionsForPosts(
    List<String> postIds,
    String userId,
  ) async {
    final result = <String, Set<ReactionType>>{};

    try {
      // Execute all reads in parallel instead of sequentially
      final futures = postIds.map((postId) async {
        final reactions = await getUserReactions(postId, userId);
        return MapEntry(postId, reactions);
      });

      final entries = await Future.wait(futures);
      for (final entry in entries) {
        result[entry.key] = entry.value;
      }
    } catch (e) {
      debugPrint('Error getting user reactions for posts: $e');
    }

    return result;
  }

  /// Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting comment count: $e');
      return 0;
    }
  }

  String _getReactionEmoji(ReactionType type) {
    switch (type) {
      case ReactionType.heart:
        return '❤️';
      case ReactionType.support:
        return '🙏';
      case ReactionType.hug:
        return '🤗';
      case ReactionType.strength:
        return '💪';
      case ReactionType.relate:
        return '🤝';
    }
  }

  Stream<List<Comment>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList(),
        );
  }

  Future<void> toggleBookmark(
    String postId,
    String userId,
    bool isBookmarked,
  ) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(postId);

    if (isBookmarked) {
      await docRef.set({
        'added_at': FieldValue.serverTimestamp(),
        'post_id': postId,
      });
    } else {
      await docRef.delete();
    }
  }

  /// Get user's bookmarked post IDs
  Future<Set<String>> getUserBookmarks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint('Error getting user bookmarks: $e');
      return {};
    }
  }
}
