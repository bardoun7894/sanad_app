/**
 * Unit tests for the chat access stamper helpers.
 *
 * These helpers capture the pure access-decision logic extracted from the
 * Cloud Function triggers so they can be tested without the Admin SDK or
 * Firestore emulator.
 *
 * Run: node --test test/chatAccessStamper.test.js
 */

'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');

// ── Helpers under test ────────────────────────────────────────────────────────

/**
 * Compute the user_access value that should be stamped on
 * therapist_chats/{therapistId}_{userId} given a booking state.
 *
 * Returns:
 *   'full'      — user may read + send
 *   'read_only' — user may read history only
 *   null        — no change / do not write
 *
 * @param {object} after  - booking document data after the update
 * @param {object} userDoc - users/{client_id} document data (may be null if missing)
 */
function computeAccessFromBooking(after, userDoc) {
  const { status, payment_status, therapist_id, client_id } = after;

  if (!therapist_id || !client_id) return null;

  // Active booking → full access
  if (
    payment_status === 'paid' &&
    (status === 'pending' || status === 'confirmed')
  ) {
    return 'full';
  }

  // Completed booking → read_only UNLESS user still has an active subscription
  // assigned to this therapist
  if (status === 'completed') {
    const hasActiveSub =
      userDoc &&
      userDoc.is_premium === true &&
      userDoc.assigned_therapist_id === therapist_id;
    return hasActiveSub ? 'full' : 'read_only';
  }

  // Other transitions (cancelled, rejected, awaiting_payment…) → no change
  return null;
}

/**
 * Compute the user_access value based on subscription state changes on a user
 * document.
 *
 * Returns:
 *   'full'      — grant full access
 *   'read_only' — downgrade to read-only
 *   null        — no subscription-relevant change, skip
 *
 * @param {object} before  - users/{userId} data before
 * @param {object} after   - users/{userId} data after
 */
function computeAccessFromSubscription(before, after) {
  const premiumChanged = before.is_premium !== after.is_premium;
  const statusChanged  = before.subscription_status !== after.subscription_status;

  if (!premiumChanged && !statusChanged) return null;

  const assignedTherapistId = after.assigned_therapist_id || null;
  if (!assignedTherapistId) return null;

  if (after.is_premium === true && after.assigned_therapist_id) {
    return 'full';
  }

  // Premium lost: downgrade only (don't create the doc if absent)
  if (before.is_premium === true && after.is_premium !== true) {
    return 'read_only';
  }

  return null;
}

// ── Tests: computeAccessFromBooking ───────────────────────────────────────────

test('returns full for pending + paid booking', () => {
  const after = {
    status: 'pending',
    payment_status: 'paid',
    therapist_id: 'T1',
    client_id: 'U1',
  };
  assert.equal(computeAccessFromBooking(after, null), 'full');
});

test('returns full for confirmed + paid booking', () => {
  const after = {
    status: 'confirmed',
    payment_status: 'paid',
    therapist_id: 'T1',
    client_id: 'U1',
  };
  assert.equal(computeAccessFromBooking(after, null), 'full');
});

test('returns read_only for completed booking with no active subscription', () => {
  const after = {
    status: 'completed',
    payment_status: 'paid',
    therapist_id: 'T1',
    client_id: 'U1',
  };
  assert.equal(computeAccessFromBooking(after, null), 'read_only');
});

test('returns read_only for completed booking when user subscription assigned to different therapist', () => {
  const after = {
    status: 'completed',
    payment_status: 'paid',
    therapist_id: 'T1',
    client_id: 'U1',
  };
  const userDoc = { is_premium: true, assigned_therapist_id: 'T2' };
  assert.equal(computeAccessFromBooking(after, userDoc), 'read_only');
});

test('returns full for completed booking when user has active subscription with this therapist', () => {
  const after = {
    status: 'completed',
    payment_status: 'paid',
    therapist_id: 'T1',
    client_id: 'U1',
  };
  const userDoc = { is_premium: true, assigned_therapist_id: 'T1' };
  assert.equal(computeAccessFromBooking(after, userDoc), 'full');
});

test('returns null for cancelled booking', () => {
  const after = {
    status: 'cancelled',
    payment_status: 'paid',
    therapist_id: 'T1',
    client_id: 'U1',
  };
  assert.equal(computeAccessFromBooking(after, null), null);
});

test('returns null for rejected booking', () => {
  const after = {
    status: 'rejected',
    payment_status: 'paid',
    therapist_id: 'T1',
    client_id: 'U1',
  };
  assert.equal(computeAccessFromBooking(after, null), null);
});

test('returns null when payment_status is not paid and status is pending', () => {
  const after = {
    status: 'pending',
    payment_status: 'awaiting_payment',
    therapist_id: 'T1',
    client_id: 'U1',
  };
  assert.equal(computeAccessFromBooking(after, null), null);
});

test('returns null when therapist_id is missing', () => {
  const after = {
    status: 'pending',
    payment_status: 'paid',
    therapist_id: '',
    client_id: 'U1',
  };
  assert.equal(computeAccessFromBooking(after, null), null);
});

test('returns null when client_id is missing', () => {
  const after = {
    status: 'pending',
    payment_status: 'paid',
    therapist_id: 'T1',
    client_id: null,
  };
  assert.equal(computeAccessFromBooking(after, null), null);
});

// ── Tests: computeAccessFromSubscription ─────────────────────────────────────

test('returns full when user gains premium with assigned therapist', () => {
  const before = { is_premium: false, assigned_therapist_id: 'T1' };
  const after  = { is_premium: true,  assigned_therapist_id: 'T1' };
  assert.equal(computeAccessFromSubscription(before, after), 'full');
});

test('returns read_only when user loses premium', () => {
  const before = { is_premium: true,  assigned_therapist_id: 'T1' };
  const after  = { is_premium: false, assigned_therapist_id: 'T1' };
  assert.equal(computeAccessFromSubscription(before, after), 'read_only');
});

test('returns null when no premium or subscription_status change', () => {
  const before = { is_premium: true, subscription_status: 'active', assigned_therapist_id: 'T1' };
  const after  = { is_premium: true, subscription_status: 'active', assigned_therapist_id: 'T1' };
  assert.equal(computeAccessFromSubscription(before, after), null);
});

test('returns null when premium gained but no assigned therapist', () => {
  const before = { is_premium: false };
  const after  = { is_premium: true };
  assert.equal(computeAccessFromSubscription(before, after), null);
});

test('returns full when subscription_status changes to active while premium', () => {
  const before = { is_premium: true, subscription_status: 'inactive', assigned_therapist_id: 'T1' };
  const after  = { is_premium: true, subscription_status: 'active',   assigned_therapist_id: 'T1' };
  assert.equal(computeAccessFromSubscription(before, after), 'full');
});
