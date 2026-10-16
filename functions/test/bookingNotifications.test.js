'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { formatSessionAr, formatSessionEn } = require('../lib/bookingFormat');
const n = require('../lib/bookingNotifications');

// Sunday 18 Oct 2026, 20:00 Sudan time (UTC+2) = 18:00 UTC
const T = new Date('2026-10-18T18:00:00Z');
const base = {
  therapist_id: 't1', client_id: 'c1', client_name: 'سارة', therapist_name: 'د. أحمد',
  scheduled_time: T, status: 'awaiting_payment', payment_status: 'awaiting_payment',
};

test('formatter: Gregorian, Sudan time, latin digits', () => {
  const ar = formatSessionAr(T);
  const en = formatSessionEn(T);
  console.log('SAMPLE AR:', ar.full);
  console.log('SAMPLE EN:', en.full);
  assert.equal(ar.full, 'الأحد 18 أكتوبر 2026 الساعة 8:00 م بتوقيت السودان');
  assert.equal(en.full, 'Sunday, October 18, 2026 at 8:00 PM Sudan time');
  assert.equal(formatSessionAr(null), null);
  assert.equal(formatSessionAr({ toDate: () => T }).time, '8:00 م');
});

test('bank transfer pending notifies therapist only, once', () => {
  const after = { ...base, payment_status: 'bank_transfer_pending' };
  assert.equal(n.becameBankTransferPending(base, after), true);
  assert.equal(n.becameBankTransferPending(after, after), false);
  assert.equal(n.becameBankTransferPending(base, { ...after, therapist_notified_at: 1 }), false);
  const s = n.bankTransferTherapistSpec(after, 'b1');
  assert.equal(s.userId, 't1');
  assert.equal(s.type, 'new_booking');
  assert.equal(s.body, 'سارة حجز معك جلسة يوم الأحد 18 أكتوبر 2026 الساعة 8:00 م بتوقيت السودان — بانتظار تأكيد الدفع');
  assert.equal(s.chatId, 't1_c1');
  assert.equal(s.recipientRole, 'therapist');
  assert.equal(s.scheduledTime, T.toISOString());
  assert.equal(s.clientName, 'سارة');
});

test('paid pending auto-confirms and sends no therapist notification', () => {
  const before = { ...base };
  const after = { ...base, status: 'pending', payment_status: 'paid' };
  assert.equal(n.shouldAutoConfirm(after), true);
  assert.equal(n.shouldAutoConfirm({ ...after, payment_status: 'awaiting_payment' }), false);
  assert.equal(n.shouldAutoConfirm({ ...after, status: 'confirmed' }), false);
  // planStatusNotifications never emits anything for pending
  assert.deepEqual(n.planStatusNotifications(before, after, 'b1'), []);
});

test('confirmed notifies therapist with date/time; client body has date/time', () => {
  const before = { ...base, status: 'pending', payment_status: 'paid' };
  const after = { ...before, status: 'confirmed' };
  const plan = n.planStatusNotifications(before, after, 'b1');
  assert.equal(plan.length, 1);
  assert.equal(plan[0].userId, 't1');
  assert.equal(plan[0].type, 'booking_confirmed');
  assert.equal(plan[0].body, 'جلسة مؤكدة: سارة يوم الأحد 18 أكتوبر 2026 الساعة 8:00 م بتوقيت السودان');
  const c = n.clientConfirmedBodies(after);
  assert.match(c.arBody, /د\. أحمد يوم الأحد 18 أكتوبر 2026 الساعة 8:00 م بتوقيت السودان/);
  assert.match(c.enBody, /confirmed on Sunday, October 18, 2026 at 8:00 PM Sudan time/);
});

