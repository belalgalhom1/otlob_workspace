import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'otlob_splash_to_login_logo.dart';

class _CelebrationColors {
  const _CelebrationColors._();

  static const purpleDeep = Color(0xFF280E46);
  static const purpleRoyal = Color(0xFF471B78);
  static const purpleAccent = Color(0xFF7E3FF2);
  static const goldBright = Color(0xFFFFD864);
  static const goldPrimary = Color(0xFFFBBB2B);
  static const goldDeep = Color(0xFFB77912);
  static const redVelvetBright = Color(0xFFD92649);
  static const redVelvet = Color(0xFFA81533);
  static const redVelvetDeep = Color(0xFF68081B);
}

class _ConfettiSpec {
  final double xFraction;
  final double start;
  final double span;
  final double startYFraction;
  final double swayAmplitude;
  final double swayCycles;
  final double swayPhase;
  final double spinSpeed;
  final double width;
  final double height;
  final bool isCircle;
  final double baseAlpha;
  final Color color;

  const _ConfettiSpec({
    required this.xFraction,
    required this.start,
    required this.span,
    this.startYFraction = 0.0,
    required this.swayAmplitude,
    required this.swayCycles,
    required this.swayPhase,
    required this.spinSpeed,
    required this.width,
    required this.height,
    required this.isCircle,
    this.baseAlpha = 0.72,
    required this.color,
  });
}

class _SparkleSpec {
  final double xFraction;
  final double yFraction;
  final double radius;
  final double phase;
  final double twinkleCycles;
  final double maxAlpha;

  const _SparkleSpec({
    required this.xFraction,
    required this.yFraction,
    required this.radius,
    required this.phase,
    required this.twinkleCycles,
    this.maxAlpha = 0.78,
  });
}

/// Non-intrusive celebratory overlay rendered INSIDE the actual original
/// LoginScreen without altering its background, layout, logo position,
/// fields, buttons, or touch responsiveness.
///
/// Only adds the 4 approved celebration elements strictly after the Hero logo
/// transition completes:
/// 1. Compact purple & gold `WELCOME TO OTLOB` sign at the top.
/// 2. Two supporting red velvet ropes with gold connectors from top corners.
/// 3. Lightweight falling gold/purple/red confetti particles.
/// 4. Subtle twinkling golden sparkles around the welcome sign.
class OtlobLoginWelcomeOverlay extends StatefulWidget {
  final Widget child;
  final double signTopOffset;
  final bool? forceAnimateCelebration;
  final String? welcomeText;

  const OtlobLoginWelcomeOverlay({
    super.key,
    required this.child,
    this.signTopOffset = 6.0,
    this.forceAnimateCelebration,
    this.welcomeText,
  });

  /// Minimum top padding inside [child]'s [SafeArea] so the brand logo and
  /// login form start cleanly below the welcome banner without overlapping it,
  /// even under larger accessibility text scaling.
  static double recommendedTopClearance(
    BuildContext context, {
    double signTopOffset = 6.0,
    double gap = 16.0,
  }) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);
    // _CompactWelcomeSign height at 1.0x: vertical padding (12) + border (3.2) + ~20px line height ≈ 38px.
    const double baseSignHeight = 38.0;
    return signTopOffset + (baseSignHeight * textScale) + gap;
  }

  @override
  State<OtlobLoginWelcomeOverlay> createState() =>
      OtlobLoginWelcomeOverlayState();
}

