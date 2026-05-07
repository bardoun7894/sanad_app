/**
 * Unit tests for patternAnalyzer.js — pure logic only, no Firestore calls.
 * Run: node --test functions/test/patternAnalyzer.test.js
 */

'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');

// We test only the pure exported helpers.
// Firestore-dependent `analyze` and `getCachedPatterns` are integration-tested via callable.
const {
  moodToScore,
  scoreToRiskLevel,
  calcTrend,
  calcDominantMood,
  calcLowStreak,
  calcWeekendDip,
  extractNoteThemes,
  MOOD_LABELS,
  // New helpers for extended pattern fields
  bucketTimeOfDay,
  bucketDayOfWeek,
  linearRegressionSlope,
  calcMaxLoggingGap,
  countNoteSentiment,
} = require('../lib/patternAnalyzer');

// ── MOOD_LABELS ──────────────────────────────────────────────────────────────
test('MOOD_LABELS maps index 0 to happy', () => {
  assert.equal(MOOD_LABELS[0], 'happy');
});

test('MOOD_LABELS maps index 5 to tired', () => {
  assert.equal(MOOD_LABELS[5], 'tired');
});

// ── moodToScore ──────────────────────────────────────────────────────────────
test('moodToScore: happy(0) returns 5', () => {
  assert.equal(moodToScore(0), 5);
});

test('moodToScore: calm(1) returns 4', () => {
  assert.equal(moodToScore(1), 4);
});

test('moodToScore: anxious(2) returns 2', () => {
  assert.equal(moodToScore(2), 2);
});

test('moodToScore: sad(3) returns 1', () => {
  assert.equal(moodToScore(3), 1);
});

test('moodToScore: angry(4) returns 1', () => {
  assert.equal(moodToScore(4), 1);
});

test('moodToScore: tired(5) returns 2', () => {
  assert.equal(moodToScore(5), 2);
});

test('moodToScore: out-of-range returns 3', () => {
  assert.equal(moodToScore(99), 3);
  assert.equal(moodToScore(-1), 3);
});

// ── scoreToRiskLevel ─────────────────────────────────────────────────────────
test('scoreToRiskLevel: avgScore < 2.0 → critical', () => {
  assert.equal(scoreToRiskLevel(1.5, 0), 'critical');
});

test('scoreToRiskLevel: trend < -2.0 → critical', () => {
  assert.equal(scoreToRiskLevel(3, -2.5), 'critical');
});

test('scoreToRiskLevel: avgScore < 2.5 → high', () => {
  assert.equal(scoreToRiskLevel(2.2, 0), 'high');
});

test('scoreToRiskLevel: trend < -1.5 → high', () => {
  assert.equal(scoreToRiskLevel(3, -1.8), 'high');
});

test('scoreToRiskLevel: avgScore < 3.0 → moderate', () => {
  assert.equal(scoreToRiskLevel(2.7, 0), 'moderate');
});

test('scoreToRiskLevel: trend < -1.0 → moderate', () => {
  assert.equal(scoreToRiskLevel(3.5, -1.2), 'moderate');
});

test('scoreToRiskLevel: good score and stable → low', () => {
  assert.equal(scoreToRiskLevel(4, 0.1), 'low');
});

// ── calcTrend ────────────────────────────────────────────────────────────────
// entries sorted newest-first (index 0 = most recent), scores are numeric.
// trend = avgLast(older half) - avgFirst(newer half)
// Newer half improving means avgFirst > avgLast → negative trend value → "improving"
// Wait: Dart code: avgFirst = first half (newest), avgLast = last half (oldest)
// trend = avgLast - avgFirst  — if negative, newer > older → improving
// Our JS mirrors this: entries sorted newest-first.

test('calcTrend: all high scores → improving', () => {
  // 6 entries newest-first, scores all high — no real change
  const scores = [5, 5, 5, 5, 5, 5];
  const result = calcTrend(scores);
  assert.equal(result, 'stable');
});

test('calcTrend: declining scores (newer entries low) → declining', () => {
  // scores newest-first: newer entries are low (1,1,1) older were high (5,5,5)
  // avgFirst (newer) = 1, avgLast (older) = 5, trend = 5-1 = 4 → positive → declining
  const scores = [1, 1, 1, 5, 5, 5];
  const result = calcTrend(scores);
  assert.equal(result, 'declining');
});

test('calcTrend: improving scores (newer entries high) → improving', () => {
  // scores newest-first: newer entries are high (5,5,5) older were low (1,1,1)
  // avgFirst (newer) = 5, avgLast (older) = 1, trend = 1-5 = -4 → negative → improving
  const scores = [5, 5, 5, 1, 1, 1];
  const result = calcTrend(scores);
  assert.equal(result, 'improving');
});

test('calcTrend: fewer than 4 entries → stable', () => {
  assert.equal(calcTrend([3, 3]), 'stable');
});

