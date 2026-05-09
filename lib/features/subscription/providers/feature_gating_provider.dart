import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_provider.dart';

/// Subscription tier hierarchy (ordered by features)
/// Higher index = more features
enum SubscriptionTier { free, weekly, basic, premium, premiumVip }

/// Extension to add helper methods to SubscriptionTier
extension SubscriptionTierX on SubscriptionTier {
  /// Get tier from product ID
  static SubscriptionTier fromProductId(String? productId) {
    if (productId == null) return SubscriptionTier.free;

    switch (productId.toLowerCase()) {
      case 'weekly':
        return SubscriptionTier.weekly;
      case 'basic':
        return SubscriptionTier.basic;
      case 'premium':
      case 'monthly_premium':
        return SubscriptionTier.premium;
      case 'premium_vip':
        return SubscriptionTier.premiumVip;
      default:
        // Handle legacy or unknown product IDs
        if (productId.contains('premium') || productId.contains('vip')) {
          return SubscriptionTier.premiumVip;
        }
        return SubscriptionTier.free;
    }
  }

  /// Check if this tier includes another tier's features
  bool includes(SubscriptionTier other) {
    return index >= other.index;
  }

  /// Check if this is any paid tier
  bool get isPaid => index >= SubscriptionTier.weekly.index;

