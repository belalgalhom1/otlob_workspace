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
    return AnimatedBuilder(
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
    );
  }
}

/// A lifelike, animated driver marker for customer tracking screens.
///
/// Features:
/// - Smooth walking/striding vertical bobbing when [isWalking] is true.
/// - Directional heading orientation pointing along the street trajectory.
/// - Radar aura wave pulse effect underneath.
/// - Floating driver badge / pill label.
class LiveWalkingDriverMarker extends StatefulWidget {
  final double size;
  final Color color;
  final double heading; // 0 - 360 degrees
  final bool isWalking;
  final String? label;

  const LiveWalkingDriverMarker({
    super.key,
    this.size = 48.0,
    this.color = const Color(0xFFF59E0B), // Otlob Primary Yellow
    this.heading = 0.0,
    this.isWalking = false,
    this.label,
  });

  @override
  State<LiveWalkingDriverMarker> createState() => _LiveWalkingDriverMarkerState();
}

class _LiveWalkingDriverMarkerState extends State<LiveWalkingDriverMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _walkAnimController;
  late Animation<double> _bobAnimation;

  @override
  void initState() {
    super.initState();
    _walkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _bobAnimation = Tween<double>(begin: 0.0, end: -5.0).animate(
      CurvedAnimation(parent: _walkAnimController, curve: Curves.easeInOutSine),
    );

    if (widget.isWalking) {
      _walkAnimController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant LiveWalkingDriverMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWalking && !_walkAnimController.isAnimating) {
      _walkAnimController.repeat(reverse: true);
    } else if (!widget.isWalking && _walkAnimController.isAnimating) {
      _walkAnimController.stop();
      _walkAnimController.animateTo(0.0);
    }
  }

  @override
  void dispose() {
    _walkAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bobAnimation,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating label pill (if provided)
            if (widget.label != null && widget.label!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: widget.color, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
            // Bobbing courier icon
            Transform.translate(
              offset: Offset(0, widget.isWalking ? _bobAnimation.value : 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ground drop shadow
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: widget.size * 0.7,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  // Pulse ring
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.22),
                    ),
                  ),
                  // White circular base with vehicle / navigation pointer
                  Container(
                    width: widget.size * 0.8,
                    height: widget.size * 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color,
                        ),
                        child: Transform.rotate(
                          angle: widget.heading * 3.141592653589793 / 180.0,
                          child: const Icon(
                            LucideIcons.navigation,
                            size: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