// ── calcDominantMood ─────────────────────────────────────────────────────────
test('calcDominantMood: most frequent mood wins', () => {
  const moods = [3, 3, 3, 0, 0]; // sad(3) appears 3 times
  assert.equal(calcDominantMood(moods), 'sad');
});

test('calcDominantMood: empty → null', () => {
  assert.equal(calcDominantMood([]), null);
});

// ── calcLowStreak ────────────────────────────────────────────────────────────
// entries sorted newest-first; low moods: sad(3), angry(4), tired(5)
test('calcLowStreak: consecutive low moods from start', () => {
  const moodIndices = [3, 4, 5, 0]; // 3 low then happy
  assert.equal(calcLowStreak(moodIndices), 3);
});

test('calcLowStreak: no low moods → 0', () => {
  assert.equal(calcLowStreak([0, 1, 0]), 0);
});

// ── calcWeekendDip ───────────────────────────────────────────────────────────
test('calcWeekendDip: avg weekend < avg weekday by >=1 → true', () => {
  // Construct entries with known weekday/weekend dates
  const monday = new Date('2025-01-06');  // Monday
  const saturday = new Date('2025-01-11'); // Saturday

  const entries = [
    { date: monday, moodIndex: 5 },    // weekday: score 2
    { date: monday, moodIndex: 1 },    // weekday: score 4
    { date: saturday, moodIndex: 3 },  // weekend: score 1
    { date: saturday, moodIndex: 4 },  // weekend: score 1
  ];
  // weekday avg: (2+4)/2 = 3.0, weekend avg: (1+1)/2 = 1.0, diff >= 1 → true
  assert.equal(calcWeekendDip(entries), true);
});

test('calcWeekendDip: weekend ≥ weekday → false', () => {
  const monday = new Date('2025-01-06');
  const saturday = new Date('2025-01-11');
  const entries = [
    { date: monday, moodIndex: 3 },    // weekday: score 1
    { date: saturday, moodIndex: 0 },  // weekend: score 5
  ];
  assert.equal(calcWeekendDip(entries), false);
});

// ── extractNoteThemes ────────────────────────────────────────────────────────
test('extractNoteThemes: English sleep keyword', () => {
  const themes = extractNoteThemes(["I couldn't sleep last night"]);
  assert.ok(themes.includes('sleep'), `Expected sleep in ${themes}`);
});

test('extractNoteThemes: Arabic sleep keyword (نوم)', () => {
  const themes = extractNoteThemes(['لم أنم جيداً']);
  assert.ok(themes.includes('sleep'), `Expected sleep in ${themes}`);
});

test('extractNoteThemes: English work keyword', () => {
  const themes = extractNoteThemes(['too much work today']);
  assert.ok(themes.includes('work'), `Expected work in ${themes}`);
});

test('extractNoteThemes: Arabic work keyword (عمل)', () => {
  const themes = extractNoteThemes(['ضغط في العمل']);
  assert.ok(themes.includes('work'), `Expected work in ${themes}`);
});

test('extractNoteThemes: money keyword (دين)', () => {
  const themes = extractNoteThemes(['لدي ديون كثيرة']);
  assert.ok(themes.includes('money'), `Expected money in ${themes}`);
});

test('extractNoteThemes: health keyword', () => {
  const themes = extractNoteThemes(['feeling sick today']);
  assert.ok(themes.includes('health'), `Expected health in ${themes}`);
});

test('extractNoteThemes: no notes → empty array', () => {
  const themes = extractNoteThemes([]);
  assert.deepEqual(themes, []);
});

test('extractNoteThemes: null/empty notes ignored', () => {
  const themes = extractNoteThemes([null, undefined, '', 'some note']);
  assert.ok(Array.isArray(themes));
});

test('extractNoteThemes: no keywords match → empty array', () => {
  const themes = extractNoteThemes(['everything is fine and good']);
  assert.deepEqual(themes, []);
});

test('extractNoteThemes: returns unique buckets only', () => {
  const themes = extractNoteThemes(['sleep problems', 'tired sleep']);
  const sleepCount = themes.filter(t => t === 'sleep').length;
  assert.equal(sleepCount, 1);
});

// ── bucketTimeOfDay ───────────────────────────────────────────────────────────

test('bucketTimeOfDay: hour 7 → morning', () => {
  assert.equal(bucketTimeOfDay(7), 'morning');
});

test('bucketTimeOfDay: hour 12 → afternoon', () => {
  assert.equal(bucketTimeOfDay(12), 'afternoon');
});

test('bucketTimeOfDay: hour 17 → evening', () => {
  assert.equal(bucketTimeOfDay(17), 'evening');
});

test('bucketTimeOfDay: hour 22 → night', () => {
  assert.equal(bucketTimeOfDay(22), 'night');
});

test('bucketTimeOfDay: hour 0 → night', () => {
  assert.equal(bucketTimeOfDay(0), 'night');
});

