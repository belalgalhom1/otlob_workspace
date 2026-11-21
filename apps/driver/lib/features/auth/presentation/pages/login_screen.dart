import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAppleSignInPressed(BuildContext context, AppLocalizations l10n) {
    // UI-only placeholder until Sign in with Apple authentication is enabled.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.appleSignInComingSoon)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AsyncValue<bool>>(authProvider, (previous, state) {
      if (!mounted) return;
      if (!state.isLoading && state.hasValue && state.value == true) {
        final startupState = ref.read(driverPostLoginStateProvider);
        switch (startupState) {
          case AppStartupState.suspended:
            context.go('/suspended');
            break;
          case AppStartupState.needsTerms:
            context.go('/terms-acceptance');
            break;
          case AppStartupState.activeOrder:
            context.go('/order-execution');
            break;
          default:
            context.go('/dashboard');
            break;
        }
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const signTopOffset = 4.0;
    final topClearance = OtlobLoginWelcomeOverlay.recommendedTopClearance(
      context,
      signTopOffset: signTopOffset,
      gap: 18.0,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeToggle(context),
                const SizedBox(width: 8),
                _buildLanguageToggle(context),
              ],
            ),
          ),
        ],
      ),
      body: OtlobLoginWelcomeOverlay(
        signTopOffset: signTopOffset,
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(24.0, topClearance, 24.0, 24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: OtlobBrandHeroLogo(
                        child: Image.asset(
                          'assets/logo_without_background.png',
                          height: 124,
                          fit: BoxFit.contain,
                          color: isDark
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          colorBlendMode: isDark ? BlendMode.srcIn : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        AppLocalizations.of(context)?.appName ?? 'Otlob Driver',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

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
                    const SizedBox(height: 24),
                    Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(authProvider);
                        return ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              isLoading: state.isLoading,
                              onPressed: state.isLoading
                                  ? null
                                  : () {
                                      ref.read(authProvider.notifier).login(
                                            _emailController.text
                                                .trim()
                                                .toLowerCase(),
                                            _passwordController.text,
                                          );
                                    },
                              text: l10n.signIn,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 18),
                    Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(authProvider);
                        return Column(
                          children: [
                            SocialAuthButton(
                              height: 56,
                              label: l10n.continueWithGoogle,
                              onPressed: state.isLoading
                                  ? null
                                  : () => ref
                                      .read(authProvider.notifier)
                                      .loginWithGoogle(),
                              icon: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4285F4),
                                  height: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SocialAuthButton(
                              height: 56,
                              label: l10n.continueWithApple,
                              onPressed: state.isLoading
                                  ? null
                                  : () => _onAppleSignInPressed(context, l10n),
                              icon: Icon(
                                Icons.apple,
                                size: 24,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'بتسجيل الدخول، فإنك توافق على '
                                : 'By signing in, you agree to the ',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          InkWell(
                            onTap: () => context.push(
                              '/legal-document',
                              extra: {
                                'type': 'TERMS_OF_USE',
                                'title': l10n.terms,
                              },
                            ),
                            child: Text(
                              l10n.terms,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                          Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? ' و '
                                : ' and ',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          InkWell(
                            onTap: () => context.push(
                              '/legal-document',
                              extra: {
                                'type': 'PRIVACY_POLICY',
                                'title': l10n.privacy,
                              },
                            ),
                            child: Text(
                              l10n.privacy,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final prefs = ref.watch(appPreferencesProvider);
        final isDark = prefs.themeMode == ThemeMode.dark;
        return Material(
          color: Colors.transparent,
          child: InkWell(
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
        ));
      },
    );
  }

  Widget _buildLanguageToggle(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final prefs = ref.watch(appPreferencesProvider);
        final isArabic = prefs.locale.languageCode == 'ar';
        return Material(
          color: Colors.transparent,
          child: InkWell(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            ref.read(appPreferencesProvider.notifier).setLocale(isArabic ? 'en' : 'ar');
          },
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
        ));
      },
    );
  }
}

