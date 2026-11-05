'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { buildBasicUserReport } = require('../lib/basicUserReport');

const sample = {
  rangeDays: 30,
  moods: [
    { mood: 0, date: '2026-10-05' }, { mood: 0, date: '2026-10-06' },
    { mood: 3, date: '2026-10-13' }, { mood: 2, date: '2026-10-14' },
  ],
  tests: [{ type: 'phq9', score: 12, interpretation: 'moderate', date: '2026-10-10' }],
  bookingsByStatus: { completed: 2, cancelled: 1 },
  activityCounts: { appOpen: 7 },
  subscription: 'premium',
};

test('ar report has mood stats and weekly trend', () => {
  const md = buildBasicUserReport({ ...sample, locale: 'ar' });
  assert.match(md, /تقرير أساسي للمستخدم/);
  assert.match(md, /عدد التسجيلات: 4/);
  assert.match(md, /متوسط الدرجة \(من 0 إلى 5\): 1\.25/);
  assert.match(md, /سعيد \(2\)/);
  assert.match(md, /الأسبوع 2026-10-05: 0\.00 \(2 تسجيلات\)/);
  assert.match(md, /الإجمالي: 3/);
  assert.match(md, /premium/);
});

test('en report has mood stats and trend', () => {
  const md = buildBasicUserReport({ ...sample, locale: 'en' });
  assert.match(md, /Entries: 4/);
  assert.match(md, /Average score \(0 to 5\): 1\.25/);
  assert.match(md, /Happy \(2\)/);
  assert.match(md, /Week 2026-10-12: 2\.50 \(2 entries\)/);
  assert.match(md, /phq9: score 12 — moderate/);
});

test('fr locale works and unknown locale falls back to ar', () => {
  assert.match(buildBasicUserReport({ ...sample, locale: 'fr' }), /Rapport utilisateur de base/);
  assert.match(buildBasicUserReport({ ...sample, locale: 'xx' }), /تقرير أساسي/);
});

test('zero data does not throw and says no data', () => {
  for (const locale of ['ar', 'en', 'fr']) {
    const md = buildBasicUserReport({ locale });
    assert.ok(md.length > 0);
    assert.ok(!/NaN|undefined/.test(md));
  }
  assert.match(buildBasicUserReport({ locale: 'en' }), /No data/);
  assert.doesNotThrow(() => buildBasicUserReport());
});
