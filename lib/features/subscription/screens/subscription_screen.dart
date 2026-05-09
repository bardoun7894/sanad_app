// lib/features/subscription/screens/subscription_screen.dart
// Premium Paywall - matching reference design with dynamic features per plan

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/subscription_product.dart';
import '../providers/subscription_provider.dart';
import '../../../core/widgets/whatsapp_support_button.dart';

/// Formats [date] using the locale-appropriate medium date format.
///
/// Uses [DateFormat.yMd] from the `intl` package so Arabic, English, and
/// French dates render in the expected regional notation rather than the
/// hardcoded YYYY-MM-DD produced by the original [_formatDate] method.
String formatSubscriptionDate(DateTime date, String localeCode) {
  return DateFormat.yMd(localeCode).format(date.toLocal());
}

/// Wraps [date] with U+200E LEFT-TO-RIGHT MARK so that bidirectional
/// punctuation (e.g. slashes in Arabic numerals) does not flip when the date
/// is embedded inside an RTL paragraph.
///
/// Only applied when [localeCode] is 'ar'. Other locales already use a
/// left-to-right paragraph direction and do not require the mark.
String wrapDateForLocale(String date, String localeCode) {
  if (localeCode == 'ar') {
    // U+200E prevents bidi algorithm from flipping date punctuation.
    return '‎$date‎';
  }
  return date;
}

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  int _selectedPlanIndex = 0;

  @override
  void initState() {
    super.initState();
    final products = ref.read(subscriptionProvider).products;
    final featuredIndex = products.indexWhere((p) => p.isFeatured);
    if (featuredIndex >= 0) _selectedPlanIndex = featuredIndex;
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);
    final s = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (subscriptionState.isPremium) {
      return _buildPremiumStatusScreen(context, s, isDark);
    }

    final products = subscriptionState.products;
    final selectedProduct = products.isNotEmpty
        ? products[_selectedPlanIndex < products.length
              ? _selectedPlanIndex
              : 0]
        : null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFFCFCFC),
      body: Column(
        children: [
          // Header with GO PREMIUM badge
          _buildHeader(context, s, isDark),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Dynamic features based on selected plan
                  if (selectedProduct != null)
                    _buildDynamicFeatures(selectedProduct, s, isDark),

                  const SizedBox(height: 24),

                  // Plan rows
                  ...products.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SubscriptionPlanCard(
                        product: product,
                        isSelected: _selectedPlanIndex == index,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedPlanIndex = index);
                        },
                        isDark: isDark,
                        s: s,
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // Auto-renewal note
                  Text(
                    s.autoRenewalStatement,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Continue button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: subscriptionState.isProcessingPurchase
                                ? 0.2
                                : 0.4,
                          ),
                          blurRadius: subscriptionState.isProcessingPurchase
                              ? 4
                              : 16,
                          spreadRadius: subscriptionState.isProcessingPurchase
                              ? 0
                              : 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: subscriptionState.isProcessingPurchase
                          ? null
                          : () {
                              if (selectedProduct != null) {
                                _showPaymentOptions(context, selectedProduct);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation:
                            0, // Elevation handled by glowing AnimatedContainer
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: subscriptionState.isProcessingPurchase
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              s.continueText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Terms & Privacy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          s.termsOfService,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '·',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          s.privacyPolicy,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white38
                                : Colors.grey.shade500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const WhatsAppSupportButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, S s, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.25),
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.10),
                  AppColors.primary.withValues(alpha: 0.03),
                  const Color(0xFFFCFCFC),
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              // Top row: GO PREMIUM badge + close
              Row(
                children: [
                  // GO PREMIUM badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFFFD700),
                        ], // Gold Gradient
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.upgradeToPremium,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // PREMIUM text label
                  Text(
                    s.premium.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Close button
                  GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : null,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dynamic features (changes per selected plan) ────────────────────────────

  Widget _buildDynamicFeatures(SubscriptionProduct product, S s, bool isDark) {
    // Get localized features based on product ID
    final featuresWithIcons = _getLocalizedFeatures(product.id, s);

    if (featuresWithIcons.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(product.id),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: featuresWithIcons.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeatureListItem(
                text: item.text,
                icon: item.icon,
                isDark: isDark,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Helper struct for Feature Items
  List<({String text, IconData icon})> _getLocalizedFeatures(
    String productId,
    S s,
  ) {
    switch (productId) {
      case 'weekly':
        return [
          (text: s.featureTextChat, icon: Icons.chat_bubble_outline_rounded),
          (text: s.feature247Support, icon: Icons.access_time_rounded),
          (
            text: s.featureDailyReminders,
            icon: Icons.notifications_active_outlined,
          ),
          (text: s.featureAiAssistant, icon: Icons.auto_awesome_rounded),
        ];
      case 'basic':
        return [
          (text: s.featureAllWeekly, icon: Icons.done_all_rounded),
          (text: s.featurePeriodicTests, icon: Icons.assignment_outlined),
          (text: s.featureWeeklyReports, icon: Icons.bar_chart_rounded),
          (text: s.featureFastResponse, icon: Icons.bolt_rounded),
        ];
      case 'premium':
        return [
          (text: s.featureAllBasic, icon: Icons.star_outline_rounded),
          (text: s.featureDirectTherapist, icon: Icons.person_outline_rounded),
          (text: s.featureFreeSession, icon: Icons.headset_mic_rounded),
          (text: s.featureWhatsappSupport, icon: Icons.phone_iphone_rounded),
        ];
      case 'premium_vip':
        return [
          (text: s.featureAllPremium, icon: Icons.diamond_outlined),
          (text: s.featureThreeSessions, icon: Icons.headset_mic_rounded),
          (
            text: s.featurePriorityEmergency,
            icon: Icons.medical_services_outlined,
          ),
          (text: s.featureCustomPlan, icon: Icons.favorite_border_rounded),
        ];
      default:
        return [];
    }
  }

  // ── Premium status screen ───────────────────────────────────────────────────

  Widget _buildPremiumStatusScreen(BuildContext context, S s, bool isDark) {
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.premium),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.premium,
              style: AppTypography.displayMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 32),
            Material(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildBenefitRow(
                      Icons.chat_bubble_outline_rounded,
                      s.featureTextChat,
                      isDark,
                    ),
                    _buildBenefitRow(
                      Icons.psychology_rounded,
                      s.featureDirectTherapist,
                      isDark,
                    ),
                    _buildBenefitRow(
                      Icons.headset_mic_rounded,
                      s.featureFreeSession,
                      isDark,
                    ),
                    _buildBenefitRow(
                      Icons.support_agent_rounded,
                      s.featureFastResponse,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const WhatsAppSupportButton(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _showCancelDialog(context, s),
              child: Text(
                s.cancelSubscription,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }

  void _showPaymentOptions(BuildContext context, SubscriptionProduct product) {
    context.push('/payment-method', extra: product);
  }

  void _showCancelDialog(BuildContext context, S s) {
    // Expiry is captured at dialog-open time; stale-state on a subsequent
    // stream update before the user taps confirm is acceptable here.
    final localeCode = ref.read(languageProvider).locale.languageCode;
    final expiryDate = ref.read(subscriptionProvider).status.expiryDate;
    final formattedDate = expiryDate != null
        ? wrapDateForLocale(formatSubscriptionDate(expiryDate, localeCode), localeCode)
        : null;
    final body = formattedDate != null
        ? s.cancelKeepsAccessUntil.replaceAll('{date}', formattedDate)
        : s.cancelNoExpiryNotice;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.cancelSubscription),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(subscriptionProvider.notifier)
                    .cancelSubscription();
                if (!context.mounted) return;
                final currentLocale = ref.read(languageProvider).locale.languageCode;
                final newExpiry =
                    ref.read(subscriptionProvider).status.expiryDate;
                final newFormatted = newExpiry != null
                    ? wrapDateForLocale(
                        formatSubscriptionDate(newExpiry, currentLocale),
                        currentLocale,
                      )
                    : null;
                final msg = newFormatted != null
                    ? s.subscriptionCancelledUntil
                          .replaceAll('{date}', newFormatted)
                    : s.subscriptionCancelled;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                debugPrint('SubscriptionScreen._showCancelDialog error: $e');
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(s.subscriptionCancelError),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            child: Text(
              s.cancelSubscription,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REUSABLE WIDGETS
// =============================================================================

class FeatureListItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isDark;

  const FeatureListItem({
    super.key,
    required this.text,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkmark (RTL safe)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 14),

        // Feature text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Feature icon (RTL safe placing it at the end for RTL if desired or keep the original design.
        // Original design had Icon -> Text -> Checkmark. The layout image shows Checkmark -> Text -> Icon (RTL)).
        Container(
          margin: const EdgeInsets.only(top: 0),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
      ],
    );
  }
}

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionProduct product;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final S s;

  const SubscriptionPlanCard({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.s,
  });

  String _getPlanName() {
    switch (product.id) {
      case 'weekly':
        return s.planWeeklyTitle;
      case 'basic':
        return s.planBasicTitle;
      case 'premium':
        return s.planPremiumTitle;
      case 'premium_vip':
        return s.planVipTitle;
      default:
        return product.title;
    }
  }

  String _getPeriodLabel() {
    switch (product.billingPeriod) {
      case 'weekly':
        return '/${s.week}';
      case 'monthly':
        return '/${s.month}';
      case 'hourly':
        return '/${s.hour}';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremiumTier = product.id.contains('premium');

    // Background color: subtle tint when selected.
    final bgColor = isDark
        ? (isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceDark)
        : (isSelected
              ? AppColors.primary.withValues(alpha: 0.03)
              : Colors.white);

    // Border color logic.
    final borderColor = isSelected
        ? (isPremiumTier ? const Color(0xFFFFD700) : AppColors.primary)
        : (isDark ? AppColors.borderDark : Colors.grey.shade200);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.only(
              top:
                  32, // Increased top padding to ensure badge clears title completely
              bottom: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              boxShadow: [
                BoxShadow(
                  color: isSelected && isPremiumTier
                      ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                      : AppColors.primary.withValues(
                          alpha: isSelected ? 0.08 : 0.02,
                        ),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Radio circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isPremiumTier
                                ? const Color(0xFFFFD700)
                                : AppColors.primary)
                          : Colors.grey.shade300,
                      width: isSelected ? 7 : 2,
                    ),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),

                // Main Content: Titles and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _getPlanName(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isPremiumTier) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Color(0xFFFFD700),
                            ),
                          ],
                        ],
                      ),

                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Text(
                          product.id == 'weekly'
                              ? s.planWeeklyDesc
                              : product.id == 'basic'
                              ? s.planBasicDesc
                              : product.id == 'premium'
                              ? s.planPremiumDesc
                              : s.planVipDesc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Price and Period
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? (isPremiumTier
                                  ? const Color(0xFFD4AF37)
                                  : AppColors.primary)
                            : (isDark ? Colors.white : AppColors.textPrimary),
                      ),
                      child: Text(
                        '\$${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)}',
                      ),
                    ),
                    Text(
                      _getPeriodLabel(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (product.id == 'premium' || product.id == 'premium_vip')
            PositionedDirectional(
              top: 0,
              start: 0,
              child: _buildCornerBadge(
                product.id == 'premium' ? s.popular : s.bestValue,
                product.id,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerBadge(String text, String id) {
    final isVip = id == 'premium_vip';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isVip ? null : const Color(0xFFFF6B35),
        gradient: isVip
            ? const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
              )
            : null,
        borderRadius: const BorderRadiusDirectional.only(
          bottomEnd: Radius.circular(16),
          topStart: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: (isVip ? const Color(0xFFFFD700) : const Color(0xFFFF6B35))
                .withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVip ? Icons.emoji_events : Icons.local_fire_department,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
