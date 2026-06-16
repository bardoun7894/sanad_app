// Behavioral test: changing a user's role keeps the app therapist list in sync.
// App list query = therapists where is_active==true AND approval_status=='approved'.
//   - user/admin -> therapist : SHOW  (is_active true, approval_status approved)
//   - therapist  -> user/admin: HIDE  (is_active false, approval_status revoked)
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/admin/providers/activity_log_provider.dart';
import 'package:sanad_app/features/admin/providers/admin_users_provider.dart';

void main() {
  late FakeFirebaseFirestore db;
  late AdminUsersNotifier sut;

  setUp(() {
    db = FakeFirebaseFirestore();
    sut = AdminUsersNotifier(
      firestore: db,
      activityLogService: ActivityLogService(firestore: db),
    );
  });

  Future<void> seedUser(String id, {String role = 'user'}) =>
      db.collection('users').doc(id).set({
        'id': id,
        'name': 'Test $id',
        'email': '$id@x.com',
        'role': role,
      });

  Future<void> seedTherapistDoc(String id,
          {required bool active, required String approval}) =>
      db.collection('therapists').doc(id).set({
        'id': id,
        'name': 'Test $id',
        'is_active': active,
        'approval_status': approval,
      });

  Future<Map<String, dynamic>?> therapistDoc(String id) async =>
      (await db.collection('therapists').doc(id).get()).data();

  bool showsInList(Map<String, dynamic>? d) =>
      d != null && d['is_active'] == true && d['approval_status'] == 'approved';

  test('user -> therapist : created and SHOWS in the list', () async {
    await seedUser('u1', role: 'user');

    await sut.updateUserRole('u1', 'therapist', actorUid: 'admin');

    expect(showsInList(await therapistDoc('u1')), isTrue);
  });

  test('admin -> therapist (existing inactive doc) : re-activated and SHOWS',
      () async {
    await seedUser('u2', role: 'admin');
    await seedTherapistDoc('u2', active: false, approval: 'revoked');

    await sut.updateUserRole('u2', 'therapist', actorUid: 'admin');

    expect(showsInList(await therapistDoc('u2')), isTrue);
  });

  test('therapist -> user : deactivated and HIDDEN from the list', () async {
    await seedUser('u3', role: 'therapist');
    await seedTherapistDoc('u3', active: true, approval: 'approved');

    await sut.updateUserRole('u3', 'user', actorUid: 'admin');

    final d = await therapistDoc('u3');
    expect(showsInList(d), isFalse);
    expect(d!['is_active'], isFalse);
  });

  test('therapist -> admin : deactivated and HIDDEN from the list', () async {
    await seedUser('u4', role: 'therapist');
    await seedTherapistDoc('u4', active: true, approval: 'approved');

    await sut.updateUserRole('u4', 'admin', actorUid: 'admin');

    expect(showsInList(await therapistDoc('u4')), isFalse);
  });

  test('user -> user (no therapist doc) : no therapist doc created', () async {
    await seedUser('u5', role: 'user');

    await sut.updateUserRole('u5', 'user', actorUid: 'admin');

    expect(await therapistDoc('u5'), isNull);
  });
}
