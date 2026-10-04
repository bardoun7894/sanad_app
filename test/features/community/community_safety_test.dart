import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/community/models/post.dart';
import 'package:sanad_app/features/community/services/community_safety_service.dart';

Post _post(String id, String authorId, {bool anon = false}) => Post(
  id: id,
  author: Author(id: authorId, name: 'n', isAnonymous: anon),
  content: 'c',
  category: PostCategory.general,
  createdAt: DateTime(2026),
);

Comment _comment(String id, String authorId) => Comment(
  id: id,
  author: Author(id: authorId, name: 'n'),
  content: 'c',
  createdAt: DateTime(2026),
);

void main() {
  group('block filter', () {
    test('hides posts from blocked authors including anonymous ones', () {
      final posts = [
        _post('1', 'a'),
        _post('2', 'b', anon: true),
        _post('3', 'c'),
      ];
      final out = filterVisiblePosts(posts, blockedUserIds: {'b'});
      expect(out.map((p) => p.id), ['1', '3']);
    });

    test('hides reported posts and comments', () {
      final posts = [_post('1', 'a'), _post('2', 'b')];
      expect(
        filterVisiblePosts(
          posts,
          blockedUserIds: {},
          hiddenPostIds: {'1'},
        ).map((p) => p.id),
        ['2'],
      );
      final comments = [_comment('x', 'a'), _comment('y', 'b')];
      expect(
        filterVisibleComments(
          comments,
          blockedUserIds: {'a'},
          hiddenCommentIds: {'y'},
        ),
        isEmpty,
      );
    });
  });

  group('CommunitySafetyService', () {
    late FakeFirebaseFirestore db;
    late CommunitySafetyService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = CommunitySafetyService(firestore: db);
      await db.collection('posts').doc('p1').set({
        'author_id': 'author',
        'report_count': 0,
      });
    });

    test('reportContent writes a pending report and bumps report_count', () async {
      await service.reportContent(
        targetType: ReportTargetType.comment,
        postId: 'p1',
        commentId: 'c1',
        reportedUserId: 'author',
        reporterId: 'me',
        reason: ReportReason.harassment,
      );
      final reports = await db.collection('community_reports').get();
      expect(reports.docs, hasLength(1));
      final d = reports.docs.first.data();
      expect(d['target_type'], 'comment');
      expect(d['post_id'], 'p1');
      expect(d['comment_id'], 'c1');
      expect(d['reported_user_id'], 'author');
      expect(d['reporter_id'], 'me');
      expect(d['reason'], 'harassment');
      expect(d['status'], 'pending');
      expect(d['created_at'], isA<Timestamp>());
      final post = await db.collection('posts').doc('p1').get();
      expect(post.data()!['report_count'], 1);
    });

    test('block and unblock update blocked_user_ids', () async {
      await service.blockUser('me', 'x');
      await service.blockUser('me', 'y');
      var safety = await service.watchUserSafety('me').first;
      expect(safety.blockedUserIds, {'x', 'y'});
      expect(safety.termsAccepted, isFalse);
      await service.unblockUser('me', 'x');
      safety = await service.watchUserSafety('me').first;
      expect(safety.blockedUserIds, {'y'});
    });

    test('acceptCommunityTerms persists the timestamp', () async {
      await service.acceptCommunityTerms('me');
      final safety = await service.watchUserSafety('me').first;
      expect(safety.termsAccepted, isTrue);
    });
  });
}
