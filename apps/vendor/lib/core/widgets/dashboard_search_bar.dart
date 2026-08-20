import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class DashboardSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final String? hintText;

  const DashboardSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText,
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
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _isFocused
            ? (isDark
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
                  : theme.colorScheme.surface)
            : (isDark
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? AppColors.primary
              : (isDark
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          width: 1.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText ?? AppLocalizations.of(context)!.search,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                LucideIcons.search,
                key: ValueKey(_isFocused),
                size: 20,
                color: _isFocused
                    ? AppColors.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? Container(
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    child: IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onClear();
                      },
                      splashRadius: 24,
                      color: theme.colorScheme.onSurface,
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

