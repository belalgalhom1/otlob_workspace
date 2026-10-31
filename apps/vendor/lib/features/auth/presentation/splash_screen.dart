import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late final AnimationController _rotationController;
  Timer? _watchdogTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.forward();

    // Watchdog timer: If anything upstream hangs, never leave the user frozen
    _watchdogTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || _navigated) return;
      debugPrint('🚀 Splash: watchdog triggered fallback');
      _navigated = true;
      context.go('/login');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAppGate();
    });
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
                      final url = (status.storeUrl ?? '').trim();
                      final uri = Uri.tryParse(url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(l10n.updateNow),
                  ),
                ],
              ),
            );
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

  void _onAuthStateChanged(BuildContext context, AsyncValue<bool> state) async {
    if (_navigated) return;
    if (!state.isLoading && state.hasValue) {
      try {
        if (state.value == true) {
          final repo = ref.read(sharedAuthRepositoryProvider);
          final role = await repo.getUserRole();
          if (role != 'ADMIN' && role != 'SUPER_ADMIN' && role != 'VENDOR_MEMBER' && role != 'DRIVER_MANAGER') {
            await repo.logout();
            if (context.mounted) {
              _navigated = true;
              context.go('/login');
            }
            return;
          }
          if (role == 'VENDOR_MEMBER') {
            final vendorId = ref.read(activeVendorProvider);
            if (vendorId == null || vendorId.isEmpty) {
              if (context.mounted) {
                _navigated = true;
                context.go('/select-vendor');
              }
              return;
            }
          }
          if (context.mounted) {
            _navigated = true;
            context.go('/dashboard');
          }
        } else {
          _navigated = true;
          context.go('/login');
        }
      } catch (e) {
        debugPrint('_onAuthStateChanged error: $e');
        if (context.mounted) {
          _navigated = true;
          context.go('/login');
        }
      }
    }
  }

  @override
  void dispose() {
    _watchdogTimer?.cancel();
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(authProvider, (previous, state) {
      _onAuthStateChanged(context, state);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RepaintBoundary(
                child: RotationTransition(
                  turns: _rotationController,
                  child: Image.asset(
                    'assets/logo_without_background.png',
                    width: 140,
                    fit: BoxFit.contain,
                  ),
                ),
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
    );
  }
}