class OtlobLoginWelcomeOverlayState extends State<OtlobLoginWelcomeOverlay>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entranceController;
  late final AnimationController _effectsController;
  Animation<double>? _routeAnimation;
  bool _routeHooked = false;
  bool _started = false;
  bool _effectsStarted = false;

  /// Exposed for unit/widget tests to verify celebration sequencing cleanly.
  AnimationController get entranceController => _entranceController;

  /// Exposed for unit/widget tests to verify particle lifecycle cleanly.
  AnimationController get effectsController => _effectsController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_maybeTriggerEffects);

    _effectsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );
  }

  void _maybeTriggerEffects() {
    if (!_effectsStarted && _entranceController.value >= 0.72 && mounted) {
      _effectsStarted = true;
      _effectsController.forward(from: 0.0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _entranceController.stop(canceled: false);
      _effectsController.stop(canceled: false);
    } else if (state == AppLifecycleState.resumed &&
        _started &&
        !MediaQuery.disableAnimationsOf(context)) {
      if (_entranceController.value < 1.0 &&
          !_entranceController.isAnimating) {
        _entranceController.forward();
      }
      if (_effectsStarted &&
          _effectsController.value < 1.0 &&
          !_effectsController.isAnimating) {
        _effectsController.forward();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeHooked) return;
    _routeHooked = true;

    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final shouldAnimate = widget.forceAnimateCelebration ??
        OtlobLoginEntranceCoordinator.consumeFromSplash();

    if (reducedMotion || !shouldAnimate) {
      _started = true;
      _effectsStarted = true;
      _entranceController.value = 1.0;
      _effectsController.value = 1.0;
      return;
    }

    final routeAnim = ModalRoute.of(context)?.animation;
    if (routeAnim != null && routeAnim.status != AnimationStatus.completed) {
      // Strictly wait until the Splash-to-Login Hero logo finishes settling in
      // its original login position before launching the welcome celebration.
      _routeAnimation = routeAnim;
      routeAnim.addStatusListener(_onRouteAnimationStatus);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCelebration();
      });
    }
  }

  void _onRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
      _startCelebration();
    }
  }

  void _startCelebration() {
    if (!mounted || _started) return;
    _started = true;
    _entranceController.forward(from: 0.0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _entranceController.removeListener(_maybeTriggerEffects);
    _entranceController.dispose();
    _effectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Stack(
      children: [
        // Full-screen background layer: confetti & golden sparkles fall and
        // twinkle across the entire viewport BEHIND interactive login controls.
        if (!reducedMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _FullScreenCelebrationPainter(
                    animation: _effectsController,
                  ),
                ),
              ),
            ),
          ),

        // Original LoginScreen content stays completely untouched, crisp,
        // and immediately interactive above the decorative background layer.
        widget.child,

        // Non-blocking top layer for only the compact WELCOME TO OTLOB sign
        // and its two supporting red velvet ropes.
        Positioned.fill(
          child: IgnorePointer(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final signWidth = (maxWidth * 0.62).clamp(182.0, 260.0);
                  final signLeft = (maxWidth - signWidth) / 2;
                  final signTop = widget.signTopOffset;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, _) {
                              final t = _entranceController.value;
                              final ropeProgress = const Interval(
                                0.30,
                                1.0,
                                curve: Curves.easeOutCubic,
                              ).transform(t);
                              return CustomPaint(
                                painter: _VelvetRopesPainter(
                                  progress: ropeProgress,
                                  signLeft: signLeft,
                                  signWidth: signWidth,
                                  signTop: signTop,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: signTop,
                        left: signLeft,
                        width: signWidth,
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, signChild) {
                              final signProgress = const Interval(
                                0.0,
                                0.62,
                                curve: Curves.easeOutBack,
                              ).transform(_entranceController.value);
                              final opacity =
                                  signProgress.clamp(0.0, 1.0);
                              final dy =
                                  (1.0 - signProgress.clamp(0.0, 1.2)) * -18.0;
                              return Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: Offset(0, dy),
                                  child: signChild,
                                ),
                              );
                            },
                            child: _CompactWelcomeSign(
                              welcomeText: widget.welcomeText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactWelcomeSign extends StatelessWidget {
  final String? welcomeText;

  const _CompactWelcomeSign({this.welcomeText});

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl ||
        Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final label =
        welcomeText ?? (isArabic ? 'مرحباً بك في أطلب' : 'WELCOME TO OTLOB');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _CelebrationColors.purpleRoyal,
            _CelebrationColors.purpleDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _CelebrationColors.goldBright,
          width: 1.6,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          textDirection:
              welcomeText == null && isArabic ? TextDirection.rtl : null,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isArabic ? 14.0 : 13.5,
            height: 1.25,
            fontWeight: FontWeight.w900,
            letterSpacing: isArabic ? 0.0 : 1.5,
            color: _CelebrationColors.goldBright,
          ),
        ),
      ),
    );
  }
}

class _VelvetRopesPainter extends CustomPainter {
  final double progress;
  final double signLeft;
  final double signWidth;
  final double signTop;

  _VelvetRopesPainter({
    required this.progress,
    required this.signLeft,
    required this.signWidth,
    required this.signTop,
  });

  final Paint _basePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _highlightPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _goldPaint = Paint();

  void _drawRope(
    Canvas canvas,
    Offset start,
    Offset end,
    double t, {
    required bool isLeft,
  }) {
    final currentEnd = Offset.lerp(start, end, t)!;
    final ctrlX = (start.dx + currentEnd.dx) * 0.5 + (isLeft ? -5.0 : 5.0);
    final ctrlY = (start.dy + currentEnd.dy) * 0.5 + 6.0;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrlX, ctrlY, currentEnd.dx, currentEnd.dy);

