'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { buildBasicUserReport, SECTION_TITLES } = require('../lib/basicUserReport');
const { resolveReportRange, computeReportMetrics } = require('../lib/reportMetrics');

const now = new Date('2026-11-09T10:00:00Z');

test('range: explicit dates are inclusive and validated', () => {
  const r = resolveReportRange({ startDate: '2026-10-01', endDate: '2026-10-31', now });
  assert.equal(r.days, 31);
  assert.equal(r.startIso, '2026-10-01');
  assert.equal(r.endExclusive.toISOString(), '2026-11-01T00:00:00.000Z');
  assert.throws(() => resolveReportRange({ startDate: '2026-10-31', endDate: '2026-10-01', now }), /before/);
  assert.throws(() => resolveReportRange({ startDate: '2026-10-01', now }), /YYYY-MM-DD/);
  assert.throws(() => resolveReportRange({ startDate: '2026-02-30', endDate: '2026-03-01', now }), /YYYY-MM-DD/);
  assert.throws(() => resolveReportRange({ startDate: '2024-01-01', endDate: '2026-01-01', now }), /longer/);
});

test('range: default is the last 30 days ending today', () => {
  const r = resolveReportRange({ now });
  assert.equal(r.endIso, '2026-11-09');
  assert.equal(r.startIso, '2026-10-11');
  assert.equal(r.days, 30);
  assert.equal(resolveReportRange({ rangeDays: 90, now }).days, 90);
});

const range = resolveReportRange({ startDate: '2026-10-01', endDate: '2026-10-10', now });

test('metrics: mood index maps to score, declining trend, engagement %', () => {
  const m = computeReportMetrics({
    range,
    moods: [
      { mood: 0, date: '2026-10-01' }, { mood: 1, date: '2026-10-02' },
      { mood: 3, date: '2026-10-08' }, { mood: 4, date: '2026-10-09' },
      { mood: 0, date: '2026-09-30' }, // out of range
    ],
    tests: [{ type: 'phq9', score: 12, interpretation: 'moderate', date: '2026-10-05' }],
    activeDates: ['2026-10-02', '2026-10-03', '2026-11-01'],
  });
  assert.equal(m.moodCount, 4);
  assert.equal(m.avgScore, (5 + 4 + 1 + 1) / 4); // happy, calm, sad, angry
  assert.equal(m.direction, 'declining');
  assert.equal(m.lowStreak, 2);
  assert.equal(m.riskLevel, 'critical'); // delta -3.5
  assert.equal(m.activeDays, 6); // 01,02,03,05,08,09
  assert.equal(m.engagementPct, 60);
});

test('metrics: one or two logged days never rate risk', () => {
  const m = computeReportMetrics({ range, moods: [{ mood: 3, date: '2026-10-02' }, { mood: 4, date: '2026-10-02' }] });
  assert.equal(m.riskLevel, 'unknown');
  assert.equal(m.direction, 'insufficient');
});

test('metrics: no data gives unknown risk and 0% engagement', () => {
  const m = computeReportMetrics({ range });
  assert.equal(m.riskLevel, 'unknown');
  assert.equal(m.direction, 'insufficient');
  assert.equal(m.engagementPct, 0);
});

test('ar report: six sections in order, no admin data, consent note', () => {
  const metrics = computeReportMetrics({
    range,
    moods: [{ mood: 2, date: '2026-10-03' }],
    activeDates: ['2026-10-03', '2026-10-04'],
  });
  const md = buildBasicUserReport({ locale: 'ar', range, metrics, generatedIso: '2026-11-09' });
  assert.match(md, /^# التقرير النفسي/);
  assert.match(md, /من 2026-10-01 إلى 2026-10-10 \(10 يوماً\)/);
  let pos = -1;
  SECTION_TITLES.ar.forEach((s, i) => {
    const at = md.indexOf(`## ${i + 1}. ${s}`);
    assert.ok(at > pos, `section ${s} missing or out of order`);
    pos = at;
  });
  assert.match(md, /لم تتم الموافقة على مشاركة البيانات/);
  assert.match(md, /قلق \(1\)/);
  assert.match(md, /أيام النشاط في التطبيق: 2 من 10 يوماً \(20%\)/);
  assert.doesNotMatch(md, /الحجوزات|الاشتراك|reportGenerated|moodLogged/);
  assert.doesNotMatch(md, /\|/); // no tables
});

test('en and fr reports render all six sections', () => {
  const metrics = computeReportMetrics({ range });
  for (const locale of ['en', 'fr']) {
    const md = buildBasicUserReport({ locale, range, metrics, generatedIso: '2026-11-09' });
    SECTION_TITLES[locale].forEach((s, i) => assert.ok(md.includes(`## ${i + 1}. ${s}`), `${locale}: ${s}`));
  }
});

test('consentMissing false omits the consent note', () => {
  const metrics = computeReportMetrics({ range });
  const md = buildBasicUserReport({ locale: 'ar', range, metrics, generatedIso: '2026-11-09', consentMissing: false });
  assert.doesNotMatch(md, /لم تتم الموافقة/);
  assert.match(md, /## 6\. التوصيات/);
});
