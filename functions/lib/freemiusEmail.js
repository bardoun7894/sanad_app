'use strict';

/**
 * Buyer email for the Freemius checkout of a user who has no real email
 * (phone sign-up). Freemius flags undeliverable addresses such as
 * `<uid>@sanad-app.firebaseapp.com` ("typo or flagged for security"), so we
 * use a plus-address on the clinic's Gmail: deliverable, receipts reach the
 * clinic, and the uid after "+" lets the webhook find the account.
 */

const CLINIC_MAILBOX = 'sanadpsy';
const CLINIC_DOMAIN = 'gmail.com';
const PLUS_RE = new RegExp(`^${CLINIC_MAILBOX}\\+([A-Za-z0-9_-]+)@${CLINIC_DOMAIN.replace('.', '\\.')}$`, 'i');
const LEGACY_RE = /^([A-Za-z0-9_-]+)@sanad-app\.firebaseapp\.com$/i;

function buyerEmailFor(email, uid) {
  const raw = typeof email === 'string' ? email.trim() : '';
  if (raw.includes('@') && !LEGACY_RE.test(raw)) return raw;
  return `${CLINIC_MAILBOX}+${uid}@${CLINIC_DOMAIN}`;
}

/** The uid encoded in a synthetic buyer email, or null for a real email. */
function uidFromBuyerEmail(email) {
  const raw = typeof email === 'string' ? email.trim() : '';
  const m = raw.match(PLUS_RE) || raw.match(LEGACY_RE);
  return m ? m[1] : null;
}

const DEFAULT_PENDING_WINDOW_MS = 2 * 60 * 60 * 1000; // 2 hours

function _toEpochMs(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (value instanceof Date) return value.getTime();
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value._seconds === 'number') return value._seconds * 1000;
  if (typeof value.seconds === 'number') return value.seconds * 1000;
  const parsed = Date.parse(String(value));
  return Number.isNaN(parsed) ? null : parsed;
}

/**
 * Fallback matcher when a phone-auth customer replaces the pre-filled synthetic
 * email on the Freemius hosted checkout with her own email address.
 *
 * Given an array of `freemius_pending_purchases` records (`{ id, user_id,
 * plan_id, product_id, created_at, paid_at }`), returns the `uid` of the
 * recent unpaid checkout within `maxAgeMs` (default 2h) ONLY when there is a
 * single unambiguous candidate (matching `planId`/`productId` if provided).
 */
function pickRecentUnpaidPending(
  records,
  { planId = '', productId = '', nowMs = Date.now(), maxAgeMs = DEFAULT_PENDING_WINDOW_MS } = {},
) {
  if (!Array.isArray(records) || records.length === 0) return null;
  const minCreatedMs = nowMs - maxAgeMs;
  const wantPlan = String(planId || '').trim();
  const wantProduct = String(productId || '').trim();

  const unpaidRecent = records.filter((r) => {
    if (!r || r.paid_at) return false;
    const uid = r.user_id || r.id;
    if (!uid) return false;
    const createdMs = _toEpochMs(r.created_at);
    if (createdMs === null || createdMs < minCreatedMs || createdMs > nowMs + 60_000) {
      return false;
    }
    return true;
  });

  if (unpaidRecent.length === 0) return null;

  // Narrow by plan_id / product_id when the webhook provides them.
  let matched = unpaidRecent;
  if (wantPlan) {
    const byPlan = matched.filter((r) => String(r.plan_id || '').trim() === wantPlan);
    if (byPlan.length > 0) matched = byPlan;
  }
  if (wantProduct) {
    const byProduct = matched.filter((r) => String(r.product_id || '').trim() === wantProduct);
    if (byProduct.length > 0) matched = byProduct;
  }

  if (matched.length !== 1) return null;
  return matched[0].user_id || matched[0].id || null;
}

module.exports = {
  buyerEmailFor,
  uidFromBuyerEmail,
  pickRecentUnpaidPending,
  DEFAULT_PENDING_WINDOW_MS,
};

