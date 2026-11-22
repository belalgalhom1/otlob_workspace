import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Modern pulsing navigation user/driver location marker with optional heading arrow.
class NavigationLocationMarker extends StatefulWidget {
  final double size;
  final Color color;
  final double? heading; // In degrees (0 - 360)

  const NavigationLocationMarker({
    super.key,
    this.size = 36.0,
    this.color = const Color(0xFF2563EB), // Navigation Blue
    this.heading,
  });

  @override
  State<NavigationLocationMarker> createState() => _NavigationLocationMarkerState();
}

class _NavigationLocationMarkerState extends State<NavigationLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulseAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuad,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Radar pulse ring
            Container(
              width: widget.size * (1.0 + (_pulseAnimation.value * 0.6)),
              height: widget.size * (1.0 + (_pulseAnimation.value * 0.6)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: (1.0 - _pulseAnimation.value) * 0.35),
              ),
            ),
            // White halo
            Container(
              width: widget.size * 0.65,
              height: widget.size * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            // Core colored beacon
            Container(
              width: widget.size * 0.45,
              height: widget.size * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
              child: widget.heading != null
                  ? Transform.rotate(
                      angle: (widget.heading! * 3.141592653589793 / 180.0),
                      child: const Icon(
                        LucideIcons.navigation2,
                        size: 10,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
      ),
    );
  }
}

/// An authentic inDrive-style top-down vehicle marker for real-time tracking screens.
///
/// Features:
/// - Exact inDrive aesthetic: top-down car, motorcycle with delivery box, bicycle, van/truck.
/// - Radar pulse wave underneath indicating live satellite/telemetry connection.
/// - Smooth heading orientation along the street trajectory.
/// - Zero-lag, zero GC allocation CustomPainter with hardware accelerated rendering.
/// - Upright floating badge/license plate pill that stays readable while the vehicle turns.
class InDriveVehicleMarker extends StatefulWidget {
  final double size;
  final Color color;
  final double heading; // 0 - 360 degrees
  final bool isMoving;
  final String? label;
  final String? vehicleType; // 'MOTORCYCLE', 'CAR', 'MINIBUS', 'TUK_TUK', 'BICYCLE', 'QUARTER_TRUCK', 'HALF_TRUCK', 'MOTOR_TRICYCLE'
  final String? plateNumber;
  final String? driverName;
  final bool showHeadlightGlow;
  final bool showRadarPulse;
  final bool showCargoBox;

  const InDriveVehicleMarker({
    super.key,
    this.size = 54.0,
    this.color = const Color(0xFFF59E0B),
    this.heading = 0.0,
    this.isMoving = false,
    this.label,
    this.vehicleType = 'MOTORCYCLE',
    this.plateNumber,
    this.driverName,
    this.showHeadlightGlow = true,
    this.showRadarPulse = true,
    this.showCargoBox = true,
  });

  @override
  State<InDriveVehicleMarker> createState() => _InDriveVehicleMarkerState();
}

