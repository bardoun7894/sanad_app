// grant-admin.js — grant (or inspect) admin role for a Sanad account.
//
// The app decides admin via auth_provider.dart:239-286, in order:
//   1. custom claim  admin == true
//   2. Firestore     users/{uid}.role == 'admin'
//   3. else          UserRole.user
// The email super-admin fallback only exists in firestore.rules, NOT in the
// app — so an account with no claim and role != 'admin' is treated as a plain
// user even though the rules let it touch admin data. This script fixes that
// by setting BOTH the custom claim and the Firestore role (same as the
// setAdminClaim Cloud Function, but bootstraps via ADC so it works even when
// no admin claim exists yet).
//
// Usage:
//   node grant-admin.js                       # dry-run, default email sanadpsy@gmail.com
//   node grant-admin.js <email>               # dry-run for a specific email
//   node grant-admin.js <email> --apply       # actually grant admin
//   node grant-admin.js <email> --apply --revoke   # remove admin instead
//
// After --apply, the target user must sign out and back in once so the new
// custom claim lands in their ID token.

const admin = require('firebase-admin');

const PROJECT_ID = 'sanad-app-beldify';
const EMAIL = process.argv.find((a) => a.includes('@')) || 'sanadpsy@gmail.com';
const APPLY = process.argv.includes('--apply');
const REVOKE = process.argv.includes('--revoke');
const MAKE_ADMIN = !REVOKE;

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: PROJECT_ID,
});

const auth = admin.auth();
const db = admin.firestore();

async function main() {
  console.log(`Project : ${PROJECT_ID}`);
  console.log(`Target  : ${EMAIL}`);
  console.log(`Action  : ${MAKE_ADMIN ? 'GRANT admin' : 'REVOKE admin'}`);
  console.log(`Mode    : ${APPLY ? 'APPLY (writes)' : 'DRY-RUN (read-only)'}`);
  console.log('');

  let user;
  try {
    user = await auth.getUserByEmail(EMAIL);
  } catch (e) {
    console.error(`✗ Could not find an auth user with email ${EMAIL}: ${e.message}`);
    process.exit(1);
  }

  const uid = user.uid;
  const currentClaims = user.customClaims || {};
  const docRef = db.collection('users').doc(uid);
  const docSnap = await docRef.get();
  const currentDocRole = docSnap.exists ? docSnap.data().role : '(no user doc)';

  console.log('--- current state ---');
  console.log(`  uid            : ${uid}`);
  console.log(`  displayName    : ${user.displayName || '(none)'}`);
  console.log(`  custom claims  : ${JSON.stringify(currentClaims)}`);
  console.log(`  users/{uid}.role : ${currentDocRole}`);
  console.log('');

  const newClaims = { ...currentClaims };
  if (MAKE_ADMIN) {
    newClaims.admin = true;
    newClaims.role = 'admin';
  } else {
    delete newClaims.admin;
    newClaims.role = 'user';
  }
  const newDocRole = MAKE_ADMIN ? 'admin' : 'user';

  console.log('--- would change to ---');
  console.log(`  custom claims  : ${JSON.stringify(newClaims)}`);
  console.log(`  users/{uid}.role : ${newDocRole}`);
  console.log('');

  if (!APPLY) {
    console.log('Dry-run only. Re-run with --apply to write these changes.');
    return;
  }

  await auth.setCustomUserClaims(uid, newClaims);
  if (docSnap.exists) {
    await docRef.update({ role: newDocRole, updated_at: admin.firestore.FieldValue.serverTimestamp() });
  } else {
    await docRef.set({ role: newDocRole, email: EMAIL, updated_at: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  }

  // Verify
  const after = await auth.getUser(uid);
  const afterDoc = await docRef.get();
  console.log('--- after (verified) ---');
  console.log(`  custom claims  : ${JSON.stringify(after.customClaims || {})}`);
  console.log(`  users/{uid}.role : ${afterDoc.data().role}`);
  console.log('');
  console.log(`✓ ${MAKE_ADMIN ? 'Granted' : 'Revoked'} admin for ${EMAIL} (${uid}).`);
  console.log('  → The user must sign OUT and back IN once to refresh their ID token.');
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('✗ Failed:', e.message);
    process.exit(1);
  });
