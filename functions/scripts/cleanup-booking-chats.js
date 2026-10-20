#!/usr/bin/env node
// Finds booking-created therapist_chats with no messages whose patient is not
// assigned to that therapist. Dry run by default; deletes only with --apply.
// Usage: GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/cleanup-booking-chats.js [--apply]

const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const apply = process.argv.includes('--apply');

(async () => {
  const snap = await db.collection('therapist_chats').where('source', '==', 'booking').get();
  const stale = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    const msg = await doc.ref.collection('messages').limit(1).get();
    if (!msg.empty) continue;
    const user = d.user_id ? await db.collection('users').doc(d.user_id).get() : null;
    const assigned = user && user.exists ? user.data().assigned_therapist_id : null;
    if (assigned === d.therapist_id) continue;
    stale.push(doc);
  }
  console.log(`${snap.size} booking chats scanned, ${stale.length} stale (no messages, not assigned)`);
  for (const doc of stale) {
    const d = doc.data();
    console.log(doc.id.padEnd(50), d.therapist_name || '', '/', d.user_name || '');
  }
  if (!apply) {
    console.log('\nDry run. Re-run with --apply to delete.');
    return;
  }
  for (const doc of stale) await doc.ref.delete();
  console.log(`Deleted ${stale.length} chats.`);
})().catch(e => { console.error(e); process.exit(1); });
