# Sanad App - Cloud Functions

Backend webhook handlers for payment processing via Firebase Cloud Functions.

---

## Functions Overview

### 1. PayPal Webhook Handler

**File**: `paypal-webhook/index.js`

Processes webhook events from PayPal for subscription payments.

**Events Handled**:
- `BILLING.SUBSCRIPTION.CREATED` - Subscription activated
- `BILLING.SUBSCRIPTION.UPDATED` - Subscription updated
- `BILLING.SUBSCRIPTION.EXPIRED` - Subscription expired
- `BILLING.SUBSCRIPTION.CANCELLED` - User cancelled subscription
- `BILLING.SUBSCRIPTION.SUSPENDED` - Payment failed (suspended)

**Deployed To**: Firebase Cloud Functions (Gen 2)

### 2. 2Checkout Webhook Handler

**File**: `checkout-webhook/index.js`

Processes webhook events from 2Checkout (Verifone) for payment processing.

**Events Handled**:
- `subscription_activated` - Subscription activated
- `subscription_renewed` - Subscription renewed
- `subscription_cancelled` - Subscription cancelled
- `charge_failed` - Payment failed
- `charge_disputed` - Charge disputed

**Deployed To**: Firebase Cloud Functions (Gen 2)

---

## Deployment

### Prerequisites

```bash
# Install Google Cloud CLI
curl https://sdk.cloud.google.com | bash

# Install Firebase CLI
npm install -g firebase-tools

# Login to Google Cloud
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

### Deploy PayPal Webhook

```bash
cd backend/cloud-functions/paypal-webhook
npm install
gcloud functions deploy paypalWebhook --gen2 --runtime nodejs18 --trigger-http --allow-unauthenticated
```

### Deploy 2Checkout Webhook

```bash
cd backend/cloud-functions/checkout-webhook
npm install
gcloud functions deploy checkoutWebhook --gen2 --runtime nodejs18 --trigger-http --allow-unauthenticated
```

### View Deployed Functions

```bash
gcloud functions list
```

### Get Function URLs

```bash
gcloud functions describe paypalWebhook --gen2 --format='value(serviceConfig.uri)'
gcloud functions describe checkoutWebhook --gen2 --format='value(serviceConfig.uri)'
```

---

## Configuration

### PayPal Setup

1. Go to PayPal Developer Dashboard
2. Create/select your app
3. Go to Webhooks
4. Add webhook URL: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/paypalWebhook`
5. Events: Select all subscription events
6. Save and test

### 2Checkout Setup

1. Go to 2Checkout Merchant Panel
2. Settings → Webhooks
3. Add webhook URL: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/checkoutWebhook`
4. Events: Select all payment/subscription events
5. Save and test

---

## How Webhooks Work

### Payment Flow

```
User subscribes via card
  ↓
PayPal/2Checkout processes payment
  ↓
Payment completed
  ↓
PayPal/2Checkout sends webhook to Cloud Function
  ↓
Cloud Function updates Firestore:
  - user.subscription_status = "active"
  - user.subscription_expiry_date = 30 days from now
  - user.payment_gateway = "paypal" or "2checkout"
  ↓
Sends push notification to user
  ↓
App polls Firestore for updated status
  ↓
UI updates to show premium features
```

---

## Firestore Updates

When payment succeeds, the function updates:

**Users Collection** - `users/{userId}`:
```javascript
{
  subscription_status: "active",
  subscription_plan: "chat_monthly",
  subscription_expiry_date: Timestamp,
  payment_gateway: "paypal" or "2checkout",
  auto_renew: true
}
```

**Payments Collection** - `payments/{paymentId}`:
```javascript
{
  user_id: "userId",
  amount: 5.0,
  currency: "USD",
  status: "completed",
  payment_method: "card",
  gateway_transaction_id: "orderId",
  created_at: Timestamp
}
```

---

## Testing

### Local Testing with Emulator

```bash
# Start Firebase emulator
firebase emulators:start

# In another terminal, test webhook
curl -X POST http://localhost:5001/YOUR_PROJECT/us-central1/paypalWebhook \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "BILLING.SUBSCRIPTION.CREATED",
    "id": "WH-12345",
    "resource": {
      "id": "I-XXXXX",
      "custom_id": "user_test_123",
      "status": "ACTIVE"
    }
  }'
```

### Using ngrok for Local Testing

```bash
# Install ngrok
brew install ngrok

# Expose local function to internet
ngrok http 5001

# Copy ngrok URL and add to webhook settings in PayPal/2Checkout
```

---

## Monitoring

### View Logs

```bash
# PayPal webhook logs
gcloud functions logs read paypalWebhook --gen2 --limit 50 --follow

# 2Checkout webhook logs
gcloud functions logs read checkoutWebhook --gen2 --limit 50 --follow
```

### View Errors

In Firebase Console:
1. Go to Cloud Functions
2. Select function
3. Click "Logs" tab
4. Filter by "Error" level

---

## Troubleshooting

### Webhook Not Triggering

1. Check webhook URL is correct in payment provider settings
2. Verify function is deployed: `gcloud functions list`
3. Check function status: `gcloud functions describe paypalWebhook --gen2`
4. Look at Cloud Function logs for errors

### Permission Errors

Ensure service account has these roles:
- Cloud Functions Developer
- Firestore Editor
- Cloud Messaging Admin

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT \
  --member=serviceAccount:YOUR_SERVICE_ACCOUNT \
  --role=roles/cloudfunctions.developer
```

### User Document Not Updating

1. Check Firestore security rules allow writes from Cloud Function
2. Verify `custom_id` matches user UID in Firebase Auth
3. Check if document exists: `users/{custom_id}`
4. View Firestore logs for permission errors

### No Notifications Sent

1. Ensure FCM (Firebase Cloud Messaging) is enabled
2. Check user has registered FCM tokens: `user.fcm_tokens`
3. Verify notification service is running in app

---

## Production Considerations

### Security

- [ ] Verify webhook signatures from PayPal/2Checkout
- [ ] Implement request throttling
- [ ] Add logging for compliance
- [ ] Encrypt sensitive data in logs
- [ ] Regularly rotate credentials

### Reliability

- [ ] Monitor function execution time
- [ ] Set up alerts for errors
- [ ] Implement retry logic for failed updates
- [ ] Create backup backup strategy for failed payments
- [ ] Test failover scenarios

### Performance

- [ ] Monitor Firestore write throughput
- [ ] Set up capacity planning
- [ ] Consider eventual consistency implications
- [ ] Optimize queries for large user bases

---

## Environment Variables

Consider storing in Firebase Config:

```bash
gcloud functions deploy paypalWebhook \
  --set-env-vars PAYPAL_MODE=production
```

---

## Related Documentation

- **App Implementation**: See `lib/features/subscription/`
- **Firestore Setup**: See `docs/FIRESTORE-SETUP.md`
- **Payment System**: See `docs/PAYMENT_SYSTEM_SUMMARY.md`

---

## Support

For issues or questions:
1. Check Cloud Function logs
2. Review Firestore permissions
3. Verify webhook configuration in payment provider
4. Check app logs for state management issues

---

**Last Updated**: December 17, 2025
**Version**: 1.0
**Status**: Ready for Deployment

