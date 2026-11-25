import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'category_icon_image.dart';
import 'store_detail_tokens.dart';

/// Launches a slow, smooth quadratic-Bézier parabolic Fly-to-Cart thumbnail
/// overlay from [srcRect] to [dstRect] on the root [Overlay], then calls
/// [onLanded] when the thumbnail arrives at the existing Cart UI.
void launchFlyToCartAnimation({
  required BuildContext context,
  required Rect srcRect,
  required Rect dstRect,
  required String? imageUrl,
  VoidCallback? onLanded,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    onLanded?.call();
    return;
  }

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ParabolicFlyToCartOverlay(
      srcRect: srcRect,
      dstRect: dstRect,
      imageUrl: imageUrl,
      onComplete: () {
        if (entry.mounted) {
          entry.remove();
        }
        onLanded?.call();
      },
    ),
  );

  overlay.insert(entry);
}

class _ParabolicFlyToCartOverlay extends StatefulWidget {
  final Rect srcRect;
  final Rect dstRect;
  final String? imageUrl;
  final VoidCallback onComplete;

  const _ParabolicFlyToCartOverlay({
    required this.srcRect,
    required this.dstRect,
    required this.imageUrl,
    required this.onComplete,
  });

  @override
  State<_ParabolicFlyToCartOverlay> createState() =>
      _ParabolicFlyToCartOverlayState();
}

class _ParabolicFlyToCartOverlayState extends State<_ParabolicFlyToCartOverlay>
    with SingleTickerProviderStateMixin {
  static const double _size = 64.0;
  static const int _totalMs = 820;
  static const double _liftPhaseEnd = 0.10;

  // Low peak-velocity sine easing keeps the flying image clearly readable
  // across the entire arc instead of zipping quickly through the middle.
  static const Curve _flightCurve = Curves.easeInOutSine;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFallbackIcon() {
    return const Center(
      child: Icon(
        Icons.shopping_bag_rounded,
        color: Color(0xFFE5A93C),
        size: 26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startX = widget.srcRect.left + widget.srcRect.width / 2;
    final startY = widget.srcRect.top + widget.srcRect.height / 2;
    final liftedY = math.max(36.0, startY - 18.0);
    final endX = widget.dstRect.left + widget.dstRect.width / 2;
    final endY = widget.dstRect.top + widget.dstRect.height / 2;

    // Quadratic Bézier control point high above the midpoint produces a true,
    // continuous parabolic arc that stays clearly visible across the screen.
    final ctrlX = (startX + endX) / 2;
    final ctrlY = math.max(36.0, math.min(liftedY, endY) - 165.0);

    final resolvedUrl = widget.imageUrl?.trim() ?? '';

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final rawT = _controller.value;

          final double x;
          final double y;
          final double scale;

          if (rawT < _liftPhaseEnd) {
            // Brief anticipation pop & lift so the user's eye locks onto
            // the product image before it glides across the screen.
            final p = Curves.easeOutBack.transform(
              (rawT / _liftPhaseEnd).clamp(0.0, 1.0),
            );
            x = startX;
            y = startY + (liftedY - startY) * p;
            scale = 0.95 + (1.22 - 0.95) * p.clamp(0.0, 1.15);
          } else {
            final flightT =
                ((rawT - _liftPhaseEnd) / (1.0 - _liftPhaseEnd)).clamp(0.0, 1.0);
            final u = _flightCurve.transform(flightT);
            final inv = 1.0 - u;

            // B(u) = (1-u)^2 * P0 + 2(1-u)u * P1 + u^2 * P2
            x = (inv * inv * startX) +
                (2 * inv * u * ctrlX) +
                (u * u * endX);
            y = (inv * inv * liftedY) +
                (2 * inv * u * ctrlY) +
                (u * u * endY);

            // Smoothly taper from 1.22 down to 0.46 as it glides into the cart.
            final shrinkP = Curves.easeInOutCubic.transform(flightT);
            scale = 1.22 + (0.46 - 1.22) * shrinkP;
          }

          // Remain 100% opaque across almost the entire trajectory so the
          // product image is clearly visible, gently softening at landing.
          final double opacity = rawT < 0.86
              ? 1.0
              : (1.0 - 0.28 * ((rawT - 0.86) / 0.14)).clamp(0.72, 1.0);

          return Stack(
            children: [
              Positioned(
                left: x - _size / 2,
                top: y - _size / 2,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: Container(
          key: const ValueKey('fly_to_cart_overlay_item'),
          width: _size,
          height: _size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: StoreDetailPalette.dark.gold,
              width: 2.2,
            ),
            color: StoreDetailPalette.dark.bgCard,
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(229, 169, 60, 0.55),
                blurRadius: 24,
                spreadRadius: 1,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: resolvedUrl.isNotEmpty
                ? TransparentBgNetworkImage(
                    imageUrl: resolvedUrl,
                    mode: BackgroundRemovalMode.autoUniform,
                    width: _size - 8,
                    height: _size - 8,
                    fit: BoxFit.contain,
                    // Matches product card cache key (220) for instant Frame-0 display.
                    maxCacheDimension: 220,
                    placeholderBuilder: (_) => CachedNetworkImage(
                      imageUrl: resolvedUrl,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => _buildFallbackIcon(),
                      placeholder: (_, _) => _buildFallbackIcon(),
                    ),
                    fallbackBuilder: (_) => _buildFallbackIcon(),
                  )
                : _buildFallbackIcon(),
          ),
        ),
      ),
    );
  }
}
