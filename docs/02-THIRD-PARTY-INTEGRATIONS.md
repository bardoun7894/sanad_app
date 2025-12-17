# Third-Party Integrations Guide - Sanad App

**Document Version:** 1.0
**Last Updated:** 2025-12-17
**Status:** Recommended Solutions for Sprint 1+

---

## Overview

This document outlines recommended third-party services for chat, calls, and payments in the Sanad mental health app. These solutions are chosen based on cost-effectiveness, ease of integration with Flutter, and scalability.

---

## 1. Voice & Video Calls Solution

### Recommended: Agora (Budget-Friendly)

**Why Agora for Sanad:**
- 10,000 free minutes per month (generous free tier)
- Excellent Flutter support with ready-to-use SDK
- Best cost-to-quality ratio for mental health apps
- Reliable for both 1-on-1 therapist calls and group support sessions
- Strong security and data privacy (important for mental health)

**Pricing Breakdown:**
```
Free Tier:      10,000 minutes/month
Audio Calls:    $0.99 per 1,000 minutes
HD Video:       $3.99 per 1,000 minutes
Full HD Video:  $8.99 per 1,000 minutes
```

**For Sanad MVP (estimated usage):**
- 50 active therapist calls/day × 30 min = 1,500 min/month → FREE ✓
- Community voice groups: ~2,000 min/month → FREE ✓
- **Total: ~3,500 min/month → Falls within free tier**

**Flutter Integration:**
```dart
// Add to pubspec.yaml
agora_rtc_engine: ^6.2.0
permission_handler: ^11.4.3

// Basic example
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class TherapistCallScreen extends ConsumerWidget {
  final String channelName;
  final String token; // Generated from Agora API

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AgoraVideoViewer(
      rtcEngine: RtcEngine.create(
        AgoraRtcEngineConfig(appId: 'YOUR_AGORA_APP_ID'),
      ),
      channelEventHandler: RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          // Handle user joined
        },
        onUserOffline: (connection, remoteUid, reason) {
          // Handle user left
        },
      ),
      agoraEventHandler: AgoraEventHandler(
        onLocalUserRegistered: (uid) {
          // User registered
        },
      ),
      channelName: channelName,
      textFieldValue: token,
    );
  }
}
```

**Setup Steps:**
1. Create account at agora.io
2. Create a project and get App ID
3. Generate temporary tokens for calls (backend responsibility)
4. Install agora_rtc_engine package
5. Request microphone/camera permissions
6. Implement call UI with Agora widgets

**Best For:**
- Therapist-to-user 1-on-1 calls ✓
- Community group voice chats ✓
- Crisis support calls ✓

---

## 2. Chat Solution

### Recommended: Firebase Realtime Database + Custom Implementation

**Why Firebase for Sanad:**
- Already integrated in project (Firebase Auth, Cloud Messaging)
- Real-time message sync perfect for therapy chat
- Scalable to 100,000+ concurrent connections
- Built-in security rules for privacy
- No additional cost (included in Firebase free tier initially)

**Alternative: Stream Chat SDK**
If you want a managed solution with more features:
```dart
// Add to pubspec.yaml
stream_chat_flutter: ^8.0.0

// Setup
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

final client = StreamChatClient(
  'your-api-key',
  logLevel: Level.INFO,
);

await client.connectUser(
  User(
    id: userId,
    name: userName,
    image: userImage,
  ),
  client.generateToken(userId),
);
```

**Firebase Realtime Structure:**
```json
{
  "chats": {
    "user_id_1": {
      "therapist_id_1": {
        "messages": {
          "msg_1": {
            "content": "How are you feeling today?",
            "sender": "therapist_id_1",
            "timestamp": 1702816800000,
            "read": false
          }
        }
      }
    }
  },
  "community": {
    "posts": {
      "post_1": {
        "content": "Feeling anxious...",
        "author": "user_id_1",
        "reactions": {
          "❤️": ["user_2", "user_3"],
          "💪": ["user_4"]
        },
        "comments": {
          "comment_1": {
            "content": "You're not alone",
            "author": "user_2"
          }
        }
      }
    }
  }
}
```

