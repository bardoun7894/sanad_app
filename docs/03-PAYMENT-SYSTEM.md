# Payment System Architecture - Sanad App

**Version**: 1.0
**Date**: December 17, 2025
**Status**: Planning Phase

---

## Table of Contents

1. [Overview](#overview)
2. [Pricing Model](#pricing-model)
3. [Payment Gateways](#payment-gateways)
4. [Architecture](#architecture)
5. [Feature Gating](#feature-gating)
6. [Payment Flows](#payment-flows)
7. [Admin Dashboard](#admin-dashboard)
8. [Implementation Details](#implementation-details)

---

## Overview

Sanad implements a dual-gateway payment system supporting both **automatic card payments** and **manual bank transfers**. This enables maximum accessibility for users in Morocco and the broader MENA region.

### Key Principles

- **User Choice**: Two payment options (card vs. bank transfer)
- **Simplicity**: Card payments are instant; bank transfers are manual but lower-fee
- **Accessibility**: No company registration required
- **Compliance**: Full legal transparency with all disclaimers
- **Monetization**: Sustainable revenue with reasonable margins

---

## Pricing Model

### Subscription Tiers

#### Tier 0: Free (Default)

**Price**: FREE
**Features**:
- Browse therapists
- View community content
- Limited chat (5-10 messages/day cap)
- View mood history
- Access educational content

**Business Model**: Conversion funnel to paid tiers

---

#### Tier 1: Chat Subscription

**Price**: $5/month or $5 for 3-week trial
**Duration**: 1 month (auto-renews) or 3 weeks
**Features**:
- ✅ All free features
- ✅ **Unlimited text chat** with AI assistant
- ✅ Unlimited community participation
- ❌ Voice/video calls (separate pay-as-you-go)
- ❌ Therapist bookings (requires call payment)

**Target Users**: Users wanting daily psychological support & chat

**Revenue**: Primary subscription revenue (80% expected)

---

#### Tier 2: Premium (Chat + Calls/Bookings)

**Price**: $5 (chat) + $0.05-0.10/minute (calls) or $3-5/hour packages
**Features**:
- ✅ All chat features
- ✅ Voice/video calls
- ✅ Make therapist bookings
- ✅ 20% discount on call minutes
- ✅ Priority support

**Target Users**: Serious users needing professional therapist sessions

**Revenue**: Secondary revenue (calls + bookings)

---

### Revenue Breakdown

| Tier | Expected % | Primary Revenue |
|------|-----------|-----------------|
| Free | 40% | None (conversion funnel) |
| Chat Sub ($5/mo) | 45% | Subscriptions (auto-renew) |
| Pay-as-you-go (Calls) | 15% | Per-minute billing |

**Estimated Monthly Revenue (1,000 users)**:
- 400 free users → $0
- 450 chat subscribers × $5 = $2,250
- 150 users doing calls (avg. 30 min/mo × $0.075) = $337.50
- **Total**: ~$2,587/month

---

## Payment Gateways

### Gateway 1: Visa/Card Payments (Automatic)

#### Overview

Card payments are processed instantly through PayPal or 2Checkout, with automatic monthly subscription renewal. No manual intervention required.

#### Providers

**Option A: PayPal**
- Supports: Visa, Mastercard, PayPal balance
- Fees: 2.9% + $0.30 per transaction + currency conversion (2-4%)
- Processing: Instant (seconds)
- Renewal: Automatic monthly via PayPal
- Pros: Easy onboarding, user-friendly
- Cons: Highest fees

**Option B: 2Checkout (Verifone)**
- Supports: Visa, Mastercard, local payment methods
- Fees: 4.3% + $1 per transaction
- Processing: Instant
- Renewal: Automatic via 2Checkout
- Pros: Global coverage, better for apps
- Cons: Higher fees than PayPal

**Recommendation**: Start with PayPal (simpler), add 2Checkout later for global expansion

#### Integration Architecture

```
┌─────────────────────────────────┐
│  Sanad Mobile App (Flutter)     │
│  SubscriptionProvider + UI      │
└────────────────┬────────────────┘
                 │
                 ▼
        ┌────────────────┐
        │  Backend API   │ (Node.js/Python/Go)
        │  /payments/    │
        └────────┬───────┘
                 │
          ┌──────┴──────┐
          ▼             ▼
     ┌─────────┐   ┌──────────────┐
     │ PayPal  │   │ 2Checkout    │
     │ REST API│   │ REST API     │
     └─────────┘   └──────────────┘
          │             │
          └──────┬──────┘
                 ▼
        ┌────────────────┐
        │ Webhook Handler│
        │ Payment Status │
        └────────┬───────┘
                 │
                 ▼
        ┌────────────────┐
        │  Sanad Backend │
        │  Update Status │
        └────────┬───────┘
                 │
                 ▼
        ┌────────────────┐
        │  App Polling   │
        │ Fetch Status   │
        └────────────────┘
```

#### Payment Flow (Card)

1. User selects "Subscribe with Card"
2. App shows subscription options ($5/month or 3 weeks)
3. User clicks "Continue to Payment"
4. App opens PayPal/2Checkout payment interface (webview/external)
5. User enters card details (PayPal/2Checkout handles security)
6. Payment processor approves/declines
7. Webhook sent to backend with payment confirmation
8. Backend:
   - Validates webhook signature
   - Updates user.subscriptionStatus = "active"
   - Calculates expiry date (30 days)
   - Saves to database
9. App polls backend for updated status (or receives push notification)
10. SubscriptionProvider updates state
11. UI rebuilds, premium features unlock
12. Monthly: PayPal auto-renews (user can cancel in PayPal settings)

#### API Endpoints (Backend)

**POST /api/v1/payments/create-subscription**
```json
{
  "userId": "user123",
  "planId": "chat_monthly",
  "gateway": "paypal",
  "successUrl": "sanad://subscription/success",
  "cancelUrl": "sanad://subscription/cancel"
}
```

**POST /api/v1/webhooks/paypal** (Webhook)
```json
{
  "event_type": "BILLING.SUBSCRIPTION.CREATED",
  "resource": {
    "id": "I-12345",
    "status": "APPROVAL_PENDING",
    "custom_id": "user123",
    "links": {...}
  }
}
```

**GET /api/v1/users/{userId}/subscription**
```json
{
  "status": "active",
  "planId": "chat_monthly",
  "gateway": "paypal",
  "expiryDate": "2026-01-17",
  "autoRenew": true,
  "lastPayment": "2025-12-17"
}
```

---

### Gateway 2: Bank Transfer (Manual)

#### Overview

Users can pay via bank transfer with manual admin verification. Lower fees but slower process (1-24 hours).

#### Methods

**Option A: Wise**
- International transfers to Morocco/UAE account
- Fees: 0.5-1% (very low)
- Processing: 1-3 business days
- Pros: Lowest fees, international reach
- Cons: Slow, requires manual verification

**Option B: Payzone/CMI (Local)**
- Local payment method for Morocco
- Fees: Variable (usually 1-2%)
- Processing: 1-2 days
- Pros: Instant for local users
- Cons: Only works in Morocco

**Option C: Paystack (alternative)**
- Works in multiple African countries
- Fees: 2% + flat fee
- Good for future expansion

#### Integration Architecture

```
┌──────────────────────────────────┐
│  Sanad Mobile App (Flutter)      │
│  Bank Transfer Payment Screen    │
└──────────────┬───────────────────┘
               │
               ▼
    ┌─────────────────────────┐
    │ Display Bank Details:   │
    │ - IBAN/Account Number   │
    │ - Reference Code        │
    │ - Amount ($5)           │
    └──────────┬──────────────┘
               │ (User transfers from their bank)
               │
               ▼
    ┌──────────────────────────┐
    │ Upload Receipt/Proof     │
    │ In-App Message Form      │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │ Create Payment           │
    │ Verification Message:    │
    │ - To: Admin              │
    │ - Receipt attachment     │
    │ - Reference code         │
    │ - Amount                 │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │ Backend Stores           │
    │ PaymentVerification      │
    │ status: "pending"        │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │ Admin Dashboard          │
    │ Payment Verification     │
    │ Section                  │
    └──────────┬───────────────┘
               │ (Admin reviews)
               │
        ┌──────┴──────┐
        ▼             ▼
    [Verify]     [Reject]
        │             │
        ▼             ▼
    ┌────────┐   ┌────────┐
    │ Update │   │ Notify │
    │ Status │   │ User   │
    │ Active │   │ Reject │
    └────┬───┘   └────────┘
         │
         ▼
    ┌──────────────────┐
    │ Send Notification│
    │ to User: Approved
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────────┐
    │ App Fetches Status   │
    │ subscription.status  │
    │ = "active"           │
    └────────┬─────────────┘
             │
             ▼
    ┌──────────────────────┐
    │ UI Rebuilds          │
    │ Premium Features     │
    │ Unlocked             │
    └──────────────────────┘
```

#### Payment Flow (Bank Transfer)

1. User selects "Subscribe with Bank Transfer"
2. System generates unique reference code: `REF-USER123-202512`
3. App shows modal with:
   - Bank details (Wise/Payzone account)
   - Account holder name
   - Amount: $5
   - Reference code (copy to clipboard)
4. User initiates transfer from their bank app/website
   - Amount: $5 (or local equivalent)
   - Reference: REF-USER123-202512
5. User returns to Sanad app
6. User clicks "I've Sent Payment"
7. User can upload:
   - Receipt screenshot
   - Payment confirmation
8. In-app message created:
   - To: Admin
   - Subject: "Payment Verification - $5 Chat Subscription"
   - Body: User details, amount, reference, receipt
9. Status: `payment_pending`
10. Admin receives notification
11. Admin checks bank account for transfer
12. Admin verifies amount + reference code match
13. Admin clicks "Verify Payment" in Payment Verification dashboard
14. Backend:
    - Updates user.subscriptionStatus = "active"
    - Sets expiryDate = now + 30 days
    - Sends notification to user
15. User receives push: "Your subscription is now active!"
16. App fetches updated status
17. SubscriptionProvider updates
18. UI rebuilds, premium features unlock

#### Admin Dashboard (Backend)

**View**: Payment Verification Queue
- List of pending verifications
- User details
- Amount
- Reference code
- Receipt image (if uploaded)
- "Verify" / "Reject" buttons
- Notes field

**Actions**:
- Click "Verify" → Activates subscription + sends user notification
- Click "Reject" → Marks as rejected + sends reason to user
- Search by reference code
- Filter by date

---

## Architecture

### Database Schema

**users Table**
```sql
ALTER TABLE users ADD COLUMN (
  subscription_status ENUM('free', 'active', 'expired', 'pending', 'cancelled'),
  subscription_plan VARCHAR(50),  -- 'chat_monthly', 'chat_3weeks'
  subscription_start_date DATETIME,
  subscription_expiry_date DATETIME,
  payment_gateway VARCHAR(20),    -- 'paypal', '2checkout', 'bank_transfer'
  auto_renew BOOLEAN DEFAULT true,
  paypal_subscription_id VARCHAR(255),  -- For PayPal subscriptions
  payment_method_id VARCHAR(255)
);
```

**payments Table**
```sql
CREATE TABLE payments (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  plan_id VARCHAR(50),
  gateway VARCHAR(20),  -- 'paypal', '2checkout', 'bank_transfer'
  amount DECIMAL(10, 2),
  currency VARCHAR(3),  -- 'USD'
  status ENUM('pending', 'processing', 'completed', 'failed', 'refunded'),
  reference_code VARCHAR(100),
  transaction_id VARCHAR(255),
  webhook_id VARCHAR(255),
  created_at DATETIME,
  completed_at DATETIME,
  metadata JSON,  -- Any extra data
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**payment_verifications Table** (For bank transfers)
```sql
CREATE TABLE payment_verifications (
  id VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  payment_id VARCHAR(255),
  amount DECIMAL(10, 2),
  reference_code VARCHAR(100),
  status ENUM('pending', 'verified', 'rejected'),
  receipt_url VARCHAR(500),
  admin_notes TEXT,
  verified_by VARCHAR(255),
  verified_at DATETIME,
  created_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (payment_id) REFERENCES payments(id)
);
```

### Backend Services

**PaymentService** (Core logic)
```
- createSubscription(userId, planId, gateway)
- handlePaymentWebhook(webhookData)
- verifyPayment(paymentId)
- cancelSubscription(userId)
- refundPayment(paymentId)
- checkSubscriptionExpiry()
- renewSubscription(userId)
```

**PayPalService** (Gateway integration)
```
- createBillingPlan(planId, amount, interval)
- createBillingAgreement(userId, planId)
- validateWebhook(webhookData)
- cancelAgreement(agreementId)
- getAgreementStatus(agreementId)
```

**2CheckoutService** (Gateway integration)
```
- createSubscription(userId, planId)
- validateWebhook(webhookData)
- cancelSubscription(subscriptionId)
- getSubscriptionStatus(subscriptionId)
```

**BankTransferService** (Manual verification)
```
- generateReferenceCode(userId)
- getBankDetails()
- createPaymentVerification(userId, receiptUrl)
- verifyPayment(paymentId) [Admin action]
- rejectPayment(paymentId, reason)
```

---

## Feature Gating

### Gating Logic

```dart
// Pseudo-code

bool canAccessChat(User user) {
  return user.subscriptionStatus == 'active' ||
         DateTime.now().isBefore(user.subscriptionExpiryDate);
}

bool canAccessCalls(User user) {
  return user.subscriptionStatus == 'active' &&
         user.balance >= costPerMinute;
}

bool canBookTherapist(User user) {
  return canAccessCalls(user);
}

int getMessageLimit(User user) {
  if (canAccessChat(user)) return unlimited;
  return 10;  // Free limit
}

double getCallDiscount(User user) {
  if (canAccessChat(user)) return 0.20;  // 20% discount
  return 0.0;
}
```

### UI Implementation

**Chat Screen Gating**:
```dart
if (!isPremium) {
  return UpgradeCTA(
    title: "Unlimited Chat",
    message: "Subscribe for unlimited conversations",
    onTap: () => navigate('/subscription')
  );
}
```

**Call Gating**:
```dart
if (!isCallEligible) {
  return OutlineButton(
    label: "Make a Call",
    enabled: false,
    onTap: () => showUpgradeSheet(),
  );
}
```

**Message Counter**:
```dart
Text("${messageCount}/${messageLimit} messages today")
```

---

## Payment Flows

### Complete User Journey - Card Payment

```
Day 1: Free User Browsing
├─ Tries to send unlimited message
├─ Hits 10-message limit
├─ Sees "Upgrade to Premium" button
├─ Taps button → SubscriptionScreen
└─ Sees price: $5/month or $5 for 3 weeks

Day 1: User Chooses Card Payment
├─ Selects "$5 for 1 month"
├─ Taps "Continue with Card"
├─ PayPal webview opens
├─ Enters Visa details: 4111111111111111
├─ Completes payment
├─ PayPal confirms: "Subscription Active"
└─ Closes webview

Day 1: Backend Processing
├─ PayPal webhook received
├─ Backend validates signature
├─ Creates payment record
├─ Updates user.subscription_status = 'active'
├─ Sets expiry = 2026-01-17
├─ Sends push notification
└─ Updates cache

Day 1: App Updates
├─ App polls /api/users/{id}/subscription
├─ Gets: { status: 'active', expiry: '2026-01-17' }
├─ SubscriptionProvider state updates
├─ UI rebuilds
├─ Message limit removed
└─ User sends unlimited messages

Days 2-30: Active Subscription
├─ User enjoys unlimited chat
├─ Premium badge on profile
├─ Can make voice calls (pay-per-minute)
└─ No interruptions

Day 30: Auto-Renewal
├─ PayPal charges $5 automatically
├─ Backend webhook received
├─ Expiry extended to 2026-02-17
└─ User stays active

Day 60: User Cancels
├─ User goes to PayPal account
├─ Cancels billing agreement
├─ PayPal sends webhook: cancelled
├─ Backend updates status = 'cancelled'
├─ App shows: "Subscription ends 2026-02-17"
├─ After expiry date
├─ status = 'expired'
├─ Message limit re-enabled
└─ User prompted to resubscribe
```

### Complete User Journey - Bank Transfer

```
Day 1: Free User Browsing
├─ Same as card payment
└─ Sees price options

Day 1: User Chooses Bank Transfer
├─ Selects "$5 for 1 month"
├─ Taps "Continue with Bank Transfer"
├─ System generates REF-USER123-202512
├─ Modal shows:
│  ├─ Wise Bank Account: [IBAN]
│  ├─ Account Name: Sanad App
│  ├─ Amount: $5
│  └─ Reference: REF-USER123-202512 [Copy]
├─ User initiates transfer from their bank
├─ Returns to app, clicks "I've Sent Payment"
├─ Optionally uploads receipt
└─ Status: payment_pending

Day 1: Backend
├─ Creates payment record
├─ Status: pending
├─ Creates payment_verification record
├─ Status: pending
└─ Notifies admin

Admin (Day 1, afternoon):
├─ Sees notification: "Payment verification pending"
├─ Opens Payment Dashboard
├─ Sees: REF-USER123-202512, $5, pending
├─ Checks Wise bank account
├─ Confirms $5 received with reference
├─ Clicks "Verify Payment"
└─ Confirms

Backend (Day 1, admin action):
├─ Updates payment.status = 'completed'
├─ Updates user.subscription_status = 'active'
├─ Sets expiry = now + 30 days
├─ Sends push notification to user
└─ Updates cache

User (Day 1, evening):
├─ Receives push: "Subscription Approved!"
├─ Opens app
├─ App polls for status
├─ Gets: { status: 'active' }
├─ SubscriptionProvider updates
├─ Unlimited messaging unlocked
└─ Starts using premium features

Days 2-30: Active Subscription
├─ Same as card payment
└─ Manual renewal needed

Day 31: Expires
├─ Backend cron checks subscriptions
├─ Finds expired (status = 'active' but date passed)
├─ Updates status = 'expired'
├─ Sends notification to user
└─ Message limit re-enabled
```

---

## Admin Dashboard

### Payment Verification Section

**URL**: `/admin/payments/verification`

**View**: List of pending verifications

**Columns**:
- User name
- Amount ($5)
- Reference code (REF-USER123-202512)
- Receipt (thumbnail)
- Submitted date
- Status badge (Pending/Verified/Rejected)

**Actions**:
- Click row → View details
- "Verify" button → Mark verified + activate subscription
- "Reject" button → Reject + message user reason
- Search by reference
- Filter by date range

**Details Modal**:
- User profile (name, email, ID)
- Amount
- Reference code
- Bank details they used
- Receipt full view
- Admin notes text area
- Verify / Reject buttons
- Audit log (who verified, when)

---

## Implementation Details

### Phase 1-2: Card Payment Integration

**Dependencies**:
- `stripe_flutter` or `paypal_checkout` (depending on choice)
- `http` package for API calls
- `dio` for webhooks

**Create**:
1. `PaymentProvider` (StateNotifier)
2. `PaymentService` (card processing)
3. PaymentScreen (card selection)
4. SubscriptionCard widget

**Modify**:
1. SubscriptionProvider (integrate with PaymentProvider)
2. Chat/Call screens (feature gating)

---

### Phase 2-3: Bank Transfer Integration

**Create**:
1. `BankTransferService`
2. BankTransferScreen
3. ReceiptUploadWidget
4. PaymentVerificationMessage (in chat system)

**Modify**:
1. MessagesProvider (admin notification)
2. ProfileScreen (show subscription status)

---

### Testing Strategy

**Card Payment Testing**:
- Use PayPal/2Checkout sandbox
- Test successful payment
- Test failed payment
- Test cancellation
- Test webhook handling

**Bank Transfer Testing**:
- Manual testing with real small transfer
- Test receipt upload
- Test admin verification
- Test notification delivery

---

## Compliance & Legal

### Payment Terms (Must Display)

"All payments are processed securely through PayPal/2Checkout (card) or direct bank transfer (bank). Your payment details are never stored on Sanad servers."

### Subscription Terms

"Subscriptions auto-renew monthly unless cancelled. You can cancel anytime through PayPal settings (card) or by messaging admin (bank transfer)."

### Refund Policy

"Refunds available within 7 days of purchase for full reimbursement. Contact support via in-app messages."

---

## Launch Checklist

- [ ] PayPal/2Checkout account created
- [ ] Webhook endpoints set up
- [ ] Database schema updated
- [ ] Backend APIs implemented and tested
- [ ] Frontend payment screens built
- [ ] Feature gating logic implemented
- [ ] Admin dashboard for bank transfers
- [ ] Testing with sandbox
- [ ] Testing with real small transaction
- [ ] Legal disclaimers added to app
- [ ] Privacy policy updated
- [ ] Terms of service updated
- [ ] Launch on play store

---

## Future Enhancements

1. **Annual subscriptions** ($50/year vs. $60/year monthly)
2. **Family plans** (discount for multiple users)
3. **Promotional codes** (discounts)
4. **Gift subscriptions**
5. **Server-side receipt validation** (for security)
6. **Chargeback protection**
7. **Subscription analytics** (MRR, churn, LTV)
8. **In-app purchase for calls** (instead of separate API)
9. **Crypto payments** (optional, for unbanked users)

---

**Document Version**: 1.0
**Last Updated**: December 17, 2025
**Status**: Ready for Implementation
