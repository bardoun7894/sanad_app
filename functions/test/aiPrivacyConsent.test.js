'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

// Execute production callables with Firebase/Google network boundaries replaced.
function harness({ consent, patientExists = true, therapistAuthorized = true, failWrite = false, failConsentRead = false, revokeDuringContext = false, failFirstReport = false, revokeBeforeFallback = false } = {}) {
  const source = fs.readFileSync(require.resolve('../index.js'), 'utf8');
  const users = new Map([['patient', patientExists ? { ai_privacy_consent: consent } : null], ['staff', { ai_privacy_consent: { accepted: true, version: '2026-10-01' } }]]);
  const reads = [], writes = [];
  let externalCalls = 0;
  const snapshot = data => ({ exists: !!data, data: () => data });
  const empty = { docs: [], empty: true, size: 0 };
  function collection(name, prefix = '') {
    const query = {
      where() { return query; }, orderBy() { return query; }, limit() { return query; },
      get: async () => name === 'bookings' && therapistAuthorized ? { ...empty, empty: false } : empty,
      add: async value => writes.push({ path: name, value }),
      doc: (id = 'report-id') => {
        const path = prefix + name + '/' + id;
        return {
          id, get: async () => { if (name === 'users' && failConsentRead) throw new Error('consent read failed'); reads.push(path); return snapshot(name === 'users' ? users.get(id) : null); },
          set: async (value, options) => {
            if (failWrite) throw new Error('write failed');
            writes.push({ path, value, options });
            if (name === 'users') users.set(id, { ...(users.get(id) || {}), ...value });
          },
          collection: child => collection(child, path + '/'),
        };
      },
    };
    return query;
  }
  const db = { collection, doc: () => ({ get: async () => snapshot({ gemini_api_key: 'fake-test-key' }) }) };
  class HttpsError extends Error {
    constructor(code, message, details) { super(message); this.code = code; this.details = details; }
  }
  const https = { onCall: fn => fn, HttpsError };
  const timestamp = { serverTimestamp: true };
  const result = { response: { text: () => 'AI response', usageMetadata: { totalTokenCount: 10 } } };
  class GoogleGenerativeAI {
    getGenerativeModel() {
      return {
        startChat: () => ({ sendMessage: async () => { externalCalls++; return result; } }),
        generateContent: async () => {
          externalCalls++;
          if (failFirstReport && externalCalls === 1) {
            if (revokeBeforeFallback) users.get('patient').ai_privacy_consent = { ...current, accepted: false };
            throw new Error('model unavailable');
          }
          return result;
        },
      };
    }
  }
  const helperPath = require('node:path').join(__dirname, '../lib/aiPrivacyConsent.js');
  const helpers = fs.existsSync(helperPath) ? require(helperPath) : {};
  const sandbox = {
    exports: {}, db, ...helpers, GoogleGenerativeAI,
    functions: { https, runWith: () => ({ https }) },
    admin: { firestore: { FieldValue: { serverTimestamp: () => timestamp }, Timestamp: { fromDate: date => date } } },
    getCachedBriefing: async () => {
      if (revokeDuringContext) users.get('patient').ai_privacy_consent = { ...current, accepted: false };
      return { markdown: '', structured: { user: {} } };
    },
    getCachedPatterns: async () => ({}), matchContent: async () => [],
    buildSystemPrompt: () => 'system', PERSONAS: { companion: {} },
    _isAssignedTherapistFor: async () => therapistAuthorized,
    require: name => name === './lib/userBriefing' ? { getCachedBriefing: async () => ({ markdown: 'local summary' }) } : require(name),
    CHAT_MODEL: 'fake-model', DAILY_TOKEN_CAP: 100000,
    console: { log() {}, warn() {}, error() {} },
  };
  vm.runInNewContext(source.slice(source.indexOf('let _geminiKeyCache'), source.indexOf('exports.chatWithGemini =')), sandbox);
  for (const name of ['setAiPrivacyConsent', 'chatWithGemini', 'generateUserReport', 'generateUserBriefing']) {
    const start = source.indexOf('exports.' + name + ' =');
    if (start < 0) continue;
    const end = source.indexOf('\n});', start) + '\n});'.length;
    vm.runInNewContext(source.slice(start, end), sandbox);
  }
  return { ...sandbox.exports, users, reads, writes, timestamp, externalCalls: () => externalCalls };
}
const auth = (uid = 'patient', admin = false, provider = 'password') => ({ auth: { uid, token: { admin, firebase: { sign_in_provider: provider } } } });
const current = { accepted: true, version: '2026-10-01' };
const chatData = { messages: [{ role: 'user', content: 'Private health message' }] };

