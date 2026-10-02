const test = require('node:test');
const assert = require('node:assert/strict');
const { accountTokenFor, subscriptionState, createAppStoreService } = require('../lib/appStoreSubscriptions');

const now = 1800000000000;
const uid = 'patient-one';
const transaction = (overrides = {}) => ({
  bundleId: 'com.sanadtherapy.app', productId: 'com.sanadtherapy.app.premium',
  type: 'Auto-Renewable Subscription', transactionId: '2001', originalTransactionId: '1001',
  appAccountToken: accountTokenFor(uid), expiresDate: now + 60000,
  purchaseDate: now - 60000, signedDate: now, environment: 'Sandbox', price: 34900, currency: 'USD', ...overrides,
});

function harness(overrides = {}) {
  const docs = new Map([['users/' + uid, {}]]);
  const ref = (path) => ({ path, async get() { return snap(path); } });
  const snap = (path) => ({ exists: docs.has(path), data: () => docs.get(path) });
  const db = {
    collection: (name) => ({ doc: (id) => ref(name + '/' + id) }),
    async runTransaction(fn) {
      const writes = [];
      const value = await fn({
        get: async (r) => snap(r.path),
        set: (r, data, opts) => writes.push([r.path, data, opts]),
      });
      for (const [path, data, opts] of writes) {
        docs.set(path, opts?.merge ? { ...docs.get(path), ...data } : data);
      }
      return value;
    },
  };
  const tx = transaction(overrides);
  let status = 1;
  let renewal = { autoRenewStatus: 1, signedDate: now };
  const service = createAppStoreService({
    db, now: () => now, timestamp: (ms) => ms,
    verifyTransaction: async (signed) => {
      if (signed === 'forged') throw new Error('Invalid signature');
      return tx;
    },
    fetchStatus: async () => ({ transaction: tx, renewal, status }),
  });
  return { service, docs, tx, setStatus: (s) => { status = s; },
    setRenewal: (r) => { renewal = r; } };
}

