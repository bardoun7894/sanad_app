import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';

enum StaticPageType { privacy, terms, knowYourRights, about }

extension on StaticPageType {
  String get firestoreId => switch (this) {
    StaticPageType.privacy => 'privacy_policy',
    StaticPageType.terms => 'terms_of_service',
    StaticPageType.knowYourRights => 'know_your_rights',
    StaticPageType.about => 'about_us',
  };
}

/// Streams the live admin-managed content for a static page.
final staticPageDocProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((
      ref,
      pageId,
    ) {
      return FirebaseFirestore.instance
          .collection('static_pages')
          .doc(pageId)
          .snapshots();
    });

class StaticPageScreen extends ConsumerWidget {
  final StaticPageType pageType;

  const StaticPageScreen({super.key, required this.pageType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final langState = ref.watch(languageProvider);
    final isArabic = langState.language == AppLanguage.arabic;
    final isRtl = langState.isRtl;

    final title = switch (pageType) {
      StaticPageType.privacy => s.privacyPolicy,
      StaticPageType.terms => s.termsOfService,
      StaticPageType.knowYourRights => s.knowYourRights,
      StaticPageType.about => s.aboutSanad,
    };

    final docAsync = ref.watch(staticPageDocProvider(pageType.firestoreId));

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
        body: docAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => _buildSections(
            isDark,
            isRtl,
            _fallbackSections(pageType, isArabic),
          ),
          data: (doc) {
            final data = doc.data();
            final remote = isArabic
                ? (data?['content_ar'] as String?)?.trim() ?? ''
                : (data?['content_en'] as String?)?.trim() ?? '';

            if (remote.isNotEmpty) {
              return _buildRemoteContent(isDark, isRtl, remote);
            }
            return _buildSections(
              isDark,
              isRtl,
              _fallbackSections(pageType, isArabic),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRemoteContent(bool isDark, bool isRtl, String content) {
    final styleSheet = MarkdownStyleSheet(
      p: AppTypography.bodyMedium.copyWith(
        color: isDark ? Colors.white70 : AppColors.textSecondary,
        height: 1.7,
      ),
      h1: AppTypography.headingLarge.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      h2: AppTypography.headingMedium.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      h3: AppTypography.headingSmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      strong: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      em: AppTypography.bodyMedium.copyWith(
        fontStyle: FontStyle.italic,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      listBullet: AppTypography.bodyMedium.copyWith(
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      blockquote: AppTypography.bodyMedium.copyWith(
        color: isDark ? Colors.white60 : AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
      code: AppTypography.bodyMedium.copyWith(
        backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Directionality(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: MarkdownBody(
          data: content,
          styleSheet: styleSheet,
          selectable: true,
        ),
      ),
    );
  }

  Widget _buildSections(bool isDark, bool isRtl, List<_Section> sections) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        crossAxisAlignment: isRtl
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
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
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              section.body,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                height: 1.7,
              ),
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ],
        ],
      ),
    );
  }
}

List<_Section> _fallbackSections(StaticPageType type, bool isArabic) {
  return switch (type) {
    StaticPageType.privacy => _privacySections(isArabic),
    StaticPageType.terms => _termsSections(isArabic),
    StaticPageType.knowYourRights => _knowYourRightsSections(isArabic),
    StaticPageType.about => _aboutSections(isArabic),
  };
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

List<_Section> _knowYourRightsSections(bool isArabic) {
  if (isArabic) {
    return const [
      _Section(
        body: 'ك مستخدم لتطبيق سند، لديك حقوق مهمة نحرص على حمايتها وضمانها.',
      ),
      _Section(
        title: 'الحق في الخصوصية',
        body:
            'جميع بياناتك الشخصية والمحادثات العلاجية سرية تماماً. لا يحق لأي طرف مشاركة معلوماتك دون موافقتك الصريحة.',
      ),
      _Section(
        title: 'الحق في جودة الخدمة',
        body:
            'يحق لك الحصول على جلسات علاجية عالية الجودة مع معالجين مرخصين ومؤهلين. يمكنك تغيير المعالج في أي وقت إذا لم تكن راضياً.',
      ),
      _Section(
        title: 'الحق في الوصول للمعلومات',
        body:
            'يحق لك الوصول إلى سجلك العلاجي وتاريخ جلساتك في أي وقت. يمكنك طلب نسخة من بياناتك الشخصية.',
      ),
      _Section(
        title: 'الحق في الإلغاء والاسترداد',
        body:
            'يحق لك إلغاء اشتراكك في أي وقت. في حالة عدم الرضا عن الخدمة، يمكنك طلب استرداد وفقاً لسياسة الاسترداد المعتمدة.',
      ),
      _Section(
        title: 'الحق في الأمان',
        body:
            'يحق لك التمتع ببيئة آمنة وخالية من التحرش أو الإساءة. أي سلوك مسيء من المعالجين أو المستخدمين الآخرين يتم التعامل معه بحزم.',
      ),
      _Section(
        title: 'التواصل',
        body:
            'إذا شعرت أن أي من حقوقك قد انتهكت، يرجى التواصل معنا فوراً على: support@sanad.app',
      ),
    ];
  }
  return const [
    _Section(
      body:
          'As a Sanad app user, you have important rights that we are committed to protecting and ensuring.',
    ),
    _Section(
      title: 'Right to Privacy',
      body:
          'All your personal data and therapeutic conversations are completely confidential. No party has the right to share your information without your explicit consent.',
    ),
    _Section(
      title: 'Right to Quality Service',
      body:
          'You have the right to receive high-quality therapy sessions with licensed and qualified therapists. You can change your therapist at any time if you are not satisfied.',
    ),
    _Section(
      title: 'Right to Information Access',
      body:
          'You have the right to access your therapeutic records and session history at any time. You can request a copy of your personal data.',
    ),
    _Section(
      title: 'Right to Cancel and Refund',
      body:
          'You have the right to cancel your subscription at any time. If you are dissatisfied with the service, you can request a refund according to the approved refund policy.',
    ),
    _Section(
      title: 'Right to Safety',
      body:
          'You have the right to enjoy a safe environment free from harassment or abuse. Any abusive behavior from therapists or other users is dealt with firmly.',
    ),
    _Section(
      title: 'Contact',
      body:
          'If you feel any of your rights have been violated, please contact us immediately at: support@sanad.app',
    ),
  ];
}
