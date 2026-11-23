import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Pure-Dart pixel processor that strips exterior near-black backgrounds
/// (e.g. solid `#000000` square backgrounds baked into uploaded category icons)
/// using a 4-edge-connected flood fill with smooth anti-aliased feathering
/// across channel values 22..45.
///
/// Edge-connected flood-fill ensures dark details *inside* the icon artwork
/// (such as outlines, shadows, or chalkboards) remain 100% opaque while the
/// surrounding black background becomes transparent so the `#FFFFFF` tile shows
/// through cleanly.
Uint8List removeBlackBackgroundRgba({
  required Uint8List rgbaBytes,
  required int width,
  required int height,
}) {
  final out = Uint8List.fromList(rgbaBytes);
  final pixelCount = width * height;
  if (pixelCount == 0 || out.length < pixelCount * 4) return out;

  const int hardTransparentMax = 24; // r < 25 && g < 25 && b < 25
  const int featherStart = 22;
  const int featherEnd = 45;
  const int seedAndTraverseLimit = 48;

  final visited = Uint8List(pixelCount);
  final isBackground = Uint8List(pixelCount);
  final queue = Int32List(pixelCount);
  var head = 0;
  var tail = 0;

  int maxChannel(int pixelIdx) {
    final off = pixelIdx * 4;
    final r = out[off];
    final g = out[off + 1];
    final b = out[off + 2];
    final rg = r > g ? r : g;
    return rg > b ? rg : b;
  }

  void trySeed(int x, int y) {
    final idx = y * width + x;
    if (visited[idx] != 0) return;
    final off = idx * 4;
    final a = out[off + 3];
    if (a == 0 || maxChannel(idx) < seedAndTraverseLimit) {
      visited[idx] = 1;
      queue[tail++] = idx;
    }
  }

  // Seed along all 4 outer borders
  for (var x = 0; x < width; x++) {
    trySeed(x, 0);
    trySeed(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    trySeed(0, y);
    trySeed(width - 1, y);
  }

  if (tail == 0) {
    // Border has no dark/transparent pixels — nothing to remove.
    return out;
  }

  // BFS flood-fill through connected dark exterior pixels
  while (head < tail) {
    final idx = queue[head++];
    isBackground[idx] = 1;
    final off = idx * 4;
    final a = out[off + 3];
    if (a > 0 && maxChannel(idx) >= featherEnd) {
      // Stop propagating past the feather band boundary
      continue;
    }

    final x = idx % width;
    final y = idx ~/ width;

    if (x + 1 < width) {
      final n = idx + 1;
      if (visited[n] == 0 &&
          (out[n * 4 + 3] == 0 || maxChannel(n) < seedAndTraverseLimit)) {
        visited[n] = 1;
        queue[tail++] = n;
      }
    }
    if (x > 0) {
      final n = idx - 1;
      if (visited[n] == 0 &&
          (out[n * 4 + 3] == 0 || maxChannel(n) < seedAndTraverseLimit)) {
        visited[n] = 1;
        queue[tail++] = n;
      }
    }
    if (y + 1 < height) {
      final n = idx + width;
      if (visited[n] == 0 &&
          (out[n * 4 + 3] == 0 || maxChannel(n) < seedAndTraverseLimit)) {
        visited[n] = 1;
        queue[tail++] = n;
      }
    }
    if (y > 0) {
      final n = idx - width;
      if (visited[n] == 0 &&
          (out[n * 4 + 3] == 0 || maxChannel(n) < seedAndTraverseLimit)) {
        visited[n] = 1;
        queue[tail++] = n;
      }
    }
  }

  // Apply transparency & smooth anti-aliased edge feathering (22..45)
  for (var idx = 0; idx < pixelCount; idx++) {
    final off = idx * 4;
    final a = out[off + 3];
    if (a == 0) continue;

    final r = out[off];
    final g = out[off + 1];
    final b = out[off + 2];
    final m = (r > g ? (r > b ? r : b) : (g > b ? g : b));

    if (isBackground[idx] != 0) {
      if (r <= hardTransparentMax &&
          g <= hardTransparentMax &&
          b <= hardTransparentMax &&
          m <= featherStart) {
        out[off + 3] = 0;
      } else if (m <= hardTransparentMax) {
        out[off + 3] = 0;
      } else if (m < featherEnd) {
        final t = (m - featherStart) / (featherEnd - featherStart);
        out[off + 3] = (a * t.clamp(0.0, 1.0)).round();
      }
    } else if (m < 60) {
      // Soften 1px dark anti-aliased halo pixels directly bordering the removed background
      final x = idx % width;
      final y = idx ~/ width;
      final touchesBg =
          (x + 1 < width && isBackground[idx + 1] != 0) ||
          (x > 0 && isBackground[idx - 1] != 0) ||
          (y + 1 < height && isBackground[idx + width] != 0) ||
          (y > 0 && isBackground[idx - width] != 0);
      if (touchesBg) {
        final t = ((m - featherStart) / (60 - featherStart)).clamp(0.0, 1.0);
        out[off + 3] = (a * t).round();
      }
    }
  }

  return out;
}

Uint8List _processInIsolate(_RgbaJob job) => removeBlackBackgroundRgba(
  rgbaBytes: job.bytes,
  width: job.width,
  height: job.height,
);

class _RgbaJob {
  const _RgbaJob(this.bytes, this.width, this.height);
  final Uint8List bytes;
  final int width;
  final int height;
}

/// Renders an uploaded Business Type category image edge-to-edge (`BoxFit.cover`)
/// over a pure white (`#FFFFFF`) background while stripping near-black exterior
/// backgrounds at runtime with smooth anti-aliased edge feathering.
class CategoryWhiteBgImage extends StatefulWidget {
  const CategoryWhiteBgImage({
    super.key,
    required this.imageUrl,
    required this.fallbackBuilder,
  });

  final String imageUrl;
  final WidgetBuilder fallbackBuilder;

  static final LinkedHashMap<String, ui.Image> _cache =
      LinkedHashMap<String, ui.Image>();
  static const int _maxCacheEntries = 32;

  static void _putCache(String url, ui.Image image) {
    _cache.remove(url);
    _cache[url] = image;
    while (_cache.length > _maxCacheEntries) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  @override
  State<CategoryWhiteBgImage> createState() => _CategoryWhiteBgImageState();
}

class _CategoryWhiteBgImageState extends State<CategoryWhiteBgImage> {
  ImageStream? _imageStream;
  ImageStreamListener? _listener;
  ui.Image? _processedImage;
  bool _hasError = false;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant CategoryWhiteBgImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _detachStream();
      _processedImage = null;
      _hasError = false;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _detachStream();
    super.dispose();
  }

  void _detachStream() {
    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
    }
    _imageStream = null;
    _listener = null;
  }

  void _resolveImage() {
    final url = widget.imageUrl;
    final cached = CategoryWhiteBgImage._cache[url];
    if (cached != null) {
      _processedImage = cached;
      return;
    }

    final seq = ++_loadSeq;
    final provider = CachedNetworkImageProvider(
      url,
      maxWidth: 240,
      maxHeight: 240,
    );
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        _processDecodedImage(url, info, seq);
      },
      onError: (_, _) {
        if (!mounted || seq != _loadSeq) return;
        setState(() => _hasError = true);
      },
    );
    _imageStream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  Future<void> _processDecodedImage(
    String url,
    ImageInfo info,
    int seq,
  ) async {
    try {
      final srcImage = info.image;
      final width = srcImage.width;
      final height = srcImage.height;
      final byteData = await srcImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        if (mounted && seq == _loadSeq) {
          setState(() => _hasError = true);
        }
        return;
      }

      final rawBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final processedBytes = width * height > 4096
          ? await compute(
              _processInIsolate,
              _RgbaJob(rawBytes, width, height),
            )
          : removeBlackBackgroundRgba(
              rgbaBytes: rawBytes,
              width: width,
              height: height,
            );

      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        processedBytes,
        width,
        height,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
      final processedImage = await completer.future;

      CategoryWhiteBgImage._putCache(url, processedImage);
      if (!mounted || seq != _loadSeq) return;
      setState(() {
        _processedImage = processedImage;
        _hasError = false;
      });
    } catch (_) {
      if (mounted && seq == _loadSeq) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _processedImage == null) {
      return ColoredBox(
        color: Colors.white,
        child: widget.fallbackBuilder(context),
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: RawImage(
        image: _processedImage,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
