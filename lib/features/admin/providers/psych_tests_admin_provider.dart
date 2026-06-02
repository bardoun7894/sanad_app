import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../content/models/psychological_test.dart';
import '../services/admin_chat_service.dart';

/// Pure function exposed at top-level so it can be unit-tested without
/// standing up Firestore.
///
/// NOTE: The Firestore schema stores scoring ranges nested under
/// `scoring.ranges` (as read by [PsychologicalTest.fromJson] lines 106–107).
/// A flat `scoring_ranges` key would silently lose all ranges on reload.
@visibleForTesting
Map<String, dynamic> psychTestToMap(PsychologicalTest t) => {
      'title': t.title,
      'title_en': t.titleEn,
      'description': t.description,
      'description_en': t.descriptionEn,
      'type': t.type,
      'duration_minutes': t.durationMinutes,
      'is_active': t.isActive,
      'questions': t.questions
          .map((q) => {
                'text': q.text,
                'text_en': q.textEn,
                'options': q.options
                    .map((o) => {
                          'text': o.text,
                          'text_en': o.textEn,
                          'score': o.score,
                        })
                    .toList(),
              })
          .toList(),
      // Nested structure matches PsychologicalTest.fromJson (scoring.ranges)
      'scoring': {
        'ranges': t.scoringRanges
            .map((r) => {
                  'min': r.min,
                  'max': r.max,
                  'level': r.level,
                  'text': r.text,
                  'text_en': r.textEn,
                })
            .toList(),
      },
    };

/// Validates test dialog fields before save.
/// Returns a human-readable error string, or null when all fields are valid.
@visibleForTesting
String? psychTestValidate({
  required String title,
  required int questionCount,
  required int rangeCount,
}) {
  if (title.trim().isEmpty) {
    return 'title is required';
  }
  if (questionCount < 1) {
    return 'at least one question is required';
  }
  if (rangeCount < 1) {
    return 'at least one scoring range is required';
  }
  return null;
}

class PsychTestsAdminState {
  final bool isLoading;
  final String? error;
  final List<PsychologicalTest> tests;

  const PsychTestsAdminState({
    this.isLoading = false,
    this.error,
    this.tests = const [],
  });

  PsychTestsAdminState copyWith({
    bool? isLoading,
    String? error,
    List<PsychologicalTest>? tests,
  }) =>
      PsychTestsAdminState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        tests: tests ?? this.tests,
      );
}

class PsychTestsAdminNotifier extends StateNotifier<PsychTestsAdminState> {
  final _col = FirebaseFirestore.instance.collection('psychological_tests');

  PsychTestsAdminNotifier() : super(const PsychTestsAdminState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final snap = await _col.orderBy('title').get();
      final tests =
          snap.docs.map((d) => PsychologicalTest.fromFirestore(d)).toList();
      state = state.copyWith(isLoading: false, tests: tests);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTest(PsychologicalTest t, {bool notifyUsers = false}) async {
    final ref = _col.doc();
    final data = psychTestToMap(t)
      ..['created_at'] = FieldValue.serverTimestamp();
    await ref.set(data);
    await _maybeBroadcast(
      notify: notifyUsers,
      title: 'اختبار نفسي جديد',
      body: t.title,
    );
    await load();
  }

  Future<void> updateTest(
    PsychologicalTest t, {
    bool notifyUsers = false,
  }) async {
    await _col.doc(t.id).update(psychTestToMap(t));
    await _maybeBroadcast(
      notify: notifyUsers,
      title: 'تم تحديث اختبار نفسي',
      body: t.title,
    );
    await load();
  }

  Future<void> _maybeBroadcast({
    required bool notify,
    required String title,
    required String body,
  }) async {
    if (!notify) return;
    try {
      await AdminChatService().broadcastNotificationToAllUsers(
        title: title,
        body: body,
        actionRoute: '/psychological-tests',
      );
    } catch (e) {
      debugPrint('[PsychTestsAdmin] notification broadcast failed: $e');
    }
  }

  Future<void> deleteTest(String id) async {
    await _col.doc(id).delete();
    await load();
  }
}

final psychTestsAdminProvider =
    StateNotifierProvider<PsychTestsAdminNotifier, PsychTestsAdminState>(
  (ref) => PsychTestsAdminNotifier(),
);
