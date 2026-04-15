# Firestore Collections Reference

**Last Updated**: January 15, 2026
**Purpose**: Complete reference for all Firestore collections used in Sanad App

---

## Core Collections

### `/users`
**Purpose**: User profiles and account information

```typescript
{
  uid: string;                    // Firebase Auth UID
  email: string;
  full_name?: string;
  name?: string;
  avatar_url?: string;
  phone?: string;
  role: 'user' | 'therapist' | 'admin';

  // Subscription
  subscription_status?: 'active' | 'expired' | 'cancelled';
  subscription_product_id?: string;
  subscription_product_title?: string;
  subscription_start_date?: timestamp;
  subscription_end_date?: timestamp;
  is_premium?: boolean;

  // Profile
  has_complete_profile?: boolean;
  date_of_birth?: timestamp;
  gender?: string;
  matching_preferences?: map;

  // Settings
  settings?: {
    notifications_enabled: boolean;
    daily_reminders: boolean;
    mood_tracking_reminders: boolean;
    reminder_time: string;
    dark_mode: boolean;
    language: string;
  };

  // Timestamps
  created_at: timestamp;
  updated_at: timestamp;
  last_login: timestamp;
}
```

**Indexes Required**:
- `role` (ASC)
- `subscription_status` (ASC)
- `created_at` (DESC)

---

### `/therapists`
**Purpose**: Therapist profiles and professional information

```typescript
{
  user_id: string;                // References /users/{uid}
  full_name: string;
  email: string;
  phone: string;

  // Professional Details
  specialization: string[];
  license_number: string;
  years_of_experience: number;
  education: string;
  bio: string;

  // Verification
  status: 'pending' | 'approved' | 'rejected';
  license_document_url?: string;
  id_document_url?: string;
  certificate_document_url?: string;

  // Availability
  is_active: boolean;
  available_slots?: map;

  // Stats
  total_sessions?: number;
  avg_rating?: number;
  total_earnings?: number;

  // Timestamps
  created_at: timestamp;
  updated_at: timestamp;
  approved_at?: timestamp;
}
```

**Indexes Required**:
- `status` (ASC), `created_at` (DESC)
- `is_active` (ASC)

---

### `/bookings`
**Purpose**: Therapy session bookings

```typescript
{
  user_id: string;                // Patient ID
  therapist_id: string;           // Therapist ID
  client_name: string;
  therapist_name?: string;

  // Session Details
  session_type: 'individual' | 'couples' | 'family' | 'group';
  issue_category?: string;
  scheduled_time: timestamp;
  date: timestamp;
  duration: number;               // Minutes
  amount?: number;

  // Status
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled' | 'no_show' | 'rejected';

  // Notes
  notes?: string;                 // Session notes (therapist)
  private_notes?: string;         // Private therapist notes
  user_notes?: string;            // Patient notes
  rejection_reason?: string;
  cancellation_reason?: string;

  // Timestamps
  created_at: timestamp;
  updated_at: timestamp;
  confirmed_at?: timestamp;
  completed_at?: timestamp;
  cancelled_at?: timestamp;
}
```

**Indexes Required (Composite)**:
- `therapist_id` (ASC), `date` (ASC), `status` (ASC)
- `therapist_id` (ASC), `status` (ASC), `scheduled_time` (ASC)
- `user_id` (ASC), `status` (ASC), `date` (DESC)

---

### `/payments`
**Purpose**: Payment records and transaction history

```typescript
{
  user_id: string;
  product_id: string;
  product_title: string;
  amount: number;
  currency: string;               // e.g., 'SAR'

  payment_method: 'bank_transfer' | 'paypal' | 'card';
  status: 'pending' | 'completed' | 'failed' | 'refunded';

  // Bank Transfer Details
  bank_name?: string;
  account_number?: string;
  transaction_id?: string;

  // Subscription Details
  start_date?: timestamp;
  end_date?: timestamp;

  // Timestamps
  created_at: timestamp;
  updated_at?: timestamp;
}
```

**Indexes Required**:
- `user_id` (ASC), `status` (ASC)
- `status` (ASC), `created_at` (DESC)

---

### `/payment_verifications`
**Purpose**: Bank transfer verification queue for admin

```typescript
{
  od_id: string;                  // User ID
  product_id: string;
  product_title: string;
  amount: number;
  currency: string;

  // Bank Details
  bank_name: string;
  account_number: string;
  transaction_id: string;

  // Receipt
  receipt_url: string;

  // Verification Status
  status: 'pending' | 'approved' | 'rejected';
  reviewed_at?: timestamp;
  reviewed_by?: string;           // Admin ID
  rejection_reason?: string;

  // Timestamps
  created_at: timestamp;
}
```

**Indexes Required**:
- `status` (ASC), `created_at` (DESC)

---

### `/activity_logs` ✨ NEW
**Purpose**: Activity feed for admin dashboard

```typescript
{
  type: 'sessionCompleted' | 'bookingCreated' | 'moodLogged' | 'postCreated' |
        'userRegistered' | 'therapistApproved' | 'paymentVerified';
  user_id: string;
  user_name: string;
  description: string;            // e.g., "completed a session with Sarah"

  // Optional Metadata
  metadata?: {
    client_name?: string;
    therapist_name?: string;
    mood?: string;
    amount?: number;
    [key: string]: any;
  };

  // Timestamps
  timestamp: timestamp;
}
```

**Indexes Required**:
- `timestamp` (DESC)

