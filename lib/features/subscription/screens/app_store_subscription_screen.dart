import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../models/subscription_product.dart';
import '../providers/app_store_provider.dart';
import '../providers/subscription_provider.dart';

class AppStoreSubscriptionScreen extends ConsumerWidget {
  const AppStoreSubscriptionScreen({super.key, this.selectedPlan});
  final String? selectedPlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(appStoreProvider);
    final status = ref.watch(subscriptionStatusProvider);
    final plans = ref.watch(availableProductsProvider);
    final copy = AppStoreCopy(Localizations.localeOf(context).languageCode);
    final products = plans.isEmpty ? SubscriptionProduct.allProducts : plans;
    return Scaffold(
      appBar: AppBar(title: Text(copy.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (status.isActive) ...[
              Text(
                copy.currentPlan,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(copy.planName(status.productId ?? '')),
              const SizedBox(height: 16),
            ],
            Text(copy.intro),
            const SizedBox(height: 20),
            if (store.isLoading)
              const Center(child: CircularProgressIndicator()),
            for (final plan in products) ...[
              Builder(
                builder: (context) {
                  final native = store.productFor(plan.id);
                  final current =
                      status.isActive &&
                      status.productId == plan.id &&
                      status.paymentGateway == 'app_store';
                  return Card(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: selectedPlan == plan.id
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            copy.planName(plan.id),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            native == null
                                ? copy.unavailable
                                : '${native.price} / ${plan.id == 'weekly' ? copy.week : copy.month}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(copy.planDescription(plan.id)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed:
                                  native == null ||
                                      store.isLoading ||
                                      store.isBusy ||
                                      store.hasUnverifiedPurchases ||
                                      current
                                  ? null
                                  : () => store.purchase(plan.id),
                              child: Text(
                                current ? copy.currentPlan : copy.subscribe,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
            if (store.isBusy) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(copy.pending, textAlign: TextAlign.center),
            ],
            if (store.errorCode != null) ...[
              Text(
                copy.error(store.errorCode!),
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: store.isBusy || store.isLoading
                    ? null
                    : () async {
                        await store.retryVerification();
                        await store.initialize();
                      },
                child: Text(copy.retry),
              ),
            ],
            if (store.lastPurchaseActive != null)
              Text(
                store.lastPurchaseActive!
                    ? copy.verified
                    : copy.noActivePurchase,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            Text(copy.renewal, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextButton(
              onPressed: store.isBusy ? null : store.restore,
              child: Text(copy.restore),
            ),
            TextButton(
              onPressed: () => _open(
                context,
                copy,
                'https://apps.apple.com/account/subscriptions',
              ),
              child: Text(copy.manage),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      _open(context, copy, 'https://sanadtherapy.com/privacy'),
                  child: Text(copy.privacy),
                ),
                TextButton(
                  onPressed: () => _open(
                    context,
                    copy,
                    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                  ),
                  child: Text(copy.terms),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    AppStoreCopy copy,
    String url,
  ) async {
    try {
      if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication))
        return;
    } catch (_) {
      /* The localized message below also handles launch exceptions. */
    }
    if (context.mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.linkError)));
  }
}

class AppStoreCopy {
  const AppStoreCopy(this.locale);
  final String locale;
  String _text(String en, String ar, String fr) => locale == 'ar'
      ? ar
      : locale == 'fr'
      ? fr
      : en;
  String get title => _text('Subscriptions', 'الاشتراكات', 'Abonnements');
  String get intro => _text(
    'Choose your Sanad plan. Payment is handled by the App Store.',
    'اختر باقة سند. يتم الدفع عبر App Store.',
    'Choisissez votre formule Sanad. Le paiement passe par l’App Store.',
  );
  String get subscribe => _text(
    'Subscribe with App Store',
    'اشترك عبر App Store',
    'S’abonner via l’App Store',
  );
  String get currentPlan =>
      _text('Current subscription', 'الاشتراك الحالي', 'Abonnement actuel');
  String get week => _text('week', 'أسبوع', 'semaine');
  String get month => _text('month', 'شهر', 'mois');
  String get unavailable => _text(
    'Currently unavailable',
    'غير متاح حالياً',
    'Indisponible actuellement',
  );
  String get pending => _text(
    'Waiting for App Store confirmation…',
    'بانتظار تأكيد App Store…',
    'En attente de confirmation de l’App Store…',
  );
  String get restore =>
      _text('Restore Purchases', 'استعادة المشتريات', 'Restaurer les achats');
  String get manage => _text(
    'Manage or cancel subscriptions',
    'إدارة الاشتراكات أو إلغاؤها',
    'Gérer ou annuler les abonnements',
  );
  String get privacy =>
      _text('Privacy Policy', 'سياسة الخصوصية', 'Politique de confidentialité');
  String get terms =>
      _text('Terms of Use', 'شروط الاستخدام', 'Conditions d’utilisation');
  String get retry => _text('Retry', 'إعادة المحاولة', 'Réessayer');
  String get verified => _text(
    'Your subscription is active.',
    'اشتراكك مفعّل.',
    'Votre abonnement est actif.',
  );
  String get noActivePurchase => _text(
    'No active subscription was found.',
    'لم يتم العثور على اشتراك ساري.',
    'Aucun abonnement actif trouvé.',
  );
  String get linkError => _text(
    'Could not open the link. Please try again.',
    'تعذر فتح الرابط. حاول مرة أخرى.',
    'Impossible d’ouvrir le lien. Réessayez.',
  );
  String get renewal => _text(
    'Payment is charged to your Apple Account at confirmation. Subscriptions renew automatically for the period shown unless canceled at least 24 hours before the current period ends. Manage or cancel in your App Store account settings. Cancellation keeps access until the paid period ends.',
    'يُخصم المبلغ من حساب Apple عند التأكيد. يتجدد الاشتراك تلقائياً للمدة الموضحة ما لم يتم إلغاؤه قبل نهاية الفترة الحالية بـ24 ساعة على الأقل. يمكنك إدارة الاشتراك أو إلغاؤه من إعدادات حساب App Store. يستمر الوصول حتى نهاية الفترة المدفوعة بعد الإلغاء.',
    'Le paiement est débité de votre compte Apple à la confirmation. L’abonnement se renouvelle pour la durée indiquée, sauf annulation au moins 24 heures avant la fin de la période. Gérez ou annulez dans les réglages de votre compte App Store. L’accès reste disponible jusqu’à la fin de la période payée.',
  );
  String planName(String id) => switch (id) {
    'weekly' => _text('Weekly', 'الأسبوعية', 'Hebdomadaire'),
    'basic' => _text('Basic', 'الأساسية', 'Essentiel'),
    'premium' => _text('Premium', 'بريميوم', 'Premium'),
    'premium_vip' => _text('Premium VIP', 'بريميوم VIP', 'Premium VIP'),
    _ => id,
  };
  String planDescription(String id) => switch (id) {
    'weekly' => _text(
      'Text support, daily reminders and AI assistance.',
      'دعم نصي وتذكيرات يومية ومساعد ذكي.',
      'Soutien par messages, rappels quotidiens et assistant IA.',
    ),
    'basic' => _text(
      'Weekly benefits plus assessments and monthly reports.',
      'مميزات الأسبوعية مع اختبارات وتقارير شهرية.',
      'Avantages hebdomadaires, évaluations et rapports mensuels.',
    ),
    'premium' => _text(
      'Basic benefits plus a dedicated therapist and one monthly audio session.',
      'مميزات الأساسية مع معالج خاص وجلسة صوتية شهرية.',
      'Avantages essentiels, thérapeute dédié et une séance audio mensuelle.',
    ),
    'premium_vip' => _text(
      'Premium benefits plus three monthly audio sessions and a personalized care plan.',
      'مميزات بريميوم مع ثلاث جلسات صوتية شهرية وخطة علاج مخصصة.',
      'Avantages Premium, trois séances audio mensuelles et un plan personnalisé.',
    ),
    _ => '',
  };
  String error(String code) => switch (code) {
    'sign_in' => _text(
      'Sign in to purchase or restore your subscription.',
      'سجّل الدخول للاشتراك أو استعادة مشترياتك.',
      'Connectez-vous pour vous abonner ou restaurer vos achats.',
    ),
    'product_unavailable' || 'store_unavailable' => _text(
      'App Store subscriptions are unavailable right now. Please try again later.',
      'اشتراكات App Store غير متاحة حالياً. حاول لاحقاً.',
      'Les abonnements App Store sont indisponibles. Réessayez plus tard.',
    ),
    'verification_failed' => _text(
      'Your purchase could not be verified. Retry or restore purchases; do not pay again.',
      'تعذر التحقق من مشترياتك. أعد المحاولة أو استعد المشتريات؛ لا تدفع مرة أخرى.',
      'Achat non vérifié. Réessayez ou restaurez les achats ; ne payez pas à nouveau.',
    ),
    _ => _text(
      'The purchase could not be completed. Please try again.',
      'تعذر إتمام العملية. حاول مرة أخرى.',
      'Impossible de terminer l’achat. Réessayez.',
    ),
  };
}
