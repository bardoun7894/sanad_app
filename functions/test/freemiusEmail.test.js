'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  buyerEmailFor,
  uidFromBuyerEmail,
  pickRecentUnpaidPending,
} = require('../lib/freemiusEmail');

const UID = 'QXa9Zk3PLmN0bC7dE2fG4hJ6kL8m';

test('phone-auth user gets a deliverable plus-address, not the firebaseapp one', () => {
  assert.equal(buyerEmailFor('', UID), `sanadpsy+${UID}@gmail.com`);
  assert.equal(buyerEmailFor(undefined, UID), `sanadpsy+${UID}@gmail.com`);
  assert.equal(buyerEmailFor('not-an-email', UID), `sanadpsy+${UID}@gmail.com`);
  // Old app builds still send the synthetic address: rewrite it.
  assert.equal(buyerEmailFor(`${UID}@sanad-app.firebaseapp.com`, UID), `sanadpsy+${UID}@gmail.com`);
});

test('a real email is kept as is', () => {
  assert.equal(buyerEmailFor('  amal@example.com ', UID), 'amal@example.com');
});

test('uid comes back from both the new and the legacy synthetic address', () => {
  assert.equal(uidFromBuyerEmail(`sanadpsy+${UID}@gmail.com`), UID);
  assert.equal(uidFromBuyerEmail(`SanadPsy+${UID}@Gmail.com`), UID);
  assert.equal(uidFromBuyerEmail(`${UID}@sanad-app.firebaseapp.com`), UID);
  assert.equal(uidFromBuyerEmail('amal@example.com'), null);
  assert.equal(uidFromBuyerEmail('sanadpsy@gmail.com'), null);
  assert.equal(uidFromBuyerEmail(''), null);
});

test('pickRecentUnpaidPending matches a single recent unpaid checkout when buyer types custom email', () => {
  const nowMs = 1_700_000_000_000;
  const records = [
    {
      id: UID,
      user_id: UID,
      plan_id: 'plan_weekly',
      product_id: 'prod_1',
      created_at: { toMillis: () => nowMs - 10 * 60 * 1000 }, // 10 min ago
    },
  ];
  assert.equal(
    pickRecentUnpaidPending(records, { planId: 'plan_weekly', productId: 'prod_1', nowMs }),
    UID,
  );
});

test('pickRecentUnpaidPending ignores paid or expired (>2h) checkouts and rejects ambiguous multiples', () => {
  const nowMs = 1_700_000_000_000;
  // Already paid -> null
  assert.equal(
    pickRecentUnpaidPending(
      [{ id: UID, user_id: UID, created_at: nowMs - 60_000, paid_at: nowMs - 10_000 }],
      { nowMs },
    ),
    null,
  );
  // Older than 2 hours -> null
  assert.equal(
    pickRecentUnpaidPending(
      [{ id: UID, user_id: UID, created_at: nowMs - 3 * 60 * 60 * 1000 }],
      { nowMs },
    ),
    null,
  );
  // Two unpaid checkouts on the same plan -> null (ambiguous)
  assert.equal(
    pickRecentUnpaidPending(
      [
        { id: 'u1', user_id: 'u1', plan_id: 'p1', created_at: nowMs - 60_000 },
        { id: 'u2', user_id: 'u2', plan_id: 'p1', created_at: nowMs - 30_000 },
      ],
      { planId: 'p1', nowMs },
    ),
    null,
  );
  // Two unpaid checkouts on different plans -> disambiguates by planId
  assert.equal(
    pickRecentUnpaidPending(
      [
        { id: 'u1', user_id: 'u1', plan_id: 'p1', created_at: nowMs - 60_000 },
        { id: 'u2', user_id: 'u2', plan_id: 'p2', created_at: nowMs - 30_000 },
      ],
      { planId: 'p2', nowMs },
    ),
    'u2',
  );
});

