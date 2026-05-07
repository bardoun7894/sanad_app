'use strict';

/**
 * patternAnalyzer.js — Mood pattern analysis for Sanad AI RAG layer.
 *
 * Firestore schema (confirmed from Flutter models):
 *   users/{userId}/mood_entries: { mood: int 0-5, date: Timestamp, note: string? }
 *   Mood scale: 0=happy, 1=calm, 2=anxious, 3=sad, 4=angry, 5=tired
 *
 * Risk score ported from lib/features/admin/providers/risk_alerts_provider.dart:
 *   _moodToScore and _scoreToRiskLevel (M6.4, aligned with Laravel RiskAlertService)
 */

const admin = require('firebase-admin');

// ── Mood labels (index → label) ───────────────────────────────────────────────
const MOOD_LABELS = ['happy', 'calm', 'anxious', 'sad', 'angry', 'tired'];

// ── Low mood set (for lowStreak and weekend dip) ──────────────────────────────
const LOW_MOOD_INDICES = new Set([3, 4, 5]); // sad, angry, tired

// ── Keyword buckets ───────────────────────────────────────────────────────────
// Arabic + English keywords per theme bucket
const THEME_KEYWORDS = {
  sleep: ['sleep', 'tired', 'insomnia', 'awake', 'rest', 'nap', 'نوم', 'أرق', 'تعب', 'نعاس', 'راحة', 'أنام', 'أنم', 'نايم', 'صحيت'],
  work: ['work', 'job', 'office', 'boss', 'career', 'deadline', 'عمل', 'شغل', 'وظيفة', 'مدير', 'مهنة'],
  relationships: ['partner', 'wife', 'husband', 'girlfriend', 'boyfriend', 'relationship', 'breakup', 'زوجة', 'زوج', 'حبيب', 'حبيبة', 'علاقة'],
  health: ['pain', 'sick', 'ill', 'hospital', 'doctor', 'medicine', 'headache', 'مرض', 'ألم', 'وجع', 'مستشفى', 'دكتور', 'صحة'],
  family: ['mom', 'dad', 'mother', 'father', 'sister', 'brother', 'family', 'parents', 'أم', 'أب', 'أخت', 'أخ', 'عائلة', 'والد', 'والدة'],
  money: ['money', 'debt', 'loan', 'financial', 'bills', 'broke', 'salary', 'مال', 'دين', 'ديون', 'قرض', 'راتب', 'مصاريف'],
};

// ── Sentiment word lists (AR + EN + FR) ──────────────────────────────────────
// Positive words
const POSITIVE_WORDS = [
  // Arabic
  'سعيد', 'جميل', 'تحسن', 'ممتاز', 'رائع', 'فرح', 'سعادة', 'مبسوط',
  // English
  'happy', 'good', 'better', 'grateful', 'joy', 'great', 'wonderful', 'positive',
  // French
  'heureux', 'heureuse', 'bien', 'mieux', 'content', 'contentе', 'joyeux',
];
// Negative words
const NEGATIVE_WORDS = [
  // Arabic
  'حزين', 'خائف', 'قلق', 'تعب', 'ضيق', 'مكتئب', 'أسوأ',
  // English
  'sad', 'tired', 'anxious', 'anxious', 'worse', 'depressed', 'fear', 'scared', 'angry',
  // French
  'triste', 'fatigué', 'fatiguée', 'anxieux', 'anxieuse', 'peur', 'malheureux',
];

// ── Day-of-week labels ────────────────────────────────────────────────────────
const DOW_LABELS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

// ── Pure helper functions (exported for testing) ──────────────────────────────

/**
 * Convert mood index (0-5) to numeric score (higher = better).
 * Mirrors _moodToScore in risk_alerts_provider.dart (M6.4).
 */
function moodToScore(moodIndex) {
  switch (moodIndex) {
    case 0: return 5; // happy
    case 1: return 4; // calm
    case 2: return 2; // anxious
    case 3: return 1; // sad
    case 4: return 1; // angry
    case 5: return 2; // tired
    default: return 3; // unknown / out-of-range
  }
}

/**
 * Determine risk level from avg score and trend.
 * Mirrors _scoreToRiskLevel in risk_alerts_provider.dart (M6.4).
 */
function scoreToRiskLevel(avgScore, trend) {
  if (avgScore < 2.0 || trend < -2.0) return 'critical';
  if (avgScore < 2.5 || trend < -1.5) return 'high';
  if (avgScore < 3.0 || trend < -1.0) return 'moderate';
  return 'low';
}

