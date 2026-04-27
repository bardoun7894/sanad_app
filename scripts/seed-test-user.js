#!/usr/bin/env node
// Seed a test user with Premium VIP subscription for Google Play review.
//
// Usage:
//   node scripts/seed-test-user.js
//
// Output: creates (or updates) the user and prints credentials for Play Console.

const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');

const PROJECT_ID = 'sanad-app-beldify';
// Android API key from lib/firebase_options.dart — used for Identity Toolkit REST.
const FIREBASE_API_KEY = 'AIzaSyCk1lzla88iqSM2ab_vqlXhbklHByFBUks';

const TEST_EMAIL = 'play-review@sanadtherapy.app';
const TEST_PASSWORD = 'SanadReview2026!';
const TEST_DISPLAY_NAME = 'Play Store Reviewer';

const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function httpsRequest(url, options, body = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const req = https.request(
      {
        hostname: urlObj.hostname,
        path: urlObj.pathname + urlObj.search,
        method: options.method || 'GET',
        headers: options.headers || {},
      },
      (res) => {
        let data = '';
        res.on('data', (d) => (data += d));
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, body: JSON.parse(data) });
          } catch {
            resolve({ status: res.statusCode, body: data });
          }
        });
      }
    );
    req.on('error', reject);
    if (body) req.write(typeof body === 'string' ? body : JSON.stringify(body));
    req.end();
  });
}

async function getFirestoreToken() {
  const configPath = path.join(
    os.homedir(),
    '.config/configstore/firebase-tools.json'
  );
  if (!fs.existsSync(configPath)) {
    throw new Error(
      `firebase-tools token not found at ${configPath}. Run \`firebase login\` first.`
    );
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const refreshToken = config.tokens?.refresh_token;
  if (!refreshToken) throw new Error('No refresh_token in firebase-tools config.');

  const body = new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id:
      '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
  }).toString();

  const res = await httpsRequest(
    'https://oauth2.googleapis.com/token',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    },
    body
  );
  if (res.status !== 200 || !res.body.access_token) {
    throw new Error(`Token exchange failed: ${JSON.stringify(res.body)}`);
  }
  return res.body.access_token;
}

async function createOrGetAuthUser(adminToken) {
  // Use Admin REST API — bypasses email/password sign-up being disabled for clients.
  // https://cloud.google.com/identity-platform/docs/reference/rest/v1/projects.accounts/create
  const createUrl = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts`;
  const createRes = await httpsRequest(
    createUrl,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${adminToken}`,
        'Content-Type': 'application/json',
      },
    },
    {
      email: TEST_EMAIL,
      password: TEST_PASSWORD,
      emailVerified: true,
      displayName: TEST_DISPLAY_NAME,
    }
  );

  if (createRes.status === 200 && createRes.body.localId) {
    console.log(`✅ Auth user created: uid=${createRes.body.localId}`);
    return createRes.body.localId;
  }

  const err = createRes.body?.error?.message;
  if (err === 'EMAIL_EXISTS') {
    // Look up existing user by email
    const lookupUrl = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:lookup`;
    const lookupRes = await httpsRequest(
      lookupUrl,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${adminToken}`,
          'Content-Type': 'application/json',
        },
      },
      { email: [TEST_EMAIL] }
    );
    if (lookupRes.status === 200 && lookupRes.body.users?.[0]?.localId) {
      const uid = lookupRes.body.users[0].localId;
      console.log(`ℹ️  Auth user already exists: uid=${uid}`);
      // Reset the password so we're sure of it
      const resetUrl = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}/accounts:update`;
      await httpsRequest(
        resetUrl,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${adminToken}`,
            'Content-Type': 'application/json',
          },
        },
        {
          localId: uid,
          password: TEST_PASSWORD,
          emailVerified: true,
          displayName: TEST_DISPLAY_NAME,
        }
      );
      console.log(`✅ Password reset to known value.`);
      return uid;
    }
    throw new Error(`Lookup failed: ${JSON.stringify(lookupRes.body)}`);
  }

  throw new Error(`Admin user creation failed: ${JSON.stringify(createRes.body)}`);
}

async function upsertFirestoreUserDoc(token, uid) {
  const url = `${FIRESTORE_BASE}/users/${uid}?updateMask.fieldPaths=email&updateMask.fieldPaths=display_name&updateMask.fieldPaths=role&updateMask.fieldPaths=is_premium&updateMask.fieldPaths=subscription_status&updateMask.fieldPaths=subscription_plan&updateMask.fieldPaths=subscription_expiry&updateMask.fieldPaths=has_complete_profile&updateMask.fieldPaths=phone&updateMask.fieldPaths=whatsapp_number&updateMask.fieldPaths=created_at&updateMask.fieldPaths=settings&updateMask.fieldPaths=notes`;

  const now = new Date();
  const oneYearLater = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);

  const userDoc = {
    fields: {
      email: { stringValue: TEST_EMAIL },
      display_name: { stringValue: TEST_DISPLAY_NAME },
      role: { stringValue: 'user' },
      is_premium: { booleanValue: true },
      subscription_status: { stringValue: 'active' },
      subscription_plan: { stringValue: 'premium_vip' },
      subscription_expiry: { timestampValue: oneYearLater.toISOString() },
      has_complete_profile: { booleanValue: true },
      phone: { stringValue: '+966500000000' },
      whatsapp_number: { stringValue: '+966500000000' },
      created_at: { timestampValue: now.toISOString() },
      notes: {
        stringValue:
          'Google Play Store review test account — Premium VIP granted for full-feature review.',
      },
      settings: {
        mapValue: {
          fields: {
            notifications_enabled: { booleanValue: true },
            daily_reminders: { booleanValue: true },
            mood_tracking_reminders: { booleanValue: true },
            reminder_time: { stringValue: '09:00' },
            dark_mode: { booleanValue: false },
            language: { stringValue: 'English' },
            anonymous_in_community: { booleanValue: false },
            share_progress: { booleanValue: false },
          },
        },
      },
    },
  };

  const res = await httpsRequest(
    url,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    },
    userDoc
  );

  if (res.status !== 200) {
    throw new Error(`Firestore upsert failed: ${JSON.stringify(res.body)}`);
  }
  console.log(`✅ Firestore /users/${uid} upserted with Premium VIP.`);
}

async function main() {
  console.log('Seeding Play Store review test user...\n');
  const token = await getFirestoreToken();
  const uid = await createOrGetAuthUser(token);
  await upsertFirestoreUserDoc(token, uid);

  console.log('\n────────────────────────────────────────');
  console.log('Test account ready for Play Console:');
  console.log(`  Email:    ${TEST_EMAIL}`);
  console.log(`  Password: ${TEST_PASSWORD}`);
  console.log(`  UID:      ${uid}`);
  console.log(`  Tier:     Premium VIP (active for 1 year)`);
  console.log('────────────────────────────────────────');
}

main().catch((e) => {
  console.error('ERROR:', e.message);
  process.exit(1);
});