test('cancel notifies therapist only when they knew or payment was in flight', () => {
  const cancelled = (b) => ({ ...b, status: 'cancelled' });
  const abandoned = n.planStatusNotifications(base, cancelled(base), 'b1');
  assert.deepEqual(abandoned, [], 'abandoned card checkout: no spam');

  const bank = { ...base, payment_status: 'bank_transfer_pending' };
  const p1 = n.planStatusNotifications(bank, cancelled(bank), 'b1');
  assert.equal(p1.length, 1);
  assert.equal(p1[0].type, 'booking_cancelled');
  assert.equal(p1[0].body, 'الجلسة مع سارة يوم الأحد 18 أكتوبر 2026 الساعة 8:00 م ملغاة — لا توجد جلسة');

  const paid = { ...base, status: 'confirmed', payment_status: 'paid' };
  assert.equal(n.planStatusNotifications(paid, { ...paid, status: 'rejected' }, 'b1').length, 1);

  const notified = { ...base, therapist_notified_at: 1 };
  assert.equal(n.planStatusNotifications(notified, cancelled(notified), 'b1').length, 1);
});

test('completed sends no therapist notification', () => {
  const b = { ...base, status: 'confirmed', payment_status: 'paid' };
  assert.deepEqual(n.planStatusNotifications(b, { ...b, status: 'completed' }, 'b1'), []);
});

test('double-booking guard', () => {
  const now = Date.now();
  const future = new Date(now + 3600e3);
  const past = new Date(now - 3600e3);
  assert.equal(n.blocksSlot({ status: 'pending' }, now), true);
  assert.equal(n.blocksSlot({ status: 'confirmed' }, now), true);
  assert.equal(n.blocksSlot({ status: 'awaiting_payment', payment_status: 'bank_transfer_pending' }, now), true);
  assert.equal(n.blocksSlot({ status: 'awaiting_payment', payment_status: 'awaiting_payment', payment_deadline: future }, now), true);
  assert.equal(n.blocksSlot({ status: 'awaiting_payment', payment_status: 'awaiting_payment', payment_deadline: past }, now), false);
  assert.equal(n.blocksSlot({ status: 'awaiting_payment', payment_status: 'awaiting_payment' }, now), false);
  assert.equal(n.blocksSlot({ status: 'cancelled' }, now), false);
  assert.equal(n.blocksSlot({ status: 'completed' }, now), false);
});

test('reminder for therapist', () => {
  const s = n.reminderTherapistSpec({ ...base, status: 'confirmed' }, 'b1');
  assert.equal(s.type, 'booking_reminder');
  assert.equal(s.body, 'لديك جلسة الساعة 8:00 م بتوقيت السودان مع سارة');
  assert.equal(s.recipientRole, 'therapist');
  assert.equal(s.chatId, 't1_c1');
});

test('slot guard: earlier booking wins a race, later one never blocks', () => {
  const now = Date.now();
  const mk = (id, ms, extra = {}) => ({
    id, data: { ...base, client_id: 'other', status: 'pending', created_at: ms === null ? undefined : new Date(ms), ...extra },
  });
  const me = { ...base, status: 'awaiting_payment', created_at: new Date(2000) };
  // existing created earlier blocks
  assert.equal(n.resolveSlotClash(me, 'b2', [mk('b1', 1000)], now).blocked, true);
  // existing created later does not block (it will lose on its own trigger)
  assert.equal(n.resolveSlotClash(me, 'b1', [mk('b2', 3000)], now).blocked, false);
  // equal created_at: lower doc id wins
  const eq = { ...me, created_at: new Date(1000) };
  assert.equal(n.resolveSlotClash(eq, 'b2', [mk('b1', 1000)], now).blocked, true);
  assert.equal(n.resolveSlotClash(eq, 'b1', [mk('b2', 1000)], now).blocked, false);
  // missing created_at falls back to doc id
  const noTs = { ...me, created_at: undefined };
  assert.equal(n.resolveSlotClash(noTs, 'b2', [mk('b1', null)], now).blocked, true);
  assert.equal(n.resolveSlotClash(noTs, 'b1', [mk('b2', null)], now).blocked, false);
  // never blocked by itself
  assert.equal(n.resolveSlotClash(me, 'b1', [mk('b1', 1000)], now).blocked, false);
  // Firestore Timestamp-like values
  const ts = (ms) => ({ toDate: () => new Date(ms) });
  assert.equal(n.resolveSlotClash({ ...me, created_at: ts(2000) }, 'b2', [mk('b1', 0, { created_at: ts(1000) })], now).blocked, true);
});

