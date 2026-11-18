'use strict';

/**
 * Admin usage insights: which app sections users actually use, how active
 * users are, who is most active, and which feature new users try first.
 *
 * Built only from records the app already writes (no screen tracking exists
 * yet), so article views and the screen-by-screen path are reported as
 * "not tracked" instead of being guessed.
 */

const { AI_PRIVACY_CONSENT_VERSION } = require('./aiPrivacyConsent');

const DAY_MS = 24 * 60 * 60 * 1000;
const RIYADH_OFFSET_MS = 3 * 60 * 60 * 1000;

const SECTIONS = {
  mood: { ar: 'تسجيل المشاعر (المزاج)', en: 'Mood check-in' },
  challenges: { ar: 'التحديات اليومية', en: 'Daily challenges' },
  tests: { ar: 'الاختبارات النفسية', en: 'Psychological tests' },
  aiChat: { ar: 'المحادثة مع الذكاء الاصطناعي', en: 'AI chat' },
  bookings: { ar: 'حجز جلسات مع معالج', en: 'Therapist bookings' },
  therapistChat: { ar: 'المحادثة مع المعالج', en: 'Therapist chat' },
  community: { ar: 'المجتمع', en: 'Community posts' },
  support: { ar: 'الدعم الفني', en: 'Support chat' },
};

const NOT_TRACKED = [
  { key: 'content_views', ar: 'مشاهدات المقالات والتمارين والفيديوهات', en: 'Article / exercise / video views' }, // secret-scan:allow
  { key: 'screen_path', ar: 'مسار التنقل بين الشاشات (أول شاشة يفتحها المستخدم وترتيب الشاشات)', en: 'Screen-by-screen navigation path' }, // secret-scan:allow
];

/** Accepts Firestore Timestamp, Date, millis or ISO string. */
function toMillis(value) {
  if (value == null) return null;
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value.getTime();
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value.toDate === 'function') return value.toDate().getTime();
  if (typeof value === 'string') {
    const t = Date.parse(value);
    return Number.isNaN(t) ? null : t;
  }
  return null;
}

const riyadhDayKey = (ms) => new Date(ms + RIYADH_OFFSET_MS).toISOString().slice(0, 10);
const riyadhHour = (ms) => new Date(ms + RIYADH_OFFSET_MS).getUTCHours();

function displayName(u) {
  const full = [u.first_name, u.last_name].filter(Boolean).join(' ').trim();
  return (u.display_name || u.name || full || u.email || 'مستخدم').toString();
}

/**
 * Pure aggregation.
 *
 * @param {object} input
 * @param {Array<{id:string,data:object}>} input.users
 * @param {Array<{section:string,uid:string,at:any,weight?:number,hourly?:boolean}>} input.events
 *   One entry per recorded action. `weight` (default 1) counts messages for
 *   chat threads; `hourly:false` excludes thread-level timestamps from peak
 *   hours because they only reflect the latest message.
 * @param {number} input.now millis
 * @param {number} [input.windowDays=30]
 * @param {number} [input.topN=10]
 */
