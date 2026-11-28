import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Bridges Android 12+ (API 31+) `ScrollCaptureCallback` requests to Flutter's
/// active vertical [Scrollable], enabling native system scrolling screenshots
/// ("Capture more" / long screenshots) across all screens.
class AndroidScrollCaptureBridge {
  AndroidScrollCaptureBridge._();

  static const String channelName = 'com.otlobegy/scroll_capture';
  static const MethodChannel _channel = MethodChannel(channelName);

  static bool _initialized = false;
  static ScrollableState? _activeScrollable;
  static double? _initialOffsetLogical;
  static double _activeDpr = 1.0;

  /// Registers the platform channel handler once on Android.
  /// Safe to call multiple times and safe on non-Android platforms (no-op).
  static void ensureInitialized({bool forceForTesting = false}) {
    if (_initialized && !forceForTesting) return;
    if (!forceForTesting &&
        (kIsWeb || defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }
    _initialized = true;
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Resets internal capture state (useful in widget tests).
  @visibleForTesting
  static void resetForTesting() {
    _activeScrollable = null;
    _initialOffsetLogical = null;
    _activeDpr = 1.0;
    _initialized = false;
  }

  @visibleForTesting
  static Future<dynamic> handleMethodCallForTesting(MethodCall call) =>
      _handleMethodCall(call);

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getScrollMetrics':
        return _getScrollMetrics();
      case 'startCapture':
        return _startCapture();
      case 'scrollToOffset':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final offsetPx = (args?['offsetPx'] as num?)?.toDouble() ?? 0.0;
        return _scrollToOffset(offsetPx);
      case 'endCapture':
        return _endCapture();
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Unknown scroll capture method: ${call.method}',
        );
    }
  }

  static Map<String, dynamic> _getScrollMetrics() {
    final candidate = _findPrimaryVerticalScrollable();
    if (candidate == null) {
      return const {'scrollable': false};
    }
    return candidate.toMetricsMap();
  }

  static Map<String, dynamic> _startCapture() {
    final candidate = _findPrimaryVerticalScrollable();
    if (candidate == null) {
      _activeScrollable = null;
      _initialOffsetLogical = null;
      return const {'scrollable': false};
    }
    _activeScrollable = candidate.scrollable;
    _initialOffsetLogical = candidate.scrollable.position.pixels;
    _activeDpr = candidate.devicePixelRatio;
    return candidate.toMetricsMap();
  }

  static Future<Map<String, dynamic>> _scrollToOffset(double offsetPx) async {
    final scrollable = _activeScrollable;
    if (scrollable == null || !scrollable.mounted) {
      return const {'ok': false};
    }
    final position = scrollable.position;
    if (!position.hasPixels || !position.hasContentDimensions) {
      return const {'ok': false};
    }

    final dpr = _activeDpr > 0 ? _activeDpr : 1.0;
    final targetLogical = (offsetPx / dpr).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((position.pixels - targetLogical).abs() > 0.25) {
      position.jumpTo(targetLogical);
    }

    await _waitForRenderedFrame();

    // After jumping in a lazy SliverList, re-check extents in case layout grew.
    final clampedActual = position.pixels;
    return {
      'ok': true,
      'actualOffsetPx': (clampedActual * dpr).round(),
      'minExtentPx': (position.minScrollExtent * dpr).round(),
      'maxExtentPx': (position.maxScrollExtent * dpr).round(),
    };
  }

  static Future<bool> _endCapture() async {
    final scrollable = _activeScrollable;
    final initial = _initialOffsetLogical;
    _activeScrollable = null;
    _initialOffsetLogical = null;

    if (scrollable != null && scrollable.mounted && initial != null) {
      final position = scrollable.position;
      if (position.hasPixels && position.hasContentDimensions) {
        final target = initial.clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        if ((position.pixels - target).abs() > 0.25) {
          position.jumpTo(target);
          await _waitForRenderedFrame();
        }
      }
    }
    return true;
  }

  static Future<void> _waitForRenderedFrame() async {
    final scheduler = SchedulerBinding.instance;
    scheduler.scheduleFrame();
    await scheduler.endOfFrame;
    // Wait one additional frame so the TextureView / Surface buffer swap settles.
    scheduler.scheduleFrame();
    await scheduler.endOfFrame;
  }

  static _ScrollCandidate? _findPrimaryVerticalScrollable() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;

    final views = WidgetsBinding.instance.platformDispatcher.views;
    final dpr = views.isNotEmpty ? views.first.devicePixelRatio : 1.0;
    final candidates = <_ScrollCandidate>[];

    void visit(Element element) {
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) {
        return;
      }
      if (widget is Visibility && !widget.visible) {
        return;
      }

      if (element is StatefulElement && element.state is ScrollableState) {
        final scrollable = element.state as ScrollableState;
        final route = ModalRoute.of(element);
        final isOnCurrentRoute = route == null || route.isCurrent;
        if (isOnCurrentRoute && _isVerticallyScrollable(scrollable)) {
          final candidate = _buildCandidate(scrollable, dpr);
          if (candidate != null) {
            candidates.add(candidate);
          }
        }
      }

      element.visitChildren(visit);
    }

    visit(root);

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.area.compareTo(a.area));
    return candidates.first;
  }

  static bool _isVerticallyScrollable(ScrollableState scrollable) {
    if (!scrollable.mounted) return false;
    final axisDirection = scrollable.axisDirection;
    if (axisDirection != AxisDirection.down &&
        axisDirection != AxisDirection.up) {
      return false;
    }
    final position = scrollable.position;
    if (!position.hasPixels ||
        !position.hasContentDimensions ||
        !position.hasViewportDimension) {
      return false;
    }
    return position.maxScrollExtent - position.minScrollExtent > 1.0;
  }

  static _ScrollCandidate? _buildCandidate(
    ScrollableState scrollable,
    double dpr,
  ) {
    final renderObject = scrollable.context.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }

    final size = renderObject.size;
    if (size.width < 40 || size.height < 80) return null;

    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rawRect = topLeft & size;

    // Exclude pinned top slivers (such as SliverAppBar(pinned: true)) from the
    // tiled capture region so pinned headers are not duplicated across tiles.
    final pinnedTopInset = _findPinnedTopSliverExtent(renderObject);
    final maxAllowedInset = math.max(0.0, rawRect.height - 120.0);
    final effectiveInset = pinnedTopInset.clamp(0.0, maxAllowedInset);
    final effectiveRect = Rect.fromLTRB(
      rawRect.left,
      rawRect.top + effectiveInset,
      rawRect.right,
      rawRect.bottom,
    );

    if (effectiveRect.height < 80) return null;

    return _ScrollCandidate(
      scrollable: scrollable,
      viewportRectLogical: effectiveRect,
      devicePixelRatio: dpr,
    );
  }

  static double _findPinnedTopSliverExtent(RenderObject root) {
    double pinnedHeight = 0.0;

    void walk(RenderObject node) {
      if (node is RenderViewportBase) {
        RenderSliver? child = node.firstChild;
        while (child != null) {
          if (child is RenderSliverPinnedPersistentHeader) {
            final extent = child.geometry?.paintExtent ?? 0.0;
            if (extent > 0) {
              pinnedHeight += extent;
            }
          }
          child = node.childAfter(child);
        }
        return;
      }
      node.visitChildren(walk);
    }

    walk(root);
    return pinnedHeight;
  }
}

class _ScrollCandidate {
  final ScrollableState scrollable;
  final Rect viewportRectLogical;
  final double devicePixelRatio;

  const _ScrollCandidate({
    required this.scrollable,
    required this.viewportRectLogical,
    required this.devicePixelRatio,
  });

  double get area => viewportRectLogical.width * viewportRectLogical.height;

  Map<String, dynamic> toMetricsMap() {
    final pos = scrollable.position;
    final dpr = devicePixelRatio;
    return {
      'scrollable': true,
      'offsetPx': (pos.pixels * dpr).round(),
      'minExtentPx': (pos.minScrollExtent * dpr).round(),
      'maxExtentPx': (pos.maxScrollExtent * dpr).round(),
      'viewportLeft': (viewportRectLogical.left * dpr).round(),
      'viewportTop': (viewportRectLogical.top * dpr).round(),
      'viewportRight': (viewportRectLogical.right * dpr).round(),
      'viewportBottom': (viewportRectLogical.bottom * dpr).round(),
      'devicePixelRatio': dpr,
    };
  }
}
