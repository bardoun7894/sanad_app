#!/usr/bin/env node
// Backfill the `created_at` field on users/{uid} docs that are missing it.
//
// WHY: the admin dashboard lists users with
//   .collection('users').orderBy('created_at', descending: true)
// Firestore SILENTLY DROPS any doc that lacks the orderBy field, so every
// user doc without `created_at` is invisible in the dashboard. This is the
// root cause of "new subscribers registered but don't show up".
//
// The deployed `backfillOrphanUsers` callable fixes this too, but it iterates
// Firebase Auth (Identity Toolkit API), which is awkward to invoke from a
// local shell. This script does the equivalent repair using Firestore only:
// for each users/{uid} missing `created_at`, it backfills a best-effort
// timestamp derived from the doc's own existing fields, falling back to now.
//
// Idempotent — docs that already have `created_at` are skipped. Safe to re-run.
//
// Usage:
//   GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/backfill-users-created-at.js           # dry-run
//   GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/backfill-users-created-at.js --execute  # really write

const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const Timestamp = admin.firestore.Timestamp;
const FieldValue = admin.firestore.FieldValue;

const EXECUTE = process.argv.includes('--execute');

// Pick the most truthful creation time we can find in the doc itself.
// Order of preference: updated_at -> last_login -> serverTimestamp() (now).
function deriveCreatedAt(data) {
  const candidate = data.updated_at || data.last_login;
  if (candidate instanceof Timestamp) return candidate;
  return null; // signal: use serverTimestamp() at write time
}

(async () => {
  console.log(`Mode: ${EXECUTE ? 'EXECUTE (will write)' : 'DRY-RUN'}`);
  console.log('Project: sanad-app-beldify\n');

  const snap = await db.collection('users').get();
  const targets = [];
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.created_at == null) {
      targets.push({ id: doc.id, data });
    }
  }

  console.log(`Total users docs:                 ${snap.size}`);
  console.log(`Missing created_at (to repair):   ${targets.length}\n`);

  if (targets.length === 0) {
    console.log('Nothing to do — all user docs already have created_at.');
    process.exit(0);
  }

  for (const t of targets) {
    const name = t.data.name || t.data.email || t.data.phone || '(no name)';
    const role = t.data.role || '?';
    const src = deriveCreatedAt(t.data) ? 'from updated_at/last_login' : 'serverTimestamp (no fallback field)';
    console.log(`  - ${t.id.padEnd(30)} ${String(name).padEnd(28)} role=${role}  -> ${src}`);
  }

  if (!EXECUTE) {
    console.log('\nDry-run only. Re-run with --execute to apply.');
    process.exit(0);
  }

  let written = 0;
  for (let i = 0; i < targets.length; i += 400) {
    const batch = db.batch();
    for (const t of targets.slice(i, i + 400)) {
      const derived = deriveCreatedAt(t.data);
      batch.set(
        db.collection('users').doc(t.id),
        {
          created_at: derived || FieldValue.serverTimestamp(),
          updated_at: FieldValue.serverTimestamp(),
          repaired_by: 'backfill-users-created-at-script',
        },
        { merge: true }
      );
    }
    await batch.commit();
    written += Math.min(400, targets.length - i);
  }

  console.log(`\nRepaired ${written} user doc(s). They will now appear in the admin dashboard.`);
  process.exit(0);
})().catch(err => {
  console.error('ERROR:', err.message);
  process.exit(1);
});
