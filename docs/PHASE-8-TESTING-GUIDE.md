# Phase 8: Authentication Testing & Polish Guide

## Overview

Phase 8 focuses on comprehensive testing of all authentication flows and ensuring the system is production-ready. This guide covers manual testing procedures, Firebase setup requirements, and common issues encountered.

**Status**: Ready for Testing (Phases 1-7 Complete)
**Prerequisites**: Firebase credentials configured in `firebase_options.dart`
**Estimated Time**: 2-3 hours

---

## Part A: Firebase Configuration (Required Setup)

### Before Testing - Firebase Credentials

The authentication system requires Firebase credentials to run. Currently, `lib/firebase_options.dart` contains placeholder values.

#### Option 1: Use Firebase Console (Recommended)

1. **Create Firebase Project**
   ```
   - Go to https://console.firebase.google.com
   - Click "Create Project"
   - Enter project name: "sanad-app"
   - Accept terms and create
   ```

2. **Register iOS App**
   ```
   - Click "Add app" → iOS
   - iOS Bundle ID: com.example.sanadApp
   - Download GoogleService-Info.plist
   - Add to Xcode: ios/Runner/
   ```

3. **Register Android App**
   ```
   - Click "Add app" → Android
   - Package name: com.example.sanad_app
   - SHA-1: Get from `keytool -list -v -keystore ~/.android/debug.keystore`
   - Download google-services.json
   - Place in: android/app/
   ```

4. **Configure Authentication**
   ```
   - Go to Authentication → Sign-in method
   - Enable: Email/Password
   - Enable: Google
     * Click on Google
     * Add support email
     * Add OAuth 2.0 client IDs for Android and iOS (auto-generated)
   ```

5. **Run FlutterFire Configure**
   ```bash
   flutterfire configure
   ```
   This automatically updates `firebase_options.dart` with correct values.

#### Option 2: Manual Configuration

If you have Firebase credentials already:

1. Update `lib/firebase_options.dart` with your project values:
   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'YOUR_API_KEY',
     appId: '1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID',
     messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
     projectId: 'your-project-id',
     storageBucket: 'your-project-id.appspot.com',
   );
   ```

2. Add `google-services.json` to `android/app/`

3. Add `GoogleService-Info.plist` to `ios/Runner/` via Xcode

### Google Sign-In Configuration

For Google Sign-In to work on physical devices/emulators:

**iOS Setup:**
```
1. In Firebase Console → Project Settings → General
2. Download GoogleService-Info.plist
3. In Xcode: Runner → Info → URL Types
4. Add URL scheme from GoogleService-Info.plist (REVERSED_CLIENT_ID field)
```

**Android Setup:**
```
1. Firebase Console auto-generates OAuth client for Android
2. google-services.json is already configured
3. Ensure SHA-1 fingerprint is correctly registered
```

---

## Part B: Manual Testing Procedures

### Test Environment Setup

**Device/Emulator Requirements:**
- Android Emulator API 26+ OR iOS Simulator iOS 12+
- Active internet connection (required for Firebase)
- Valid test email accounts ready

**Test Accounts to Create:**
```
1. Valid email: test@example.com
   Password: Test@1234

2. Valid email with existing account: existing@example.com
   Password: Existing@1234

3. Google Account: (your personal Gmail account)
```

---

### Test Suite 1: Fresh App Install

**Test Case 1.1: First Launch Screen**
```
Steps:
1. Uninstall app completely
2. flutter run --release

Expected Results:
✓ App launches without errors
✓ LoginScreen appears as first screen
✓ No Firebase initialization errors in console
✓ All UI elements render correctly
```

**Test Case 1.2: Network Error Handling**
```
Steps:
1. Turn off WiFi and mobile data
2. Click "Sign In" button without entering credentials

Expected Results:
✓ Form validation error appears (field required)
3. Enter email and password
4. Click "Sign In"

