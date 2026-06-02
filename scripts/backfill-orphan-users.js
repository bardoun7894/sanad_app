// One-off backfill: ensure every Firebase Auth user has a Firestore users/{uid}
// document with the fields the admin dashboard (orderBy created_at) requires.
//
// Run from repo root:
//   node scripts/backfill-orphan-users.js --dry-run   # show what would change
//   node scripts/backfill-orphan-users.js             # actually write
//
// Auth options (in priority order):
//   1. Service account JSON: GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
//   2. Application Default Credentials with quota project set:
//        gcloud auth application-default login
//        gcloud auth application-default set-quota-project sanad-app-beldify
//
// Idempotent: only creates/repairs docs that are missing or lack created_at.
// Never overwrites existing fields except by merging missing-only data.
//
// Why this exists: the Flutter client _syncUserData() silently swallowed write
// exceptions, so Auth users could exist without a Firestore doc — invisible to
// the admin user list. The client now retries + logs to signup_failures and
// the ensureUserDocument Cloud Function trigger seeds missing docs going
// forward. This script reconciles the historical gap.

const path = require('path');

const PROJECT_ID = 'sanad-app-beldify';
process.env.GOOGLE_CLOUD_PROJECT = process.env.GOOGLE_CLOUD_PROJECT || PROJECT_ID;
process.env.GOOGLE_CLOUD_QUOTA_PROJECT =
  process.env.GOOGLE_CLOUD_QUOTA_PROJECT || PROJECT_ID;

const adminPath = path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin');
const admin = require(adminPath);

const initOpts = { projectId: PROJECT_ID };
if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  // firebase-admin auto-picks up the env var; nothing to do here.
  console.log(`Using service account: ${process.env.GOOGLE_APPLICATION_CREDENTIALS}`);
} else {
  console.log('Using Application Default Credentials.');
  console.log('If you hit a quota-project error, run once:');
  console.log(`  gcloud auth application-default set-quota-project ${PROJECT_ID}`);
}
admin.initializeApp(initOpts);

const auth = admin.auth();
const db = admin.firestore();

const DRY_RUN = process.argv.includes('--dry-run');

function deriveProvider(user) {
  const p = user.providerData?.[0]?.providerId || 'unknown';
  if (p.includes('phone')) return 'phone';
  if (p.includes('google')) return 'google';
  if (p.includes('apple')) return 'apple';
  if (p.includes('password')) return 'email';
  if (user.providerData?.length === 0) return 'anonymous';
  return p;
}

function buildSeed(user) {
  return {
    email: user.email || null,
    name: user.displayName || 'User',
    avatar_url: user.photoURL || null,
    phone: user.phoneNumber || null,
    role: 'user',
    auth_provider: deriveProvider(user),
    created_at: user.metadata?.creationTime
      ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.creationTime))
      : admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    last_login: user.metadata?.lastSignInTime
      ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.lastSignInTime))
      : admin.firestore.FieldValue.serverTimestamp(),
    created_by: 'backfill_script',
    settings: {
      notifications_enabled: true,
      daily_reminders: true,
      mood_tracking_reminders: true,
      reminder_time: '09:00',
      dark_mode: false,
      language: 'English',
    },
  };
}

async function main() {
  console.log(`Mode: ${DRY_RUN ? 'DRY RUN (no writes)' : 'LIVE (will write)'}`);
  console.log('Listing Firebase Auth users...');

  let pageToken;
  let totalAuth = 0;
  const orphans = [];
  const missingCreatedAt = [];

  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const user of page.users) {
      totalAuth++;
      const doc = await db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        orphans.push(user);
      } else if (!doc.data().created_at) {
        missingCreatedAt.push(user);
      }
    }
    pageToken = page.pageToken;
  } while (pageToken);

  console.log('');
  console.log(`Total Auth users: ${totalAuth}`);
  console.log(`Orphans (no Firestore doc):       ${orphans.length}`);
  console.log(`Has doc but missing created_at:   ${missingCreatedAt.length}`);
  console.log('');

  if (orphans.length === 0 && missingCreatedAt.length === 0) {
    console.log('Nothing to repair. All Auth users already have a doc with created_at.');
    return;
  }

  console.log('Orphan sample (up to 20):');
  for (const u of orphans.slice(0, 20)) {
    console.log(`  ${u.uid}  ${u.email || u.phoneNumber || '(no contact)'}  created=${u.metadata?.creationTime || '?'}`);
  }
  console.log('');

  if (DRY_RUN) {
    console.log('Dry run — no writes made. Re-run without --dry-run to apply.');
    return;
  }

  console.log('Writing repairs...');
  let written = 0;
  const batchSize = 400;

  for (let i = 0; i < orphans.length; i += batchSize) {
    const batch = db.batch();
    const chunk = orphans.slice(i, i + batchSize);
    for (const user of chunk) {
      batch.set(db.collection('users').doc(user.uid), buildSeed(user), { merge: true });
    }
    await batch.commit();
    written += chunk.length;
    console.log(`  ...${written}/${orphans.length} orphans seeded`);
  }

  for (let i = 0; i < missingCreatedAt.length; i += batchSize) {
    const batch = db.batch();
    const chunk = missingCreatedAt.slice(i, i + batchSize);
    for (const user of chunk) {
      const createdAt = user.metadata?.creationTime
        ? admin.firestore.Timestamp.fromDate(new Date(user.metadata.creationTime))
        : admin.firestore.FieldValue.serverTimestamp();
      batch.set(
        db.collection('users').doc(user.uid),
        {
          created_at: createdAt,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          repaired_by: 'backfill_script',
        },
        { merge: true }
      );
    }
    await batch.commit();
    console.log(`  ...repaired created_at on ${Math.min(i + batchSize, missingCreatedAt.length)}/${missingCreatedAt.length}`);
  }

  console.log('');
  console.log('Done.');
}

main()
  .catch(err => {
    console.error('Backfill failed:', err);
    process.exit(1);
  })
  .finally(() => {
    setTimeout(() => process.exit(0), 500);
  });
