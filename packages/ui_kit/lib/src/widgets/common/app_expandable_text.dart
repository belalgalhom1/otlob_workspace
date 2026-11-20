import 'package:flutter/material.dart';

/// Reusable presentation widget that displays a limited line preview of [text]
/// and reveals a smooth animated "Read more / Read less" toggle only when the
/// rendered text actually exceeds [trimLines] at the current layout width and
/// [TextScaler].
class AppExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int trimLines;
  final String? readMoreLabel;
  final String? readLessLabel;
  final Color? toggleColor;
  final TextStyle? toggleStyle;
  final TextAlign? textAlign;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showChevron;

  const AppExpandableText({
    super.key,
    required this.text,
    this.style,
    this.trimLines = 3,
    this.readMoreLabel,
    this.readLessLabel,
    this.toggleColor,
    this.toggleStyle,
    this.textAlign,
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = Curves.easeInOutCubic,
    this.showChevron = true,
  }) : assert(trimLines > 0, 'trimLines must be greater than zero');

  @override
  State<AppExpandableText> createState() => _AppExpandableTextState();
}

class _AppExpandableTextState extends State<AppExpandableText> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(covariant AppExpandableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.trimLines != widget.trimLines) {
      _isExpanded = false;
    }
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.text.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    final isArabic =
        Localizations.maybeLocaleOf(context)?.languageCode == 'ar' ||
            Directionality.of(context) == TextDirection.rtl;
    final effectiveStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveDuration =
        reducedMotion ? Duration.zero : widget.animationDuration;
    final theme = Theme.of(context);
    final effectiveToggleColor =
        widget.toggleColor ?? theme.colorScheme.primary;
    final moreText =
        widget.readMoreLabel ?? (isArabic ? 'اقرأ المزيد' : 'Read more');
    final lessText =
        widget.readLessLabel ?? (isArabic ? 'عرض أقل' : 'Read less');
    final effectiveToggleStyle = widget.toggleStyle ??
        TextStyle(
          color: effectiveToggleColor,
          fontSize: ((effectiveStyle.fontSize ?? 14.0) - 1.5).clamp(12.0, 15.0),
          fontWeight: FontWeight.w700,
          height: 1.3,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final locale = Localizations.maybeLocaleOf(context);
        final textScaler = MediaQuery.textScalerOf(context);

        final painter = TextPainter(
          text: TextSpan(text: trimmed, style: effectiveStyle),
          maxLines: widget.trimLines,
          textDirection: textDirection,
          textScaler: textScaler,
          locale: locale,
          textAlign: widget.textAlign ?? TextAlign.start,
        )..layout(maxWidth: constraints.maxWidth);

        final hasOverflow = painter.didExceedMaxLines;
        painter.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: effectiveDuration,
              curve: widget.animationCurve,
              alignment: AlignmentDirectional.topStart,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  trimmed,
                  style: effectiveStyle,
                  textAlign: widget.textAlign ?? TextAlign.start,
                  maxLines:
                      (_isExpanded || !hasOverflow) ? null : widget.trimLines,
                  overflow: (_isExpanded || !hasOverflow)
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ),
            ),
            if (hasOverflow) ...[
              const SizedBox(height: 4),
              Semantics(
                button: true,
                expanded: _isExpanded,
                label: _isExpanded ? lessText : moreText,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggle,
                    borderRadius: BorderRadius.circular(8),
                    splashColor: effectiveToggleColor.withValues(alpha: 0.12),
                    highlightColor:
                        effectiveToggleColor.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? lessText : moreText,
                            style: effectiveToggleStyle,
                          ),
                          if (widget.showChevron) ...[
                            const SizedBox(width: 2),
                            AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0.0,
                              duration: effectiveDuration,
                              curve: widget.animationCurve,
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: effectiveToggleColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
