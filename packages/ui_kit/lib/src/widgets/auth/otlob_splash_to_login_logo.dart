import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared Hero tag connecting the Splash logo cleanly to the Login screen.
const String otlobBrandLogoHeroTag = 'otlob_brand_logo_hero';

/// Coordinates whether an upcoming navigation to the Login route originated
/// from a completed Splash spin so the Login screen waits for the Hero flight
/// before starting the welcome celebration.
class OtlobLoginEntranceCoordinator {
  OtlobLoginEntranceCoordinator._();

  static bool _pendingFromSplash = false;

  /// Marks that Splash is about to transition into Login.
  static void markFromSplash() {
    _pendingFromSplash = true;
  }

  /// Returns whether a Splash-to-Login transition was marked without consuming.
  static bool get isPendingFromSplash => _pendingFromSplash;

  /// Reads and clears the Splash-to-Login transition marker.
  static bool consumeFromSplash() {
    final value = _pendingFromSplash;
    _pendingFromSplash = false;
    return value;
  }

  /// Resets pending state cleanly (primarily for tests).
  static void reset() {
    _pendingFromSplash = false;
  }
}

/// Shared transition timing & fade builder for Splash -> Login Hero flights.
class OtlobSplashToLoginTransition {
  const OtlobSplashToLoginTransition._();

  static const Duration heroFlightDuration = Duration(milliseconds: 850);

  static Duration effectiveDuration(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : heroFlightDuration;
  }

  static Widget buildPageTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.18, 0.92, curve: Curves.easeInOutCubic),
    );
    return FadeTransition(opacity: fade, child: child);
  }
}

/// Continuous Hero-wrapped Otlob brand logo used at both ends of Splash -> Login.
class OtlobBrandHeroLogo extends StatelessWidget {
  final String assetPath;
  final double size;
  final double auraPadding;
  final Color? auraColor;
  final Color? borderColor;
  final bool showMedallion;
  final Object heroTag;

  const OtlobBrandHeroLogo({
    super.key,
    required this.assetPath,
    this.size = 130,
    this.auraPadding = 16,
    this.auraColor,
    this.borderColor,
    this.showMedallion = true,
    this.heroTag = otlobBrandLogoHeroTag,
  });

  Widget _buildLogoVisual(
    BuildContext context, {
    required double targetSize,
    required double padding,
    Color? resolvedAuraColor,
    Color? resolvedBorderColor,
  }) {
    final logoImage = Image.asset(
      assetPath,
      width: targetSize,
      height: targetSize,
      fit: BoxFit.contain,
    );

    if (!showMedallion) {
      return SizedBox(
        width: targetSize,
        height: targetSize,
        child: logoImage,
      );
    }

    final outerSize = targetSize + padding * 2;
    return Container(
      width: outerSize,
      height: outerSize,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: resolvedAuraColor ?? Colors.white.withValues(alpha: 0.14),
        border: resolvedBorderColor != null
            ? Border.all(color: resolvedBorderColor, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(child: logoImage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      createRectTween: (begin, end) =>
          MaterialRectArcTween(begin: begin, end: end),
      flightShuttleBuilder: (
        flightContext,
        animation,
        flightDirection,
        fromHeroContext,
        toHeroContext,
      ) {
        final fromHero = fromHeroContext.widget as Hero?;
        final toHero = toHeroContext.widget as Hero?;
        final fromLogo = fromHero?.child;
        final toLogo = toHero?.child;

        final fromBox = fromHeroContext.findRenderObject() as RenderBox?;
        final toBox = toHeroContext.findRenderObject() as RenderBox?;
        final beginOuter = fromBox?.size.width ?? (size + auraPadding * 2);
        final endOuter = toBox?.size.width ?? (size + auraPadding * 2);
        final beginSize = fromLogo is Container ? (beginOuter - auraPadding * 2) : size;
        final endSize = toLogo is Container ? (endOuter - auraPadding * 2) : size;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = Curves.easeInOutCubic.transform(animation.value);
            final currentOuter = beginOuter + (endOuter - beginOuter) * t;
            final currentLogo = (beginSize + (endSize - beginSize) * t)
                .clamp(24.0, 220.0);
            final currentPad =
                ((currentOuter - currentLogo) / 2).clamp(0.0, 40.0);
            return Material(
              type: MaterialType.transparency,
              child: Center(
                child: _buildLogoVisual(
                  flightContext,
                  targetSize: currentLogo,
                  padding: currentPad,
                  resolvedAuraColor: auraColor,
                  resolvedBorderColor: borderColor,
                ),
              ),
            );
          },
        );
      },
      child: _buildLogoVisual(
        context,
        targetSize: size,
        padding: auraPadding,
        resolvedAuraColor: auraColor,
        resolvedBorderColor: borderColor,
      ),
    );
  }
}

