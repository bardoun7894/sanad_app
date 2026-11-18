// Apple-only wording for static_pages (owner decision 2026-11-16).
// The Apple build (>= 1.0.31+59) reads content_<lang>_ios first; Android reads content_<lang>.
//
//   node scripts/static_pages_apple_split.js --set-ios
//       Copies the current coach / counselor wording (content_ar/content_en) into the _ios fields.
//   node scripts/static_pages_apple_split.js --restore-shared <backup dir>
//       Puts the original wording back in content_ar/content_en for Android, from the JSON
//       backups (functions/scripts/backups/static_pages-2026-11-16). Run only after build 59
//       is the live / in-review iOS build, or older iOS builds show the original wording.
const path = require('path');
const fs = require('fs');
const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));

const IDS = ['about_us', 'know_your_rights', 'privacy_policy', 'terms_of_service'];
const [mode, backupDir] = process.argv.slice(2);

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();

async function main() {
  const batch = db.batch();
  for (const id of IDS) {
    const ref = db.collection('static_pages').doc(id);
    if (mode === '--set-ios') {
      const d = (await ref.get()).data() || {};
      batch.set(ref, { content_ar_ios: d.content_ar || '', content_en_ios: d.content_en || '' }, { merge: true });
    } else if (mode === '--restore-shared') {
      const orig = JSON.parse(fs.readFileSync(path.join(backupDir, `${id}.json`), 'utf8'));
      batch.set(ref, {
        content_ar: orig.content_ar,
        content_en: orig.content_en,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    } else {
      throw new Error('usage: --set-ios | --restore-shared <backup dir>');
    }
  }
  await batch.commit();
  console.log(`${mode} done for ${IDS.join(', ')}`);
}

main().then(() => process.exit(0)).catch((e) => { console.error(e.message); process.exit(1); });
