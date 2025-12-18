# Feature Gating Implementation Guide

**Phase 8**: Add premium feature restrictions and access control

---

## Overview

Feature gating restricts premium features to paying users:
- **Chat Access**: Unlimited messaging (premium only, 10 msgs/month for free)
- **Therapy Calls**: Booking calls with therapists (premium only)
- **Community**: Access community features (free)
- **Mood Tracking**: Log daily moods (free)
- **AI Chat**: Basic AI chat (free)

---

## Components Created

### 1. Feature Gating Provider ✅
**File**: `lib/features/subscription/providers/feature_gating_provider.dart`

**Providers**:
- `isFeatureAccessibleProvider(featureId)` - Generic feature check
- `canAccessChatProvider` - Check chat access
- `canBookCallsProvider` - Check call booking access
- `canAccessUnlimitedChatProvider` - Unlimited chat flag
- `remainingFreeChatMessagesProvider` - Free tier message limit
- `featureAccessListProvider` - Get all feature access flags

**Usage**:
```dart
final canChat = ref.watch(canAccessChatProvider);
if (!canChat) {
  showPaywallOverlay(context, featureName: 'Unlimited Chat');
}
```

---

### 2. Paywall Overlay Widget ✅
**File**: `lib/features/subscription/widgets/paywall_overlay.dart`

**Features**:
- Beautiful modal dialog
- Displays feature description
- Shows premium benefits
- Upgrade CTA button
- Dismissible overlay

**Usage**:
```dart
showPaywallOverlay(
  context,
  featureName: 'Therapy Calls',
  featureDescription: 'Book one-on-one sessions with licensed therapists',
);
```

---

### 3. Premium Badge Widget ✅
**File**: `lib/features/subscription/widgets/premium_badge.dart`

**Components**:
- `PremiumBadge()` - Simple star icon
- `PremiumBadgeWithDetails()` - With expiry date
- `PremiumFeatureTag()` - Inline tag

**Usage**:
```dart
// In profile screen
PremiumBadge(size: 24, showText: true)

// With details
PremiumBadgeWithDetails()

// On chat feature
PremiumFeatureTag()
```

---

## Changes Required in Existing Screens

### 1. Chat Screen
**File**: `lib/features/chat/chat_screen.dart`

**Changes**:
1. Add import:
```dart
import 'package:sanad_app/features/subscription/providers/feature_gating_provider.dart';
import 'package:sanad_app/features/subscription/widgets/paywall_overlay.dart';
```

2. Add to `_ChatScreenState`:
```dart
@override
void initState() {
  super.initState();
  // Check access after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkChatAccess();
  });
}

void _checkChatAccess() {
  final canAccess = ref.read(canAccessChatProvider);
  if (!canAccess) {
    showPaywallOverlay(
      context,
      featureName: 'Unlimited Chat',
      featureDescription: 'Chat with AI and therapists anytime',
    );
  }
}
```

3. Modify `build()` method:
```dart
@override
Widget build(BuildContext context) {
  final canAccess = ref.watch(canAccessChatProvider);

  if (!canAccess) {
    return Scaffold(
      appBar: AppBar(title: Text(s.chatTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(s.subscriptionRequired),
            SizedBox(height: 16),
            SanadButton(
              text: s.upgradeToPremium,
              onPressed: () => context.push('/subscription'),
            ),
          ],
        ),
      ),
    );
  }

  // Existing chat UI code...
  return Scaffold(/* ... */);
}
```

---

### 2. Therapist List/Booking Screen
**File**: `lib/features/therapists/therapist_list_screen.dart`

**Changes**:
1. Add import:
```dart
import 'package:sanad_app/features/subscription/providers/feature_gating_provider.dart';
import 'package:sanad_app/features/subscription/widgets/paywall_overlay.dart';
```

