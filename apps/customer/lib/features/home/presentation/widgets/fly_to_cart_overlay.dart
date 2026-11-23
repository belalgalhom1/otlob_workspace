import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart' show ImageUtils;
import 'package:flutter/material.dart';

import 'store_details_tokens.dart';

/// Launches a 2-phase parabolic fly-to-cart image animation matching the TLOB
/// Store Details specification:
/// - 48x48 thumbnail (`borderRadius: 14`, `2px #E5A93C`, gold shadow)
/// - Phase 1 (Ascent, 0..260ms, `Cubic(0.22, 1, 0.36, 1)`):
///   lifts to `(midX, max(24, min(startY, endY) - 85))` at scale `1.14`
/// - Phase 2 (Descent, 250..590ms, `Cubic(0.45, 0, 0.85, 0.5)`):
///   drops to the Cart Bar target at scale `0.42` and opacity `0.65`
/// - At 600ms removes the overlay and invokes [onLanded].
class FlyToCartOverlay {
  FlyToCartOverlay._();

  static void launch({
    required BuildContext context,
    required Rect? sourceRect,
    required Rect? targetRect,
    required String? imageUrl,
    required VoidCallback onLanded,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (overlay == null ||
        disableAnimations ||
        sourceRect == null ||
        sourceRect.isEmpty) {
      onLanded();
      return;
    }

    final screenSize = MediaQuery.sizeOf(context);
    final effectiveTarget = (targetRect != null && !targetRect.isEmpty)
        ? targetRect
        : Rect.fromLTWH(
            14,
            screenSize.height - 58,
            math.max(120, screenSize.width - 28),
            44,
          );

    final startPoint = sourceRect.center;
    final endPoint = Offset(
      effectiveTarget.left + effectiveTarget.width * 0.25,
      effectiveTarget.center.dy,
    );

    late final OverlayEntry entry;
    var completed = false;

    void finish() {
      if (completed) return;
      completed = true;
      if (entry.mounted) {
        entry.remove();
      }
      onLanded();
    }

    entry = OverlayEntry(
      builder: (_) => _FlyToCartAnimationWidget(
        startPoint: startPoint,
        endPoint: endPoint,
        imageUrl: imageUrl,
        onComplete: finish,
      ),
    );

    overlay.insert(entry);
  }
}

class _FlyToCartAnimationWidget extends StatefulWidget {
  final Offset startPoint;
  final Offset endPoint;
  final String? imageUrl;
  final VoidCallback onComplete;

  const _FlyToCartAnimationWidget({
    required this.startPoint,
    required this.endPoint,
    required this.imageUrl,
    required this.onComplete,
  });

  @override
  State<_FlyToCartAnimationWidget> createState() =>
      _FlyToCartAnimationWidgetState();
}

class _FlyToCartAnimationWidgetState extends State<_FlyToCartAnimationWidget>
    with SingleTickerProviderStateMixin {
  static const double _size = 48.0;
  static const Cubic _ascentCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Cubic _descentCurve = Cubic(0.45, 0.0, 0.85, 0.5);
  static const double _ascentEndFraction = 260.0 / 600.0;
  static const double _descentStartFraction = 250.0 / 600.0;
  static const double _descentEndFraction = 590.0 / 600.0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addStatusListener((status) {
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

  @override
  Widget build(BuildContext context) {
    final start = widget.startPoint;
    final end = widget.endPoint;
    final midX = (start.dx + end.dx) / 2;
    final peakY = math.max(24.0, math.min(start.dy, end.dy) - 85.0);
    final peakPoint = Offset(midX, peakY);

    final normalizedUrl = widget.imageUrl?.trim() ?? '';
    final formattedUrl =
        normalizedUrl.isNotEmpty ? ImageUtils.formatImageUrl(normalizedUrl) : '';

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;

          final Offset pos;
          final double scale;
          final double opacity;

          if (t < _descentStartFraction) {
            final p1 = (t / _ascentEndFraction).clamp(0.0, 1.0);
            final curved = _ascentCurve.transform(p1);
            pos = Offset.lerp(start, peakPoint, curved)!;
            scale = lerpDouble(1.0, 1.14, curved)!;
            opacity = 1.0;
          } else {
            // Capture seamless handoff point from Phase 1 at 250ms
            final handoffCurved = _ascentCurve.transform(
              (_descentStartFraction / _ascentEndFraction).clamp(0.0, 1.0),
            );
            final handoffPos = Offset.lerp(start, peakPoint, handoffCurved)!;
            final handoffScale = lerpDouble(1.0, 1.14, handoffCurved)!;

            final p2 = ((t - _descentStartFraction) /
                    (_descentEndFraction - _descentStartFraction))
                .clamp(0.0, 1.0);
            final curved = _descentCurve.transform(p2);
            pos = Offset.lerp(handoffPos, end, curved)!;
            scale = lerpDouble(handoffScale, 0.42, curved)!;
            opacity = lerpDouble(1.0, 0.65, curved)!;
          }

          return Stack(
            children: [
              Positioned(
                left: pos.dx - _size / 2,
                top: pos.dy - _size / 2,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
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
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1815),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: StoreDetailsTokens.gold, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(229, 169, 60, 0.45),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: formattedUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: formattedUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const Center(
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      color: StoreDetailsTokens.gold,
                      size: 22,
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: StoreDetailsTokens.gold,
                    size: 22,
                  ),
                ),
        ),
      ),
    );
  }
}
