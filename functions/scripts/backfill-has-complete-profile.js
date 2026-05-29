#!/usr/bin/env node
// Backfill the `has_complete_profile` field on users/{uid} docs missing it.
//
// WHY: the admin "incomplete profiles" list queries
//   users.where('has_complete_profile', '==', false).orderBy('created_at','desc')
// Firestore does NOT match docs where the field is ABSENT — and signup never
// wrote it — so abandoned signups were invisible to admin. Going forward the
// field is written at every signup path; this repairs the historical docs.
//
// IMPORTANT (avoid mislabeling): the same field gates the app's own
// profile-completion screen. We do NOT blanket-set false — we DERIVE the real
// value from whether the user actually has a name + phone, and we ONLY touch
// docs where the field is absent and role == 'user' (therapist/admin docs are
// excluded; they don't belong in this list).
//
// Idempotent — docs that already have the field are skipped. Safe to re-run.
//
// Usage:
//   GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/backfill-has-complete-profile.js           # dry-run
//   GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/backfill-has-complete-profile.js --execute  # write

const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const EXECUTE = process.argv.includes('--execute');

function hasName(d) {
  return !!(
    (d.name && String(d.name).trim()) ||
    (d.display_name && String(d.display_name).trim()) ||
    (d.first_name && String(d.first_name).trim())
  );
}
function hasPhone(d) {
  return !!((d.phone && String(d.phone).trim()) || (d.whatsapp_number && String(d.whatsapp_number).trim()));
}

(async () => {
  console.log(`Mode: ${EXECUTE ? 'EXECUTE (will write)' : 'DRY-RUN'}`);
  console.log('Project: sanad-app-beldify\n');

  const snap = await db.collection('users').get();
  const targets = [];
  let skippedHasField = 0, skippedNonUser = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    if (d.has_complete_profile !== undefined && d.has_complete_profile !== null) { skippedHasField++; continue; }
    if ((d.role || 'user') !== 'user') { skippedNonUser++; continue; }
    const complete = hasName(d) && hasPhone(d);
    targets.push({ id: doc.id, name: d.name || d.display_name || d.first_name || '(no name)', complete });
  }

  console.log(`Total users docs:            ${snap.size}`);
  console.log(`Already has field (skip):    ${skippedHasField}`);
  console.log(`Non-user role (skip):        ${skippedNonUser}`);
  console.log(`To repair (role==user):      ${targets.length}\n`);

  for (const t of targets) {
    console.log(`  - ${t.id.padEnd(30)} ${String(t.name).padEnd(26)} -> has_complete_profile=${t.complete}`);
  }

  if (targets.length === 0) { console.log('\nNothing to repair.'); process.exit(0); }
  if (!EXECUTE) { console.log('\nDry-run only. Re-run with --execute to apply.'); process.exit(0); }

  let written = 0;
  for (let i = 0; i < targets.length; i += 400) {
    const batch = db.batch();
    for (const t of targets.slice(i, i + 400)) {
      batch.set(
        db.collection('users').doc(t.id),
        { has_complete_profile: t.complete, updated_at: FieldValue.serverTimestamp(), repaired_by: 'backfill-has-complete-profile-script' },
        { merge: true }
      );
    }
    await batch.commit();
    written += Math.min(400, targets.length - i);
  }
  console.log(`\nRepaired ${written} user doc(s). Incomplete ones now surface in the admin Signup Health screen.`);
  process.exit(0);
})().catch(err => { console.error('ERROR:', err.message); process.exit(1); });
