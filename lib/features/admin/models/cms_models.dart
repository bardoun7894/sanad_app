import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { article, exercise, video }

class DailyQuote {
  final String id;
  final String text; // Arabic
  final String textEn;
  final String author; // Arabic
  final String authorEn;
  final String category; // e.g., 'Anxiety', 'Depression', 'General'
  final DateTime? publishDate;
  final bool isActive;

  DailyQuote({
    required this.id,
    required this.text,
    this.textEn = '',
    this.author = '',
    this.authorEn = '',
    this.category = 'General',
    this.publishDate,
    this.isActive = true,
  });

  factory DailyQuote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyQuote(
      id: doc.id,
      text: data['text'] ?? '',
      textEn: data['text_en'] ?? '',
      author: data['author'] ?? '',
      authorEn: data['author_en'] ?? '',
      category: data['category'] ?? 'General',
      publishDate: data['publish_date'] != null
          ? (data['publish_date'] as Timestamp).toDate()
          : null,
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'text_en': textEn,
      'author': author,
      'author_en': authorEn,
      'category': category,
      // Never persist a null publish_date: the app reads quotes with
      // orderBy('publish_date'), and Firestore silently drops any doc missing
      // that field — a null here would make the quote invisible in the app.
      'publish_date': Timestamp.fromDate(publishDate ?? DateTime.now()),
      'is_active': isActive,
    };
  }

  /// Locale-aware reader. Falls back to Arabic when English is empty.
  String localizedText(String localeCode) =>
      (localeCode.toLowerCase().startsWith('en') && textEn.trim().isNotEmpty)
          ? textEn
          : text;

  String localizedAuthor(String localeCode) =>
      (localeCode.toLowerCase().startsWith('en') && authorEn.trim().isNotEmpty)
          ? authorEn
          : author;
}

class AppContent {
  final String id;
  final String title;
  final String titleEn;
  final String category;
  final ContentType type;
  final String? contentText;
  final String? contentTextEn;
  final String? mediaUrl;
  final String? linkUrl;
  final bool isPublished;
  final List<String> moodTags;
  final DateTime createdAt;

  AppContent({
    required this.id,
    required this.title,
    this.titleEn = '',
    required this.category,
    required this.type,
    this.contentText,
    this.contentTextEn,
    this.mediaUrl,
    this.linkUrl,
    this.isPublished = true,
    this.moodTags = const [],
    required this.createdAt,
  });