  /// Monthly AI message limit per tier
  int get monthlyAiMessages {
    switch (this) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.weekly:
        return 50;
      case SubscriptionTier.basic:
        return 200;
      case SubscriptionTier.premium:
        return 1000;
      case SubscriptionTier.premiumVip:
        return -1; // Unlimited
    }
  }

  /// Free voice sessions per month
  int get freeVoiceSessions {
    switch (this) {
      case SubscriptionTier.free:
      case SubscriptionTier.weekly:
      case SubscriptionTier.basic:
        return 0;
      case SubscriptionTier.premium:
        return 1;
      case SubscriptionTier.premiumVip:
        return 3;
    }
  }

  /// Whether tier includes WhatsApp support
  bool get hasWhatsAppSupport {
    return this == SubscriptionTier.premium ||
        this == SubscriptionTier.premiumVip;
  }

  /// Whether tier includes priority support
  bool get hasPrioritySupport {
    return this == SubscriptionTier.premiumVip;
  }

  /// Whether tier includes dedicated therapist
  bool get hasDedicatedTherapist {
    return this == SubscriptionTier.premium ||
        this == SubscriptionTier.premiumVip;
  }

  /// Whether tier includes psychological tests
  bool get hasPsychologicalTests {
    return includes(SubscriptionTier.basic);
  }

  /// Tier display name
  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.weekly:
        return 'Weekly';
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.premiumVip:
        return 'Premium VIP';
    }
  }

  /// Arabic tier display name
  String get displayNameAr {
    switch (this) {
      case SubscriptionTier.free:
        return 'مجاني';
      case SubscriptionTier.weekly:
        return 'أسبوعي';
      case SubscriptionTier.basic:
        return 'أساسي';
      case SubscriptionTier.premium:
        return 'بريميوم';
      case SubscriptionTier.premiumVip:
        return 'بريميوم VIP';
    }
  }

  /// French tier display name
  String get displayNameFr {
    switch (this) {
      case SubscriptionTier.free:
        return 'Gratuit';
      case SubscriptionTier.weekly:
        return 'Hebdo';
      case SubscriptionTier.basic:
        return 'Basique';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.premiumVip:
        return 'Premium VIP';
    }
  }

  /// Locale-aware label
  String displayNameFor(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return displayNameAr;
      case 'fr':
        return displayNameFr;
      default:
        return displayName;
    }
  }

  // -------------------------------------------------------------------------
  // CANONICAL VISUAL TOKENS
  // Centralises every badge/ring/icon colour so there is a single source of
  // truth across PremiumBadge, ProfileHeader, and GreetingHeader.
  //
  // Token table:
  // ┌──────────────┬─────────────┬─────────────┬──────────────┬────────────┬────────────┐
  // │ tier         │ primary     │ gradStart   │ gradEnd      │ ring       │ textOn     │
  // ├──────────────┼─────────────┼─────────────┼──────────────┼────────────┼────────────┤
  // │ free         │ #94A3B8     │ #CBD5E1     │ #94A3B8      │ #CBD5E1    │ #475569    │
  // │ weekly       │ #0284C7     │ #38BDF8     │ #0284C7      │ #7DD3FC    │ white      │
  // │ basic        │ #059669     │ #34D399     │ #059669      │ #6EE7B7    │ white      │
  // │ premium      │ #F59E0B ✦   │ #F59E0B ✦   │ #B45309 ✦    │ #FBBF24 ✦  │ white ✦   │
  // │ premiumVip   │ #FDE047     │ #FDE047     │ #F59E0B      │ #FDE68A    │ #713F12    │
  // └──────────────┴─────────────┴─────────────┴──────────────┴────────────┴────────────┘
  // ✦ = canonical orange from packet spec.
  //
  // Reconciliation notes (drift between old local tables before collapse):
  //   • premium primary: badge had #F59E0B; profile had #F59E0B ✓ (no drift)
  //   • premiumVip primary: badge had #D97706; profile had #FDE047; home had #FDE047→#F59E0B
  //     Resolved to home's treatment: #FDE047 as primary, gradient to #F59E0B.
  //   • weekly primary: badge had #0284C7; profile had #0EA5E9; home had #38BDF8→#0284C7
  //     Resolved to home's gradient: start #38BDF8, end/primary #0284C7.
  //   • basic primary: badge had #059669; profile had #34D399; home had #34D399→#059669
  //     Resolved to home's gradient: start #34D399, end/primary #059669.
  //   • iconBg existed only in premium_badge; pulled forward unchanged.
  // -------------------------------------------------------------------------

  /// The tier's primary brand colour (used for text, icon, border, flat bg).
  Color get tierPrimaryColor {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFF94A3B8);
      case SubscriptionTier.weekly:
        return const Color(0xFF0284C7);
      case SubscriptionTier.basic:
        return const Color(0xFF059669);
      case SubscriptionTier.premium:
        return const Color(0xFFF59E0B);
      case SubscriptionTier.premiumVip:
        return const Color(0xFFFDE047);
    }
  }

  /// Gradient start (lighter end, top).
  Color get tierGradientStart {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFFCBD5E1);
      case SubscriptionTier.weekly:
        return const Color(0xFF38BDF8);
      case SubscriptionTier.basic:
        return const Color(0xFF34D399);
      case SubscriptionTier.premium:
        return const Color(0xFFF59E0B);
      case SubscriptionTier.premiumVip:
        return const Color(0xFFFDE047);
    }
  }

  /// Gradient end (darker end, bottom).
  Color get tierGradientEnd {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFF94A3B8);
      case SubscriptionTier.weekly:
        return const Color(0xFF0284C7);
      case SubscriptionTier.basic:
        return const Color(0xFF059669);
      case SubscriptionTier.premium:
        return const Color(0xFFB45309);
      case SubscriptionTier.premiumVip:
        return const Color(0xFFF59E0B);
    }
  }

  /// Text colour to use ON the tier's coloured background.
  ///
  /// WCAG AA target ≥4.5:1. Premium uses dark slate (#1F2937 on #F59E0B
  /// → ~7:1) per user contrast-audit decision; white-on-orange measured
  /// 2.15:1 which fails AA at all badge sizes.
  Color get tierTextOnColor {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFF475569);
      case SubscriptionTier.weekly:
        return Colors.white;
      case SubscriptionTier.basic:
        return Colors.white;
      case SubscriptionTier.premium:
        return const Color(0xFF1F2937);
      case SubscriptionTier.premiumVip:
        return const Color(0xFF713F12);
    }
  }

  /// Ring/border colour around the avatar for this tier.
  Color get tierRingColor {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFFCBD5E1);
      case SubscriptionTier.weekly:
        return const Color(0xFF7DD3FC);
      case SubscriptionTier.basic:
        return const Color(0xFF6EE7B7);
      case SubscriptionTier.premium:
        return const Color(0xFFFBBF24);
      case SubscriptionTier.premiumVip:
        return const Color(0xFFFDE68A);
    }
  }

  /// Soft tinted background for the icon circle in PremiumBadgeWithDetails.
  Color get tierIconBg {
    switch (this) {
      case SubscriptionTier.free:
        return const Color(0xFFF1F5F9);
      case SubscriptionTier.weekly:
        return const Color(0xFFE0F2FE);
      case SubscriptionTier.basic:
        return const Color(0xFFD1FAE5);
      case SubscriptionTier.premium:
        return const Color(0xFFFEF3C7);
      case SubscriptionTier.premiumVip:
        return const Color(0xFFFEF3C7);
    }
  }

  /// Icon for this tier.
  IconData get tierIcon {
    switch (this) {
      case SubscriptionTier.free:
        return Icons.circle_outlined;
      case SubscriptionTier.weekly:
        return Icons.timer_rounded;
      case SubscriptionTier.basic:
        return Icons.verified_rounded;
      case SubscriptionTier.premium:
        return Icons.star_rounded;
      case SubscriptionTier.premiumVip:
        return Icons.workspace_premium_rounded;
    }
  }
}

