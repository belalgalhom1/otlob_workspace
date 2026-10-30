import 'package:flutter/material.dart';

/// A professional circular speed limit sign conforming to international/European
/// and Egyptian road regulation standards (White circle with bold red border
/// and black numerals), plus unit badge ('km/h' or 'mph').
///
/// If [speedLimit] is null or <= 0, the sign renders nothing or an empty box,
/// strictly adhering to the rule: "Never invent missing speed-limit information."
class SpeedLimitSign extends StatelessWidget {
  /// The maximum road speed limit in [unit].
  /// If null, the sign is not shown.
  final int? speedLimit;

  /// Current vehicle speed (optional). If provided, can show speed vs limit.
  final double? currentSpeed;

  /// Unit of speed, default is 'km/h'.
  final String unit;

  /// Diameter of the sign in logical pixels.
  final double size;

  /// Whether to display the speed limit in an elevated floating badge style.
  final bool showElevation;

  const SpeedLimitSign({
    super.key,
    required this.speedLimit,
    this.currentSpeed,
    this.unit = 'km/h',
    this.size = 54.0,
    this.showElevation = true,
  });

  @override
  Widget build(BuildContext context) {
    if (speedLimit == null || speedLimit! <= 0) {
      return const SizedBox.shrink();
    }

    final isOverSpeed = currentSpeed != null && currentSpeed! > (speedLimit! + 3);

    return Container(
      width: size,
      height: size + (size * 0.28), // slightly taller for unit badge
      decoration: showElevation
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Road Sign
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: isOverSpeed ? const Color(0xFFDC2626) : const Color(0xFFE11D48),
                width: size * 0.12, // Standard proportional thick red border
              ),
            ),
            child: Center(
              child: Text(
                '$speedLimit',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Unit pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              unit,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.18,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
