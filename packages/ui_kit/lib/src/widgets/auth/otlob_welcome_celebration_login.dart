import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'otlob_splash_to_login_logo.dart';

/// Shared celebration color tokens uniting royal purple, metallic gold,
/// and crimson red velvet across all Otlob login screens.
class _CelebrationPalette {
  const _CelebrationPalette._();

  static const purpleDeep = Color(0xFF220B3B);
  static const purpleRoyal = Color(0xFF3E1868);
  static const purpleBright = Color(0xFF6B2FA0);
  static const goldBright = Color(0xFFFFD864);
  static const goldPrimary = Color(0xFFFBBB2B);
  static const goldDeep = Color(0xFFC5830E);
  static const redVelvetBright = Color(0xFFD92649);
  static const redVelvet = Color(0xFFA81533);
  static const redVelvetDeep = Color(0xFF68081B);
}

/// Hosts the cohesive Splash-settled logo, suspended "WELCOME TO OTLOB" sign
/// held by red velvet supporting ropes, decorative purple-and-gold podium,
/// spotlights, balloons, sparkles, falling confetti, and staggered login form
/// reveal directly inside the actual Login screen of Customer, Driver, and Vendor.
class OtlobWelcomeLoginShell extends StatefulWidget {
  final String logoAssetPath;
  final String appLabel;
  final String? welcomeSubLabel;
  final Widget formChild;
  final bool? forceAnimateCelebration;
  final double topInsetPadding;
  final EdgeInsetsGeometry horizontalPadding;

  const OtlobWelcomeLoginShell({
    super.key,
    required this.logoAssetPath,
    required this.appLabel,
    this.welcomeSubLabel,
    required this.formChild,
    this.forceAnimateCelebration,
    this.topInsetPadding = 0,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  State<OtlobWelcomeLoginShell> createState() => OtlobWelcomeLoginShellState();
}

class OtlobWelcomeLoginShellState extends State<OtlobWelcomeLoginShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrationController;
  Animation<double>? _routeAnimation;
  bool _routeHooked = false;
  bool _celebrationStarted = false;

  /// Exposed for testing animation phases cleanly.
  AnimationController get celebrationController => _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeHooked) return;
    _routeHooked = true;

    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final shouldAnimateFromSplash = widget.forceAnimateCelebration ??
        OtlobLoginEntranceCoordinator.consumeFromSplash();

    if (reducedMotion) {
      _celebrationStarted = true;
      _celebrationController.value = 1.0;
      return;
    }

    if (!shouldAnimateFromSplash) {
      // Returning to Login from Register/Forgot Password or direct open:
      // show settled celebration immediately without forcing a replay delay.
      _celebrationStarted = true;
      _celebrationController.value = 1.0;
      return;
    }

