import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    final videoId = widget.content.youTubeVideoId;
    if (videoId == null) return;

    // Use iframe embed HTML — far more reliable in WebViews than loading
    // m.youtube.com (which triggers sign-in redirects, consent pages, etc.)
    final embedHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #000; width: 100%; height: 100vh; display: flex; align-items: center; justify-content: center; }
    .video-container { position: relative; width: 100%; padding-bottom: 56.25%; height: 0; }
    .video-container iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none; }
  </style>
</head>
<body>
  <div class="video-container">
    <iframe
      src="https://www.youtube-nocookie.com/embed/$videoId?autoplay=1&playsinline=1&rel=0&modestbranding=1"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
      allowfullscreen>
    </iframe>
  </div>
</body>
</html>
''';

    final controller = WebViewController();

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _isLoading = true; _hasError = false; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            // Only show error for main frame failures, not sub-resources
            if (error.isForMainFrame == true) {
              if (mounted) setState(() { _isLoading = false; _hasError = true; });
            }
          },
          onNavigationRequest: (request) {
            // Allow YouTube embed and nocookie domains
            final url = request.url;
            if (url.contains('youtube-nocookie.com') ||
                url.contains('youtube.com') ||
                url.contains('youtu.be') ||
                url.startsWith('about:')) {
              return NavigationDecision.navigate;
            }
            // Open anything else (ads, external links) in external browser
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(embedHtml, baseUrl: 'https://www.youtube-nocookie.com');
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
          : Stack(
              children: [
                // Black background while loading
                Container(color: Colors.black),
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (_hasError && !_isLoading)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'تعذّر تشغيل الفيديو',
                            style: AppTypography.bodyLarge.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _openExternal,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('فتح في يوتيوب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
