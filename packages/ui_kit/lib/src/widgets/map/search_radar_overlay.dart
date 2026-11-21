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

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || waveCount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.48;
    final minRadius = maxRadius * 0.16;

    for (var i = 0; i < waveCount; i++) {
      final t = (progress.value + i / waveCount) % 1.0;
      final eased = Curves.easeOut.transform(t);
      final radius = minRadius + (maxRadius - minRadius) * eased;
      final opacity = (1.0 - eased) * 0.34;

      final fillPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);

      final ringPaint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPulsePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.waveCount != waveCount ||
        oldDelegate.isActive != isActive;
  }
}
