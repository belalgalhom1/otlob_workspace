import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// An adaptive chevron icon that points forward in both LTR (Right) and RTL (Left).
class AppAdaptiveChevron extends StatelessWidget {
  final double size;
  final Color? color;

  const AppAdaptiveChevron({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final iconColor = color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    return Icon(
      isRtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
      size: size,
      color: iconColor,
    );
  }
}
