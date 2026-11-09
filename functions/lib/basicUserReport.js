'use strict';

/**
 * Patient-facing psychological report in six fixed sections. Pure: no I/O.
 *
 * buildBasicUserReport: full deterministic report, used when the user has
 * not given the current AI consent (mood, tests and engagement only).
 * buildReportHeader / SECTION_TITLES: shared with the AI report so both
 * paths have the same title, period line and section names.
 *
 * Markdown is limited to #, ##, ###, "- " bullets and **bold** so the
 * admin PDF export can render it.
 */

const T = {
  ar: {
    title: 'التقرير النفسي',
    period: (a, b, d) => `**الفترة:** من ${a} إلى ${b} (${d} يوماً)`,
    generated: (g) => `**تاريخ الإصدار:** ${g}`,
    sections: ['الملخص السريري', 'أنماط المزاج', 'نتائج الاختبارات النفسية', 'تقييم المخاطر', 'مستوى التفاعل مع التطبيق', 'التوصيات'],
    noConsent: 'لم تتم الموافقة على مشاركة البيانات التفصيلية للتحليل، لذلك يقتصر هذا التقرير على المزاج اليومي ونتائج الاختبارات ومستوى التفاعل مع التطبيق.',
    moods: { happy: 'سعيد', calm: 'هادئ', anxious: 'قلق', sad: 'حزين', angry: 'غاضب', tired: 'متعب' },
    risk: { low: 'منخفض', moderate: 'متوسط', high: 'مرتفع', critical: 'مرتفع جداً', unknown: 'غير محدد (لا توجد بيانات مزاج كافية)' },
    dir: { improving: 'تحسن', declining: 'تراجع', stable: 'استقرار', insufficient: 'بيانات غير كافية لتحديد الاتجاه' },
    sep: '، ',
    noMood: 'لم تُسجَّل أي حالة مزاجية خلال هذه الفترة.',
    moodCount: (n, d) => `عدد تسجيلات المزاج: ${n} (في ${d} يوماً)`,
    moodAvg: (s) => `متوسط المزاج: ${s} من 5 (5 = أفضل حالة)`,
    moodTop: 'الحالات الأكثر تكراراً',
    moodDir: 'اتجاه المزاج خلال الفترة',
    weekly: 'المتوسط الأسبوعي',
    week: (w, a, n) => `أسبوع ${w}: ${a} من 5 (${n} تسجيل)`,
    noTests: 'لم تُجرَ أي اختبارات نفسية خلال هذه الفترة.',
    testLine: (t) => `${t.date}: ${t.type}، الدرجة ${t.score}${t.interpretation ? '، ' + t.interpretation : ''}`,
    riskLevel: 'مستوى الخطر الحالي',
    lowStreak: (n) => `آخر ${n} تسجيلات متتالية كانت مزاجاً منخفضاً (حزين أو غاضب أو متعب).`,
    clinicalNote: 'ملاحظة سريرية',
    riskNote: {
      low: 'المؤشرات المتاحة لا تُظهر علامات خطر واضحة.',
      moderate: 'توجد مؤشرات تستدعي المتابعة المنتظمة.',
      high: 'المؤشرات تستدعي متابعة قريبة مع المعالج.',
      critical: 'المؤشرات تستدعي تواصلاً عاجلاً مع المعالج.',
      unknown: 'لا يمكن تقييم الخطر بدقة بسبب قلة تسجيلات المزاج.',
    },
    engagement: (a, d, p) => `أيام النشاط في التطبيق: ${a} من ${d} يوماً (${p}%)`,
    engagementWord: (p) => p >= 70 ? 'تفاعل منتظم' : p >= 30 ? 'تفاعل متوسط' : 'تفاعل منخفض',
    summary: (m, risk, dir) => m.moodCount
      ? `خلال هذه الفترة سُجِّل المزاج ${m.moodCount} مرة، وكانت الحالة الغالبة "${m.dominantMood}"، بمتوسط ${m.avgScore.toFixed(1)} من 5. اتجاه المزاج: ${dir}. مستوى الخطر الحالي: ${risk}. ${m.tests.length ? `أُجري ${m.tests.length} اختبار نفسي.` : 'لم تُجرَ اختبارات نفسية.'}`
      : `لم تُسجَّل حالات مزاجية خلال هذه الفترة${m.tests.length ? `، وأُجري ${m.tests.length} اختبار نفسي` : ''}. نسبة أيام النشاط في التطبيق ${m.engagementPct}%.`,
    rec: {
      logMood: 'تسجيل المزاج يومياً من التطبيق، حتى يكون التقرير القادم أدق.',
      takeTest: 'إجراء اختبار نفسي من قسم الاختبارات (مثل القلق أو الاكتئاب) لمتابعة التغيّر.',
      contact: 'التواصل مع المعالج في أقرب وقت لمراجعة الحالة.',
      session: 'حجز جلسة متابعة مع المعالج.',
      keep: 'الاستمرار على الروتين الحالي، والاستفادة من تمارين الاسترخاء والتنفس في التطبيق.',
      engage: 'زيادة استخدام التطبيق يومياً (تسجيل المزاج، التمارين، المقالات).',
    },
  },
  en: {
    title: 'Psychological Report',
    period: (a, b, d) => `**Period:** ${a} to ${b} (${d} days)`,
    generated: (g) => `**Issued:** ${g}`,
    sections: ['Clinical Summary', 'Mood Patterns', 'Psychological Test Results', 'Risk Assessment', 'App Engagement', 'Recommendations'],
    noConsent: 'Consent to share detailed data for analysis was not given, so this report covers daily mood, test results and app engagement only.',
    moods: { happy: 'happy', calm: 'calm', anxious: 'anxious', sad: 'sad', angry: 'angry', tired: 'tired' },
    risk: { low: 'low', moderate: 'moderate', high: 'high', critical: 'very high', unknown: 'not determined (not enough mood data)' },
    dir: { improving: 'improving', declining: 'declining', stable: 'stable', insufficient: 'not enough data to tell' },
    sep: ', ',
    noMood: 'No mood was logged in this period.',
    moodCount: (n, d) => `Mood entries: ${n} (on ${d} days)`,
    moodAvg: (s) => `Average mood: ${s} out of 5 (5 = best)`,
    moodTop: 'Most frequent moods',
    moodDir: 'Mood direction over the period',
    weekly: 'Weekly average',
    week: (w, a, n) => `Week of ${w}: ${a} out of 5 (${n} entries)`,
    noTests: 'No psychological tests were taken in this period.',
    testLine: (t) => `${t.date}: ${t.type}, score ${t.score}${t.interpretation ? ', ' + t.interpretation : ''}`,
    riskLevel: 'Current risk level',
    lowStreak: (n) => `The last ${n} entries in a row were low moods (sad, angry or tired).`,
    clinicalNote: 'Clinical note',
    riskNote: {
      low: 'The available indicators show no clear warning signs.',
      moderate: 'Some indicators call for regular follow-up.',
      high: 'The indicators call for close follow-up with the therapist.',
      critical: 'The indicators call for urgent contact with the therapist.',
      unknown: 'Risk cannot be assessed reliably because few moods were logged.',
    },
    engagement: (a, d, p) => `Active days in the app: ${a} of ${d} (${p}%)`,
    engagementWord: (p) => p >= 70 ? 'regular engagement' : p >= 30 ? 'moderate engagement' : 'low engagement',
    summary: (m, risk, dir) => m.moodCount
      ? `Mood was logged ${m.moodCount} times in this period, mostly "${m.dominantMood}", averaging ${m.avgScore.toFixed(1)} out of 5. Direction: ${dir}. Current risk level: ${risk}. ${m.tests.length ? `${m.tests.length} psychological test(s) taken.` : 'No psychological tests taken.'}`
      : `No mood was logged in this period${m.tests.length ? `; ${m.tests.length} psychological test(s) taken` : ''}. Active on ${m.engagementPct}% of days.`,
    rec: {
      logMood: 'Log mood daily in the app so the next report is more accurate.',
      takeTest: 'Take a psychological test (for example anxiety or depression) to track change.',
      contact: 'Contact the therapist soon to review the situation.',
      session: 'Book a follow-up session with the therapist.',
      keep: 'Keep the current routine and use the relaxation and breathing exercises in the app.',
      engage: 'Use the app more often (mood log, exercises, articles).',
    },
  },
  fr: {
    title: 'Rapport psychologique',
    period: (a, b, d) => `**Période :** du ${a} au ${b} (${d} jours)`,
    generated: (g) => `**Émis le :** ${g}`,
    sections: ['Résumé clinique', "Profil de l'humeur", 'Résultats des tests psychologiques', 'Évaluation des risques', "Engagement dans l'application", 'Recommandations'],
    noConsent: "Le partage des données détaillées pour analyse n'a pas été accepté ; ce rapport se limite à l'humeur quotidienne, aux tests et à l'engagement.",
    moods: { happy: 'heureux', calm: 'calme', anxious: 'anxieux', sad: 'triste', angry: 'en colère', tired: 'fatigué' },
    risk: { low: 'faible', moderate: 'modéré', high: 'élevé', critical: 'très élevé', unknown: "non déterminé (pas assez de données d'humeur)" },
    dir: { improving: 'amélioration', declining: 'dégradation', stable: 'stable', insufficient: 'données insuffisantes' },
    sep: ', ',
    noMood: "Aucune humeur enregistrée sur cette période.",
    moodCount: (n, d) => `Entrées d'humeur : ${n} (sur ${d} jours)`,
    moodAvg: (s) => `Humeur moyenne : ${s} sur 5 (5 = meilleure)`,
    moodTop: 'Humeurs les plus fréquentes',
    moodDir: "Tendance de l'humeur",
    weekly: 'Moyenne hebdomadaire',
    week: (w, a, n) => `Semaine du ${w} : ${a} sur 5 (${n} entrées)`,
    noTests: 'Aucun test psychologique sur cette période.',
    testLine: (t) => `${t.date} : ${t.type}, score ${t.score}${t.interpretation ? ', ' + t.interpretation : ''}`,
    riskLevel: 'Niveau de risque actuel',
    lowStreak: (n) => `Les ${n} dernières entrées consécutives étaient des humeurs basses (triste, en colère ou fatigué).`,
    clinicalNote: 'Note clinique',
    riskNote: {
      low: "Les indicateurs disponibles ne montrent pas de signe d'alerte clair.",
      moderate: 'Certains indicateurs demandent un suivi régulier.',
      high: 'Les indicateurs demandent un suivi rapproché avec le thérapeute.',
      critical: 'Les indicateurs demandent un contact urgent avec le thérapeute.',
      unknown: "Le risque ne peut pas être évalué faute d'entrées d'humeur.",
    },
    engagement: (a, d, p) => `Jours actifs dans l'application : ${a} sur ${d} (${p} %)`,
    engagementWord: (p) => p >= 70 ? 'engagement régulier' : p >= 30 ? 'engagement moyen' : 'engagement faible',
    summary: (m, risk, dir) => m.moodCount
      ? `L'humeur a été enregistrée ${m.moodCount} fois, surtout « ${m.dominantMood} », moyenne ${m.avgScore.toFixed(1)} sur 5. Tendance : ${dir}. Risque actuel : ${risk}. ${m.tests.length ? `${m.tests.length} test(s) psychologique(s).` : 'Aucun test psychologique.'}`
      : `Aucune humeur enregistrée sur cette période${m.tests.length ? ` ; ${m.tests.length} test(s) psychologique(s)` : ''}. Actif ${m.engagementPct} % des jours.`,
    rec: {
      logMood: "Enregistrer l'humeur chaque jour dans l'application pour un prochain rapport plus précis.",
      takeTest: "Passer un test psychologique (anxiété, dépression) pour suivre l'évolution.",
      contact: 'Contacter le thérapeute rapidement pour faire le point.',
      session: 'Réserver une séance de suivi avec le thérapeute.',
      keep: "Garder la routine actuelle et utiliser les exercices de relaxation et de respiration de l'application.",
      engage: "Utiliser l'application plus souvent (humeur, exercices, articles).",
    },
  },
};

