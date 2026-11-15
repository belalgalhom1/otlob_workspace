import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';
import '../router/route_paths.dart';

class AuthPromptDialog extends StatelessWidget {
  const AuthPromptDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthPromptDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24).copyWith(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            // Illustration/Icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              s.authRequiredTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: s.isArabic ? null : -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              s.authRequiredMessage,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(RoutePaths.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    s.login,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(RoutePaths.register);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    s.register,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                s.cancel,
                style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
