import 'package:flutter/material.dart';

/// Horizontally scrollable button/chip strip that adapts to ambient [Directionality]:
/// - English (LTR): anchors items on the left and scrolls toward the right.
/// - Arabic (RTL): anchors items on the right and scrolls toward the left.
///
/// Resets its scroll offset to the leading edge (`0.0`) whenever [Directionality]
/// changes (for example when toggling EN/AR in-place).
class HorizontalActionStrip extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;

  const HorizontalActionStrip({
    super.key,
    required this.children,
    this.spacing = 8,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  @override
  State<HorizontalActionStrip> createState() => _HorizontalActionStripState();
}

class _HorizontalActionStripState extends State<HorizontalActionStrip> {
  final ScrollController _controller = ScrollController();
  TextDirection? _lastDirection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentDirection = Directionality.of(context);
    if (_lastDirection != null && _lastDirection != currentDirection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpTo(0.0);
        }
      });
    }
    _lastDirection = currentDirection;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveMinWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 0.0;
        return SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: widget.physics ??
              const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
          padding: widget.padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: effectiveMinWidth),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.children.length; i++) ...[
                    if (i > 0) SizedBox(width: widget.spacing),
                    widget.children[i],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
