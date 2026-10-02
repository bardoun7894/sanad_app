const { createHash } = require('node:crypto');

const BUNDLE_ID = 'com.sanadtherapy.app';
const APPLE_APP_ID = 6817892036;
const PRODUCTS = Object.freeze({
  [`${BUNDLE_ID}.weekly`]: 'weekly',
  [`${BUNDLE_ID}.basic`]: 'basic',
  [`${BUNDLE_ID}.premium`]: 'premium',
  [`${BUNDLE_ID}.premium_vip`]: 'premium_vip',
});

class AppStoreError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}

function accountTokenFor(uid) {
  const bytes = createHash('sha256').update(`sanad-app-store:${uid}`).digest().subarray(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function validateTransaction(tx, uid) {
  if (tx.bundleId !== BUNDLE_ID || !PRODUCTS[tx.productId] ||
      tx.type !== 'Auto-Renewable Subscription' ||
      !/^\d+$/.test(tx.transactionId || '') || !/^\d+$/.test(tx.originalTransactionId || '') ||
      !['Production', 'Sandbox'].includes(tx.environment) ||
      !Number.isFinite(tx.expiresDate) || !Number.isFinite(tx.signedDate) ||
      !Number.isFinite(tx.purchaseDate)) {
    throw new AppStoreError('invalid-argument', 'Unsupported App Store transaction.');
  }
  if (tx.appAccountToken?.toLowerCase() !== accountTokenFor(uid)) {
    throw new AppStoreError('permission-denied', 'This purchase belongs to another account.');
  }
}

function subscriptionState(tx, renewal, status, now) {
  const expiry = status === 4 && Number.isFinite(renewal.gracePeriodExpiresDate)
    ? Math.max(tx.expiresDate, renewal.gracePeriodExpiresDate) : tx.expiresDate;
  const active = !tx.revocationDate && [1, 4].includes(status) && expiry > now;
  return { active, expiry, autoRenew: active && renewal.autoRenewStatus === 1 };
}

function millis(value) {
  return typeof value?.toMillis === 'function' ? value.toMillis() : value;
}

function hasActiveEntitlement(user, now) {
  const expiry = millis(user.subscription_expiry_date ?? user.subscription_end_date);
  return (user.is_premium === true || ['active', 'cancelled'].includes(user.subscription_status)) &&
    (expiry == null || (Number.isFinite(expiry) && expiry > now));
}

function canSelectEntitlement(user, tx, entitlement, now) {
  if (user.payment_gateway !== 'app_store') return !hasActiveEntitlement(user, now);
  const sameSubscription = user.app_store_original_transaction_id === tx.originalTransactionId &&
    user.app_store_environment === tx.environment;
  if (sameSubscription) return true;
  // An old lineage's refund/expiry must never revoke the selected subscription.
  if (!entitlement.active) return false;
  const selectedPurchase = millis(user.app_store_purchase_date);
  if (Number.isFinite(selectedPurchase)) return tx.purchaseDate > selectedPurchase;
  const selectedExpiry = millis(user.subscription_expiry_date);
  return !hasActiveEntitlement(user, now) || entitlement.expiry > selectedExpiry;
}

function createAppStoreService({ db, verifyTransaction, fetchStatus, timestamp, now = Date.now }) {
  async function reconcile(uid, originalId, environment) {
    const { transaction: tx, renewal, status } = await fetchStatus(originalId, environment);
    validateTransaction(tx, uid);
    if (tx.originalTransactionId !== originalId || tx.environment !== environment) {
      throw new AppStoreError('permission-denied', 'Subscription identity mismatch.');
    }
    const currentTime = now();
    const entitlement = subscriptionState(tx, renewal, status, currentTime);
    const signedDate = Math.max(tx.signedDate, renewal.signedDate || 0);
    const subRef = db.collection('app_store_subscriptions').doc(`${environment}_${originalId}`);
    const userRef = db.collection('users').doc(uid);
    const paymentRef = db.collection('payments').doc(`app_store_${environment}_${tx.transactionId}`);

    return db.runTransaction(async (t) => {
      const [previous, user, payment] = await Promise.all([t.get(subRef), t.get(userRef), t.get(paymentRef)]);
      if (!user.exists) throw new AppStoreError('failed-precondition', 'Complete your Sanad account first.');
      if (previous.exists && previous.data().user_id !== uid) {
        throw new AppStoreError('permission-denied', 'This purchase belongs to another account.');
      }
      if (previous.exists && (previous.data().signed_date > signedDate ||
          previous.data().transaction_signed_date > tx.signedDate ||
          previous.data().renewal_signed_date > (renewal.signedDate || 0))) {
        return { success: true, active: hasActiveEntitlement(user.data(), currentTime) };
      }
      const selectEntitlement = canSelectEntitlement(user.data(), tx, entitlement, currentTime);
      t.set(subRef, {
        user_id: uid, original_transaction_id: originalId,
        transaction_id: tx.transactionId, environment,
        product_id: tx.productId, signed_date: signedDate,
        transaction_signed_date: tx.signedDate, renewal_signed_date: renewal.signedDate || 0,
        expires_at: timestamp(entitlement.expiry), active: entitlement.active,
        auto_renew: entitlement.autoRenew,
      });
      if (selectEntitlement) t.set(userRef, {
        subscription_status: entitlement.active ? 'active' : 'expired',
        subscription_plan: PRODUCTS[tx.productId],
        subscription_expiry_date: timestamp(entitlement.expiry),
        payment_gateway: 'app_store', is_premium: entitlement.active,
        auto_renew: entitlement.autoRenew,
        app_store_original_transaction_id: originalId,
        app_store_environment: environment,
        app_store_purchase_date: timestamp(tx.purchaseDate),
      }, { merge: true });
      if (!payment.exists && !tx.revocationDate && tx.price != null) {
        t.set(paymentRef, {
          user_id: uid, amount: tx.price / 1000, currency: tx.currency,
          status: 'completed', payment_method: 'app_store', provider: 'app_store',
          product_id: PRODUCTS[tx.productId], created_at: timestamp(tx.purchaseDate),
          transaction_id: tx.transactionId, environment,
        });
      }
      return { success: true, active: selectEntitlement ? entitlement.active : hasActiveEntitlement(user.data(), currentTime) };
    });
  }

  async function verifyPurchase(uid, signedTransaction) {
    if (typeof signedTransaction !== 'string' || signedTransaction.length > 30000) {
      throw new AppStoreError('invalid-argument', 'Signed transaction is required.');
    }
    const tx = await verifyTransaction(signedTransaction);
    validateTransaction(tx, uid);
    return reconcile(uid, tx.originalTransactionId, tx.environment);
  }

  return { verifyPurchase, reconcile };
}

module.exports = { BUNDLE_ID, APPLE_APP_ID, PRODUCTS, AppStoreError,
  accountTokenFor, subscriptionState, createAppStoreService };
