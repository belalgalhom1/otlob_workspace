import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight, repaint-isolated concentric radar pulse animation for map
/// search markers.
///
/// Uses `CustomPainter(repaint: animation)` inside a [RepaintBoundary] so frame
/// ticks never rebuild widget subtrees or trigger unnecessary layout passes.
class DriverSearchRadarPulse extends StatefulWidget {
  const DriverSearchRadarPulse({
    super.key,
    this.size = 200,
    required this.color,
    this.isActive = true,
    this.waveCount = 3,
    this.period = const Duration(milliseconds: 2400),
    this.child,
  });

  final double size;
  final Color color;
  final bool isActive;
  final int waveCount;
  final Duration period;
  final Widget? child;

  @override
  State<DriverSearchRadarPulse> createState() => _DriverSearchRadarPulseState();
}

class _DriverSearchRadarPulseState extends State<DriverSearchRadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant DriverSearchRadarPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _controller.duration = widget.period;
    }
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _RadarPulsePainter(
            progress: _controller,
            color: widget.color,
            waveCount: widget.waveCount,
            isActive: widget.isActive,
          ),
          child: widget.child != null ? Center(child: widget.child) : null,
        ),
      ),
    );
  }
}

class _RadarPulsePainter extends CustomPainter {
  _RadarPulsePainter({
    required this.progress,
    required this.color,
    required this.waveCount,
    required this.isActive,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final int waveCount;
  final bool isActive;

  // Reused across frames to guarantee zero GC allocations at 60/120fps.
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || waveCount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.48;
    final minRadius = maxRadius * 0.14;

    // Soft breathing core aura around pickup pin
    final corePulse = 0.5 + 0.5 * math.sin(progress.value * math.pi * 2.0);
    _fillPaint.color = color.withValues(alpha: 0.10 + corePulse * 0.08);
    canvas.drawCircle(
      center,
      minRadius * (1.2 + corePulse * 0.28),
      _fillPaint,
    );

    for (var i = 0; i < waveCount; i++) {
      final t = (progress.value + i / waveCount) % 1.0;
      final eased = Curves.easeOutCubic.transform(t);
      final radius = minRadius + (maxRadius - minRadius) * eased;
      final fade = (1.0 - eased).clamp(0.0, 1.0);
      final smoothFade = fade * fade;

      _fillPaint.color = color.withValues(alpha: smoothFade * 0.18);
      canvas.drawCircle(center, radius, _fillPaint);

      _ringPaint
        ..color = color.withValues(alpha: fade * 0.48)
        ..strokeWidth = 1.2 + fade * 1.1;
      canvas.drawCircle(center, radius, _ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.waveCount != waveCount ||
        oldDelegate.isActive != isActive;
  }
}