  factory AppContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppContent(
      id: doc.id,
      title: data['title'] ?? '',
      titleEn: data['title_en'] ?? '',
      category: data['category'] ?? 'General',
      type: ContentType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'article'),
        orElse: () => ContentType.article,
      ),
      contentText: data['content_text'],
      contentTextEn: data['content_text_en'],
      mediaUrl: data['media_url'],
      linkUrl: data['link_url'],
      isPublished: data['is_published'] ?? false,
      moodTags: List<String>.from(data['mood_tags'] ?? const []),
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'title_en': titleEn,
      'category': category,
      'type': type.name,
      'content_text': contentText,
      'content_text_en': contentTextEn,
      'media_url': mediaUrl,
      'link_url': linkUrl,
      'is_published': isPublished,
      'mood_tags': moodTags,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  AppContent copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? category,
    ContentType? type,
    String? contentText,
    String? contentTextEn,
    String? mediaUrl,
    String? linkUrl,
    bool? isPublished,
    List<String>? moodTags,
    DateTime? createdAt,
  }) {
    return AppContent(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      category: category ?? this.category,
      type: type ?? this.type,
      contentText: contentText ?? this.contentText,
      contentTextEn: contentTextEn ?? this.contentTextEn,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      isPublished: isPublished ?? this.isPublished,
      moodTags: moodTags ?? this.moodTags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Challenge types for daily challenges.
/// Keep in sync with the app-side enum in
/// lib/features/engagement/models/challenge.dart — the two are serialized by
/// `.name`, so a type known to one side but not the other gets silently
/// rewritten on round-trip and the wrong icon/color renders.
enum ChallengeType {
  breathing,
  gratitude,
  mindfulness,
  exercise,
  journaling,
  social,
  selfCare,
  movement,
  general,
}

/// Daily Challenge model for admin CMS
/// Admin-editable journaling prompt ("سؤال اليوم" for مذكرتي).
/// Stored in the `journaling_prompts` collection. This is the ONLY
/// journal-related data in the cloud — generic questions, never user content.
class JournalPromptCms {
  final String id;
  final String question;
  final String questionEn;
  final int order;
  final bool isActive;

  JournalPromptCms({
    required this.id,
    required this.question,
    this.questionEn = '',
    this.order = 0,
    this.isActive = true,
  });

  factory JournalPromptCms.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JournalPromptCms(
      id: doc.id,
      question: data['question'] ?? '',
      questionEn: data['question_en'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'question_en': questionEn,
      'order': order,
      'is_active': isActive,
    };
  }

  JournalPromptCms copyWith({
    String? id,
    String? question,
    String? questionEn,
    int? order,
    bool? isActive,
  }) {
    return JournalPromptCms(
      id: id ?? this.id,
      question: question ?? this.question,
      questionEn: questionEn ?? this.questionEn,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Admin-editable supportive advice shown when a user picks a mood in the
/// journal. One document per mood in the `mood_advice` collection (doc id =
/// MoodType.name, e.g. "anxious"). Content is generic guidance, not user data.
class MoodAdvice {
  final String mood; // MoodType.name
  final String advice;
  final String adviceEn;
  final bool isActive;

  MoodAdvice({
    required this.mood,
    required this.advice,
    this.adviceEn = '',
    this.isActive = true,
  });

  factory MoodAdvice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoodAdvice(
      mood: doc.id,
      advice: data['advice'] ?? '',
      adviceEn: data['advice_en'] ?? '',
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'advice': advice,
        'advice_en': adviceEn,
        'is_active': isActive,
      };

  MoodAdvice copyWith({String? advice, String? adviceEn, bool? isActive}) {
    return MoodAdvice(
      mood: mood,
      advice: advice ?? this.advice,
      adviceEn: adviceEn ?? this.adviceEn,
      isActive: isActive ?? this.isActive,
    );
  }
}

class DailyChallenge {
  final String id;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final ChallengeType type;
  final int durationMinutes;
  final int order;
  final DateTime? publishDate;
  final bool isActive;

  DailyChallenge({
    required this.id,
    required this.title,
    this.titleEn = '',
    required this.description,
    this.descriptionEn = '',
    this.type = ChallengeType.general,
    this.durationMinutes = 5,
    this.order = 0,
    this.publishDate,
    this.isActive = true,
  });

  factory DailyChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyChallenge(
      id: doc.id,
      title: data['title'] ?? '',
      titleEn: data['title_en'] ?? '',
      description: data['description'] ?? '',
      descriptionEn: data['description_en'] ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'general'),
        orElse: () => ChallengeType.general,
      ),
      durationMinutes: data['duration_minutes'] ?? 5,
      order: data['order'] ?? 0,
      publishDate: data['publish_date'] != null
          ? (data['publish_date'] as Timestamp).toDate()
          : null,
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'title_en': titleEn,
      'description': description,
      'description_en': descriptionEn,
      'type': type.name,
      'duration_minutes': durationMinutes,
      'order': order,
      'publish_date':
          publishDate != null ? Timestamp.fromDate(publishDate!) : null,
      'is_active': isActive,
    };
  }

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? description,
    String? descriptionEn,
    ChallengeType? type,
    int? durationMinutes,
    int? order,
    DateTime? publishDate,
    bool? isActive,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      order: order ?? this.order,
      publishDate: publishDate ?? this.publishDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
