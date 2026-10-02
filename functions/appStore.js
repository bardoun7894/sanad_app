const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fs = require('node:fs');
const path = require('node:path');
const { SignedDataVerifier, AppStoreServerAPIClient, Environment } = require('@apple/app-store-server-library');
const { BUNDLE_ID, APPLE_APP_ID, AppStoreError, accountTokenFor, createAppStoreService } = require('./lib/appStoreSubscriptions');

const rootCertificates = ['AppleRootCA-G2.cer', 'AppleRootCA-G3.cer']
  .map((file) => fs.readFileSync(path.join(__dirname, 'certificates', file)));
const verifiers = new Map();

function environmentFromJws(jws, notification = false) {
  if (typeof jws !== 'string' || jws.length > 60000 || jws.split('.').length !== 3) {
    throw new AppStoreError('invalid-argument', 'Invalid signed App Store data.');
  }
  let payload;
  try { payload = JSON.parse(Buffer.from(jws.split('.')[1], 'base64url').toString()); }
  catch { throw new AppStoreError('invalid-argument', 'Invalid signed App Store data.'); }
  // This value only selects a verifier. No field is trusted before signature verification.
  const environment = notification ? payload.data?.environment : payload.environment;
  if (![Environment.PRODUCTION, Environment.SANDBOX].includes(environment)) {
    throw new AppStoreError('invalid-argument', 'Unsupported App Store environment.');
  }
  if (environment === Environment.SANDBOX && process.env.APP_STORE_ALLOW_SANDBOX !== 'true') {
    throw new AppStoreError('failed-precondition', 'Sandbox purchases are disabled.');
  }
  return environment;
}

function verifierFor(environment) {
  if (!verifiers.has(environment)) {
    verifiers.set(environment, new SignedDataVerifier(rootCertificates, true, environment, BUNDLE_ID, APPLE_APP_ID));
  }
  return verifiers.get(environment);
}

function clientFor(environment) {
  const { APP_STORE_PRIVATE_KEY, APP_STORE_KEY_ID, APP_STORE_ISSUER_ID } = process.env;
  if (!APP_STORE_PRIVATE_KEY || !APP_STORE_KEY_ID || !APP_STORE_ISSUER_ID) {
    throw new AppStoreError('failed-precondition', 'App Store purchases are not configured yet.');
  }
  return new AppStoreServerAPIClient(APP_STORE_PRIVATE_KEY, APP_STORE_KEY_ID, APP_STORE_ISSUER_ID, BUNDLE_ID, environment);
}

async function fetchStatus(originalId, environment) {
  const response = await clientFor(environment).getAllSubscriptionStatuses(originalId);
  const entries = (response.data || []).flatMap((group) => group.lastTransactions || []);
  const entry = entries.find((item) => item.originalTransactionId === originalId);
  if (!entry?.signedTransactionInfo || !entry.signedRenewalInfo) {
    throw new AppStoreError('failed-precondition', 'Subscription not found in the App Store.');
  }
  const verifier = verifierFor(environment);
  const [transaction, renewal] = await Promise.all([
    verifier.verifyAndDecodeTransaction(entry.signedTransactionInfo),
    verifier.verifyAndDecodeRenewalInfo(entry.signedRenewalInfo),
  ]);
  return { transaction, renewal, status: entry.status };
}

function service() {
  return createAppStoreService({
    db: admin.firestore(), timestamp: (ms) => admin.firestore.Timestamp.fromMillis(ms),
    verifyTransaction: (jws) => verifierFor(environmentFromJws(jws)).verifyAndDecodeTransaction(jws),
    fetchStatus,
  });
}

function requireUser(context) {
  if (!context.auth || context.auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new functions.https.HttpsError('unauthenticated', 'Sign in before purchasing or restoring.');
  }
  return context.auth.uid;
}

exports.prepareAppStorePurchase = functions.https.onCall(async (_data, context) => {
  const uid = requireUser(context);
  const accountToken = accountTokenFor(uid);
  await admin.firestore().collection('app_store_accounts').doc(accountToken).set({ user_id: uid });
  return { accountToken };
});

const runtime = functions.runWith({ secrets: ['APP_STORE_PRIVATE_KEY'] });
exports.verifyAppStorePurchase = runtime.https.onCall(async (data, context) => {
  const uid = requireUser(context);
  try { return await service().verifyPurchase(uid, data?.signedTransaction); }
  catch (error) {
    // Never log receipts, tokens, signing keys, or Apple's full API response.
    console.error('App Store verification failed', error.code || error.name);
    if (error instanceof AppStoreError) throw new functions.https.HttpsError(error.code, error.message);
    throw new functions.https.HttpsError('unavailable', 'Could not verify with the App Store. Try Restore Purchases again.');
  }
});

exports.appStoreNotifications = runtime.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('Method not allowed');
  try {
    const jws = req.body?.signedPayload;
    const environment = environmentFromJws(jws, true);
    const verifier = verifierFor(environment);
    const notification = await verifier.verifyAndDecodeNotification(jws);
    if (notification.notificationType === 'TEST') return res.sendStatus(200);
    if (!notification.data?.signedTransactionInfo) return res.sendStatus(200);
    const tx = await verifier.verifyAndDecodeTransaction(notification.data.signedTransactionInfo);
    if (!tx.appAccountToken) return res.status(400).send('Missing account token');
    const account = await admin.firestore().collection('app_store_accounts').doc(tx.appAccountToken.toLowerCase()).get();
    if (!account.exists) return res.status(503).send('Account mapping not ready');
    // Re-read Apple's current state so delayed notifications cannot undo newer changes.
    await service().reconcile(account.data().user_id, tx.originalTransactionId, environment);
    return res.sendStatus(200);
  } catch (error) {
    console.error('App Store notification failed', error.code || error.name);
    return res.status(error instanceof AppStoreError && error.code === 'invalid-argument' ? 400 : 503).send('Notification not processed');
  }
});