function computeUsageInsights({ users, events, now, windowDays = 30, topN = 10 }) {
  const since = now - windowDays * DAY_MS;
  const userById = new Map(users.map((u) => [u.id, u.data || {}]));

  // ── Active users from presence fields ──────────────────────────────────
  const lastSeenById = new Map();
  let active1 = 0;
  let active7 = 0;
  let active30 = 0;
  let newUsers = 0;
  for (const { id, data } of users) {
    const seen = Math.max(toMillis(data.last_seen) || 0, toMillis(data.last_login) || 0) || null;
    if (seen) lastSeenById.set(id, seen);
    if (seen && seen >= now - DAY_MS) active1++;
    if (seen && seen >= now - 7 * DAY_MS) active7++;
    if (seen && seen >= since) active30++;
    const created = toMillis(data.created_at);
    if (created && created >= since) newUsers++;
  }

  // ── Per-section usage, per-user activity, first feature, peak hours ────
  const section = {};
  for (const key of Object.keys(SECTIONS)) {
    section[key] = { events: 0, eventsAllTime: 0, users: new Set(), usersAllTime: new Set() };
  }
  const perUser = new Map(); // uid -> { days:Set, bySection:{}, events }
  const firstEvent = new Map(); // uid -> { at, section }
  const hours = new Array(24).fill(0);
  const weekdays = new Array(7).fill(0);
  const seenHourSlots = new Set();
  const seenDaySlots = new Set();

  for (const ev of events) {
    const s = section[ev.section];
    const at = toMillis(ev.at);
    if (!s || !ev.uid || !at || at > now + DAY_MS) continue;
    const weight = Math.max(1, Number(ev.weight) || 1);

    s.eventsAllTime += weight;
    s.usersAllTime.add(ev.uid);
    const first = firstEvent.get(ev.uid);
    if (!first || at < first.at) firstEvent.set(ev.uid, { at, section: ev.section });

    if (at < since) continue;
    s.events += weight;
    s.users.add(ev.uid);

    let u = perUser.get(ev.uid);
    if (!u) {
      u = { days: new Set(), bySection: {}, events: 0 };
      perUser.set(ev.uid, u);
    }
    u.days.add(riyadhDayKey(at));
    u.bySection[ev.section] = (u.bySection[ev.section] || 0) + weight;
    u.events += weight;

    if (ev.hourly !== false) {
      // One count per user per hour slot / per day, so a few heavy chatters
      // can't dominate the "when are people active" answer.
      const day = riyadhDayKey(at);
      const hourKey = `${ev.uid}|${day}|${riyadhHour(at)}`;
      if (!seenHourSlots.has(hourKey)) {
        seenHourSlots.add(hourKey);
        hours[riyadhHour(at)]++;
      }
      const dayKey = `${ev.uid}|${day}`;
      if (!seenDaySlots.has(dayKey)) {
        seenDaySlots.add(dayKey);
        weekdays[new Date(at + RIYADH_OFFSET_MS).getUTCDay()]++;
      }
    }
  }

  const sections = Object.entries(section)
    .map(([key, s]) => ({
      key,
      labelAr: SECTIONS[key].ar,
      labelEn: SECTIONS[key].en,
      events: s.events,
      uniqueUsers: s.users.size,
      eventsAllTime: s.eventsAllTime,
      uniqueUsersAllTime: s.usersAllTime.size,
    }))
    .sort((a, b) => b.uniqueUsers - a.uniqueUsers || b.events - a.events);

  // Presence counts as an active day too, so someone who only browses still ranks.
  for (const [uid, seen] of lastSeenById) {
    if (seen < since) continue;
    let u = perUser.get(uid);
    if (!u) {
      u = { days: new Set(), bySection: {}, events: 0 };
      perUser.set(uid, u);
    }
    u.days.add(riyadhDayKey(seen));
  }

  const topUsers = [...perUser.entries()]
    .filter(([uid]) => userById.has(uid) && (userById.get(uid).role || 'user') === 'user')
    .map(([uid, u]) => {
      const data = userById.get(uid);
      const consent = data.ai_privacy_consent;
      return {
        uid,
        name: displayName(data),
        activeDays: u.days.size,
        events: u.events,
        bySection: u.bySection,
        lastSeen: lastSeenById.has(uid) ? new Date(lastSeenById.get(uid)).toISOString() : null,
        aiConsent: consent?.accepted === true && consent.version === AI_PRIVACY_CONSENT_VERSION,
      };
    })
    .sort((a, b) => b.activeDays - a.activeDays || b.events - a.events || (b.lastSeen || '').localeCompare(a.lastSeen || ''))
    .slice(0, topN);

  const isPatient = (uid) => userById.has(uid) && (userById.get(uid).role || 'user') === 'user';
  const firstFeatureCounts = {};
  for (const [uid, { section: key }] of firstEvent) {
    if (!isPatient(uid)) continue;
    firstFeatureCounts[key] = (firstFeatureCounts[key] || 0) + 1;
  }
  const firstFeature = Object.entries(firstFeatureCounts)
    .map(([key, usersCount]) => ({ key, labelAr: SECTIONS[key].ar, labelEn: SECTIONS[key].en, users: usersCount }))
    .sort((a, b) => b.users - a.users);

  const peakHours = hours
    .map((count, hour) => ({ hour, count }))
    .filter((h) => h.count > 0)
    .sort((a, b) => b.count - a.count)
    .slice(0, 3);
  const weekdayNamesAr = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
  const busiestWeekdays = weekdays
    .map((count, day) => ({ day, labelAr: weekdayNamesAr[day], count }))
    .filter((d) => d.count > 0)
    .sort((a, b) => b.count - a.count)
    .slice(0, 3);

  return {
    generatedAt: new Date(now).toISOString(),
    windowDays,
    totals: { users: users.length, active1d: active1, active7d: active7, active30d: active30, newUsers },
    sections,
    topUsers,
    firstFeature,
    peakHours,
    busiestWeekdays,
    timezone: 'Asia/Riyadh',
    notTracked: NOT_TRACKED,
  };
}