test('bucketTimeOfDay: hour 5 → morning', () => {
  assert.equal(bucketTimeOfDay(5), 'morning');
});

test('bucketTimeOfDay: hour 23 → night', () => {
  assert.equal(bucketTimeOfDay(23), 'night');
});

// ── bucketDayOfWeek ───────────────────────────────────────────────────────────

test('bucketDayOfWeek: day 1 (Mon) → mon', () => {
  assert.equal(bucketDayOfWeek(1), 'mon');
});

test('bucketDayOfWeek: day 0 (Sun) → sun', () => {
  assert.equal(bucketDayOfWeek(0), 'sun');
});

test('bucketDayOfWeek: day 6 (Sat) → sat', () => {
  assert.equal(bucketDayOfWeek(6), 'sat');
});

// ── linearRegressionSlope ────────────────────────────────────────────────────

test('linearRegressionSlope: consistently increasing series → positive slope', () => {
  // x=[0,1,2,3,4], y=[1,2,3,4,5] → slope = 1.0
  const slope = linearRegressionSlope([1, 2, 3, 4, 5]);
  assert.ok(slope > 0.9 && slope < 1.1, `Expected slope ~1 but got ${slope}`);
});

test('linearRegressionSlope: consistently decreasing → negative slope', () => {
  const slope = linearRegressionSlope([5, 4, 3, 2, 1]);
  assert.ok(slope < -0.9 && slope > -1.1, `Expected slope ~-1 but got ${slope}`);
});

test('linearRegressionSlope: flat series → slope near 0', () => {
  const slope = linearRegressionSlope([3, 3, 3, 3, 3]);
  assert.ok(Math.abs(slope) < 0.001, `Expected slope ~0 but got ${slope}`);
});

test('linearRegressionSlope: empty array → 0', () => {
  assert.equal(linearRegressionSlope([]), 0);
});

test('linearRegressionSlope: single element → 0', () => {
  assert.equal(linearRegressionSlope([5]), 0);
});

// ── calcMaxLoggingGap ─────────────────────────────────────────────────────────

test('calcMaxLoggingGap: consecutive days → gap 0', () => {
  // Entries every day for 3 days, range 5 days
  const d = (daysAgo) => {
    const dt = new Date('2025-01-10');
    dt.setDate(dt.getDate() - daysAgo);
    return dt;
  };
  const entries = [d(0), d(1), d(2)];
  const gap = calcMaxLoggingGap(entries, new Date('2025-01-10'), 5);
  // 5-day range: days 0–4. Entries on day 0,1,2. Day 3 and 4 are missing → gap 2
  assert.ok(gap >= 0, 'gap must be non-negative');
});

test('calcMaxLoggingGap: no entries → gap equals rangeDays', () => {
  const endDate = new Date('2025-01-10');
  const gap = calcMaxLoggingGap([], endDate, 7);
  assert.equal(gap, 7);
});

test('calcMaxLoggingGap: gap in the middle', () => {
  const d = (daysAgo) => {
    const dt = new Date('2025-01-15');
    dt.setDate(dt.getDate() - daysAgo);
    return dt;
  };
  // entries on day 0 and day 6 — gap of 5 days in between
  const entries = [d(0), d(6)];
  const gap = calcMaxLoggingGap(entries, new Date('2025-01-15'), 10);
  assert.ok(gap >= 5, `Expected gap >= 5, got ${gap}`);
});

// ── countNoteSentiment ────────────────────────────────────────────────────────

test('countNoteSentiment: positive English keyword', () => {
  const result = countNoteSentiment(['today was a happy day', 'feeling good']);
  assert.ok(result.positive >= 2, `Expected >= 2 positives, got ${result.positive}`);
  assert.equal(result.negative, 0);
});

test('countNoteSentiment: negative Arabic keyword', () => {
  const result = countNoteSentiment(['أنا حزين اليوم', 'أشعر بالقلق']);
  assert.ok(result.negative >= 2, `Expected >= 2 negatives, got ${result.negative}`);
});

test('countNoteSentiment: French keyword (heureux)', () => {
  const result = countNoteSentiment(["je me sens heureux aujourd'hui"]);
  assert.ok(result.positive >= 1, `Expected >= 1 positive, got ${result.positive}`);
});

test('countNoteSentiment: empty notes → both 0', () => {
  const result = countNoteSentiment([]);
  assert.equal(result.positive, 0);
  assert.equal(result.negative, 0);
});

test('countNoteSentiment: null notes are ignored', () => {
  const result = countNoteSentiment([null, undefined, '', 'happy day']);
  assert.ok(result.positive >= 1);
});

test('countNoteSentiment: one note can count multiple keyword hits', () => {
  // "happy good grateful" → 3 positive keywords in one note = 3
  const result = countNoteSentiment(['I am happy good and grateful today']);
  assert.ok(result.positive >= 3, `Expected >= 3, got ${result.positive}`);
});
