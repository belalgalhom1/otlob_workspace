import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';

/// Presentation model for a single stage on [OrderStatusProgressLine].
class OrderProgressStepItem {
  final String label;
  final IconData icon;

  const OrderProgressStepItem({
    required this.label,
    required this.icon,
  });
}

/// Reusable, presentation-only multi-stage order progress timeline.
///
/// Adapts automatically between a full-width balanced row on wide screens and
/// an auto-centering horizontal track on compact phones so 6–8 lifecycle
/// stages remain crisp and readable in both LTR English and RTL Arabic.
class OrderStatusProgressLine extends StatefulWidget {
  final List<OrderProgressStepItem> steps;
  final int currentStep;
  final String? activeStatusLabel;
  final EdgeInsetsGeometry margin;
  final Color? accentColor;

  const OrderStatusProgressLine({
    super.key,
    required this.steps,
    required this.currentStep,
    this.activeStatusLabel,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
    this.accentColor,
  });

  /// Presentation-only icon mapping for canonical lifecycle stage keys.
  static IconData iconForStageKey(String key) {
    switch (key.trim().toUpperCase()) {
      case 'PENDING':
        return LucideIcons.shoppingBag;
      case 'ACCEPTED':
        return LucideIcons.checkCheck;
      case 'LOOKING_FOR_DRIVER':
        return LucideIcons.search;
      case 'DRIVER_ASSIGNED':
      case 'PENDING_PAYMENT':
        return LucideIcons.user;
      case 'PREPARING':
        return LucideIcons.store;
      case 'READY_FOR_PICKUP':
        return LucideIcons.packageCheck;
      case 'PICKED_UP':
      case 'PARTIALLY_PICKED_UP':
        return LucideIcons.truck;
      case 'DELIVERED':
        return LucideIcons.mapPin;
      default:
        return LucideIcons.clock;
    }
  }

  @override
  State<OrderStatusProgressLine> createState() =>
      _OrderStatusProgressLineState();
}

class _OrderStatusProgressLineState extends State<OrderStatusProgressLine> {
  static const double _baseStepWidth = 76.0;
  final ScrollController _scrollController = ScrollController();
  double _lastViewportWidth = 0;
  double _lastStepWidth = _baseStepWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerActiveStep(animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant OrderStatusProgressLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStep != widget.currentStep ||
        oldWidget.steps.length != widget.steps.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerActiveStep(animate: true);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerActiveStep({required bool animate}) {
    if (!mounted || !_scrollController.hasClients || widget.steps.isEmpty) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final clamped = widget.currentStep.clamp(0, widget.steps.length - 1);
    final viewport = _lastViewportWidth > 0
        ? _lastViewportWidth
        : _scrollController.position.viewportDimension;
    final targetCenter = (clamped * _lastStepWidth) + (_lastStepWidth / 2);
    final desiredOffset = (targetCenter - (viewport / 2)).clamp(0.0, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        desiredOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(desiredOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty || widget.currentStep < 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clampedStep = widget.currentStep.clamp(0, widget.steps.length - 1);
    final isFinalCompleted = clampedStep == widget.steps.length - 1;
    final baseAccent = widget.accentColor ?? AppColors.primary;
    final activeAccent = isFinalCompleted ? AppColors.success : baseAccent;
    final checkInk = isFinalCompleted ? Colors.white : AppColors.onPrimary;

    final bgColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.grey.shade50;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final inactiveLineColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    final inactiveNodeBg = isDark
        ? const Color(0xFF232323)
        : Colors.white;
    final inactiveNodeBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.16);
    final inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.35);
    final completedLabelColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : Colors.black.withValues(alpha: 0.78);
    final upcomingLabelColor = isDark
        ? Colors.white.withValues(alpha: 0.38)
        : Colors.black.withValues(alpha: 0.4);

    final activeItem = widget.steps[clampedStep];
    final headerText = (widget.activeStatusLabel != null &&
            widget.activeStatusLabel!.trim().isNotEmpty)
        ? widget.activeStatusLabel!.trim()
        : activeItem.label;

    return Container(
      margin: widget.margin,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top compact status header + numeric step indicator
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: activeAccent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFinalCompleted ? LucideIcons.check : activeItem.icon,
                  size: 13,
                  color: activeAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  headerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: activeAccent.withValues(alpha: 0.28),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '${clampedStep + 1} / ${widget.steps.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: activeAccent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Responsive connected step track (adapts to TextScaler & width)
          LayoutBuilder(
            builder: (context, constraints) {
              final textScaleFactor =
                  (MediaQuery.textScalerOf(context).scale(10.5) / 10.5)
                      .clamp(1.0, 1.45);
              final stepWidth = (_baseStepWidth * textScaleFactor).ceilToDouble();
              _lastStepWidth = stepWidth;
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : widget.steps.length * stepWidth;
              _lastViewportWidth = maxWidth;
              final needsHorizontalScroll =
                  maxWidth < (widget.steps.length * stepWidth);

              Widget buildStepTile(int index) {
                final step = widget.steps[index];
                final isCompleted = index < clampedStep ||
                    (isFinalCompleted && index == clampedStep);
                final isCurrent = index == clampedStep && !isFinalCompleted;
                final isReached = index <= clampedStep;

                final leftLineColor = index == 0
                    ? Colors.transparent
                    : (isReached ? activeAccent : inactiveLineColor);
                final rightLineColor = index == widget.steps.length - 1
                    ? Colors.transparent
                    : (index < clampedStep ? activeAccent : inactiveLineColor);

                final nodeSize = isCurrent ? 28.0 : 24.0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 28,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2.5,
                              color: leftLineColor,
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: nodeSize,
                            height: nodeSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? activeAccent
                                  : (isCurrent
                                      ? activeAccent.withValues(alpha: 0.14)
                                      : inactiveNodeBg),
                              border: Border.all(
                                color: isReached
                                    ? activeAccent
                                    : inactiveNodeBorder,
                                width: isCurrent ? 2.2 : 1.5,
                              ),
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: activeAccent.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Icon(
                                isCompleted ? LucideIcons.check : step.icon,
                                size: isCompleted ? 13 : (isCurrent ? 13 : 11.5),
                                color: isCompleted
                                    ? checkInk
                                    : (isCurrent
                                        ? activeAccent
                                        : inactiveIconColor),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2.5,
                              color: rightLineColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        step.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.2,
                          fontWeight: isCurrent || isFinalCompleted && index == clampedStep
                              ? FontWeight.w700
                              : (isCompleted
                                  ? FontWeight.w600
                                  : FontWeight.w500),
                          color: isCurrent || (isFinalCompleted && index == clampedStep)
                              ? activeAccent
                              : (isCompleted
                                  ? completedLabelColor
                                  : upcomingLabelColor),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (!needsHorizontalScroll) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    widget.steps.length,
                    (index) => Expanded(child: buildStepTile(index)),
                  ),
                );
              }

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    widget.steps.length,
                    (index) => SizedBox(
                      width: stepWidth,
                      child: buildStepTile(index),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
