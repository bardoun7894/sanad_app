// Behavioral tests for TherapistAssignmentNotifier.
//
// T9 cases:
//   (a) Fresh assign — happy path
//   (b) Reassign — replace old therapist
//   (c) Re-click idempotency — no-op when already assigned same therapist
//   (d) Inactive therapist — validation error, no side effects
//   (e) Missing user doc — validation error
//   (f) Unassign — clears assignment, archives chat
//
// Shape sanity (compact): 3 inline tests cover sealed-class construction.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sanad_app/features/therapist_chat/models/therapist_chat.dart';
import 'package:sanad_app/features/therapist_chat/services/therapist_chat_service.dart';
import 'package:sanad_app/features/therapists/providers/therapist_assignment_provider.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class _MockTherapistChatService extends Mock implements TherapistChatService {}

// ---------------------------------------------------------------------------
// Fallback registrations (needed for mocktail any() on custom types)
// ---------------------------------------------------------------------------

class _FakeChatThread extends Fake implements TherapistChatThread {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TherapistChatThread _fakeThread({
  String therapistId = 'therapist-A',
  String userId = 'user-1',
  String therapistName = 'Dr. Test',
}) {
  final now = DateTime.now();
  final chatId = TherapistChatThread.generateChatId(therapistId, userId);
  return TherapistChatThread(
    chatId: chatId,
    therapistId: therapistId,
    userId: userId,
    therapistName: therapistName,
    userName: 'Alice',
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _seedTherapist(
  FakeFirebaseFirestore db, {
  required String id,
  String approvalStatus = 'approved',
  String name = 'Dr. Test',
}) async {
  await db.collection('therapists').doc(id).set({
    'id': id,
    'name': name,
    'approval_status': approvalStatus,
  });
}

Future<void> _seedUser(
  FakeFirebaseFirestore db, {
  required String id,
  String? assignedTherapistId,
  String displayName = 'Alice',
  String locale = 'en',
}) async {
  await db.collection('users').doc(id).set({
    'id': id,
    'display_name': displayName,
    'locale': locale,
    if (assignedTherapistId != null)
      'assigned_therapist_id': assignedTherapistId,
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeChatThread());
    registerFallbackValue(ChatSource.direct);
  });

  // ------------------------------------------------------------------
  // Sealed-class shape (compact sanity)
  // ------------------------------------------------------------------
  group('AssignmentResult sealed class shape', () {
    test('AssignmentSuccess is an AssignmentResult', () {
      expect(const AssignmentSuccess(), isA<AssignmentResult>());
    });

    test('AssignmentValidationError carries reason', () {
      const r = AssignmentValidationError(reason: 'test');
      expect(r, isA<AssignmentResult>());
      expect(r.reason, 'test');
    });

    test('AssignmentPartialSuccess carries chatWriteFailed', () {
      const r = AssignmentPartialSuccess(chatWriteFailed: true);
      expect(r, isA<AssignmentResult>());
      expect(r.chatWriteFailed, isTrue);
    });
  });

  // ------------------------------------------------------------------
  // Behavioral — (a) Fresh assign
  // ------------------------------------------------------------------
  group('(a) Fresh assign', () {
    late FakeFirebaseFirestore db;
    late _MockTherapistChatService chatService;
    late TherapistAssignmentNotifier sut;

    setUp(() {
      db = FakeFirebaseFirestore();
      chatService = _MockTherapistChatService();
      sut = TherapistAssignmentNotifier(
        firestore: db,
        chatService: chatService,
      );
    });

    test(
      'approved therapist + new user + empty chat → AssignmentSuccess, '
      'user doc updated, activity log written, sendWelcomeMessage called once',
      () async {
        await _seedTherapist(db, id: 'therapist-A');
        await _seedUser(db, id: 'user-1');

        final thread = _fakeThread();

        when(
          () => chatService.getOrCreateChat(
            therapistId: any(named: 'therapistId'),
            userId: any(named: 'userId'),
            therapistName: any(named: 'therapistName'),
            userName: any(named: 'userName'),
            therapistPhotoUrl: any(named: 'therapistPhotoUrl'),
            userPhotoUrl: any(named: 'userPhotoUrl'),
            source: any(named: 'source'),
          ),
        ).thenAnswer((_) async => thread);

        when(
          () => chatService.chatHasMessages(any()),
        ).thenAnswer((_) async => false);

        when(
          () => chatService.sendWelcomeMessage(
            chatId: any(named: 'chatId'),
            therapistId: any(named: 'therapistId'),
            therapistName: any(named: 'therapistName'),
            content: any(named: 'content'),
            triggeredBy: any(named: 'triggeredBy'),
          ),
        ).thenAnswer((_) async {});

        final result = await sut.assignTherapist(
          userId: 'user-1',
          therapistId: 'therapist-A',
          therapistName: 'Dr. Test',
          actorUid: 'admin-1',
          actorName: 'Admin',
          triggeredBy: 'admin',
        );

        expect(result, isA<AssignmentSuccess>());

        // User doc must have the assigned_therapist_id set.
        final userSnap =
            await db.collection('users').doc('user-1').get();
        expect(
          userSnap.data()?['assigned_therapist_id'],
          'therapist-A',
        );

        // Activity log entry must exist.
        final logs =
            await db.collection('activity_logs').get();
        expect(logs.docs, hasLength(1));
        expect(
          logs.docs.first.data()['metadata']['therapist_id'],
          'therapist-A',
        );

        // sendWelcomeMessage called exactly once.
        verify(
          () => chatService.sendWelcomeMessage(
            chatId: any(named: 'chatId'),
            therapistId: any(named: 'therapistId'),
            therapistName: any(named: 'therapistName'),
            content: any(named: 'content'),
            triggeredBy: any(named: 'triggeredBy'),
          ),
        ).called(1);
      },
    );
  });

  // ------------------------------------------------------------------
  // Behavioral — (b) Reassign
  // ------------------------------------------------------------------
  group('(b) Reassign — replace old therapist with new one', () {
    late FakeFirebaseFirestore db;
    late _MockTherapistChatService chatService;
    late TherapistAssignmentNotifier sut;

    setUp(() {
      db = FakeFirebaseFirestore();
      chatService = _MockTherapistChatService();
      sut = TherapistAssignmentNotifier(
        firestore: db,
        chatService: chatService,
      );
    });

    test(
      'user already has therapist-A; assigning therapist-B '
      '→ replaceChat called; welcome from B; activity log has old + new ids',
      () async {
        await _seedTherapist(db, id: 'therapist-B', name: 'Dr. B');
        await _seedUser(
          db,
          id: 'user-1',
          assignedTherapistId: 'therapist-A',
        );

        final newThread = _fakeThread(
          therapistId: 'therapist-B',
          therapistName: 'Dr. B',
        );

        when(
          () => chatService.replaceChat(
            oldTherapistId: any(named: 'oldTherapistId'),
            newTherapistId: any(named: 'newTherapistId'),
            userId: any(named: 'userId'),
            newTherapistName: any(named: 'newTherapistName'),
            newTherapistPhotoUrl: any(named: 'newTherapistPhotoUrl'),
            userName: any(named: 'userName'),
            userPhotoUrl: any(named: 'userPhotoUrl'),
            source: any(named: 'source'),
          ),
        ).thenAnswer((_) async => newThread);

        when(
          () => chatService.chatHasMessages(any()),
        ).thenAnswer((_) async => false);

        when(
          () => chatService.sendWelcomeMessage(
            chatId: any(named: 'chatId'),
            therapistId: any(named: 'therapistId'),
            therapistName: any(named: 'therapistName'),
            content: any(named: 'content'),
            triggeredBy: any(named: 'triggeredBy'),
          ),
        ).thenAnswer((_) async {});

        final result = await sut.assignTherapist(
          userId: 'user-1',
          therapistId: 'therapist-B',
          therapistName: 'Dr. B',
          actorUid: 'admin-1',
          actorName: 'Admin',
          triggeredBy: 'admin',
        );

        expect(result, isA<AssignmentSuccess>());

        // replaceChat must have been invoked (not getOrCreateChat).
        verify(
          () => chatService.replaceChat(
            oldTherapistId: 'therapist-A',
            newTherapistId: 'therapist-B',
            userId: any(named: 'userId'),
            newTherapistName: any(named: 'newTherapistName'),
            newTherapistPhotoUrl: any(named: 'newTherapistPhotoUrl'),
            userName: any(named: 'userName'),
            userPhotoUrl: any(named: 'userPhotoUrl'),
            source: any(named: 'source'),
          ),
        ).called(1);
        verifyNever(
          () => chatService.getOrCreateChat(
            therapistId: any(named: 'therapistId'),
            userId: any(named: 'userId'),
            therapistName: any(named: 'therapistName'),
            userName: any(named: 'userName'),
            therapistPhotoUrl: any(named: 'therapistPhotoUrl'),
            userPhotoUrl: any(named: 'userPhotoUrl'),
            source: any(named: 'source'),
          ),
        );

        // sendWelcomeMessage is for the new therapist.
        final captured = verify(
          () => chatService.sendWelcomeMessage(
            chatId: any(named: 'chatId'),
            therapistId: captureAny(named: 'therapistId'),
            therapistName: any(named: 'therapistName'),
            content: any(named: 'content'),
            triggeredBy: any(named: 'triggeredBy'),
          ),
        ).captured;
        expect(captured.first, 'therapist-B');

        // Activity log must record both old and new therapist ids.
        final logs = await db.collection('activity_logs').get();
        expect(logs.docs, hasLength(1));
        final meta =
            logs.docs.first.data()['metadata'] as Map<String, dynamic>;
        expect(meta['old_therapist_id'], 'therapist-A');
        expect(meta['therapist_id'], 'therapist-B');
      },
    );
  });

  // ------------------------------------------------------------------
  // Behavioral — (c) Idempotency
  // ------------------------------------------------------------------
  group('(c) Idempotency — re-click same therapist', () {
    late FakeFirebaseFirestore db;
    late _MockTherapistChatService chatService;
    late TherapistAssignmentNotifier sut;

    setUp(() {
      db = FakeFirebaseFirestore();
      chatService = _MockTherapistChatService();
      sut = TherapistAssignmentNotifier(
        firestore: db,
        chatService: chatService,
      );
    });

    test(
      'user already assigned to therapist-A; calling assign(A) again '
      '→ AssignmentSuccess without sendWelcomeMessage',
      () async {
        // Therapist must be approved; idempotency check happens after validation.
        await _seedTherapist(db, id: 'therapist-A');
        await _seedUser(
          db,
          id: 'user-1',
          assignedTherapistId: 'therapist-A',
        );

        final result = await sut.assignTherapist(
          userId: 'user-1',
          therapistId: 'therapist-A',
          therapistName: 'Dr. Test',
          actorUid: 'admin-1',
          actorName: 'Admin',
          triggeredBy: 'admin',
        );

        expect(result, isA<AssignmentSuccess>());

        // No chat service calls whatsoever.
        verifyNever(
          () => chatService.sendWelcomeMessage(
            chatId: any(named: 'chatId'),
            therapistId: any(named: 'therapistId'),
            therapistName: any(named: 'therapistName'),
            content: any(named: 'content'),
            triggeredBy: any(named: 'triggeredBy'),
          ),
        );
        verifyNever(
          () => chatService.getOrCreateChat(
            therapistId: any(named: 'therapistId'),
            userId: any(named: 'userId'),
            therapistName: any(named: 'therapistName'),
            userName: any(named: 'userName'),
            therapistPhotoUrl: any(named: 'therapistPhotoUrl'),
            userPhotoUrl: any(named: 'userPhotoUrl'),
            source: any(named: 'source'),
          ),
        );
        verifyNever(
          () => chatService.replaceChat(
            oldTherapistId: any(named: 'oldTherapistId'),
            newTherapistId: any(named: 'newTherapistId'),
            userId: any(named: 'userId'),
            newTherapistName: any(named: 'newTherapistName'),
            newTherapistPhotoUrl: any(named: 'newTherapistPhotoUrl'),
            userName: any(named: 'userName'),
            userPhotoUrl: any(named: 'userPhotoUrl'),
            source: any(named: 'source'),
          ),
        );
      },
    );
  });

  // ------------------------------------------------------------------
  // Behavioral — (d) Inactive therapist
  // ------------------------------------------------------------------
  group('(d) Inactive therapist', () {
    late FakeFirebaseFirestore db;
    late _MockTherapistChatService chatService;
    late TherapistAssignmentNotifier sut;

    setUp(() {
      db = FakeFirebaseFirestore();
      chatService = _MockTherapistChatService();
      sut = TherapistAssignmentNotifier(
        firestore: db,
        chatService: chatService,
      );
    });

    test(
      'therapist with approval_status=pending '
      '→ AssignmentValidationError, no writes to user doc, no chat side-effects',
      () async {
        await _seedTherapist(
          db,
          id: 'therapist-X',
          approvalStatus: 'pending',
        );
        await _seedUser(db, id: 'user-1');

        // Record user doc before.
        final beforeSnap =
            await db.collection('users').doc('user-1').get();
        final beforeData =
            Map<String, dynamic>.from(beforeSnap.data() ?? {});

        final result = await sut.assignTherapist(
          userId: 'user-1',
          therapistId: 'therapist-X',
          therapistName: 'Dr. Pending',
          actorUid: 'admin-1',
          actorName: 'Admin',
          triggeredBy: 'admin',
        );

        expect(result, isA<AssignmentValidationError>());
        expect(
          (result as AssignmentValidationError).reason,
          'therapist_not_approved',
        );

        // User doc must be unchanged.
        final afterSnap =
            await db.collection('users').doc('user-1').get();
        expect(afterSnap.data(), equals(beforeData));

        // No activity log.
        final logs = await db.collection('activity_logs').get();
        expect(logs.docs, isEmpty);

        // No chat side effects.
        verifyNever(
          () => chatService.sendWelcomeMessage(
            chatId: any(named: 'chatId'),
            therapistId: any(named: 'therapistId'),
            therapistName: any(named: 'therapistName'),
            content: any(named: 'content'),
            triggeredBy: any(named: 'triggeredBy'),
          ),
        );
        verifyNever(
          () => chatService.getOrCreateChat(
            therapistId: any(named: 'therapistId'),
            userId: any(named: 'userId'),
            therapistName: any(named: 'therapistName'),
            userName: any(named: 'userName'),
            therapistPhotoUrl: any(named: 'therapistPhotoUrl'),
            userPhotoUrl: any(named: 'userPhotoUrl'),
            source: any(named: 'source'),
          ),
        );
      },
    );
  });

  // ------------------------------------------------------------------
  // Behavioral — (e) Missing user doc
  // ------------------------------------------------------------------
  group('(e) Missing user doc', () {
    late FakeFirebaseFirestore db;
    late _MockTherapistChatService chatService;
    late TherapistAssignmentNotifier sut;

    setUp(() {
      db = FakeFirebaseFirestore();
      chatService = _MockTherapistChatService();
      sut = TherapistAssignmentNotifier(
        firestore: db,
        chatService: chatService,
      );
    });

    test(
      'users/{id} does not exist → AssignmentValidationError(user_not_found)',
      () async {
        await _seedTherapist(db, id: 'therapist-A');
        // Deliberately do NOT seed the user doc.

        final result = await sut.assignTherapist(
          userId: 'ghost-user',
          therapistId: 'therapist-A',
          therapistName: 'Dr. Test',
          actorUid: 'admin-1',
          actorName: 'Admin',
          triggeredBy: 'admin',
        );

        expect(result, isA<AssignmentValidationError>());
        expect(
          (result as AssignmentValidationError).reason,
          'user_not_found',
        );
      },
    );
  });

  // ------------------------------------------------------------------
  // Behavioral — (f) Unassign
  // ------------------------------------------------------------------
  group('(f) Unassign', () {
    late FakeFirebaseFirestore db;
    late _MockTherapistChatService chatService;
    late TherapistAssignmentNotifier sut;

    setUp(() {
      db = FakeFirebaseFirestore();
      chatService = _MockTherapistChatService();
      sut = TherapistAssignmentNotifier(
        firestore: db,
        chatService: chatService,
      );
    });

    test(
      'user has therapist-A → assigned_therapist_id cleared (deleted), '
      'archiveChat called with the composite chatId, activity log written',
      () async {
        await _seedUser(
          db,
          id: 'user-1',
          assignedTherapistId: 'therapist-A',
        );

        when(
          () => chatService.archiveChat(any()),
        ).thenAnswer((_) async {});

        final result = await sut.unassignTherapist(
          userId: 'user-1',
          actorUid: 'admin-1',
          actorName: 'Admin',
          triggeredBy: 'admin',
        );

        expect(result, isA<AssignmentSuccess>());

        // assigned_therapist_id must be gone from the user doc.
        final userSnap =
            await db.collection('users').doc('user-1').get();
        expect(
          userSnap.data()?.containsKey('assigned_therapist_id'),
          isFalse,
        );

        // Activity log must exist with old_therapist_id.
        final logs = await db.collection('activity_logs').get();
        expect(logs.docs, hasLength(1));
        final meta =
            logs.docs.first.data()['metadata'] as Map<String, dynamic>;
        expect(meta['old_therapist_id'], 'therapist-A');

        // archiveChat must be called with the composite chatId.
        final expectedChatId = TherapistChatThread.generateChatId(
          'therapist-A',
          'user-1',
        );
        verify(() => chatService.archiveChat(expectedChatId)).called(1);
      },
    );
  });
}
