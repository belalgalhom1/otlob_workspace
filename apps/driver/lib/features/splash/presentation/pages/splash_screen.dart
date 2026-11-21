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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<OtlobSplashSpinLogoState> _spinLogoKey =
      GlobalKey<OtlobSplashSpinLogoState>();
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  Timer? _watchdogTimer;
  bool _showRetry = false;
  bool _navigated = false;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _animController.forward();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    precacheImage(
      const AssetImage('assets/logo_delivery.png'),
      context,
    ).catchError((_) {});
    precacheImage(
      const AssetImage('assets/logo_delivery_dark.png'),
      context,
    ).catchError((_) {});
    precacheImage(
      const AssetImage('assets/logo_without_background.png'),
      context,
    ).catchError((_) {});
  }

  Future<void> _waitForSpinCompleted() async {
    final spinState = _spinLogoKey.currentState;
    if (spinState != null) {
      await spinState.waitForSpinAndSettle(Future<void>.value());
    } else {
      await Future.delayed(const Duration(milliseconds: 3900));
    }
  }

  Future<void> _goToLoginAfterSpin() async {
    await _waitForSpinCompleted();
    if (!mounted) return;
    if (ref.read(authProvider).value == true) {
      ref.read(authProvider.notifier).markUnauthenticated();
    }
    OtlobLoginEntranceCoordinator.markFromSplash();
    context.go('/login');
  }

  Future<void> _goToRouteAfterSpin(String route) async {
    await _waitForSpinCompleted();
    if (!mounted) return;
    OtlobLoginEntranceCoordinator.reset();
    context.go(route);
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
          _goToRouteAfterSpin('/suspended');
          break;
        case AppStartupState.needsTerms:
          _goToRouteAfterSpin('/terms-acceptance');
          break;
        case AppStartupState.dashboard:
          _maybeShowOptionalUpdate('/dashboard');
          break;
        case AppStartupState.activeOrder:
          _maybeShowOptionalUpdate('/order-execution');
          break;
        case AppStartupState.maintenance:
          _goToRouteAfterSpin('/maintenance');
          break;
        case AppStartupState.forceUpdate:
          _goToRouteAfterSpin('/update-required');
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
    _animController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowOptionalUpdate(String target) async {
    await _waitForSpinCompleted();
    if (!mounted) return;
    if (ref.read(appUpdateAvailableProvider) != true) {
      OtlobLoginEntranceCoordinator.reset();
      context.go(target);
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
    if (mounted) {
      OtlobLoginEntranceCoordinator.reset();
      context.go(target);
    }
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OtlobSplashSpinLogo(
                key: _spinLogoKey,
                scaleAnimation: _scaleAnimation,
                onInitialSpinCompleted: () => _spinLogoKey.currentState
                    ?.continueSpinningWhileWaiting(),
                child: Image.asset(
                  isDark
                      ? 'assets/logo_delivery_dark.png'
                      : 'assets/logo_delivery.png',
                  width: 140,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context)?.appName ?? 'Otlob Driver',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
                    _watchdogTimer = Timer(const Duration(seconds: 30), () {
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
    );
  }
}