**Usage**: Powers the Recent Activity panel in Admin Dashboard

---

### `/reviews` ✨ NEW (To Be Created)
**Purpose**: Therapist ratings and reviews

```typescript
{
  therapist_id: string;
  user_id: string;
  booking_id: string;             // References /bookings/{id}

  // Review Content
  rating: number;                 // 1-5 stars
  comment?: string;

  // Timestamps
  created_at: timestamp;
  updated_at?: timestamp;
}
```

**Indexes Required**:
- `therapist_id` (ASC), `created_at` (DESC)
- `booking_id` (ASC)

**Usage**: Powers KPI Sparklines in Therapist Dashboard (average rating metric)

---

## Sub-Collections

### `/users/{userId}/mood_entries`
**Purpose**: Daily mood tracking for each user

```typescript
{
  mood: 'excellent' | 'great' | 'happy' | 'good' | 'okay' | 'neutral' |
        'bad' | 'sad' | 'anxious' | 'stressed' | 'depressed';
  note?: string;
  activities?: string[];
  energy_level?: number;          // 1-5
  sleep_hours?: number;

  // Timestamps
  date: timestamp;
  created_at: timestamp;
}
```

**Indexes Required**:
- `date` (DESC)
- `created_at` (DESC)

**Usage**:
- Powers Risk Alerts Panel (mood pattern analysis)
- User mood history and insights

---

### `/posts/{postId}/comments`
**Purpose**: Comments on community posts

```typescript
{
  author_id: string;
  author_name: string;
  content: string;
  created_at: timestamp;
}
```

---

### `/therapist_chats/{chatId}/messages`
**Purpose**: Messages in therapist-patient chat threads

```typescript
{
  sender_id: string;
  sender_type: 'patient' | 'therapist';
  content: string;
  timestamp: timestamp;
  read: boolean;
}
```

---

## CMS Collections

### `/daily_quotes`
**Purpose**: Inspirational quotes for home screen

```typescript
{
  text_ar: string;
  text_en: string;
  author_ar?: string;
  author_en?: string;
  category?: string;
  is_active: boolean;
  created_at: timestamp;
  updated_at?: timestamp;
}
```

---

### `/content`
**Purpose**: Educational content and articles

```typescript
{
  title_ar: string;
  title_en: string;
  body_ar: string;
  body_en: string;
  category: string;
  image_url?: string;
  is_published: boolean;
  created_at: timestamp;
  updated_at?: timestamp;
}
```

---

### `/challenges`
**Purpose**: Daily wellness challenges

```typescript
{
  title_ar: string;
  title_en: string;
  description_ar: string;
  description_en: string;
  icon: string;
  category: string;
  difficulty: 'easy' | 'medium' | 'hard';
  points: number;
  display_order: number;
  is_active: boolean;
  created_at: timestamp;
  updated_at?: timestamp;
}
```

---

## Query Patterns

### Admin Dashboard Queries

#### Get Today's Sessions Count
```dart
firestore.collection('bookings')
  .where('date', isGreaterThanOrEqualTo: startOfDay)
  .where('date', isLessThan: startOfDay + 1day)
  .get()
```

#### Get Pending Verifications
```dart
firestore.collection('payment_verifications')
  .where('status', isEqualTo: 'pending')
  .orderBy('created_at', descending: true)
  .snapshots()
```

#### Get Recent Activity
```dart
firestore.collection('activity_logs')
  .orderBy('timestamp', descending: true)
  .limit(20)
  .snapshots()
```

---

### Therapist Dashboard Queries

#### Get Session Volume (Last 7 Days)
```dart
firestore.collection('bookings')
  .where('therapist_id', isEqualTo: therapistId)
  .where('date', isGreaterThanOrEqualTo: startDate)
  .where('status', isEqualTo: 'completed')
  .get()
```

#### Get Average Rating
```dart
firestore.collection('reviews')
  .where('therapist_id', isEqualTo: therapistId)
  .get()
// Calculate average from results
```

---

### Risk Alerts Queries

#### Detect Declining Mood Patterns
```dart
firestore.collectionGroup('mood_entries')
  .where('created_at', isGreaterThanOrEqualTo: sevenDaysAgo)
  .orderBy('created_at', descending: true)
  .limit(100)
  .snapshots()
// Analyze mood trends per user in client
```

---

## Security Rules

### User Data
- Users can read/write their own `/users/{userId}` document
- Users can read/write their own `/users/{userId}/mood_entries` subcollection
- Admin can read all user documents

### Bookings
- Users can create bookings
- Users can read bookings where `user_id == uid`
- Therapists can read bookings where `therapist_id == uid`
- Therapists can update booking status
- Admin can read all bookings

### Reviews
- Users can create reviews for their completed bookings
- Users can read/update their own reviews
- Therapists can read reviews where `therapist_id == uid` (read-only)
- Admin can read all reviews

### Activity Logs
- Admin only (read)
- System writes (via Cloud Functions or secure backend)

---

## Migration Notes

### Reviews Collection
**Status**: Not yet created
**Required for**: Therapist KPI Sparklines (average rating)

**Steps to Create**:
1. Add Firestore Security Rules for `/reviews`
2. Create composite index: `therapist_id` (ASC), `created_at` (DESC)
3. Build UI for clients to leave reviews after completed sessions
4. Optional: Migrate any existing review data

---

**Generated**: January 15, 2026
**Maintained By**: Development Team
**Review Frequency**: After each major feature release
