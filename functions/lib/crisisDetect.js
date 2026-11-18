'use strict';

// Server-side crisis detection for AI chat messages (owner request 2026-11-17:
// a client's suicidal message must reach the admin dashboard at once).
// Runs on every chatWithGemini call, so it covers every installed app build.
// Errs on the side of flagging: a false alarm costs an admin a look, a miss costs more.

const AR_DIACRITICS = /[ً-ٰٟـ]/g; // harakat, superscript alef, tatweel

function normalize(text) {
  return String(text || '')
    .toLowerCase()
    .replace(AR_DIACRITICS, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي')
    .replace(/\s+/g, ' ')
    .trim();
}

// Phrases are stored already normalized (see normalize()).
const CRISIS_PHRASES = [
  // Arabic: MSA and Sudanese / Egyptian / Gulf / Levantine / Maghrebi forms
  'انتحار', 'انتحر', 'انتحاري', 'انتحاريه',
  'اقتل نفسي', 'قتل نفسي', 'اموت نفسي', 'اشنق نفسي', 'ارمي نفسي',
  'اذي نفسي', 'اذيه نفسي', 'اذيت نفسي', 'ايذاء نفسي', 'ايذاء النفس', 'اذاء نفسي',
  'جرح نفسي', 'اجرح نفسي', 'قطع شرايين', 'اقطع شرايين', 'شراييني',
  'انهي حياتي', 'انهاء حياتي', 'اخلص من حياتي', 'اخلص علي نفسي', 'انهي نفسي',
  'اريد الموت', 'اريد ان اموت', 'اريد اموت', 'ابي اموت', 'ابغي اموت', 'ابغا اموت',
  'بدي موت', 'بدي اموت', 'عايز اموت', 'عايزه اموت', 'عاوز اموت', 'عاوزه اموت',
  'داير اموت', 'دايره اموت', 'بغيت نموت', 'بغيت اموت', 'نفسي اموت',
  'افكر اموت', 'بفكر اموت', 'افكر في الموت', 'بفكر في الموت',
  'اتمني الموت', 'اتمني اموت', 'الموت ارحم', 'احسن لو مت', 'افضل لو كنت ميت',
  'لا اريد ان اعيش', 'لا اريد العيش', 'ما بدي عيش', 'مابدي عيش', 'ما عايز اعيش',
  'ماعايز اعيش', 'مش عايز اعيش', 'مش عاوز اعيش', 'ما داير اعيش', 'ماداير اعيش',
  'جرعه زائده', 'جرعه زايده', 'حبوب منومه',
  // English
  'suicid', 'kill myself', 'end my life', 'want to die', 'wanna die',
  "don't want to live", 'dont want to live', 'hurt myself', 'self harm', 'self-harm',
  'cut myself', 'cutting myself', 'overdose', 'better off dead', 'end it all',
  'ending it all', 'hang myself', 'take my life', 'no reason to live',
  // French
  'me tuer', 'envie de mourir', 'veux mourir', 'plus envie de vivre',
  'me faire du mal', 'automutilation', 'mettre fin à mes jours', 'en finir avec la vie',
  'me pendre',
];

/** @returns {{ isCrisis: boolean, matched: string[] }} */
function detectCrisis(text) {
  const t = normalize(text);
  if (!t) return { isCrisis: false, matched: [] };
  const matched = CRISIS_PHRASES.filter((p) => t.includes(p));
  return { isCrisis: matched.length > 0, matched };
}

/** Same user + same text within the window = the alert already exists (client or server wrote it). */
function isDuplicateAlert(existing, text, nowMs, windowMs = 10 * 60 * 1000) {
  const key = normalize(text);
  return (existing || []).some((a) => {
    const at = a.created_at && typeof a.created_at.toMillis === 'function'
      ? a.created_at.toMillis()
      : (a.created_at instanceof Date ? a.created_at.getTime() : 0);
    return normalize(a.triggered_text) === key && nowMs - at < windowMs;
  });
}

function contactOf(user) {
  const u = user || {};
  const name = u.name || u.full_name ||
    [u.first_name, u.last_name].filter(Boolean).join(' ') || '';
  return {
    name: String(name).trim(),
    phone: String(u.phone || u.phone_number || u.whatsapp || '').trim(),
    email: String(u.email || '').trim(),
  };
}

/** Admin notification text: who, how to reach them, and what they wrote. */
function buildCrisisAdminMessage({ contact, text, severity = 'critical' }) {
  const c = contact || {};
  const excerpt = String(text || '').trim().slice(0, 300);
  const who = c.name || 'مستخدم';
  const reach = [c.phone, c.email].filter(Boolean).join(' • ');
  const whoEn = c.name || 'A user';
  return {
    title: severity === 'critical'
      ? 'تنبيه خطر: رسالة عن الانتحار أو إيذاء النفس'
      : 'تنبيه: رسالة ضيق شديد',
    body: `${who}${reach ? ` (${reach})` : ''} كتب في دردشة الذكاء الاصطناعي: «${excerpt}». تواصل معه فوراً.`,
    titleEn: severity === 'critical'
      ? 'Danger alert: suicide or self-harm message'
      : 'Alert: severe distress message',
    bodyEn: `${whoEn}${reach ? ` (${reach})` : ''} wrote in the AI chat: "${excerpt}". Contact them now.`,
  };
}

module.exports = {
  normalize,
  detectCrisis,
  isDuplicateAlert,
  contactOf,
  buildCrisisAdminMessage,
  CRISIS_PHRASES,
};
