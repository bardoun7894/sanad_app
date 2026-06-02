#!/usr/bin/env node
// Read-only inventory of the therapists collection in prod.
// Usage: GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/list-therapists.js

const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();

(async () => {
  const snap = await db.collection('therapists').get();
  const rows = snap.docs.map(d => {
    const x = d.data();
    return {
      id: d.id,
      name: x.full_name || x.name || x.name_ar || x.name_en || '(no name)',
      approval_status: x.approval_status || '(unset)',
      is_active: x.is_active === undefined ? '(unset)' : x.is_active,
      email: x.email || '(no email)',
    };
  });
  rows.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
  console.log(`Total: ${rows.length} therapist documents in sanad-app-beldify\n`);
  console.log('id'.padEnd(24), 'name'.padEnd(30), 'status'.padEnd(12), 'active', 'email');
  console.log('-'.repeat(110));
  for (const r of rows) {
    console.log(
      String(r.id).padEnd(24),
      String(r.name).padEnd(30),
      String(r.approval_status).padEnd(12),
      String(r.is_active).padEnd(7),
      r.email,
    );
  }
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