class _InDriveVehicleMarkerState extends State<InDriveVehicleMarker>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  void _ensurePulseController() {
    if (_pulseController != null) return;
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseController = ctrl;
    _pulseAnimation = CurvedAnimation(
      parent: ctrl,
      curve: Curves.easeOutQuad,
    );
  }

  void _syncPulseState() {
    if (widget.showRadarPulse && widget.isMoving) {
      _ensurePulseController();
      if (!_pulseController!.isAnimating) {
        _pulseController!.repeat();
      }
    } else if (_pulseController != null && _pulseController!.isAnimating) {
      _pulseController!.stop();
      _pulseController!.value = 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    // Lazily allocate a Ticker ONLY when radar pulse is actually enabled,
    // keeping multi-vehicle map search layers completely zero-ticker.
    _syncPulseState();
  }

  @override
  void didUpdateWidget(covariant InDriveVehicleMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showRadarPulse != widget.showRadarPulse ||
        oldWidget.isMoving != widget.isMoving) {
      _syncPulseState();
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveVehicle = widget.vehicleType ?? 'MOTORCYCLE';
    final hasPill = (widget.label != null && widget.label!.isNotEmpty) ||
        (widget.plateNumber != null && widget.plateNumber!.isNotEmpty);

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size * 1.35,
        height: widget.size * 1.35,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // 1. Live Telemetry Radar Pulse Wave (inDrive style)
            if (widget.showRadarPulse && _pulseAnimation != null)
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _pulseAnimation!,
                  builder: (context, _) {
                    final progress = _pulseAnimation!.value;
                    final waveSize = widget.size * (0.8 + (progress * 0.5));
                    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.35;
                    return Container(
                      width: waveSize,
                      height: waveSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: opacity),
                        border: Border.all(
                          color: widget.color.withValues(alpha: opacity * 0.8),
                          width: 1.0,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 2. The Smoothly-Oriented Vehicle Graphic
            Transform.rotate(
              angle: widget.heading * math.pi / 180.0,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: InDriveVehiclePainter(
                  vehicleType: effectiveVehicle,
                  primaryColor: widget.color,
                  showHeadlightGlow: widget.showHeadlightGlow,
                  isMoving: widget.isMoving,
                  showCargoBox: widget.showCargoBox,
                ),
              ),
            ),

            // 3. Floating Info Badge / License Plate Pill (always upright, doesn't spin)
            if (hasPill)
              Positioned(
                top: -6,
                child: _buildUprightBadge(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUprightBadge() {
    final text = widget.label ?? widget.plateNumber ?? '';
    return Container(
      constraints: BoxConstraints(maxWidth: widget.size * 1.8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xE60F172A), // Dark slate 90%
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.color, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Zero-lag, zero GC allocation high-performance vehicle painter.
class InDriveVehiclePainter extends CustomPainter {
  final String vehicleType;
  final Color primaryColor;
  final bool showHeadlightGlow;
  final bool isMoving;
  final bool showCargoBox;

  // Cached Paint objects to guarantee 0 allocations during 60/120fps animation ticks.
  // Dual-alpha hardware rasterized shadows: zero GPU blur filter overhead on budget mobile chips.
  static final Paint _shadowOuterPaint = Paint()
    ..color = const Color(0x18000000)
    ..style = PaintingStyle.fill;

  static final Paint _shadowInnerPaint = Paint()
    ..color = const Color(0x2E000000)
    ..style = PaintingStyle.fill;

  static final Paint _headlightBeamPaint = Paint()
    ..color = const Color(0x22FEF08A)
    ..style = PaintingStyle.fill;

  static final Paint _tirePaint = Paint()
    ..color = const Color(0xFF1E293B)
    ..style = PaintingStyle.fill;

  static final Paint _rimPaint = Paint()
    ..color = const Color(0xFF94A3B8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _carBodyPaint = Paint()
    ..color = const Color(0xFFF8FAFC)
    ..style = PaintingStyle.fill;

  static final Paint _carBodyStroke = Paint()
    ..color = const Color(0xFF64748B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _detailStrokePaint = Paint()
    ..color = const Color(0xFFCBD5E1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  static final Paint _roofPaint = Paint()
    ..color = const Color(0xFFE2E8F0)
    ..style = PaintingStyle.fill;

  static final Paint _sunroofPaint = Paint()
    ..color = const Color(0xFF1E293B)
    ..style = PaintingStyle.fill;

  static final Paint _glassPaint = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.fill;

  static final Paint _glassHighlightPaint = Paint()
    ..color = const Color(0x40FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;

  static final Paint _headlightPaint = Paint()
    ..color = const Color(0xFFFEF08A)
    ..style = PaintingStyle.fill;

  static final Paint _taillightPaint = Paint()
    ..color = const Color(0xFFEF4444)
    ..style = PaintingStyle.fill;

  static final Paint _mirrorPaint = Paint()
    ..color = const Color(0xFFE2E8F0)
    ..style = PaintingStyle.fill;

  static final Paint _mirrorStroke = Paint()
    ..color = const Color(0xFF64748B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  static final Paint _handlebarPaint = Paint()
    ..color = const Color(0xFF94A3B8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  static final Paint _bicycleBarPaint = Paint()
    ..color = const Color(0xFF94A3B8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;

  static final Paint _gripPaint = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.square;

  static final Paint _jacketPaint = Paint()
    ..color = const Color(0xFF1E293B)
    ..style = PaintingStyle.fill;

  static final Paint _helmetPaint = Paint()
    ..color = const Color(0xFFF8FAFC)
    ..style = PaintingStyle.fill;

  static final Paint _helmetStrokePaint = Paint()
    ..color = const Color(0xFF64748B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  static final Paint _visorPaint = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.fill;

  static final Paint _boxStrokePaint = Paint()
    ..color = const Color(0xFF92400E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _bedBorderPaint = Paint()
    ..color = const Color(0xFF92400E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final Paint _boxDetailPaint = Paint()
    ..color = const Color(0x35000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  static final Paint _emblemPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint _seatPaint = Paint()
    ..color = const Color(0xFF334155)
    ..style = PaintingStyle.fill;

  static final Paint _bedInnerFloorPaint = Paint()
    ..color = const Color(0x401E293B)
    ..style = PaintingStyle.fill;

  static final Paint _bedRibPaint = Paint()
    ..color = const Color(0x470F172A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  final Paint _primaryFillPaint;
  final Paint _primaryStrokePaint;
  final Path _path = Path();

  InDriveVehiclePainter({
    required this.vehicleType,
    required this.primaryColor,
    this.showHeadlightGlow = true,
    this.isMoving = false,
    this.showCargoBox = true,
  }) : _primaryFillPaint = Paint()
         ..color = primaryColor
         ..style = PaintingStyle.fill,
       _primaryStrokePaint = Paint()
         ..color = primaryColor
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.6
         ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;
    final cy = size.height / 2.0;
    canvas.save();
    canvas.translate(cx, cy);

    final scale = size.width / 54.0;
    canvas.scale(scale, scale);

    final normalizedType = vehicleType.toUpperCase().trim();
    switch (normalizedType) {
      case 'CAR':
        _paintCar(canvas);
        break;
      case 'MINIBUS':
        _paintMinibus(canvas);
        break;
      case 'TUK_TUK':
        _paintTukTuk(canvas);
        break;
      case 'BICYCLE':
        _paintBicycle(canvas);
        break;
      case 'QUARTER_TRUCK':
        _paintPickupTruck(canvas, isHalfTon: false);
        break;
      case 'HALF_TRUCK':
        _paintPickupTruck(canvas, isHalfTon: true);
        break;
      case 'MOTOR_TRICYCLE':
        _paintMotorTricycle(canvas);
        break;
      case 'MOTORCYCLE':
      default:
        _paintMotorcycle(canvas);
        break;
    }

    canvas.restore();
  }

  void _paintCar(Canvas canvas) {
    // 1. Dual-alpha hardware drop shadow (zero blur pass)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-15, -25, 30, 54),
        const Radius.circular(11),
      ),
      _shadowOuterPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -23, 26, 50),
        const Radius.circular(9),
      ),
      _shadowInnerPaint,
    );

    // 2. Headlight Beams (zero runtime shader creation)
    if (showHeadlightGlow) {
      _path.reset();
      _path.moveTo(-10, -24);
      _path.lineTo(-18, -48);
      _path.lineTo(-4, -48);
      _path.lineTo(-6, -24);
      _path.close();
      canvas.drawPath(_path, _headlightBeamPaint);

      _path.reset();
      _path.moveTo(6, -24);
      _path.lineTo(4, -48);
      _path.lineTo(18, -48);
      _path.lineTo(10, -24);
      _path.close();
      canvas.drawPath(_path, _headlightBeamPaint);
    }

    // 3. Side mirrors
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16.5, -12, 4.5, 3),
        const Radius.circular(1.5),
      ),
      _mirrorPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16.5, -12, 4.5, 3),
        const Radius.circular(1.5),
      ),
      _mirrorStroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, -12, 4.5, 3),
        const Radius.circular(1.5),
      ),
      _mirrorPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, -12, 4.5, 3),
        const Radius.circular(1.5),
      ),
      _mirrorStroke,
    );

    // 4. Car Outer Aerodynamic Body
    _path.reset();
    _path.moveTo(0, -26);
    _path.quadraticBezierTo(-10, -26, -12.5, -20);
    _path.lineTo(-12.5, 18);
    _path.quadraticBezierTo(-12.5, 26, -7, 26.5);
    _path.lineTo(7, 26.5);
    _path.quadraticBezierTo(12.5, 26, 12.5, 18);
    _path.lineTo(12.5, -20);
    _path.quadraticBezierTo(10, -26, 0, -26);
    _path.close();

    canvas.drawPath(_path, _carBodyPaint);
    canvas.drawPath(_path, _carBodyStroke);

    // Detail creases
    canvas.drawLine(
      const Offset(-8, -21),
      const Offset(-6, -14),
      _detailStrokePaint,
    );
    canvas.drawLine(
      const Offset(8, -21),
      const Offset(6, -14),
      _detailStrokePaint,
    );

    // 5. Front Windshield (curved dark tinted glass)
    _path.reset();
    _path.moveTo(-8.5, -14);
    _path.quadraticBezierTo(0, -15.5, 8.5, -14);
    _path.lineTo(9.5, -5);
    _path.quadraticBezierTo(0, -6.5, -9.5, -5);
    _path.close();
    canvas.drawPath(_path, _glassPaint);

    // Windshield reflection
    canvas.drawLine(
      const Offset(-4, -13),
      const Offset(2, -7),
      _glassHighlightPaint,
    );

    // 6. Roof & Sunroof
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8.5, -5, 17, 14),
        const Radius.circular(2),
      ),
      _roofPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5.5, -3, 11, 6),
        const Radius.circular(1.5),
      ),
      _sunroofPaint,
    );

    // 7. Rear Window
    _path.reset();
    _path.moveTo(-9.5, 9);
    _path.quadraticBezierTo(0, 8, 9.5, 9);
    _path.lineTo(8, 16);
    _path.quadraticBezierTo(0, 15, -8, 16);
    _path.close();
    canvas.drawPath(_path, _glassPaint);

    canvas.drawLine(
      const Offset(-3, 10.5),
      const Offset(3, 14.5),
      _glassHighlightPaint,
    );

    // 8. Front Headlights
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10.5, -25, 4, 3),
        const Radius.circular(1.5),
      ),
      _headlightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6.5, -25, 4, 3),
        const Radius.circular(1.5),
      ),
      _headlightPaint,
    );

    // 9. Rear Taillights
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11.5, 24, 4.5, 2.5),
        const Radius.circular(1),
      ),
      _taillightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 24, 4.5, 2.5),
        const Radius.circular(1),
      ),
      _taillightPaint,
    );

    // 10. Otlob Brand Accent on Car Roof
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, 5, 6, 2.5),
        const Radius.circular(1),
      ),
      _primaryFillPaint,
    );
  }

  void _paintMotorcycle(Canvas canvas) {
    // 1. Dual-alpha hardware drop shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-11, -23, 22, 48),
        const Radius.circular(11),
      ),
      _shadowOuterPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -21, 18, 44),
        const Radius.circular(9),
      ),
      _shadowInnerPaint,
    );

    // 2. Headlight forward glow (zero shader allocation)
    if (showHeadlightGlow) {
      _path.reset();
      _path.moveTo(-4, -18);
      _path.lineTo(-12, -44);
      _path.lineTo(12, -44);
      _path.lineTo(4, -18);
      _path.close();
      canvas.drawPath(_path, _headlightBeamPaint);
    }

    // 3. Front Wheel & Tire
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, -23, 5, 11),
        const Radius.circular(2.5),
      ),
      _tirePaint,
    );
    canvas.drawLine(const Offset(0, -21), const Offset(0, -14), _rimPaint);

    // 4. Front Mudguard & Fairing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.5, -16, 7, 5),
        const Radius.circular(2),
      ),
      _primaryFillPaint,
    );

    // 5. Front Headlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, -17, 5, 2.5),
        const Radius.circular(1),
      ),
      _headlightPaint,
    );

    // 6. Handlebars & Mirrors
    canvas.drawLine(
      const Offset(-10, -11),
      const Offset(10, -11),
      _handlebarPaint,
    );

    // Rubber Hand Grips
    canvas.drawLine(
      const Offset(-11.5, -11),
      const Offset(-8, -11),
      _gripPaint,
    );
    canvas.drawLine(
      const Offset(8, -11),
      const Offset(11.5, -11),
      _gripPaint,
    );

    // Side Mirrors
    canvas.drawCircle(const Offset(-11.5, -14), 1.8, _mirrorPaint);
    canvas.drawCircle(const Offset(-11.5, -14), 1.8, _mirrorStroke);
    canvas.drawCircle(const Offset(11.5, -14), 1.8, _mirrorPaint);
    canvas.drawCircle(const Offset(11.5, -14), 1.8, _mirrorStroke);

    // 7. Rider Shoulders & Uniform
    _path.reset();
    _path.moveTo(-8, 3);
    _path.quadraticBezierTo(-8, -8, 0, -8);
    _path.quadraticBezierTo(8, -8, 8, 3);
    _path.close();
    canvas.drawPath(_path, _jacketPaint);

    // Brand accent stripes on rider shoulders
    canvas.drawLine(
      const Offset(-7, -4),
      const Offset(-4, -6),
      _primaryStrokePaint,
    );
    canvas.drawLine(
      const Offset(7, -4),
      const Offset(4, -6),
      _primaryStrokePaint,
    );

    // 8. Rider Helmet (Top-Down with aerodynamic shape & visor)
    canvas.drawOval(const Rect.fromLTWH(-5.5, -10, 11, 13), _helmetPaint);
    canvas.drawOval(
      const Rect.fromLTWH(-5.5, -10, 11, 13),
      _helmetStrokePaint,
    );

    // Helmet Dark Tinted Visor
    _path.reset();
    _path.moveTo(-4.5, -7);
    _path.quadraticBezierTo(0, -10.5, 4.5, -7);
    _path.quadraticBezierTo(0, -8.5, -4.5, -7);
    _path.close();
    canvas.drawPath(_path, _visorPaint);

    canvas.drawLine(
      const Offset(0, -6),
      const Offset(0, 0),
      _primaryStrokePaint,
    );

    // 9. Rear Wheel / Fender
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, 17, 5, 8),
        const Radius.circular(2),
      ),
      _tirePaint,
    );

    // 10. Delivery Cargo Box (Custom Delivery) OR Passenger Saddle (Ride)
    if (showCargoBox) {
      final boxRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8.5, 5, 17, 15),
        const Radius.circular(3),
      );
      canvas.drawRRect(boxRRect, _primaryFillPaint);
      canvas.drawRRect(boxRRect, _boxStrokePaint);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, 6.5, 14, 12),
          const Radius.circular(2),
        ),
        _boxDetailPaint,
      );
      canvas.drawCircle(const Offset(0, 12.5), 2.2, _emblemPaint);
    } else {
      // Sleek tapered passenger saddle for Ride motorcycles
      final saddleRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-5.5, 3, 11, 15),
        const Radius.circular(4),
      );
      canvas.drawRRect(saddleRRect, _seatPaint);
      canvas.drawRRect(saddleRRect, _carBodyStroke);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, 15.5, 6, 3),
          const Radius.circular(1.5),
        ),
        _primaryFillPaint,
      );
    }

    // 11. Rear LED Brake Light
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3.5, 20, 7, 2.5),
        const Radius.circular(1),
      ),
      _taillightPaint,
    );
  }

  void _paintBicycle(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-7, -22, 14, 44),
        const Radius.circular(7),
      ),
      _shadowInnerPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-1.5, -21, 3, 11),
        const Radius.circular(1.5),
      ),
      _tirePaint,
    );

    canvas.drawLine(
      const Offset(-8, -10),
      const Offset(8, -10),
      _bicycleBarPaint,
    );

    canvas.drawOval(const Rect.fromLTWH(-6, -6, 12, 12), _jacketPaint);
    canvas.drawOval(const Rect.fromLTWH(-4, -9, 8, 10), _primaryFillPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6.5, 4, 13, 11),
        const Radius.circular(2.5),
      ),
      _visorPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-1.5, 14, 3, 10),
        const Radius.circular(1.5),
      ),
      _tirePaint,
    );

    canvas.drawCircle(const Offset(0, 16), 1.5, _taillightPaint);
  }

  void _paintMinibus(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-15.5, -27, 31, 58),
        const Radius.circular(8),
      ),
      _shadowInnerPaint,
    );

    if (showHeadlightGlow) {
      _path.reset();
      _path.moveTo(-11, -26);
      _path.lineTo(-18, -50);
      _path.lineTo(-4, -50);
      _path.lineTo(-7, -26);
      _path.close();
      canvas.drawPath(_path, _headlightBeamPaint);

      _path.reset();
      _path.moveTo(7, -26);
      _path.lineTo(4, -50);
      _path.lineTo(18, -50);
      _path.lineTo(11, -26);
      _path.close();
      canvas.drawPath(_path, _headlightBeamPaint);
    }

    canvas.drawRect(const Rect.fromLTWH(-17.5, -14, 4, 3), _mirrorPaint);
    canvas.drawRect(const Rect.fromLTWH(13.5, -14, 4, 3), _mirrorPaint);

    _path.reset();
    _path.moveTo(-13.5, -25);
    _path.quadraticBezierTo(0, -28, 13.5, -25);
    _path.lineTo(13.5, 28);
    _path.quadraticBezierTo(0, 29.5, -13.5, 28);
    _path.close();
    canvas.drawPath(_path, _carBodyPaint);
    canvas.drawPath(_path, _carBodyStroke);

    // Wide panoramic front windshield
    _path.reset();
    _path.moveTo(-11, -18);
    _path.lineTo(11, -18);
    _path.lineTo(11.8, -10);
    _path.lineTo(-11.8, -10);
    _path.close();
    canvas.drawPath(_path, _glassPaint);
    canvas.drawLine(const Offset(-5, -16), const Offset(3, -11), _glassHighlightPaint);

    // Side passenger windows & roof AC hatch
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-12.5, -6, 2.2, 26),
        const Radius.circular(1),
      ),
      _glassPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10.3, -6, 2.2, 26),
        const Radius.circular(1),
      ),
      _glassPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, -2, 12, 9),
        const Radius.circular(2.5),
      ),
      _carBodyStroke,
    );

    canvas.drawRect(const Rect.fromLTWH(-13.5, 13, 27, 4), _primaryFillPaint);

    // Rear window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9.5, 22, 19, 3.5),
        const Radius.circular(1),
      ),
      _glassPaint,
    );

    canvas.drawRect(const Rect.fromLTWH(-12, -26.5, 4, 2.5), _headlightPaint);
    canvas.drawRect(const Rect.fromLTWH(8, -26.5, 4, 2.5), _headlightPaint);
    canvas.drawRect(const Rect.fromLTWH(-12.5, 26.5, 3.5, 2), _taillightPaint);
    canvas.drawRect(const Rect.fromLTWH(9, 26.5, 3.5, 2), _taillightPaint);
  }

  void _paintTukTuk(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13, -21, 26, 44),
        const Radius.circular(10),
      ),
      _shadowInnerPaint,
    );

    if (showHeadlightGlow) {
      _path.reset();
      _path.moveTo(-4, -22);
      _path.lineTo(-11, -44);
      _path.lineTo(11, -44);
      _path.lineTo(4, -22);
      _path.close();
      canvas.drawPath(_path, _headlightBeamPaint);
    }

    // Single front wheel + two rear wheels
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, -22, 5, 9),
        const Radius.circular(2),
      ),
      _tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13.5, 9, 3.5, 10),
        const Radius.circular(1.5),
      ),
      _tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 9, 3.5, 10),
        const Radius.circular(1.5),
      ),
      _tirePaint,
    );

    // Tapered 3-wheel canopy body
    _path.reset();
    _path.moveTo(-6, -18);
    _path.quadraticBezierTo(0, -21, 6, -18);
    _path.lineTo(11.5, -5);
    _path.lineTo(11.5, 19);
    _path.quadraticBezierTo(0, 21.5, -11.5, 19);
    _path.lineTo(-11.5, -5);
    _path.close();
    canvas.drawPath(_path, _primaryFillPaint);
    canvas.drawPath(_path, _carBodyStroke);

    // Curved front windshield
    _path.reset();
    _path.moveTo(-7.5, -11);
    _path.quadraticBezierTo(0, -14, 7.5, -11);
    _path.lineTo(9, -5.5);
    _path.lineTo(-9, -5.5);
    _path.close();
    canvas.drawPath(_path, _glassPaint);

    // Canopy roof panel accent
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8.5, -2, 17, 17),
        const Radius.circular(3),
      ),
      _carBodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-8.5, -2, 17, 17),
        const Radius.circular(3),
      ),
      _carBodyStroke,
    );

    // Central headlight + dual taillights
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-3, -20, 6, 2.5),
        const Radius.circular(1),
      ),
      _headlightPaint,
    );
    canvas.drawRect(const Rect.fromLTWH(-9.5, 18.5, 3.5, 2), _taillightPaint);
    canvas.drawRect(const Rect.fromLTWH(6, 18.5, 3.5, 2), _taillightPaint);
  }

  void _paintPickupTruck(Canvas canvas, {required bool isHalfTon}) {
    final halfWidth = isHalfTon ? 15.0 : 13.5;
    final bodyTop = isHalfTon ? -26.0 : -24.0;
    final bodyBottom = isHalfTon ? 28.5 : 25.5;
    final bedTop = isHalfTon ? -1.0 : 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          -halfWidth - 2,
          bodyTop - 1,
          halfWidth + 2,
          bodyBottom + 2,
        ),
        const Radius.circular(7),
      ),
      _shadowInnerPaint,
    );

    if (showHeadlightGlow) {
      _path.reset();
      _path.moveTo(-halfWidth + 2, bodyTop);
      _path.lineTo(-halfWidth - 5, bodyTop - 24);
      _path.lineTo(-4, bodyTop - 24);
      _path.lineTo(-7, bodyTop);
      _path.close();
      canvas.drawPath(_path, _headlightBeamPaint);

      _path.reset();
      _path.moveTo(7, bodyTop);
      _path.lineTo(4, bodyTop - 24);
      _path.lineTo(halfWidth + 5, bodyTop - 24);
      _path.lineTo(halfWidth - 2, bodyTop);
      _path.close();
      canvas.drawPath(_path, _headlightBeamPaint);
    }

    canvas.drawRect(Rect.fromLTWH(-halfWidth - 3.5, -13, 3.5, 3), _mirrorPaint);
    canvas.drawRect(Rect.fromLTWH(halfWidth, -13, 3.5, 3), _mirrorPaint);

    // Front cab
    _path.reset();
    _path.moveTo(-halfWidth, bodyTop + 2);
    _path.quadraticBezierTo(0, bodyTop - 2, halfWidth, bodyTop + 2);
    _path.lineTo(halfWidth, bedTop);
    _path.lineTo(-halfWidth, bedTop);
    _path.close();
    canvas.drawPath(_path, _carBodyPaint);
    canvas.drawPath(_path, _carBodyStroke);

    // Windshield
    _path.reset();
    _path.moveTo(-halfWidth + 2.5, bodyTop + 8);
    _path.lineTo(halfWidth - 2.5, bodyTop + 8);
    _path.lineTo(halfWidth - 1.5, bodyTop + 15.5);
    _path.lineTo(-halfWidth + 1.5, bodyTop + 15.5);
    _path.close();
    canvas.drawPath(_path, _glassPaint);
    canvas.drawLine(
      Offset(-4.5, bodyTop + 10),
      Offset(2.5, bodyTop + 14.5),
      _glassHighlightPaint,
    );

    // Open pickup cargo bed
    final bedOuter = RRect.fromRectAndRadius(
      Rect.fromLTRB(-halfWidth, bedTop, halfWidth, bodyBottom),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(bedOuter, _primaryFillPaint);
    canvas.drawRRect(bedOuter, _bedBorderPaint);

    // Inner bed floor + structural ribs
    final innerBed = Rect.fromLTRB(
      -halfWidth + 2.5,
      bedTop + 2.5,
      halfWidth - 2.5,
      bodyBottom - 2.5,
    );
    canvas.drawRect(innerBed, _bedInnerFloorPaint);

    final ribCount = isHalfTon ? 3 : 2;
    for (var i = 1; i <= ribCount; i++) {
      final y = bedTop + ((bodyBottom - bedTop) * i / (ribCount + 1));
      canvas.drawLine(
        Offset(-halfWidth + 3, y),
        Offset(halfWidth - 3, y),
        _bedRibPaint,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(-halfWidth + 1, bodyTop, 4, 2.5),
      _headlightPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(halfWidth - 5, bodyTop, 4, 2.5),
      _headlightPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(-halfWidth + 1, bodyBottom - 2, 3.5, 2),
      _taillightPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(halfWidth - 4.5, bodyBottom - 2, 3.5, 2),
      _taillightPaint,
    );
  }

  void _paintMotorTricycle(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, -20, 28, 44),
        const Radius.circular(8),
      ),
      _shadowInnerPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, -21, 5, 10),
        const Radius.circular(2),
      ),
      _tirePaint,
    );

    canvas.drawLine(
      const Offset(-9, -11),
      const Offset(9, -11),
      _handlebarPaint,
    );

    canvas.drawCircle(const Offset(0, -4), 5.5, _carBodyPaint);
    canvas.drawCircle(const Offset(0, -4), 5.5, _carBodyStroke);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-13.5, 10, 3.5, 10),
        const Radius.circular(1.5),
      ),
      _tirePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 10, 3.5, 10),
        const Radius.circular(1.5),
      ),
      _tirePaint,
    );

    final bedRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-10, 3, 20, 19),
      const Radius.circular(2),
    );
    canvas.drawRRect(bedRect, _primaryFillPaint);
    canvas.drawRRect(bedRect, _boxStrokePaint);

    canvas.drawRect(const Rect.fromLTWH(-9.5, 20.5, 3.5, 2), _taillightPaint);
    canvas.drawRect(const Rect.fromLTWH(6, 20.5, 3.5, 2), _taillightPaint);
  }

  @override
  bool shouldRepaint(covariant InDriveVehiclePainter oldDelegate) {
    return oldDelegate.vehicleType != vehicleType ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.showHeadlightGlow != showHeadlightGlow ||
        oldDelegate.isMoving != isMoving ||
        oldDelegate.showCargoBox != showCargoBox;
  }
}

