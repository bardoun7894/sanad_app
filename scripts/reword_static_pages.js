// Reword static_pages (about_us, know_your_rights, privacy_policy, terms_of_service):
// no psychological/therapy wording; coach / counselor (مدرب / مستشار).
// Usage: node reword_pages.js <firebase-admin path> <pages dir> [--apply]
const fs = require('fs');
const path = require('path');
const [adminPath, dir, flag] = process.argv.slice(2);
const APPLY = flag === '--apply';

const AR = [
  // about_us
  ['سند ثيرابي – دعم نفسي أقرب إليك', 'سند – دعم وإرشاد أقرب إليك'],
  ['متخصصة في تقديم خدمات الدعم النفسي عن بُعد، تهدف إلى جعل العناية بالصحة النفسية أكثر', 'متخصصة في تقديم خدمات الإرشاد والتدريب الشخصي عن بُعد، تهدف إلى جعل العناية بجودة الحياة والتوازن الشخصي أكثر'],
  ['بمعالجين نفسيين مؤهلين ومستقلين', 'بمدربين ومستشارين مؤهلين ومستقلين'],
  ['للدعم النفسي الرقمي، وأن نساهم في بناء مجتمع أكثر وعيًا واهتمامًا بالصحة النفسية', 'للدعم والإرشاد الرقمي، وأن نساهم في بناء مجتمع أكثر وعيًا واهتمامًا بجودة الحياة'],
  ['تقديم خدمات دعم نفسي مهنية', 'تقديم خدمات إرشاد وتدريب مهنية'],
  ['جودة حياتهم النفسية', 'جودة حياتهم'],
  ['جلسات دعم نفسي عن بُعد مع معالجين مؤهلين ومرخصين', 'جلسات إرشاد وتدريب عن بُعد مع مدربين ومستشارين مؤهلين ومعتمدين'],
  ['مع معالجين نفسيين لتقديم', 'مع مدربين ومستشارين لتقديم'],
  ['محتوى نفسي تثقيفي', 'محتوى تثقيفي'],
  // know_your_rights
  ['للدعم النفسي)', 'للإرشاد والتدريب)'],
  ['المرتبطة بالصحة النفسية التي', 'المرتبطة بالحالة المزاجية والعافية الشخصية التي'],
  ['علاقتك المباشرة بمعالجك', 'علاقتك المباشرة بمستشارك'],
  ['حقوقك أثناء الجلسة النفسية', 'حقوقك أثناء الجلسة'],
  ['علاقتك بمعالجك تقوم', 'علاقتك بمستشارك تقوم'],
  ['يلتزم معالجك', 'يلتزم مستشارك'],
  ['من معالجك الحياد', 'من مستشارك الحياد'],
  ['المنهجية العلاجية التي يتبعها معالجك', 'المنهجية التي يتبعها مستشارك'],
  ['من أن معالجك لا', 'من أن مستشارك لا'],
  ['اختيار معالجك بناءً', 'اختيار مستشارك بناءً'],
  ['تغيير معالجك في', 'تغيير مستشارك في'],
  ['الترخيص المهني لمعالجك', 'الاعتماد المهني لمستشارك'],
  ['مع معالجك على أهداف الجلسات والمسار العلاجي', 'مع مستشارك على أهداف الجلسات ومسار الإرشاد'],
  ['معالجك ملزم بإرشادك', 'مستشارك ملزم بإرشادك'],
  ['حق تقديم الشكوى ضد المعالج', 'حق تقديم الشكوى ضد المدرب أو المستشار'],
  ['إفصاح المعالج عن', 'إفصاح المستشار عن'],
  ['لا صلة لها بالعلاج أو الخدمة', 'لا صلة لها بالخدمة'],
  ['عن المعالج المشتكى عليه', 'عن المستشار المشتكى عليه'],
  // privacy_policy + terms_of_service (shared phrases)
  ['والمعالجين النفسيين المرخَّصين والمُدرَجين', 'والمدربين والمستشارين المعتمدين والمُدرَجين'],
  ['«المعالج»: كل معالج نفسي مرخَّص ومُدرَج على المنصة', '«المستشار»: كل مدرب أو مستشار معتمد ومُدرَج على المنصة'],
  // privacy_policy
  ['وتشمل المعلومات المتعلقة بالصحة النفسية والجسدية', 'وتشمل بيانات المزاج والعافية الشخصية'],
  ['يُبادلها المستخدم مع المعالج.', 'يُبادلها المستخدم مع المستشار.'],
  ['البيانات الحساسة المتعلقة بالصحة النفسية', 'البيانات الحساسة المتعلقة بالمزاج والعافية الشخصية'],
  ['بين المستخدم والمعالج المختار', 'بين المستخدم والمستشار المختار'],
  ['سرية البيانات الصحية والنفسية', 'سرية بيانات المزاج والعافية'],
  ['بالصحة النفسية للمستخدمين', 'بالمزاج والعافية الشخصية للمستخدمين'],
  ['يمكن للمعالج المعني الاطلاع على محادثات العلاج.', 'يمكن للمستشار المعني الاطلاع على محادثات الجلسات.'],
  ['يلتزم المعالجون المُدرَجون على المنصة بالحفاظ على السرية المهنية وفقاً للمعايير الأخلاقية المعتمدة في مجال الصحة النفسية ومتطلبات الترخيص المهني', 'يلتزم المدربون والمستشارون المُدرَجون على المنصة بالحفاظ على السرية المهنية وفقاً للمعايير الأخلاقية المعتمدة في مجال الإرشاد والتدريب ومتطلبات الاعتماد المهني'],
  ['المعالج المختار: يحق للمعالج الذي', 'المستشار المختار: يحق للمستشار الذي'],
  ['وبيانات صحتك النفسية إلى Google Gemini', 'وبيانات مزاجك إلى Google Gemini'],
  ['الاستمرار في محادثة المعالج', 'الاستمرار في محادثة المستشار'],
  ['لا يغني عن المختص المرخّص أو خدمات الطوارئ', 'لا يغني عن المستشار المختص أو خدمات الطوارئ'],
  // terms_of_service
  ['بين المستخدم والمعالج عبر المنصة', 'بين المستخدم والمستشار عبر المنصة'],
  ['التواصل مع معالج نفسي مرخَّص يختاره', 'التواصل مع مدرب أو مستشار معتمد يختاره'],
  ['بين المستخدم والمعالج.', 'بين المستخدم والمستشار.'],
  ['محتوى توعوي وتثقيفي في مجال الصحة النفسية', 'محتوى توعوي وتثقيفي في مجال جودة الحياة والتطوير الذاتي'],
  ['خدمات طبية أو نفسية مباشرة', 'خدمات طبية أو صحية مباشرة'],
  ['خدمات الطوارئ النفسية أو الأزمات الحادة', 'خدمات الطوارئ أو الأزمات الحادة'],
  ['ضماناً لنتائج أو فوائد علاجية محددة', 'ضماناً لنتائج أو فوائد محددة'],
  ['المعالجون النفسيون المُدرَجون على المنصة', 'المدربون والمستشارون المُدرَجون على المنصة'],
  ['جميع المعالجين المُدرَجين على منصة سند ثيرابي حاصلون على تراخيص مهنية سارية المفعول من جهاتهم المختصة. وتتحقق المنصة من سريان هذه التراخيص ضمن إجراءات القبول', 'جميع المدربين والمستشارين المُدرَجين على منصة سند حاصلون على مؤهلات أو اعتمادات مهنية من جهاتهم المختصة. وتتحقق المنصة من هذه المؤهلات ضمن إجراءات القبول'],
  ['يعمل كل معالج بصفة', 'يعمل كل مدرب أو مستشار بصفة'],
  ['على عاتق المعالج وحده', 'على عاتق المدرب أو المستشار وحده'],
  ['التي يُقدِّمها المعالج خلال', 'التي يُقدِّمها المدرب أو المستشار خلال'],
  ['حق اختيار معالجه وتغييره', 'حق اختيار مستشاره وتغييره'],
  ['التعامل مع المعالج وفريق', 'التعامل مع المستشار وفريق'],
  ['موافقة صريحة من المعالج ومن', 'موافقة صريحة من المستشار ومن'],
  ['حالات الطوارئ والأزمات النفسية', 'حالات الطوارئ والأزمات'],
  ['إدارة الطوارئ أو الأزمات النفسية الحادة', 'إدارة الطوارئ أو الأزمات الحادة'],
  ['أو من أزمة نفسية حادة تستدعي', 'أو من أزمة حادة تستدعي'],
  ['من قِبَل المعالجين أو عن نتائج الجلسات، كون المعالجين يعملون', 'من قِبَل المدربين والمستشارين أو عن نتائج الجلسات، كونهم يعملون'],
  ['بناءً على توصيات المعالج أو', 'بناءً على توصيات المستشار أو'],
  ['تجاه المعالجين أو فريق', 'تجاه المدربين والمستشارين أو فريق'],
  // brand, last
  ['سند ثيرابي', 'سند'],
];

