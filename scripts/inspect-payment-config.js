// READ-ONLY: inspect the LIVE payment config that decides sandbox-vs-live and
// whether gateway keys are present. Masks secret values (shows only presence +
// length + last 4) so nothing sensitive is dumped.
//   node scripts/inspect-payment-config.js

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();

const mask = (v) => {
  if (v === undefined || v === null) return 'MISSING';
  const s = String(v);
  if (s.length <= 6) return `set(len=${s.length})`;
  return `set(len=${s.length}, …${s.slice(-4)})`;
};

(async () => {
  for (const docId of ['config', 'api_keys']) {
    const snap = await db.collection('system_settings').doc(docId).get();
    console.log(`\n=== system_settings/${docId} ${snap.exists ? '' : '(MISSING)'} ===`);
    if (!snap.exists) continue;
    const d = snap.data();
    for (const [k, v] of Object.entries(d)) {
      const isSecret = /key|secret|token|client_id|bearer/i.test(k);
      const isFlag = /sandbox|test|live|mode|enabled/i.test(k);
      if (isSecret) console.log(`  ${k}: ${mask(v)}`);
      else if (isFlag || typeof v !== 'object') console.log(`  ${k}: ${JSON.stringify(v)}`);
      else console.log(`  ${k}: {object}`);
    }
  }
  process.exit(0);
})().catch((e) => { console.error(e.message); process.exit(1); });