    _basePaint
      ..color = _CelebrationColors.redVelvetDeep.withValues(alpha: t)
      ..strokeWidth = 5.4;
    canvas.drawPath(path, _basePaint);

    _corePaint
      ..color = _CelebrationColors.redVelvet.withValues(alpha: t)
      ..strokeWidth = 3.6;
    canvas.drawPath(path, _corePaint);

    _highlightPaint
      ..color = _CelebrationColors.redVelvetBright.withValues(alpha: 0.65 * t)
      ..strokeWidth = 1.2;
    canvas.drawPath(path, _highlightPaint);

    // Top ceiling gold connector + sign gold attachment clasp
    _drawGoldConnector(canvas, start + const Offset(0, 2), 3.6, t);
    if (t > 0.35) {
      final claspAlpha = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
      _drawGoldConnector(canvas, currentEnd, 4.4, claspAlpha);
    }
  }

  void _drawGoldConnector(
    Canvas canvas,
    Offset center,
    double radius,
    double alpha,
  ) {
    _goldPaint.color = _CelebrationColors.goldDeep.withValues(alpha: alpha);
    canvas.drawCircle(center, radius, _goldPaint);
    _goldPaint.color = _CelebrationColors.goldBright.withValues(alpha: alpha);
    canvas.drawCircle(center, radius * 0.72, _goldPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.01) return;

    final leftAnchor = Offset((signLeft - 18).clamp(12.0, signLeft), 0);
    final leftAttach = Offset(signLeft + 10, signTop + 5);

    final rightAnchor = Offset(
      (signLeft + signWidth + 18).clamp(signLeft + signWidth, size.width - 12),
      0,
    );
    final rightAttach = Offset(signLeft + signWidth - 10, signTop + 5);

    _drawRope(canvas, leftAnchor, leftAttach, t, isLeft: true);
    _drawRope(canvas, rightAnchor, rightAttach, t, isLeft: false);
  }

  @override
  bool shouldRepaint(_VelvetRopesPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.signLeft != signLeft ||
      oldDelegate.signWidth != signWidth ||
      oldDelegate.signTop != signTop;
}

class _FullScreenCelebrationPainter extends CustomPainter {
  final Animation<double> animation;

  _FullScreenCelebrationPainter({required this.animation})
      : super(repaint: animation);

  final Paint _paint = Paint();
  final Path _sparklePath = Path();

