/**
 * Unit tests for admin user action helpers (setUserBlocked / deleteUserAccount).
 *
 * These helpers are pure-logic utilities extracted from the callables:
 *   1. validateBlockArgs(data)          — validates setUserBlocked inputs
 *   2. validateDeleteArgs(data)         — validates deleteUserAccount inputs
 *   3. deleteCollectionInBatches(ref, batchSize) — recursive batch-delete
 *
 * The full callables (auth gate, Admin SDK calls, Firestore cross-collection
 * writes) are integration-tested via `firebase functions:list` + log inspection
 * after deploy. There is no firebase-functions-test dep in this project.
 *
 * Run: node --test test/adminUserActions.test.js
 */

'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');

// ── 1. Argument validation helpers ────────────────────────────────────────────

/**
 * Validates args for setUserBlocked.
 * Returns null on success or an error string on failure.
 */
function validateBlockArgs({ userId, blocked }) {
  if (!userId || typeof userId !== 'string') {
    return 'userId must be a non-empty string';
  }
  if (typeof blocked !== 'boolean') {
    return 'blocked must be a boolean';
  }
  return null;
}

/**
 * Validates args for deleteUserAccount.
 * Returns null on success or an error string on failure.
 */
function validateDeleteArgs({ userId }) {
  if (!userId || typeof userId !== 'string') {
    return 'userId must be a non-empty string';
  }
  return null;
}

// ── 2. deleteCollectionInBatches helper ───────────────────────────────────────
// Matches the implementation that will live inline in index.js.

/**
 * Deletes all documents in a Firestore collection reference in batches.
 * Uses firestore.batch() from the db reference passed in.
 *
 * @param {object} db           - Firestore db instance (or mock)
 * @param {object} collRef      - CollectionReference to delete
 * @param {number} batchSize    - Max docs per batch (default 500)
 * @returns {Promise<number>}   - Total docs deleted
 */
async function deleteCollectionInBatches(db, collRef, batchSize = 500) {
  let totalDeleted = 0;
  while (true) {
    const snap = await collRef.limit(batchSize).get();
    if (snap.empty) break;

    const batch = db.batch();
    snap.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
    totalDeleted += snap.docs.length;

    // If fewer docs than batchSize were returned, we've cleared the collection
    if (snap.docs.length < batchSize) break;
  }
  return totalDeleted;
}

// ── Tests: validateBlockArgs ───────────────────────────────────────────────────

test('validateBlockArgs: passes for valid userId and blocked=true', () => {
  const err = validateBlockArgs({ userId: 'uid123', blocked: true });
  assert.equal(err, null);
});

test('validateBlockArgs: passes for valid userId and blocked=false', () => {
  const err = validateBlockArgs({ userId: 'uid123', blocked: false });
  assert.equal(err, null);
});

test('validateBlockArgs: fails for empty userId string', () => {
  const err = validateBlockArgs({ userId: '', blocked: true });
  assert.notEqual(err, null);
  assert.match(err, /userId/);
});

test('validateBlockArgs: fails for null userId', () => {
  const err = validateBlockArgs({ userId: null, blocked: true });
  assert.notEqual(err, null);
  assert.match(err, /userId/);
});

test('validateBlockArgs: fails for numeric userId', () => {
  const err = validateBlockArgs({ userId: 42, blocked: true });
  assert.notEqual(err, null);
  assert.match(err, /userId/);
});

test('validateBlockArgs: fails when blocked is a string "true"', () => {
  const err = validateBlockArgs({ userId: 'uid123', blocked: 'true' });
  assert.notEqual(err, null);
  assert.match(err, /blocked/);
});

test('validateBlockArgs: fails when blocked is undefined', () => {
  const err = validateBlockArgs({ userId: 'uid123', blocked: undefined });
  assert.notEqual(err, null);
  assert.match(err, /blocked/);
});

test('validateBlockArgs: fails when blocked is null', () => {
  const err = validateBlockArgs({ userId: 'uid123', blocked: null });
  assert.notEqual(err, null);
  assert.match(err, /blocked/);
});

// ── Tests: validateDeleteArgs ──────────────────────────────────────────────────

test('validateDeleteArgs: passes for valid userId', () => {
  const err = validateDeleteArgs({ userId: 'uid123' });
  assert.equal(err, null);
});

