import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class DashboardSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final String? hintText;
  final double height;

  const DashboardSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText,
    this.height = 50,
  });

  @override
  State<DashboardSearchBar> createState() => _DashboardSearchBarState();
}

class _DashboardSearchBarState extends State<DashboardSearchBar> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant DashboardSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _isFocused
            ? (isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.10)
                  : theme.colorScheme.surface)
            : (isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.035)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary
              : (isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          width: _isFocused ? 1.5 : 1.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText ?? AppLocalizations.of(context)!.search,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            prefixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                LucideIcons.search,
                key: ValueKey(_isFocused),
                size: 19,
                color: _isFocused
                    ? AppColors.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? Container(
                    margin: const EdgeInsetsDirectional.only(end: 4),
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onClear();
                      },
                      splashRadius: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          ),
        ),
      ),
    );
  }
}

