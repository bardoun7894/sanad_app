import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/content/models/content_models.dart';

class ContentShareUtils {
  ContentShareUtils._();

  /// General share using system share sheet
  static Future<void> shareContent(ContentItem content) async {
    final text = _buildShareText(content);
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// Share via WhatsApp
  static Future<void> shareViaWhatsApp(ContentItem content) async {
    final text = Uri.encodeComponent(_buildShareText(content));
    final whatsappUrl = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  /// Share via Facebook
  static Future<void> shareViaFacebook(ContentItem content) async {
    if (content.contentUrl != null && content.contentUrl!.isNotEmpty) {
      final encodedUrl = Uri.encodeComponent(content.contentUrl!);
      final fbUrl = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl',
      );
      if (await canLaunchUrl(fbUrl)) {
        await launchUrl(fbUrl, mode: LaunchMode.externalApplication);
      }
    } else {
      // Fallback to general share if no URL
      await shareContent(content);
    }
  }

  static String _buildShareText(ContentItem content) {
    final buffer = StringBuffer();
    buffer.writeln(content.title);
    if (content.description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(content.description.length > 150
          ? '${content.description.substring(0, 150)}...'
          : content.description);
    }
    if (content.contentUrl != null && content.contentUrl!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(content.contentUrl);
    }
    buffer.writeln();
    buffer.write('عبر تطبيق سند 💙');
    return buffer.toString();
  }
}
