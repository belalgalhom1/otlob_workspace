import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart'
    show OtlobWelcomeLoginShell, SocialAuthButton;

import '../providers/auth_controller.dart';
import '../providers/login_controller.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/l10n/app_strings.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';

enum _AuthSubmissionMethod { email, google }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _saveInfo = true;
  _AuthSubmissionMethod? _submittingMethod;
  Map<String, String>? _savedProfile;

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  Future<void> _loadSavedProfile() async {
    try {
      final profile = await ref.read(tokenServiceProvider).getSavedProfile();
      if (!mounted || profile == null) return;
      setState(() {
        _savedProfile = profile;
        _emailController.text = profile['email'] ?? '';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _submittingMethod = _AuthSubmissionMethod.email);
    try {
      final result = await ref.read(loginControllerProvider.notifier).login(
            email: email,
            password: password,
            rememberMe: _saveInfo,
          );

      if (result && mounted) {
        _goAfterLogin();
      }
    } finally {
      if (mounted) {
        setState(() => _submittingMethod = null);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _submittingMethod = _AuthSubmissionMethod.google);
    try {
      final result = await ref
          .read(loginControllerProvider.notifier)
          .signInWithGoogle();

      if (result && mounted) {
        _goAfterLogin();
      }
    } finally {
      if (mounted) {
        setState(() => _submittingMethod = null);
      }
    }
  }

  void _onAppleSignInPressed(AppStrings s) {
    // UI-only placeholder until Sign in with Apple authentication is enabled.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(s.appleSignInComingSoon)),
      );
  }

  void _goAfterLogin() {
    if (!mounted) return;
    // Never navigate to authenticated routes unless AuthController actually
    // reached AuthStatus.authenticated.
    if (ref.read(authControllerProvider) != AuthStatus.authenticated) return;
    final currentPath = GoRouterState.of(context).matchedLocation;
    if (currentPath != RoutePaths.login) return;

    if (ref.read(needsPhoneProvider)) {
      context.go(RoutePaths.completePhone);
      return;
    }
    if (ref.read(needsTermsProvider)) {
      context.go(RoutePaths.termsAcceptance);
      return;
    }
    if (ref.read(needsAddressProvider)) {
      context.go('/addresses');
      return;
    }

    final uri = GoRouterState.of(context).uri;
    final redirectUrl = uri.queryParameters['redirect'];

    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      context.go(redirectUrl);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, next.error)),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final s = AppStrings.of(context);
    final showBack = context.canPop();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : null,
      body: OtlobWelcomeLoginShell(
        logoAssetPath: 'assets/logo_without_background.png',
        appLabel: s.isArabic ? 'اطلب' : 'OTLOB',
        welcomeSubLabel: s.isArabic
            ? 'كل اللي تحتاجه، واصل لحد بابك'
            : 'Everything you crave, delivered fast',
        topInsetPadding: showBack ? 40 : 4,
        formChild: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.loginToApp,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              if (_savedProfile != null) ...[
                InkWell(
                  onTap: () {
                    final email = _savedProfile!['email'] ?? '';
                    final password = _savedProfile!['password'] ?? '';
                    _emailController.text = email;
                    _passwordController.text = password;
                    _submit();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: _buildSavedProfileCard(s),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    s.orLoginWithAnother,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: s.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? s.emailRequired : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: s.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.length < 6) ? s.passwordMinLen : null,
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _saveInfo,
                      onChanged: (v) => setState(() => _saveInfo = v ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => setState(() => _saveInfo = !_saveInfo),
                      child: Text(
                        s.rememberMe,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => context.push(RoutePaths.forgotPassword),
                  child: Text(
                    s.forgotPassword,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 50),
                child: ElevatedButton(
                  onPressed: loginState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  child: loginState.isLoading &&
                          _submittingMethod == _AuthSubmissionMethod.email
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(s.login, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      s.or,
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
              const SizedBox(height: 14),
              SocialAuthButton(
                height: 50,
                label: s.continueWithGoogle,
                isLoading: loginState.isLoading &&
                    _submittingMethod == _AuthSubmissionMethod.google,
                onPressed: loginState.isLoading ? null : _signInWithGoogle,
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
                height: 50,
                label: s.continueWithApple,
                isLoading: false,
                onPressed: loginState.isLoading
                    ? null
                    : () => _onAppleSignInPressed(s),
                icon: Icon(
                  Icons.apple,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(RoutePaths.register),
                child: Text.rich(
                  TextSpan(
                    text: s.dontHaveAccount,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: [
                      TextSpan(
                        text: s.signUp,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              TextButton(
                onPressed: () => context.go(RoutePaths.home),
                child: Text(
                  s.isArabic ? 'تصفح كزائر' : 'Continue as Guest',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedProfileCard(AppStrings s) {
    final savedName = (_savedProfile?['name'] ?? '').trim();
    final initial = savedName.isNotEmpty ? savedName[0].toUpperCase() : 'U';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _savedProfile!['name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _savedProfile!['email'] ?? '',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () async {
              await ref.read(tokenServiceProvider).deleteSavedProfile();
              if (mounted) {
                setState(() {
                  _savedProfile = null;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
