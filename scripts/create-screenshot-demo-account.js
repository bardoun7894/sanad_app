#!/usr/bin/env node
// Creates/updates the App Store screenshot demo patient (idempotent).
//   screenshots.demo@sanadtherapy.com: complete profile, premium via admin_grant, is_demo=true
// The password is random on first creation and written to ~/.config/sanad/screenshot-account.txt (0600).
// Pass --reset-password to rotate it. Never reuse the Apple App Review accounts for screenshots.
//
// Usage: NODE_PATH=functions/node_modules node scripts/create-screenshot-demo-account.js [--reset-password]

const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execSync } = require('child_process');
const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const FV = admin.firestore.FieldValue;
const TS = admin.firestore.Timestamp;

const EMAIL = 'screenshots.demo@sanadtherapy.com';
const NAME = 'ليلى أحمد';
const RESET = process.argv.includes('--reset-password');
const CRED_FILE = path.join(os.homedir(), '.config/sanad/screenshot-account.txt');
const randomPassword = () => crypto.randomBytes(12).toString('base64').replace(/[+/=]/g, 'x') + 'aA1!';

const BASE = 'https://identitytoolkit.googleapis.com/v1/projects/sanad-app-beldify';
async function itk(p, body) {
  const token = execSync('gcloud auth print-access-token').toString().trim();
  const res = await fetch(`${BASE}/${p}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'x-goog-user-project': 'sanad-app-beldify',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const j = await res.json();
  if (!res.ok) throw new Error(`ITK ${p} ${res.status}: ${JSON.stringify(j)}`);
  return j;
}

(async () => {
  let password = null;
  let rec;
  const found = await itk('accounts:lookup', { email: [EMAIL] });
  if (found.users && found.users.length) {
    rec = found.users[0];
    const upd = { localId: rec.localId, displayName: NAME, emailVerified: true, disableUser: false };
    if (RESET) { password = randomPassword(); upd.password = password; }
    await itk('accounts:update', upd);
  } else {
    password = randomPassword();
    const c = await itk('accounts', { email: EMAIL, password, displayName: NAME, emailVerified: true });
    rec = (await itk('accounts:lookup', { localId: [c.localId] })).users[0];
  }
  const uid = rec.localId;
  await new Promise(r => setTimeout(r, 4000)); // let ensureUserDocument settle

  await db.collection('users').doc(uid).set({
    email: EMAIL,
    name: NAME,
    display_name: NAME,
    first_name: 'ليلى',
    last_name: 'أحمد',
    phone: '+971500000003',
    whatsapp_number: '+971500000003',
    whatsapp_ads_consent: false,
    date_of_birth: TS.fromDate(new Date('1994-03-12T00:00:00Z')),
    gender: 'female',
    matching_preferences: { goals: ['anxiety', 'stress'], relationship_status: 'single', preferred_therapist_gender: 'any' },
    role: 'user',
    auth_provider: 'email',
    has_complete_profile: true,
    profile_completion_percentage: 1.0,
    is_demo: true,
    is_premium: true,
    subscription_status: 'active',
    subscription_plan: 'premium',
    subscription_product_title: 'Premium (screenshot demo)',
    subscription_start_date: FV.serverTimestamp(),
    subscription_expiry_date: TS.fromDate(new Date(Date.now() + 365 * 24 * 3600 * 1000)),
    payment_gateway: 'admin_grant',
    auto_renew: false,
    subscription_assigned_by: 'screenshot-demo-script',
    subscription_assigned_at: FV.serverTimestamp(),
    updated_at: FV.serverTimestamp(),
    created_at: TS.fromDate(new Date(Number(rec.createdAt))),
  }, { merge: true });

  if (password) {
    fs.mkdirSync(path.dirname(CRED_FILE), { recursive: true });
    fs.writeFileSync(CRED_FILE, `${EMAIL}\n${password}\n`, { mode: 0o600 });
  }
  const u = (await db.collection('users').doc(uid).get()).data();
  console.log(`uid=${uid} email=${EMAIL} premium=${u.is_premium} complete=${u.has_complete_profile} demo=${u.is_demo}`);
  console.log(password ? `password written to ${CRED_FILE}` : `password unchanged (see ${CRED_FILE})`);
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
