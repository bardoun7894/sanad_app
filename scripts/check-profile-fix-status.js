// One-off READ-ONLY check after the 1.0.3+26 profile-persistence fix:
//   1. Find Sanad Namariq's users/{uid} doc and print its profile state.
//   2. List every user whose phone/whatsapp carries a doubled country code
//      ("+966+971...") — candidates for a later backfill repair.
//   3. Summarize has_complete_profile for users created since 2026-06-07.
//
// Run from repo root:  node scripts/check-profile-fix-status.js

const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();

const DOUBLE_CODE = /\+\d{1,4}\+/;

(async () => {
  const snap = await db.collection('users').get();
  console.log(`users docs: ${snap.size}\n`);

  const namariq = [];
  const doubled = [];
  let recentTotal = 0;
  let recentComplete = 0;
  const cutoff = new Date('2026-06-07T00:00:00Z');

  for (const doc of snap.docs) {
    const d = doc.data();
    const name = `${d.name || d.display_name || ''} ${d.first_name || ''} ${d.last_name || ''}`;
    if (/نمارق|namariq/i.test(name)) namariq.push([doc.id, d]);

    for (const f of ['phone', 'whatsapp_number']) {
      if (typeof d[f] === 'string' && DOUBLE_CODE.test(d[f])) {
        doubled.push(`${doc.id}  ${f}=${d[f]}  name=${(d.name || d.display_name || '?').slice(0, 30)}`);
        break;
      }
    }

    const created = d.created_at?.toDate?.();
    if (created && created >= cutoff) {
      recentTotal++;
      if (d.has_complete_profile === true) recentComplete++;
    }
  }

  console.log('=== Namariq doc(s) ===');
  for (const [id, d] of namariq) {
    console.log(`uid=${id}`);
    for (const k of ['name', 'first_name', 'last_name', 'email', 'phone',
                     'whatsapp_number', 'gender', 'has_complete_profile',
                     'profile_completion_percentage']) {
      console.log(`  ${k}: ${JSON.stringify(d[k])}`);
    }
    console.log(`  updated_at: ${d.updated_at?.toDate?.()?.toISOString?.() || d.updated_at}`);
  }
  if (!namariq.length) console.log('  (no doc matched نمارق/namariq)');

  console.log(`\n=== doubled country codes (${doubled.length}) ===`);
  doubled.forEach((l) => console.log('  ' + l));

  console.log(`\n=== users created since 2026-06-07: ${recentTotal}, has_complete_profile=true: ${recentComplete} ===`);
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
