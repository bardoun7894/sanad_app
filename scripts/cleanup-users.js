const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');

const PROJECT_ID = 'sanad-app-beldify';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

// Users to KEEP
const KEEP_UIDS = [
  'LUAqWpsZf8S8Qf020gaWB9wRSD82', // mbardouni44@gmail.com
  '45VN8ZuxncaU65FIjx4PN6YSGP02', // sanadpsy@gmail.com (Sanad Psy)
  'Dioajt0tqGgpBc0c2e3QdfI5Paj2', // beldify@gmail.com
];

// Sub-collections under each user doc
const USER_SUBCOLLECTIONS = ['mood_entries', 'test_results', 'engagement'];

// Default field values for normalization
const DEFAULT_FIELDS = {
  is_premium: { booleanValue: false },
  subscription_status: { stringValue: 'free' },
  has_complete_profile: { booleanValue: false },
};

const DEFAULT_SETTINGS = {
  notifications_enabled: { booleanValue: true },
  daily_reminders: { booleanValue: true },
  mood_tracking_reminders: { booleanValue: true },
  reminder_time: { stringValue: '09:00' },
  dark_mode: { booleanValue: false },
  language: { stringValue: 'English' },
  anonymous_in_community: { booleanValue: false },
  share_progress: { booleanValue: false },
};

// ⚠️  DANGER: this script DELETES users and PATCHES the survivors. Never run it
// against production without an explicit pre-launch-reset purpose.
// `first_name` and `last_name` are LIVE canonical name fields (written by
// verifyOtp + completeProfile, read by the admin dashboard) — they were
// removed from this list so a re-run can never strip real users' names.
const FIELDS_TO_REMOVE = ['displayName', 'uid', 'updated_by', 'claims_updated_at', 'custom_claims_synced', 'premium_updated_by', 'whatsapp_consent'];

async function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config/configstore/firebase-tools.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const refreshToken = config.tokens?.refresh_token;
  if (!refreshToken) throw new Error('No refresh token found');

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
    const url = `${BASE_URL}/${collectionPath}?pageSize=100${nextPageToken ? '&pageToken=' + nextPageToken : ''}`;
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

async function patchDocument(token, docName, fieldsToUpdate, fieldsToRemove = []) {
  // Build update mask
  const updateFields = Object.keys(fieldsToUpdate);
  const allFields = [...updateFields, ...fieldsToRemove];
  const mask = allFields.map(f => `updateMask.fieldPaths=${f}`).join('&');

  // For field removal, we use the update mask but don't include the field in the body
  const url = `https://firestore.googleapis.com/v1/${docName}?${mask}`;
  const body = { fields: fieldsToUpdate };
  const result = await httpRequest(url, 'PATCH', token, body);
  return result;
}

