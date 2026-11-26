#!/usr/bin/env node
// Replace the App Store screenshots of an editable version and (optionally) add the en-US listing.
// Never submits for review.
//
// Usage: node app-store-assets/asc-upload.js <versionString> [--en-listing]
// Auth: ASC API key 784AHAY2BN in ~/.appstoreconnect/private_keys (see ios-release-pipeline KB note).
const fs = require('fs'), path = require('path'), os = require('os'), crypto = require('crypto');

const APP_ID = '6817892036';
const KEY_ID = '784AHAY2BN', ISSUER = '8129ee3d-6a41-496a-8f1c-2cb67c1a75df';
const OUT = path.join(__dirname, 'out');
const SETS = [ // display type -> out/<lang>/<folder>
  ['APP_IPHONE_67', 'iphone69'],
  ['APP_IPHONE_65', 'iphone65'],
  ['APP_IPAD_PRO_3GEN_129', 'ipad13'],
];
const LOCALES = { 'ar-SA': 'ar', 'en-US': 'en' };

function jwt() {
  const p8 = fs.readFileSync(path.join(os.homedir(), `.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`), 'utf8');
  const b = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const h = b({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' }), p = b({ iss: ISSUER, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' });
  const sig = crypto.sign('sha256', Buffer.from(`${h}.${p}`), { key: p8, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${h}.${p}.${sig}`;
}
const TOKEN = jwt();
async function retry(fn, tries = 4) {
  for (let i = 1; ; i++) {
    try { return await fn(); } catch (e) {
      if (i >= tries || !/fetch failed|ECONNRESET|ETIMEDOUT|socket/i.test(String(e.message) + String(e.cause))) throw e;
      await new Promise(r => setTimeout(r, 2000 * i));
    }
  }
}
const fetch = (...a) => retry(() => globalThis.fetch(...a));
async function asc(ep, method = 'GET', body) {
  const r = await fetch(`https://api.appstoreconnect.apple.com${ep}`, {
    method, headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`${method} ${ep} -> ${r.status} ${t.slice(0, 500)}`);
  return t ? JSON.parse(t) : {};
}

async function uploadShot(setId, file) {
  const bytes = fs.readFileSync(file);
  const res = await asc('/v1/appScreenshots', 'POST', { data: { type: 'appScreenshots',
    attributes: { fileName: path.basename(file), fileSize: bytes.length },
    relationships: { appScreenshotSet: { data: { type: 'appScreenshotSets', id: setId } } } } });
  const shot = res.data;
  for (const op of shot.attributes.uploadOperations) {
    const headers = Object.fromEntries(op.requestHeaders.map(h => [h.name, h.value]));
    const r = await fetch(op.url, { method: op.method, headers, body: bytes.subarray(op.offset, op.offset + op.length) });
    if (!r.ok) throw new Error(`upload part ${r.status}`);
  }
  await asc(`/v1/appScreenshots/${shot.id}`, 'PATCH', { data: { type: 'appScreenshots', id: shot.id,
    attributes: { uploaded: true, sourceFileChecksum: crypto.createHash('md5').update(bytes).digest('hex') } } });
  return shot.id;
}

async function replaceSets(locId, lang) {
  const existing = await asc(`/v1/appStoreVersionLocalizations/${locId}/appScreenshotSets`);
  for (const s of existing.data) {
    await asc(`/v1/appScreenshotSets/${s.id}`, 'DELETE');
    console.log(`  deleted old set ${s.attributes.screenshotDisplayType}`);
  }
  for (const [type, folder] of SETS) {
    const dir = path.join(OUT, lang, folder);
    if (!fs.existsSync(dir)) { console.log(`  skip ${type}: no ${dir}`); continue; }
    const files = fs.readdirSync(dir).filter(f => f.endsWith('.png')).sort();
    const set = (await asc('/v1/appScreenshotSets', 'POST', { data: { type: 'appScreenshotSets',
      attributes: { screenshotDisplayType: type },
      relationships: { appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: locId } } } } })).data;
    for (const f of files) await uploadShot(set.id, path.join(dir, f));
    console.log(`  ${type}: uploaded ${files.length}`);
  }
}

(async () => {
  const [versionString] = process.argv.slice(2);
  const withEn = process.argv.includes('--en-listing');
  const versions = await asc(`/v1/apps/${APP_ID}/appStoreVersions?filter[versionString]=${versionString}`);
  const version = versions.data[0];
  if (!version) throw new Error(`version ${versionString} not found`);
  const state = version.attributes.appStoreState;
  if (!['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED'].includes(state)) {
    throw new Error(`version ${versionString} is ${state}, not editable`);
  }
  let locs = (await asc(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`)).data;

  if (withEn) {
    const listing = JSON.parse(fs.readFileSync(path.join(__dirname, 'listing-en-US.json'), 'utf8'));
    if (!locs.find(l => l.attributes.locale === 'en-US')) {
      await asc('/v1/appStoreVersionLocalizations', 'POST', { data: { type: 'appStoreVersionLocalizations',
        attributes: { locale: 'en-US', ...listing.version },
        relationships: { appStoreVersion: { data: { type: 'appStoreVersions', id: version.id } } } } });
      console.log('created en-US version localization');
    }
    const infos = (await asc(`/v1/apps/${APP_ID}/appInfos`)).data;
    const info = infos.find(i => !['READY_FOR_SALE', 'READY_FOR_DISTRIBUTION'].includes(i.attributes.appStoreState || i.attributes.state)) || infos[0];
    const infoLocs = (await asc(`/v1/appInfos/${info.id}/appInfoLocalizations`)).data;
    if (!infoLocs.find(l => l.attributes.locale === 'en-US')) {
      await asc('/v1/appInfoLocalizations', 'POST', { data: { type: 'appInfoLocalizations',
        attributes: { locale: 'en-US', ...listing.appInfo },
        relationships: { appInfo: { data: { type: 'appInfos', id: info.id } } } } });
      console.log(`created en-US app info localization on ${info.id}`);
    }
    locs = (await asc(`/v1/appStoreVersions/${version.id}/appStoreVersionLocalizations`)).data;
  }

  for (const loc of locs) {
    const lang = LOCALES[loc.attributes.locale];
    if (!lang) continue;
    console.log(`${loc.attributes.locale}:`);
    await replaceSets(loc.id, lang);
  }

  // Report processing state.
  for (const loc of locs) {
    const sets = await asc(`/v1/appStoreVersionLocalizations/${loc.id}/appScreenshotSets?include=appScreenshots`);
    for (const s of sets.data) {
      const shots = (sets.included || []).filter(i => s.relationships.appScreenshots.data.some(d => d.id === i.id));
      console.log(`${loc.attributes.locale} ${s.attributes.screenshotDisplayType}: ${shots.map(x => x.attributes.assetDeliveryState?.state).join(',')}`);
    }
  }
})().catch(e => { console.error(e.message); process.exit(1); });
