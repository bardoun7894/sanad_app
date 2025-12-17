# Sanad Payment System - Implementation Summary

**Date**: December 17, 2025
**Status**: Planning & Documentation Complete

---

## What Has Been Planned

A complete **dual-gateway payment system** for the Sanad mental health app with the following features:

### Payment Options

#### Option 1: Card Payments (Visa/Mastercard) - AUTOMATIC
- **Gateways**: PayPal or 2Checkout
- **Speed**: Instant (seconds)
- **Features**:
  - User enters card details in PayPal/2Checkout interface
  - Payment confirmed immediately
  - Subscription activated automatically
  - Auto-renews monthly
  - User cancels via PayPal settings
- **Fees**: 2.9% (PayPal) or 4.3% (2Checkout)
- **Expected Volume**: 80% of payments

#### Option 2: Bank Transfer - MANUAL
- **Methods**: Wise, Payzone, or local payment services
- **Speed**: 1-24 hours (manual verification)
- **Features**:
  - System generates unique reference code
  - Shows user bank account details
  - User transfers $5 from their bank
  - User uploads receipt/proof in app
  - System sends message to admin
  - Admin verifies and activates subscription
  - User gets notification when approved
- **Fees**: 0.5-1% (very low)
- **Expected Volume**: 20% of payments
- **Best for**: Local users in Morocco, bulk transfers

---

## Pricing Tiers

### Tier 1: Free (Default)
- **Cost**: $0 (Forever free)
- **Features**:
  - ✅ Browse therapists
  - ✅ Mood tracking (unlimited)
  - ✅ View community
  - ✅ View educational content
  - ❌ Message/Chat (requires subscription)
  - ❌ Book therapy call (requires subscription)
- **Purpose**: Conversion funnel to paid features

### Tier 2: Chat Subscription
- **Cost**: $5/month
- **Duration**: Monthly (auto-renewable)
- **Features**:
  - ✅ All free features
  - ✅ Unlimited messaging/chat
  - ❌ Book therapy calls (requires payment per call)
- **Revenue**: Primary (~$2,250/month for 450 users × $5)

### Tier 3: Therapy Call Booking
- **Cost**: $5/hour (pay-per-minute)
  - 1 hour = $5.00
  - 30 minutes = $2.50
  - 15 minutes = $1.25
- **Type**: Pay-as-you-go (separate from subscription)
- **Features**:
  - Voice/video call with therapist
  - Call duration-based billing
  - Payment required BEFORE booking
- **Prerequisites**: Must have active $5/month subscription
- **Revenue**: Secondary (~$300-500/month for call users)

---

## Complete Architecture

### Database Changes Required
```sql
-- Add to users table:
- subscription_status (free, active, expired, pending)
- subscription_plan (chat_monthly, chat_3weeks)
- subscription_expiry_date
- payment_gateway (paypal, 2checkout, bank_transfer)
- auto_renew (boolean)
- paypal_subscription_id (for PayPal tracking)

-- New tables:
- payments (id, user_id, amount, status, reference_code)
- payment_verifications (id, user_id, status, receipt_url, verified_by)
```

### Backend APIs Required

**Subscription Management**
```
POST   /api/v1/payments/create-subscription
GET    /api/v1/users/{userId}/subscription
POST   /api/v1/payments/cancel
POST   /api/v1/webhooks/paypal
POST   /api/v1/webhooks/2checkout
```

**Bank Transfer (Admin)**
```
GET    /api/v1/admin/payment-verifications
POST   /api/v1/admin/payment-verifications/{id}/verify
POST   /api/v1/admin/payment-verifications/{id}/reject
```

### Frontend Changes Required

**New Screens**:
1. SubscriptionScreen - Main paywall with pricing
2. PaymentMethodScreen - Choose Card or Bank Transfer
3. CardPaymentScreen - PayPal/2Checkout webview
4. BankTransferScreen - Show bank details + reference code
5. ReceiptUploadScreen - User uploads proof
6. PaymentSuccessScreen - Confirmation

**Modified Screens**:
1. ChatScreen - Gate unlimited messaging
2. CallScreen - Gate calls behind premium
3. ProfileScreen - Show subscription status & badge
4. HomeScreen - Show upgrade CTA for free users

**New Widgets**:
1. SubscriptionCard - Shows price & subscribe button
2. UpgradeCTA - Promotional card
3. PremiumBadge - "PRO" indicator on profile
4. LegalDisclaimer - All required legal texts

### Feature Gating Logic

```dart
// FREE FEATURES - Always available
bool canBrowseTherapists(User user) {
  return true;  // Forever free
}

bool canTrackMood(User user) {
  return true;  // Forever free, unlimited
}

bool canViewCommunity(User user) {
  return true;  // Forever free
}

// PAID FEATURE: Chat/Messaging ($5/month subscription)
bool canAccessChat(User user) {
  return user.subscriptionStatus == 'active' &&
         DateTime.now().isBefore(user.subscriptionExpiryDate);
}

// PAID FEATURE: Therapy Calls ($5/hour, pay-per-minute)
bool canBookTherapyCall(User user) {
  // Requires: Active subscription + Available balance for call
  return user.subscriptionStatus == 'active' &&
         user.balance >= minimumCallDuration;  // e.g., $2.50 for 30 min
}

// Calculate call price: $5/hour = $0.0833/minute
double getCallPrice(Duration callDuration) {
  return (callDuration.inMinutes / 60.0) * 5.0;
}

// Chat access
bool canSendMessage(User user) {
  return canAccessChat(user);  // Cannot message without subscription
}
```