Expected Results:
✓ Loading indicator shows on button (2-3 seconds)
✓ Network error message appears in snackbar
✓ Error message is user-friendly and localized
```

---

### Test Suite 2: Email/Password Authentication

**Test Case 2.1: Sign Up Flow - New User**
```
Steps:
1. On LoginScreen, click "Don't have an account? Sign up"
2. Fill form:
   - Email: test@example.com
   - Password: Test@1234
   - Confirm: Test@1234
   - Check "I agree to terms"
3. Click "Sign Up"

Expected Results:
✓ Loading state shows on button
✓ Navigation to ProfileCompletionScreen after success
✓ No error messages
✓ New user created in Firebase Console → Users
```

**Test Case 2.2: Profile Completion**
```
Prerequisite: Completed Test 2.1

Steps:
1. On ProfileCompletionScreen, fill:
   - Full Name: Test User (required)
   - Phone: +212612345678 (optional)
   - Date of Birth: 1990-01-15 (optional)
   - Gender: Male (optional)
2. Click "Continue"

Expected Results:
✓ Loading state shows
✓ Navigation to HomeScreen after success
✓ User data visible in Firebase User Profile
✓ Profile is marked as complete
✓ Can access main app features
```

**Test Case 2.3: Skip Profile Completion**
```
Prerequisite: Fresh signup

Steps:
1. On ProfileCompletionScreen, click "Skip for now"

Expected Results:
✓ Navigation to HomeScreen
✓ User can still use app
⚠️ Profile completion should be re-prompted on next sessions or in Settings
```

**Test Case 2.4: Sign In - Existing User**
```
Prerequisite: Completed signup (Test 2.1-2.2)

Steps:
1. On LoginScreen, fill:
   - Email: test@example.com
   - Password: Test@1234
2. Click "Sign In"

Expected Results:
✓ Loading state shows (2-3 seconds)
✓ Navigation to HomeScreen
✓ No profile completion screen (profile already complete)
✓ User session is active
```

**Test Case 2.5: Invalid Credentials**
```
Steps:
1. On LoginScreen, fill:
   - Email: test@example.com
   - Password: WrongPassword123
2. Click "Sign In"

Expected Results:
✓ Loading state shows
✓ Error snackbar: "Invalid email or password"
✓ User remains on LoginScreen
✓ Form fields are not cleared
✓ Error is dismissible
```

**Test Case 2.6: Email Validation**
```
Steps:
1. On LoginScreen or SignupScreen
2. Try entering invalid emails:
   - "notanemail"
   - "missing@domain"
   - "@nodomain.com"

Expected Results:
✓ Form validation prevents submit
✓ Error message: "Please enter a valid email"
✓ Sign In/Up button remains disabled
```

**Test Case 2.7: Password Validation**
```
Steps:
1. On SignupScreen
2. Enter password: "short"
3. Confirm: "short"

Expected Results:
✓ Form validation prevents submit
✓ Error message: "Password must be at least 8 characters"
✓ Sign Up button remains disabled
```

**Test Case 2.8: Password Mismatch**
```
Steps:
1. On SignupScreen
2. Fill:
   - Email: newuser@example.com
   - Password: Test@1234
   - Confirm: Different@1234
3. Click "Sign Up"

Expected Results:
✓ Form validation prevents submit
✓ Error message: "Passwords do not match"
✓ Sign Up button remains disabled
```

---

### Test Suite 3: Password Reset

**Test Case 3.1: Forgot Password Flow**
```
Steps:
1. On LoginScreen, click "Forgot password?"
2. On ForgotPasswordScreen, enter: test@example.com
3. Click "Send Reset Link"

Expected Results:
✓ Loading state shows
✓ Success message: "Password reset email sent to test@example.com"
✓ Check email inbox for reset link
✓ (If using Firebase: Email appears in Firebase Console → Templates)
```

**Test Case 3.2: Invalid Email in Password Reset**
```
Steps:
1. On ForgotPasswordScreen
2. Enter: nonexistent@example.com
3. Click "Send Reset Link"

