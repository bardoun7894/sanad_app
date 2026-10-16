/**
 * Pure decision logic for booking notifications, so it can be unit-tested
 * without the Admin SDK. index.js turns the returned specs into pushes and
 * in-app notification docs.
 */
'use strict';

const { formatSessionAr, formatSessionEn, toDate } = require('./bookingFormat');

function ctx(booking, bookingId) {
  const when = toDate(booking.scheduled_time);
  return {
    bookingId,
    therapistId: booking.therapist_id,
    clientId: booking.client_id,
    clientName: booking.client_name || 'عميل',
    therapistName: booking.therapist_name || 'المعالج',
    when,
    ar: formatSessionAr(when),
    en: formatSessionEn(when),
  };
}

function therapistSpec(c, type, title, titleEn, body, bodyEn, status) {
  return {
    userId: c.therapistId,
    role: 'therapist',
    type,
    title,
    titleEn,
    body,
    bodyEn,
    status,
    bookingId: c.bookingId,
    chatId: `${c.therapistId}_${c.clientId}`,
    actionRoute: `/therapist/messages/${c.therapistId}_${c.clientId}`,
    clientId: c.clientId,
    clientName: c.clientName,
    scheduledTime: c.when ? c.when.toISOString() : '',
    recipientRole: 'therapist',
  };
}


function bankTransferTherapistSpec(booking, bookingId) {
  const c = ctx(booking, bookingId);
  const arW = c.ar ? `يوم ${c.ar.date} الساعة ${c.ar.time} بتوقيت السودان` : '';
  const enW = c.en ? `on ${c.en.date} at ${c.en.time} Sudan time` : '';
  return therapistSpec(
    c, 'new_booking',
    'حجز جديد', 'New Booking',
    `${c.clientName} حجز معك جلسة ${arW} — بانتظار تأكيد الدفع`.replace(/\s+/g, ' '),
    `${c.clientName} booked a session with you ${enW} — awaiting payment confirmation`.replace(/\s+/g, ' '),
    'awaiting_payment',
  );
}

/**
 * Plan for the status-changed transition (status differs).
 * Returns { notifications: [spec] } where spec.role is 'therapist'|'client'.
 * The paid-pending → confirmed server update is decided separately by
 * shouldAutoConfirm.
 */
function planStatusNotifications(before, after, bookingId) {
  const c = ctx(after, bookingId);
  const out = [];
  const s = after.status;

  if (s === 'confirmed' && c.therapistId) {
    const arW = c.ar ? `يوم ${c.ar.date} الساعة ${c.ar.time} بتوقيت السودان` : '';
    const enW = c.en ? `on ${c.en.date} at ${c.en.time} Sudan time` : '';
    out.push(therapistSpec(
      c, 'booking_confirmed',
      'جلسة مؤكدة', 'Session Confirmed',
      `جلسة مؤكدة: ${c.clientName} ${arW}`.trim(),
      `Session confirmed: ${c.clientName} ${enW}`.trim(),
      'confirmed',
    ));
  }

  if ((s === 'cancelled' || s === 'rejected') && c.therapistId) {
    const notified = !!(before.therapist_notified_at || after.therapist_notified_at);
    const paidish = before.payment_status === 'bank_transfer_pending' || before.payment_status === 'paid';
    if (notified || paidish) {
      const arW = c.ar ? `يوم ${c.ar.date} الساعة ${c.ar.time}` : '';
      const enW = c.en ? `on ${c.en.date} at ${c.en.time}` : '';
      out.push(therapistSpec(
        c, 'booking_cancelled',
        'جلسة ملغاة', 'Session Cancelled',
        `الجلسة مع ${c.clientName} ${arW} ملغاة — لا توجد جلسة`.replace(/\s+/g, ' '),
        `The session with ${c.clientName} ${enW} is cancelled — no session`.replace(/\s+/g, ' '),
        s,
      ));
    }
  }

  return out;
}

/** Paid bookings auto-confirm: pending + paid. */
function shouldAutoConfirm(after) {
  return after.status === 'pending' && after.payment_status === 'paid';
}

/** True when payment_status newly became bank_transfer_pending. */
function becameBankTransferPending(before, after) {
  return before.payment_status !== 'bank_transfer_pending' &&
    after.payment_status === 'bank_transfer_pending' &&
    !after.therapist_notified_at;
}

/**
 * Does `other` (an existing booking doc) block the slot for a new booking?
 * Same therapist + same scheduled_time is assumed to be pre-filtered by query.
 */