---

## User Journeys

### Journey 1: Free User → Subscribe for Chat ($5/month)

```
1. Free user browsing therapists (free)
2. Tries to send message in chat
3. Sees: "Subscribe to unlock messaging"
4. Clicks "Subscribe Now"
5. SubscriptionScreen shows: "$5/month - Unlimited Chat"
6. Clicks "Continue with Card"
7. PaymentMethodScreen shows:
   [Card (Visa/Mastercard)] [Bank Transfer]
8. Clicks "Card Payment"
9. PayPal webview opens
10. Enters Visa: 4111 1111 1111 1111
11. Completes payment ($5)
12. Returns to app
13. App polls backend: GET /api/v1/users/{id}/subscription
14. Gets: { status: 'active', expiry: '2026-01-17' }
15. SubscriptionProvider updates state
16. UI rebuilds
17. Chat unlocked - can send unlimited messages
18. Monthly: PayPal auto-renews $5
19. User continues with subscription
20. (Optional) User cancels in PayPal settings
21. Status → 'cancelled', expires at end of month
22. After expiry: Chat disabled, can browse for free again
```

**Time**: 2 minutes
**Friction**: Low
**Cost**: $5/month (auto-renews)

---

### Journey 2: Chat Subscription via Bank Transfer (Manual)

```
1. Free user tries to message
2. Sees "Subscribe to unlock messaging"
3. Clicks "Subscribe Now"
4. SubscriptionScreen shows: "$5/month"
5. Clicks "Continue with Bank Transfer"
6. Dialog shows:
   - Bank account: Wise IBAN or local Payzone
   - Reference: REF-USER123-202512
   - Amount: $5
7. User copies reference code
8. User opens their bank app
9. Initiates $5 transfer with reference code
10. Returns to Sanad
11. Clicks "I've Sent Payment"
12. Optionally uploads receipt screenshot
13. Submits
14. System creates message to admin:
    Subject: "Chat Subscription Verification - $5"
    User: User123
    Reference: REF-USER123-202512
    Receipt: [image]
15. Status: payment_pending
16. User sees: "Awaiting verification (1-24 hours)"
17. Admin gets notification
18. Admin checks bank account - confirms $5 received
19. Admin clicks "Verify Payment"
20. Backend updates: subscription_status = 'active'
21. Sends notification to user
22. User receives push: "Subscription Approved!"
23. App polls and fetches updated status
24. UI rebuilds
25. Chat unlocked - can send unlimited messages
26. (Month later) Status expires
27. Chat disabled again
28. User must transfer again for renewal (no auto-renewal)
```

**Time**: 1-24 hours (manual verification)
**Friction**: Medium
**Cost**: $5 (manual renewal required)

---

### Journey 3: Book Therapy Call with Therapist ($5/hour)

```
1. Chat subscriber wants to book a call with therapist
2. Browses therapist list (free)
3. Clicks "Book Call" button on therapist profile
4. Booking form appears:
   - Date & time selector
   - Duration selector: 15 min / 30 min / 1 hour
5. Selects: 1 hour = $5.00 total cost
6. Sees price breakdown:
   - Duration: 1 hour
   - Rate: $5/hour
   - Total: $5.00
7. Clicks "Confirm Booking"
8. Payment processing screen (depends on gateway)

   IF PayPal: Opens PayPal webview, confirms $5 payment
   IF Bank: Shows transfer details, user sends $5 with reference

9. Payment confirmed
10. Booking confirmed
11. Notification sent: "Call with [Therapist] scheduled for [date/time]"
12. At scheduled time:
    - Join call button appears
    - Opens Agora call interface
    - Voice/video connected
13. During call:
    - Duration tracked
    - Timer shows remaining time
14. Call ends after 1 hour
15. Bill generated: $5.00 charged
16. Receipt sent to user
17. User can rate therapist

Note: Chat subscription IS required to book calls.
Payment for call is SEPARATE from chat subscription.
```

**Time**: Instant (for card) or 1-24h (for bank)
**Friction**: Low (integrated with booking)
**Cost**: $5/hour (pay-per-minute, $0.0833/min)


---

## Implementation Phases

### Phase 1: Foundation (2-3 days)
- [ ] Database schema updates
- [ ] Backend API setup (create-subscription, webhooks)
- [ ] PayPal/2Checkout account & integration
- [ ] Wise bank account setup

### Phase 2: Card Payment Flow (3-4 days)
- [ ] PaymentService (PayPal/2Checkout SDK)
- [ ] Webhook handlers
- [ ] PaymentScreen UI
- [ ] Payment success/failure handling
- [ ] Testing with PayPal sandbox