async function main() {
  console.log('🔑 Getting access token...');
  const token = await getAccessToken();

  // ==========================================
  // STEP 1: Delete users NOT in KEEP list
  // ==========================================
  console.log('\n📋 Fetching all users...');
  const allUsers = await listCollection(token, 'users');
  console.log(`Found ${allUsers.length} users total.`);

  const toDelete = allUsers.filter(doc => {
    const uid = doc.name.split('/').pop();
    return !KEEP_UIDS.includes(uid);
  });

  const toKeep = allUsers.filter(doc => {
    const uid = doc.name.split('/').pop();
    return KEEP_UIDS.includes(uid);
  });

  console.log(`Keeping: ${toKeep.map(d => d.name.split('/').pop()).join(', ')}`);
  console.log(`Deleting: ${toDelete.length} users\n`);

  // Delete sub-collections first, then user docs
  for (const doc of toDelete) {
    const uid = doc.name.split('/').pop();
    const email = doc.fields?.email?.stringValue || 'no-email';
    console.log(`🗑️  Deleting user ${uid} (${email})...`);

    // Delete sub-collections
    for (const subCol of USER_SUBCOLLECTIONS) {
      const subDocs = await listCollection(token, `users/${uid}/${subCol}`);
      for (const subDoc of subDocs) {
        await deleteDocument(token, subDoc.name);
      }
      if (subDocs.length > 0) {
        console.log(`   Deleted ${subDocs.length} docs from ${subCol}`);
      }
    }

    // Delete user doc
    const ok = await deleteDocument(token, doc.name);
    console.log(`   User doc: ${ok ? 'deleted' : 'FAILED'}`);
  }

  // ==========================================
  // STEP 2: Normalize kept users
  // ==========================================
  console.log('\n✨ Normalizing kept users...\n');

  for (const doc of toKeep) {
    const uid = doc.name.split('/').pop();
    const fields = doc.fields || {};
    const email = fields.email?.stringValue || 'N/A';
    console.log(`Normalizing ${uid} (${email})...`);

    const updates = {};
    const removals = [];

    // Add missing critical fields with defaults
    for (const [field, defaultVal] of Object.entries(DEFAULT_FIELDS)) {
      if (!fields[field]) {
        updates[field] = defaultVal;
        console.log(`   + Adding ${field} = ${JSON.stringify(defaultVal)}`);
      }
    }

    // Ensure settings map has all required keys
    if (!fields.settings) {
      updates.settings = { mapValue: { fields: DEFAULT_SETTINGS } };
      console.log('   + Adding complete settings map');
    } else {
      // Merge missing settings keys
      const existingSettings = fields.settings.mapValue?.fields || {};
      const mergedSettings = { ...existingSettings };
      let settingsUpdated = false;
      for (const [key, val] of Object.entries(DEFAULT_SETTINGS)) {
        if (!mergedSettings[key]) {
          mergedSettings[key] = val;
          settingsUpdated = true;
          console.log(`   + Adding settings.${key}`);
        }
      }
      if (settingsUpdated) {
        updates.settings = { mapValue: { fields: mergedSettings } };
      }
    }

    // Ensure updated_at exists
    if (!fields.updated_at) {
      updates.updated_at = { timestampValue: new Date().toISOString() };
      console.log('   + Adding updated_at');
    }

    // Ensure created_at exists
    if (!fields.created_at) {
      updates.created_at = { timestampValue: new Date().toISOString() };
      console.log('   + Adding created_at');
    }

    // Remove non-standard fields
    for (const field of FIELDS_TO_REMOVE) {
      if (fields[field]) {
        removals.push(field);
        console.log(`   - Removing non-standard field: ${field}`);
      }
    }

    // Fix whatsapp_consent -> whatsapp_ads_consent
    if (fields.whatsapp_consent && !fields.whatsapp_ads_consent) {
      updates.whatsapp_ads_consent = fields.whatsapp_consent;
      console.log('   ~ Renamed whatsapp_consent -> whatsapp_ads_consent');
    }

    if (Object.keys(updates).length > 0 || removals.length > 0) {
      const result = await patchDocument(token, doc.name, updates, removals);
      if (result.status === 200) {
        console.log(`   ✅ Updated successfully`);
      } else {
        console.log(`   ❌ Update failed: ${JSON.stringify(result.body)}`);
      }
    } else {
      console.log('   Already clean!');
    }
  }

  // ==========================================
  // STEP 3: Clean up related orphan data
  // ==========================================
  console.log('\n🧹 Cleaning up related data for deleted users...\n');

  // Delete legacy user_profiles collection
  const legacyDocs = await listCollection(token, 'user_profiles');
  if (legacyDocs.length > 0) {
    console.log(`Deleting ${legacyDocs.length} legacy user_profiles docs...`);
    for (const doc of legacyDocs) {
      await deleteDocument(token, doc.name);
      console.log(`   Deleted ${doc.name.split('/').pop()}`);
    }
  } else {
    console.log('No legacy user_profiles to clean.');
  }

  // Clean bookings for deleted users
  const deletedUids = toDelete.map(d => d.name.split('/').pop());
  const allBookings = await listCollection(token, 'bookings');
  let deletedBookings = 0;
  for (const doc of allBookings) {
    const clientId = doc.fields?.client_id?.stringValue || doc.fields?.user_id?.stringValue;
    if (clientId && deletedUids.includes(clientId)) {
      await deleteDocument(token, doc.name);
      deletedBookings++;
    }
  }
  if (deletedBookings > 0) console.log(`Deleted ${deletedBookings} orphaned bookings.`);

  // Clean payments for deleted users
  const allPayments = await listCollection(token, 'payments');
  let deletedPayments = 0;
  for (const doc of allPayments) {
    const userId = doc.fields?.user_id?.stringValue;
    if (userId && deletedUids.includes(userId)) {
      await deleteDocument(token, doc.name);
      deletedPayments++;
    }
  }
  if (deletedPayments > 0) console.log(`Deleted ${deletedPayments} orphaned payments.`);

  // Clean payment_verifications for deleted users
  const allVerifications = await listCollection(token, 'payment_verifications');
  let deletedVerifications = 0;
  for (const doc of allVerifications) {
    const userId = doc.fields?.user_id?.stringValue || doc.fields?.od_id?.stringValue;
    if (userId && deletedUids.includes(userId)) {
      await deleteDocument(token, doc.name);
      deletedVerifications++;
    }
  }
  if (deletedVerifications > 0) console.log(`Deleted ${deletedVerifications} orphaned verifications.`);

  // Clean activity_logs for deleted users
  const allLogs = await listCollection(token, 'activity_logs');
  let deletedLogs = 0;
  for (const doc of allLogs) {
    const userId = doc.fields?.user_id?.stringValue;
    if (userId && deletedUids.includes(userId)) {
      await deleteDocument(token, doc.name);
      deletedLogs++;
    }
  }
  if (deletedLogs > 0) console.log(`Deleted ${deletedLogs} orphaned activity logs.`);

  console.log('\n✅ Cleanup complete!');
  console.log(`Kept ${toKeep.length} users, deleted ${toDelete.length} users + related data.`);
}

main().catch(e => { console.error('Fatal error:', e); process.exit(1); });
