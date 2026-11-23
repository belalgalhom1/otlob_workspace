import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shared app-wide text interaction scope for all Otlob Flutter applications
/// (Customer, Driver, and Vendor Admin).
///
/// Dismisses keyboard focus when the user taps outside of any editable text
/// field while preserving full platform-standard text-selection behavior on
/// both Android and iOS:
/// - Long-press to select text and open the selection toolbar
/// - Copy, Cut, Paste, and Select All toolbar actions
/// - Dragging selection handles and repositioning the cursor
///
/// Unlike a raw root [Listener.onPointerDown] that unfocuses unconditionally
/// (which cancels long-press selection and dismisses selection menus before
/// button taps register), overriding [EditableTextTapOutsideIntent] respects
/// Flutter's [TextFieldTapRegion] group (the text field itself, its selection
/// handles, and its floating selection toolbar).
class AppTextInteractionScope extends StatelessWidget {
  final Widget child;

  const AppTextInteractionScope({
    super.key,
    required this.child,
  });

  /// Applies legible, brand-consistent cursor, selection highlight, and
  /// selection handle colors to [baseTheme] without altering any other theme
  /// tokens or widget styling.
  static ThemeData applySelectionTheme(ThemeData baseTheme) {
    final isDark = baseTheme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.primary : AppColors.primaryVariant;

    return baseTheme.copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.30),
        selectionHandleColor: accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        EditableTextTapOutsideIntent:
            CallbackAction<EditableTextTapOutsideIntent>(
          onInvoke: (intent) {
            intent.focusNode.unfocus();
            return null;
          },
        ),
      },
      child: child,
    );
  }
}