**Implementation Pattern:**
```dart
class ChatService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> sendMessage({
    required String chatId,
    required String message,
    required String userId,
  }) async {
    final ref = _database.ref('chats/$chatId/messages').push();
    await ref.set({
      'content': message,
      'sender': userId,
      'timestamp': ServerValue.timestamp,
      'read': false,
    });
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _database
        .ref('chats/$chatId/messages')
        .onValue
        .map((event) {
          final messages = <Message>[];
          if (event.snapshot.value != null) {
            final data = event.snapshot.value as Map;
            data.forEach((key, value) {
              messages.add(Message.fromMap(value as Map));
            });
          }
          return messages;
        });
  }
}
```

**Security Rules:**
```json
{
  "rules": {
    "chats": {
      "$userId": {
        ".read": "auth.uid === $userId",
        ".write": "auth.uid === $userId",
        "$chatId": {
          "messages": {
            ".read": "auth.uid === $userId",
            ".write": "auth.uid === $userId"
          }
        }
      }
    },
    "community": {
      "posts": {
        ".read": "auth != null",
        "$postId": {
          ".write": "root.child('posts').child($postId).child('author').val() === auth.uid"
        }
      }
    }
  }
}
```

**Best For:**
- Therapist-to-user direct chat ✓
- AI assistant chat ✓
- Community messaging ✓
- Simple comment system ✓

---

## 3. Payment Gateway Solution

### Option A: PayPal (Recommended for MVP)

**Why PayPal for Sanad:**
- Works for individuals in Morocco without company registration
- Supports Visa/MasterCard directly
- Easier onboarding than 2Checkout
- Better mobile app support
- Proven track record for mental health apps
- Lower barrier to entry

**Pricing:**
```
Credit Cards:        2.9% + fixed fee per transaction
International:       2.9% + 4% currency conversion fee
No monthly fees
Withdrawal: 1-2 days
```

**Flutter Integration:**
```dart
// Add to pubspec.yaml
flutter_paypal: ^1.0.0
// or use Stripe/Square for more stability

import 'package:flutter_paypal/flutter_paypal.dart';

class TherapistBookingScreen extends ConsumerWidget {
  Future<void> _processPayment(double amount) async {
    try {
      var result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => PaypalCheckout(
            sandboxMode: true, // false for production
            clientId: "YOUR_CLIENT_ID",
            secretKey: "YOUR_SECRET_KEY",
            returnURL: "https://samplesite.com/return",
            cancelURL: "https://samplesite.com/cancel",
            transactions: [
              {
                "amount": amount.toString(),
                "currency": "USD",
                "description": "Therapist Session - Dr. Ahmed",
                "item_number": "therapist_123",
                "items": [
                  {
                    "name": "Session 60 minutes",
                    "quantity": 1,
                    "price": amount.toString(),
                  }
                ]
              }
            ],
            onSuccess: (Map params) async {
              // Save booking to Firebase
              await _saveBooking(params);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment successful!")),
              );
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment failed: $error")),
              );
            },
            onCancel: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment cancelled")),
              );
            },
          ),
        ),
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _processPayment(50.0), // $50 session
      child: Text('Book Session'),
    );
  }
}
```

**Setup Steps:**
1. Go to developer.paypal.com
2. Create Business/Premier account
3. Generate Client ID and Secret Key
4. Add to flutter_paypal package
5. Test in sandbox mode
6. Go live when ready

### Option B: 2Checkout (For International Scalability)

**Why 2Checkout if scaling globally:**
- 200+ countries supported
- 45+ payment methods (not just cards)
- Better for multi-currency transactions
- Lower risk of payment rejections (25% higher approval rate)

**Pricing:**
```
Base:              3.5% + $0.35 per transaction
Currency conversion: 2-5%
International fee:  2%
Chargeback dispute: $15-$45
Withdrawal: 5-7 days
```

