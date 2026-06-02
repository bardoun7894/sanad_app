/**
 * delete-non-allowed-therapists.js
 *
 * Lists all therapists from `therapists/` and `therapist_profiles/` collections,
 * keeps any whose email contains 'sanadpsy' or 'beldify' (case-insensitive),
 * and deletes all others from Firestore + Firebase Auth + related docs.
 *
 * Usage:
 *   node scripts/delete-non-allowed-therapists.js          # dry run
 *   node scripts/delete-non-allowed-therapists.js --confirm  # actually delete
 *
 * Auth: uses firebase-tools refresh token (same pattern as cleanup-users.js).
 * No service account file required.
 */

'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');

const PROJECT_ID = 'sanad-app-beldify';
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const IDENTITY_BASE = `https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}`;

const ALLOWED_SUBSTRINGS = ['sanadpsy', 'beldify'];
const DRY_RUN = !process.argv.includes('--confirm');

// ── Auth ─────────────────────────────────────────────────────────────────────

async function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config/configstore/firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const refreshToken = config.tokens?.refresh_token;
  if (!refreshToken) throw new Error('No refresh token found in firebase-tools.json');

  const postData = new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
  }).toString();

  return new Promise((resolve, reject) => {
    const req = https.request('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    }, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        const parsed = JSON.parse(data);
        if (parsed.access_token) resolve(parsed.access_token);
        else reject(new Error('Token exchange failed: ' + data));
      });
    });
    req.write(postData);
    req.end();
  });
}

// ── HTTP helpers ──────────────────────────────────────────────────────────────

function httpRequest(url, method, token, body = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, body: data }); }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function listCollection(token, collectionPath) {
  let allDocs = [];
  let nextPageToken = null;
  do {
    const url = `${FIRESTORE_BASE}/${collectionPath}?pageSize=100${nextPageToken ? '&pageToken=' + nextPageToken : ''}`;
    const result = await httpRequest(url, 'GET', token);
    if (result.body.documents) {
      allDocs = allDocs.concat(result.body.documents);
    }
    nextPageToken = result.body?.nextPageToken;
  } while (nextPageToken);
  return allDocs;
}

async function deleteDocument(token, docName) {
  const url = `https://firestore.googleapis.com/v1/${docName}`;
  const result = await httpRequest(url, 'DELETE', token);
  return result.status === 200 || result.status === 204;
}

// ── Firebase Auth via Identity Toolkit REST ───────────────────────────────────

/** Look up an Auth user by uid. Returns user object or null if not found. */
async function getAuthUserByUid(token, uid) {
  const url = `${IDENTITY_BASE}/accounts:lookup`;
  const result = await httpRequest(url, 'POST', token, { localId: [uid] });
  if (result.status === 200 && result.body.users && result.body.users.length > 0) {
    return result.body.users[0];
  }
  return null;
}

/** Delete a Firebase Auth user by uid. Returns true on success. */
async function deleteAuthUser(token, uid) {
  const url = `${IDENTITY_BASE}/accounts:delete`;
  const result = await httpRequest(url, 'POST', token, { localId: uid });
  return result.status === 200;
}

// ── Email resolution ──────────────────────────────────────────────────────────

/** Extract email from a Firestore doc's fields map. Returns null if absent. */
function emailFromFields(fields) {
  return fields?.email?.stringValue || null;
}

/** Try to get email from Firestore doc; fall back to Auth lookup by uid. */
async function resolveEmail(token, uid, fields) {
  const fromDoc = emailFromFields(fields);
  if (fromDoc) return fromDoc;

  const authUser = await getAuthUserByUid(token, uid);
  if (authUser && authUser.email) {
    console.log(`  (email resolved from Auth for uid=${uid})`);
    return authUser.email;
  }
  return null;
}

// ── Keep/delete logic ─────────────────────────────────────────────────────────