Expected Results:
✓ Success message shown (Firebase doesn't reveal if email exists)
✓ No actual email sent (if user doesn't exist)
```

**Test Case 3.3: Back from Password Reset**
```
Steps:
1. On ForgotPasswordScreen
2. Click back arrow or "Back to Sign In"

Expected Results:
✓ Navigation back to LoginScreen
✓ LoginScreen state is preserved
```

---

### Test Suite 4: Google Sign-In

**Test Case 4.1: Google Sign-In - First Time User**
```
Prerequisites:
- Google account configured
- Internet connection active
- Google Play Services installed (Android) or GmsCore (simulator)

Steps:
1. On LoginScreen, click "Sign in with Google"
2. Select your Google account in popup
3. Grant app permissions

Expected Results:
✓ Loading state shows
✓ Navigation to ProfileCompletionScreen
✓ Name field pre-populated from Google account
✓ New user created in Firebase with Google provider
```

**Test Case 4.2: Google Sign-In - Returning User**
```
Prerequisite: Completed Test 4.1

Steps:
1. Sign out first (via home screen menu)
2. On LoginScreen, click "Sign in with Google"
3. Select same Google account

Expected Results:
✓ Loading state shows
✓ Direct navigation to HomeScreen (no profile screen)
✓ User logged back in instantly
```

**Test Case 4.3: Google Sign-In Error Handling**
```
Steps:
1. On LoginScreen, click "Sign in with Google"
2. Click "Cancel" in Google popup

Expected Results:
✓ Loading state clears
✓ No error message (user cancelled)
✓ Remain on LoginScreen
```

**Test Case 4.4: Google Sign-In - Network Error**
```
Steps:
1. Turn off internet
2. On LoginScreen, click "Sign in with Google"
3. Wait for timeout

Expected Results:
✓ Error message: "Network error. Please check connection"
✓ Loading state clears
✓ Remain on LoginScreen
```

---

### Test Suite 5: Navigation Guards & Redirects

**Test Case 5.1: Unauthenticated Access Protection**
```
Prerequisites:
- App is logged out
- Know a protected route like /home

Steps:
1. Logout if needed
2. Try to deep link to protected route:
   - Use system intent: adb shell am start -a android.intent.action.VIEW -d sanad://home
   - Or in code: GoRouter.of(context).go('/home')

Expected Results:
✓ Redirected to LoginScreen
✓ LoginScreen displays
✓ Previous route is not loaded
```

**Test Case 5.2: Profile Incomplete Redirect**
```
Prerequisites:
- User signed up but didn't complete profile (Test 2.3)

Steps:
1. Force quit app (or navigate directly if possible)
2. Restart app

Expected Results:
✓ App detects profile incomplete status
✓ User redirected to ProfileCompletionScreen
✓ Cannot access main app without completing profile
```

**Test Case 5.3: Authenticated User on Auth Screen**
```
Prerequisites:
- User is logged in with complete profile

Steps:
1. Logout
2. Sign back in
3. Manually try to navigate to /auth/login:
   - Use: GoRouter.of(context).go('/auth/login')
   - Or deep link if implemented

Expected Results:
✓ Navigation to LoginScreen shows briefly
✓ Immediately redirected to HomeScreen
✓ User remains logged in
```

---

### Test Suite 6: Session Persistence

**Test Case 6.1: App Restart - User Session Persists**
```
Prerequisites:
- User is logged in with complete profile

Steps:
1. User logged in on HomeScreen
2. Close app completely (force quit)
3. Reopen app

Expected Results:
✓ App shows no splash screen
✓ HomeScreen appears immediately (or with brief loading)
✓ User remains authenticated
✓ No need to login again
✓ Check console: "AuthNotifier: Initialized with stored user"
```

**Test Case 6.2: Logout Clears Session**
```
Prerequisites:
- User is logged in

Steps:
1. Open app menu (top right)
2. Click "Logout"
3. Confirm logout

Expected Results:
✓ Loading state shows
✓ Navigation to LoginScreen
✓ User is fully logged out
4. Force quit and reopen app

Expected Results:
✓ LoginScreen appears (not HomeScreen)
✓ Session was cleared properly
```

**Test Case 6.3: Firebase Auth State Sync**
```
Prerequisites:
- User logged in
- Hive storage working

Steps:
1. While app is running, logout user from Firebase Console:
   - Firebase Console → Auth → Users
   - Click user → Delete
2. Wait 5 seconds or restart app

Expected Results:
✓ App detects user deletion from Firebase
✓ AuthNotifier receives auth state change
✓ Redirected to LoginScreen
✓ Session cleared
```

---

### Test Suite 7: Localization

**Test Case 7.1: English UI - All Auth Screens**
```
Prerequisites:
- App set to English language

Steps:
1. Go through complete signup/login flow
2. Verify all text on each screen:
   - LoginScreen: "Welcome Back", "Sign in to continue..."
   - SignupScreen: "Create Account", "I agree to terms"
   - ForgotPasswordScreen: "Reset Your Password"
   - ProfileCompletionScreen: "Complete Your Profile"

Expected Results:
✓ All text is in English
✓ No placeholder text visible
✓ Validation messages in English
✓ Error messages in English
```

**Test Case 7.2: Arabic UI - All Auth Screens**
```
Prerequisites:
- Device set to Arabic language
- App respects device locale

Steps:
1. Change system language to Arabic
2. Restart app
3. Go through complete signup/login flow

Expected Results:
✓ All text appears in Arabic
✓ RTL layout applied (text right-aligned)
✓ Form direction is RTL
✓ Buttons and icons in correct positions
✓ No English text mixed in
```

**Test Case 7.3: Error Messages Localized**
```
Steps:
1. Trigger validation error:
   - Try signing in without email

Expected Results:
✓ English: "Email is required"
✓ Arabic: "البريد الإلكتروني مطلوب"

2. Trigger Firebase error:
   - Wrong password

Expected Results:
✓ Error message is localized
✓ User-friendly (not Firebase error code)
```

---

### Test Suite 8: UI/UX Polish

**Test Case 8.1: Loading States**
```
Steps:
1. On any auth screen with network
2. Click submit button
3. Observe button during request (2-3 seconds)

Expected Results:
✓ Button shows loading indicator (spinner or progress)
✓ Button text changes to "Loading..." or similar
✓ Button is disabled (no double-tap)
✓ Other form fields remain accessible
✓ Loading state clears on success/error
```

**Test Case 8.2: Error Snackbars**
```
Steps:
1. Trigger an error (wrong password, etc)

Expected Results:
✓ Snackbar appears from bottom
✓ Error message is readable
✓ Auto-dismiss after 4 seconds
✓ Can be manually dismissed
✓ Color indicates error (usually red/orange)
```

**Test Case 8.3: Keyboard Handling**
```
Steps:
1. On LoginScreen, tap email field
2. Keyboard appears
3. Tap password field
4. Tap submit button

Expected Results:
✓ Keyboard shows for text fields
✓ Keyboard hides on button submit
✓ Text fields are visible (not covered by keyboard)
✓ Scrollable if needed on small screens
```

**Test Case 8.4: Form State Persistence**
```
Steps:
1. On SignupScreen
2. Fill: Email, password, confirm, agree checkbox
3. Trigger an error (e.g., email already exists)
4. Observe form

Expected Results:
✓ Form fields retain entered values
✓ Checkbox state is preserved
✓ User doesn't need to re-enter data
```

**Test Case 8.5: Password Visibility Toggle**
```
Steps:
1. On LoginScreen, enter password
2. Click eye icon (show/hide password)

Expected Results:
✓ Password toggles between visible and hidden
✓ Icon changes (open/closed eye)
✓ Text type changes appropriately
```

---

### Test Suite 9: Edge Cases & Error Handling

**Test Case 9.1: Rapid Button Clicks**
```
Steps:
1. On LoginScreen, quickly click Sign In multiple times

Expected Results:
✓ Only one request sent (debounce/disable working)
✓ No duplicate Firebase calls
✓ No multiple snackbars
```

**Test Case 9.2: Screen Rotation During Auth**
```
Steps:
1. On LoginScreen, start to rotate
2. While loading, rotate device
3. Complete rotation to landscape

Expected Results:
✓ Layout adapts to landscape
✓ Loading state persists
✓ Form is still valid
✓ No crashes or errors
```

**Test Case 9.3: App Backgrounded During Auth**
```
Steps:
1. On LoginScreen, start sign-in
2. While loading, press home button (background app)
3. Wait 10 seconds
4. Foreground app again

Expected Results:
✓ Request completes (or timeout occurs)
✓ App handles response properly
✓ No frozen UI or error states
```

**Test Case 9.4: Firebase Downtime Simulation**
```
Steps:
1. Turn off internet after signing in
2. Kill and reopen app
3. Try to sign in with no internet

Expected Results:
✓ First attempt: Network error message
✓ Enable internet
✓ Retry succeeds
✓ Offline mode graceful (shows offline message)
```

---

## Part C: Testing Checklist

### Pre-Testing Checklist
- [ ] Firebase credentials configured in `firebase_options.dart`
- [ ] Google services downloaded for Android/iOS
- [ ] FlutterFire configure completed
- [ ] `flutter pub get` run successfully
- [ ] App compiles without errors
- [ ] Test email accounts created
- [ ] Google test account ready
- [ ] Internet connection available
- [ ] Emulator/device storage cleared

### Testing Execution Checklist

**Suite 1 - Fresh Install (3 tests)**
- [ ] First launch screen displays
- [ ] Network errors handled
- [ ] All tests pass

**Suite 2 - Email/Password Auth (8 tests)**
- [ ] Sign up flow complete
- [ ] Profile completion works
- [ ] Can skip profile
- [ ] Sign in works
- [ ] Invalid credentials rejected
- [ ] Email validation works
- [ ] Password validation works
- [ ] Password mismatch caught

**Suite 3 - Password Reset (3 tests)**
- [ ] Password reset email sent
- [ ] Invalid email handled
- [ ] Navigation works

**Suite 4 - Google Sign-In (4 tests)**
- [ ] First-time Google sign-in
- [ ] Returning user re-signin
- [ ] Google cancellation handled
- [ ] Network error on Google sign-in

**Suite 5 - Navigation Guards (3 tests)**
- [ ] Unauthenticated protection
- [ ] Profile incomplete redirect
- [ ] Authenticated redirect from auth screens

**Suite 6 - Session Persistence (3 tests)**
- [ ] Session persists after restart
- [ ] Logout clears session
- [ ] Firebase state sync works

**Suite 7 - Localization (3 tests)**
- [ ] English UI complete
- [ ] Arabic UI complete
- [ ] Error messages localized

**Suite 8 - UI/UX (5 tests)**
- [ ] Loading states work
- [ ] Error snackbars display
- [ ] Keyboard handling correct
- [ ] Form state preserved
- [ ] Password visibility toggle works

**Suite 9 - Edge Cases (4 tests)**
- [ ] Rapid clicks handled
- [ ] Screen rotation safe
- [ ] Background/foreground safe
- [ ] Offline handling graceful

### Total: 36 test cases

---

## Part D: Debugging & Common Issues

### Issue 1: Firebase Initialization Fails
```
Error: "FirebaseOptions not configured"
Solution:
- Check firebase_options.dart has real values (not placeholders)
- Verify Firebase project exists
- Run: flutterfire configure again
- Check that google-services.json is in android/app/
```

### Issue 2: Google Sign-In Button Does Nothing
```
Error: Clicking button shows no response
Solution:
- Verify Google OAuth configured in Firebase Console
- For emulator: Check Google Play Services installed
- For iOS: Verify URL scheme in Info.plist
- Check SHA-1 fingerprint registered in Firebase (Android)
```

### Issue 3: User Session Not Persisting
```
Error: User logged out after app restart
Solution:
- Check Hive box is initialized: `await Hive.initFlutter()`
- Verify TokenStorageService.initialize() called in main.dart
- Check saveUser() is called after login
- Ensure Hive box not cleared by uninstall
```

### Issue 4: Profile Completion Screen Never Appears
```
Error: Signed up but no profile completion screen
Solution:
- Check AuthStatus.profileIncomplete state is set
- Verify ProfileCompletionScreen route exists in app_router.dart
- Ensure redirect logic in app.dart checks profileIncomplete status
- Check hasCompleteProfile getter in AuthUser model
```

### Issue 5: Localization Strings Not Showing
```
Error: Auth screens show English even with Arabic locale
Solution:
- Verify app_strings_ar.dart has all required auth strings
- Check stringsProvider is watched in auth screens
- Rebuild app: flutter clean && flutter pub get && flutter run
- Ensure device language is actually set to Arabic
```

### Issue 6: Firebase Errors Not User-Friendly
```
Error: Technical Firebase error codes shown to users
Solution:
- Check mapFirebaseException() in auth_repository.dart
- Verify error mapping includes all Firebase codes
- Test with actual Firebase errors to verify messages
- Add new error cases as they're discovered
```

---

## Part E: Performance Testing

### Load Test
```
Test: Create 100 new users rapidly
Method:
1. Write script to call signUpWithEmail in rapid succession
2. Monitor Firebase realtime database writes
3. Check for rate limiting errors

Expected:
✓ First 10-20 succeed
✓ Later requests return rate limit error
✓ App handles gracefully with message
```

### Memory Test
```
Test: Sign in/out 50 times
Method:
1. Loop: login → logout → login
2. Monitor memory usage in Android Studio Profiler

Expected:
✓ Memory stable (no memory leak)
✓ No UI lag
✓ Session cleared each time
```

### Network Test
```
Test: Slow network conditions
Method:
1. Set network throttling in emulator
2. Perform auth operations
3. Measure timeout handling

Expected:
✓ Timeout occurs ~30 seconds
✓ User-friendly timeout message
✓ Can retry operation
```

---

## Part F: Success Criteria

### ✅ Testing Complete When:
- [ ] All 36 test cases pass
- [ ] No crashes or exceptions
- [ ] Error messages are user-friendly
- [ ] All text is properly localized
- [ ] Session persists across restarts
- [ ] Navigation guards prevent unauthorized access
- [ ] Google Sign-In works on physical device
- [ ] No obvious UI/UX issues
- [ ] Network errors handled gracefully
- [ ] Forms work correctly (validation, state, loading)

### ✅ Code Quality Complete When:
- [ ] No console errors or warnings (except expected)
- [ ] No memory leaks detected
- [ ] No hardcoded strings outside localization
- [ ] All error codes mapped to user messages
- [ ] Firebase credentials in environment (not committed)
- [ ] Code follows project patterns (Riverpod, clean architecture)

---

## Next Steps After Phase 8

Once all tests pass:

1. **API Client Setup** - Implement Dio HTTP client with interceptors
2. **Backend Integration** - Connect to actual API endpoints
3. **Payment Gateway** - Implement PayPal integration
4. **Push Notifications** - Set up Firebase Cloud Messaging
5. **Therapist Features** - Booking, session calls (Agora integration)

---

## Additional Resources

- [Firebase Auth Docs](https://firebase.flutter.dev/docs/auth/overview)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Riverpod State Management](https://riverpod.dev/)
- [GoRouter Navigation](https://pub.dev/packages/go_router)

---

**Created**: 2025-12-17
**Status**: Ready for Phase 8 Testing
**Phase 8 Time Estimate**: 2-3 hours for comprehensive testing
