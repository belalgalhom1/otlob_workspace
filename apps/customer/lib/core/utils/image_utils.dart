import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageUtils {
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;

    var baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:3000';

    // Remove trailing slash from baseUrl
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    // Ensure path starts with /
    final path = url.startsWith('/') ? url : '/$url';

    return '$baseUrl$path';
  }

  static String thumbnailUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('_thumb.')) return formatImageUrl(url);

    if (url.endsWith('.webp')) {
      return formatImageUrl(url.replaceAll(RegExp(r'\.webp$'), '_thumb.webp'));
    }

    final uri = Uri.tryParse(url);
    if (uri != null && uri.path.contains('.')) {
      final lastDot = uri.path.lastIndexOf('.');
      final thumbPath = '${uri.path.substring(0, lastDot)}_thumb.webp';
      final replaced = uri.replace(path: thumbPath).toString();
      return formatImageUrl(replaced);
    }

    return formatImageUrl(url);
  }
}
