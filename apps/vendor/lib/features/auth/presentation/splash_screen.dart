import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<OtlobSplashSpinLogoState> _spinLogoKey =
      GlobalKey<OtlobSplashSpinLogoState>();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _watchdogTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Watchdog timer: If anything upstream hangs, never leave the user frozen
    _watchdogTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || _navigated) return;
      debugPrint('🚀 Splash: watchdog triggered fallback');
      _navigated = true;
      _goToLoginAfterSpin();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAppGate();
    });
  }

  Future<void> _goToLoginAfterSpin() async {
    final spinState = _spinLogoKey.currentState;
    if (spinState != null) {
      await spinState.waitForSpinAndSettle(Future<void>.value());
    }
    if (!mounted) return;
    OtlobLoginEntranceCoordinator.markFromSplash();
    context.go('/login');
  }

  Future<void> _runAppGate() async {
    try {
      final status = await checkAppStatus(
        ref.read(sharedPlatformSettingsRepositoryProvider),
      ).timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (!mounted || _navigated) return;

      if (status != null) {
        final isStaff = await _isPlatformStaff().timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        );
        if (status.maintenance && !isStaff) {
          _navigated = true;
          context.go('/maintenance');
          return;
        }
        if (status.mustUpdate) {
          _navigated = true;
          ref.read(updateStoreUrlProvider.notifier).set(status.storeUrl);
          context.go('/update-required');
          return;
        }
        if (status.shouldUpdate) {
          final l10n = AppLocalizations.of(context);
          if (l10n != null) {
            final shouldUpdate = await AppConfirmDialog.show(
              context,
              title: l10n.updateAvailableTitle,
              message: l10n.updateAvailableMessage,
              confirmLabel: l10n.updateNow,
              cancelLabel: l10n.updateLater,
              icon: LucideIcons.sparkles,
              confirmIcon: LucideIcons.externalLink,
            );
            if (!mounted || _navigated) return;
            if (shouldUpdate == true) {
              final url = (status.storeUrl ?? '').trim();
              if (url.isNotEmpty) {
                await ExternalActionLauncher.openWebUrl(
                  url,
                  context: mounted ? context : null,
                );
              }
            }
            if (!mounted || _navigated) return;
          }
        }
      }
    } catch (e) {
      debugPrint('Splash gate error: $e');
    }

    if (!mounted || _navigated) return;
    ref.read(authProvider.notifier).checkAuth();
  }

  /// Platform staff (super admins and admins) keep full access during
  /// maintenance. Vendors and logged-out users are held on the gate.
  Future<bool> _isPlatformStaff() async {
    try {
      final repo = ref.read(sharedAuthRepositoryProvider);
      if (!await repo.isLoggedIn()) return false;
      final role = await repo.getUserRole();
      return role == 'SUPER_ADMIN' || role == 'ADMIN' || role == 'DRIVER_MANAGER';
    } catch (_) {
      return false;
    }
  }

  void _onAuthStateChanged(BuildContext context, AsyncValue<bool> state) {
    if (_navigated) return;
    if (!state.isLoading && state.hasValue) {
      if (!context.mounted) return;
      _navigated = true;
      if (state.value == true) {
        OtlobLoginEntranceCoordinator.reset();
        context.go(ref.read(vendorPostAuthRouteProvider));
      } else {
        _goToLoginAfterSpin();
      }
    }
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(authProvider, (previous, state) {
      _onAuthStateChanged(context, state);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OtlobSplashSpinLogo(
                  key: _spinLogoKey,
                  assetPath: 'assets/logo_without_background.png',
                  size: 140,
                  auraPadding: 14,
                  auraColor: AppColors.primary.withValues(alpha: 0.1),
                  borderColor: AppColors.primary.withValues(alpha: 0.2),
                  onInitialSpinCompleted: () => _spinLogoKey.currentState
                      ?.continueSpinningWhileWaiting(),
                ),
                const SizedBox(height: 24),
                Text(
                  'OTLOB ADMIN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