### Phase 3: Bank Transfer Flow (2-3 days)
- [ ] BankTransferService
- [ ] ReceiptUploadWidget
- [ ] Admin dashboard for verification
- [ ] Message integration with admin notification
- [ ] Manual verification workflow

### Phase 4: Feature Gating (1-2 days)
- [ ] Gating logic in ChatProvider
- [ ] Gating logic in CallProvider
- [ ] Message limit enforcement
- [ ] Call discount application
- [ ] UI updates (badges, CTAs)

### Phase 5: Testing (2-3 days)
- [ ] Unit tests for payment logic
- [ ] Integration tests with PayPal sandbox
- [ ] Manual testing of complete flows
- [ ] Edge case testing (failures, cancellations, etc.)
- [ ] Admin dashboard testing

### Phase 6: Deployment (1 day)
- [ ] Database migration
- [ ] Backend deployment
- [ ] App store submission
- [ ] Monitoring & alert setup

**Total Estimated Time**: 11-16 days

---

## Key Implementation Files

### New Files to Create (12+)

**Models**:
1. `lib/features/subscription/models/subscription_product.dart`
2. `lib/features/subscription/models/subscription_status.dart`

**Services**:
3. `lib/features/subscription/services/subscription_storage_service.dart`
4. `lib/features/subscription/services/paypal_service.dart`
5. `lib/features/subscription/services/bank_transfer_service.dart`

**Providers**:
6. `lib/features/subscription/providers/subscription_provider.dart`
7. `lib/features/subscription/providers/payment_provider.dart`

**Screens**:
8. `lib/features/subscription/screens/subscription_screen.dart`
9. `lib/features/subscription/screens/payment_method_screen.dart`
10. `lib/features/subscription/screens/bank_transfer_screen.dart`
11. `lib/features/subscription/screens/receipt_upload_screen.dart`

**Widgets**:
12. `lib/features/subscription/widgets/subscription_card.dart`
13. `lib/features/subscription/widgets/premium_feature_tile.dart`
14. `lib/features/subscription/widgets/upgrade_cta.dart`
15. `lib/features/subscription/widgets/legal_disclaimer.dart`

### Files to Modify (8)

1. `pubspec.yaml` - Add payment SDKs
2. `lib/main.dart` - Initialize payment services
3. `lib/routes/app_router.dart` - Add subscription routes
4. `lib/core/l10n/app_strings.dart` - Payment strings (Arabic)
5. `lib/core/l10n/app_strings_en.dart` - Payment strings (English)
6. `lib/features/chat/chat_screen.dart` - Gate unlimited messaging
7. `lib/features/profile/profile_screen.dart` - Show subscription status
8. `lib/features/calls/call_screen.dart` - Gate calls

---

## Legal & Compliance

### Disclosures Required

1. **Auto-renewal**: "Subscriptions auto-renew monthly unless cancelled"
2. **Cancellation**: "Cancel anytime via PayPal/2Checkout settings (card) or message admin (bank)"
3. **Refund**: "Refunds available within 7 days of purchase"
4. **Payment Security**: "Card details never stored on Sanad servers"
5. **Mental Health**: "Not a substitute for professional medical treatment"

### Privacy Updates Required

- Mention payment processing by PayPal/2Checkout
- Explain bank account usage for transfers
- Data retention policy for payment records
- User rights regarding payment data

---

## Revenue Projection (1,000 users)

| User Segment | Count | Feature | Monthly Revenue |
|--------------|-------|---------|-----------------|
| Free users (browse + mood) | 500 | Free | $0 |
| Chat subscribers | 400 | $5/month messaging | $2,000 |
| Call users | 100 | $5/hour calls (avg 2h/mo) | $1,000 |
| **Total** | 1,000 | | **$3,000/month** |

**After Payment Processing Fees**:
- Chat subs: $2,000 × (1 - 0.03) = $1,940 (3% avg fee)
- Call payments: $1,000 × (1 - 0.03) = $970 (3% avg fee)
- **Net Revenue**: **~$2,910/month**

**Economics Per User**:
- ARPU (Average Revenue Per User): $2.91/month
- Chat subscription rate: 40% (400/1,000 users)
- Call usage rate: 10% (100/1,000 users)
- Churn expectation: 5-10% monthly

---

## Next Steps

1. **Confirm Plan**: Review this summary
2. **Backend Setup**: Create PayPal/2Checkout accounts
3. **Database**: Plan schema changes
4. **Implementation**: Start Phase 1
5. **Testing**: Complete all test cases before launch

---

## Documentation Available

- **Full Payment System Doc**: `docs/03-PAYMENT-SYSTEM.md`
- **Implementation Plan**: `.claude/plans/rosy-sauteeing-waffle.md`
- **Pricing Model**: This document
- **Architecture**: `docs/01-ARCHITECTURE.md`

---

**Status**: Ready for Implementation
**Approval Needed**: Confirm pricing, approve payment gateways
