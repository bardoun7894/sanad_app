'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

// Load the actual callable in isolation from unrelated functions and live Firebase.
function harness({ chat = { user_id: 'patient', therapist_id: 'therapist', user_access: 'read_only', status: 'active' }, role, count = 0, nested = false, failDelete = false, lateMessage = false } = {}) {
  const source = fs.readFileSync(require.resolve('../index.js'), 'utf8');
  const start = source.indexOf('exports.clearTherapistChat =');
  assert.notEqual(start, -1, 'clearTherapistChat callable must exist');
  const end = source.indexOf('\n});', start) + '\n});'.length;
  const batches = [];
  let resultChat = chat && { ...chat };
  function collection(size, hasNested = false) {
    const docs = Array.from({ length: size }, (_, i) => {
      const child = collection(hasNested && i === 0 ? 2 : 0);
      return { ref: { listCollections: async () => hasNested && i === 0 ? [child] : [] } };
    });
    for (const doc of docs) doc.ref.remove = () => docs.splice(docs.indexOf(doc), 1);
    return { docs, limit: n => ({ get: async () => ({ docs: docs.slice(0, n), empty: docs.length === 0, size: Math.min(n, docs.length) }) }) };
  }
  const messages = collection(count, nested);
  const chatRef = {
    get: async () => ({ exists: !!resultChat, data: () => resultChat }),
    collection: name => { assert.equal(name, 'messages'); return messages; },
    update: async fields => { Object.assign(resultChat, fields); },
  };
  const db = {
    runTransaction: async fn => {
      if (lateMessage) {
        lateMessage = false;
        messages.docs.push({ ref: { listCollections: async () => [], remove: () => messages.docs.shift() } });
      }
      return fn({ get: query => query.get(), update: (ref, fields) => ref.update(fields) });
    },
    collection: name => ({ doc: id => {
      if (name === 'therapist_chats') { assert.equal(id, 'chat'); return chatRef; }
      assert.equal(name, 'users');
      return { get: async () => ({ exists: !!role, data: () => ({ role }) }) };
    } }),
    batch: () => {
      const refs = [];
      return { delete: ref => refs.push(ref), commit: async () => {
        if (failDelete) throw new Error('database unavailable');
        assert.ok(refs.length <= 400);
        batches.push(refs.length);
        refs.forEach(ref => ref.remove());
      } };
    },
  };
  class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
  const https = { onCall: fn => fn, HttpsError };
  const sandbox = { exports: {}, db, functions: { https, runWith: () => ({ https }) }, admin: { firestore: { FieldValue: { serverTimestamp: () => 'server-time' } } }, console: { log() {}, error() {} } };
  vm.runInNewContext(source.slice(start, end), sandbox);
  return { clear: sandbox.exports.clearTherapistChat, messages, batches, chat: () => resultChat };
}

const auth = (uid, admin = false) => ({ auth: { uid, token: { admin } } });

test('requires authentication and a valid chatId', async () => {
  const h = harness();
  await assert.rejects(h.clear({ chatId: 'chat' }, {}), { code: 'unauthenticated' });
  for (const chatId of [null, '', ' ', 'a/b', 42]) {
    await assert.rejects(h.clear({ chatId }, auth('patient')), { code: 'invalid-argument' });
  }
});

test('missing chat returns not-found', async () => {
  await assert.rejects(harness({ chat: null }).clear({ chatId: 'chat' }, auth('patient')), { code: 'not-found' });
});

test('rejects outsiders without deleting any messages', async () => {
  const h = harness({ count: 3, role: 'therapist' });
  await assert.rejects(h.clear({ chatId: 'chat' }, auth('outsider')), { code: 'permission-denied' });
  assert.equal(h.messages.docs.length, 3);
  assert.deepEqual(h.batches, []);
});

for (const [uid, claim, role] of [['patient', false], ['therapist', false], ['admin', true], ['admin', false, 'admin']]) {
  test(`allows ${uid} (claim=${claim}, role=${role}) and preserves the thread`, async () => {
    const h = harness({ count: 805, nested: true, role });
    const result = await h.clear({ chatId: 'chat' }, auth(uid, claim));
    assert.equal(result.deleted, 805);
    assert.equal(h.messages.docs.length, 0);
    assert.deepEqual(h.batches, [2, 400, 400, 5]);
    assert.deepEqual(h.chat(), { user_id: 'patient', therapist_id: 'therapist', user_access: 'read_only', status: 'active', last_message: '', last_message_time: 'server-time', unread_count_user: 0, unread_count_therapist: 0, cleared_at: 'server-time', cleared_by: uid });
    assert.equal((await h.clear({ chatId: 'chat' }, auth(uid, claim))).deleted, 0);
  });
}

test('deletion failures surface as internal errors', async () => {
  const h = harness({ count: 1, failDelete: true });
  await assert.rejects(h.clear({ chatId: 'chat' }, auth('patient')), { code: 'internal' });
  assert.equal(h.chat().cleared_at, undefined);
});

test('rechecks messages transactionally before resetting chat metadata', async () => {
  const h = harness({ count: 1, lateMessage: true });
  const result = await h.clear({ chatId: 'chat' }, auth('patient'));
  assert.equal(result.deleted, 2);
  assert.equal(h.messages.docs.length, 0);
});

for (const exists of [false, true]) {
  test(`message trigger ${exists ? 'updates a live message' : 'cannot restore a deleted preview after clear'}`, async () => {
    const source = fs.readFileSync(require.resolve('../index.js'), 'utf8');
    const start = source.indexOf('exports.onTherapistChatMessage =');
    const end = source.indexOf('\n  });', start) + '\n  });'.length;
    let updates = 0;
    let notifications = 0;
    const chatRef = { update: async () => { updates++; } };
    const sandbox = {
      exports: {},
      functions: { firestore: { document: () => ({ onCreate: fn => fn }) } },
      admin: { firestore: { FieldValue: { serverTimestamp: () => 'time', increment: () => 1 } } },
      db: {
        collection: () => ({ doc: () => ({ ...chatRef, get: async () => ({ exists: true, ref: chatRef, data: () => ({ user_id: 'patient', therapist_id: 'therapist' }) }) }) }),
        runTransaction: fn => fn({ get: async () => ({ exists }), update: () => { updates++; } }),
      },
      sendNotificationToUser: async () => { notifications++; },
      console: { log() {} },
    };
    vm.runInNewContext(source.slice(start, end), sandbox);
    await sandbox.exports.onTherapistChatMessage(
      { ref: {}, data: () => ({ sender_id: 'patient', content: 'Sensitive history' }) },
      { params: { chatId: 'chat' } },
    );
    assert.equal(updates, exists ? 1 : 0);
    assert.equal(notifications, exists ? 1 : 0);
  });
}
