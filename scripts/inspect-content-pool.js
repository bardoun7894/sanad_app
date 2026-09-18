// READ-ONLY: why does "اخترنا لك" show a single fixed article?
// App query = content where type==X AND is_published==true ORDER BY created_at desc
// orderBy silently drops docs missing created_at — count both ways.
//   node scripts/inspect-content-pool.js

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();

(async () => {
  const all = await db.collection('content').get();
  console.log(`content docs total: ${all.size}\n`);

  const byType = {};
  for (const doc of all.docs) {
    const d = doc.data();
    const t = d.type || '∅';
    byType[t] = byType[t] || { total: 0, published: 0, publishedWithCreatedAt: 0, samples: [] };
    byType[t].total++;
    if (d.is_published === true) {
      byType[t].published++;
      if (d.created_at !== undefined && d.created_at !== null) byType[t].publishedWithCreatedAt++;
      else byType[t].samples.push(`${doc.id} :: ${(d.title || '').slice(0, 40)} (no created_at)`);
    }
  }

  for (const [type, s] of Object.entries(byType)) {
    console.log(`type=${type}`);
    console.log(`  total=${s.total} published=${s.published} published+created_at=${s.publishedWithCreatedAt}  → APP SEES ${s.publishedWithCreatedAt}`);
    s.samples.slice(0, 5).forEach((x) => console.log(`    dropped: ${x}`));
  }

  // Exactly the app's query for articles
  try {
    const q = await db
      .collection('content')
      .where('type', '==', 'article')
      .where('is_published', '==', true)
      .orderBy('created_at', 'desc')
      .limit(15)
      .get();
    console.log(`\nAPP ARTICLE QUERY returns: ${q.size} docs`);
    q.docs.forEach((d) => console.log(`  ${d.id} :: ${(d.data().title || '').slice(0, 50)}`));
  } catch (e) {
    console.log(`\nAPP ARTICLE QUERY FAILED: ${e.message}`);
  }

  // API key used by the YouTube service
  const keys = await db.collection('api_keys').get();
  console.log(`\napi_keys docs: ${keys.size}`);
  keys.docs.forEach((d) => {
    const data = d.data();
    const k = Object.keys(data);
    console.log(`  ${d.id}: ${k.join(', ')}`);
    if (data.youtube_api_key) console.log(`    youtube_api_key = ${String(data.youtube_api_key).slice(0, 12)}… (len ${String(data.youtube_api_key).length})`);
  });
  process.exit(0);
})();