/// Whether the subscription state is still loading/initializing
final isSubscriptionLoadingProvider = Provider<bool>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  return subscription.isLoading || !subscription.isInitialized;
});

/// Provider for current subscription tier
final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  final subscription = ref.watch(subscriptionProvider);
  debugPrint(
    '🎫 subscriptionTierProvider: isPremium=${subscription.isPremium}, status=${subscription.status.state}, productId=${subscription.status.productId}, isLoading=${subscription.isLoading}, isInitialized=${subscription.isInitialized}',
  );

  // If not premium, return free tier
  if (!subscription.isPremium) {
    debugPrint('🎫 User is not premium, returning free tier');
    return SubscriptionTier.free;
  }

  // User is premium, resolve the tier from productId
  final tier = SubscriptionTierX.fromProductId(subscription.status.productId);
  debugPrint('🎫 Resolved tier from productId: $tier (isPaid: ${tier.isPaid})');

  // IMPORTANT: If user isPremium but tier resolved to free (e.g., admin grant with
  // missing or unrecognized productId), default to premium tier
  if (!tier.isPaid) {
    debugPrint(
      '🎫 WARNING: isPremium=true but tier is not paid. Defaulting to premium tier.',
    );
    return SubscriptionTier.premium;
  }

  return tier;
});

/// Feature gating provider - determines which features are accessible
/// based on subscription tier
final isFeatureAccessibleProvider = Provider.family<bool, String>((
  ref,
  featureId,
) {
  final tier = ref.watch(subscriptionTierProvider);

  switch (featureId) {
    // Therapist chat: only Premium/VIP with admin-assigned therapist
    case 'therapist_chat':
    case 'chat_access':
      return tier.hasDedicatedTherapist; // Premium and VIP only

    // Unlimited AI chat messages
    case 'unlimited_chat':
      return tier.monthlyAiMessages == -1; // VIP only (unlimited)

    case 'psychological_tests':
      return tier.hasPsychologicalTests; // Basic and above

    case 'dedicated_therapist':
      return tier.hasDedicatedTherapist; // Premium and above

    // Voice session booking (for separate fee) - all paid tiers
    case 'voice_sessions':
    case 'therapy_calls':
    case 'call_booking':
      return tier.isPaid; // All paid tiers can book for separate fee

    case 'whatsapp_support':
      return tier.hasWhatsAppSupport; // Premium and above

    case 'priority_support':
      return tier.hasPrioritySupport; // Premium VIP only

    case 'exclusive_content':
      return tier.includes(SubscriptionTier.premium); // Premium and above

    case 'faster_response':
      return tier.includes(SubscriptionTier.basic); // Basic and above

    // Free features (available to all)
    case 'mood_tracking':
    case 'community':
    case 'ai_chat':
    case 'meditation':
    case 'view_therapists':
    case 'support_chat':
      return true;

    default:
      // Default: require at least weekly subscription for unknown features
      return tier.isPaid;
  }
});

