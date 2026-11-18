'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { computeUsageInsights, toMillis } = require('../lib/usageInsights');

const now = Date.parse('2026-11-09T10:00:00Z');
const daysAgo = (n) => now - n * 24 * 60 * 60 * 1000;
const consent = { accepted: true, version: '2026-10-01' };

const users = [
  { id: 'a', data: { name: 'Amal', role: 'user', last_seen: daysAgo(0.5), created_at: daysAgo(10), ai_privacy_consent: consent } },
  { id: 'b', data: { name: 'Badr', role: 'user', last_login: daysAgo(5), created_at: daysAgo(200) } },
  { id: 'c', data: { name: 'Coach', role: 'admin', last_seen: daysAgo(0.1) } },
  { id: 'd', data: { name: 'Dormant', role: 'user', last_seen: daysAgo(90), created_at: daysAgo(300) } },
];

const events = [
  { section: 'mood', uid: 'a', at: daysAgo(1) },
  { section: 'mood', uid: 'a', at: daysAgo(2) },
  { section: 'mood', uid: 'b', at: daysAgo(3) },
  { section: 'tests', uid: 'a', at: daysAgo(4) },
  { section: 'aiChat', uid: 'b', at: daysAgo(60) }, // b's first feature, outside window
  { section: 'aiChat', uid: 'b', at: daysAgo(3), weight: 9, hourly: false },
  { section: 'community', uid: 'd', at: daysAgo(100) },
  { section: 'mood', uid: 'c', at: daysAgo(1) },
  { section: 'unknown', uid: 'a', at: daysAgo(1) },
  { section: 'mood', uid: null, at: daysAgo(1) },
];

const r = computeUsageInsights({ users, events, now, windowDays: 30 });

test('active users come from last_seen / last_login windows', () => {
  assert.deepEqual(r.totals, { users: 4, active1d: 2, active7d: 3, active30d: 3, newUsers: 1 });
});

test('sections rank by unique users in the window, then events', () => {
  assert.equal(r.sections[0].key, 'mood');
  assert.equal(r.sections[0].uniqueUsers, 3); // a, b, c (admins still count in section reach)
  assert.equal(r.sections[0].events, 4);
  const ai = r.sections.find((s) => s.key === 'aiChat');
  assert.equal(ai.events, 9);
  assert.equal(ai.eventsAllTime, 10);
  assert.equal(r.sections.find((s) => s.key === 'community').uniqueUsers, 0);
  assert.equal(r.sections.find((s) => s.key === 'community').uniqueUsersAllTime, 1);
});

test('top users exclude staff, rank by active days, and carry AI consent', () => {
  assert.deepEqual(r.topUsers.map((u) => u.uid), ['a', 'b']);
  assert.equal(r.topUsers[0].activeDays, 4); // 3 event days + presence day
  assert.equal(r.topUsers[0].aiConsent, true);
  assert.equal(r.topUsers[1].aiConsent, false);
  assert.deepEqual(r.topUsers[1].bySection, { mood: 1, aiChat: 9 });
});

test('first feature uses each user\'s earliest event across all time', () => {
  const byKey = Object.fromEntries(r.firstFeature.map((f) => [f.key, f.users]));
  assert.deepEqual(byKey, { tests: 1, aiChat: 1, community: 1 }); // a, b, d; admin c excluded
});

test('peak hours skip thread-level timestamps', () => {
  const total = r.peakHours.reduce((n, h) => n + h.count, 0);
  assert.ok(total <= 5);
  assert.ok(r.notTracked.some((n) => n.key === 'screen_path'));
});

test('toMillis handles Firestore-like values', () => {
  assert.equal(toMillis({ toMillis: () => 5 }), 5);
  assert.equal(toMillis(new Date(7)), 7);
  assert.equal(toMillis('bad'), null);
  assert.equal(toMillis(null), null);
});
