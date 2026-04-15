import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';

final youtubeServiceProvider = Provider((ref) => YouTubeService());

/// Service to fetch videos from a YouTube channel via its RSS/Atom feed.
/// No API key required.
class YouTubeService {
  static const String channelId = 'UCWS5K6VFx3YrGBqhoVmMRSQ';
  static const String _feedUrl =
      'https://www.youtube.com/feeds/videos.xml?channel_id=$channelId';

  final Dio _dio = Dio();

  /// Fetches the latest videos from the YouTube channel.
  /// Returns them as [ContentItem] objects compatible with existing cards.
  Future<List<ContentItem>> getChannelVideos({int limit = 10}) async {
    try {
      final response = await _dio.get(
        _feedUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode != 200) return [];

      final xml = response.data as String;
      return _parseAtomFeed(xml, limit: limit);
    } catch (e) {
      return [];
    }
  }

  /// Parse the Atom XML feed into ContentItem list.
  /// Uses simple string parsing to avoid adding an XML package dependency.
  List<ContentItem> _parseAtomFeed(String xml, {int limit = 10}) {
    final items = <ContentItem>[];

    // Split by <entry> tags
    final entries = xml.split('<entry>');
    // Skip the first split (it's the feed header)
    for (int i = 1; i < entries.length && items.length < limit; i++) {
      final entry = entries[i];
      final endIndex = entry.indexOf('</entry>');
      final entryContent = endIndex >= 0 ? entry.substring(0, endIndex) : entry;

      final videoId = _extractTag(entryContent, 'yt:videoId');
      final title = _extractTag(entryContent, 'title');
      // media:description has the video description
      final description =
          _extractTag(entryContent, 'media:description') ?? '';
      final published = _extractTag(entryContent, 'published');

      if (videoId == null || title == null) continue;

      final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      final contentUrl = 'https://www.youtube.com/watch?v=$videoId';

      DateTime? createdAt;
      if (published != null) {
        createdAt = DateTime.tryParse(published);
      }

      items.add(ContentItem(
        id: 'yt_$videoId',
        title: title,
        description: description,
        type: 'video',
        category: null,
        contentUrl: contentUrl,
        thumbnailUrl: thumbnailUrl,
        createdAt: createdAt,
      ));
    }

    return items;
  }

  /// Extract text content from a simple XML tag.
  String? _extractTag(String xml, String tagName) {
    final openTag = '<$tagName>';
    final closeTag = '</$tagName>';
    final startIdx = xml.indexOf(openTag);
    if (startIdx < 0) return null;
    final contentStart = startIdx + openTag.length;
    final endIdx = xml.indexOf(closeTag, contentStart);
    if (endIdx < 0) return null;
    return _decodeXmlEntities(xml.substring(contentStart, endIdx).trim());
  }

  /// Decode common XML entities.
  String _decodeXmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }
}
