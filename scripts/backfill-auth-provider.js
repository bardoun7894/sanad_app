// Backfill users/{uid}.auth_provider from the real Firebase Auth provider so
// the admin "Registered via" shows Google / Phone / Guest instead of "unknown".
// _fmtProvider already maps: google→Google, apple→Apple, phone→Phone,
// email→Email, anonymous→Guest. We just need the field populated.
//
//   node scripts/backfill-auth-provider.js            # dry-run
//   node scripts/backfill-auth-provider.js --apply    # write

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const auth = admin.auth();
const APPLY = process.argv.includes('--apply');

function derive(u) {
  const ids = (u.providerData || []).map((p) => p.providerId);
  if (ids.includes('google.com')) return 'google';
  if (ids.includes('apple.com')) return 'apple';
  if (ids.includes('phone')) return 'phone';
  if (ids.includes('password')) return 'email';
  if (ids.length === 0) return 'anonymous'; // no providers → guest
  return ids[0];
}

(async () => {
  const snap = await db.collection('users').get();
  let changed = 0, same = 0, noauth = 0;
  const updates = [];

  for (const doc of snap.docs) {
    const cur = doc.data().auth_provider || null;
    let derived;
    try {
      derived = derive(await auth.getUser(doc.id));
    } catch {
      noauth++;
      continue; // no auth user — skip
    }
    if (cur === derived) { same++; continue; }
    changed++;
    console.log(`${doc.id}  ${cur ?? '∅'} -> ${derived}`);
    updates.push([doc.ref, derived]);
  }

  console.log(`\nsummary: ${changed} to change, ${same} already correct, ${noauth} no-auth-user`);
  if (!APPLY) { console.log('Dry-run. Re-run with --apply to write.'); return; }

  for (let i = 0; i < updates.length; i += 400) {
    const batch = db.batch();
    for (const [ref, val] of updates.slice(i, i + 400)) {
      batch.set(ref, { auth_provider: val }, { merge: true });
    }
    await batch.commit();
  }
  console.log(`✓ wrote auth_provider on ${updates.length} docs. Admin "Registered via" will now show Google/Phone/Guest.`);
})().then(() => process.exit(0)).catch((e) => { console.error(e.message); process.exit(1); });
