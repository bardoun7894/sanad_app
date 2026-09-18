#!/usr/bin/env node
// Strict re-evaluation of `has_complete_profile` on ALL users/{uid} docs.
//
// WHY: the flag gates the app's hard profile-completion gate AND feeds the
// admin "incomplete profiles" list. It used to be derived from a weak rule
// (name + phone only), so users who signed up with just a name and phone were
// flagged complete — they reached Home with no gender / DOB / matching data
// and never saw the wizard. This script recomputes the flag for every
// role == 'user' doc against the SAME strict mandatory set the app gate,
// completeProfile callable and syncProfileCompletion trigger enforce.
//
// Strict set: real name, phone OR WhatsApp, gender, date_of_birth, avatar_url,
// at least one matching goal, relationship status, preferred therapist gender.
//
// Unlike the previous version this does NOT skip docs that already carry the
// field — flipping wrong true→false is the whole point. Staff docs
// (therapist/admin) are excluded so a data gap can never lock them out.
//
// Safety:
//   - dry-run by default; re-run with --execute to write
//   - a backup JSON of every changed doc is written to
//     backups/has-complete-profile-<timestamp>.json before any write
//
// Usage:
//   GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/backfill-has-complete-profile.js           # dry-run
//   GOOGLE_CLOUD_PROJECT=sanad-app-beldify node scripts/backfill-has-complete-profile.js --execute  # write

const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const EXECUTE = process.argv.includes('--execute');

const str = (v) => (v == null ? '' : String(v).trim());
// 'User'/'مستخدم' are placeholder names seeded for nameless signups — they
// do not count as a real name.
function realName(v) {
  const t = str(v).toLowerCase();
  return !!t && t !== 'user' && t !== 'مستخدم';
}

// Same strict mandatory set as completeProfile callable + syncProfileCompletion
// trigger + the Flutter wizard's mandatory gate.
function isStrictComplete(d) {
  const hasName =
    realName(d.first_name) || realName(d.display_name) || realName(d.name);
  const hasPhone = !!str(d.phone) || !!str(d.whatsapp_number);
  const hasGender = !!str(d.gender);
  const hasDob = !!d.date_of_birth;
  const hasAvatar = !!str(d.avatar_url);
  const mp = d.matching_preferences || {};
  const hasGoals = Array.isArray(mp.goals) && mp.goals.length > 0;
  const hasRelationship = !!str(mp.relationship_status);
  const hasPreferredGender = !!str(mp.preferred_therapist_gender);
  return (
    hasName && hasPhone && hasGender && hasDob && hasAvatar &&
    hasGoals && hasRelationship && hasPreferredGender
  );
}

(async () => {
  console.log(`Mode: ${EXECUTE ? 'EXECUTE (will write)' : 'DRY-RUN'}`);
  console.log('Project: sanad-app-beldify\n');

  // Backup dir next to this script.
  const backupDir = path.join(__dirname, 'backups');
  if (EXECUTE) fs.mkdirSync(backupDir, { recursive: true });

  const changes = [];
  let scanned = 0;

  // Cursor-paginated scan — never loads the whole collection at once.
  let cursor = null;
  let docs;
  do {
    let q = db.collection('users')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(500);
    if (cursor) q = q.startAfter(cursor);
    const snap = await q.get();
    docs = snap.docs;
    for (const doc of docs) {
      cursor = doc;
      const d = doc.data();
      scanned++;
      if ((d.role || 'user') !== 'user') continue; // staff exempt
      const complete = isStrictComplete(d);
      const flagged = d.has_complete_profile === true;
      if (flagged === complete) continue;
      changes.push({
        id: doc.id,
        name: d.display_name || d.name || d.first_name || '(no name)',
        from: flagged,
        to: complete,
        doc: d, // for backup/restore
      });
    }
  } while (docs.length === 500);

  console.log(`Total user docs scanned:     ${scanned}`);
  console.log(`Flag changes needed:        ${changes.length}`);
  console.log(`  downgrade true -> false:  ${changes.filter(c => c.from && !c.to).length}`);
  console.log(`  upgrade   false -> true:  ${changes.filter(c => !c.from && c.to).length}\n`);

  for (const t of changes.slice(0, 200)) {
    console.log(`  - ${t.id.padEnd(30)} ${String(t.name).padEnd(26)} ${t.from} -> ${t.to}`);
  }
  if (changes.length > 200) console.log(`  ... and ${changes.length - 200} more`);

  if (changes.length === 0) {
    console.log('\nNothing to repair — every flag already matches the strict set.');
    process.exit(0);
  }
  if (!EXECUTE) {
    console.log('\nDry-run only. Re-run with --execute to apply.');
    process.exit(0);
  }

  // Backup every changed doc BEFORE writing anything.
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupPath = path.join(backupDir, `has-complete-profile-${stamp}.json`);
  const backup = changes.map(c => ({
    id: c.id,
    has_complete_profile: c.from,
    doc: c.doc,
  }));
  fs.writeFileSync(backupPath, JSON.stringify(backup, null, 2));
  console.log(`\nBackup written: ${backupPath}`);

  let written = 0;
  for (let i = 0; i < changes.length; i += 400) {
    const batch = db.batch();
    for (const t of changes.slice(i, i + 400)) {
      batch.set(
        db.collection('users').doc(t.id),
        {
          has_complete_profile: t.to,
          updated_at: FieldValue.serverTimestamp(),
          repaired_by: 'backfill-has-complete-profile-script',
        },
        { merge: true }
      );
    }
    await batch.commit();
    written += Math.min(400, changes.length - i);
  }

  console.log(`\nRepaired ${written} user doc(s).`);
  console.log('Downgraded users will be routed to the profile-completion wizard on next app open.');
  console.log('Incomplete ones now surface in the admin Signup Health screen.');
  process.exit(0);
})().catch(err => { console.error('ERROR:', err.message); process.exit(1); });
