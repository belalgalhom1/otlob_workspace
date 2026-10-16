import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  Timer? _watchdogTimer;
  bool _showRetry = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    // Watchdog: whatever happens upstream (hang, missed event, provider
    // error), the user is never left on a dead spinner — offer a retry.
    _watchdogTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      final state = ref.read(splashProvider);
      if (state.isLoading || state.hasError) {
        // ignore: avoid_print
        debugPrint(
          '🚀 Splash: watchdog fired (loading=${state.isLoading} error=${state.hasError})',
        );
        setState(() => _showRetry = true);
      }
    });
    void handleState(AsyncValue<AppStartupState> state) {
      if (!mounted || _navigated) return;
      if (state.hasError) {
        debugPrint('🚀 Splash: provider error, failing open to login');
        _navigated = true;
        context.go('/login');
        return;
      }
      if (state.hasValue && !state.isLoading) {
        debugPrint('🚀 Splash: navigating to ${state.value}');
        _navigated = true;
        switch (state.value!) {
          case AppStartupState.unauthenticated:
            context.go('/login');
            break;

          case AppStartupState.suspended:
            context.go('/suspended');
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
            break;
        }
      }
    }

    // If this screen (re)mounts while the provider already completed
    // (remount, scope rebuild, retry navigation), handle the current value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🚀 Splash: mount check');
      handleState(ref.read(splashProvider));
    });
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _rotationController.dispose();
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
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.updateAvailableTitle),
        content: Text(l10n.updateAvailableMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.updateLater),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _openStore(ref.read(updateStoreUrlProvider));
            },
            child: Text(l10n.updateNow),
          ),
        ],
      ),
    );
    if (mounted) context.go(target);
  }

  Future<void> _openStore(String? storeUrl) async {
    final url = (storeUrl ?? '').trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Belt and suspenders: navigation driven by the build itself cannot miss
    // a completed value the way a listener can (late subscription, remount,
    // missed event). The _navigated guard keeps all three paths (listener,
    // mount check, build) from double-navigating.
    final state = ref.watch(splashProvider);
    if (!_navigated && mounted && (state.hasValue || state.hasError)) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _navigated = false;
          return;
        }
        if (state.hasError) {
          debugPrint('🚀 Splash: provider error, failing open to login');
          context.go('/login');
          return;
        }
        if (state.hasValue && !state.isLoading) {
          debugPrint('🚀 Splash: navigating to ${state.value}');
          switch (state.value!) {
            case AppStartupState.unauthenticated:
              context.go('/login');
              break;
            case AppStartupState.suspended:
              context.go('/suspended');
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
        } else {
          _navigated = false;
        }
      });
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _rotationController,
                child: Image.asset(
                  'assets/logo_without_background.png',
                  width: 140,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)?.appName ?? 'Otlob Driver',
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
