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

module.exports = { buyerEmailFor, uidFromBuyerEmail };
