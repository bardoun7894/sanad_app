/**
 * Unit tests for the analyzeAllUsers helper — specifically runWithConcurrency.
 *
 * We test the inline helper by extracting it the same way it will be written
 * in index.js: as a standalone function. This is the only pure logic in the
 * callable that can be meaningfully unit-tested without a Firestore emulator.
 *
 * Run: node --test test/analyzeAllUsers.test.js
 */

'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');

// ── runWithConcurrency — extracted copy of the inline helper ──────────────────
// Must match the implementation in index.js exactly (same 5-line shape).
async function runWithConcurrency(items, limit, fn) {
  const results = new Array(items.length);
  let i = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (i < items.length) { const idx = i++; results[idx] = await fn(items[idx], idx); }
  });
  await Promise.all(workers);
  return results;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

test('runWithConcurrency: processes all items and returns results in order', async () => {
  const items = [1, 2, 3, 4, 5];
  const results = await runWithConcurrency(items, 3, async (x) => x * 2);
  assert.deepEqual(results, [2, 4, 6, 8, 10]);
});

test('runWithConcurrency: respects concurrency limit (no more than N simultaneous)', async () => {
  let concurrent = 0;
  let maxConcurrent = 0;
  const items = Array.from({ length: 10 }, (_, i) => i);
  const LIMIT = 3;

  await runWithConcurrency(items, LIMIT, async (x) => {
    concurrent++;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    // Yield to allow other workers to potentially exceed limit
    await new Promise(resolve => setImmediate(resolve));
    concurrent--;
    return x;
  });

  assert.ok(
    maxConcurrent <= LIMIT,
    `Expected max concurrent <= ${LIMIT}, got ${maxConcurrent}`
  );
});

test('runWithConcurrency: handles empty array', async () => {
  const results = await runWithConcurrency([], 5, async (x) => x);
  assert.deepEqual(results, []);
});

test('runWithConcurrency: single item with limit > 1', async () => {
  const results = await runWithConcurrency(['only'], 10, async (x) => x.toUpperCase());
  assert.deepEqual(results, ['ONLY']);
});

test('runWithConcurrency: propagates errors from fn', async () => {
  const items = [1, 2, 3];
  await assert.rejects(
    () => runWithConcurrency(items, 2, async (x) => {
      if (x === 2) throw new Error('item 2 failed');
      return x;
    }),
    /item 2 failed/
  );
});

test('runWithConcurrency: limit of 1 processes items sequentially', async () => {
  const order = [];
  const items = [10, 20, 30];
  await runWithConcurrency(items, 1, async (x) => {
    order.push(x);
    return x;
  });
  assert.deepEqual(order, [10, 20, 30]);
});

test('runWithConcurrency: passes index as second argument to fn', async () => {
  const items = ['a', 'b', 'c'];
  const results = await runWithConcurrency(items, 2, async (item, idx) => `${idx}:${item}`);
  assert.deepEqual(results, ['0:a', '1:b', '2:c']);
});