**Comparison Table:**
```
Feature              PayPal         2Checkout
For Individuals      ✓ Excellent    ✓ Good
Morocco Support      ✓ Full         ✓ Supported
Visa/MasterCard      ✓              ✓
Setup Complexity     Simple         Complex
Fees                 2.9%           3.5%
Payment Methods      6              45+
Mobile App           ✓              ✗
Withdrawal Speed     1-2 days       5-7 days
```

**Recommendation for Sanad:**
→ **Start with PayPal** (easier to implement, cheaper fees)
→ **Add 2Checkout later** (if expanding to MENA/Europe/Africa)

---

## 4. WhatsApp Payment Option

For users without bank cards, integrate WhatsApp transfers:

```dart
class BookingPaymentScreen extends ConsumerWidget {
  Future<void> _initiateWhatsAppTransfer() async {
    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=+212XXXXXXXXX&text=Hello, I want to book a session. Please provide payment details.',
    );

    try {
      await launchUrl(whatsappUrl);
    } catch (e) {
      // Fallback: Show manual payment instructions
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('WhatsApp Transfer'),
          content: Text(
            'Contact us on WhatsApp:\n+212 XXX XXX XXX\n\n'
            'Please mention your booking ID: ${bookingId}'
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // PayPal button
        PayPalCheckoutButton(amount: "50.00"),

        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 16),

        // WhatsApp alternative
        ElevatedButton.icon(
          icon: Icon(Icons.chat),
          label: Text('Pay via WhatsApp'),
          onPressed: _initiateWhatsAppTransfer,
        ),
      ],
    );
  }
}
```

---

## 5. Firebase Cloud Functions for Payment Processing

Backend payment handling:

```javascript
// functions/processPayment.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const paypal = require('paypal-rest-sdk');

paypal.configure({
  mode: process.env.PAYPAL_MODE,
  client_id: process.env.PAYPAL_CLIENT_ID,
  client_secret: process.env.PAYPAL_SECRET,
});

exports.createPayment = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { amount, therapistId, sessionDate } = data;

  const paymentJson = {
    intent: 'sale',
    payer: {
      payment_method: 'paypal',
    },
    redirect_urls: {
      return_url: 'https://app.sanad.com/payment/return',
      cancel_url: 'https://app.sanad.com/payment/cancel',
    },
    transactions: [
      {
        amount: {
          total: amount,
          currency: 'USD',
          details: {
            subtotal: amount,
          },
        },
        description: `Therapy session with Dr. ${therapistId}`,
        item_list: {
          items: [
            {
              name: 'Therapy Session (60 min)',
              sku: `session_${therapistId}`,
              price: amount,
              quantity: 1,
              currency: 'USD',
            },
          ],
        },
        custom: JSON.stringify({
          userId: context.auth.uid,
          therapistId,
          sessionDate,
        }),
      },
    ],
  };

  try {
    const payment = await new Promise((resolve, reject) => {
      paypal.payment.create(paymentJson, (err, payment) => {
        if (err) reject(err);
        else resolve(payment);
      });
    });

    // Store payment record
    await admin.firestore().collection('payments').doc(payment.id).set({
      userId: context.auth.uid,
      therapistId,
      amount,
      sessionDate,
      paypalPaymentId: payment.id,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Return approval URL
    const approvalUrl = payment.links.find((l) => l.rel === 'approval_url');
    return { approvalUrl: approvalUrl.href };
  } catch (error) {
    console.error('Payment creation error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to create payment'
    );
  }
});

exports.executePayment = functions.https.onCall(async (data, context) => {
  const { paymentId, payerId } = data;

  try {
    const payment = await new Promise((resolve, reject) => {
      paypal.payment.execute(
        paymentId,
        { payer_id: payerId },
        (err, payment) => {
          if (err) reject(err);
          else resolve(payment);
        }
      );
    });

    // Update payment record
    await admin.firestore().collection('payments').doc(paymentId).update({
      status: 'completed',
      payerId,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Get payment document to retrieve booking details
    const paymentDoc = await admin
      .firestore()
      .collection('payments')
      .doc(paymentId)
      .get();

    const { therapistId, sessionDate, userId } = paymentDoc.data();

    // Create booking record
    await admin.firestore().collection('bookings').add({
      userId,
      therapistId,
      sessionDate,
      paymentId,
      status: 'confirmed',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, bookingId: paymentId };
  } catch (error) {
    console.error('Payment execution error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to execute payment'
    );
  }
});
```

