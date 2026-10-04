#!/usr/bin/env node
// Creates/updates the Apple App Review demo accounts (idempotent).
//  - patient:   appreview.patient@sanadtherapy.com  (complete profile, premium via admin_grant)
//  - therapist: appreview.therapist@sanadtherapy.com (approved, is_active=false => hidden
//               from the public list, which needs is_active==true AND approval_status=='approved')
// Passwords: random on first creation (printed once); existing accounts keep their
// password unless --reset-password is passed. Re-running never duplicates.
//
// Usage: GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/create-review-demo-accounts.js [--reset-password]

const crypto = require('crypto');
const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const FV = admin.firestore.FieldValue;
const TS = admin.firestore.Timestamp;

const RESET = process.argv.includes('--reset-password');
const randomPassword = () => crypto.randomBytes(12).toString('base64').replace(/[+/=]/g, 'x') + 'aA1!';

const { execSync } = require('child_process');
const BASE = 'https://identitytoolkit.googleapis.com/v1/projects/sanad-app-beldify';
async function itk(path, body) {
  const token = execSync('gcloud auth print-access-token').toString().trim();
  const res = await fetch(`${BASE}/${path}`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'x-goog-user-project': 'sanad-app-beldify',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const j = await res.json();
  if (!res.ok) throw new Error(`ITK ${path} ${res.status}: ${JSON.stringify(j)}`);
  return j;
}
const toUser = (r) => ({
  uid: r.localId,
  email: r.email,
  metadata: { creationTime: new Date(Number(r.createdAt)).toISOString() },
});

async function upsertAuth(email, displayName) {
  let password = null;
  const found = await itk('accounts:lookup', { email: [email] });
  let rec;
  if (found.users && found.users.length) {
    rec = found.users[0];
    const upd = { localId: rec.localId, displayName, emailVerified: true, disableUser: false };
    if (RESET) { password = randomPassword(); upd.password = password; }
    await itk('accounts:update', upd);
  } else {
    password = randomPassword();
    const c = await itk('accounts', { email, password, displayName, emailVerified: true });
    const again = await itk('accounts:lookup', { localId: [c.localId] });
    rec = again.users[0];
  }
  return { user: toUser(rec), password };
}

(async () => {
  const sleep = (ms) => new Promise(r => setTimeout(r, ms));
  const out = [];

  // ---------- Patient ----------
  const p = await upsertAuth('appreview.patient@sanadtherapy.com', 'Apple Reviewer');
  await sleep(4000); // let ensureUserDocument trigger settle
  const expiry = TS.fromDate(new Date(Date.now() + 365 * 24 * 3600 * 1000));
  await db.collection('users').doc(p.user.uid).set({
    email: p.user.email,
    name: 'Apple Reviewer',
    display_name: 'Apple Reviewer',
    first_name: 'Apple',
    last_name: 'Reviewer',
    phone: '+971500000001',
    whatsapp_number: '+971500000001',
    whatsapp_ads_consent: false,
    avatar_url: 'https://ui-avatars.com/api/?name=Apple+Reviewer&size=256',
    date_of_birth: TS.fromDate(new Date('1990-01-01T00:00:00Z')),
    gender: 'male',
    matching_preferences: {
      goals: ['anxiety'],
      relationship_status: 'single',
      preferred_therapist_gender: 'any',
    },
    role: 'user',
    auth_provider: 'email',
    has_complete_profile: true,
    profile_completion_percentage: 1.0,
    is_demo: true,
    // premium via the same fields as admin assignSubscription (admin_grant)
    is_premium: true,
    subscription_status: 'active',
    subscription_plan: 'premium',
    subscription_product_title: 'Premium (App Review demo)',
    subscription_start_date: FV.serverTimestamp(),
    subscription_expiry_date: expiry,
    payment_gateway: 'admin_grant',
    auto_renew: false,
    subscription_assigned_by: 'review-demo-script',
    subscription_assigned_at: FV.serverTimestamp(),
    updated_at: FV.serverTimestamp(),
    last_login: FV.serverTimestamp(),
    created_at: TS.fromDate(new Date(p.user.metadata.creationTime)),
  }, { merge: true });
  out.push({ role: 'patient', uid: p.user.uid, email: p.user.email, password: p.password });

  // ---------- Therapist (hidden from public list) ----------
  const t = await upsertAuth('appreview.therapist@sanadtherapy.com', 'Apple Review Therapist');
  await sleep(4000);
  await db.collection('users').doc(t.user.uid).set({
    email: t.user.email,
    name: 'Apple Review Therapist',
    display_name: 'Apple Review Therapist',
    first_name: 'Apple',
    last_name: 'Review Therapist',
    phone: '+971500000002',
    role: 'therapist',
    therapist_status: 'approved',
    auth_provider: 'email',
    has_complete_profile: true,
    is_demo: true,
    updated_at: FV.serverTimestamp(),
    last_login: FV.serverTimestamp(),
    created_at: TS.fromDate(new Date(t.user.metadata.creationTime)),
  }, { merge: true });
  await db.collection('therapists').doc(t.user.uid).set({
    email: t.user.email,
    name: 'Apple Review Therapist',
    name_ar: 'Apple Review Therapist',
    name_en: 'Apple Review Therapist',
    name_fr: 'Apple Review Therapist',
    title: 'Demo account', title_ar: 'Demo account', title_en: 'Demo account', title_fr: 'Demo account',
    bio: 'Demo account for Apple App Review.', bio_ar: 'Demo account for Apple App Review.',
    bio_en: 'Demo account for Apple App Review.', bio_fr: 'Demo account for Apple App Review.',
    specialties: [], session_types: [], therapy_types: [], languages: ['English'], qualifications: [],
    session_price: 0, currency: 'USD', years_experience: 0,
    approval_status: 'approved',
    is_active: false, // KEEP false: hides from public list/booking
    is_demo: true,
    rating: 0, review_count: 0,
    approved_at: FV.serverTimestamp(),
    approved_by: 'review-demo-script',
    updated_at: FV.serverTimestamp(),
    created_at: TS.fromDate(new Date(t.user.metadata.creationTime)),
  }, { merge: true });
  out.push({ role: 'therapist', uid: t.user.uid, email: t.user.email, password: t.password });

  // ---------- Verify ----------
  for (const o of out) {
    const u = (await db.collection('users').doc(o.uid).get()).data();
    console.log(`\n[${o.role}] ${o.email} uid=${o.uid} password=${o.password || '(unchanged, existing account)'}`);
    console.log({
      role: u.role, has_complete_profile: u.has_complete_profile, is_demo: u.is_demo,
      is_premium: u.is_premium, payment_gateway: u.payment_gateway, gender: u.gender,
      first_name: u.first_name, phone: u.phone, therapist_status: u.therapist_status,
    });
    if (o.role === 'therapist') {
      const td = (await db.collection('therapists').doc(o.uid).get()).data();
      console.log({ approval_status: td.approval_status, is_active: td.is_active, is_demo: td.is_demo });
    }
  }
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
