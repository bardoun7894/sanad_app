import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/app_config.dart';
import '../models/content_models.dart';

final youtubeServiceProvider = Provider((ref) => YouTubeService());

class YouTubeService {
  static const String _channelId = 'UCWS5K6VFx3YrGBqhoVmMRSQ';
  static const String _sanadTubePlaylist = 'PLvz7o6Rxv9iBASvocqCB7GH5IMvHz---T';
  static const String _sanadPodcastPlaylist =
      'PLvz7o6Rxv9iDkB_C7qeejg5_IY8RMCUdZ';

  static const String _apiBase = 'https://www.googleapis.com/youtube/v3';

  // Channel uploads playlist follows YouTube's UC -> UU convention.
  static String get _channelUploadsPlaylist =>
      _channelId.replaceFirst('UC', 'UU');

  final Dio _dio = Dio();

  Future<List<ContentItem>> getChannelVideos({int limit = 10}) =>
      _fetchPlaylist(_channelUploadsPlaylist, limit: limit, type: 'video');

  Future<List<ContentItem>> getSanadTubeVideos({int limit = 10}) =>
      _fetchPlaylist(_sanadTubePlaylist, limit: limit, type: 'video');

  Future<List<ContentItem>> getSanadPodcastVideos({int limit = 10}) =>
      _fetchPlaylist(_sanadPodcastPlaylist, limit: limit, type: 'podcast');

  Future<List<ContentItem>> _fetchPlaylist(
    String playlistId, {
    int limit = 10,
    String type = 'video',
  }) async {
    final apiKey = AppConfig.youtubeApiKey;
    if (apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[YouTubeService] YOUTUBE_API_KEY missing');
      }
      return [];
    }

    try {
      final response = await _dio.get(
        '$_apiBase/playlistItems',
        queryParameters: {
          'part': 'snippet',
          'playlistId': playlistId,
          'maxResults': limit.clamp(1, 50),
          'key': apiKey,
        },
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode != 200) return [];

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? const [];

      final result = <ContentItem>[];
      for (final raw in items) {
        final snippet = (raw as Map)['snippet'] as Map?;
        if (snippet == null) continue;

        final resourceId = (snippet['resourceId'] as Map?) ?? const {};
        final videoId = resourceId['videoId'] as String?;
        final title = snippet['title'] as String?;
        if (videoId == null || title == null) continue;

        // Skip private/deleted entries — YouTube returns "Private video"
        // / "Deleted video" placeholders without a usable thumbnail.
        if (title == 'Private video' || title == 'Deleted video') continue;

        final thumbnails = (snippet['thumbnails'] as Map?) ?? const {};
        final picked = thumbnails['high'] ??
            thumbnails['medium'] ??
            thumbnails['default'];
        final thumbnailUrl = (picked is Map ? picked['url'] : null) as String? ??
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

        DateTime? publishedAt;
        final publishedRaw = snippet['publishedAt'] as String?;
        if (publishedRaw != null) {
          publishedAt = DateTime.tryParse(publishedRaw);
        }

        result.add(
          ContentItem(
            id: 'yt_$videoId',
            title: title,
            description: (snippet['description'] as String?) ?? '',
            type: type,
            category: null,
            contentUrl: 'https://www.youtube.com/watch?v=$videoId',
            thumbnailUrl: thumbnailUrl,
            createdAt: publishedAt,
          ),
        );
      }

      return result;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[YouTubeService] playlist $playlistId failed: $e');
        debugPrint('$st');
      }
      return [];
    }
  }
}