2. Modify build method to check access:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final canBook = ref.watch(canBookCallsProvider);

  if (!canBook) {
    return Scaffold(
      appBar: AppBar(title: Text(s.findTherapist)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_call_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(s.premiumOnly),
            SizedBox(height: 8),
            Text('Book therapy sessions', style: AppTypography.bodySmall),
            SizedBox(height: 16),
            SanadButton(
              text: s.upgradeToPremium,
              onPressed: () => context.push('/subscription'),
            ),
          ],
        ),
      ),
    );
  }

  // Existing therapist list UI...
}
```

3. Add badge to therapist cards (in `TherapistCard` widget):
```dart
Stack(
  children: [
    // Existing card content
    Existing TherapistCard(),

    // Add premium badge in top-right
    Positioned(
      top: 8,
      right: 8,
      child: PremiumFeatureTag(),
    ),
  ],
)
```

---

### 3. Profile Screen
**File**: `lib/features/profile/profile_screen.dart`

**Changes**:
1. Add import:
```dart
import 'package:sanad_app/features/subscription/widgets/premium_badge.dart';
import 'package:sanad_app/features/subscription/providers/subscription_provider.dart';
```

2. Add premium section in profile header:
```dart
// After user name section
if (ref.watch(isPremiumProvider)) ...[
  SizedBox(height: 12),
  PremiumBadgeWithDetails(),
],
```

3. Add subscription management option in settings:
```dart
// In settings section
ListTile(
  leading: Icon(Icons.card_giftcard_outlined),
  title: Text(s.subscription),
  subtitle: ref.watch(subscriptionStatusProvider).state.name,
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () => context.push('/subscription'),
),
```

---

### 4. Home Screen
**File**: `lib/features/home/home_screen.dart`

**Changes**:
1. Add import:
```dart
import 'package:sanad_app/features/subscription/providers/feature_gating_provider.dart';
```

2. Add upgrade CTA card for free users:
```dart
// After existing cards, add:
if (!ref.watch(isPremiumProvider)) ...[
  SizedBox(height: 16),
  GestureDetector(
    onTap: () => context.push('/subscription'),
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                s.upgradeToPremium,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Get unlimited chat and therapy calls',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    ),
  ),
],
```

---

### 5. Community Screen (Optional)
**File**: `lib/features/community/screens/community_screen.dart` (if exists)

**Changes**:
Community is free, but can add upgrade CTA:
```dart
// Add persistent upgrade banner for free users
if (!ref.watch(isPremiumProvider)) ...[
  Container(
    color: AppColors.primary.withValues(alpha: 0.1),
    padding: EdgeInsets.all(12),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: AppColors.primary),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Upgrade to premium for unlimited features',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
        TextButton(
          onPressed: () => context.push('/subscription'),
          child: Text(s.upgradeNow),
        ),
      ],
    ),
  ),
],
```

---

## Implementation Checklist

### Required Changes
- [ ] Update `chat_screen.dart` with access check
- [ ] Update `therapist_list_screen.dart` with access check
- [ ] Update `profile_screen.dart` with premium badge
- [ ] Update `home_screen.dart` with upgrade CTA

### New Components (Already Created)
- [x] `feature_gating_provider.dart` - Feature access logic
- [x] `paywall_overlay.dart` - Paywall modal
- [x] `premium_badge.dart` - Premium badges

### Optional Enhancements
- [ ] Update `community_screen.dart` with banner
- [ ] Add premium filter in therapist list
- [ ] Premium badge on all premium features
- [ ] Analytics tracking for feature access attempts

---

## Testing Checklist

### Functional Tests
- [ ] Free user sees paywall when accessing chat
- [ ] Free user sees paywall when trying to book call
- [ ] Premium user can access all features
- [ ] Premium badge displays on profile
- [ ] Upgrade CTA works (navigates to /subscription)
- [ ] Paywall overlay closes properly

### UI/UX Tests
- [ ] Paywall displays correctly in dark mode
- [ ] Paywall displays correctly in light mode
- [ ] All text is localized (Arabic, English, French)
- [ ] Icons display properly
- [ ] Responsive on different screen sizes

### Edge Cases
- [ ] Subscription expires during session
- [ ] User upgrades from free to premium
- [ ] User downgrades from premium to free
- [ ] Network error during feature check
- [ ] Offline mode behavior

---

## Future Enhancements

1. **Progressive Paywall**
   - Show feature-specific benefits
   - Different copy for different features
   - Video preview of features

2. **Freemium Model**
   - Limited free chat messages (implement `remainingFreeChatMessagesProvider`)
   - Free call with timer
   - Limited community posting

3. **Analytics**
   - Track feature access attempts
   - Track conversion from free to premium
   - Feature usage by subscription tier

4. **A/B Testing**
   - Test different paywall copy
   - Test different CTA placement
   - Test different upgrade incentives

---

## Code Changes Summary

| Screen | Type | Changes | Time |
|--------|------|---------|------|
| chat_screen.dart | Modify | Add access check, paywall | 20 min |
| therapist_list_screen.dart | Modify | Add access check, restrictions | 20 min |
| profile_screen.dart | Modify | Add premium badge, subscription tile | 15 min |
| home_screen.dart | Modify | Add upgrade CTA | 15 min |
| community_screen.dart | Modify (Optional) | Add banner | 10 min |
| feature_gating_provider.dart | Create | ✅ Done | - |
| paywall_overlay.dart | Create | ✅ Done | - |
| premium_badge.dart | Create | ✅ Done | - |

**Total Implementation Time**: ~80 minutes (1-2 hours)

---

## Files Created

```
lib/features/subscription/
├── providers/
│   └── feature_gating_provider.dart ✅ (NEW)
└── widgets/
    ├── paywall_overlay.dart ✅ (NEW)
    └── premium_badge.dart ✅ (NEW)
```

---

## Next Steps

1. Run tests to verify all strings are available (l10n)
2. Manually test each modified screen
3. Test with both free and premium users
4. Test with network offline
5. Create admin dashboard (Phase 9)
6. Run E2E tests (Phase 10)

---

**Status**: Phase 8 - 60% Complete (infrastructure done, screens pending update)
**Next Phase**: Admin Dashboard (Phase 9)
**Estimated Time to Complete Phase 8**: 1-2 hours