/**
 * Calculate trend from an array of numeric scores (newest-first order).
 * trend = avgLast(older half) - avgFirst(newer half)
 * Positive → declining (older scores were better than newer)
 * Negative → improving (newer scores are better than older)
 * Mirrors the Flutter risk_alerts_provider logic.
 *
 * @param {number[]} scores - Numeric scores newest-first.
 * @returns {'improving'|'declining'|'stable'}
 */
function calcTrend(scores) {
  if (!scores || scores.length < 4) return 'stable';
  const halfLen = Math.floor(scores.length / 2);
  const newerHalf = scores.slice(0, halfLen);
  const olderHalf = scores.slice(halfLen);
  const avgFirst = newerHalf.reduce((a, b) => a + b, 0) / newerHalf.length;
  const avgLast = olderHalf.reduce((a, b) => a + b, 0) / olderHalf.length;
  const trend = avgLast - avgFirst;
  if (trend > 0.5) return 'declining';   // older was better → getting worse
  if (trend < -0.5) return 'improving';  // older was worse → getting better
  return 'stable';
}

/**
 * Find the most frequent mood index in an array.
 * @param {number[]} moodIndices
 * @returns {string|null} mood label or null if empty
 */
function calcDominantMood(moodIndices) {
  if (!moodIndices || moodIndices.length === 0) return null;
  const counts = {};
  for (const idx of moodIndices) {
    counts[idx] = (counts[idx] || 0) + 1;
  }
  const maxIdx = Object.keys(counts).reduce((a, b) => counts[a] > counts[b] ? a : b);
  return MOOD_LABELS[parseInt(maxIdx, 10)] || null;
}

/**
 * Count consecutive low-mood days from the most recent entry.
 * Low moods: sad(3), angry(4), tired(5).
 * @param {number[]} moodIndices - newest-first
 * @returns {number}
 */
