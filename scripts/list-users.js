const { execSync } = require('child_process');
const https = require('https');

const PROJECT_ID = 'sanad-app-beldify';

// Get access token from gcloud/firebase
function getAccessToken() {
  // Try firebase first
  try {
    const token = execSync('firebase login:ci --no-localhost 2>/dev/null', { encoding: 'utf8' }).trim();
    if (token) return token;
  } catch {}

  // Use firebase internals - the CLI stores tokens we can use
  try {
    const result = execSync(
      `node -e "const c = require(require('path').join(require('os').homedir(), '.config/configstore/firebase-tools.json')); console.log(JSON.stringify(c))"`,
      { encoding: 'utf8' }
    );
    const config = JSON.parse(result);
    if (config.tokens?.refresh_token) {
      // Exchange refresh token for access token
      return exchangeRefreshToken(config.tokens.refresh_token);
    }
  } catch (e) {}

  throw new Error('Could not get access token. Run: firebase login');
}

function exchangeRefreshToken(refreshToken) {
  // Synchronous HTTP is hard in Node, let's use a different approach
  return refreshToken; // We'll handle this async
}

async function getAccessTokenAsync() {
  try {
    const fs = require('fs');
    const os = require('os');
    const path = require('path');
    const configPath = path.join(os.homedir(), '.config/configstore/firebase-tools.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    const refreshToken = config.tokens?.refresh_token;

    if (!refreshToken) throw new Error('No refresh token');

    // Exchange for access token
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
          else reject(new Error('No access token: ' + data));
        });
      });
      req.write(postData);
      req.end();
    });
  } catch (e) {
    throw new Error('Could not get access token: ' + e.message);
  }
}

function firestoreRequest(accessToken, path, method = 'GET', body = null) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents${path}`;
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      method,
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          resolve(data);
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function parseFirestoreValue(val) {
  if (!val) return null;
  if ('stringValue' in val) return val.stringValue;
  if ('booleanValue' in val) return val.booleanValue;
  if ('integerValue' in val) return parseInt(val.integerValue);
  if ('doubleValue' in val) return val.doubleValue;
  if ('timestampValue' in val) return val.timestampValue;
  if ('nullValue' in val) return null;
  if ('mapValue' in val) {
    const result = {};
    for (const [k, v] of Object.entries(val.mapValue.fields || {})) {
      result[k] = parseFirestoreValue(v);
    }
    return result;
  }
  if ('arrayValue' in val) {
    return (val.arrayValue.values || []).map(parseFirestoreValue);
  }
  return JSON.stringify(val);
}

function parseDocument(doc) {
  const fields = {};
  for (const [k, v] of Object.entries(doc.fields || {})) {
    fields[k] = parseFirestoreValue(v);
  }
  const id = doc.name.split('/').pop();
  return { id, ...fields };
}

async function main() {
  console.log('Getting access token...');
  const token = await getAccessTokenAsync();
  console.log('Got access token.\n');

  // List users collection
  console.log('=== Fetching users collection ===\n');
  let allDocs = [];
  let nextPageToken = null;
  do {
    const pagePath = `/users?pageSize=100${nextPageToken ? '&pageToken=' + nextPageToken : ''}`;
    const result = await firestoreRequest(token, pagePath);
    if (result.documents) {
      allDocs = allDocs.concat(result.documents);
    }
    nextPageToken = result.nextPageToken;
  } while (nextPageToken);

  console.log(`Total users: ${allDocs.length}\n`);

  const standardFields = [
    'email', 'name', 'display_name', 'phone', 'avatar_url',
    'date_of_birth', 'gender', 'role', 'is_premium',
    'subscription_status', 'subscription_plan', 'subscription_product_title',
    'subscription_expiry_date', 'subscription_start_date',
    'subscription_assigned_by', 'subscription_assigned_at',
    'subscription_revoked_at', 'subscription_revoked_by',
    'payment_gateway', 'auto_renew', 'premium_updated_at',
    'has_complete_profile', 'therapist_status',
    'whatsapp_number', 'whatsapp_ads_consent',
    'matching_preferences', 'last_login', 'created_at', 'updated_at',
    'settings', 'migrated_at', 'auth_provider',
    'profile_completion_percentage', 'crisis_mode', 'crisis_mode_set_at',
    'crisis_mode_set_by',
  ];

  const critical = ['email', 'name', 'role', 'settings', 'created_at', 'updated_at',
    'is_premium', 'subscription_status', 'has_complete_profile'];

  for (const doc of allDocs) {
    const parsed = parseDocument(doc);
    const fields = Object.keys(parsed).filter(f => f !== 'id').sort();

    console.log(`--- ${parsed.id} ---`);
    console.log(`  email: ${parsed.email || 'N/A'}`);
    console.log(`  name: ${parsed.name || 'N/A'}`);
    console.log(`  display_name: ${parsed.display_name || 'N/A'}`);
    console.log(`  role: ${parsed.role || 'N/A'}`);
    console.log(`  has_complete_profile: ${parsed.has_complete_profile}`);
    console.log(`  subscription_status: ${parsed.subscription_status || 'N/A'}`);
    console.log(`  is_premium: ${parsed.is_premium}`);
    console.log(`  settings: ${parsed.settings ? 'present' : 'MISSING'}`);

    const nonStandard = fields.filter(f => !standardFields.includes(f));
    if (nonStandard.length > 0) {
      console.log(`  ⚠️  Non-standard fields: ${nonStandard.join(', ')}`);
    }

    const missing = critical.filter(f => parsed[f] === undefined || parsed[f] === null);
    if (missing.length > 0) {
      console.log(`  ❌ Missing critical: ${missing.join(', ')}`);
    }
    console.log('');
  }

  // Check legacy collection
  console.log('=== Legacy user_profiles collection ===');
  const legacyResult = await firestoreRequest(token, '/user_profiles?pageSize=100');
  if (legacyResult.documents && legacyResult.documents.length > 0) {
    console.log(`Found ${legacyResult.documents.length} legacy documents:`);
    for (const doc of legacyResult.documents) {
      const p = parseDocument(doc);
      console.log(`  - ${p.id}: ${p.email || 'no email'}`);
    }
  } else {
    console.log('No legacy user_profiles documents found.');
  }
}

main().catch(e => { console.error(e); process.exit(1); });
