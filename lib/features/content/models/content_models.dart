import 'package:cloud_firestore/cloud_firestore.dart';

class DailyQuote {
  final String id;
  final String text;
  final String author;
  final DateTime publishDate;

  DailyQuote({
    required this.id,
    required this.text,
    required this.author,
    required this.publishDate,
  });

  factory DailyQuote.fromJson(Map<String, dynamic> json) {
    return DailyQuote(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      author: json['author'] ?? 'Unknown',
      publishDate:
          (json['publish_date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Content types for recommendations
enum ContentType { article, exercise, podcast, video }

class ContentItem {
  final String id;
  final String title;
  final String description;
  final String type; // 'article', 'exercise', 'podcast', 'video'
  final String? category;
  final String? contentUrl;
  final String? thumbnailUrl;
  final bool isPremium;
  final bool isPublished;
  final List<String> moodTags;
  final DateTime? createdAt;
  final int? durationMinutes;

  ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.category,
    this.contentUrl,
    this.thumbnailUrl,
    this.isPremium = false,
    this.isPublished = true,
    this.moodTags = const [],
    this.createdAt,
    this.durationMinutes,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      // Admin writes 'content_text', fallback to 'description'
      description: json['content_text'] ?? json['description'] ?? '',
      type: json['type'] ?? 'article',
      category: json['category'],
      // Admin writes 'media_url' or 'link_url', fallback to 'content_url'
      contentUrl: json['media_url'] ?? json['link_url'] ?? json['content_url'],
      thumbnailUrl: json['thumbnail_url'],
      isPremium: json['is_premium'] ?? false,
      isPublished: json['is_published'] ?? true,
      moodTags: List<String>.from(json['mood_tags'] ?? []),
      createdAt: (json['created_at'] as Timestamp?)?.toDate(),
      durationMinutes: json['duration_minutes'] as int?,
    );
  }

  factory ContentItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    data['id'] = doc.id;
    return ContentItem.fromJson(data);
  }

  /// Check if contentUrl is a YouTube video link
  bool get isYouTubeVideo {
    if (contentUrl == null) return false;
    final url = contentUrl!.toLowerCase();
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('youtube-nocookie.com');
  }

  /// Extract YouTube video ID from URL
  String? get youTubeVideoId {
    if (contentUrl == null) return null;
    final uri = Uri.tryParse(contentUrl!);
    if (uri == null) return null;

    // youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    // youtu.be/VIDEO_ID
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    // youtube-nocookie.com/embed/VIDEO_ID
    if (uri.host.contains('youtube-nocookie.com') && uri.pathSegments.length >= 2) {
      return uri.pathSegments[1];
    }
    return null;
  }

  /// Formatted duration string
  String get formattedDuration {
    if (durationMinutes == null) return '';
    if (durationMinutes! >= 60) {
      final hours = durationMinutes! ~/ 60;
      final mins = durationMinutes! % 60;
      return mins > 0 ? '$hours ساعة $mins دقيقة' : '$hours ساعة';
    }
    return '$durationMinutes دقيقة';
  }
}