  static const _particles = <_ConfettiSpec>[
    // Early distributed particles so upper, middle, and form zones sparkle/drift immediately.
    _ConfettiSpec(xFraction: 0.09, start: 0.00, span: 0.44, startYFraction: 0.00, swayAmplitude: 11, swayCycles: 2.6, swayPhase: 0.4, spinSpeed: 2.2, width: 6.5, height: 3.5, isCircle: false, baseAlpha: 0.62, color: _CelebrationColors.goldBright),
    _ConfettiSpec(xFraction: 0.22, start: 0.00, span: 0.40, startYFraction: 0.14, swayAmplitude: 14, swayCycles: 2.3, swayPhase: 1.5, spinSpeed: 1.9, width: 4.8, height: 4.8, isCircle: true, baseAlpha: 0.56, color: _CelebrationColors.purpleAccent),
    _ConfettiSpec(xFraction: 0.37, start: 0.02, span: 0.46, startYFraction: 0.00, swayAmplitude: 10, swayCycles: 3.1, swayPhase: 2.2, spinSpeed: 2.8, width: 7.0, height: 3.5, isCircle: false, baseAlpha: 0.50, color: _CelebrationColors.redVelvetBright),
    _ConfettiSpec(xFraction: 0.53, start: 0.00, span: 0.42, startYFraction: 0.26, swayAmplitude: 12, swayCycles: 2.5, swayPhase: 0.9, spinSpeed: 2.4, width: 6.0, height: 3.5, isCircle: false, baseAlpha: 0.62, color: _CelebrationColors.goldPrimary),
    _ConfettiSpec(xFraction: 0.68, start: 0.01, span: 0.45, startYFraction: 0.00, swayAmplitude: 15, swayCycles: 2.8, swayPhase: 2.7, spinSpeed: 2.1, width: 4.5, height: 4.5, isCircle: true, baseAlpha: 0.56, color: _CelebrationColors.purpleRoyal),
    _ConfettiSpec(xFraction: 0.84, start: 0.00, span: 0.41, startYFraction: 0.20, swayAmplitude: 11, swayCycles: 2.4, swayPhase: 1.1, spinSpeed: 2.6, width: 6.5, height: 3.5, isCircle: false, baseAlpha: 0.62, color: _CelebrationColors.goldBright),
    _ConfettiSpec(xFraction: 0.15, start: 0.00, span: 0.38, startYFraction: 0.42, swayAmplitude: 13, swayCycles: 2.2, swayPhase: 3.0, spinSpeed: 2.0, width: 6.0, height: 3.2, isCircle: false, baseAlpha: 0.52, color: _CelebrationColors.redVelvetBright),
    _ConfettiSpec(xFraction: 0.77, start: 0.02, span: 0.40, startYFraction: 0.46, swayAmplitude: 10, swayCycles: 2.7, swayPhase: 0.6, spinSpeed: 2.5, width: 5.0, height: 5.0, isCircle: true, baseAlpha: 0.60, color: _CelebrationColors.goldPrimary),

    // Second wave: steady top-to-bottom drift across entire screen width & height.
    _ConfettiSpec(xFraction: 0.06, start: 0.16, span: 0.48, swayAmplitude: 12, swayCycles: 3.0, swayPhase: 1.8, spinSpeed: 2.7, width: 6.0, height: 3.5, isCircle: false, baseAlpha: 0.58, color: _CelebrationColors.purpleAccent),
    _ConfettiSpec(xFraction: 0.19, start: 0.20, span: 0.50, swayAmplitude: 15, swayCycles: 2.8, swayPhase: 0.3, spinSpeed: 2.2, width: 7.2, height: 3.8, isCircle: false, baseAlpha: 0.64, color: _CelebrationColors.goldBright),
    _ConfettiSpec(xFraction: 0.31, start: 0.14, span: 0.46, swayAmplitude: 9, swayCycles: 3.2, swayPhase: 2.4, spinSpeed: 2.9, width: 4.5, height: 4.5, isCircle: true, baseAlpha: 0.52, color: _CelebrationColors.redVelvetBright),
    _ConfettiSpec(xFraction: 0.45, start: 0.24, span: 0.48, swayAmplitude: 14, swayCycles: 2.9, swayPhase: 1.2, spinSpeed: 2.4, width: 6.5, height: 3.5, isCircle: false, baseAlpha: 0.60, color: _CelebrationColors.goldPrimary),
    _ConfettiSpec(xFraction: 0.59, start: 0.18, span: 0.52, swayAmplitude: 11, swayCycles: 3.3, swayPhase: 2.9, spinSpeed: 2.1, width: 5.2, height: 5.2, isCircle: false, baseAlpha: 0.56, color: _CelebrationColors.purpleRoyal),
    _ConfettiSpec(xFraction: 0.72, start: 0.22, span: 0.46, swayAmplitude: 16, swayCycles: 2.7, swayPhase: 0.7, spinSpeed: 2.6, width: 6.5, height: 3.5, isCircle: false, baseAlpha: 0.64, color: _CelebrationColors.goldBright),
    _ConfettiSpec(xFraction: 0.87, start: 0.15, span: 0.50, swayAmplitude: 10, swayCycles: 3.0, swayPhase: 1.9, spinSpeed: 2.3, width: 4.6, height: 4.6, isCircle: true, baseAlpha: 0.50, color: _CelebrationColors.redVelvetBright),
    _ConfettiSpec(xFraction: 0.94, start: 0.26, span: 0.46, swayAmplitude: 12, swayCycles: 2.6, swayPhase: 0.5, spinSpeed: 2.8, width: 6.0, height: 3.5, isCircle: false, baseAlpha: 0.58, color: _CelebrationColors.purpleAccent),

    // Third overlapping wave: continues ongoing fall smoothly down to the bottom edge.
    _ConfettiSpec(xFraction: 0.12, start: 0.38, span: 0.48, swayAmplitude: 13, swayCycles: 3.1, swayPhase: 2.1, spinSpeed: 2.5, width: 6.8, height: 3.6, isCircle: false, baseAlpha: 0.62, color: _CelebrationColors.goldPrimary),
    _ConfettiSpec(xFraction: 0.26, start: 0.44, span: 0.46, swayAmplitude: 11, swayCycles: 2.9, swayPhase: 0.8, spinSpeed: 2.0, width: 4.8, height: 4.8, isCircle: true, baseAlpha: 0.56, color: _CelebrationColors.purpleAccent),
    _ConfettiSpec(xFraction: 0.41, start: 0.36, span: 0.50, swayAmplitude: 15, swayCycles: 3.4, swayPhase: 1.6, spinSpeed: 2.9, width: 6.2, height: 3.4, isCircle: false, baseAlpha: 0.64, color: _CelebrationColors.goldBright),
    _ConfettiSpec(xFraction: 0.56, start: 0.48, span: 0.45, swayAmplitude: 10, swayCycles: 2.8, swayPhase: 2.5, spinSpeed: 2.3, width: 6.0, height: 3.4, isCircle: false, baseAlpha: 0.50, color: _CelebrationColors.redVelvetBright),
    _ConfettiSpec(xFraction: 0.69, start: 0.40, span: 0.49, swayAmplitude: 14, swayCycles: 3.0, swayPhase: 0.2, spinSpeed: 2.6, width: 5.0, height: 5.0, isCircle: false, baseAlpha: 0.56, color: _CelebrationColors.purpleRoyal),
    _ConfettiSpec(xFraction: 0.81, start: 0.46, span: 0.46, swayAmplitude: 12, swayCycles: 3.2, swayPhase: 1.4, spinSpeed: 2.2, width: 6.8, height: 3.6, isCircle: false, baseAlpha: 0.62, color: _CelebrationColors.goldPrimary),
    _ConfettiSpec(xFraction: 0.91, start: 0.42, span: 0.48, swayAmplitude: 9, swayCycles: 2.7, swayPhase: 2.8, spinSpeed: 2.4, width: 4.5, height: 4.5, isCircle: true, baseAlpha: 0.64, color: _CelebrationColors.goldBright),
    _ConfettiSpec(xFraction: 0.34, start: 0.54, span: 0.44, swayAmplitude: 12, swayCycles: 2.9, swayPhase: 1.0, spinSpeed: 2.7, width: 6.2, height: 3.4, isCircle: false, baseAlpha: 0.58, color: _CelebrationColors.purpleAccent),
    _ConfettiSpec(xFraction: 0.64, start: 0.52, span: 0.46, swayAmplitude: 13, swayCycles: 3.0, swayPhase: 2.3, spinSpeed: 2.1, width: 6.5, height: 3.5, isCircle: false, baseAlpha: 0.50, color: _CelebrationColors.redVelvetBright),
    _ConfettiSpec(xFraction: 0.49, start: 0.56, span: 0.42, swayAmplitude: 11, swayCycles: 2.6, swayPhase: 0.5, spinSpeed: 2.5, width: 6.0, height: 3.4, isCircle: false, baseAlpha: 0.62, color: _CelebrationColors.goldBright),
  ];

