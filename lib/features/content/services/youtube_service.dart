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

  Future<List<ContentItem>> getSanadTubeVideos({int? limit}) =>
      _fetchPlaylist(_sanadTubePlaylist, limit: limit, type: 'video');

  Future<List<ContentItem>> getSanadPodcastVideos({int? limit}) =>
      _fetchPlaylist(_sanadPodcastPlaylist, limit: limit, type: 'podcast');

  /// Fetches playlist items, walking `nextPageToken` pages so "no limit"
  /// really means ALL episodes (owner asked to drop the 30-item cap).
  ///
  /// [limit] null/0 = fetch every page (safety-capped at [_maxUnlimitedItems]
  /// so a pathological playlist can't loop forever); otherwise only the
  /// first [limit] items are kept.
  static const int _maxUnlimitedItems = 500;

  Future<List<ContentItem>> _fetchPlaylist(
    String playlistId, {
    int? limit,
    String type = 'video',
  }) async {
    final apiKey = AppConfig.youtubeApiKey;
    if (apiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('[YouTubeService] YOUTUBE_API_KEY missing');
      }
      return [];
    }

    final effectiveLimit = (limit == null || limit <= 0)
        ? _maxUnlimitedItems
        : limit;
    final pageSize = effectiveLimit.clamp(1, 50);

    final result = <ContentItem>[];
    String? pageToken;

    try {
      while (result.length < effectiveLimit) {
        final response = await _dio.get(
          '$_apiBase/playlistItems',
          queryParameters: {
            'part': 'snippet',
            'playlistId': playlistId,
            'maxResults': pageSize,
            if (pageToken != null) 'pageToken': pageToken,
            'key': apiKey,
          },
          options: Options(receiveTimeout: const Duration(seconds: 10)),
        );

        if (response.statusCode != 200) break;

        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List?) ?? const [];

        for (final raw in items) {
          if (result.length >= effectiveLimit) break;
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
          final thumbnailUrl =
              (picked is Map ? picked['url'] : null) as String? ??
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

        pageToken = data['nextPageToken'] as String?;
        if (pageToken == null || pageToken.isEmpty) break;
      }

      return result;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[YouTubeService] playlist $playlistId failed: $e');
        debugPrint('$st');
      }
      // Keep whatever pages already came back. Since the 30-item cap was
      // dropped this loop makes up to 10 requests per playlist, so a single
      // slow page on a flaky mobile network used to wipe out the entire
      // list (and with it the video/podcast slots on the home screen).
      return result;
    }
  }
}
