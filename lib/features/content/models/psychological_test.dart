import 'package:cloud_firestore/cloud_firestore.dart';

class TestOption {
  final String text;
  final String textEn;
  final int score;

  const TestOption({
    required this.text,
    required this.textEn,
    required this.score,
  });

  factory TestOption.fromJson(Map<String, dynamic> json) {
    return TestOption(
      text: json['text'] ?? '',
      textEn: json['text_en'] ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'text_en': textEn,
        'score': score,
      };
}

class TestQuestion {
  final String text;
  final String textEn;
  final List<TestOption> options;

  const TestQuestion({
    required this.text,
    required this.textEn,
    required this.options,
  });

  factory TestQuestion.fromJson(Map<String, dynamic> json) {
    return TestQuestion(
      text: json['text'] ?? '',
      textEn: json['text_en'] ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => TestOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ScoringRange {
  final int min;
  final int max;
  final String level;
  final String text;
  final String textEn;

  const ScoringRange({
    required this.min,
    required this.max,
    required this.level,
    required this.text,
    required this.textEn,
  });

  factory ScoringRange.fromJson(Map<String, dynamic> json) {
    return ScoringRange(
      min: (json['min'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 0,
      level: json['level'] ?? '',
      text: json['text'] ?? '',
      textEn: json['text_en'] ?? '',
    );
  }
}

class PsychologicalTest {
  final String id;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final String type; // depression, anxiety, stress
  final int durationMinutes;
  final bool isActive;
  final List<TestQuestion> questions;
  final List<ScoringRange> scoringRanges;
  final DateTime? createdAt;

  const PsychologicalTest({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.type,
    required this.durationMinutes,
    required this.isActive,
    required this.questions,
    required this.scoringRanges,
    this.createdAt,
  });

  int get questionsCount => questions.length;

  factory PsychologicalTest.fromJson(Map<String, dynamic> json) {
    final scoring = json['scoring'] as Map<String, dynamic>? ?? {};
    final ranges = scoring['ranges'] as List<dynamic>? ?? [];

    return PsychologicalTest(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      titleEn: json['title_en'] ?? '',
      description: json['description'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      type: json['type'] ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 5,
      isActive: json['is_active'] ?? true,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => TestQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scoringRanges: ranges
          .map((e) => ScoringRange.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
    );
  }

  factory PsychologicalTest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return PsychologicalTest.fromJson(data);
  }

  ScoringRange? getInterpretation(int score) {
    for (final range in scoringRanges) {
      if (score >= range.min && score <= range.max) {
        return range;
      }
    }
    return null;
  }
}

class TestResult {
  final String id;
  final String testId;
  final String testType;
  final int totalScore;
  final String interpretation;
  final List<int> answers;
  final DateTime createdAt;

  const TestResult({
    required this.id,
    required this.testId,
    required this.testType,
    required this.totalScore,
    required this.interpretation,
    required this.answers,
    required this.createdAt,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'] ?? '',
      testId: json['test_id'] ?? '',
      testType: json['test_type'] ?? '',
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      interpretation: json['interpretation'] ?? '',
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      createdAt:
          (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory TestResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return TestResult.fromJson(data);
  }

  Map<String, dynamic> toJson() => {
        'test_id': testId,
        'test_type': testType,
        'total_score': totalScore,
        'interpretation': interpretation,
        'answers': answers,
        'created_at': FieldValue.serverTimestamp(),
      };
}
