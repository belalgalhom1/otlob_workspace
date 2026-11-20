import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/env_config.dart';

class ImageUtils {
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    if (!dotenv.isInitialized || (dotenv.env['API_URL'] ?? '').isEmpty) {
      return url;
    }

    var base = EnvConfig.apiUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    // Ensure URL starts with /
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
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

  static String cdnUrl(String path, {int? width, int? height, int? quality}) {
    var url = 'https://cdn.otlob.com';
    if (!path.startsWith('/')) {
      url += '/';
    }
    url += path;

    final queryParams = <String>[];
    if (width != null) queryParams.add('width=$width');
    if (height != null) queryParams.add('height=$height');
    if (quality != null) queryParams.add('quality=$quality');

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }
    return url;
  }
}
