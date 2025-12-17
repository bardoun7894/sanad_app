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
- **Cost**: $0
- **Features**:
  - Browse therapists
  - View content
  - Limited chat (5-10 messages/day)
- **Purpose**: Conversion funnel

### Tier 2: Chat Subscription
- **Cost**: $5/month OR $5 for 3-week trial
- **Auto-renewal**: Yes (monthly)
- **Features**:
  - ✅ Unlimited text chat with AI
  - ✅ Unlimited community access
  - ❌ Voice/video calls (separate)
  - ❌ Bookings (separate)
- **Revenue**: ~$2,250/month (450 users × $5)

### Tier 3: Calls & Bookings
- **Cost**: $0.05-0.10/minute for calls OR $3-5/hour packages
- **Features**:
  - Voice/video calls
  - Therapist bookings
  - 20% discount on call time
- **Type**: Pay-as-you-go (not subscription)
- **Revenue**: Secondary (~15% of total)

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
bool canAccessUnlimitedChat(User user) {
  return user.subscriptionStatus == 'active' &&
         DateTime.now().isBefore(user.subscriptionExpiryDate);
}

bool canMakeCall(User user) {
  return user.hasActiveSubscription && user.balance >= costPerMinute;
}

int dailyMessageLimit(User user) {
  return canAccessUnlimitedChat(user) ? unlimited : 10;
}

double getCallDiscount(User user) {
  return canAccessUnlimitedChat(user) ? 0.20 : 0.0;  // 20% off
}
```

---

## User Journeys

### Journey 1: Free → Card Payment (Happy Path)

```
1. Free user hits 10-message limit in chat
2. Sees "Upgrade to Premium" button
3. Clicks → SubscriptionScreen
4. Sees: "$5/month - Unlimited Chat"
5. Clicks "Continue with Card"
6. PaymentMethodScreen shows:
   [Card Payment] [Bank Transfer]
7. Clicks "Card Payment"
8. PayPal webview opens
9. Enters Visa: 4111 1111 1111 1111
10. Completes payment
11. Returns to app
12. App polls backend: GET /api/v1/users/{id}/subscription
13. Gets: { status: 'active', expiry: '2026-01-17' }
14. SubscriptionProvider updates state
15. UI rebuilds
16. Message limit removed
17. User sends unlimited messages
18. Monthly: PayPal auto-renews $5
19. No interruption
20. (Optional) 30 days later: User cancels in PayPal
21. Status → 'cancelled'
22. Message limit returns after expiry date
```

**Time**: 2 minutes
**Friction**: Low (webview handles security)

---

### Journey 2: Free → Bank Transfer (Manual Path)

```
1. Free user hits message limit
2. Sees "Upgrade to Premium" button
3. Clicks → SubscriptionScreen
4. Clicks "Continue with Bank Transfer"
5. Dialog shows:
   - Bank account: Wise IBAN
   - Reference: REF-USER123-202512
   - Amount: $5
6. User copies reference code
7. User opens their bank app
8. Initiates transfer:
   - Amount: $5
   - Reference: REF-USER123-202512
   - To: Wise account
9. Returns to Sanad
10. Clicks "I've Sent Payment"
11. Optionally uploads receipt screenshot
12. Submits
13. System creates message to admin:
    Subject: "Payment Verification - $5"
    User: User123
    Reference: REF-USER123-202512
    Receipt: [image]
14. Status: payment_pending
15. User sees: "Awaiting verification (1-24 hours)"
16. Admin gets notification
17. Admin opens Payment Verification dashboard
18. Sees: REF-USER123-202512, $5, pending
19. Checks Wise account - confirms $5 received
20. Clicks "Verify Payment"
21. Backend updates: subscription_status = 'active'
22. Sends notification to user
23. User receives push: "Subscription Approved!"
24. App polls and fetches updated status
25. UI rebuilds
26. Message limit removed
27. (Month later) Status expires
28. Message limit returns
29. User must initiate new transfer (no auto-renewal)
```

**Time**: 1-24 hours (includes manual verification)
**Friction**: Medium (requires manual bank transfer)

---

### Journey 3: Call Payment (During Chat)

```
1. Chat subscriber wants to call therapist
2. Clicks "Schedule Call"
3. Therapist selected, duration: 30 minutes
4. System calculates: 30 min × $0.10/min = $3.00
5. With 20% discount (sub): $2.40
6. Shows pricing dialog
7. Click "Confirm Call"
8. Charging screen appears
9. Backend deducts from user balance (if prepaid)
   OR integrates with payment gateway for pay-as-you-go
10. Call connects via Agora (voice/video)
11. Call duration tracked
12. After call ends
13. Charges applied: $2.40
14. Receipt shown
15. Email receipt sent
```

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

| Tier | Users | Monthly |
|------|-------|---------|
| Free | 400 | $0 |
| Chat Sub | 450 | $2,250 |
| Calls (avg 30 min) | 150 | $337.50 |
| **Total** | 1,000 | **$2,587.50** |

**After Fees** (avg 2.5% + payment processor):
- Card: 450 × $5 = $2,250 - 2.5% = $2,193.75
- Bank: 50 × $5 = $250 - 1% = $247.50
- **Net**: ~$2,400/month

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
