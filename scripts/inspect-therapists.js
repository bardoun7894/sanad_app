// READ-ONLY: dump therapists docs to see why a promoted user doesn't show in
// the app list. App query = where is_active==true AND approval_status=='approved'.
//   node scripts/inspect-therapists.js

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();

const F = (v) => (v === undefined ? '∅' : JSON.stringify(v));

(async () => {
  const snap = await db.collection('therapists').get();
  console.log(`therapists docs: ${snap.size}\n`);
  let wouldShow = 0;
  for (const doc of snap.docs) {
    const d = doc.data();
    const active = d.is_active === true;
    const approved = d.approval_status === 'approved';
    const match = active && approved;
    if (match) wouldShow++;
    console.log(`${doc.id}`);
    console.log(`  name=${F(d.name)}  is_active=${F(d.is_active)}  approval_status=${F(d.approval_status)}  status=${F(d.status)}  → ${match ? 'SHOWS ✓' : 'HIDDEN ✗'}`);
    // fields the UI model commonly needs
    console.log(`  specialties=${F(d.specialties)}  session_types=${F(d.session_types)}  rating=${F(d.rating)}  session_price=${F(d.session_price)}  created_at=${d.created_at ? 'set' : '∅'}`);
  }
  console.log(`\n=> ${wouldShow}/${snap.size} match the app query (is_active==true AND approval_status=='approved')`);
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
