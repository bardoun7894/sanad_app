'use strict';

/**
 * Deterministic, NON-AI user report. Used by generateUserReport when the user
 * has not given the current AI privacy consent. Pure function: no I/O.
 */

const MOOD_KEYS = ['happy', 'calm', 'anxious', 'sad', 'angry', 'tired'];

const T = {
  ar: {
    title: 'تقرير أساسي للمستخدم',
    period: (d) => `الفترة: آخر ${d} يوماً`,
    mood: 'المزاج', moodCount: 'عدد التسجيلات', moodAvg: 'متوسط الدرجة (من 0 إلى 5)', moodTop: 'الأكثر تكراراً',
    trend: 'الاتجاه الأسبوعي', week: 'الأسبوع', entries: 'تسجيلات', none: 'لا توجد بيانات',
    tests: 'الاختبارات النفسية', bookings: 'الحجوزات', total: 'الإجمالي', activity: 'النشاط في التطبيق',
    subscription: 'حالة الاشتراك', unknown: 'غير معروفة',
    moods: { happy: 'سعيد', calm: 'هادئ', anxious: 'قلق', sad: 'حزين', angry: 'غاضب', tired: 'متعب' },
    score: 'الدرجة',
  },
  en: {
    title: 'Basic User Report',
    period: (d) => `Period: last ${d} days`,
    mood: 'Mood', moodCount: 'Entries', moodAvg: 'Average score (0 to 5)', moodTop: 'Most frequent',
    trend: 'Weekly trend', week: 'Week', entries: 'entries', none: 'No data',
    tests: 'Psychological tests', bookings: 'Bookings', total: 'Total', activity: 'App activity',
    subscription: 'Subscription state', unknown: 'unknown',
    moods: { happy: 'Happy', calm: 'Calm', anxious: 'Anxious', sad: 'Sad', angry: 'Angry', tired: 'Tired' },
    score: 'score',
  },
  fr: {
    title: 'Rapport utilisateur de base',
    period: (d) => `Période : ${d} derniers jours`,
    mood: 'Humeur', moodCount: 'Entrées', moodAvg: 'Score moyen (0 à 5)', moodTop: 'Les plus fréquentes',
    trend: 'Tendance hebdomadaire', week: 'Semaine', entries: 'entrées', none: 'Aucune donnée',
    tests: 'Tests psychologiques', bookings: 'Réservations', total: 'Total', activity: "Activité dans l'application",
    subscription: "État de l'abonnement", unknown: 'inconnu',
    moods: { happy: 'Heureux', calm: 'Calme', anxious: 'Anxieux', sad: 'Triste', angry: 'En colère', tired: 'Fatigué' },
    score: 'score',
  },
};

function weekStart(iso) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  const day = (d.getUTCDay() + 6) % 7; // Monday = 0
  d.setUTCDate(d.getUTCDate() - day);
  return d.toISOString().split('T')[0];
}

/**
 * @param {object} p
 * @param {string} [p.locale] ar | en | fr
 * @param {number} [p.rangeDays]
 * @param {{mood:number,date:string}[]} [p.moods] mood 0-5, date ISO string
 * @param {{type:string,score:number,interpretation:string,date:string}[]} [p.tests]
 * @param {Object<string,number>} [p.bookingsByStatus]
 * @param {Object<string,number>} [p.activityCounts]
 * @param {string|object|null} [p.subscription]
 * @returns {string} markdown
 */
function buildBasicUserReport(p = {}) {
  const t = T[p.locale] || T.ar;
  const rangeDays = p.rangeDays || 90;
  const moods = (p.moods || []).filter(m => Number.isInteger(m.mood) && m.mood >= 0 && m.mood < MOOD_KEYS.length);
  const tests = p.tests || [];
  const bookings = p.bookingsByStatus || {};
  const activity = p.activityCounts || {};
  const L = [];

  L.push(`# ${t.title}`, '', t.period(rangeDays), '');

  L.push(`## ${t.mood}`, '');
  if (!moods.length) {
    L.push(`- ${t.none}`);
  } else {
    const avg = moods.reduce((s, m) => s + m.mood, 0) / moods.length;
    const freq = {};
    moods.forEach(m => { freq[m.mood] = (freq[m.mood] || 0) + 1; });
    const top = Object.entries(freq).sort((a, b) => b[1] - a[1] || a[0] - b[0]).slice(0, 3)
      .map(([i, c]) => `${t.moods[MOOD_KEYS[i]]} (${c})`).join(t === T.ar ? '، ' : ', ');
    L.push(`- ${t.moodCount}: ${moods.length}`, `- ${t.moodAvg}: ${avg.toFixed(2)}`, `- ${t.moodTop}: ${top}`, '', `### ${t.trend}`, '');
    const weeks = {};
    moods.forEach(m => {
      const w = weekStart(m.date);
      if (!w) return;
      (weeks[w] = weeks[w] || []).push(m.mood);
    });
    Object.keys(weeks).sort().forEach(w => {
      const v = weeks[w];
      L.push(`- ${t.week} ${w}: ${(v.reduce((a, b) => a + b, 0) / v.length).toFixed(2)} (${v.length} ${t.entries})`);
    });
  }
  L.push('');

  L.push(`## ${t.tests}`, '');
  if (!tests.length) L.push(`- ${t.none}`);
  else tests.forEach(x => L.push(`- ${x.date || ''} ${x.type}: ${t.score} ${x.score}${x.interpretation ? ' — ' + x.interpretation : ''}`));
  L.push('');

  L.push(`## ${t.bookings}`, '');
  const bEntries = Object.entries(bookings);
  if (!bEntries.length) L.push(`- ${t.none}`);
  else {
    L.push(`- ${t.total}: ${bEntries.reduce((s, [, c]) => s + c, 0)}`);
    bEntries.forEach(([k, c]) => L.push(`- ${k}: ${c}`));
  }
  L.push('');

  L.push(`## ${t.activity}`, '');
  const aEntries = Object.entries(activity);
  if (!aEntries.length) L.push(`- ${t.none}`);
  else aEntries.forEach(([k, c]) => L.push(`- ${k}: ${c}`));
  L.push('');

  const sub = p.subscription;
  const subText = sub == null ? t.unknown
    : typeof sub === 'string' ? sub
      : (sub.status || sub.plan || sub.tier || JSON.stringify(sub));
  L.push(`## ${t.subscription}`, '', `- ${subText}`, '');

  return L.join('\n');
}

module.exports = { buildBasicUserReport };