    final routeAnim = ModalRoute.of(context)?.animation;
    if (routeAnim != null && routeAnim.status != AnimationStatus.completed) {
      // Strictly wait until the Splash-to-Login Hero logo transition finishes
      // before starting Step 4 (Welcome Celebration inside Login).
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
    if (!mounted || _celebrationStarted) return;
    _celebrationStarted = true;
    _celebrationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatus);
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0E2E),
              Color(0xFF130B22),
              Color(0xFF0F172A),
            ],
            stops: [0.0, 0.42, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF6EFFC),
              const Color(0xFFFFFBF2),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.36, 1.0],
          );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: bgGradient),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final isNarrow = maxW < 360;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                top: widget.topInsetPadding,
                bottom: 24,
              ),
              child: Padding(
                padding: widget.horizontalPadding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AnimatedBuilder(
                      animation: _celebrationController,
                      builder: (context, child) {
                        final t = _celebrationController.value;
                        final lightAlpha = reducedMotion
                            ? 1.0
                            : const Interval(0.0, 0.32, curve: Curves.easeOut)
                                .transform(t);
                        final ropeProgress = reducedMotion
                            ? 1.0
                            : const Interval(0.06, 0.42,
                                    curve: Curves.easeOutCubic)
                                .transform(t);
                        final signDrop = reducedMotion
                            ? 1.0
                            : const Interval(0.08, 0.48,
                                    curve: Curves.easeOutBack)
                                .transform(t);
                        final podiumRise = reducedMotion
                            ? 1.0
                            : const Interval(0.02, 0.42,
                                    curve: Curves.easeOutBack)
                                .transform(t);
                        final balloonRise = reducedMotion
                            ? 1.0
                            : const Interval(0.16, 0.72,
                                    curve: Curves.easeOutCubic)
                                .transform(t);
                        final particleProgress = reducedMotion ? 1.0 : t;
                        final formReveal = reducedMotion
                            ? 1.0
                            : const Interval(0.54, 0.96,
                                    curve: Curves.easeOutCubic)
                                .transform(t);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _WelcomeCelebrationStage(
                              logoAssetPath: widget.logoAssetPath,
                              appLabel: widget.appLabel,
                              welcomeSubLabel: widget.welcomeSubLabel,
                              isDark: isDark,
                              isNarrow: isNarrow,
                              lightAlpha: lightAlpha,
                              ropeProgress: ropeProgress,
                              signDrop: signDrop,
                              podiumRise: podiumRise,
                              balloonRise: balloonRise,
                              particleProgress: particleProgress,
                              reducedMotion: reducedMotion,
                            ),
                            const SizedBox(height: 14),
                            // Login form appears smoothly AFTER the welcome
                            // celebration begins unfolding around the settled logo.
                            IgnorePointer(
                              ignoring: formReveal < 0.25,
                              child: Opacity(
                                opacity: formReveal.clamp(0.0, 1.0),
                                child: Transform.translate(
                                  offset: Offset(0, (1.0 - formReveal) * 24),
                                  child: child,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(isNarrow ? 16 : 22),
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.surface.withValues(alpha: 0.94)
                              : Colors.white.withValues(alpha: 0.97),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? _CelebrationPalette.goldPrimary
                                    .withValues(alpha: 0.22)
                                : _CelebrationPalette.purpleRoyal
                                    .withValues(alpha: 0.14),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? Colors.black
                                      : _CelebrationPalette.purpleDeep)
                                  .withValues(alpha: isDark ? 0.36 : 0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: widget.formChild,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeCelebrationStage extends StatelessWidget {
  final String logoAssetPath;
  final String appLabel;
  final String? welcomeSubLabel;
  final bool isDark;
  final bool isNarrow;
  final double lightAlpha;
  final double ropeProgress;
  final double signDrop;
  final double podiumRise;
  final double balloonRise;
  final double particleProgress;
  final bool reducedMotion;

  const _WelcomeCelebrationStage({
    required this.logoAssetPath,
    required this.appLabel,
    required this.welcomeSubLabel,
    required this.isDark,
    required this.isNarrow,
    required this.lightAlpha,
    required this.ropeProgress,
    required this.signDrop,
    required this.podiumRise,
    required this.balloonRise,
    required this.particleProgress,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    final stageHeight = isNarrow ? 276.0 : 292.0;

    return SizedBox(
      width: double.infinity,
      height: stageHeight,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            final signWidth = (width * 0.74).clamp(198.0, 300.0);
            final signTop = 44.0 + (1.0 - signDrop.clamp(0.0, 1.3)) * -26.0;
            final signLeft = (width - signWidth) / 2;

            return Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              children: [
                // 1. Warm golden spotlight cones + ambient purple-gold stage glow
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _SpotlightsAndGlowPainter(
                          alpha: lightAlpha,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Left & right decorative balloons floating gracefully into flank
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _CelebrationBalloonsPainter(
                          progress: balloonRise,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Red velvet supporting ropes with gold clasp connectors
                // anchored cleanly to the left & right upper corners of the sign
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _RedVelvetSupportingRopesPainter(
                          progress: ropeProgress,
                          signLeft: signLeft,
                          signWidth: signWidth,
                          signTop: signTop,
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Decorative Purple & Gold Podium / Table underneath the sign
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 112,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: podiumRise.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          (1.0 - podiumRise.clamp(0.0, 1.2)) * 28,
                        ),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _DecorativePodiumPainter(
                              isDark: isDark,
                              brandLabel: appLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Suspended "WELCOME TO OTLOB" Sign
                Positioned(
                  top: signTop,
                  width: signWidth,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: signDrop.clamp(0.0, 1.0),
                      child: _SuspendedWelcomeSign(
                        appLabel: appLabel,
                        welcomeSubLabel: welcomeSubLabel,
                      ),
                    ),
                  ),
                ),

                // 6. Settled Otlob Logo Hero destination (centered directly above podium)
                Positioned(
                  bottom: 72,
                  child: OtlobBrandHeroLogo(
                    assetPath: logoAssetPath,
                    size: isNarrow ? 64 : 72,
                    auraPadding: 9,
                    auraColor: isDark
                        ? _CelebrationPalette.purpleRoyal.withValues(alpha: 0.78)
                        : Colors.white.withValues(alpha: 0.94),
                    borderColor: _CelebrationPalette.goldBright
                        .withValues(alpha: 0.85),
                    showMedallion: true,
                  ),
                ),

                // 7. Falling Confetti & Golden Sparkles (finite celebration fade-out)
                if (!reducedMotion)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _ConfettiAndSparklesPainter(
                            progress: particleProgress,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SuspendedWelcomeSign extends StatelessWidget {
  final String appLabel;
  final String? welcomeSubLabel;

  const _SuspendedWelcomeSign({
    required this.appLabel,
    this.welcomeSubLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _CelebrationPalette.purpleBright,
            _CelebrationPalette.purpleRoyal,
            _CelebrationPalette.purpleDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _CelebrationPalette.goldBright,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _CelebrationPalette.purpleDeep.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _CelebrationPalette.goldPrimary.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Inner gold & red-velvet hairline frame
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _CelebrationPalette.goldPrimary.withValues(alpha: 0.38),
                  width: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'WELCOME TO OTLOB',
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                      color: _CelebrationPalette.goldBright,
                      shadows: [
                        Shadow(
                          color: Color(0xAA000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _CelebrationPalette.redVelvetDeep,
                        _CelebrationPalette.redVelvet,
                        _CelebrationPalette.redVelvetDeep,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _CelebrationPalette.goldPrimary
                          .withValues(alpha: 0.65),
                      width: 0.8,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      welcomeSubLabel != null && welcomeSubLabel!.isNotEmpty
                          ? '$appLabel • $welcomeSubLabel'
                          : appLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightsAndGlowPainter extends CustomPainter {
  final double alpha;
  final bool isDark;

  const _SpotlightsAndGlowPainter({
    required this.alpha,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha <= 0.01) return;

    // Warm golden descending spotlights from top corners onto the sign & podium
    final beamAlpha = (isDark ? 0.22 : 0.16) * alpha;
    final leftBeamPath = Path()
      ..moveTo(size.width * 0.16, 0)
      ..lineTo(size.width * 0.28, 0)
      ..lineTo(size.width * 0.68, size.height * 0.82)
      ..lineTo(size.width * 0.22, size.height * 0.82)
      ..close();

    final rightBeamPath = Path()
      ..moveTo(size.width * 0.72, 0)
      ..lineTo(size.width * 0.84, 0)
      ..lineTo(size.width * 0.78, size.height * 0.82)
      ..lineTo(size.width * 0.32, size.height * 0.82)
      ..close();

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _CelebrationPalette.goldBright.withValues(alpha: beamAlpha),
          _CelebrationPalette.goldPrimary.withValues(alpha: beamAlpha * 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.85));

    canvas.drawPath(leftBeamPath, beamPaint);
    canvas.drawPath(rightBeamPath, beamPaint);

    // Warm halo behind the central welcome sign & logo medallion
    final center = Offset(size.width / 2, size.height * 0.48);
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _CelebrationPalette.goldPrimary
              .withValues(alpha: (isDark ? 0.24 : 0.18) * alpha),
          _CelebrationPalette.purpleBright
              .withValues(alpha: (isDark ? 0.18 : 0.10) * alpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.42));
    canvas.drawCircle(center, size.width * 0.42, haloPaint);
  }

  @override
  bool shouldRepaint(_SpotlightsAndGlowPainter oldDelegate) =>
      oldDelegate.alpha != alpha || oldDelegate.isDark != isDark;
}

class _RedVelvetSupportingRopesPainter extends CustomPainter {
  final double progress;
  final double signLeft;
  final double signWidth;
  final double signTop;

  const _RedVelvetSupportingRopesPainter({
    required this.progress,
    required this.signLeft,
    required this.signWidth,
    required this.signTop,
  });

  void _drawRopeSegment(
    Canvas canvas,
    Offset start,
    Offset end,
    double t, {
    required bool curveInwardLeft,
  }) {
    final currentEnd = Offset.lerp(start, end, t)!;
    final ctrlX = curveInwardLeft
        ? (start.dx + currentEnd.dx) * 0.5 - 6
        : (start.dx + currentEnd.dx) * 0.5 + 6;
    final ctrlY = (start.dy + currentEnd.dy) * 0.5 + 8;

    final ropePath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(ctrlX, ctrlY, currentEnd.dx, currentEnd.dy);

    // Shadow under velvet rope
    canvas.drawPath(
      ropePath.shift(const Offset(0, 2.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round,
    );

    // Deep velvet base
    canvas.drawPath(
      ropePath,
      Paint()
        ..color = _CelebrationPalette.redVelvetDeep.withValues(alpha: t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round,
    );

    // Rich crimson velvet core
    canvas.drawPath(
      ropePath,
      Paint()
        ..color = _CelebrationPalette.redVelvet.withValues(alpha: t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round,
    );

    // Subtle sheen highlight along the velvet braid
    canvas.drawPath(
      ropePath,
      Paint()
        ..color = _CelebrationPalette.redVelvetBright.withValues(alpha: 0.72 * t)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // Top ceiling gold finial
    _drawGoldConnector(canvas, start + const Offset(0, 3), 4.6, t);
    // Gold ring clasp attaching rope directly to the suspended sign
    if (t > 0.35) {
      final claspAlpha = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
      _drawGoldConnector(canvas, currentEnd, 5.5, claspAlpha);
    }
  }

  void _drawGoldConnector(
    Canvas canvas,
    Offset center,
    double radius,
    double alpha,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = _CelebrationPalette.goldDeep.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      center,
      radius * 0.76,
      Paint()..color = _CelebrationPalette.goldBright.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      center,
      radius * 0.32,
      Paint()..color = _CelebrationPalette.purpleDeep.withValues(alpha: alpha),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.01) return;

    final leftAnchor = Offset((signLeft - 24).clamp(16.0, signLeft), 2);
    final leftAttach = Offset(signLeft + 14, signTop + 5);

    final rightAnchor =
        Offset((signLeft + signWidth + 24).clamp(signLeft + signWidth, size.width - 16), 2);
    final rightAttach = Offset(signLeft + signWidth - 14, signTop + 5);

    _drawRopeSegment(canvas, leftAnchor, leftAttach, t, curveInwardLeft: true);
    _drawRopeSegment(canvas, rightAnchor, rightAttach, t, curveInwardLeft: false);
  }

  @override
  bool shouldRepaint(_RedVelvetSupportingRopesPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.signLeft != signLeft ||
      oldDelegate.signWidth != signWidth ||
      oldDelegate.signTop != signTop;
}

class _DecorativePodiumPainter extends CustomPainter {
  final bool isDark;
  final String brandLabel;

  const _DecorativePodiumPainter({
    required this.isDark,
    required this.brandLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final deckWidth = (size.width * 0.64).clamp(180.0, 270.0);
    final bodyWidth = deckWidth * 0.84;
    final topY = 26.0;
    final deckHeight = 14.0;
    final bodyTop = topY + deckHeight;
    final bodyBottom = size.height - 8;

    // Soft ground shadow beneath the podium
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, bodyBottom + 2),
        width: deckWidth * 0.94,
        height: 12,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.42 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Podium main tapered purple body
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(cx, (bodyTop + bodyBottom) / 2),
        width: bodyWidth,
        height: (bodyBottom - bodyTop).clamp(24.0, 80.0),
      ),
      bottomLeft: const Radius.circular(14),
      bottomRight: const Radius.circular(14),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _CelebrationPalette.purpleRoyal,
            _CelebrationPalette.purpleDeep,
          ],
        ).createShader(bodyRect.outerRect),
    );

    // Royal purple front drape scallops & gold trim line
    final trimPaint = Paint()
      ..color = _CelebrationPalette.goldPrimary.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final drapeY = bodyTop + 13;
    final drapePath = Path()..moveTo(cx - bodyWidth / 2 + 8, bodyTop + 2);
    const scallops = 4;
    final step = (bodyWidth - 16) / scallops;
    for (int i = 0; i < scallops; i++) {
      final sx = cx - bodyWidth / 2 + 8 + i * step;
      drapePath.quadraticBezierTo(sx + step / 2, drapeY + 8, sx + step, bodyTop + 2);
    }
    canvas.drawPath(
      drapePath,
      Paint()..color = _CelebrationPalette.purpleBright.withValues(alpha: 0.55),
    );
    canvas.drawPath(drapePath, trimPaint);

    // Beveled metallic gold podium top table deck
    final deckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, topY + deckHeight / 2),
        width: deckWidth,
        height: deckHeight,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      deckRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _CelebrationPalette.goldBright,
            _CelebrationPalette.goldPrimary,
            _CelebrationPalette.goldDeep,
          ],
        ).createShader(deckRect.outerRect),
    );

    // Bottom gold plinth base
    final plinthRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, bodyBottom - 4),
        width: bodyWidth + 14,
        height: 8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      plinthRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            _CelebrationPalette.goldDeep,
            _CelebrationPalette.goldBright,
            _CelebrationPalette.goldDeep,
          ],
        ).createShader(plinthRect.outerRect),
    );

    // Decorative miniature gift boxes with red velvet ribbons resting on deck edges
    _drawGiftBox(
      canvas,
      Offset(cx - deckWidth * 0.36, topY - 12),
      18,
      _CelebrationPalette.purpleBright,
      _CelebrationPalette.goldBright,
    );
    _drawGiftBox(
      canvas,
      Offset(cx + deckWidth * 0.36, topY - 10),
      16,
      _CelebrationPalette.redVelvet,
      _CelebrationPalette.goldBright,
    );

    // Festive floral rosette buds beside gift boxes
    _drawRosette(canvas, Offset(cx - deckWidth * 0.25, topY - 4));
    _drawRosette(canvas, Offset(cx + deckWidth * 0.25, topY - 4));

    // Central embossed gold OTLOB crest plaque on podium front
    final crestRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, (bodyTop + bodyBottom) / 2 + 4),
        width: (bodyWidth * 0.44).clamp(74.0, 112.0),
        height: 22,
      ),
      const Radius.circular(11),
    );
    canvas.drawRRect(
      crestRect,
      Paint()..color = _CelebrationPalette.purpleDeep,
    );
    canvas.drawRRect(
      crestRect,
      Paint()
        ..color = _CelebrationPalette.goldBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'OTLOB',
        style: TextStyle(
          color: _CelebrationPalette.goldBright,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        cx - textPainter.width / 2,
        crestRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawGiftBox(
    Canvas canvas,
    Offset topLeft,
    double size,
    Color boxColor,
    Color ribbonColor,
  ) {
    final rect = Rect.fromLTWH(topLeft.dx - size / 2, topLeft.dy, size, size * 0.78);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = boxColor,
    );
    // Ribbon vertical + horizontal
    final rPaint = Paint()..color = ribbonColor;
    canvas.drawRect(
      Rect.fromCenter(center: rect.center, width: 3.2, height: rect.height),
      rPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: rect.center, width: rect.width, height: 2.6),
      rPaint,
    );
    // Tiny bow loop on top
    canvas.drawCircle(Offset(rect.center.dx - 2.5, rect.top - 1.5), 2.2, rPaint);
    canvas.drawCircle(Offset(rect.center.dx + 2.5, rect.top - 1.5), 2.2, rPaint);
  }

  void _drawRosette(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 4.5, Paint()..color = const Color(0xFF10B981));
    canvas.drawCircle(center.translate(0, -1), 3.4, Paint()..color = _CelebrationPalette.redVelvetBright);
    canvas.drawCircle(center.translate(0, -1), 1.4, Paint()..color = _CelebrationPalette.goldBright);
  }

  @override
  bool shouldRepaint(_DecorativePodiumPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.brandLabel != brandLabel;
}

class _CelebrationBalloonsPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _CelebrationBalloonsPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.clamp(0.0, 1.0);
    if (t <= 0.01) return;

    final balloons = <({double rx, double ry, double r, Color color, double bob})>[
      (rx: 0.09, ry: 0.36, r: 16, color: _CelebrationPalette.purpleBright, bob: 4),
      (rx: 0.16, ry: 0.48, r: 14, color: _CelebrationPalette.goldPrimary, bob: -3),
      (rx: 0.07, ry: 0.54, r: 13, color: _CelebrationPalette.redVelvetBright, bob: 3),
      (rx: 0.91, ry: 0.36, r: 16, color: _CelebrationPalette.redVelvetBright, bob: -4),
      (rx: 0.84, ry: 0.48, r: 14, color: _CelebrationPalette.purpleBright, bob: 3),
      (rx: 0.93, ry: 0.54, r: 13, color: _CelebrationPalette.goldPrimary, bob: -3),
    ];

    final riseOffset = (1.0 - t) * 48.0;

    for (final b in balloons) {
      final cx = size.width * b.rx;
      final cy = size.height * b.ry + riseOffset + math.sin(t * math.pi) * b.bob;

      // Delicate curved balloon string
      final stringPath = Path()
        ..moveTo(cx, cy + b.r * 1.15)
        ..quadraticBezierTo(cx + 4, cy + b.r * 1.8, cx - 2, cy + b.r * 2.5);
      canvas.drawPath(
        stringPath,
        Paint()
          ..color = (isDark ? Colors.white54 : Colors.black26).withValues(alpha: t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      final oval = Rect.fromCenter(
        center: Offset(cx, cy),
        width: b.r * 1.72,
        height: b.r * 2.08,
      );
      canvas.drawOval(
        oval,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: [
              Colors.white.withValues(alpha: 0.72 * t),
              b.color.withValues(alpha: 0.92 * t),
              b.color.withValues(alpha: 0.75 * t),
            ],
            stops: const [0.0, 0.35, 1.0],
          ).createShader(oval),
      );
    }
  }

  @override
  bool shouldRepaint(_CelebrationBalloonsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}

class _ConfettiAndSparklesPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  const _ConfettiAndSparklesPainter({
    required this.progress,
    required this.isDark,
  });

  static const _confettiPalette = <Color>[
    _CelebrationPalette.goldBright,
    _CelebrationPalette.purpleBright,
    _CelebrationPalette.redVelvetBright,
    _CelebrationPalette.goldPrimary,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.05 || progress >= 0.995) return;

    // Smooth celebratory envelope: fades in at 0.12 and settles out softly at 0.98
    final envelope = progress < 0.22
        ? ((progress - 0.05) / 0.17).clamp(0.0, 1.0)
        : (progress > 0.78
            ? (1.0 - (progress - 0.78) / 0.22).clamp(0.0, 1.0)
            : 1.0);

    // 18 lightweight falling confetti pieces across header stage
    for (int i = 0; i < 18; i++) {
      final seed = (i * 0.6180339887) % 1.0;
      final fallT = ((progress - 0.08) * 1.15 - seed * 0.35).clamp(0.0, 1.0);
      if (fallT <= 0 || fallT >= 1.0) continue;

      final xBase = size.width * (0.08 + ((i * 37) % 84) / 100.0);
      final sway = math.sin(fallT * math.pi * 3 + i) * 10.0;
      final y = fallT * size.height * 0.92;
      final angle = fallT * math.pi * 2.5 + i;
      final color = _confettiPalette[i % _confettiPalette.length]
          .withValues(alpha: 0.85 * envelope);

      canvas.save();
      canvas.translate(xBase + sway, y);
      canvas.rotate(angle);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 2.6, Paint()..color = color);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3.5, -2.0, 7.0, 4.0),
            const Radius.circular(1),
          ),
          Paint()..color = color,
        );
      }
      canvas.restore();
    }

    // 8 subtle golden 4-point star sparkles around the sign & medallion
    final sparklePositions = <Offset>[
      Offset(size.width * 0.18, size.height * 0.18),
      Offset(size.width * 0.82, size.height * 0.18),
      Offset(size.width * 0.24, size.height * 0.44),
      Offset(size.width * 0.76, size.height * 0.44),
      Offset(size.width * 0.34, size.height * 0.56),
      Offset(size.width * 0.66, size.height * 0.56),
      Offset(size.width * 0.50, size.height * 0.11),
      Offset(size.width * 0.50, size.height * 0.62),
    ];

    for (int i = 0; i < sparklePositions.length; i++) {
      final pulse =
          (0.35 + 0.65 * math.sin(progress * math.pi * 4 + i * 0.9).abs()) *
              envelope;
      _drawFourPointStar(
        canvas,
        sparklePositions[i],
        5.5 + (i % 2) * 2.0,
        _CelebrationPalette.goldBright.withValues(alpha: pulse * 0.9),
      );
    }
  }

  void _drawFourPointStar(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    final inner = radius * 0.26;
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + inner, center.dy - inner)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + inner, center.dy + inner)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - inner, center.dy + inner)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - inner, center.dy - inner)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ConfettiAndSparklesPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isDark != isDark;
}
