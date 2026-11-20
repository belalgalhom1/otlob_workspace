import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart'
    show
        AppConfirmDialog,
        ExternalActionLauncher,
        OtlobLoginEntranceCoordinator,
        OtlobSplashSpinLogo,
        OtlobSplashSpinLogoState;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final GlobalKey<OtlobSplashSpinLogoState> _spinLogoKey =
      GlobalKey<OtlobSplashSpinLogoState>();

  Timer? _watchdogTimer;
  bool _showRetry = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Watchdog: whatever happens upstream (hang, missed event, provider
    // error), the user is never left on a dead spinner — offer a retry.
    _watchdogTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      final state = ref.read(splashProvider);
      if (state.isLoading || state.hasError) {
        debugPrint(
          '🚀 Splash: watchdog fired (loading=${state.isLoading} error=${state.hasError})',
        );
        setState(() => _showRetry = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🚀 Splash: mount check');
      _handleState(ref.read(splashProvider));
    });
  }

  Future<void> _goToLoginAfterSpin() async {
    final spinState = _spinLogoKey.currentState;
    if (spinState != null) {
      await spinState.waitForSpinAndSettle(Future<void>.value());
    } else {
      await Future.delayed(const Duration(milliseconds: 3900));
    }
    if (!mounted) return;
    if (ref.read(authProvider).value == true) {
      ref.read(authProvider.notifier).markUnauthenticated();
    }
    OtlobLoginEntranceCoordinator.markFromSplash();
    context.go('/login');
  }

  void _handleState(AsyncValue<AppStartupState> state) {
    if (!mounted || _navigated) return;
    if (state.hasError) {
      debugPrint('🚀 Splash: provider error, failing open to login');
      _navigated = true;
      _goToLoginAfterSpin();
      return;
    }
    if (state.hasValue && !state.isLoading) {
      debugPrint('🚀 Splash: navigating to ${state.value}');
      _navigated = true;
      switch (state.value!) {
        case AppStartupState.unauthenticated:
          _goToLoginAfterSpin();
          break;
        case AppStartupState.suspended:
          context.go('/suspended');
          break;
        case AppStartupState.needsTerms:
          context.go('/terms-acceptance');
          break;
        case AppStartupState.dashboard:
          _maybeShowOptionalUpdate('/dashboard');
          break;
        case AppStartupState.activeOrder:
          _maybeShowOptionalUpdate('/order-execution');
          break;
        case AppStartupState.maintenance:
          context.go('/maintenance');
          break;
        case AppStartupState.forceUpdate:
          context.go('/update-required');
          break;
        case AppStartupState.loading:
          _navigated = false;
          break;
      }
    }
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    super.dispose();
  }

  Future<void> _maybeShowOptionalUpdate(String target) async {
    if (!mounted) return;
    if (ref.read(appUpdateAvailableProvider) != true) {
      if (mounted) context.go(target);
      return;
    }
    ref.read(appUpdateAvailableProvider.notifier).set(false);
    final l10n = AppLocalizations.of(context)!;
    final shouldUpdate = await AppConfirmDialog.show(
      context,
      title: l10n.updateAvailableTitle,
      message: l10n.updateAvailableMessage,
      confirmLabel: l10n.updateNow,
      cancelLabel: l10n.updateLater,
      icon: LucideIcons.sparkles,
      confirmIcon: LucideIcons.externalLink,
    );
    if (shouldUpdate == true) {
      await _openStore(ref.read(updateStoreUrlProvider));
    }
    if (mounted) context.go(target);
  }

  Future<void> _openStore(String? storeUrl) async {
    final url = (storeUrl ?? '').trim();
    if (url.isEmpty) return;
    await ExternalActionLauncher.openWebUrl(
      url,
      context: mounted ? context : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(splashProvider);
    if (!_navigated && mounted && (state.hasValue || state.hasError)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleState(ref.read(splashProvider));
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 32).clamp(0.0, double.infinity),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OtlobSplashSpinLogo(
                        key: _spinLogoKey,
                        onInitialSpinCompleted: () => _spinLogoKey
                            .currentState
                            ?.continueSpinningWhileWaiting(),
                        child: Image.asset(
                          isDark
                              ? 'assets/logo_delivery_dark.png'
                              : 'assets/logo_delivery.png',
                          width: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        AppLocalizations.of(context)?.appName ?? 'Otlob Driver',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      if (_showRetry) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showRetry = false;
                              _navigated = false;
                            });
                            ref.invalidate(splashProvider);
                            _watchdogTimer?.cancel();
                            _watchdogTimer =
                                Timer(const Duration(seconds: 30), () {
                              if (!mounted) return;
                              final state = ref.read(splashProvider);
                              if (state.isLoading || state.hasError) {
                                setState(() => _showRetry = true);
                              }
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
