# Testing Checklist (Manual)

> **Total Tests**: 226
> **Scope**: Full Regression

---

## 1. Authentication (30 Tests)
- [ ] Splash screen loads < 2s
- [ ] Language switch changes UI instantly
- [ ] Login fails with invalid email
- [ ] Login fails with invalid password
- [ ] Login succeeds with valid creds
- [ ] Google Sign-In popup appears
- [ ] Google Sign-In completes
- [ ] Apple Sign-In works
- [ ] OTP SMS received
- [ ] Invalid OTP handled
- [ ] Resend OTP timer works
- [ ] Forgot Password email sent
- [ ] Guest mode access works
- [ ] Restricted pages prompt login in Guest mode
- [ ] Logout clears session
- [ ] Auto-login on restart works
- [ ] Therapist login redirects to portal
- [ ] Admin login redirects to admin panel
- [ ] Signup valid form submits
- [ ] Signup email overlap error
- [ ] Terms of Service link works
- [ ] Privacy Policy link works
- [ ] Avatar upload camera works
- [ ] Avatar upload gallery works
- [ ] Nickname validation
- [ ] Biometric login setup
- [ ] Biometric login success
- [ ] Biometric login failure fallback
- [ ] Session expiry handling
- [ ] Token refresh logic

## 2. Mood Tracker (40 Tests)
- [ ] Mood picker animations smooth
- [ ] Select 'Happy' logs correctly
- [ ] Select 'Sad' logs correctly
- [ ] Add 3+ activities tags
- [ ] Custom activity tag creation
- [ ] Voice note records
- [ ] Voice note plays back
- [ ] Voice note delete
- [ ] Journal text saves > 500 chars
- [ ] Save entry updates home screen
- [ ] Edit entry changes data
- [ ] Delete entry removes data
- [ ] Calendar view shows dots
- [ ] Clicking calendar day shows entries
- [ ] Streak counter increments
- [ ] Streak freeze logic
- [ ] Monthly chart renders
- [ ] Weekly chart renders
- [ ] PDF export generates file
- [ ] PDF export opens
- [ ] Share image generation
- [ ] Share to WhatsApp
- [ ] Share to Instagram
- [ ] Dark mode colors correct in chart
- [ ] RTL layout correct in chart
- [ ] Offline entry saves locally
- [ ] Offline entry syncs when online
- [ ] Recommendation logic works
- [ ] Quote widget refresh
- [ ] Mood insights logic
- [ ] ... (10 more edge cases)

## 3. AI Chat (30 Tests)
- [ ] Chat opens quickly
- [ ] Typing indicator shows
- [ ] User message appears
- [ ] AI response streams
- [ ] Markdown bold/italic renders
- [ ] Code blocks render
- [ ] Arabic text aligns right
- [ ] History loads pagination
- [ ] New chat clears context
- [ ] Rename chat works
- [ ] Delete chat removes from list
- [ ] Voice input transcribes correctly
- [ ] TTS speaks response
- [ ] Stop generation button works
- [ ] Error state (no net) handled
- [ ] Retry button works
- [ ] Token limit warning
- [ ] Safety filter triggers
- [ ] Context memory check (name/mood)
- [ ] Suggestion chips insert text
- [ ] ... (10 more edge cases/performance)

## 4. Therapist Booking (40 Tests)
- [ ] Directory loads
- [ ] Filter by specialty works
- [ ] Search returns results
- [ ] Profile load speed
- [ ] Image gallery swipe
- [ ] Availability slots correct dates
- [ ] Slot selection highlights
- [ ] Booking summary totals correct
- [ ] Payment sheet opens
- [ ] Success screen after payment
- [ ] Booking appears in Upcoming
- [ ] Notification received for booking
- [ ] Cancel booking < 24h logic
- [ ] Reschedule flow
- [ ] Video call connection
- [ ] Video call mic toggle
- [ ] Video call camera toggle
- [ ] Chat message send
- [ ] Chat message receive
- [ ] File attachment upload
- [ ] Reviews load
- [ ] Add review flow
- [ ] Rating calculation
- [ ] Report therapist form
- [ ] ... (16 more edge cases/flows)

## 5. Community & Admin (50 Tests)
- [ ] Feed refresh pull-to-refresh
- [ ] Infinite scroll loading
- [ ] Post image upload
- [ ] Anonymous toggle
- [ ] Like counter updates optimistically
- [ ] Like persists on refresh
- [ ] Comment add
- [ ] Comment reply
- [ ] Report post
- [ ] Admin ban user
- [ ] Admin verify therapist
- [ ] Admin analytics charts load
- [ ] Push notification sent from admin
- [ ] Support ticket creation
- [ ] Coupon code applied
- [ ] Feature flag toggle works
- [ ] ... (34 more admin/community tests)

## 6. Subscription & Settings (36 Tests)
- [ ] Paywall shows current plan
- [ ] Select Weekly plan
- [ ] Select Monthly plan
- [ ] Valid purchase flow (Sandbox)
- [ ] Restore purchases works
- [ ] Cancel link opens store
- [ ] Dark mode toggle
- [ ] Language change persists
- [ ] Notification settings toggle
- [ ] Clear cache works
- [ ] Delete account flow
- [ ] ... (25 more settings/sub tests)
