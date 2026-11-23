import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum BackgroundRemovalMode {
  /// Strips exterior near-black pixels (`r < 25 && g < 25 && b < 25`, feathering
  /// smoothly across 22..45). Used for uploaded Business Type icons.
  black,

  /// Auto-detects a uniform solid backdrop at the corners (white, black, or any
  /// uniform studio background) and strips ONLY the edge-connected exterior
  /// backdrop with anti-aliased feathering while leaving natural lifestyle
  /// photos and interior product details intact. Used for product images.
  autoUniform,
}

/// Pure-Dart pixel processor that strips exterior near-black backgrounds
/// using a 4-edge-connected flood fill with smooth anti-aliased feathering
/// across channel values 22..45.
Uint8List removeBlackBackgroundRgba({
  required Uint8List rgbaBytes,
  required int width,
  required int height,
}) {
  final out = Uint8List.fromList(rgbaBytes);
  final pixelCount = width * height;
  if (pixelCount == 0 || out.length < pixelCount * 4) return out;

  const int hardTransparentMax = 24;
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

  for (var x = 0; x < width; x++) {
    trySeed(x, 0);
    trySeed(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    trySeed(0, y);
    trySeed(width - 1, y);
  }

  if (tail == 0) return out;

  while (head < tail) {
    final idx = queue[head++];
    isBackground[idx] = 1;
    final off = idx * 4;
    final a = out[off + 3];
    if (a > 0 && maxChannel(idx) >= featherEnd) continue;

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

  for (var idx = 0; idx < pixelCount; idx++) {
    final off = idx * 4;
    final a = out[off + 3];
    if (a == 0) continue;

    final r = out[off];
    final g = out[off + 1];
    final b = out[off + 2];
    final m = (r > g ? (r > b ? r : b) : (g > b ? g : b));

    if (isBackground[idx] != 0) {
      if (m <= hardTransparentMax) {
        out[off + 3] = 0;
      } else if (m < featherEnd) {
        final t = (m - featherStart) / (featherEnd - featherStart);
        out[off + 3] = (a * t.clamp(0.0, 1.0)).round();
      }
    } else if (m < 60) {
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

/// Pure-Dart pixel processor for product images.
///
/// Conservatively strips ONLY pure / near-pure white (`>= 242`) or near-pure
/// black (`<= 18`) exterior studio backdrops when all 4 corners share that
/// exact uniform backdrop color. Uses tight edge-respecting thresholds so it
/// NEVER bleeds into white/silver/light-gray product packaging (e.g., medicine
/// boxes, cartons, plates) or modifies full-bleed photos.
Uint8List removeUniformBackgroundRgba({
  required Uint8List rgbaBytes,
  required int width,
  required int height,
}) {
  final out = Uint8List.fromList(rgbaBytes);
  final pixelCount = width * height;
  if (pixelCount == 0 || width < 3 || height < 3 || out.length < pixelCount * 4) {
    return out;
  }

  final cornerIndices = <int>[
    0,
    width - 1,
    (height - 1) * width,
    (height - 1) * width + (width - 1),
  ];

  // If 3+ corners are already transparent, the image is already a PNG cutout.
  var transparentCorners = 0;
  for (final idx in cornerIndices) {
    if (out[idx * 4 + 3] < 20) transparentCorners++;
  }
  if (transparentCorners >= 3) return out;

  // All 4 corners must be opaque and agree tightly on the same backdrop color.
  double colorDist(int r1, int g1, int b1, int r2, int g2, int b2) {
    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    return math.sqrt((dr * dr + dg * dg + db * db).toDouble());
  }

  var sumR = 0;
  var sumG = 0;
  var sumB = 0;
  for (final idx in cornerIndices) {
    final off = idx * 4;
    if (out[off + 3] < 240) return out;
    sumR += out[off];
    sumG += out[off + 1];
    sumB += out[off + 2];
  }
  final bgR = (sumR / 4).round();
  final bgG = (sumG / 4).round();
  final bgB = (sumB / 4).round();

  for (final idx in cornerIndices) {
    final off = idx * 4;
    if (colorDist(out[off], out[off + 1], out[off + 2], bgR, bgG, bgB) > 14.0) {
      return out;
    }
  }

  // Only strip genuine near-pure white or near-pure black studio backdrops.
  final isPureWhiteBackdrop = bgR >= 242 && bgG >= 242 && bgB >= 242;
  final isPureBlackBackdrop = bgR <= 18 && bgG <= 18 && bgB <= 18;
  if (!isPureWhiteBackdrop && !isPureBlackBackdrop) {
    return out;
  }

  const double hardDist = 12.0;
  const double featherStart = 10.0;
  const double featherEnd = 20.0;
  const double traverseLimit = 20.0;

  double distToBg(int pixelIdx) {
    final off = pixelIdx * 4;
    return colorDist(out[off], out[off + 1], out[off + 2], bgR, bgG, bgB);
  }

  final visited = Uint8List(pixelCount);
  final isBackground = Uint8List(pixelCount);
  final queue = Int32List(pixelCount);
  var head = 0;
  var tail = 0;

  void trySeed(int x, int y) {
    final idx = y * width + x;
    if (visited[idx] != 0) return;
    final a = out[idx * 4 + 3];
    if (a == 0 || distToBg(idx) <= traverseLimit) {
      visited[idx] = 1;
      queue[tail++] = idx;
    }
  }

  for (var x = 0; x < width; x++) {
    trySeed(x, 0);
    trySeed(x, height - 1);
  }
  for (var y = 0; y < height; y++) {
    trySeed(0, y);
    trySeed(width - 1, y);
  }

  if (tail == 0) return out;

  while (head < tail) {
    final idx = queue[head++];
    isBackground[idx] = 1;
    final a = out[idx * 4 + 3];
    if (a > 0 && distToBg(idx) >= featherEnd) continue;

    final x = idx % width;
    final y = idx ~/ width;

    if (x + 1 < width) {
      final n = idx + 1;
      if (visited[n] == 0 &&
          (out[n * 4 + 3] == 0 || distToBg(n) <= traverseLimit)) {
        visited[n] = 1;
        queue[tail++] = n;
      }
    }
    if (x > 0) {
      final n = idx - 1;
      if (visited[n] == 0 &&
          (out[n * 4 + 3] == 0 || distToBg(n) <= traverseLimit)) {
        visited[n] = 1;
        queue[tail++] = n;
      }
    }
    if (y + 1 < height) {
      final n = idx + width;
      if (visited[n] == 0 &&
          (out[n * 4 + 3] == 0 || distToBg(n) <= traverseLimit)) {
        visited[n] = 1;
        queue[tail++] = n;
      }
    }
    if (y > 0) {
      final n = idx - width;
      if (visited[n] == 0 &&
          (out[n * 4 + 3] == 0 || distToBg(n) <= traverseLimit)) {
        visited[n] = 1;
        queue[tail++] = n;
      }
    }
  }

  for (var idx = 0; idx < pixelCount; idx++) {
    final off = idx * 4;
    final a = out[off + 3];
    if (a == 0) continue;

    final d = distToBg(idx);
    if (isBackground[idx] != 0) {
      if (d <= hardDist) {
        out[off + 3] = 0;
      } else if (d < featherEnd) {
        final t = ((d - featherStart) / (featherEnd - featherStart))
            .clamp(0.0, 1.0);
        out[off + 3] = (a * t).round();
      }
    } else if (d < 28.0) {
      final x = idx % width;
      final y = idx ~/ width;
      final touchesBg =
          (x + 1 < width && isBackground[idx + 1] != 0) ||
          (x > 0 && isBackground[idx - 1] != 0) ||
          (y + 1 < height && isBackground[idx + width] != 0) ||
          (y > 0 && isBackground[idx - width] != 0);
      if (touchesBg) {
        final t = ((d - featherStart) / (28.0 - featherStart)).clamp(0.0, 1.0);
        out[off + 3] = (a * t).round();
      }
    }
  }

  return out;
}

Uint8List _processInIsolate(_RgbaJob job) {
  return switch (job.mode) {
    BackgroundRemovalMode.black => removeBlackBackgroundRgba(
      rgbaBytes: job.bytes,
      width: job.width,
      height: job.height,
    ),
    BackgroundRemovalMode.autoUniform => removeUniformBackgroundRgba(
      rgbaBytes: job.bytes,
      width: job.width,
      height: job.height,
    ),
  };
}

class _RgbaJob {
  const _RgbaJob(this.bytes, this.width, this.height, this.mode);
  final Uint8List bytes;
  final int width;
  final int height;
  final BackgroundRemovalMode mode;
}

/// Renders a network image with runtime exterior background removal so icons
/// and products float directly on the parent surface with NO background box.
class TransparentBgNetworkImage extends StatefulWidget {
  const TransparentBgNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fallbackBuilder,
    this.placeholderBuilder,
    this.mode = BackgroundRemovalMode.autoUniform,
    this.fit = BoxFit.contain,
    this.width = double.infinity,
    this.height = double.infinity,
    this.maxCacheDimension = 280,
  });

  final String imageUrl;
  final WidgetBuilder fallbackBuilder;
  final WidgetBuilder? placeholderBuilder;
  final BackgroundRemovalMode mode;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int maxCacheDimension;

  static final LinkedHashMap<String, ui.Image> _cache =
      LinkedHashMap<String, ui.Image>();
  static const int _maxCacheEntries = 64;

  static String _cacheKey(String url, BackgroundRemovalMode mode, int maxDim) =>
      '${mode.name}:$maxDim:$url';

  static void _putCache(String key, ui.Image image) {
    _cache.remove(key);
    _cache[key] = image;
    while (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  @override
  State<TransparentBgNetworkImage> createState() =>
      _TransparentBgNetworkImageState();
}

class _TransparentBgNetworkImageState extends State<TransparentBgNetworkImage> {
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
  void didUpdateWidget(covariant TransparentBgNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.mode != widget.mode ||
        oldWidget.maxCacheDimension != widget.maxCacheDimension) {
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
    final key = TransparentBgNetworkImage._cacheKey(
      url,
      widget.mode,
      widget.maxCacheDimension,
    );
    final cached = TransparentBgNetworkImage._cache[key];
    if (cached != null) {
      _processedImage = cached;
      return;
    }

    final seq = ++_loadSeq;
    final provider = CachedNetworkImageProvider(
      url,
      maxWidth: widget.maxCacheDimension,
      maxHeight: widget.maxCacheDimension,
    );
    final stream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        _processDecodedImage(key, info, seq);
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
    String cacheKey,
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
              _RgbaJob(rawBytes, width, height, widget.mode),
            )
          : _processInIsolate(
              _RgbaJob(rawBytes, width, height, widget.mode),
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

      TransparentBgNetworkImage._putCache(cacheKey, processedImage);
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
    if (_hasError) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.fallbackBuilder(context),
      );
    }
    if (_processedImage == null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: (widget.placeholderBuilder ?? widget.fallbackBuilder)(context),
      );
    }

    return RawImage(
      image: _processedImage,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
    );
  }
}