function strings(locale) {
  return T[locale] || T.ar;
}

const SECTION_TITLES = Object.fromEntries(Object.entries(T).map(([k, v]) => [k, v.sections]));

/** Title + period + issue date, identical for AI and non-AI reports. */
function buildReportHeader({ locale, range, generatedIso }) {
  const t = strings(locale);
  return [`# ${t.title}`, '', t.period(range.startIso, range.endIso, range.days), '', t.generated(generatedIso), ''].join('\n');
}

/**
 * @param {object} p
 * @param {string} [p.locale] ar | en | fr
 * @param {{startIso:string,endIso:string,days:number}} p.range
 * @param {object} p.metrics  output of reportMetrics.computeReportMetrics
 * @param {string} p.generatedIso YYYY-MM-DD
 * @param {boolean} [p.consentMissing] false hides the "no consent" note (AI was allowed but unavailable)
 * @returns {string} markdown
 */
function buildBasicUserReport(p) {
  const t = strings(p.locale);
  const m = p.metrics;
  const fmt = (x) => x.toFixed(1);
  const moodName = (k) => t.moods[k] || k;
  const risk = t.risk[m.riskLevel] || m.riskLevel;
  const dir = t.dir[m.direction] || m.direction;
  const [S1, S2, S3, S4, S5, S6] = t.sections;
  const L = [buildReportHeader({ locale: p.locale, range: p.range, generatedIso: p.generatedIso })];

  if (p.consentMissing !== false) L.push(`> ${t.noConsent}`, '');

  L.push(`## 1. ${S1}`, '', t.summary({ ...m, dominantMood: moodName(m.dominantMood) }, risk, dir), '');

  L.push(`## 2. ${S2}`, '');
  if (!m.moodCount) {
    L.push(t.noMood);
  } else {
    const top = Object.entries(m.distribution).sort((a, b) => b[1] - a[1]).slice(0, 3)
      .map(([k, c]) => `${moodName(k)} (${c})`).join(t.sep);
    L.push(`- ${t.moodCount(m.moodCount, m.moodDays)}`, `- ${t.moodAvg(fmt(m.avgScore))}`,
      `- ${t.moodTop}: ${top}`, `- ${t.moodDir}: ${dir}`, '', `### ${t.weekly}`, '');
    m.weekly.forEach(w => L.push(`- ${t.week(w.week, fmt(w.avg), w.count)}`));
  }
  L.push('');

  L.push(`## 3. ${S3}`, '');
  if (!m.tests.length) L.push(t.noTests);
  else m.tests.forEach(x => L.push(`- ${t.testLine(x)}`));
  L.push('');

  L.push(`## 4. ${S4}`, '', `- **${t.riskLevel}:** ${risk}`, `- ${t.moodDir}: ${dir}`);
  if (m.lowStreak >= 3) L.push(`- ${t.lowStreak(m.lowStreak)}`);
  L.push(`- **${t.clinicalNote}:** ${t.riskNote[m.riskLevel] || t.riskNote.unknown}`, '');

  L.push(`## 5. ${S5}`, '', `- ${t.engagement(m.activeDays, m.daysInRange, m.engagementPct)}: ${t.engagementWord(m.engagementPct)}`, '');

  const recs = [];
  if (m.riskLevel === 'critical' || m.riskLevel === 'high') recs.push(t.rec.contact);
  else if (m.riskLevel === 'moderate' || m.direction === 'declining') recs.push(t.rec.session);
  if (m.moodDays < Math.min(7, m.daysInRange)) recs.push(t.rec.logMood);
  if (!m.tests.length) recs.push(t.rec.takeTest);
  if (m.engagementPct < 30) recs.push(t.rec.engage);
  if (m.riskLevel === 'low' && m.direction !== 'declining') recs.push(t.rec.keep);
  L.push(`## 6. ${S6}`, '');
  recs.forEach(r => L.push(`- ${r}`));
  L.push('');

  return L.join('\n');
}

module.exports = { buildBasicUserReport, buildReportHeader, SECTION_TITLES };
