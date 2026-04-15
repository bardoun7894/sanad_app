import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sanad_app/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Seed Database Data', (WidgetTester tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;

    // 1. Seed Subscription Products
    final products = [
      {
        'id': 'free',
        'name': 'Basic Access',
        'description': 'Access to community and basic content',
        'price': 0.0,
        'currency': 'SAR',
        'interval': 'forever',
        'features': [
          'Community Access',
          'Daily Mood Tracking',
          'Basic Content',
        ],
        'is_active': true,
      },
      {
        'id': 'monthly',
        'name': 'Premium Monthly',
        'description': 'Full access to all features',
        'price': 29.99,
        'currency': 'SAR',
        'interval': 'month',
        'features': [
          'Unlimited AI Chat',
          'Therapist Booking Access',
          'Advanced Insights',
          'Priority Support',
        ],
        'is_active': true,
      },
      {
        'id': 'yearly',
        'name': 'Premium Yearly',
        'description': 'Best value for long-term wellness',
        'price': 299.99,
        'currency': 'SAR',
        'interval': 'year',
        'features': [
          'All Monthly Features',
          '2 Months Free',
          'Exclusive Workshops',
        ],
        'is_active': true,
      },
    ];

    for (var p in products) {
      await firestore
          .collection('subscription_products')
          .doc(p['id'] as String)
          .set(p);
      print('Seeded product: ${p['id']}');
    }

    // 2. See Therapist Availability (for top approved therapists)
    // Fetch approved therapists first
    final therapistSnapshot = await firestore
        .collection('therapists')
        .where('status', isEqualTo: 'approved')
        .limit(3)
        .get();

    for (var doc in therapistSnapshot.docs) {
      final therapistId = doc.id;
      print('Seeding availability for: $therapistId'); // Debug

      // Create slots for next 7 days
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        // Create 3 slots per day: 10AM, 2PM, 4PM
        final hours = [10, 14, 16];

        for (var h in hours) {
          final startTime = DateTime(date.year, date.month, date.day, h);
          final endTime = startTime.add(const Duration(minutes: 50));

          // Check if slot exists to avoid dups (simple check)
          // Ideally we query, but for seeding we'll just write new IDs

          await firestore.collection('therapist_availability').add({
            'therapist_id': therapistId,
            'start_time': Timestamp.fromDate(startTime),
            'end_time': Timestamp.fromDate(endTime),
            'is_booked': false,
            'is_available': true,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  });
}
