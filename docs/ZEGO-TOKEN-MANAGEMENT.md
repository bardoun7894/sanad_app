# Zego Call Token Management Guide

**Last Updated**: 2026-01-29
**Current Token Status**: ✅ Valid until 2026-01-30 (24 hours)

---

## 📋 Current Configuration

### Active Token
- **AppID**: 1415432561 (sanad)
- **UserID**: bardouni
- **Generated**: 2026-01-29
- **Expires**: 2026-01-30 (24 hours from generation)
- **Status**: ✅ **ACTIVE**

### Server Secret
- **ServerSecret**: `af2b09977575916a4fbbcdeb56c1f82f`
- ⚠️ **IMPORTANT**: Keep this secret secure! Never commit to public repos.

---

## 🔴 CRITICAL: Token Will Expire in 24 Hours

**Current Solution**: Temporary token (testing only)
**Production Solution Needed**: Permanent AppSign OR Server-side token generation

---

## 🎯 Production Solutions

### Option 1: Use Permanent AppSign (RECOMMENDED - Easiest)

**Why This Is Best**:
- ✅ Never expires
- ✅ No server-side logic needed
- ✅ One-time setup
- ✅ Production-ready

**How to Get AppSign**:
1. Go to: https://console.zegocloud.com/
2. Log in with your account
3. Navigate to **Project Management** → **AppID: 1415432561**
4. Go to **Basic Information** tab
5. Copy the **AppSign** value
6. Update `lib/features/booking/screens/call/call_config.dart`:
   ```dart
   static const String appSign = 'YOUR_APPSIGN_FROM_CONSOLE';
   static const String token = ''; // Clear the token
   ```

**That's it!** Calls will work forever without needing to regenerate tokens.

---

### Option 2: Server-Side Token Generation (Advanced)

**Why Use This**:
- More secure (secret stays on server)
- Can control token expiry per user
- Can revoke tokens
- Professional production setup

**Implementation Steps**:

#### Step 1: Create Cloud Function

Create `functions/zego_token.js`:
```javascript
const crypto = require('crypto');
const functions = require('firebase-functions');

/**
 * Generate Zego token server-side
 * Call from app: httpsCallable('generateZegoToken').call({userId: 'user123'})
 */
exports.generateZegoToken = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const appId = 1415432561;
  const serverSecret = functions.config().zego.server_secret; // Store via Firebase config
  const userId = data.userId || context.auth.uid;
  const effectiveTimeInSeconds = data.validity || 86400; // Default 24h

  try {
    // Zego token generation algorithm
    const time = Math.floor(Date.now() / 1000);
    const nonce = Math.floor(Math.random() * 2147483647);

    const payload = JSON.stringify({
      app_id: appId,
      user_id: userId,
      nonce: nonce,
      ctime: time,
      expire: time + effectiveTimeInSeconds
    });

    const hash = crypto.createHash('sha256');
    const signature = hash.update(appId + serverSecret + userId + time).digest('hex');

    const token = Buffer.from(payload).toString('base64') + '.' + signature;

    return {
      success: true,
      token: token,
      expiresAt: time + effectiveTimeInSeconds,
      userId: userId
    };
  } catch (error) {
    console.error('Zego token generation error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to generate token');
  }
});
```

#### Step 2: Configure Server Secret

```bash
# Set server secret in Firebase Functions config
firebase functions:config:set zego.server_secret="af2b09977575916a4fbbcdeb56c1f82f"

# Deploy function
firebase deploy --only functions:generateZegoToken
```

#### Step 3: Update Flutter App

Update `call_helper.dart`:
```dart
import 'package:cloud_functions/cloud_functions.dart';

class CallHelper {
  static Future<String> _getZegoToken(String userId) async {
    final functions = FirebaseFunctions.instance;

    try {
      final result = await functions
          .httpsCallable('generateZegoToken')
          .call({'userId': userId});

      return result.data['token'] as String;
    } catch (e) {
      debugPrint('Failed to get Zego token: $e');
      throw Exception('Could not initialize call');
    }
  }

  static Future<void> startAudioCall({
    required BuildContext context,
    required String calleeUserId,
    required String calleeName,
    required String callerUserId,
    required String callerName,
  }) async {
    // Validate Zego configuration
    if (CallConfig.appId == 0) {
      _showError(context, 'Call configuration error: Invalid App ID');
      return;
    }

    // Get fresh token from server
    String token;
    try {
      token = await _getZegoToken(callerUserId);
    } catch (e) {
      _showError(context, 'Failed to initialize call: $e');
      return;
    }

    // Generate unique call ID
    final callID = _generateCallID(callerUserId, calleeUserId);

    // Navigate to call screen with fresh token
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallPage(
          callID: callID,
          userID: callerUserId,
          userName: callerName,
          isVideo: false,
          token: token, // Pass fresh token
        ),
      ),
    );
  }
}
```