const EN = [
  ['Sanad Therapy – Mental Health Support Closer to You', 'Sanad – Support and Guidance Closer to You'],
  ['specializing in providing remote mental health support services. Our goal is to make mental health care more accessible', 'specializing in remote coaching and counseling services. Our goal is to make wellbeing support more accessible'],
  ['with qualified and independent therapists', 'with qualified and independent coaches and counselors'],
  ['for digital mental health support and to contribute to building a more mental health-conscious and supportive society', 'for digital wellbeing support and guidance and to contribute to building a more aware and supportive society'],
  ['easily accessible mental health support services that empower individuals to improve their mental well-being', 'easily accessible coaching and counseling services that empower individuals to improve their wellbeing'],
  ['Remote psychological support sessions with qualified and licensed therapists', 'Remote coaching and counseling sessions with qualified and certified coaches and counselors'],
  ['Daily chat space with therapists', 'Daily chat space with coaches and counselors'],
  ['Educational psychological content', 'Educational content'],
  ['Sanad Therapy Platform for Psychological Support', 'Sanad Platform for Coaching and Counseling'],
  ['particularly data related to mental health, which', 'particularly data related to mood and personal wellbeing, which'],
  ['During a Therapy Session', 'During a Session'],
  ["therapist's therapeutic approach", "counselor's approach"],
  ['professional license, specialization', 'professional credentials, specialization'],
  ['session goals and treatment plan', 'session goals and plan'],
  ['unrelated to the treatment or service provided', 'unrelated to the service provided'],
  ['licensed psychotherapists listed on the platform', 'certified coaches and counselors listed on the platform'],
  ['“Therapist”: Any licensed psychotherapist listed', '“Counselor”: Any certified coach or counselor listed'],
  ['information related to mental and physical health', 'information related to mood, personal wellbeing and health'],
  ['sensitive data related to mental health', 'sensitive data related to mood and personal wellbeing'],
  ['Confidentiality of Health and Mental Health Data', 'Confidentiality of Mood and Wellbeing Data'],
  ["users' mental health information", "users' mood and wellbeing information"],
  ['can access therapy conversations', 'can access session conversations'],
  ['in the field of mental health and the requirements of their professional license', 'in the field of coaching and counseling and the requirements of their professional credentials'],
  ['relevant profile and mental-health context', 'relevant profile and mood context'],
  ['replacement for a licensed professional', 'replacement for a qualified counselor'],
  ['with a licensed therapist of their choice', 'with a certified coach or counselor of their choice'],
  ['in the field of mental health.', 'in the field of wellbeing and personal development.'],
  ['Direct medical or psychological services', 'Direct medical or health services'],
  ['Emergency psychological services or acute crisis', 'Emergency services or acute crisis'],
  ['specific therapeutic outcomes', 'specific outcomes'],
  ['Psychotherapists Listed on the Platform', 'Coaches and Counselors Listed on the Platform'],
  ['All therapists listed on the Sanad Therapy platform hold valid professional licenses from their respective authorities. The platform verifies the validity of these licenses', 'All coaches and counselors listed on the Sanad platform hold professional qualifications or credentials from their respective bodies. The platform verifies these qualifications'],
  ['Emergencies and Psychological Crises', 'Emergencies and Crises'],
  ['acute psychological crises', 'acute crises'],
  ['an acute psychological crisis', 'an acute crisis'],
  ['provided by therapists or for the outcomes of sessions, as therapists operate', 'provided by coaches and counselors or for the outcomes of sessions, as they operate'],
  ['towards therapists or', 'towards coaches, counselors or'],
  // generic, last
  [/Therapists/g, 'Counselors'],
  [/therapists/g, 'counselors'],
  [/Therapist/g, 'Counselor'],
  [/therapist/g, 'counselor'],
  ['Sanad Therapy', 'Sanad'],
];