/// Controller/widget helper that animates the Splash logo spin and resolves
/// strictly upright (`turns` integer) before triggering the Hero transition.
class OtlobSplashSpinLogo extends StatefulWidget {
  final String assetPath;
  final double size;
  final double auraPadding;
  final Color? auraColor;
  final Color? borderColor;
  final bool showMedallion;
  final Animation<double>? scaleAnimation;
  final VoidCallback? onInitialSpinCompleted;

  const OtlobSplashSpinLogo({
    super.key,
    required this.assetPath,
    this.size = 130,
    this.auraPadding = 20,
    this.auraColor,
    this.borderColor,
    this.showMedallion = true,
    this.scaleAnimation,
    this.onInitialSpinCompleted,
  });

  @override
  State<OtlobSplashSpinLogo> createState() => OtlobSplashSpinLogoState();
}

class OtlobSplashSpinLogoState extends State<OtlobSplashSpinLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  final Completer<void> _initialSpinCompleter = Completer<void>();
  bool _settling = false;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _spinController.value = 1.0;
        if (!_initialSpinCompleter.isCompleted) {
          _initialSpinCompleter.complete();
        }
        widget.onInitialSpinCompleted?.call();
        return;
      }
      _runInitialSpin();
    });
  }

  Future<void> _runInitialSpin() async {
    try {
      await _spinController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 1050),
        curve: Curves.easeInOutCubic,
      );
    } catch (_) {}
    if (!_initialSpinCompleter.isCompleted) {
      _initialSpinCompleter.complete();
    }
    if (!mounted) return;
    widget.onInitialSpinCompleted?.call();
  }

  /// Continues gently spinning until [authAndGateFuture] completes, then
  /// finishes the current rotation cleanly upright (`0°`) before returning so
  /// the Hero flight starts from a crisp upright logo.
  Future<void> waitForSpinAndSettle(Future<void> authAndGateFuture) async {
    if (!mounted) return;
    _settling = true;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion) {
      await authAndGateFuture;
      _spinController.stop();
      _spinController.value = 1.0;
      _settled = true;
      return;
    }

    if (!_initialSpinCompleter.isCompleted) {
      await Future.wait([authAndGateFuture, _initialSpinCompleter.future]);
    } else {
      await authAndGateFuture;
    }

    if (!mounted || _settled) return;
    // Stop any repeat ticker and complete the current cycle upright (`1.0`).
    final progress = _spinController.value % 1.0;
    _spinController.stop();
    if (progress > 0.02 && progress < 0.98) {
      final remainingMs = ((1.0 - progress) * 650).round().clamp(120, 650);
      try {
        _spinController.value = progress;
        await _spinController.animateTo(
          1.0,
          duration: Duration(milliseconds: remainingMs),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    } else {
      _spinController.value = 1.0;
    }
    _settled = true;
  }

  /// Starts a smooth subtle continuous spin while long network gates are
  /// still pending after the first rotation.
  void continueSpinningWhileWaiting() {
    if (!mounted || _settled || _settling) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (!_spinController.isAnimating) {
      _spinController.repeat();
    }
  }

  @override
  void dispose() {
    if (!_initialSpinCompleter.isCompleted) {
      _initialSpinCompleter.complete();
    }
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget logo = OtlobBrandHeroLogo(
      assetPath: widget.assetPath,
      size: widget.size,
      auraPadding: widget.auraPadding,
      auraColor: widget.auraColor,
      borderColor: widget.borderColor,
      showMedallion: widget.showMedallion,
    );

    if (widget.scaleAnimation != null) {
      logo = ScaleTransition(
        scale: widget.scaleAnimation!,
        child: logo,
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _spinController,
        builder: (context, child) {
          final angle = (_spinController.value % 1.0) * 2 * math.pi;
          return Transform.rotate(
            angle: angle,
            child: child,
          );
        },
        child: logo,
      ),
    );
  }
}