test('account tokens are stable UUIDs and distinct per Sanad user', () => {
  assert.match(accountTokenFor(uid), /^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
  assert.equal(accountTokenFor(uid), accountTokenFor(uid));
  assert.notEqual(accountTokenFor(uid), accountTokenFor('patient-two'));
});

test('refunds and expiry deny access; cancellation keeps paid access', () => {
  assert.equal(subscriptionState(transaction({ revocationDate: now }), {}, 5, now).active, false);
  assert.equal(subscriptionState(transaction({ expiresDate: now }), {}, 2, now).active, false);
  const canceled = subscriptionState(transaction(), { autoRenewStatus: 0 }, 1, now);
  assert.equal(canceled.active, true);
  assert.equal(canceled.autoRenew, false);
});

test('only Apple-confirmed grace period extends access', () => {
  const expired = transaction({ expiresDate: now - 1 });
  assert.equal(subscriptionState(expired, { gracePeriodExpiresDate: now + 1000 }, 3, now).active, false);
  assert.equal(subscriptionState(expired, { gracePeriodExpiresDate: now + 1000 }, 4, now).active, true);
});

test('verified purchase writes exact Apple expiry and is idempotent', async () => {
  const h = harness();
  await h.service.verifyPurchase(uid, 'signed');
  await h.service.verifyPurchase(uid, 'signed');
  assert.equal(h.docs.get('users/' + uid).subscription_expiry_date, now + 60000);
  assert.equal(h.docs.get('users/' + uid).subscription_plan, 'premium');
  assert.equal(h.docs.get('users/' + uid).payment_gateway, 'app_store');
  assert.equal([...h.docs.keys()].filter((p) => p.startsWith('payments/')).length, 1);
});

test('forged JWS cannot grant access', async () => {
  const h = harness();
  await assert.rejects(h.service.verifyPurchase(uid, 'forged'), /Invalid signature/);
  assert.deepEqual(h.docs.get('users/' + uid), {});
});

test('wrong account, wrong bundle, and unsupported products cannot grant access', async () => {
  for (const overrides of [
    { appAccountToken: accountTokenFor('another-user') },
    { appAccountToken: undefined },
    { bundleId: 'another.app' },
    { productId: 'com.sanadtherapy.app.fake' },
    { type: 'Consumable' },
  ]) {
    const h = harness(overrides);
    await assert.rejects(h.service.verifyPurchase(uid, 'signed'));
    assert.deepEqual(h.docs.get('users/' + uid), {});
  }
});

test('fresh Apple status overrides an old successful transaction after refund', async () => {
  const h = harness();
  await h.service.verifyPurchase(uid, 'signed');
  h.tx.revocationDate = now;
  h.setStatus(5);
  await h.service.verifyPurchase(uid, 'signed');
  assert.equal(h.docs.get('users/' + uid).is_premium, false);
});

test('original transaction cannot move between Sanad accounts', async () => {
  const h = harness();
  h.docs.set('app_store_subscriptions/Sandbox_1001', { user_id: 'another-user', signed_date: now });
  await assert.rejects(h.service.verifyPurchase(uid, 'signed'), /another account/);
});

test('older status snapshots cannot overwrite a newer renewal', async () => {
  const h = harness();
  await h.service.verifyPurchase(uid, 'signed');
  h.tx.signedDate = now - 1000;
  h.tx.expiresDate = now - 1;
  h.setStatus(2);
  h.setRenewal({ signedDate: now - 1000, autoRenewStatus: 0 });
  await h.service.verifyPurchase(uid, 'signed');
  assert.equal(h.docs.get('users/' + uid).is_premium, true);
});


test('old Apple refunds cannot revoke a newer Apple lineage', async () => {
  const h = harness({ revocationDate: now });
  const user = { is_premium: true, payment_gateway: 'app_store',
    app_store_original_transaction_id: '9999', app_store_environment: 'Sandbox',
    app_store_purchase_date: now, subscription_expiry_date: now + 120000,
    subscription_plan: 'premium_vip', subscription_status: 'active' };
  h.docs.set('users/' + uid, user);
  h.setStatus(5);
  await h.service.verifyPurchase(uid, 'signed');
  assert.deepEqual(h.docs.get('users/' + uid), user);
  assert.equal(h.docs.get('app_store_subscriptions/Sandbox_1001').active, false);
});

test('Apple updates preserve active external and permanent admin entitlements', async () => {
  for (const expiry of [now + 120000, undefined]) {
    const h = harness();
    const user = { is_premium: true, payment_gateway: 'bank_transfer',
      subscription_expiry_date: expiry, subscription_plan: 'premium_vip' };
    h.docs.set('users/' + uid, user);
    await h.service.verifyPurchase(uid, 'signed');
    assert.deepEqual(h.docs.get('users/' + uid), user);
    assert.equal(h.docs.get('app_store_subscriptions/Sandbox_1001').active, true);
    assert.equal([...h.docs.keys()].filter((p) => p.startsWith('payments/')).length, 1);
  }
});

test('an old active lineage cannot replace a later Apple purchase', async () => {
  const h = harness({ expiresDate: now + 500000 });
  const user = { is_premium: true, payment_gateway: 'app_store',
    app_store_original_transaction_id: '9999', app_store_environment: 'Sandbox',
    app_store_purchase_date: now, subscription_expiry_date: now + 120000 };
  h.docs.set('users/' + uid, user);
  await h.service.verifyPurchase(uid, 'signed');
  assert.deepEqual(h.docs.get('users/' + uid), user);
});

test('a newer renewal signature cannot conceal an older transaction snapshot', async () => {
  const h = harness();
  await h.service.verifyPurchase(uid, 'signed');
  h.tx.signedDate = now - 1000;
  h.tx.expiresDate = now - 1;
  h.setStatus(2);
  h.setRenewal({ signedDate: now + 1000, autoRenewStatus: 0 });
  await h.service.verifyPurchase(uid, 'signed');
  assert.equal(h.docs.get('users/' + uid).is_premium, true);
});
