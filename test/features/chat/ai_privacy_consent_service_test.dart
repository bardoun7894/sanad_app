import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_app/features/chat/services/ai_privacy_consent_service.dart';

void main() {
  String? account;
  Map<String, dynamic>? record;
  bool readFails = false;
  bool saveFails = false;
  int transfers = 0;
  int saves = 0;
  late AiPrivacyConsentService service;

  setUp(() {
    account = 'alice';
    record = null;
    readFails = false;
    saveFails = false;
    transfers = 0;
    saves = 0;
    service = AiPrivacyConsentService(
      currentUserId: () => account,
      readConsent: (uid) async {
        if (readFails) throw StateError('offline');
        return record;
      },
      saveConsent: (accepted, expectedUserId) async {
        saves++;
        if (saveFails) throw StateError('offline');
        record = {'accepted': accepted, 'version': aiPrivacyConsentVersion};
        return record!;
      },
    );
  });

  Future<void> send(Future<bool?> Function() prompt) async {
    if (await service.ensureConsent(prompt: prompt)) {
      await service.requireConsent(userId: account!);
      transfers++;
    }
  }

  test('Agree persists current consent before allowing a transfer', () async {
    await send(() async => true);
    expect(saves, 1);
    expect(transfers, 1);
  });
  for (final answer in <bool?>[false, null]) {
    test('Not now or cancel never transfers data', () async {
      await send(() async => answer);
      expect(transfers, 0);
      expect(record?['accepted'], isNot(true));
    });
  }
  test('read failure prevents consent prompt and transfer', () async {
    readFails = true;
    await send(() async => fail('must not prompt on failed read'));
    expect(saves, 0);
    expect(transfers, 0);
  });
  test('save failure never permits transfer', () async {
    saveFails = true;
    await send(() async => true);
    expect(transfers, 0);
  });
  test(
    'missing, revoked and outdated records require explicit agreement',
    () async {
      for (final value in [
        null,
        {'accepted': false, 'version': aiPrivacyConsentVersion},
        {'accepted': true, 'version': 'old'},
      ]) {
        record = value;
        await send(() async => false);
      }
      expect(transfers, 0);
    },
  );
  test('server revocation is checked again for every transfer', () async {
    await send(() async => true);
    record = {'accepted': false, 'version': aiPrivacyConsentVersion};
    await expectLater(
      service.requireConsent(userId: 'alice'),
      throwsA(isA<AiConsentRequiredException>()),
    );
    expect(transfers, 1);
  });
  test('switching accounts during prompt cannot inherit acceptance', () async {
    await send(() async {
      account = 'bob';
      return true;
    });
    expect(saves, 0);
    expect(transfers, 0);
  });
  test('switching accounts during read blocks pending transfer', () async {
    final read = Completer<Map<String, dynamic>?>();
    service = AiPrivacyConsentService(
      currentUserId: () => account,
      readConsent: (_) => read.future,
      saveConsent: (_, expectedUserId) async => {},
    );
    final pending = service.ensureConsent(prompt: () async => true);
    account = 'bob';
    read.complete({'accepted': true, 'version': aiPrivacyConsentVersion});
    expect(await pending, false);
  });
  test('one account cannot send under another account consent', () async {
    record = {'accepted': true, 'version': aiPrivacyConsentVersion};
    await expectLater(
      service.requireConsent(userId: 'bob'),
      throwsA(isA<AiConsentRequiredException>()),
    );
  });
  test(
    'patient consent is required independently of administrator consent',
    () async {
      service = AiPrivacyConsentService(
        currentUserId: () => 'admin',
        readConsent: (id) async => {
          'accepted': id == 'admin',
          'version': aiPrivacyConsentVersion,
        },
        saveConsent: (_, expectedUserId) async => {},
      );
      await expectLater(
        service.requireConsent(userId: 'admin', subjectUserIds: {'patient'}),
        throwsA(isA<AiConsentRequiredException>()),
      );
    },
  );
  test('successful revocation blocks next transfer', () async {
    await send(() async => true);
    expect(await service.setConsent(false), false);
    await expectLater(
      service.requireConsent(userId: 'alice'),
      throwsA(isA<AiConsentRequiredException>()),
    );
  });
  test(
    'save carries the originally authenticated account, even if auth changes during the request',
    () async {
      String? expectedAccount;
      service = AiPrivacyConsentService(
        currentUserId: () => account,
        readConsent: (_) async => null,
        saveConsent: (accepted, expectedUserId) async {
          expectedAccount = expectedUserId;
          account = 'bob';
          return {'accepted': accepted, 'version': aiPrivacyConsentVersion};
        },
      );
      expect(await service.ensureConsent(prompt: () async => true), false);
      expect(expectedAccount, 'alice');
      expect(transfers, 0);
    },
  );
}
