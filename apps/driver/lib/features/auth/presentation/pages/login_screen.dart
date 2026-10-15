import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/providers/app_preferences_provider.dart';
import 'package:driver/core/utils/error_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  @override
  void initState() {
    super.initState();
    ref.listen<AsyncValue<bool>>(authProvider, (previous, state) async {
      if (!mounted) return;
      if (!state.isLoading && state.hasValue && state.value == true) {
        ref.invalidate(splashProvider);
        ref.invalidate(driverProfileProvider);
        context.go('/');
      } else if (state.hasError && state.error != null) {
        final displayMessage = ErrorUtils.translate(context, state.error);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThemeToggle(context),
                    const SizedBox(width: 8),
                    _buildLanguageToggle(context),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.package,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)?.appName ?? 'Otlob Driver',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    CustomTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      label: l10n.emailAddress,
                      hintText: l10n.emailHint,
                    ),
                    CustomTextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      label: l10n.password,
                      hintText: '********',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(authProvider);
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: PrimaryButton(
                            isLoading: state.isLoading,
                            onPressed: state.isLoading
                                ? null
                                : () {
                                    ref
                                        .read(authProvider.notifier)
                                        .login(
                                          _emailController.text
                                              .trim()
                                              .toLowerCase(),
                                          _passwordController.text,
                                        );
                                  },
                            text: l10n.signIn,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            l10n.or,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(authProvider);
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: state.isLoading
                                ? null
                                : () => ref
                                    .read(authProvider.notifier)
                                    .loginWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.continueWithGoogle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final prefs = ref.watch(appPreferencesProvider);
        final isDark = prefs.themeMode == ThemeMode.dark;
        return InkWell(
          onTap: () => ref.read(appPreferencesProvider.notifier).toggleTheme(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              size: 16,
              color: Colors.amber,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageToggle(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final prefs = ref.watch(appPreferencesProvider);
        final isArabic = prefs.locale.languageCode == 'ar';
        return InkWell(
          onTap: () => ref.read(appPreferencesProvider.notifier).setLocale(isArabic ? 'en' : 'ar'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.languages,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'EN' : 'AR',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

