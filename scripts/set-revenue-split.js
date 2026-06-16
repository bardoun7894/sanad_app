// set-revenue-split.js — set the 3-way revenue split in system_settings/config.
//
// The admin dashboard (admin_invoices_provider.dart) listens to this doc and
// recomputes every invoice's shares live — no rebuild/redeploy needed.
// RevenueSplit divides the EXACT booking amount, so the three percentages MUST
// total 100.
//
// Usage:
//   node set-revenue-split.js <therapist> <app> <maintenance>
//   node set-revenue-split.js 60 30 10
//   node set-revenue-split.js 60 30 10 --dry-run

const admin = require('firebase-admin');

const PROJECT_ID = 'sanad-app-beldify';
const nums = process.argv.slice(2).filter((a) => /^\d+(\.\d+)?$/.test(a)).map(Number);
const DRY = process.argv.includes('--dry-run');

if (nums.length !== 3) {
  console.error('Usage: node set-revenue-split.js <therapist> <app> <maintenance> [--dry-run]');
  process.exit(1);
}
const [therapist, app, maintenance] = nums;
const sum = therapist + app + maintenance;
if (Math.abs(sum - 100) > 0.01) {
  console.error(`✗ Percentages must total 100. Got ${therapist}+${app}+${maintenance} = ${sum}.`);
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: PROJECT_ID,
});
const db = admin.firestore();
const ref = db.collection('system_settings').doc('config');

async function main() {
  const before = (await ref.get()).data() || {};
  console.log('--- current ---');
  console.log(`  therapist=${before.revenue_therapist_pct ?? 70}  app=${before.revenue_app_pct ?? 20}  maintenance=${before.revenue_maintenance_pct ?? 10}`);
  console.log('--- new ---');
  console.log(`  therapist=${therapist}  app=${app}  maintenance=${maintenance}  (sum=${sum})`);

  if (DRY) { console.log('\nDry-run only. Drop --dry-run to write.'); return; }

  await ref.set({
    revenue_therapist_pct: therapist,
    revenue_app_pct: app,
    revenue_maintenance_pct: maintenance,
  }, { merge: true });

  const after = (await ref.get()).data();
  console.log('--- after (verified) ---');
  console.log(`  therapist=${after.revenue_therapist_pct}  app=${after.revenue_app_pct}  maintenance=${after.revenue_maintenance_pct}`);
  console.log('\n✓ Split updated. The dashboard recomputes invoice shares live (no redeploy).');
}

main().then(() => process.exit(0)).catch((e) => { console.error('✗', e.message); process.exit(1); });
