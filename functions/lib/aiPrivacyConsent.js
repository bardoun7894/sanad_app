'use strict';

const AI_PRIVACY_CONSENT_VERSION = '2026-10-01';

async function setAiPrivacyConsentRecord(db, data, context, HttpsError, serverTimestamp) {
  if (!context.auth?.uid || context.auth.token?.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('unauthenticated', 'Sign in to manage AI privacy consent');
  }
  if (!data || typeof data.accepted !== 'boolean' || data.version !== AI_PRIVACY_CONSENT_VERSION) {
    throw new HttpsError('invalid-argument', 'accepted must be a boolean and version must match the current AI disclosure');
  }

  if (Object.hasOwn(data, 'expectedUserId')) {
    if (typeof data.expectedUserId !== 'string' || data.expectedUserId.length === 0) {
      throw new HttpsError('invalid-argument', 'expectedUserId must be a nonempty string');
    }
    if (data.expectedUserId !== context.auth.uid) {
      throw new HttpsError('permission-denied', 'The signed-in account changed before consent could be saved');
    }
  }

  const consent = {
    accepted: data.accepted,
    version: AI_PRIVACY_CONSENT_VERSION,
    updated_at: serverTimestamp(),
  };
  await db.collection('users').doc(context.auth.uid).set({ ai_privacy_consent: consent }, { merge: true });
  return { accepted: consent.accepted, version: consent.version };
}

async function assertAiPrivacyConsent(db, userId, HttpsError) {
  const user = await db.collection('users').doc(userId).get();
  const consent = user.exists ? user.data()?.ai_privacy_consent : null;
  if (consent?.accepted !== true || consent.version !== AI_PRIVACY_CONSENT_VERSION) {
    throw new HttpsError('permission-denied', 'Current AI privacy consent is required', {
      reason: 'ai-consent-required',
      version: AI_PRIVACY_CONSENT_VERSION,
    });
  }
}

module.exports = { AI_PRIVACY_CONSENT_VERSION, setAiPrivacyConsentRecord, assertAiPrivacyConsent };
