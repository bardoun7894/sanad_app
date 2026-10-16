/**
 * Formats a booking's scheduled_time as Gregorian date + time in Sudan time.
 * The Cloud Functions runtime is UTC, so the zone is always explicit.
 * 'ar-EG' (not ar-SA, which yields Hijri) with latin digits forced.
 */
'use strict';

const TZ = 'Africa/Khartoum';

function toDate(value) {
  if (!value) return null;
  const d = typeof value.toDate === 'function' ? value.toDate() : new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

function fmt(locale, opts, d) {
  return new Intl.DateTimeFormat(locale, { timeZone: TZ, ...opts }).format(d);
}

/** @returns {{date:string,time:string,full:string}|null} */
function formatSessionAr(value) {
  const d = toDate(value);
  if (!d) return null;
  const loc = 'ar-EG-u-nu-latn';
  const date = fmt(loc, { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }, d)
    .replace('،', '');
  const time = fmt(loc, { hour: 'numeric', minute: '2-digit', hour12: true }, d);
  return { date, time, full: `${date} الساعة ${time} بتوقيت السودان` };
}

/** @returns {{date:string,time:string,full:string}|null} */
function formatSessionEn(value) {
  const d = toDate(value);
  if (!d) return null;
  const date = fmt('en-US', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }, d);
  const time = fmt('en-US', { hour: 'numeric', minute: '2-digit', hour12: true }, d);
  return { date, time, full: `${date} at ${time} Sudan time` };
}

module.exports = { formatSessionAr, formatSessionEn, toDate, TZ };
