#!/usr/bin/env node
// Seeds 14 days of mood entries for the App Store screenshot demo account so the
// mood tracker and insights screens are not empty. Idempotent (fixed doc ids).
// Only happy / calm / tired moods, so admin mood and risk alerts never fire for it.
//
// Usage: NODE_PATH=functions/node_modules node scripts/seed-screenshot-demo-moods.js

const admin = require('firebase-admin');
admin.initializeApp({ projectId: 'sanad-app-beldify' });
const db = admin.firestore();

const UID = '1SAOiseJURZJmuEyu3tcQWiEMpx1'; // screenshots.demo@sanadtherapy.com
const MOOD = { happy: 0, calm: 1, tired: 5 }; // MoodType enum index in lib/features/mood/models/mood_enums.dart
const PLAN = ['tired', 'calm', 'tired', 'calm', 'happy', 'calm', 'tired', 'calm', 'happy', 'calm', 'happy', 'happy', 'calm', 'happy'];
const HOURS = [9, 20, 13, 21, 10, 19, 8, 22, 12, 18, 9, 20, 11, 19];

(async () => {
  const user = await db.collection('users').doc(UID).get();
  if (!user.exists || user.data().is_demo !== true) throw new Error('demo user missing or not is_demo');
  const batch = db.batch();
  const today = new Date();
  PLAN.forEach((m, i) => {
    const daysAgo = PLAN.length - 1 - i;
    const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() - daysAgo, HOURS[i], 15);
    const id = `demo_${d.toISOString().slice(0, 10)}`;
    batch.set(db.collection('users').doc(UID).collection('mood_entries').doc(id), {
      mood: MOOD[m],
      date: admin.firestore.Timestamp.fromDate(d),
      note: null,
    });
  });
  await batch.commit();
  const n = (await db.collection('users').doc(UID).collection('mood_entries').get()).size;
  console.log(`mood_entries for demo user: ${n}`);
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
