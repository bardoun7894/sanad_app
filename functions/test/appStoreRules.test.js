'use strict';
const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, Timestamp } = require('firebase/firestore');
let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-sanad-rules',
    firestore: { rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());
const owner = () => env.authenticatedContext('patient', {
  admin: false, email: 'patient@example.com', firebase: { sign_in_provider: 'password' },
}).firestore();
const apple = {
  role: 'user', payment_gateway: 'app_store', subscription_status: 'active',
  subscription_plan: 'premium', subscription_expiry_date: Timestamp.fromMillis(1900000000000),
  is_premium: true, auto_renew: true, app_store_original_transaction_id: '1001',
  app_store_environment: 'Production', app_store_purchase_date: Timestamp.fromMillis(1800000000000),
};
async function seed(data = apple) {
  await env.withSecurityRulesDisabled(async (context) => setDoc(doc(context.firestore(), 'users/patient'), data));
}
test('owner may create ordinary profile but cannot self-promote to admin', async () => {
  await assertFails(setDoc(doc(owner(), 'users/patient'), { role: 'admin' }));
  await assertSucceeds(setDoc(doc(owner(), 'users/patient'), { role: 'user', name: 'Patient' }));
  await assertFails(updateDoc(doc(owner(), 'users/patient'), { role: 'admin' }));
});
test('owner cannot create Apple entitlement or transaction identity', async () => {
  await assertFails(setDoc(doc(owner(), 'users/patient'), apple));
  await assertFails(setDoc(doc(owner(), 'users/patient'), { role: 'user', app_store_purchase_date: Timestamp.now() }));
});
test('Apple owner can edit profile but cannot alter access or escape gateway', async () => {
  await seed();
  await assertSucceeds(updateDoc(doc(owner(), 'users/patient'), { name: 'New name' }));
  for (const changes of [
    { payment_gateway: 'paypal' }, { subscription_plan: 'premium_vip' },
    { subscription_expiry_date: Timestamp.fromMillis(1999999999999) },
    { app_store_purchase_date: Timestamp.now() }, { app_store_original_transaction_id: '9999' },
    { role: 'admin' }, { auto_renew: false }, { is_premium: false },
  ]) await assertFails(updateDoc(doc(owner(), 'users/patient'), changes));
});
test('ordinary owner cannot attach Apple identity or modify server ledger', async () => {
  await seed({ role: 'user', name: 'Patient' });
  await assertFails(updateDoc(doc(owner(), 'users/patient'), { payment_gateway: 'app_store' }));
  await assertFails(updateDoc(doc(owner(), 'users/patient'), { app_store_environment: 'Sandbox' }));
  await assertFails(setDoc(doc(owner(), 'app_store_accounts/account'), { user_id: 'patient' }));
  await assertFails(setDoc(doc(owner(), 'app_store_subscriptions/1001'), { user_id: 'patient' }));
});
test('trusted admin can manage users and Apple ledger', async () => {
  await seed();
  const db = env.authenticatedContext('staff', { admin: true }).firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/patient'), { subscription_status: 'expired' }));
  await assertSucceeds(setDoc(doc(db, 'app_store_subscriptions/1001'), { user_id: 'patient' }));
});

test('ordinary and Apple owners may enter pending therapist registration without admin elevation', async () => {
  for (const data of [{ role: 'user' }, apple]) {
    await seed(data);
    await assertSucceeds(updateDoc(doc(owner(), 'users/patient'), {
      role: 'therapist', therapist_status: 'pending',
    }));
    await assertFails(updateDoc(doc(owner(), 'users/patient'), { role: 'admin' }));
  }
});