function apply(text, table, report) {
  let out = text;
  for (const [from, to] of table) {
    if (typeof from === 'string') {
      const n = out.split(from).length - 1;
      report.hits.set(from, (report.hits.get(from) || 0) + n);
      out = out.split(from).join(to);
    } else {
      out = out.replace(from, to);
    }
  }
  return out;
}

const AR_LEFT = /نفسي|نفسية|معالج(?![ةت])|معالجين|المعالجون|علاج(?!ياً أو دوائياً)|مرخ|ثيرابي|إكلينيك|سريري/g;
const EN_LEFT = /therap(?!y\.com)|mental|psych|licen/gi;

const ids = ['about_us', 'know_your_rights', 'privacy_policy', 'terms_of_service'];
const report = { hits: new Map() };
const updates = {};
for (const id of ids) {
  const x = JSON.parse(fs.readFileSync(path.join(dir, id + '.json'), 'utf8'));
  const ar = apply(x.content_ar, AR, report);
  const en = apply(x.content_en, EN, report);
  updates[id] = { content_ar: ar, content_en: en };
  const leftAr = ar.split('\n').filter((l) => AR_LEFT.test(l) && !(AR_LEFT.lastIndex = 0));
  AR_LEFT.lastIndex = 0;
  const leftEn = en.split('\n').filter((l) => { const m = EN_LEFT.test(l); EN_LEFT.lastIndex = 0; return m; });
  console.log(`== ${id}: ar ${x.content_ar.length}->${ar.length}, en ${x.content_en.length}->${en.length}`);
  ar.split('\n').forEach((l) => { if (/نفسي|نفسية|معالج(?![ةت])|علاج|مرخ|ثيرابي/.test(l)) console.log('  AR left: ' + l.slice(0, 160)); });
  leftEn.forEach((l) => console.log('  EN left: ' + l.slice(0, 160)));
  fs.writeFileSync(path.join(dir, id + '.new.json'), JSON.stringify(updates[id], null, 1));
}
const unused = [...report.hits].filter(([, n]) => n === 0).map(([k]) => k.slice(0, 60));
console.log('unused pairs across all pages:', unused.length ? unused : 'none');

if (APPLY) {
  const admin = require(adminPath);
  admin.initializeApp({ projectId: 'sanad-app-beldify' });
  const db = admin.firestore();
  const batch = db.batch();
  for (const id of ids) {
    batch.set(db.collection('static_pages').doc(id), {
      ...updates[id],
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  batch.commit().then(() => { console.log('APPLIED to Firestore'); process.exit(0); })
    .catch((e) => { console.error(e.message); process.exit(1); });
}
