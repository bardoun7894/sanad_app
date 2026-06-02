// One-off cleanup: delete every Firebase Auth user AND every Firestore
// users/{uid} document EXCEPT sanadpsy@gmail.com. Does NOT touch related
// data (bookings, payments, chats, etc.) — those become orphans per user's
// explicit choice on 2026-05-24.
//
// Usage:
//   node wipe-users-except-sanadpsy.js              # dry-run (prints counts only)
//   node wipe-users-except-sanadpsy.js --apply      # actually deletes
//
// Auth: uses Application Default Credentials. Run once:
//   gcloud auth application-default login --project=sanad-app-beldify

const admin = require('firebase-admin');

const PROJECT_ID = 'sanad-app-beldify';
const KEEP_EMAIL = 'sanadpsy@gmail.com';
const APPLY = process.argv.includes('--apply');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: PROJECT_ID,
});

const auth = admin.auth();
const db = admin.firestore();

async function listAllAuthUsers() {
  const all = [];
  let pageToken;
  do {
    const result = await auth.listUsers(1000, pageToken);
    all.push(...result.users);
    pageToken = result.pageToken;
  } while (pageToken);
  return all;
}

async function listAllFirestoreUserDocs() {
  const snapshot = await db.collection('users').get();
  return snapshot.docs;
}

async function deleteAuthUsersInBatches(uids) {
  // Firebase admin SDK deleteUsers takes up to 1000 UIDs per call.
  const BATCH = 1000;
  let deleted = 0;
  let failed = 0;
  for (let i = 0; i < uids.length; i += BATCH) {
    const chunk = uids.slice(i, i + BATCH);
    const result = await auth.deleteUsers(chunk);
    deleted += result.successCount;
    failed += result.failureCount;
    if (result.errors && result.errors.length > 0) {
      console.log(`  ⚠ ${result.errors.length} errors in this chunk:`);
      result.errors.slice(0, 5).forEach((e) =>
        console.log(`    - uid=${chunk[e.index]}: ${e.error.message}`),
      );
    }
    console.log(`  → progress: deleted=${deleted}/${uids.length}, failed=${failed}`);
  }
  return { deleted, failed };
}

async function deleteFirestoreDocsInBatches(docs) {
  // Firestore batched writes hold up to 500 ops each.
  const BATCH = 500;
  let deleted = 0;
  for (let i = 0; i < docs.length; i += BATCH) {
    const chunk = docs.slice(i, i + BATCH);
    const batch = db.batch();
    chunk.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    deleted += chunk.length;
    console.log(`  → progress: deleted=${deleted}/${docs.length}`);
  }
  return deleted;
}

async function main() {
  console.log(`Project: ${PROJECT_ID}`);
  console.log(`Mode:    ${APPLY ? '🔴 APPLY (destructive)' : '🟢 dry-run'}`);
  console.log(`Keep:    ${KEEP_EMAIL}\n`);

  // Resolve UID of the user to keep
  let keepUid;
  try {
    const keepUser = await auth.getUserByEmail(KEEP_EMAIL);
    keepUid = keepUser.uid;
    console.log(`✓ Keep user resolved: ${KEEP_EMAIL} → uid ${keepUid}\n`);
  } catch (err) {
    console.error(`✗ Could not resolve ${KEEP_EMAIL}: ${err.message}`);
    console.error('Aborting — refusing to proceed without a confirmed keep UID.');
    process.exit(1);
  }

  // ── Firebase Auth users ────────────────────────────────────────────────
  console.log('Listing all Firebase Auth users…');
  const allAuthUsers = await listAllAuthUsers();
  console.log(`  total: ${allAuthUsers.length}`);

  const authToDelete = allAuthUsers.filter((u) => u.uid !== keepUid);
  console.log(`  to delete: ${authToDelete.length}`);
  console.log(`  to keep:   ${allAuthUsers.length - authToDelete.length}\n`);

  // ── Firestore users/ docs ──────────────────────────────────────────────
  console.log('Listing all Firestore users/ documents…');
  const allDocs = await listAllFirestoreUserDocs();
  console.log(`  total: ${allDocs.length}`);

  const docsToDelete = allDocs.filter((d) => d.id !== keepUid);
  console.log(`  to delete: ${docsToDelete.length}`);
  console.log(`  to keep:   ${allDocs.length - docsToDelete.length}\n`);

  // Sample preview
  console.log('Sample of first 5 Auth users to delete:');
  authToDelete.slice(0, 5).forEach((u) =>
    console.log(`  - ${u.uid}  ${u.email || '(no email)'}  ${u.displayName || ''}`),
  );

  if (!APPLY) {
    console.log('\n[dry-run] No changes made. Re-run with --apply to delete.');
    return;
  }

  // ── Apply ──────────────────────────────────────────────────────────────
  console.log('\n=== APPLYING DELETION ===');

  console.log('\nDeleting Firebase Auth users…');
  const authResult = await deleteAuthUsersInBatches(
    authToDelete.map((u) => u.uid),
  );
  console.log(
    `Auth result: ${authResult.deleted} deleted, ${authResult.failed} failed.`,
  );

  console.log('\nDeleting Firestore users/ documents…');
  const fsDeleted = await deleteFirestoreDocsInBatches(docsToDelete);
  console.log(`Firestore result: ${fsDeleted} deleted.`);

  console.log('\n✅ Done.');
  console.log(
    `Final: kept ${KEEP_EMAIL} (uid ${keepUid}). Auth=${authResult.deleted} deleted; Firestore users/=${fsDeleted} deleted.`,
  );
  console.log(
    'Note: bookings/, payments/, chats/, notifications/, mood_entries/, etc. were NOT touched per user request — they are now orphaned.',
  );
}

main()
  .catch((e) => {
    console.error('Fatal:', e);
    process.exit(1);
  })
  .finally(() => process.exit(0));
