import 'package:flutter/material.dart';

/// Shared outlined social sign-in button with consistent typography, height,
/// and 24x24 icon alignment across Customer, Driver, and Vendor Admin apps.
class SocialAuthButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const SocialAuthButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: double.infinity,
        minHeight: height,
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: onSurface.withValues(alpha: 0.2),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(child: icon),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
