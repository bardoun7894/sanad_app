// One-off FAQ seeder. Uses gcloud Application Default Credentials.
// Run from repo root:
//   node scripts/seed_faqs.js
//
// Idempotent: replaces all existing docs in the `faqs` collection with the
// list below. Safe to re-run.

const path = require('path');
process.env.GOOGLE_CLOUD_PROJECT =
  process.env.GOOGLE_CLOUD_PROJECT || 'sanad-app-beldify';

const adminPath = path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin');
const admin = require(adminPath);

admin.initializeApp({
  projectId: 'sanad-app-beldify',
});

const db = admin.firestore();

const faqs = [
  {
    question_ar: 'ما هو تطبيق سند؟',
    answer_ar:
      'سند هو تطبيق يقدم خدمات الدعم والإرشاد النفسي من خلال محتوى تثقيفي وتمارين عملية وجلسات إرشادية مع مدربين ومستشارين، بهدف تحسين جودة الحياة والتوازن النفسي.',
    question_en: 'What is the Sanad app?',
    answer_en:
      'Sanad is an app that offers wellbeing support and guidance through educational content, practical exercises, and sessions with coaches and counselors — aimed at improving wellbeing and quality of life.',
  },
  {
    question_ar: 'هل التطبيق بديل عن الاستشارات المتخصصة؟',
    answer_ar:
      'لا، التطبيق لا يُعد بديلاً كاملاً عن الرعاية المتخصصة، بل هو وسيلة داعمة تساعدك على فهم نفسك بشكل أفضل، ويمكن أن يكمل رحلتك الإرشادية مع مدرب أو مستشار.',
    question_en: 'Is the app a replacement for professional counseling?',
    answer_en:
      'No. The app is not a full substitute for specialized care. It is a supportive tool that helps you understand yourself better and can complement your journey with a coach or counselor.',
  },
  {
    question_ar: 'هل يمكنني التحدث مع مدرب / مستشار؟',
    answer_ar:
      'نعم، يوفر التطبيق إمكانية التواصل مع مدربين ومستشارين معتمدين عبر جلسات منظمة داخل التطبيق.',
    question_en: 'Can I talk to a coach / counselor?',
    answer_en:
      'Yes. The app lets you connect with certified coaches and counselors through structured in-app sessions.',
  },
  {
    question_ar: 'هل معلوماتي الشخصية آمنة؟',
    answer_ar:
      'نعم، نحن نحرص على حماية خصوصيتك، ويتم التعامل مع جميع البيانات بسرية تامة وفق سياسات الخصوصية المعتمدة.',
    question_en: 'Is my personal information safe?',
    answer_en:
      'Yes. We protect your privacy and handle all data with full confidentiality, in line with our published privacy policy.',
  },
  {
    question_ar: 'هل يمكن استخدام التطبيق دون تسجيل؟',
    answer_ar:
      'بعض المحتوى متاح بدون تسجيل، لكن للاستفادة الكاملة من الخدمات مثل الجلسات والمتابعة، يُفضل إنشاء حساب.',
    question_en: 'Can I use the app without signing up?',
    answer_en:
      'Some content is available without registration, but to take full advantage of services such as sessions and progress tracking, creating an account is recommended.',
  },
  {
    question_ar: 'هل التطبيق مناسب لجميع الأعمار؟',
    answer_ar:
      'التطبيق موجه بشكل أساسي للبالغين، ويُنصح باستخدامه تحت إشراف ولي الأمر للمستخدمين الأصغر سناً.',
    question_en: 'Is the app suitable for all ages?',
    answer_en:
      'The app is primarily intended for adults. Younger users should use it under parental supervision.',
  },
  {
    question_ar: 'ما أنواع المحتوى التي يقدمها التطبيق؟',
    answer_ar:
      'يقدم التطبيق:\n• تمارين للاسترخاء والتأمل\n• مقالات تثقيفية\n• تحديات يومية لتحسين المزاج\n• جلسات إرشاد ودعم مع مدربين ومستشارين',
    question_en: 'What kinds of content does the app offer?',
    answer_en:
      'The app offers:\n• Relaxation and meditation exercises\n• Educational wellbeing articles\n• Daily mood-boosting challenges\n• Guidance and support sessions with coaches and counselors',
  },
  {
    question_ar: 'ماذا أفعل إذا كنت أمر بأزمة نفسية حادة؟',
    answer_ar:
      'في حالات الطوارئ أو الأزمات الشديدة، يُنصح بالتواصل فوراً مع خدمات الطوارئ المحلية أو التوجه لأقرب مركز طبي، لأن التطبيق لا يقدم خدمات طوارئ.',
    question_en: 'What should I do if I am in a severe crisis?',
    answer_en:
      'In emergencies or severe crises, contact your local emergency services immediately or go to the nearest medical center — the app does not provide emergency services.',
  },
  {
    question_ar: 'هل يمكنني تغيير المدرب / المستشار؟',
    answer_ar:
      'نعم، يمكنك تغيير المدرب أو المستشار في أي وقت بما يتناسب مع راحتك واحتياجاتك.',
    question_en: 'Can I change my coach / counselor?',
    answer_en:
      'Yes. You can change your coach or counselor at any time, based on your comfort and needs.',
  },
  {
    question_ar: 'كيف يمكنني حجز جلسة؟',
    answer_ar:
      'يمكنك حجز جلسة بسهولة من داخل التطبيق عبر اختيار المدرب / المستشار والوقت المناسب ثم تأكيد الحجز.',
    question_en: 'How do I book a session?',
    answer_en:
      'You can easily book a session inside the app by picking a coach / counselor, choosing a time, and confirming the booking.',
  },
  {
    question_ar: 'هل الجلسات مدفوعة؟',
    answer_ar:
      'قد تكون بعض الخدمات مجانية، بينما تتطلب الجلسات مع المدربين والمستشارين رسوماً يتم توضيحها داخل التطبيق.',
    question_en: 'Are sessions paid?',
    answer_en:
      'Some services may be free, while sessions with coaches and counselors require fees that are made clear inside the app.',
  },
  {
    question_ar: 'هل يمكن استرجاع الرسوم؟',
    answer_ar:
      'تعتمد سياسة الاسترجاع على شروط الاستخدام داخل التطبيق، يرجى مراجعة قسم السياسات لمعرفة التفاصيل.',
    question_en: 'Can fees be refunded?',
    answer_en:
      'The refund policy is governed by the in-app terms of service. Please review the Policies section for details.',
  },
  {
    question_ar: 'هل يمكنني إلغاء الجلسة؟',
    answer_ar:
      'نعم، يمكن إلغاء الجلسة قبل موعدها وفق سياسة الإلغاء المحددة داخل التطبيق.',
    question_en: 'Can I cancel a session?',
    answer_en:
      'Yes. You can cancel a session before its scheduled time, in line with the in-app cancellation policy.',
  },
  {
    question_ar: 'كيف يمكنني التواصل مع الدعم الفني؟',
    answer_ar:
      'يمكنك التواصل مع فريق الدعم من خلال قسم "اتصل بنا" داخل التطبيق، وسيتم الرد عليك في أقرب وقت.',
    question_en: 'How can I contact technical support?',
    answer_en:
      'You can reach the support team through the "Contact Us" section inside the app — we will respond as soon as possible.',
  },
  {
    question_ar: 'هل يتم حفظ سجل الجلسات؟',
    answer_ar:
      'قد يتم حفظ بعض البيانات لتحسين الخدمة، مع الالتزام الكامل بالسرية وعدم مشاركتها دون إذنك.',
    question_en: 'Are session records saved?',
    answer_en:
      'Some data may be saved to improve the service, while maintaining strict confidentiality and never sharing it without your permission.',
  },
];

async function main() {
  const colRef = db.collection('faqs');
  console.log('Wiping existing FAQs…');
  const existing = await colRef.get();
  const batch1 = db.batch();
  existing.docs.forEach((d) => batch1.delete(d.ref));
  if (existing.size > 0) await batch1.commit();
  console.log(`Deleted ${existing.size} existing docs.`);

  console.log(`Seeding ${faqs.length} FAQs…`);
  const batch2 = db.batch();
  const now = admin.firestore.FieldValue.serverTimestamp();
  faqs.forEach((faq, idx) => {
    const ref = colRef.doc();
    batch2.set(ref, {
      ...faq,
      order: idx,
      created_at: now,
      updated_at: now,
    });
  });
  await batch2.commit();
  console.log(`✓ Wrote ${faqs.length} FAQs to faqs/.`);
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