function calcLowStreak(moodIndices) {
  if (!moodIndices || moodIndices.length === 0) return 0;
  let streak = 0;
  for (const idx of moodIndices) {
    if (LOW_MOOD_INDICES.has(idx)) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

/**
 * Check whether average weekend mood score is worse than weekday by >= 1.
 * @param {{date: Date, moodIndex: number}[]} entries
 * @returns {boolean}
 */
function calcWeekendDip(entries) {
  if (!entries || entries.length === 0) return false;
  const weekdayScores = [];
  const weekendScores = [];
  for (const e of entries) {
    const day = e.date.getDay(); // 0=Sun, 6=Sat
    const score = moodToScore(e.moodIndex);
    if (day === 0 || day === 6) {
      weekendScores.push(score);
    } else {
      weekdayScores.push(score);
    }
  }
  if (weekdayScores.length === 0 || weekendScores.length === 0) return false;
  const avgWeekday = weekdayScores.reduce((a, b) => a + b, 0) / weekdayScores.length;
  const avgWeekend = weekendScores.reduce((a, b) => a + b, 0) / weekendScores.length;
  return (avgWeekday - avgWeekend) >= 1;
}

/**
 * Keyword-based note theme extraction. Returns deduped array of bucket names.
 * @param {(string|null|undefined)[]} notes
 * @returns {string[]}
 */
function extractNoteThemes(notes) {
  if (!notes || notes.length === 0) return [];
  const combined = notes
    .filter(n => n && typeof n === 'string')
    .join(' ')
    .toLowerCase();
  if (!combined.trim()) return [];
  const fired = [];
  for (const [bucket, keywords] of Object.entries(THEME_KEYWORDS)) {
    if (keywords.some(kw => combined.includes(kw.toLowerCase()))) {
      fired.push(bucket);
    }
  }
  return fired;
}

// ── New pure helpers for extended pattern fields ──────────────────────────────

/**
 * Return the time-of-day bucket name for a UTC hour (0–23).
 * Buckets: morning 5–12, afternoon 12–17, evening 17–22, night 22–5 (inclusive starts).
 *
 * All timestamps are treated as UTC — do not convert to server local time.
 *
 * @param {number} utcHour
 * @returns {'morning'|'afternoon'|'evening'|'night'}
 */
function bucketTimeOfDay(utcHour) {
  if (utcHour >= 5 && utcHour < 12) return 'morning';
  if (utcHour >= 12 && utcHour < 17) return 'afternoon';
  if (utcHour >= 17 && utcHour < 22) return 'evening';
  return 'night'; // 22–23 and 0–4
}

/**
 * Return the day-of-week label from a JS Date.getDay() value (0=Sun … 6=Sat).
 * @param {number} dayOfWeek - 0-6
 * @returns {string} e.g. 'mon', 'sun', 'sat'
 */
function bucketDayOfWeek(dayOfWeek) {
  return DOW_LABELS[dayOfWeek] || 'sun';
}

/**
 * Compute simple linear regression slope for a values array.
 * x is implicitly [0, 1, 2, …, n-1].
 * Returns 0 for arrays with < 2 elements.
 *
 * @param {number[]} values
 * @returns {number}
 */
function linearRegressionSlope(values) {
  if (!values || values.length < 2) return 0;
  const n = values.length;
  let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
  for (let i = 0; i < n; i++) {
    sumX += i;
    sumY += values[i];
    sumXY += i * values[i];
    sumX2 += i * i;
  }
  const denom = n * sumX2 - sumX * sumX;
  if (denom === 0) return 0;
  return (n * sumXY - sumX * sumY) / denom;
}

/**
 * Compute the maximum consecutive days without a mood entry in the range.
 * All dates are compared at day granularity (UTC).
 *
 * @param {Date[]} entryDates - Unique entry dates (order does not matter)
 * @param {Date} rangeEnd - The end of the analysis window (usually "now")
 * @param {number} rangeDays - Number of days in the window
 * @returns {number} max gap in days
 */
function calcMaxLoggingGap(entryDates, rangeEnd, rangeDays) {
  if (!entryDates || entryDates.length === 0) return rangeDays;

  // Build a set of ISO date strings that have at least one entry
  const entrySet = new Set(
    entryDates.map(d => {
      const dt = new Date(d);
      return `${dt.getUTCFullYear()}-${dt.getUTCMonth()}-${dt.getUTCDate()}`;
    })
  );

  let maxGap = 0;
  let currentGap = 0;
  const end = new Date(rangeEnd);

  for (let i = rangeDays - 1; i >= 0; i--) {
    const dt = new Date(end);
    dt.setUTCDate(dt.getUTCDate() - i);
    const key = `${dt.getUTCFullYear()}-${dt.getUTCMonth()}-${dt.getUTCDate()}`;
    if (entrySet.has(key)) {
      currentGap = 0;
    } else {
      currentGap++;
      if (currentGap > maxGap) maxGap = currentGap;
    }
  }
  return maxGap;
}

/**
 * Count positive and negative sentiment word occurrences across notes.
 * Each keyword match in a note increments the counter independently.
 * Null/undefined/empty notes are skipped.
 *
 * @param {(string|null|undefined)[]} notes
 * @returns {{ positive: number, negative: number }}
 */
function countNoteSentiment(notes) {
  let positive = 0;
  let negative = 0;
  if (!notes || notes.length === 0) return { positive, negative };

  for (const note of notes) {
    if (!note || typeof note !== 'string') continue;
    const lower = note.toLowerCase();
    for (const w of POSITIVE_WORDS) {
      if (lower.includes(w.toLowerCase())) positive++;
    }
    for (const w of NEGATIVE_WORDS) {
      if (lower.includes(w.toLowerCase())) negative++;
    }
  }
  return { positive, negative };
}

// ── Firestore-backed functions ────────────────────────────────────────────────

/**
 * Build a map of moodScore keyed by UTC date string (YYYY-MM-DD) from mood entries.
 * Used by bookingImpact and contentEngagement calculations.
 * @param {{date: Date, moodIndex: number}[]} entries
 * @returns {Map<string, number[]>} date → array of mood scores that day
 */
function _buildDayScoreMap(entries) {
  const map = new Map();
  for (const e of entries) {
    const key = e.date.toISOString().split('T')[0]; // YYYY-MM-DD UTC
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(moodToScore(e.moodIndex));
  }
  return map;
}

/**
 * Compute average mood score for a set of date strings from the day score map.
 * Returns null if no data.
 * @param {Map<string, number[]>} dayScoreMap
 * @param {string[]} dateKeys - YYYY-MM-DD strings
 * @returns {number|null}
 */
function _avgScoreForDates(dayScoreMap, dateKeys) {
  const all = [];
  for (const key of dateKeys) {
    const scores = dayScoreMap.get(key);
    if (scores) all.push(...scores);
  }
  if (all.length === 0) return null;
  return all.reduce((a, b) => a + b, 0) / all.length;
}

/**
 * Generate date strings for a window around a given date.
 * @param {Date} refDate
 * @param {number} offsetDays - negative = before, positive = after
 * @param {number} windowSize - number of days
 * @returns {string[]}
 */
function _dateWindow(refDate, offsetDays, windowSize) {
  const keys = [];
  for (let i = 0; i < windowSize; i++) {
    const dt = new Date(refDate);
    dt.setUTCDate(dt.getUTCDate() + offsetDays + i);
    keys.push(dt.toISOString().split('T')[0]);
  }
  return keys;
}

/**
 * Analyze mood patterns for a user.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} userId
 * @param {number} rangeDays
 * @returns {Promise<object>} Extended pattern object with all fields.
 */
async function analyze(db, userId, rangeDays = 30) {
  const now = new Date();
  const cutoff = new Date(now);
  cutoff.setDate(cutoff.getDate() - rangeDays);
  const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

  // Fetch mood entries, test_results, bookings, activity_logs in parallel
  const [moodSnap, testSnap, bookingSnap, activitySnap] = await Promise.all([
    db.collection('users').doc(userId).collection('mood_entries')
      .where('date', '>=', cutoffTs)
      .orderBy('date', 'desc')
      .get(),
    db.collection('users').doc(userId).collection('test_results')
      .where('completedAt', '>=', cutoffTs)
      .orderBy('completedAt', 'desc')
      .get().catch(() => ({ docs: [] })), // defensive: ignore if missing
    db.collection('bookings')
      .where('client_id', '==', userId)
      .where('status', '==', 'completed')
      .where('scheduled_time', '>=', cutoffTs)
      .orderBy('scheduled_time', 'desc')
      .get().catch(() => ({ docs: [] })),
    db.collection('activity_logs')
      .where('user_id', '==', userId)
      .where('timestamp', '>=', cutoffTs)
      .orderBy('timestamp', 'desc')
      .get().catch(() => ({ docs: [] })),
  ]);

  const entries = moodSnap.docs.map(doc => {
    const d = doc.data();
    return {
      moodIndex: typeof d.mood === 'number' ? d.mood : 0,
      date: d.date instanceof admin.firestore.Timestamp ? d.date.toDate() : new Date(d.date),
      note: d.note || null,
    };
  });

  // Empty entries base case — still compute what we can
  const emptyBase = {
    trend: 'stable',
    dominantMood: null,
    lowStreak: 0,
    weekendDip: false,
    noteThemes: [],
    anomalies: [],
    riskLevel: 'low',
    // New fields
    timeOfDay: { morning: null, afternoon: null, evening: null, night: null },
    dayOfWeek: { mon: null, tue: null, wed: null, thu: null, fri: null, sat: null, sun: null },
    testTrajectory: [],
    bookingImpact: null,
    contentEngagement: null,
    loggingGap: rangeDays,
    noteSentiment: { positive: 0, negative: 0 },
  };

  if (entries.length === 0) {
    return emptyBase;
  }

  const moodIndices = entries.map(e => e.moodIndex);
  const scores = moodIndices.map(moodToScore);

  const trend = calcTrend(scores);
  const dominantMood = calcDominantMood(moodIndices);
  const lowStreak = calcLowStreak(moodIndices);
  const weekendDip = calcWeekendDip(entries);
  const noteThemes = extractNoteThemes(entries.map(e => e.note));

  // Anomalies: missing > 5 consecutive days or sudden spike to lowest mood
  const anomalies = [];
  for (let i = 0; i < entries.length - 1; i++) {
    const diffMs = entries[i].date - entries[i + 1].date;
    const diffDays = diffMs / (1000 * 60 * 60 * 24);
    if (diffDays > 5) {
      anomalies.push(`gap_${Math.floor(diffDays)}_days`);
      break;
    }
  }
  if (scores.length >= 2 && scores[0] === 1 && scores[1] >= 4) {
    anomalies.push('sudden_low_spike');
  }

  const avgScore = scores.reduce((a, b) => a + b, 0) / scores.length;
  const halfLen = Math.floor(scores.length / 2);
  const avgFirst = scores.slice(0, halfLen).reduce((a, b) => a + b, 0) / halfLen;
  const avgLast = scores.slice(halfLen).reduce((a, b) => a + b, 0) / (scores.length - halfLen);
  const trendValue = avgLast - avgFirst;
  const riskLevel = scoreToRiskLevel(avgScore, trendValue);

  // ── NEW FIELD: timeOfDay ─────────────────────────────────────────────────────
  // Bucket entries by UTC hour; compute avg mood score per bucket.
  const todBuckets = { morning: [], afternoon: [], evening: [], night: [] };
  for (const e of entries) {
    const bucket = bucketTimeOfDay(e.date.getUTCHours());
    todBuckets[bucket].push(moodToScore(e.moodIndex));
  }
  const timeOfDay = {};
  for (const [bucket, arr] of Object.entries(todBuckets)) {
    timeOfDay[bucket] = arr.length > 0
      ? arr.reduce((a, b) => a + b, 0) / arr.length
      : null;
  }

  // ── NEW FIELD: dayOfWeek ─────────────────────────────────────────────────────
  const dowBuckets = { sun: [], mon: [], tue: [], wed: [], thu: [], fri: [], sat: [] };
  for (const e of entries) {
    const dow = bucketDayOfWeek(e.date.getUTCDay());
    dowBuckets[dow].push(moodToScore(e.moodIndex));
  }
  const dayOfWeek = {};
  for (const [dow, arr] of Object.entries(dowBuckets)) {
    dayOfWeek[dow] = arr.length > 0
      ? arr.reduce((a, b) => a + b, 0) / arr.length
      : null;
  }

  // ── NEW FIELD: testTrajectory ────────────────────────────────────────────────
  // Group test_results by testType, compute slope on last 5 results.
  const testTrajectory = [];
  if (testSnap.docs.length > 0) {
    const byType = {};
    for (const doc of testSnap.docs) {
      const d = doc.data();
      const testType = d.testType || d.type || 'unknown';
      const score = typeof d.totalScore === 'number' ? d.totalScore : null;
      const completedAt = d.completedAt instanceof admin.firestore.Timestamp
        ? d.completedAt.toDate()
        : (d.completedAt ? new Date(d.completedAt) : null);
      if (score === null || completedAt === null) continue;
      if (!byType[testType]) byType[testType] = [];
      byType[testType].push({ score, completedAt });
    }
    for (const [testType, results] of Object.entries(byType)) {
      if (results.length < 2) continue;
      // Sort oldest-first for slope computation
      results.sort((a, b) => a.completedAt - b.completedAt);
      const last5 = results.slice(-5);
      const lastScore = last5[last5.length - 1].score;
      const slopeVal = linearRegressionSlope(last5.map(r => r.score));
      let direction;
      if (slopeVal > 0.5) direction = 'improving';
      else if (slopeVal < -0.5) direction = 'declining';
      else direction = 'stable';
      testTrajectory.push({ testType, lastScore, slope: slopeVal, direction });
    }
  }

  // ── NEW FIELD: bookingImpact ─────────────────────────────────────────────────
  // Compare avg mood 3 days before vs 3 days after completed bookings.
  let bookingImpact = null;
  if (bookingSnap.docs.length > 0) {
    const dayScoreMap = _buildDayScoreMap(entries);
    const beforeScores = [];
    const afterScores = [];
    for (const doc of bookingSnap.docs) {
      const d = doc.data();
      const scheduledTime = d.scheduled_time instanceof admin.firestore.Timestamp
        ? d.scheduled_time.toDate()
        : (d.scheduled_time ? new Date(d.scheduled_time) : null);
      if (!scheduledTime) continue;

      // 3 days before: offsets -3, -2, -1
      const beforeKeys = _dateWindow(scheduledTime, -3, 3);
      // 3 days after: offsets 1, 2, 3
      const afterKeys = _dateWindow(scheduledTime, 1, 3);

      const bAvg = _avgScoreForDates(dayScoreMap, beforeKeys);
      const aAvg = _avgScoreForDates(dayScoreMap, afterKeys);
      if (bAvg !== null) beforeScores.push(bAvg);
      if (aAvg !== null) afterScores.push(aAvg);
    }
    if (beforeScores.length > 0 && afterScores.length > 0) {
      const before = beforeScores.reduce((a, b) => a + b, 0) / beforeScores.length;
      const after = afterScores.reduce((a, b) => a + b, 0) / afterScores.length;
      bookingImpact = {
        before,
        after,
        deltaMoodInt: after - before,
        sampleSize: Math.min(beforeScores.length, afterScores.length),
      };
    }
  }

  // ── NEW FIELD: contentEngagement ─────────────────────────────────────────────
  // Compare avg mood on day-after engagement events vs days without engagement.
  let contentEngagement = null;
  const ENGAGEMENT_TYPES = new Set(['exerciseCompleted', 'challengeCompleted', 'articleRead']);
  if (activitySnap.docs.length > 0) {
    const engagementDays = new Set(); // days with content engagement activity
    for (const doc of activitySnap.docs) {
      const d = doc.data();
      const aType = d.type || d.activityType || '';
      if (!ENGAGEMENT_TYPES.has(aType)) continue;
      const ts = d.timestamp instanceof admin.firestore.Timestamp
        ? d.timestamp.toDate()
        : (d.timestamp ? new Date(d.timestamp) : null);
      if (!ts) continue;
      engagementDays.add(ts.toISOString().split('T')[0]);
    }
    if (engagementDays.size > 0) {
      const dayScoreMap = _buildDayScoreMap(entries);
      const withEngagementScores = [];
      const withoutEngagementScores = [];

      for (const [dayKey, dayScores] of dayScoreMap.entries()) {
        // Was the previous day an engagement day?
        const prevDate = new Date(dayKey + 'T00:00:00Z');
        prevDate.setUTCDate(prevDate.getUTCDate() - 1);
        const prevKey = prevDate.toISOString().split('T')[0];
        const avgDay = dayScores.reduce((a, b) => a + b, 0) / dayScores.length;
        if (engagementDays.has(prevKey)) {
          withEngagementScores.push(avgDay);
        } else {
          withoutEngagementScores.push(avgDay);
        }
      }
      if (withEngagementScores.length > 0 && withoutEngagementScores.length > 0) {
        contentEngagement = {
          withEngagement: withEngagementScores.reduce((a, b) => a + b, 0) / withEngagementScores.length,
          withoutEngagement: withoutEngagementScores.reduce((a, b) => a + b, 0) / withoutEngagementScores.length,
          sampleSize: withEngagementScores.length,
        };
      }
    }
  }

  // ── NEW FIELD: loggingGap ────────────────────────────────────────────────────
  const loggingGap = calcMaxLoggingGap(entries.map(e => e.date), now, rangeDays);

  // ── NEW FIELD: noteSentiment ─────────────────────────────────────────────────
  const noteSentiment = countNoteSentiment(entries.map(e => e.note));

  return {
    trend,
    dominantMood,
    lowStreak,
    weekendDip,
    noteThemes,
    anomalies,
    riskLevel,
    // Extended fields
    timeOfDay,
    dayOfWeek,
    testTrajectory,
    bookingImpact,
    contentEngagement,
    loggingGap,
    noteSentiment,
  };
}

/**
 * Return cached patterns from Firestore or rebuild if stale.
 *
 * @param {FirebaseFirestore.Firestore} db
 * @param {string} userId
 * @param {number} ttlMs - cache TTL in ms (default 6h)
 * @returns {Promise<object>}
 */
async function getCachedPatterns(db, userId, ttlMs = 6 * 3600 * 1000) {
  const cacheRef = db.collection('users').doc(userId).collection('ai_context').doc('patterns');
  const cacheSnap = await cacheRef.get();

  if (cacheSnap.exists) {
    const cached = cacheSnap.data();
    const generatedAt = cached.generatedAt instanceof admin.firestore.Timestamp
      ? cached.generatedAt.toDate()
      : new Date(cached.generatedAt);
    if (Date.now() - generatedAt.getTime() < ttlMs) {
      return cached.data;
    }
  }

  const result = await analyze(db, userId);
  await cacheRef.set({
    data: result,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return result;
}

module.exports = {
  // Pure helpers (exported for testing)
  MOOD_LABELS,
  moodToScore,
  scoreToRiskLevel,
  calcTrend,
  calcDominantMood,
  calcLowStreak,
  calcWeekendDip,
  extractNoteThemes,
  // New pure helpers for extended fields (exported for testing)
  bucketTimeOfDay,
  bucketDayOfWeek,
  linearRegressionSlope,
  calcMaxLoggingGap,
  countNoteSentiment,
  // Firestore functions
  analyze,
  getCachedPatterns,
};
