'use strict';

/**
 * userBriefing.js — User context fetcher for Sanad AI RAG layer.
 *
 * Firestore field names (confirmed from Flutter models):
 *   users/{userId}: full_name, language, dateOfBirth, crisisMode, subscription_state
 *   users/{userId}/mood_entries: { mood: int 0-5, date: Timestamp, note: string? }
 *   users/{userId}/test_results: { test_type, total_score, interpretation, created_at }
 *   bookings: { client_id, therapist_id, scheduled_time, status, session_type }
 *   users/{userId}/engagement/streak: { current_streak, total_moods_logged }
 *   chat_handoffs: { user_id, ai_summary, risk_level, created_at }
 */

const admin = require('firebase-admin');
const { MOOD_LABELS } = require('./patternAnalyzer');

// ── Mood label localization ────────────────────────────────────────────────────
const MOOD_LABELS_AR = ['سعيد', 'هادئ', 'قلق', 'حزين', 'غاضب', 'متعب'];
const MOOD_LABELS_FR = ['heureux', 'calme', 'anxieux', 'triste', 'en colère', 'fatigué'];

function moodLabel(moodIndex, locale) {
  switch (locale) {
    case 'ar': return MOOD_LABELS_AR[moodIndex] || MOOD_LABELS_AR[0];
    case 'fr': return MOOD_LABELS_FR[moodIndex] || MOOD_LABELS_FR[0];
    default: return MOOD_LABELS[moodIndex] || MOOD_LABELS[0];
  }
}

// ── Age calculation ───────────────────────────────────────────────────────────
function calcAge(dateOfBirth) {
  if (!dateOfBirth) return null;
  const dob = dateOfBirth instanceof admin.firestore.Timestamp
    ? dateOfBirth.toDate()
    : (dateOfBirth instanceof Date ? dateOfBirth : new Date(dateOfBirth));
  const ageDiff = Date.now() - dob.getTime();
  const ageDate = new Date(ageDiff);
  return Math.abs(ageDate.getUTCFullYear() - 1970);
}

// ── Briefing markdown builder ─────────────────────────────────────────────────
function _buildMarkdown(structured, locale) {
  const { user, moodEntries, testResults, bookings, streak, handoffs } = structured;

  const sectionHeader = locale === 'ar' ? '## سياق المستخدم' : locale === 'fr' ? '## Contexte utilisateur' : '## User Context';
  const lines = [sectionHeader];

  // User basics
  if (user.name) lines.push(`- ${locale === 'ar' ? 'الاسم' : 'Name'}: ${user.name}`);
  if (user.age) lines.push(`- ${locale === 'ar' ? 'العمر' : 'Age'}: ${user.age}`);
  if (user.subscription_state) lines.push(`- ${locale === 'ar' ? 'الاشتراك' : 'Subscription'}: ${user.subscription_state}`);
  if (user.crisisMode) lines.push(`- ⚠️ ${locale === 'ar' ? 'وضع الأزمة مفعّل' : 'CRISIS MODE ACTIVE'}`);

  // Recent moods
  if (moodEntries && moodEntries.length > 0) {
    lines.push('');
    lines.push(locale === 'ar' ? '### المزاج الأخير (آخر 30 يوماً)' : '### Recent Moods (last 30 days)');
    for (const e of moodEntries.slice(0, 10)) {
      const label = moodLabel(e.mood, locale);
      const dateStr = e.date instanceof admin.firestore.Timestamp
        ? e.date.toDate().toISOString().split('T')[0]
        : (e.date instanceof Date ? e.date.toISOString().split('T')[0] : String(e.date));
      const notePart = e.note ? ` — ${e.note}` : '';
      lines.push(`- ${dateStr}: ${label}${notePart}`);
    }
  }

  // Test results
  if (testResults && Object.keys(testResults).length > 0) {
    lines.push('');
    lines.push(locale === 'ar' ? '### نتائج الاختبارات النفسية' : '### Psychological Test Results');
    for (const [type, result] of Object.entries(testResults)) {
      lines.push(`- ${type}: score=${result.score}, ${result.interpretation || ''}`);
    }
  }

  // Recent bookings
  if (bookings && bookings.length > 0) {
    lines.push('');
    lines.push(locale === 'ar' ? '### الجلسات الأخيرة' : '### Recent Sessions');
    for (const b of bookings) {
      const dateStr = b.scheduledTime instanceof admin.firestore.Timestamp
        ? b.scheduledTime.toDate().toISOString().split('T')[0]
        : (b.scheduledTime instanceof Date ? b.scheduledTime.toISOString().split('T')[0] : String(b.scheduledTime));
      lines.push(`- ${dateStr}: ${b.status} (${b.sessionType || 'session'})`);
    }
  }

  // Streak
  if (streak) {
    lines.push('');
    lines.push(`- ${locale === 'ar' ? 'السلسلة الحالية' : 'Current Streak'}: ${streak.current_streak || 0} ${locale === 'ar' ? 'يوم' : 'days'}`);
    lines.push(`- ${locale === 'ar' ? 'إجمالي تسجيلات المزاج' : 'Total moods logged'}: ${streak.total_moods_logged || 0}`);
  }

  // Handoff summaries
  if (handoffs && handoffs.length > 0) {
    lines.push('');
    lines.push(locale === 'ar' ? '### سياق المحادثات السابقة' : '### Previous Chat Context');
    for (const h of handoffs) {
      if (h.ai_summary) {
        lines.push(`- ${locale === 'ar' ? 'ملخص' : 'Summary'}: ${h.ai_summary.substring(0, 200)}${h.ai_summary.length > 200 ? '...' : ''}`);
        if (h.risk_level) lines.push(`  ${locale === 'ar' ? 'مستوى الخطر' : 'Risk level'}: ${h.risk_level}`);
      }
    }
  }

  return lines.join('\n');
}

