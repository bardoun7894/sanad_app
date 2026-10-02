'use strict';
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, deleteField, Timestamp } = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-sanad-ai-consent',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());
const context = (uid = 'patient', admin = false) => env.authenticatedContext(uid, {
  admin, email: uid + '@example.com', firebase: { sign_in_provider: 'password' },
}).firestore();
const consent = { accepted: true, version: '2026-10-01', updated_at: Timestamp.now() };
async function seed(data = { role: 'user', name: 'Patient', ai_privacy_consent: consent }) {
  await env.withSecurityRulesDisabled(async ctx => setDoc(doc(ctx.firestore(), 'users/patient'), data));
}
for (const [uid, admin] of [['patient', false], ['staff', true]]) {
  test(uid + ' cannot create a profile containing client-authored consent', async () => {
    await assertFails(setDoc(doc(context(uid, admin), 'users/patient'), { role: 'user', ai_privacy_consent: consent }));
  });
  test(uid + ' cannot add, replace, edit or remove consent', async () => {
    const ref = doc(context(uid, admin), 'users/patient');
    await seed({ role: 'user' });
    await assertFails(updateDoc(ref, { ai_privacy_consent: consent }));
    await seed();
    await assertFails(updateDoc(ref, { ai_privacy_consent: { ...consent, accepted: false } }));
    await assertFails(updateDoc(ref, { 'ai_privacy_consent.accepted': false }));
    await assertFails(updateDoc(ref, { 'ai_privacy_consent.version': 'old' }));
    await assertFails(updateDoc(ref, { ai_privacy_consent: deleteField() }));
    await assertFails(setDoc(ref, { role: 'user', name: 'Replacement' }));
  });
}
test('ordinary profile creation and therapist registration preserve existing consent', async () => {
  const ref = doc(context(), 'users/patient');
  await assertSucceeds(setDoc(ref, { role: 'user', name: 'Patient' }));
  await assertSucceeds(updateDoc(ref, { role: 'therapist', therapist_status: 'pending' }));
  await seed();
  await assertSucceeds(updateDoc(ref, { name: 'Updated' }));
  await assertSucceeds(updateDoc(ref, { role: 'therapist', therapist_status: 'pending' }));
  await assertSucceeds(getDoc(ref));
});
test('trusted server writes consent and ordinary admin edits remain allowed', async () => {
  await seed();
  await env.withSecurityRulesDisabled(async ctx => {
    await assertSucceeds(updateDoc(doc(ctx.firestore(), 'users/patient'), { ai_privacy_consent: { ...consent, accepted: false } }));
  });
  await assertSucceeds(updateDoc(doc(context('staff', true), 'users/patient'), { name: 'Staff edit', subscription_status: 'active' }));
});
test('outsider cannot write another account consent or profile', async () => {
  await seed();
  const ref = doc(context('outsider'), 'users/patient');
  await assertFails(updateDoc(ref, { ai_privacy_consent: consent }));
  await assertFails(updateDoc(ref, { name: 'Forged' }));
});
test('human therapist chat stays writable when AI consent is absent', async () => {
  await seed({ role: 'user' });
  await env.withSecurityRulesDisabled(async ctx =>
    setDoc(doc(ctx.firestore(), 'therapist_chats/thread'), { user_id: 'patient', therapist_id: 'therapist', user_access: 'full' }));
  await assertSucceeds(setDoc(doc(context(), 'therapist_chats/thread/messages/message'), { sender_id: 'patient', content: 'Human conversation' }));
});