/** Reads the existing collections and flattens them into events. */
async function loadUsageInsights(db, { now = Date.now(), windowDays = 30, topN = 10 } = {}) {
  const parentUid = (doc) => doc.ref.parent.parent && doc.ref.parent.parent.id;
  const [usersSnap, moodSnap, challengeSnap, testSnap, aiSnap, bookingSnap, therapistSnap, postSnap, messageSnap] =
    await Promise.all([
      db.collection('users').select('created_at', 'last_seen', 'last_login', 'role', 'display_name', 'name', 'first_name', 'last_name', 'email', 'ai_privacy_consent').get(),
      db.collectionGroup('mood_entries').select('date').get(),
      db.collectionGroup('challenge_completions').select('completed_at').get(),
      db.collectionGroup('test_results').select('created_at').get(),
      db.collection('ai_chats').select('user_id', 'created_at', 'updated_at', 'message_count').get(),
      db.collection('bookings').select('client_id', 'created_at').get(),
      db.collection('therapist_chats').select('user_id').get(),
      db.collection('posts').select('author_id', 'created_at').get(),
      // Support + therapist chat messages. Only messages the user wrote count:
      // support threads also hold admin broadcasts and welcome messages.
      db.collectionGroup('messages').select('sender_id', 'timestamp').get(),
    ]);

  const events = [];
  moodSnap.docs.forEach((d) => events.push({ section: 'mood', uid: parentUid(d), at: d.get('date') }));
  challengeSnap.docs.forEach((d) => events.push({ section: 'challenges', uid: parentUid(d), at: d.get('completed_at') }));
  testSnap.docs.forEach((d) => events.push({ section: 'tests', uid: parentUid(d), at: d.get('created_at') }));
  aiSnap.docs.forEach((d) => {
    const uid = d.get('user_id');
    events.push({ section: 'aiChat', uid, at: d.get('created_at') });
    // Thread-level activity: latest message time, weighted by message count.
    const updated = d.get('updated_at');
    if (toMillis(updated) !== toMillis(d.get('created_at'))) {
      events.push({ section: 'aiChat', uid, at: updated, weight: Math.max(0, (Number(d.get('message_count')) || 1) - 1), hourly: false });
    }
  });
  bookingSnap.docs.forEach((d) => events.push({ section: 'bookings', uid: d.get('client_id'), at: d.get('created_at') }));
  postSnap.docs.forEach((d) => events.push({ section: 'community', uid: d.get('author_id'), at: d.get('created_at') }));

  const therapistChatUser = new Map(therapistSnap.docs.map((d) => [d.id, d.get('user_id')]));
  messageSnap.docs.forEach((d) => {
    const chat = d.ref.parent.parent;
    if (!chat) return;
    const sender = d.get('sender_id');
    if (chat.parent.id === 'support_chats' && sender === chat.id) {
      events.push({ section: 'support', uid: sender, at: d.get('timestamp') });
    } else if (chat.parent.id === 'therapist_chats' && sender && sender === therapistChatUser.get(chat.id)) {
      events.push({ section: 'therapistChat', uid: sender, at: d.get('timestamp') });
    }
  });

  return computeUsageInsights({
    users: usersSnap.docs.map((d) => ({ id: d.id, data: d.data() })),
    events,
    now,
    windowDays,
    topN,
  });
}

module.exports = { computeUsageInsights, loadUsageInsights, toMillis, SECTIONS, NOT_TRACKED };