test('consent callable writes only caller consent with server-normalized fields', async () => {
  const h = harness();
  assert.equal(typeof h.setAiPrivacyConsent, 'function');
  await h.setAiPrivacyConsent({ ...current, userId: 'victim', updated_at: 'forged', extra: true }, auth());
  assert.equal(h.writes.length, 1);
  const write = h.writes[0];
  assert.equal(write.path, 'users/patient');
  assert.equal(write.options.merge, true);
  assert.equal(write.value.ai_privacy_consent.accepted, true);
  assert.equal(write.value.ai_privacy_consent.version, '2026-10-01');
  assert.equal(write.value.ai_privacy_consent.updated_at, h.timestamp);
  assert.deepEqual(Object.keys(write.value.ai_privacy_consent).sort(), ['accepted', 'updated_at', 'version']);
  assert.equal(h.users.has('victim'), false);
});

test('callable validates authentication, anonymous accounts, boolean and exact current version', async () => {
  const h = harness();
  assert.equal(typeof h.setAiPrivacyConsent, 'function');
  await assert.rejects(h.setAiPrivacyConsent(current, {}), { code: 'unauthenticated' });
  await assert.rejects(h.setAiPrivacyConsent(current, auth('patient', false, 'anonymous')), { code: 'unauthenticated' });
  for (const data of [null, {}, { accepted: 'true', version: '2026-10-01' }, { accepted: true, version: 'old' }]) {
    await assert.rejects(h.setAiPrivacyConsent(data, auth()), { code: 'invalid-argument' });
  }
  assert.equal(h.writes.length, 0);
});

test('failed consent persistence does not report success', async () => {
  const h = harness({ failWrite: true });
  assert.equal(typeof h.setAiPrivacyConsent, 'function');
  await assert.rejects(h.setAiPrivacyConsent(current, auth()), /write failed/);
});

for (const [label, consent, patientExists] of [
  ['missing', undefined, true], ['missing profile', undefined, false],
  ['declined', { accepted: false, version: '2026-10-01' }, true],
  ['outdated', { accepted: true, version: '2025-01-01' }, true],
  ['malformed', { accepted: 'true', version: '2026-10-01' }, true],
]) {
  for (const name of ['chatWithGemini', 'generateUserReport']) {
    test(name + ' blocks ' + label + ' patient consent before Google', async () => {
      const h = harness({ consent, patientExists });
      await assert.rejects(h[name](name === 'chatWithGemini' ? chatData : { userId: 'patient' }, name === 'chatWithGemini' ? auth() : auth('staff', true)), error =>
        error.code === 'permission-denied' && error.details?.reason === 'ai-consent-required');
      assert.equal(h.externalCalls(), 0);
      assert.ok(h.reads.includes('users/patient'));
    });
  }
}
test('accepted current consent permits chat and staff report without staff consent', async () => {
  for (const name of ['chatWithGemini', 'generateUserReport']) {
    const h = harness({ consent: current });
    h.users.set('staff', { ai_privacy_consent: { accepted: false, version: '2026-10-01' } });
    await h[name](name === 'chatWithGemini' ? chatData : { userId: 'patient' }, name === 'chatWithGemini' ? auth() : auth('staff', true));
    assert.equal(h.externalCalls(), 1);
  }
});
test('therapist reports use patient consent, not therapist acceptance', async () => {
  const h = harness();
  await assert.rejects(h.generateUserReport({ userId: 'patient' }, auth('staff')), error =>
    error.code === 'permission-denied' && error.details?.reason === 'ai-consent-required');
  assert.equal(h.externalCalls(), 0);
});
test('revocation takes effect on subsequent chat and report requests', async () => {
  const h = harness({ consent: current });
  assert.equal(typeof h.setAiPrivacyConsent, 'function');
  await h.chatWithGemini(chatData, auth());
  await h.setAiPrivacyConsent({ accepted: false, version: '2026-10-01' }, auth());
  await assert.rejects(h.chatWithGemini(chatData, auth()), { code: 'permission-denied' });
  await assert.rejects(h.generateUserReport({ userId: 'patient' }, auth('staff', true)), { code: 'permission-denied' });
  assert.equal(h.externalCalls(), 1);
});
test('chat cannot borrow another account consent', async () => {
  const h = harness({ consent: current });
  await assert.rejects(h.chatWithGemini({ ...chatData, userId: 'patient' }, auth('outsider')), { code: 'permission-denied' });
  await assert.rejects(h.chatWithGemini(chatData, auth('outsider')), { code: 'permission-denied' });
  assert.equal(h.externalCalls(), 0);
});
test('unauthenticated AI callers never reach Google', async () => {
  const h = harness({ consent: current });
  for (const name of ['chatWithGemini', 'generateUserReport']) {
    await assert.rejects(h[name]({ userId: 'patient', ...chatData }, {}), { code: 'unauthenticated' });
  }
  assert.equal(h.externalCalls(), 0);
});
test('deterministic briefing remains available without AI consent', async () => {
  const h = harness();
  assert.equal((await h.generateUserBriefing({ userId: 'patient' }, auth())).briefing.markdown, 'local summary');
  assert.equal(h.externalCalls(), 0);
});