function isAllowed(email) {
  if (!email) return false;
  const lower = email.toLowerCase();
  return ALLOWED_SUBSTRINGS.some(sub => lower.includes(sub));
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  if (DRY_RUN) {
    console.log('DRY RUN — pass --confirm to actually delete.\n');
  } else {
    console.log('LIVE RUN — deletions will be performed.\n');
  }

  console.log('Getting access token...');
  const token = await getAccessToken();

  // 1. Collect all therapist uids from both collections
  console.log('\nFetching therapists/ collection...');
  const therapistDocs = await listCollection(token, 'therapists');
  console.log(`  Found ${therapistDocs.length} docs in therapists/`);

  console.log('Fetching therapist_profiles/ collection...');
  const profileDocs = await listCollection(token, 'therapist_profiles');
  console.log(`  Found ${profileDocs.length} docs in therapist_profiles/`);

  // Build uid → { email, name, inTherapists, inProfiles } map (union by uid)
  const therapistMap = new Map();

  for (const doc of therapistDocs) {
    const uid = doc.name.split('/').pop();
    const fields = doc.fields || {};
    const entry = therapistMap.get(uid) || { uid, fields, profileFields: null, inTherapists: false, inProfiles: false };
    entry.inTherapists = true;
    entry.fields = fields;
    therapistMap.set(uid, entry);
  }

  for (const doc of profileDocs) {
    const uid = doc.name.split('/').pop();
    const fields = doc.fields || {};
    const entry = therapistMap.get(uid) || { uid, fields: null, profileFields: null, inTherapists: false, inProfiles: false };
    entry.inProfiles = true;
    entry.profileFields = fields;
    therapistMap.set(uid, entry);
  }

  console.log(`\nTotal unique therapist uids: ${therapistMap.size}`);

  // 2. Resolve emails and classify
  const toDelete = [];
  const toKeep = [];

  for (const entry of therapistMap.values()) {
    const { uid, fields, profileFields } = entry;
    // Try therapists/ doc fields first, then therapist_profiles/ doc fields
    let email = emailFromFields(fields) || emailFromFields(profileFields);
    if (!email) {
      email = await resolveEmail(token, uid, fields || profileFields);
    }
    entry.email = email;

    const name = fields?.name?.stringValue || fields?.display_name?.stringValue ||
      profileFields?.name?.stringValue || profileFields?.display_name?.stringValue || '(no name)';
    entry.name = name;

    if (isAllowed(email)) {
      toKeep.push(entry);
    } else {
      toDelete.push(entry);
    }
  }

  // 3. Report
  console.log('\n--- KEEP ---');
  for (const e of toKeep) {
    console.log(`  KEEP   uid=${e.uid}  email=${e.email || '(unknown)'}  name=${e.name}`);
  }

  console.log('\n--- DELETE ---');
  for (const e of toDelete) {
    console.log(`  DELETE uid=${e.uid}  email=${e.email || '(unknown)'}  name=${e.name}`);
  }

  if (DRY_RUN) {
    console.log(`\nDRY RUN — would delete ${toDelete.length} therapist(s), keeping ${toKeep.length}.`);
    console.log('Run with --confirm to perform deletions.');
    return;
  }

  // 4. Delete
  let deletedCount = 0;
  let failedCount = 0;

  for (const e of toDelete) {
    const { uid, email, name } = e;
    console.log(`\nDeleting therapist uid=${uid} email=${email || '(unknown)'} name=${name}...`);

    // 4a. Delete therapists/{uid}
    if (e.inTherapists) {
      const ok = await deleteDocument(token, `projects/${PROJECT_ID}/databases/(default)/documents/therapists/${uid}`);
      console.log(`  therapists/${uid}: ${ok ? 'deleted' : 'FAILED'}`);
    }

    // 4b. Delete therapist_profiles/{uid}
    if (e.inProfiles) {
      const ok = await deleteDocument(token, `projects/${PROJECT_ID}/databases/(default)/documents/therapist_profiles/${uid}`);
      console.log(`  therapist_profiles/${uid}: ${ok ? 'deleted' : 'FAILED'}`);
    }

    // 4c. Delete users/{uid} if it exists
    const userDocResult = await httpRequest(`${FIRESTORE_BASE}/users/${uid}`, 'GET', token);
    if (userDocResult.status === 200) {
      const ok = await deleteDocument(token, `projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`);
      console.log(`  users/${uid}: ${ok ? 'deleted' : 'FAILED'}`);
    } else {
      console.log(`  users/${uid}: not found, skipping`);
    }

    // 4d. Delete therapist_availability docs where therapist_id == uid
    const availDocs = await listCollection(token, 'therapist_availability');
    const ownedSlots = availDocs.filter(d => d.fields?.therapist_id?.stringValue === uid);
    if (ownedSlots.length > 0) {
      let slotDeleted = 0;
      for (const slot of ownedSlots) {
        const ok = await deleteDocument(token, slot.name);
        if (ok) slotDeleted++;
      }
      console.log(`  therapist_availability: deleted ${slotDeleted}/${ownedSlots.length} slots`);
    } else {
      console.log(`  therapist_availability: no slots found`);
    }

    // 4e. Bookings: skip deletion, just warn if any exist
    const allBookings = await listCollection(token, 'bookings');
    const ownedBookings = allBookings.filter(d => d.fields?.therapist_id?.stringValue === uid);
    if (ownedBookings.length > 0) {
      console.log(`  WARNING: ${ownedBookings.length} booking(s) reference this therapist — skipping (may belong to real clients).`);
      for (const b of ownedBookings) {
        const bookingId = b.name.split('/').pop();
        const clientId = b.fields?.client_id?.stringValue || '(unknown client)';
        console.log(`    booking=${bookingId} client=${clientId}`);
      }
    } else {
      console.log(`  bookings: none found`);
    }

    // 4f. Delete Firebase Auth user
    const authDeleted = await deleteAuthUser(token, uid);
    if (authDeleted) {
      console.log(`  Auth user ${uid}: deleted`);
    } else {
      console.log(`  Auth user ${uid}: not found or already deleted`);
    }

    console.log(`  Done: ${uid}`);
    deletedCount++;
  }

  // 5. Summary
  console.log('\n=== SUMMARY ===');
  console.log(`Kept:    ${toKeep.length} therapist(s)`);
  for (const e of toKeep) {
    console.log(`  uid=${e.uid}  email=${e.email || '(unknown)'}  name=${e.name}`);
  }
  console.log(`Deleted: ${deletedCount} therapist(s)`);
  for (const e of toDelete) {
    console.log(`  uid=${e.uid}  email=${e.email || '(unknown)'}  name=${e.name}`);
  }
  if (failedCount > 0) {
    console.log(`Failures: ${failedCount}`);
  }
}

main().catch(e => { console.error('Fatal error:', e); process.exit(1); });
