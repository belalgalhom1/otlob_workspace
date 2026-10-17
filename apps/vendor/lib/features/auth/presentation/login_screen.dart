import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:vendor/core/utils/error_utils.dart';

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

  Future<bool> _isMaintenanceBlocked(WidgetRef ref) async {
    try {
      final status = await checkAppStatus(
        ref.read(sharedPlatformSettingsRepositoryProvider),
      );
      return status?.maintenance == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AsyncValue<bool>>(authProvider, (previous, state) async {
      debugPrint('DEBUG: authProvider state changed to: isLoading=${state.isLoading}, hasValue=${state.hasValue}, value=${state.value}, hasError=${state.hasError}');
      if (!state.isLoading && state.hasValue && state.value == true) {
        debugPrint('DEBUG: Login successful! Checking role...');
        try {
          final repo = ref.read(sharedAuthRepositoryProvider);
          final role = await repo.getUserRole();
          debugPrint('DEBUG: Role is $role');
          if (role == 'VENDOR_MEMBER') {
            // Vendors stay frozen during maintenance even right after login.
            final blocked = await _isMaintenanceBlocked(ref);
            if (!context.mounted) return;
            if (blocked) {
              context.go('/maintenance');
              return;
            }
            final vendorId = ref.read(activeVendorProvider);
            if (vendorId == null || vendorId.isEmpty) {
              debugPrint('DEBUG: No vendorId, going to /select-vendor');
              if (context.mounted) context.go('/select-vendor');
              return;
            }
          }
          debugPrint('DEBUG: Going to /dashboard');
          if (context.mounted) {
            context.go('/dashboard');
          } else {
            debugPrint('DEBUG: context is NOT mounted!');
          }
        } catch (e) {
          debugPrint('DEBUG: Error in listen: $e');
        }
      } else if (state.hasError && state.error != null) {
        debugPrint('DEBUG: Showing error snackbar for: ${state.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorUtils.translate(context, state.error),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

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
                        'Otlob Admin',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    Text(
                      l10n.emailAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: l10n.emailHint,
                        prefixIcon: const Icon(LucideIcons.mail, size: 20),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.password,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '********',
                        prefixIcon: const Icon(LucideIcons.lock, size: 20),
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
                    ),
                    const SizedBox(height: 32),
                    Consumer(
                      builder: (context, ref, child) {
                        final state = ref.watch(authProvider);
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
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
                            child: state.isLoading
                                ? CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  )
                                : Text(l10n.signIn),
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return InkWell(
          onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
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
        final locale = ref.watch(localeProvider);
        final isArabic = locale.languageCode == 'ar';
        return InkWell(
          onTap: () => ref.read(localeProvider.notifier).toggleLanguage(),
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