test('slot guard: same-client abandoned card checkout is superseded, not blocking', () => {
  const now = Date.now();
  const me = { ...base, created_at: new Date(2000) };
  const old = (extra) => ({ id: 'b1', data: { ...base, created_at: new Date(1000), payment_deadline: new Date(now + 60000), ...extra } });
  const r = n.resolveSlotClash(me, 'b2', [old({})], now);
  assert.equal(r.blocked, false);
  assert.deepEqual(r.supersedeIds, ['b1']);
  // same client bank transfer pending and paid still block
  const bt = n.resolveSlotClash(me, 'b2', [old({ payment_status: 'bank_transfer_pending' })], now);
  assert.equal(bt.blocked, true);
  assert.deepEqual(bt.supersedeIds, []);
  const paid = n.resolveSlotClash(me, 'b2', [old({ status: 'pending', payment_status: 'paid' })], now);
  assert.equal(paid.blocked, true);
  assert.deepEqual(paid.supersedeIds, []);
  // a different client's awaiting_payment still blocks while deadline is live
  const diff = n.resolveSlotClash(me, 'b2', [old({ client_id: 'zzz' })], now);
  assert.equal(diff.blocked, true);
  assert.deepEqual(diff.supersedeIds, []);
  // superseded one plus a real blocker: blocked, and nothing is superseded
  const both = n.resolveSlotClash(me, 'b3', [old({}), { id: 'b2', data: { ...base, client_id: 'zzz', status: 'confirmed', created_at: new Date(1500) } }], now);
  assert.equal(both.blocked, true);
  assert.deepEqual(both.supersedeIds, []);
});

test('therapist spec carries action_route to the therapist chat', () => {
  const after = { ...base, payment_status: 'bank_transfer_pending' };
  const s = n.bankTransferTherapistSpec(after, 'b1');
  assert.equal(s.actionRoute, '/therapist/messages/t1_c1');
});

test('buildTherapistChatDoc mirrors the app thread fields, access none', () => {
  const d = n.buildTherapistChatDoc(base, 'b1');
  assert.deepEqual(d, {
    chat_id: 't1_c1', therapist_id: 't1', user_id: 'c1',
    therapist_name: 'د. أحمد', user_name: 'سارة',
    booking_id: 'b1', booking_ids: ['b1'],
    status: 'active', source: 'booking', user_access: 'none',
    unread_count_therapist: 0, unread_count_user: 0,
    typing: { therapist: false, user: false },
  });
});

test('buildTherapistChatDoc omits placeholder or missing names', () => {
  for (const bad of ['User', 'Unknown User', 'Therapist', '  ', undefined, null]) {
    const d = n.buildTherapistChatDoc({ ...base, client_name: bad, therapist_name: bad }, 'b1');
    assert.equal('user_name' in d, false);
    assert.equal('therapist_name' in d, false);
  }
});

test('therapistChatId joins therapist and client', () => {
  assert.equal(n.therapistChatId(base), 't1_c1');
  assert.equal(n.therapistChatId({ client_id: 'c1' }), null);
});

test('suppressClientCancelNotice only for superseded and slot_taken cancellations', () => {
  const c = (status, reason) => ({ ...base, status, cancellation_reason: reason });
  assert.equal(n.suppressClientCancelNotice(c('cancelled', 'superseded')), true);
  assert.equal(n.suppressClientCancelNotice(c('cancelled', 'slot_taken')), true);
  assert.equal(n.suppressClientCancelNotice(c('cancelled', 'user_request')), false);
  assert.equal(n.suppressClientCancelNotice(c('cancelled', undefined)), false);
  assert.equal(n.suppressClientCancelNotice(c('confirmed', 'superseded')), false);
});
