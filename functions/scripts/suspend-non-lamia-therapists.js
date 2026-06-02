#!/usr/bin/env node
// Soft-delete (suspend) all visible therapists except Lamia and the two
// real human test accounts (owner + Mohamed). Mirrors the semantics of
// AdminTherapistNotifier.suspendTherapist() so the result is identical
// to clicking "Suspend" in the admin UI — fully reversible via reactivate.
//
// Usage:
//   GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/suspend-non-lamia-therapists.js          # dry-run
//   GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/suspend-non-lamia-therapists.js --execute # really write

const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const EXECUTE = process.argv.includes('--execute');
const ACTOR = 'cleanup-script-2026-05-24';

// Doc IDs to KEEP (do not touch).
const KEEP = new Set([
  'F4YMYOxF2zPcH5fXXtGEbIQvJRi1',         // Lamia Salah (owner's pick)
  'L1KJ9ql9HnP0mGw1kQsdfuSnoTW2',         // مهند معالج (owner test account)
  'Dioajt0tqGgpBc0c2e3QdfI5Paj2',         // mohamed bardouni (dev test account)
]);

(async () => {
  const snap = await db.collection('therapists').get();
  const targets = [];
  const skipped = [];

  for (const doc of snap.docs) {
    const x = doc.data();
    const visible = x.is_active === true && x.approval_status === 'approved';
    const name = x.full_name || x.name || x.name_ar || x.name_en || '(no name)';
    if (KEEP.has(doc.id)) {
      skipped.push({ id: doc.id, name, reason: 'KEEP list' });
      continue;
    }
    if (!visible) {
      skipped.push({ id: doc.id, name, reason: `already hidden (active=${x.is_active}, status=${x.approval_status})` });
      continue;
    }
    targets.push({ id: doc.id, name, email: x.email });
  }

  console.log(`Mode: ${EXECUTE ? 'EXECUTE' : 'DRY-RUN'}`);
  console.log(`Project: sanad-app-beldify\n`);

  console.log(`Will SUSPEND ${targets.length} therapist(s):`);
  for (const t of targets) {
    console.log(`  - ${t.id.padEnd(30)} ${String(t.name).padEnd(30)} ${t.email || ''}`);
  }
  console.log();
  console.log(`Will SKIP ${skipped.length} document(s):`);
  for (const s of skipped) {
    console.log(`  - ${s.id.padEnd(30)} ${String(s.name).padEnd(30)} (${s.reason})`);
  }
  console.log();

  if (!EXECUTE) {
    console.log('Dry-run only. Re-run with --execute to apply.');
    process.exit(0);
  }

  // Apply: mirror AdminTherapistNotifier.suspendTherapist() exactly.
  const batch = db.batch();
  for (const t of targets) {
    const tRef = db.collection('therapists').doc(t.id);
    batch.update(tRef, {
      approval_status: 'suspended',
      is_active: false,
      suspended_by: ACTOR,
      suspended_at: FieldValue.serverTimestamp(),
    });
    const uRef = db.collection('users').doc(t.id);
    batch.set(uRef, {
      therapist_status: 'suspended',
      is_active: false,
      updated_at: FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  // Activity log entry so the admin dashboard shows the cleanup.
  const logRef = db.collection('activity_logs').doc();
  batch.set(logRef, {
    type: 'userSuspended',
    user_id: ACTOR,
    user_name: 'Cleanup script',
    description: `Bulk suspended ${targets.length} demo/seed therapists (kept Lamia + Mohanned + Mohamed)`,
    metadata: {
      actor_uid: ACTOR,
      action: 'bulk_suspend',
      therapist_ids: targets.map(t => t.id),
      therapist_names: targets.map(t => t.name),
      reason: 'owner request 2026-05-23 — only Lamia visible to end users',
    },
    timestamp: FieldValue.serverTimestamp(),
  });

  await batch.commit();
  console.log(`\nCommitted: suspended ${targets.length} therapist(s). One activity_logs entry written.`);
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
