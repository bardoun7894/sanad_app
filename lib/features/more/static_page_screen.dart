import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';

enum StaticPageType { privacy, terms, about }

class StaticPageScreen extends ConsumerWidget {
  final StaticPageType pageType;

  const StaticPageScreen({super.key, required this.pageType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = ref.watch(languageProvider).language == AppLanguage.arabic;

    final title = switch (pageType) {
      StaticPageType.privacy => s.privacyPolicy,
      StaticPageType.terms => s.termsOfService,
      StaticPageType.about => s.aboutSanad,
    };

    final sections = switch (pageType) {
      StaticPageType.privacy => _privacySections(isArabic),
      StaticPageType.terms => _termsSections(isArabic),
      StaticPageType.about => _aboutSections(isArabic),
    };

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTypography.headingLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in sections) ...[
              if (section.title != null) ...[
                const SizedBox(height: 24),
                Text(
                  section.title!,
                  style: AppTypography.headingSmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                section.body,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String? title;
  final String body;
  const _Section({this.title, required this.body});
}

List<_Section> _privacySections(bool isArabic) {
  if (isArabic) {
    return const [
      _Section(
        body:
            'نحن في سند نأخذ خصوصيتك على محمل الجد. توضح هذه السياسة كيف نجمع ونستخدم ونحمي معلوماتك الشخصية.',
      ),
      _Section(
        title: 'جمع المعلومات',
        body:
            'نجمع المعلومات التي تقدمها لنا مباشرة عند إنشاء حسابك، مثل اسمك وبريدك الإلكتروني ورقم هاتفك. كما نجمع بيانات الاستخدام لتحسين تجربتك.',
      ),
      _Section(
        title: 'استخدام المعلومات',
        body:
            'نستخدم معلوماتك لتقديم خدماتنا وتحسينها، والتواصل معك بشأن حسابك، وإرسال إشعارات مهمة. لا نبيع معلوماتك الشخصية لأطراف ثالثة.',
      ),
      _Section(
        title: 'حماية البيانات',
        body:
            'نستخدم تقنيات تشفير متقدمة لحماية بياناتك. جميع المحادثات والجلسات العلاجية مشفرة ومحمية بالكامل.',
      ),
      _Section(
        title: 'السرية العلاجية',
        body:
            'جميع الجلسات والمحادثات مع المعالجين النفسيين سرية تماماً ومحمية بموجب أخلاقيات المهنة وقوانين حماية البيانات.',
      ),
      _Section(
        title: 'حقوقك',
        body:
            'لديك الحق في الوصول إلى بياناتك الشخصية وتعديلها وحذفها في أي وقت. يمكنك التواصل معنا لممارسة هذه الحقوق.',
      ),
      _Section(
        title: 'التواصل معنا',
        body:
            'إذا كانت لديك أي أسئلة حول سياسة الخصوصية، يرجى التواصل معنا عبر البريد الإلكتروني: support@sanad.app',
      ),
    ];
  }
  return const [
    _Section(
      body:
          'At Sanad, we take your privacy seriously. This policy explains how we collect, use, and protect your personal information.',
    ),
    _Section(
      title: 'Information Collection',
      body:
          'We collect information you provide directly when creating your account, such as your name, email, and phone number. We also collect usage data to improve your experience.',
    ),
    _Section(
      title: 'Use of Information',
      body:
          'We use your information to provide and improve our services, communicate with you about your account, and send important notifications. We do not sell your personal information to third parties.',
    ),
    _Section(
      title: 'Data Protection',
      body:
          'We use advanced encryption technologies to protect your data. All therapeutic conversations and sessions are fully encrypted and secured.',
    ),
    _Section(
      title: 'Therapeutic Confidentiality',
      body:
          'All sessions and conversations with therapists are completely confidential and protected under professional ethics and data protection laws.',
    ),
    _Section(
      title: 'Your Rights',
      body:
          'You have the right to access, modify, and delete your personal data at any time. Contact us to exercise these rights.',
    ),
    _Section(
      title: 'Contact Us',
      body:
          'If you have any questions about this privacy policy, please contact us at: support@sanad.app',
    ),
  ];
}

List<_Section> _termsSections(bool isArabic) {
  if (isArabic) {
    return const [
      _Section(
        body:
            'باستخدامك لتطبيق سند، فإنك توافق على الالتزام بهذه الشروط والأحكام. يرجى قراءتها بعناية.',
      ),
      _Section(
        title: 'الخدمات المقدمة',
        body:
            'يوفر تطبيق سند منصة للدعم النفسي والعلاج عن بعد، بما في ذلك جلسات مع معالجين نفسيين مرخصين، ومحادثات ذكاء اصطناعي للدعم، ومحتوى تعليمي.',
      ),
      _Section(
        title: 'حسابك',
        body:
            'أنت مسؤول عن الحفاظ على سرية حسابك وكلمة مرورك. يجب أن تكون المعلومات المقدمة دقيقة وحديثة.',
      ),
      _Section(
        title: 'الاشتراكات والدفع',
        body:
            'بعض الخدمات تتطلب اشتراكاً مدفوعاً. يتم تجديد الاشتراكات تلقائياً ما لم يتم إلغاؤها. يمكنك إلغاء اشتراكك في أي وقت.',
      ),
      _Section(
        title: 'إخلاء المسؤولية الطبية',
        body:
            'تطبيق سند ليس بديلاً عن الرعاية الطبية الطارئة. في حالات الطوارئ، يرجى الاتصال بخدمات الطوارئ المحلية فوراً.',
      ),
      _Section(
        title: 'السلوك المقبول',
        body:
            'يجب عليك استخدام التطبيق بطريقة محترمة وقانونية. أي سلوك مسيء أو غير لائق قد يؤدي إلى تعليق أو إنهاء حسابك.',
      ),
      _Section(
        title: 'التعديلات',
        body:
            'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات جوهرية.',
      ),
    ];
  }
  return const [
    _Section(
      body:
          'By using the Sanad app, you agree to comply with these terms and conditions. Please read them carefully.',
    ),
    _Section(
      title: 'Services Provided',
      body:
          'Sanad provides a platform for mental health support and remote therapy, including sessions with licensed therapists, AI-powered support conversations, and educational content.',
    ),
    _Section(
      title: 'Your Account',
      body:
          'You are responsible for maintaining the confidentiality of your account and password. All information provided must be accurate and up to date.',
    ),
    _Section(
      title: 'Subscriptions & Payments',
      body:
          'Some services require a paid subscription. Subscriptions renew automatically unless cancelled. You can cancel your subscription at any time.',
    ),
    _Section(
      title: 'Medical Disclaimer',
      body:
          'Sanad is not a substitute for emergency medical care. In case of emergencies, please contact your local emergency services immediately.',
    ),
    _Section(
      title: 'Acceptable Use',
      body:
          'You must use the app in a respectful and lawful manner. Any abusive or inappropriate behavior may result in suspension or termination of your account.',
    ),
    _Section(
      title: 'Modifications',
      body:
          'We reserve the right to modify these terms at any time. You will be notified of any material changes.',
    ),
  ];
}

List<_Section> _aboutSections(bool isArabic) {
  if (isArabic) {
    return const [
      _Section(
        body:
            'سند هو تطبيق للصحة النفسية يهدف إلى جعل الدعم النفسي متاحاً وسهل الوصول للجميع.',
      ),
      _Section(
        title: 'رؤيتنا',
        body:
            'نؤمن بأن كل شخص يستحق الوصول إلى دعم نفسي عالي الجودة. نسعى لكسر الحواجز التي تمنع الناس من طلب المساعدة النفسية.',
      ),
      _Section(
        title: 'ما نقدمه',
        body:
            'جلسات علاجية مع معالجين نفسيين مرخصين عبر المكالمات الصوتية والمحادثات النصية.\n\nدعم ذكاء اصطناعي متاح على مدار الساعة للمساعدة الفورية.\n\nمحتوى تعليمي يشمل مقالات وبودكاست وتمارين نفسية.\n\nتتبع المزاج والتقدم لمساعدتك على فهم نفسك بشكل أفضل.\n\nمجتمع داعم للتواصل مع الآخرين.',
      ),
      _Section(
        title: 'فريقنا',
        body:
            'يتكون فريقنا من معالجين نفسيين مرخصين ومطورين متخصصين ملتزمين بتقديم أفضل تجربة صحة نفسية رقمية.',
      ),
      _Section(
        title: 'تواصل معنا',
        body:
            'البريد الإلكتروني: support@sanad.app\n\nنحن هنا لمساعدتك في رحلتك نحو صحة نفسية أفضل.',
      ),
    ];
  }
  return const [
    _Section(
      body:
          'Sanad is a mental health app designed to make psychological support accessible and easy to reach for everyone.',
    ),
    _Section(
      title: 'Our Vision',
      body:
          'We believe everyone deserves access to high-quality mental health support. We strive to break the barriers that prevent people from seeking psychological help.',
    ),
    _Section(
      title: 'What We Offer',
      body:
          'Therapy sessions with licensed therapists via audio calls and text chat.\n\n24/7 AI-powered support for immediate assistance.\n\nEducational content including articles, podcasts, and psychological exercises.\n\nMood tracking and progress monitoring to help you understand yourself better.\n\nA supportive community to connect with others.',
    ),
    _Section(
      title: 'Our Team',
      body:
          'Our team consists of licensed therapists and specialized developers committed to providing the best digital mental health experience.',
    ),
    _Section(
      title: 'Contact Us',
      body:
          'Email: support@sanad.app\n\nWe are here to support you on your journey to better mental health.',
    ),
  ];
}
