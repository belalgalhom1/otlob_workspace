import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Presentation guard that enforces a minimum viewport size and aspect ratio
/// across all applications in the monorepo.
///
/// Prevents the layout canvas from collapsing below the smallest supported
/// mobile dimensions (default: 360x600 logical pixels).
///
/// When a user resizes a desktop, WSA freeform window, or browser viewport below
/// these dimensions, this guard ensures the UI never produces RenderFlex
/// overflows, broken layouts, or unclickable controls by clamping the canvas
/// to the minimum mobile size and scaling it down smoothly.
class AppWindowConstraintGuard extends StatelessWidget {
  final Widget child;
  final double minWidth;
  final double minHeight;
  final double minTextScaleFactor;
  final double maxTextScaleFactor;
  final Alignment alignment;

  const AppWindowConstraintGuard({
    super.key,
    required this.child,
    this.minWidth = 360.0,
    this.minHeight = 600.0,
    this.minTextScaleFactor = 0.85,
    this.maxTextScaleFactor = 1.3,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: minTextScaleFactor,
      maxScaleFactor: maxTextScaleFactor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final currentWidth = constraints.maxWidth;
        final currentHeight = constraints.maxHeight;

        // If constraints are unconstrained or safely above minimums, passthrough
        // with bounded text scaling while preserving device insets and size.
        final isTooNarrow = currentWidth.isFinite && currentWidth < minWidth;
        final isTooShort = currentHeight.isFinite && currentHeight < minHeight;

        if (!isTooNarrow && !isTooShort) {
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedTextScaler),
            child: child,
          );
        }

        // Clamp to minimum mobile dimensions
        final effectiveWidth = math.max(currentWidth, minWidth);
        final effectiveHeight = math.max(currentHeight, minHeight);

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: alignment,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: SizedBox(
              width: effectiveWidth,
              height: effectiveHeight,
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  size: Size(effectiveWidth, effectiveHeight),
                  textScaler: clampedTextScaler,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