function blocksSlot(other, nowMs) {
  if (other.status === 'pending' || other.status === 'confirmed') return true;
  if (other.status === 'awaiting_payment') {
    if (other.payment_status === 'bank_transfer_pending') return true;
    const dl = toDate(other.payment_deadline);
    return !!dl && dl.getTime() > nowMs;
  }
  return false;
}

/** True when `other` was created before the new booking (doc id breaks ties). */
function createdEarlier(other, otherId, mine, myId) {
  const o = toDate(other.created_at);
  const m = toDate(mine.created_at);
  if (o && m && o.getTime() !== m.getTime()) return o.getTime() < m.getTime();
  return otherId < myId;
}

/**
 * Decide the fate of a newly created booking against the bookings already on
 * the same therapist slot. `others` is [{ id, data }]. Only earlier bookings
 * can block, so of two racing bookings the earlier one wins. A same-client
 * abandoned card checkout is superseded instead of blocking; supersedeIds is
 * empty when the new booking is blocked.
 */
function resolveSlotClash(booking, bookingId, others, nowMs) {
  const supersedeIds = [];
  for (const { id, data } of others) {
    if (id === bookingId || !createdEarlier(data, id, booking, bookingId)) continue;
    const abandonedRetry = !!booking.client_id && data.client_id === booking.client_id &&
      data.status === 'awaiting_payment' && data.payment_status === 'awaiting_payment';
    if (abandonedRetry) {
      supersedeIds.push(id);
    } else if (blocksSlot(data, nowMs)) {
      return { blocked: true, supersedeIds: [] };
    }
  }
  return { blocked: false, supersedeIds };
}

const PLACEHOLDER_NAMES = new Set(['user', 'unknown user', 'therapist']);

function realName(v) {
  if (typeof v !== 'string') return null;
  const t = v.trim();
  return t && !PLACEHOLDER_NAMES.has(t.toLowerCase()) ? t : null;
}

function therapistChatId(booking) {
  return booking.therapist_id && booking.client_id
    ? `${booking.therapist_id}_${booking.client_id}` : null;
}

/**
 * Fields for a brand-new therapist_chats doc, matching what the app writes in
 * TherapistChatService.getOrCreateChat. Timestamps are added by the caller.
 * user_access starts 'none'; the access stamper sets 'full' once paid.
 * Placeholder or missing names are left out rather than written.
 */
function buildTherapistChatDoc(booking, bookingId) {
  const doc = {
    chat_id: therapistChatId(booking),
    therapist_id: booking.therapist_id,
    user_id: booking.client_id,
  };
  const tName = realName(booking.therapist_name);
  const uName = realName(booking.client_name);
  if (tName) doc.therapist_name = tName;
  if (uName) doc.user_name = uName;
  if (bookingId) {
    doc.booking_id = bookingId;
    doc.booking_ids = [bookingId];
  } else {
    doc.booking_ids = [];
  }
  Object.assign(doc, {
    status: 'active', source: 'booking', user_access: 'none',
    unread_count_therapist: 0, unread_count_user: 0,
    typing: { therapist: false, user: false },
  });
  return doc;
}

function clientConfirmedBodies(after) {
  const ar = formatSessionAr(after.scheduled_time);
  const en = formatSessionEn(after.scheduled_time);
  const name = after.therapist_name || 'المعالج';
  return {
    arBody: `تم قبول طلب الحجز مع ${name}${ar ? ' يوم ' + ar.date + ' الساعة ' + ar.time + ' بتوقيت السودان' : ''}`,
    enBody: `Your booking with ${name} has been confirmed${en ? ' on ' + en.date + ' at ' + en.time + ' Sudan time' : ''}`,
  };
}

function reminderTherapistSpec(booking, bookingId) {
  const c = ctx(booking, bookingId);
  return therapistSpec(
    c, 'booking_reminder',
    'تذكير بجلسة قادمة', 'Upcoming Session Reminder',
    `لديك جلسة الساعة ${c.ar ? c.ar.time : ''} بتوقيت السودان مع ${c.clientName}`,
    `You have a session at ${c.en ? c.en.time : ''} Sudan time with ${c.clientName}`,
    booking.status,
  );
}

// Auto-cancels from the slot guard happen while the patient is mid-rebooking,
// so the client must not get a "booking cancelled" notice for them.
function suppressClientCancelNotice(after) {
  return after.status === 'cancelled' &&
    (after.cancellation_reason === 'superseded' ||
      after.cancellation_reason === 'slot_taken');
}

module.exports = {
  suppressClientCancelNotice,
  planStatusNotifications, shouldAutoConfirm, becameBankTransferPending,
  bankTransferTherapistSpec, blocksSlot, resolveSlotClash, clientConfirmedBodies,
  reminderTherapistSpec, buildTherapistChatDoc, therapistChatId,
};
