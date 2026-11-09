'use strict';

/**
 * Pure helpers shared by both generateUserReport paths (AI and non-AI):
 * date-range resolution and the deterministic numbers the patient report
 * shows (mood, risk, engagement). No I/O.
 *
 * Mood entries store a mood INDEX (0=happy..5=tired), not a score; scores
 * come from patternAnalyzer.moodToScore (1 = worst, 5 = best).
 */

const { MOOD_LABELS, moodToScore, scoreToRiskLevel, calcLowStreak } = require('./patternAnalyzer');

const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_RANGE_DAYS = 366;
const DEFAULT_RANGE_DAYS = 30;
const ISO_RE = /^\d{4}-\d{2}-\d{2}$/;

function isoDay(d) {
  return d.toISOString().split('T')[0];
}

function parseIsoDay(s) {
  if (typeof s !== 'string' || !ISO_RE.test(s)) return null;
  const d = new Date(`${s}T00:00:00.000Z`);
  return Number.isNaN(d.getTime()) || isoDay(d) !== s ? null : d;
}

/**
 * Resolve the report period. Dates are whole UTC days, end inclusive.
 * @param {{startDate?:string,endDate?:string,rangeDays?:number,now?:Date}} p
 * @returns {{start:Date,endExclusive:Date,startIso:string,endIso:string,days:number}}
 * @throws {Error} with .code='invalid-argument' on a bad range
 */
function resolveReportRange(p = {}) {
  const fail = (msg) => { const e = new Error(msg); e.code = 'invalid-argument'; throw e; };
  const now = p.now instanceof Date ? p.now : new Date();
  const today = parseIsoDay(isoDay(now));
  let start;
  let end;
  if (p.startDate != null || p.endDate != null) {
    start = parseIsoDay(p.startDate);
    end = parseIsoDay(p.endDate);
    if (!start || !end) fail('startDate and endDate must both be YYYY-MM-DD');
    if (end < start) fail('endDate is before startDate');
  } else {
    const n = Number.isInteger(p.rangeDays) && p.rangeDays > 0 ? p.rangeDays : DEFAULT_RANGE_DAYS;
    end = today;
    start = new Date(today.getTime() - (n - 1) * DAY_MS);
  }
  const days = Math.round((end - start) / DAY_MS) + 1;
  if (days > MAX_RANGE_DAYS) fail(`range is longer than ${MAX_RANGE_DAYS} days`);
  return {
    start,
    endExclusive: new Date(end.getTime() + DAY_MS),
    startIso: isoDay(start),
    endIso: isoDay(end),
    days,
  };
}

function avg(xs) {
  return xs.length ? xs.reduce((a, b) => a + b, 0) / xs.length : null;
}

function weekStart(iso) {
  const d = parseIsoDay(iso);
  if (!d) return null;
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7)); // Monday
  return isoDay(d);
}

/**
 * @param {object} p
 * @param {{mood:number,date:string}[]} [p.moods] date = YYYY-MM-DD
 * @param {{type:string,score:number,interpretation:string,date:string}[]} [p.tests]
 * @param {string[]} [p.activeDates] YYYY-MM-DD days the user did anything in the app
 * @param {{startIso:string,endIso:string,days:number}} p.range
 */
function computeReportMetrics(p) {
  const range = p.range;
  const inRange = (iso) => typeof iso === 'string' && iso >= range.startIso && iso <= range.endIso;

  const moods = (p.moods || [])
    .filter(m => Number.isInteger(m.mood) && m.mood >= 0 && m.mood < MOOD_LABELS.length && inRange(m.date))
    .sort((a, b) => a.date.localeCompare(b.date));
  const scores = moods.map(m => moodToScore(m.mood));
  const avgScore = avg(scores);

  const distribution = {};
  moods.forEach(m => { const k = MOOD_LABELS[m.mood]; distribution[k] = (distribution[k] || 0) + 1; });
  const dominantMood = Object.keys(distribution)
    .sort((a, b) => distribution[b] - distribution[a] || MOOD_LABELS.indexOf(a) - MOOD_LABELS.indexOf(b))[0] || null;

  const weeks = {};
  moods.forEach((m, i) => { const w = weekStart(m.date); (weeks[w] = weeks[w] || []).push(scores[i]); });
  const weekly = Object.keys(weeks).sort().map(w => ({ week: w, avg: avg(weeks[w]), count: weeks[w].length }));

  // Direction: newer half vs older half (needs >= 4 entries).
  let direction = 'insufficient';
  let delta = 0;
  if (scores.length >= 4) {
    const half = Math.floor(scores.length / 2);
    delta = avg(scores.slice(scores.length - half)) - avg(scores.slice(0, scores.length - half));
    direction = delta > 0.5 ? 'improving' : delta < -0.5 ? 'declining' : 'stable';
  } else if (scores.length > 0) {
    direction = 'stable';
  }

  const lowStreak = calcLowStreak(moods.map(m => m.mood).reverse());
  let riskLevel = 'unknown';
  if (avgScore != null) {
    riskLevel = scoreToRiskLevel(avgScore, delta);
    if (lowStreak >= 5 && (riskLevel === 'low' || riskLevel === 'moderate')) riskLevel = 'high';
  }

  const tests = (p.tests || []).filter(t => inRange(t.date)).sort((a, b) => a.date.localeCompare(b.date));

  const days = new Set((p.activeDates || []).filter(inRange));
  moods.forEach(m => days.add(m.date));
  tests.forEach(t => days.add(t.date));
  const activeDays = days.size;
  const engagementPct = Math.round((activeDays / range.days) * 100);

  return {
    moodCount: moods.length,
    moodDays: new Set(moods.map(m => m.date)).size,
    avgScore,
    distribution,
    dominantMood,
    weekly,
    direction,
    lowStreak,
    riskLevel,
    tests,
    activeDays,
    daysInRange: range.days,
    engagementPct,
    moods,
  };
}

module.exports = { resolveReportRange, computeReportMetrics, isoDay, DEFAULT_RANGE_DAYS, MAX_RANGE_DAYS };