/// Check if user can send messages (open to all authenticated users)
final canSendMessagesProvider = Provider<bool>((ref) {
  return true;
});

/// Check if user can access therapist chat (Premium/VIP with dedicated therapist)
final canAccessChatProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.hasDedicatedTherapist; // Premium and VIP only
});

/// Check if user can book therapy calls (premium+ only)
final canBookCallsProvider = Provider<bool>((ref) {
  return ref.watch(isFeatureAccessibleProvider('call_booking'));
});

/// Check if user can access unlimited chat (any paid tier)
final canAccessUnlimitedChatProvider = Provider<bool>((ref) {
  return ref.watch(isFeatureAccessibleProvider('unlimited_chat'));
});

/// Check if user can access mood tracking (always free)
final canAccessMoodTrackingProvider = Provider<bool>((ref) {
  return ref.watch(isFeatureAccessibleProvider('mood_tracking'));
});

/// Check if user can access community (always free)
final canAccessCommunityProvider = Provider<bool>((ref) {
  return ref.watch(isFeatureAccessibleProvider('community'));
});

/// Check if user can access AI chat (always free, limited)
final canAccessAIChatProvider = Provider<bool>((ref) {
  return ref.watch(isFeatureAccessibleProvider('ai_chat'));
});

/// Get remaining free chat messages for current month
final remainingFreeChatMessagesProvider = Provider<int>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.monthlyAiMessages;
});

/// Get remaining voice sessions for current tier
final remainingVoiceSessionsProvider = Provider<int>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  // In a real app, track actual usage in Firestore
  return tier.freeVoiceSessions;
});

/// Check if AI messages are unlimited for current tier
final hasUnlimitedAiMessagesProvider = Provider<bool>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return tier.monthlyAiMessages == -1;
});

/// Get feature access list for current user
final featureAccessListProvider = Provider<Map<String, bool>>((ref) {
  return {
    'chat_access': ref.watch(canAccessChatProvider),
    'call_booking': ref.watch(canBookCallsProvider),
    'unlimited_chat': ref.watch(canAccessUnlimitedChatProvider),
    'mood_tracking': ref.watch(canAccessMoodTrackingProvider),
    'community': ref.watch(canAccessCommunityProvider),
    'ai_chat': ref.watch(canAccessAIChatProvider),
    'psychological_tests': ref.watch(
      isFeatureAccessibleProvider('psychological_tests'),
    ),
    'dedicated_therapist': ref.watch(
      isFeatureAccessibleProvider('dedicated_therapist'),
    ),
    'whatsapp_support': ref.watch(
      isFeatureAccessibleProvider('whatsapp_support'),
    ),
    'priority_support': ref.watch(
      isFeatureAccessibleProvider('priority_support'),
    ),
    'exclusive_content': ref.watch(
      isFeatureAccessibleProvider('exclusive_content'),
    ),
  };
});

/// Get tier-specific limits
final tierLimitsProvider = Provider<Map<String, dynamic>>((ref) {
  final tier = ref.watch(subscriptionTierProvider);
  return {
    'tier': tier,
    'tierName': tier.displayName,
    'tierNameAr': tier.displayNameAr,
    'monthlyAiMessages': tier.monthlyAiMessages,
    'freeVoiceSessions': tier.freeVoiceSessions,
    'hasWhatsAppSupport': tier.hasWhatsAppSupport,
    'hasPrioritySupport': tier.hasPrioritySupport,
    'hasDedicatedTherapist': tier.hasDedicatedTherapist,
    'hasPsychologicalTests': tier.hasPsychologicalTests,
  };
});
