import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared Hero tag connecting the Splash logo cleanly to the original Login logo.
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

  /// Returns whether a Splash-to-Login transition is pending without consuming.
  static bool get isPendingFromSplash => _pendingFromSplash;

  /// Reads and clears the Splash-to-Login transition marker.
  static bool consumeFromSplash() {
    final value = _pendingFromSplash;
    _pendingFromSplash = false;
    return value;
  }

  /// Resets pending state cleanly.
  static void reset() {
    _pendingFromSplash = false;
  }
}

/// Shared transition timing & fade builder for Splash -> Login Hero flights.
class OtlobSplashToLoginTransition {
  const OtlobSplashToLoginTransition._();

  static const Duration heroFlightDuration = Duration(milliseconds: 800);

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
      curve: const Interval(0.18, 0.90, curve: Curves.easeInOutCubic),
    );
    return FadeTransition(opacity: fade, child: child);
  }
}

/// Continuous Hero-wrapped logo widget preserving the original Splash logo and
/// original Login logo while smoothly morphing between them in flight.
class OtlobBrandHeroLogo extends StatelessWidget {
  final Widget child;
  final Object heroTag;

  const OtlobBrandHeroLogo({
    super.key,
    required this.child,
    this.heroTag = otlobBrandLogoHeroTag,
  });

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
        final fromChild = (fromHeroContext.widget as Hero).child;
        final toChild = (toHeroContext.widget as Hero).child;
        final curve =
            CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);

        return Material(
          type: MaterialType.transparency,
          child: AnimatedBuilder(
            animation: curve,
            builder: (context, _) {
              final t = curve.value;
              final fromOpacity = (1.0 - (t * 1.4).clamp(0.0, 1.0));
              final toOpacity = ((t - 0.15) * 1.35).clamp(0.0, 1.0);
              return Stack(
                alignment: Alignment.center,
                fit: StackFit.passthrough,
                children: [
                  if (fromOpacity > 0.01)
                    Opacity(
                      opacity: fromOpacity,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: fromChild,
                      ),
                    ),
                  if (toOpacity > 0.01)
                    Opacity(
                      opacity: toOpacity,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: toChild,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
      child: child,
    );
  }
}

/// Animates the existing Splash logo through a smooth ~4-second spinning
/// sequence and settles strictly upright (`0°`) before transitioning cleanly
/// via Hero into the Login screen's original logo position.
class OtlobSplashSpinLogo extends StatefulWidget {
  final Widget child;
  final Duration spinDuration;
  final double spinTurns;
  final Animation<double>? scaleAnimation;
  final VoidCallback? onInitialSpinCompleted;

  const OtlobSplashSpinLogo({
    super.key,
    required this.child,
    this.spinDuration = const Duration(milliseconds: 3900),
    this.spinTurns = 3.0,
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
      duration: widget.spinDuration,
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
        duration: widget.spinDuration,
        curve: Curves.easeInOutCubic,
      );
    } catch (_) {}
    if (!_initialSpinCompleter.isCompleted) {
      _initialSpinCompleter.complete();
    }
    if (!mounted) return;
    widget.onInitialSpinCompleted?.call();
  }

  /// Waits for BOTH [authAndGateFuture] and the ~4-second spin to finish, then
  /// completes any active spin cycle cleanly upright (`0°`) before Hero lift-off.
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
    final currentTurns = (_spinController.value * widget.spinTurns) % 1.0;
    _spinController.stop();
    if (currentTurns > 0.02 && currentTurns < 0.98) {
      final remainingMs = ((1.0 - currentTurns) * 550).round().clamp(120, 550);
      try {
        _spinController.value = currentTurns / widget.spinTurns;
        await _spinController.animateTo(
          1.0 / widget.spinTurns,
          duration: Duration(milliseconds: remainingMs),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    } else {
      _spinController.value = 1.0;
    }
    _settled = true;
  }

  /// Continues gently spinning if network gates exceed the 4-second spin window.
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
    Widget logo = OtlobBrandHeroLogo(child: widget.child);

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
          final angle =
              ((_spinController.value * widget.spinTurns) % 1.0) * 2 * math.pi;
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
