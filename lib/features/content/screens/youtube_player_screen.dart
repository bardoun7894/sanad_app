import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/content_share_utils.dart';
import '../models/content_models.dart';

class YouTubePlayerScreen extends StatefulWidget {
  final ContentItem content;

  const YouTubePlayerScreen({super.key, required this.content});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final videoId = widget.content.youTubeVideoId;
    if (videoId == null) return;

    // Load the mobile YouTube watch page directly (not embed).
    // The embed URL causes Error 153 in WebViews.
    final watchUrl = 'https://m.youtube.com/watch?v=$videoId';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(watchUrl));
  }

  void _openExternal() async {
    if (widget.content.contentUrl != null) {
      final uri = Uri.parse(widget.content.contentUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videoId = widget.content.youTubeVideoId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.content.title,
          style: AppTypography.displayMedium.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          // Open in YouTube app/browser
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'فتح في يوتيوب',
            onPressed: _openExternal,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ContentShareUtils.shareContent(widget.content),
          ),
        ],
      ),
      body: videoId == null
          ? Center(
              child: Text(
                'رابط الفيديو غير صالح',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video Player - full YouTube mobile page
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_isLoading)
                        Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
