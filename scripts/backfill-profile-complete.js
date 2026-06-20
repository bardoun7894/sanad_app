// Rescue users stuck at has_complete_profile=false who ALREADY have their core
// data (name + phone + gender). They filled the form; autosave persisted the
// fields, but the completion flag never flipped, so the gate re-prompts them on
// every launch ("registration starts again every time").
//
// UPGRADE-ONLY + NON-DESTRUCTIVE: only ever sets has_complete_profile false→true.
// Never deletes a user, never downgrades, never touches users without the data.
//
//   node scripts/backfill-profile-complete.js            # dry run (no writes)
//   node scripts/backfill-profile-complete.js --apply    # apply the flips

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();

const APPLY = process.argv.includes('--apply');

const nonEmpty = (v) => typeof v === 'string' && v.trim().length > 0;

const hasName = (d) =>
  nonEmpty(d.first_name) ||
  nonEmpty(d.display_name) ||
  (nonEmpty(d.name) && d.name.trim().toLowerCase() !== 'user');

(async () => {
  const snap = await db.collection('users').get();
  const candidates = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    if (d.has_complete_profile === true) continue; // already complete
    const phoneOk = nonEmpty(d.phone) || nonEmpty(d.whatsapp_number);
    const ok = hasName(d) && phoneOk && nonEmpty(d.gender);
    if (ok) candidates.push({ id: doc.id, d });
  }

  console.log(`total users: ${snap.size}`);
  console.log(`stuck-but-have-core-data (would flip → complete): ${candidates.length}`);
  console.log(`mode: ${APPLY ? 'APPLY (writing)' : 'DRY RUN (no writes)'}\n`);

  candidates
    .sort((a, b) => (b.d.created_at?.toMillis?.() ?? 0) - (a.d.created_at?.toMillis?.() ?? 0))
    .slice(0, 15)
    .forEach(({ id, d }) =>
      console.log(
        `  ${id}  name=${JSON.stringify(d.first_name || d.name || d.display_name)} ` +
          `phone=${JSON.stringify(d.phone || d.whatsapp_number)} gender=${JSON.stringify(d.gender)}`
      )
    );
  if (candidates.length > 15) console.log(`  ... and ${candidates.length - 15} more`);

  if (!APPLY) {
    console.log('\nDry run only. Re-run with --apply to flip these to complete.');
    process.exit(0);
  }

  let done = 0;
  for (let i = 0; i < candidates.length; i += 400) {
    const batch = db.batch();
    for (const { id } of candidates.slice(i, i + 400)) {
      batch.update(db.collection('users').doc(id), {
        has_complete_profile: true,
        completed_via: 'backfill_2026_06_20',
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    done += candidates.slice(i, i + 400).length;
    console.log(`committed ${done}/${candidates.length}`);
  }
  console.log(`\n✓ Flipped ${done} users to has_complete_profile=true. None deleted, none downgraded.`);
  process.exit(0);
})().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
