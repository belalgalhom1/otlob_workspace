import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.primary;
    final isCustomDark = effectiveBg == AppColors.error || effectiveBg == Colors.black || effectiveBg.computeLuminance() < 0.4;
    final effectiveFg = foregroundColor ?? (isCustomDark ? Colors.white : AppColors.onPrimary);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBg,
        foregroundColor: effectiveFg,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
              ),
            )
          : (icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: effectiveFg),
                    const SizedBox(width: 8),
                    Text(text, style: TextStyle(color: effectiveFg, fontWeight: FontWeight.bold)),
                  ],
                )
              : Text(text, style: TextStyle(color: effectiveFg, fontWeight: FontWeight.bold))),
    );
  }
}
