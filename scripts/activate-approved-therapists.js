// Fix therapists that are approval_status=='approved' but is_active!=true — they
// are approved yet hidden from the app list (which needs BOTH is_active==true
// AND approval_status=='approved'). Does NOT touch suspended/rejected docs.
//   node scripts/activate-approved-therapists.js            # dry-run
//   node scripts/activate-approved-therapists.js --apply

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const APPLY = process.argv.includes('--apply');

(async () => {
  const snap = await db.collection('therapists').get();
  const fix = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    if (d.approval_status === 'approved' && d.is_active !== true) {
      fix.push(doc);
      console.log(`${doc.id}  ${d.name}  is_active=${JSON.stringify(d.is_active)} -> true`);
    }
  }
  console.log(`\n${fix.length} approved-but-inactive therapist(s) to activate.`);
  if (!APPLY) { console.log('Dry-run. Re-run with --apply to write.'); return; }
  const batch = db.batch();
  for (const doc of fix) {
    batch.set(doc.ref, {
      is_active: true,
      status: 'active',
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  if (fix.length) await batch.commit();
  console.log(`✓ activated ${fix.length} therapist(s) — they now match the app list query.`);
})().then(() => process.exit(0)).catch((e) => { console.error(e.message); process.exit(1); });
