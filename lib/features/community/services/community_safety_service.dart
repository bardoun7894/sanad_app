import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

enum ReportReason { spam, harassment, selfHarm, inappropriate, other }

enum ReportTargetType { post, comment }

/// Pure filter: drop posts by blocked authors or that the reporter already
/// reported/hid locally. Anonymous posts still carry the author uid, so
/// blocking works without ever showing the identity.
List<Post> filterVisiblePosts(
  List<Post> posts, {
  required Set<String> blockedUserIds,
  Set<String> hiddenPostIds = const {},
}) {
  return posts
      .where(
        (p) =>
            !blockedUserIds.contains(p.author.id) &&
            !hiddenPostIds.contains(p.id),
      )
      .toList();
}

/// Pure filter for comments (same rules as [filterVisiblePosts]).
List<Comment> filterVisibleComments(
  List<Comment> comments, {
  required Set<String> blockedUserIds,
  Set<String> hiddenCommentIds = const {},
}) {
  return comments
      .where(
        (c) =>
            !blockedUserIds.contains(c.author.id) &&
            !hiddenCommentIds.contains(c.id),
      )
      .toList();
}

class CommunitySafetyService {
  final FirebaseFirestore _firestore;

  CommunitySafetyService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Writes a report to `community_reports` and bumps the post's report_count.
  Future<void> reportContent({
    required ReportTargetType targetType,
    required String postId,
    String? commentId,
    required String reportedUserId,
    required String reporterId,
    required ReportReason reason,
  }) async {
    await _firestore.collection('community_reports').add({
      'target_type': targetType.name,
      'post_id': postId,
      if (commentId != null) 'comment_id': commentId,
      'reported_user_id': reportedUserId,
      'reporter_id': reporterId,
      'reason': reason.name,
      'created_at': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    await _firestore.collection('posts').doc(postId).update({
      'report_count': FieldValue.increment(1),
    });
  }

  Future<void> blockUser(String currentUid, String blockedUid) {
    return _firestore.collection('users').doc(currentUid).set({
      'blocked_user_ids': FieldValue.arrayUnion([blockedUid]),
    }, SetOptions(merge: true));
  }

  Future<void> unblockUser(String currentUid, String blockedUid) {
    return _firestore.collection('users').doc(currentUid).set({
      'blocked_user_ids': FieldValue.arrayRemove([blockedUid]),
    }, SetOptions(merge: true));
  }

  Future<void> acceptCommunityTerms(String uid) {
    return _firestore.collection('users').doc(uid).set({
      'community_terms_accepted_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<CommunityUserSafety> watchUserSafety(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      final blocked = (data['blocked_user_ids'] as List?)
              ?.whereType<String>()
              .toSet() ??
          <String>{};
      return CommunityUserSafety(
        blockedUserIds: blocked,
        termsAccepted: data['community_terms_accepted_at'] != null,
      );
    });
  }
}

class CommunityUserSafety {
  final Set<String> blockedUserIds;
  final bool termsAccepted;

  const CommunityUserSafety({
    this.blockedUserIds = const {},
    this.termsAccepted = false,
  });
}