Update `call_page.dart` to accept token parameter:
```dart
class CallPage extends StatelessWidget {
  final String callID;
  final String userID;
  final String userName;
  final bool isVideo;
  final String? token; // Add optional token parameter

  const CallPage({
    Key? key,
    required this.callID,
    required this.userID,
    required this.userName,
    this.isVideo = true,
    this.token, // Accept token
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: CallConfig.appId,
        appSign: token ?? CallConfig.appSign, // Use passed token or fallback
        userID: userID,
        userName: userName,
        callID: callID,
        config: isVideo
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
      ),
    );
  }
}
```

---

## 🚨 Immediate Action Required (Before Token Expires)

**You have 3 options**:

### Option A: Get Permanent AppSign (5 minutes)
1. Log into Zego console
2. Copy AppSign
3. Update `call_config.dart`
4. **Done forever!**

### Option B: Implement Server-Side Tokens (2-3 hours)
1. Create Cloud Function (above code)
2. Configure Firebase
3. Update Flutter code
4. Deploy and test

### Option C: Generate New Temporary Token (Every 24h)
1. Go back to https://console.zegocloud.com/developmentTools/tokenTools
2. Generate new token
3. Update `call_config.dart`
4. Repeat every 24 hours

**My Strong Recommendation**: **Option A** (AppSign) - It's the easiest and most reliable.

---

## 📅 Token Expiration Reminder

**Current Token Expires**: 2026-01-30
**Action Needed By**: 2026-01-30 morning

### Set a Calendar Reminder
If you choose to stick with temporary tokens:
- Set reminder for **2026-01-30 at 9:00 AM**
- Title: "Regenerate Zego Token"
- Notes: Use ServerSecret `af2b09977575916a4fbbcdeb56c1f82f`

---

## 🔍 How to Check If Token Is Valid

### Quick Test
1. Open your app
2. Go to therapist chat
3. Tap the audio call button
4. If call screen opens → ✅ Token valid
5. If error → ❌ Token expired

### Programmatic Check
Add this to your code:
```dart
// Check token expiration (decode base64 token)
bool isTokenValid() {
  final token = CallConfig.token;
  if (token.isEmpty) return false;

  try {
    final parts = token.split('.');
    final payload = utf8.decode(base64.decode(parts[0]));
    final json = jsonDecode(payload);
    final expireTime = json['expire'] as int;
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return currentTime < expireTime;
  } catch (e) {
    return false;
  }
}
```

---

## 📝 Current Status Summary

| Item | Status | Notes |
|------|--------|-------|
| AppID | ✅ Configured | 1415432561 |
| Token | ✅ Valid | Expires 2026-01-30 |
| AppSign | ❌ Not Set | Recommended for production |
| ServerSecret | ✅ Known | af2b09977575916a4fbbcdeb56c1f82f |
| Calls Working | ✅ Yes | Until token expires |
| Production Ready | ⚠️ No | Need permanent solution |

---

## 🎯 Next Steps

**Recommended Path**:
1. ✅ Current token works until 2026-01-30 (Done!)
2. 🔜 Get permanent AppSign from console (5 minutes)
3. ✅ Update `call_config.dart` with AppSign
4. ✅ Remove token value
5. ✅ Test calls
6. ✅ **Never worry about this again!**

**Alternative Path** (if you can't get AppSign now):
1. ✅ Current token works until 2026-01-30
2. 🔜 Set calendar reminder for token renewal
3. 🔜 Regenerate token every 24 hours
4. 🔜 Eventually implement server-side generation

---

## 📞 Support

**Zego Documentation**: https://docs.zegocloud.com/
**Token Generation**: https://docs.zegocloud.com/article/11648

---

**Last Token Update**: 2026-01-29 by Claude Code
**Next Action Required**: Before 2026-01-30
