import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType { article, exercise, video }

class DailyQuote {
  final String id;
  final String text;
  final String author;
  final String category; // e.g., 'Anxiety', 'Depression', 'General'
  final DateTime? publishDate;
  final bool isActive;

  DailyQuote({
    required this.id,
    required this.text,
    this.author = '',
    this.category = 'General',
    this.publishDate,
    this.isActive = true,
  });

  factory DailyQuote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyQuote(
      id: doc.id,
      text: data['text'] ?? '',
      author: data['author'] ?? '',
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
      'author': author,
      'category': category,
      'publish_date': publishDate != null
          ? Timestamp.fromDate(publishDate!)
          : null,
      'is_active': isActive,
    };
  }
}

class AppContent {
  final String id;
  final String title;
  final String category; // e.g., 'Anxiety', 'Sleep'
  final ContentType type;
  final String? contentText; // For articles
  final String? mediaUrl; // For videos/images
  final String? linkUrl; // External link
  final bool isPublished;
  final DateTime createdAt;

  AppContent({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    this.contentText,
    this.mediaUrl,
    this.linkUrl,
    this.isPublished = false,
    required this.createdAt,
  });

  factory AppContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppContent(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'General',
      type: ContentType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'article'),
        orElse: () => ContentType.article,
      ),
      contentText: data['content_text'],
      mediaUrl: data['media_url'],
      linkUrl: data['link_url'],
      isPublished: data['is_published'] ?? false,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'type': type.name,
      'content_text': contentText,
      'media_url': mediaUrl,
      'link_url': linkUrl,
      'is_published': isPublished,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  AppContent copyWith({
    String? id,
    String? title,
    String? category,
    ContentType? type,
    String? contentText,
    String? mediaUrl,
    String? linkUrl,
    bool? isPublished,
    DateTime? createdAt,
  }) {
    return AppContent(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      type: type ?? this.type,
      contentText: contentText ?? this.contentText,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Challenge types for daily challenges
enum ChallengeType {
  breathing,
  gratitude,
  mindfulness,
  exercise,
  journaling,
  social,
  selfCare,
  general,
}

/// Daily Challenge model for admin CMS
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
