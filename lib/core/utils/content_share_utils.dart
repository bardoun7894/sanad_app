import 'dart:io';

import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/content/models/content_models.dart';

class ContentShareUtils {
  ContentShareUtils._();

  static final Dio _dio = Dio();

  /// General share using system share sheet.
  /// Attaches the post image as a file so WhatsApp/Telegram/etc render it
  /// as a real image instead of an ugly Firebase Storage link.
  static Future<void> shareContent(ContentItem content) async {
    final text = _buildShareText(content);
    final imageFile = await _downloadShareImage(content);

    if (imageFile != null) {
      await SharePlus.instance.share(
        ShareParams(text: text, files: [XFile(imageFile.path)]),
      );
    } else {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  /// Share via WhatsApp.
  /// When the post has an image, route through the system share sheet so
  /// WhatsApp receives the image as an attachment (wa.me is text-only and
  /// cannot carry files). When there is no image, fall back to wa.me.
  static Future<void> shareViaWhatsApp(ContentItem content) async {
    final imageFile = await _downloadShareImage(content);
    if (imageFile != null) {
      await SharePlus.instance.share(
        ShareParams(
          text: _buildShareText(content),
          files: [XFile(imageFile.path)],
        ),
      );
      return;
    }

    final text = Uri.encodeComponent(_buildShareText(content));
    final whatsappUrl = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Share via Facebook
  static Future<void> shareViaFacebook(ContentItem content) async {
    final linkUrl = _articleLinkUrl(content);
    if (linkUrl != null) {
      final encodedUrl = Uri.encodeComponent(linkUrl);
      final fbUrl = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl',
      );
      if (await canLaunchUrl(fbUrl)) {
        await launchUrl(fbUrl, mode: LaunchMode.externalApplication);
      }
    } else {
      await shareContent(content);
    }
  }

  static String _buildShareText(ContentItem content) {
    final buffer = StringBuffer();
    buffer.writeln(content.title);
    if (content.description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(content.description);
    }
    final linkUrl = _articleLinkUrl(content);
    if (linkUrl != null) {
      buffer.writeln();
      buffer.writeln(linkUrl);
    }
    buffer.writeln();
    buffer.write('عبر تطبيق سند 💙');
    return buffer.toString();
  }

  /// Returns a real article/video URL worth including in the share text.
  /// Returns null when contentUrl is just an image (Firebase Storage host or
  /// image file extension) — those should travel as image attachments, not
  /// as raw links that WhatsApp can't preview.
  static String? _articleLinkUrl(ContentItem content) {
    final url = content.contentUrl;
    if (url == null || url.isEmpty) return null;
    if (_looksLikeImageUrl(url)) return null;
    return url;
  }

  /// Picks the best image URL on the post (thumbnail first, then contentUrl
  /// if it points at an image) and downloads it to a temp file.
  static Future<File?> _downloadShareImage(ContentItem content) async {
    final imageUrl = _pickImageUrl(content);
    if (imageUrl == null) return null;

    try {
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;

      final ext = _imageExtensionFromUrl(imageUrl) ?? 'jpg';
      final file = File(
        '${Directory.systemTemp.path}/sanad_share_${content.id}_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  static String? _pickImageUrl(ContentItem content) {
    final thumb = content.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final url = content.contentUrl;
    if (url != null && url.isNotEmpty && _looksLikeImageUrl(url)) return url;
    return null;
  }

  static bool _looksLikeImageUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('firebasestorage.googleapis.com')) return true;
    if (lower.contains('firebasestorage.app')) return true;
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif') ||
        path.endsWith('.heic');
  }

  static String? _imageExtensionFromUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    for (final ext in const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic']) {
      if (path.endsWith('.$ext')) return ext;
    }
    return null;
  }
}
