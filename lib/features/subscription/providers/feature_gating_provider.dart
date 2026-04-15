import 'package:flutter/foundation.dart';
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