/// Backward-compatible driver marker wrapper.
class LiveWalkingDriverMarker extends StatelessWidget {
  final double size;
  final Color color;
  final double heading; // 0 - 360 degrees
  final bool isWalking;
  final String? label;
  final String? vehicleType;
  final String? plateNumber;
  final String? driverName;

  const LiveWalkingDriverMarker({
    super.key,
    this.size = 54.0,
    this.color = const Color(0xFFF59E0B),
    this.heading = 0.0,
    this.isWalking = false,
    this.label,
    this.vehicleType = 'MOTORCYCLE',
    this.plateNumber,
    this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    return InDriveVehicleMarker(
      size: size,
      color: color,
      heading: heading,
      isMoving: isWalking,
      label: label,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      driverName: driverName,
    );
  }
}

/// A modern, elevated navigation pin for destinations, stores, and customers.
class NavigationPinMarker extends StatelessWidget {
  final IconData icon;
  final Color pinColor;
  final Color iconColor;
  final double size;
  final String? badgeText;

  const NavigationPinMarker({
    super.key,
    this.icon = LucideIcons.mapPin,
    this.pinColor = const Color(0xFFEF4444), // Vibrant Red
    this.iconColor = Colors.white,
    this.size = 38.0,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pin drop shadow
          Positioned(
            bottom: 2,
            child: Container(
              width: size * 0.35,
              height: size * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(size * 0.35, size * 0.15)),
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Pin head
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: pinColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.45),
          ),
          // Optional stop index badge
          if (badgeText != null)
            Positioned(
              top: 0,
              right: 0,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.black87,
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