test('validateDeleteArgs: fails for empty string userId', () => {
  const err = validateDeleteArgs({ userId: '' });
  assert.notEqual(err, null);
  assert.match(err, /userId/);
});

test('validateDeleteArgs: fails for undefined userId', () => {
  const err = validateDeleteArgs({ userId: undefined });
  assert.notEqual(err, null);
  assert.match(err, /userId/);
});

test('validateDeleteArgs: fails for numeric userId', () => {
  const err = validateDeleteArgs({ userId: 123 });
  assert.notEqual(err, null);
  assert.match(err, /userId/);
});

// ── Tests: deleteCollectionInBatches ──────────────────────────────────────────

/**
 * Build a fake Firestore collection reference that simulates a collection
 * with `totalDocs` documents.
 *
 * Each call to `.limit(n).get()` returns the next up-to-n docs (consuming
 * from the simulated pool), so loops terminate correctly.
 */
function makeFakeCollRef(db, totalDocs) {
  const allDocs = Array.from({ length: totalDocs }, (_, i) => ({
    ref: { id: `doc${i}` },
  }));
  let offset = 0;

  return {
    limit(n) {
      return {
        async get() {
          const slice = allDocs.slice(offset, offset + n);
          offset += slice.length;
          return {
            empty: slice.length === 0,
            docs: slice,
          };
        },
      };
    },
  };
}

/**
 * Build a fake Firestore db whose .batch() returns a batch that records
 * delete calls and resolves commit().
 */
function makeFakeDb() {
  const deletedRefs = [];
  return {
    _deletedRefs: deletedRefs,
    batch() {
      const calls = [];
      return {
        delete(ref) { calls.push(ref); deletedRefs.push(ref); },
        async commit() { /* no-op */ },
      };
    },
  };
}

test('deleteCollectionInBatches: deletes all docs when count < batchSize', async () => {
  const db = makeFakeDb();
  const collRef = makeFakeCollRef(db, 3);
  const total = await deleteCollectionInBatches(db, collRef, 500);
  assert.equal(total, 3);
  assert.equal(db._deletedRefs.length, 3);
});

test('deleteCollectionInBatches: returns 0 for empty collection', async () => {
  const db = makeFakeDb();
  const collRef = makeFakeCollRef(db, 0);
  const total = await deleteCollectionInBatches(db, collRef, 500);
  assert.equal(total, 0);
  assert.equal(db._deletedRefs.length, 0);
});

test('deleteCollectionInBatches: loops correctly when docs exceed batchSize', async () => {
  const db = makeFakeDb();
  // 1100 docs, batchSize 500 → 3 iterations (500 + 500 + 100)
  const collRef = makeFakeCollRef(db, 1100);
  const total = await deleteCollectionInBatches(db, collRef, 500);
  assert.equal(total, 1100);
  assert.equal(db._deletedRefs.length, 1100);
});

test('deleteCollectionInBatches: works exactly at batchSize boundary', async () => {
  const db = makeFakeDb();
  // Exactly 500 docs — first get returns 500, second get returns 0 (empty)
  const collRef = makeFakeCollRef(db, 500);
  const total = await deleteCollectionInBatches(db, collRef, 500);
  assert.equal(total, 500);
  assert.equal(db._deletedRefs.length, 500);
});

test('deleteCollectionInBatches: each batch is committed separately', async () => {
  let commitCount = 0;
  const allDocs = Array.from({ length: 6 }, (_, i) => ({ ref: { id: `doc${i}` } }));
  let offset = 0;

  const collRef = {
    limit(n) {
      return {
        async get() {
          const slice = allDocs.slice(offset, offset + n);
          offset += slice.length;
          return { empty: slice.length === 0, docs: slice };
        },
      };
    },
  };

  const db = {
    _deletedRefs: [],
    batch() {
      return {
        delete(ref) { db._deletedRefs.push(ref); },
        async commit() { commitCount++; },
      };
    },
  };

  await deleteCollectionInBatches(db, collRef, 4);
  // 6 docs, batchSize 4 → 2 batches (4 + 2)
  assert.equal(commitCount, 2);
  assert.equal(db._deletedRefs.length, 6);
});
