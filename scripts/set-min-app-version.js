// set-min-app-version.js — set the forced-update floor in system_settings/config.
//
// app_version_gate.dart reads this doc; any client below min_app_version is
// redirected to the blocking force-update screen (app_router.dart). Admins
// bypass the gate. This is the same doc/pattern as set-revenue-split.js.
//
// Usage:
//   node set-min-app-version.js <version> [--dry-run]
//   node set-min-app-version.js 1.0.9
//   node set-min-app-version.js 1.0.9 --dry-run

const admin = require('firebase-admin');

const PROJECT_ID = 'sanad-app-beldify';
const DRY = process.argv.includes('--dry-run');
const version = process.argv.slice(2).find((a) => /^\d+\.\d+\.\d+$/.test(a));

if (!version) {
  console.error('Usage: node set-min-app-version.js <version e.g. 1.0.9> [--dry-run]');
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
  console.log(`  min_app_version=${before.min_app_version ?? '(unset, gate dormant)'}`);
  console.log('--- new ---');
  console.log(`  min_app_version=${version}`);

  if (DRY) { console.log('\nDry-run only. Drop --dry-run to write.'); return; }

  await ref.set({ min_app_version: version }, { merge: true });

  const after = (await ref.get()).data();
  console.log('--- after (verified) ---');
  console.log(`  min_app_version=${after.min_app_version}`);
  console.log('\n✓ Any client below this version-name will now hit the blocking force-update screen.');
}

main().then(() => process.exit(0)).catch((e) => { console.error('✗', e.message); process.exit(1); });
