// READ-ONLY: inspect the most recently-created users to diagnose
// "registered but data not saved". Shows the key profile fields + the
// Firebase Auth provider/emailVerified, newest first.
//   node scripts/inspect-recent-users.js [limit]

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const auth = admin.auth();

const LIMIT = parseInt(process.argv[2] || '20', 10);

const F = (v) => (v === undefined ? '∅' : JSON.stringify(v));

(async () => {
  const snap = await db.collection('users').get();
  const rows = snap.docs.map((d) => ({ id: d.id, d: d.data() }));
  rows.sort((a, b) => {
    const ca = a.d.created_at?.toMillis?.() ?? 0;
    const cb = b.d.created_at?.toMillis?.() ?? 0;
    return cb - ca;
  });

  console.log(`total users: ${rows.length}\n`);

  // Aggregate: how many recent docs are "empty/incomplete"
  let emptyName = 0, noRegVia = 0, incomplete = 0;
  for (const { d } of rows) {
    const nm = (d.name || d.display_name || d.full_name || '').trim();
    if (!nm || nm.toLowerCase() === 'user') emptyName++;
    if (!d.registered_via && !d.provider && !d.signup_method) noRegVia++;
    if (d.has_complete_profile !== true) incomplete++;
  }
  console.log(`empty/'User' name: ${emptyName}/${rows.length}   no registered_via: ${noRegVia}/${rows.length}   profile incomplete: ${incomplete}/${rows.length}\n`);

  for (const { id, d } of rows.slice(0, LIMIT)) {
    let prov = '?', verified = '?';
    try {
      const u = await auth.getUser(id);
      prov = (u.providerData || []).map((p) => p.providerId).join(',') || 'none';
      verified = u.emailVerified;
    } catch (_) { prov = 'NO-AUTH-USER'; }
    const created = d.created_at?.toDate?.()?.toISOString?.() || F(d.created_at);
    console.log(`uid=${id}  created=${created}`);
    console.log(`  name=${F(d.name)} display=${F(d.display_name)} first=${F(d.first_name)} last=${F(d.last_name)}`);
    console.log(`  email=${F(d.email)} gender=${F(d.gender)} phone=${F(d.phone)} whatsapp=${F(d.whatsapp_number)}`);
    console.log(`  registered_via=${F(d.registered_via)} provider=${F(d.provider)} signup_method=${F(d.signup_method)}`);
    console.log(`  has_complete_profile=${F(d.has_complete_profile)}  AUTH provider=[${prov}] emailVerified=${verified}`);
    console.log('');
  }
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
