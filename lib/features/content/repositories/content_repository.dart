import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_cache_helper.dart';
import '../models/content_models.dart';
import '../models/psychological_test.dart';

final contentRepositoryProvider = Provider((ref) => ContentRepository());

class ContentRepository {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Demo quotes for when Firestore is empty
  static final List<DailyQuote> _demoQuotes = [
    DailyQuote(
      id: 'demo_1',
      text:
          'The greatest glory in living lies not in never falling, but in rising every time we fall.',
      author: 'Nelson Mandela',
      publishDate: DateTime.now(),
    ),
    DailyQuote(
      id: 'demo_2',
      text:
          'Your mental health is a priority. Your happiness is essential. Your self-care is a necessity.',
      author: 'Unknown',
      publishDate: DateTime.now(),
    ),
    DailyQuote(
      id: 'demo_3',
      text:
          'Be patient with yourself. Self-growth is tender; it\'s holy ground. There\'s no greater investment.',
      author: 'Stephen Covey',
      publishDate: DateTime.now(),
    ),
  ];

  // Demo content for when Firestore is empty
  static final List<ContentItem> _demoContent = [
    ContentItem(
      id: 'demo_content_1',
      title: 'Managing Daily Stress',
      description:
          'Practical tips and techniques to handle everyday stress and maintain your mental well-being.',
      type: 'article',
      category: 'Stress Management',
      thumbnailUrl: null,
      contentUrl: null,
    ),
    ContentItem(
      id: 'demo_content_2',
      title: 'Building Healthy Habits',
      description:
          'Learn how small daily habits can significantly improve your mental health over time.',
      type: 'article',
      category: 'Self-Care',
      thumbnailUrl: null,
      contentUrl: null,
    ),
    ContentItem(
      id: 'demo_content_3',
      title: 'Understanding Anxiety',
      description:
          'A comprehensive guide to recognizing anxiety symptoms and coping strategies.',
      type: 'article',
      category: 'Mental Health',
      thumbnailUrl: null,
      contentUrl: null,
    ),
    ContentItem(
      id: 'demo_content_4',
      title: 'Improving Sleep Quality',
      description:
          'Evidence-based tips for better sleep and establishing a healthy bedtime routine.',
      type: 'article',
      category: 'Sleep',
      thumbnailUrl: null,
      contentUrl: null,
    ),
    ContentItem(
      id: 'demo_content_5',
      title: 'Mindfulness for Beginners',
      description:
          'Simple mindfulness exercises you can practice anywhere to stay present and calm.',
      type: 'article',
      category: 'Mindfulness',
      thumbnailUrl: null,
      contentUrl: null,
    ),
  ];

  Future<DailyQuote?> getLatestQuote() async {
    try {
      final query = await _firestore
          .collection('daily_quotes')
          .where('is_active', isEqualTo: true)
          .orderBy('publish_date', descending: true)
          .limit(1)
          .getCacheFirst();

      if (query.docs.isEmpty) {
        // Return demo quote when no data in Firestore
        return _demoQuotes[DateTime.now().day % _demoQuotes.length];
      }

      final data = query.docs.first.data();
      data['id'] = query.docs.first.id;
      return DailyQuote.fromJson(data);
    } catch (e) {
      // Return demo quote on error
      return _demoQuotes[DateTime.now().day % _demoQuotes.length];
    }
  }

  Future<List<ContentItem>> getFeaturedContent() async {
    try {
      final query = await _firestore
          .collection('content')
          .where('is_published', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(5)
          .getCacheFirst();

      if (query.docs.isEmpty) {
        // Return demo content when no data in Firestore
        return _demoContent;
      }

      return query.docs.map((doc) => ContentItem.fromFirestore(doc)).toList();
    } catch (e) {
      // Return demo content on error
      return _demoContent;
    }
  }

  Future<List<ContentItem>> getContentByType(
    String type, {
    int limit = 20,
  }) async {
    try {
      final query = await _firestore
          .collection('content')
          .where('type', isEqualTo: type)
          .where('is_published', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .getCacheFirst();

      return query.docs.map((doc) => ContentItem.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<ContentItem?> getContentById(String id) async {
    try {
      final doc = await _firestore
          .collection('content')
          .doc(id)
          .getCacheFirst();
      if (!doc.exists) return null;
      return ContentItem.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  Future<List<PsychologicalTest>> getPsychologicalTests() async {
    try {
      final query = await _firestore
          .collection('psychological_tests')
          .where('is_active', isEqualTo: true)
          .getCacheFirst();

      return query.docs
          .map((doc) => PsychologicalTest.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTestResult({
    required String testId,
    required String testType,
    required int totalScore,
    required String interpretation,
    required List<int> answers,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('test_results')
        .add(
          TestResult(
            id: '',
            testId: testId,
            testType: testType,
            totalScore: totalScore,
            interpretation: interpretation,
            answers: answers,
            createdAt: DateTime.now(),
          ).toJson(),
        );
  }

  Future<List<TestResult>> getUserTestResults() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('test_results')
          .orderBy('created_at', descending: true)
          .limit(20)
          .getCacheFirst();

      return query.docs.map((doc) => TestResult.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }
}
