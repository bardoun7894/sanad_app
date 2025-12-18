import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'subscription_provider.dart';

/// Feature gating provider - determines which features are accessible
/// based on subscription status
final isFeatureAccessibleProvider =
    Provider.family<bool, String>((ref, featureId) {
  final subscription = ref.watch(subscriptionProvider);

  switch (featureId) {
    // Premium features
    case 'unlimited_chat':
    case 'chat_access':
    case 'therapy_calls':
    case 'call_booking':
      return subscription.isPremium;

    // Free features
    case 'mood_tracking':
    case 'community':
    case 'ai_chat':
    case 'meditation':
      return true;

    default:
      return true; // Default to free access
  }
});

/// Check if user can access chat (premium only)
final canAccessChatProvider = Provider<bool>((ref) {
  return ref.watch(isFeatureAccessibleProvider('chat_access'));
});

/// Check if user can book therapy calls (premium only)
final canBookCallsProvider = Provider<bool>((ref) {
  return ref.watch(isFeatureAccessibleProvider('call_booking'));
});

/// Check if user can access unlimited chat (premium)
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
/// (This is a placeholder - actual implementation depends on your model)
final remainingFreeChatMessagesProvider = Provider<int>((ref) {
  final subscription = ref.watch(subscriptionProvider);

  if (subscription.isPremium) {
    return 9999; // Unlimited for premium
  }

  // Free tier: limited messages per month
  // This would be fetched from Firestore in a real app
  return 10; // Placeholder: 10 free messages per month
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
  };
});