for (const name of ['chatWithGemini', 'generateUserReport']) {
  test(name + ' rechecks consent after context generation before transferring to Google', async () => {
    const h = harness({ consent: current, revokeDuringContext: true });
    await assert.rejects(h[name](name === 'chatWithGemini' ? chatData : { userId: 'patient' }, name === 'chatWithGemini' ? auth() : auth('staff', true)), { code: 'permission-denied' });
    assert.equal(h.externalCalls(), 0);
  });
  test(name + ' fails closed if the consent read fails', async () => {
    const h = harness({ consent: current, failConsentRead: true });
    await assert.rejects(h[name](name === 'chatWithGemini' ? chatData : { userId: 'patient' }, name === 'chatWithGemini' ? auth() : auth('staff', true)), /consent read failed/);
    assert.equal(h.externalCalls(), 0);
  });
}
test('report fallback rechecks consent if revoked after the first Google request', async () => {
  const h = harness({ consent: current, failFirstReport: true, revokeBeforeFallback: true });
  await assert.rejects(h.generateUserReport({ userId: 'patient' }, auth('staff', true)), { code: 'permission-denied' });
  assert.equal(h.externalCalls(), 1);
});
test('report fallback remains available while current patient consent is accepted', async () => {
  const h = harness({ consent: current, failFirstReport: true });
  await h.generateUserReport({ userId: 'patient' }, auth('staff', true));
  assert.equal(h.externalCalls(), 2);
});

test('optional expectedUserId matches the authenticated caller and is not persisted', async () => {
  const h = harness();
  await h.setAiPrivacyConsent({ ...current, expectedUserId: 'patient' }, auth());
  assert.equal(h.writes.length, 1);
  assert.equal(h.writes[0].path, 'users/patient');
  assert.deepEqual(Object.keys(h.writes[0].value.ai_privacy_consent).sort(), ['accepted', 'updated_at', 'version']);
});
test('expectedUserId mismatch rejects account switches without writing either account', async () => {
  for (const accepted of [true, false]) {
    const h = harness();
    await assert.rejects(h.setAiPrivacyConsent({ ...current, accepted, expectedUserId: 'patient' }, auth('staff')), { code: 'permission-denied' });
    assert.equal(h.writes.length, 0);
  }
});
test('present expectedUserId must be a nonempty string before any write', async () => {
  for (const expectedUserId of ['', null, undefined, false, 42, [], {}]) {
    const h = harness();
    await assert.rejects(h.setAiPrivacyConsent({ ...current, expectedUserId }, auth()), { code: 'invalid-argument' });
    assert.equal(h.writes.length, 0);
  }
});
test('missing expectedUserId preserves the original callable protocol', async () => {
  const h = harness();
  await h.setAiPrivacyConsent(current, auth());
  assert.equal(h.writes.length, 1);
  assert.equal(h.writes[0].path, 'users/patient');
});