  // Golden sparkles distributed evenly across top welcome zone, logo area,
  // login form controls, and lower footer area.
  static const _sparkles = <_SparkleSpec>[
    _SparkleSpec(xFraction: 0.10, yFraction: 0.06, radius: 5.4, phase: 0.0, twinkleCycles: 5.2, maxAlpha: 0.80),
    _SparkleSpec(xFraction: 0.89, yFraction: 0.07, radius: 5.2, phase: 1.1, twinkleCycles: 4.8, maxAlpha: 0.80),
    _SparkleSpec(xFraction: 0.27, yFraction: 0.12, radius: 4.0, phase: 2.3, twinkleCycles: 6.0, maxAlpha: 0.72),
    _SparkleSpec(xFraction: 0.73, yFraction: 0.13, radius: 4.2, phase: 0.7, twinkleCycles: 5.6, maxAlpha: 0.72),
    _SparkleSpec(xFraction: 0.07, yFraction: 0.22, radius: 4.8, phase: 1.8, twinkleCycles: 4.6, maxAlpha: 0.74),
    _SparkleSpec(xFraction: 0.92, yFraction: 0.24, radius: 5.0, phase: 2.9, twinkleCycles: 5.4, maxAlpha: 0.76),
    _SparkleSpec(xFraction: 0.33, yFraction: 0.28, radius: 3.8, phase: 0.4, twinkleCycles: 6.4, maxAlpha: 0.66),
    _SparkleSpec(xFraction: 0.67, yFraction: 0.29, radius: 3.8, phase: 2.1, twinkleCycles: 5.8, maxAlpha: 0.66),
    _SparkleSpec(xFraction: 0.06, yFraction: 0.40, radius: 5.2, phase: 1.4, twinkleCycles: 5.0, maxAlpha: 0.76),
    _SparkleSpec(xFraction: 0.93, yFraction: 0.42, radius: 4.8, phase: 2.6, twinkleCycles: 5.5, maxAlpha: 0.74),
    _SparkleSpec(xFraction: 0.21, yFraction: 0.50, radius: 4.2, phase: 0.9, twinkleCycles: 6.2, maxAlpha: 0.68),
    _SparkleSpec(xFraction: 0.81, yFraction: 0.53, radius: 4.4, phase: 3.0, twinkleCycles: 4.9, maxAlpha: 0.70),
    _SparkleSpec(xFraction: 0.50, yFraction: 0.46, radius: 3.6, phase: 1.7, twinkleCycles: 6.6, maxAlpha: 0.62),
    _SparkleSpec(xFraction: 0.09, yFraction: 0.65, radius: 4.6, phase: 2.4, twinkleCycles: 5.3, maxAlpha: 0.72),
    _SparkleSpec(xFraction: 0.90, yFraction: 0.68, radius: 5.0, phase: 0.5, twinkleCycles: 4.7, maxAlpha: 0.74),
    _SparkleSpec(xFraction: 0.25, yFraction: 0.79, radius: 4.4, phase: 1.3, twinkleCycles: 5.9, maxAlpha: 0.70),
    _SparkleSpec(xFraction: 0.76, yFraction: 0.82, radius: 4.6, phase: 2.8, twinkleCycles: 5.1, maxAlpha: 0.72),
    _SparkleSpec(xFraction: 0.49, yFraction: 0.91, radius: 4.8, phase: 0.8, twinkleCycles: 5.4, maxAlpha: 0.74),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final p = animation.value;
    if (p <= 0.005 || p >= 0.998 || size.isEmpty) return;

    final globalEnvelope = p < 0.06
        ? (p / 0.06).clamp(0.0, 1.0)
        : (p > 0.86 ? (1.0 - (p - 0.86) / 0.14).clamp(0.0, 1.0) : 1.0);

    // 1. Twinkling golden sparkles across the entire screen height and width.
    for (final sp in _sparkles) {
      final twinkle =
          (0.18 + 0.82 * math.sin(p * math.pi * sp.twinkleCycles + sp.phase).abs()) *
              globalEnvelope;
      final cx = size.width * sp.xFraction;
      final cy = size.height * sp.yFraction;
      final r = sp.radius * (0.76 + 0.34 * twinkle);
      final inner = r * 0.25;

      _sparklePath
        ..reset()
        ..moveTo(cx, cy - r)
        ..lineTo(cx + inner, cy - inner)
        ..lineTo(cx + r, cy)
        ..lineTo(cx + inner, cy + inner)
        ..lineTo(cx, cy + r)
        ..lineTo(cx - inner, cy + inner)
        ..lineTo(cx - r, cy)
        ..lineTo(cx - inner, cy - inner)
        ..close();

      _paint.color = _CelebrationColors.goldPrimary.withValues(
        alpha: twinkle * sp.maxAlpha,
      );
      canvas.drawPath(_sparklePath, _paint);

      _paint.color = _CelebrationColors.goldBright.withValues(
        alpha: twinkle * (sp.maxAlpha * 0.95),
      );
      canvas.drawCircle(Offset(cx, cy), inner * 0.85, _paint);
    }

    // 2. Falling gold, purple & subtle red confetti spanning the entire screen.
    for (final item in _particles) {
      final localT = ((p - item.start) / item.span).clamp(0.0, 1.0);
      if (localT <= 0.0 || localT >= 1.0) continue;

      final startY = item.startYFraction > 0.0
          ? size.height * item.startYFraction
          : -14.0;
      final endY = size.height + 16.0;
      final y = startY + (endY - startY) * localT;
      final x = size.width * item.xFraction +
          math.sin(localT * math.pi * item.swayCycles + item.swayPhase) *
              item.swayAmplitude;

      final entryFade = localT < 0.10 ? localT / 0.10 : 1.0;
      final exitFade = localT > 0.85 ? (1.0 - localT) / 0.15 : 1.0;
      final alpha = entryFade * exitFade * globalEnvelope * item.baseAlpha;
      if (alpha <= 0.01) continue;

      _paint.color = item.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(localT * math.pi * item.spinSpeed + item.swayPhase);
      if (item.isCircle) {
        canvas.drawCircle(Offset.zero, item.width * 0.5, _paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: item.width,
            height: item.height,
          ),
          _paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FullScreenCelebrationPainter oldDelegate) => false;
}
