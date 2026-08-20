import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../theme/app_radius.dart';

class OtpInputWidget extends StatelessWidget {
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final bool hasError;

  const OtpInputWidget({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.obscureText = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasError ? theme.colorScheme.error : Colors.transparent,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: theme.colorScheme.primary, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
    );

    return Pinput(
      length: length,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: submittedPinTheme,
      obscureText: obscureText,
      onCompleted: onCompleted,
      onChanged: onChanged,
      showCursor: true,
      cursor: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            width: 22,
            height: 2,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