---

## 6. Implementation Timeline

### Sprint 1 (Now)
- [x] Authentication ✓
- [ ] **Add PayPal integration for booking payments**
- [ ] Chat implementation (Firebase Realtime)

### Sprint 2
- [ ] Agora voice calls for therapist sessions
- [ ] Community group voice chats

### Sprint 3
- [ ] Payment history and refunds
- [ ] 2Checkout integration (if expanding internationally)

---

## 7. Environment Variables

Create `.env` file (never commit to git):

```
# PayPal
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_SECRET=your_paypal_secret
PAYPAL_SANDBOX_MODE=true

# Agora
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_certificate

# Firebase
FIREBASE_PROJECT_ID=your_firebase_project
FIREBASE_API_KEY=your_firebase_key

# WhatsApp
WHATSAPP_BUSINESS_NUMBER=+212XXXXXXXXX
```

Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_dotenv: ^5.1.0
```

Usage in code:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentConfig {
  static final paypalClientId = dotenv.env['PAYPAL_CLIENT_ID']!;
  static final agoraAppId = dotenv.env['AGORA_APP_ID']!;
}
```

---

## 8. Security Considerations

### Payment Data
- Never store full credit card numbers (PCI-DSS violation)
- Use tokenization (PayPal handles this)
- Always process payments on secure backend
- Validate amounts server-side

### Voice/Video Calls
- Agora tokens should be generated server-side
- Tokens should expire after session ends
- Use end-to-end encryption for sensitive calls
- Log all calls for dispute resolution

### Chat Messages
- Encrypt sensitive therapy notes (Firebase encryption at rest)
- Message retention policies (archive old chats)
- User privacy: anonymous options where possible
- Compliance with GDPR/local data protection laws

---

## 9. Cost Estimation for MVP

```
Service              Monthly Cost (Estimated)
Firebase             $0 (free tier)
Agora (calls)        $0 (10,000 min free)
PayPal               ~$5-20 (2.9% of bookings)
Cloud Functions      $0-5 (free tier mostly)
──────────────────────────────────
TOTAL MVP            $0-25/month
```

**Scaling (10,000 active users):**
```
Agora (100 calls/day)      $50-100/month
PayPal (50 bookings/month) $50-100/month
Firebase upgrade           $25-50/month
──────────────────────────────────
TOTAL SCALED               $150-250/month
```

---

## 10. Recommended Tech Stack Summary

| Component | Solution | Why |
|-----------|----------|-----|
| Authentication | Firebase Auth ✓ | Already implemented |
| Chat | Firebase Realtime | Real-time, scalable, integrated |
| Voice/Video | Agora | Budget-friendly, 10k free mins |
| Payments | PayPal → 2Checkout | Easy MVP, enterprise scaling |
| Hosting | Firebase + Cloud Functions | Cost-effective, serverless |
| Database | Firestore + Realtime DB | NoSQL, real-time sync |

---

## Related Documentation

- `00-PROJECT-OVERVIEW.md` - Project scope
- `01-ARCHITECTURE.md` - System design
- `04-AUTHENTICATION.md` - Auth implementation

---

**Last Updated:** 2025-12-17

**Next Steps:**
1. Set up PayPal Developer account
2. Add paypal_sdk_flutter to pubspec.yaml
3. Implement payment processing in Sprint 1
4. Test with sample transactions
5. Go live with PayPal when ready
6. Add Agora calls in Sprint 2