/**
 * Fetch and shape user context data from Firestore.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} userId
 * @param {string} locale - 'ar' | 'en' | 'fr'
 * @returns {Promise<{structured: object, markdown: string}>}
 */
async function buildBriefing(db, userId, locale = 'ar') {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 30);
  const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

  // Parallel fetch of all user data
  const [
    userSnap,
    moodSnap,
    testSnap,
    bookingSnap,
    streakSnap,
    handoffSnap,
  ] = await Promise.all([
    db.collection('users').doc(userId).get(),
    db.collection('users').doc(userId).collection('mood_entries')
      .where('date', '>=', cutoffTs)
      .orderBy('date', 'desc')
      .limit(30)
      .get(),
    db.collection('users').doc(userId).collection('test_results')
      .orderBy('created_at', 'desc')
      .limit(20)
      .get(),
    db.collection('bookings')
      .where('client_id', '==', userId)
      .limit(20) // fetch more, sort client-side — avoids composite index requirement
      .get(),
    db.collection('users').doc(userId).collection('engagement').doc('streak').get(),
    db.collection('chat_handoffs')
      .where('user_id', '==', userId)
      .orderBy('created_at', 'desc')
      .limit(3)
      .get(),
  ]);

  // Shape user data
  const userData = userSnap.exists ? userSnap.data() : {};
  const user = {
    name: userData.full_name || userData.name || null,
    age: calcAge(userData.dateOfBirth),
    language: userData.language || locale,
    crisisMode: userData.crisisMode || false,
    subscription_state: userData.subscription_state || 'free',
  };

  // Shape mood entries
  const moodEntries = moodSnap.docs.map(doc => {
    const d = doc.data();
    return {
      mood: typeof d.mood === 'number' ? d.mood : 0,
      date: d.date,
      note: d.note || null,
    };
  });

  // Shape test results — latest per test type
  const testResults = {};
  for (const doc of testSnap.docs) {
    const d = doc.data();
    const type = d.test_type || 'unknown';
    if (!testResults[type]) {
      testResults[type] = {
        score: d.total_score || 0,
        interpretation: d.interpretation || '',
        date: d.created_at,
      };
    }
  }

  // Shape bookings
  const bookings = bookingSnap.docs.map(doc => {
    const d = doc.data();
    return {
      scheduledTime: d.scheduled_time,
      status: d.status || 'unknown',
      sessionType: d.session_type || null,
      therapistId: d.therapist_id || null,
    };
  });

  // Shape streak
  const streakData = streakSnap.exists ? streakSnap.data() : null;
  const streak = streakData ? {
    current_streak: streakData.current_streak || 0,
    total_moods_logged: streakData.total_moods_logged || 0,
  } : null;

  // Shape handoffs
  const handoffs = handoffSnap.docs.map(doc => {
    const d = doc.data();
    return {
      ai_summary: d.ai_summary || null,
      risk_level: d.risk_level || null,
    };
  });

  const structured = { user, moodEntries, testResults, bookings, streak, handoffs };
  const markdown = _buildMarkdown(structured, locale);

  return { structured, markdown };
}

/**
 * Return cached briefing from Firestore or rebuild if stale.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} userId
 * @param {string} locale
 * @param {number} ttlMs - cache TTL in ms (default 1h)
 * @returns {Promise<{structured: object, markdown: string}>}
 */
async function getCachedBriefing(db, userId, locale = 'ar', ttlMs = 3_600_000) {
  const cacheRef = db.collection('users').doc(userId).collection('ai_context').doc('briefing');
  const cacheSnap = await cacheRef.get();

  if (cacheSnap.exists) {
    const cached = cacheSnap.data();
    const generatedAt = cached.generatedAt instanceof admin.firestore.Timestamp
      ? cached.generatedAt.toDate()
      : new Date(cached.generatedAt);
    // Also invalidate if locale changed
    if (Date.now() - generatedAt.getTime() < ttlMs && cached.locale === locale) {
      return { structured: cached.structured, markdown: cached.markdown };
    }
  }

  const result = await buildBriefing(db, userId, locale);
  await cacheRef.set({
    structured: result.structured,
    markdown: result.markdown,
    locale,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return result;
}

module.exports = { buildBriefing, getCachedBriefing };
