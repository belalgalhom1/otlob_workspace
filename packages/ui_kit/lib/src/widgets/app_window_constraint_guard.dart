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
  final Alignment alignment;

  const AppWindowConstraintGuard({
    super.key,
    required this.child,
    this.minWidth = 360.0,
    this.minHeight = 600.0,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentWidth = constraints.maxWidth;
        final currentHeight = constraints.maxHeight;

        // If constraints are unconstrained or safely above minimums, passthrough
        final isTooNarrow = currentWidth.isFinite && currentWidth < minWidth;
        final isTooShort = currentHeight.isFinite && currentHeight < minHeight;

        if (!isTooNarrow && !isTooShort) {
          return child;
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
                data: MediaQuery.of(context).copyWith(
                  size: Size(effectiveWidth, effectiveHeight),
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
