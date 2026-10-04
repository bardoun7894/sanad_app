import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../community/models/post.dart';

class AdminCommunityState {
  final bool isLoading;
  final String? error;
  final List<Post> posts;

  const AdminCommunityState({
    this.isLoading = false,
    this.error,
    this.posts = const [],
  });

  AdminCommunityState copyWith({
    bool? isLoading,
    String? error,
    List<Post>? posts,
  }) {
    return AdminCommunityState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      posts: posts ?? this.posts,
    );
  }
}

class AdminCommunityNotifier extends StateNotifier<AdminCommunityState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminCommunityNotifier() : super(const AdminCommunityState()) {
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Fetch recent 50 posts for moderation for now, as no flag system exists
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      final posts = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              // Manual mapping because Post model might not have fromFirestore or it might be internal to the feature
              // Checking Post model from previous view_file...
              // Post model is simple data class, no fromFirestore factory shown in view_file output?
              // Wait, I checked view_file for Post. It DOES NOT have fromFirestore factory in the snippet I saw?
              // Let me check the view_file output again.
              // The output showed lines 1-156. It's a data class with copyWith.
              // It seems I need to implement the mapping myself here or add it to the model.
              // Adding it to the model is better but I can mapped it here for now to avoid modifying existing logic too much.

              return Post(
                id: doc.id,
                author: Author(
                  id: data['author_id'] ?? '',
                  name: data['author_name'] ?? 'Unknown',
                  avatarUrl: data['author_avatar'],
                  isAnonymous: data['is_anonymous'] ?? false,
                ),
                content: data['content'] ?? '',
                reportCount: data['report_count'] ?? 0,
                category: PostCategory.values.firstWhere(
                  (e) => e.toString().split('.').last == data['category'],
                  orElse: () => PostCategory.general,
                ),
                createdAt: (data['created_at'] as Timestamp).toDate(),
                reactions: {}, // Not needed for moderation list view really
                comments: [], // Not needed for main list
              );
            } catch (e) {
              debugPrint('Error parsing post ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Post>()
          .toList();

      state = state.copyWith(isLoading: false, posts: posts);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _fetchPosts();

  Future<void> deletePost(String postId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _firestore.collection('posts').doc(postId).delete();
      await _fetchPosts();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final adminCommunityProvider =
    StateNotifierProvider<AdminCommunityNotifier, AdminCommunityState>((ref) {
      return AdminCommunityNotifier();
    });


/// A user report from the `community_reports` collection plus the reported
/// content text (loaded from the post/comment, null if already deleted).
class CommunityReport {
  final String id;
  final String targetType; // post | comment
  final String postId;
  final String? commentId;
  final String reportedUserId;
  final String reporterId;
  final String reason;
  final DateTime? createdAt;
  final String? content;

  const CommunityReport({
    required this.id,
    required this.targetType,
    required this.postId,
    this.commentId,
    required this.reportedUserId,
    required this.reporterId,
    required this.reason,
    this.createdAt,
    this.content,
  });

  bool get isComment => targetType == 'comment';
}

class AdminReportsState {
  final bool isLoading;
  final String? error;
  final List<CommunityReport> reports;

  const AdminReportsState({
    this.isLoading = false,
    this.error,
    this.reports = const [],
  });
}

class AdminReportsNotifier extends StateNotifier<AdminReportsState> {
  final FirebaseFirestore _firestore;

  AdminReportsNotifier({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      super(const AdminReportsState());

  Future<void> refresh() async {
    state = const AdminReportsState(isLoading: true);
    try {
      final snap = await _firestore
          .collection('community_reports')
          .where('status', isEqualTo: 'pending')
          .get();
      final reports = await Future.wait(
        snap.docs.map((doc) async {
          final d = doc.data();
          final postId = d['post_id'] as String? ?? '';
          final commentId = d['comment_id'] as String?;
          String? content;
          try {
            final postRef = _firestore.collection('posts').doc(postId);
            final target = commentId != null
                ? await postRef.collection('comments').doc(commentId).get()
                : await postRef.get();
            content = target.data()?['content'] as String?;
          } catch (e) {
            debugPrint('Error loading reported content: $e');
          }
          return CommunityReport(
            id: doc.id,
            targetType: d['target_type'] as String? ?? 'post',
            postId: postId,
            commentId: commentId,
            reportedUserId: d['reported_user_id'] as String? ?? '',
            reporterId: d['reporter_id'] as String? ?? '',
            reason: d['reason'] as String? ?? 'other',
            createdAt: (d['created_at'] as Timestamp?)?.toDate(),
            content: content,
          );
        }),
      );
      reports.sort(
        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
          a.createdAt ?? DateTime(0),
        ),
      );
      state = AdminReportsState(reports: reports);
    } catch (e) {
      state = AdminReportsState(error: e.toString());
    }
  }

  Future<void> dismiss(CommunityReport report) async {
    await _firestore.collection('community_reports').doc(report.id).update({
      'status': 'dismissed',
      'resolved_at': FieldValue.serverTimestamp(),
    });
    await refresh();
  }

  /// Deletes the reported post/comment and marks every pending report on it
  /// as actioned.
  Future<void> deleteContent(CommunityReport report) async {
    final postRef = _firestore.collection('posts').doc(report.postId);
    if (report.isComment && report.commentId != null) {
      await postRef.collection('comments').doc(report.commentId).delete();
      try {
        await postRef.update({'comments_count': FieldValue.increment(-1)});
      } catch (_) {}
    } else {
      await postRef.delete();
    }
    final same = await _firestore
        .collection('community_reports')
        .where('post_id', isEqualTo: report.postId)
        .where('status', isEqualTo: 'pending')
        .get();
    for (final doc in same.docs) {
      final d = doc.data();
      final matches = report.isComment
          ? d['comment_id'] == report.commentId
          : true; // deleting a post resolves all reports under it
      if (matches) {
        await doc.reference.update({
          'status': 'actioned',
          'resolved_at': FieldValue.serverTimestamp(),
        });
      }
    }
    await refresh();
  }
}

final adminReportsProvider =
    StateNotifierProvider<AdminReportsNotifier, AdminReportsState>((ref) {
      return AdminReportsNotifier();
    });
