import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:vendor/core/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  void _onAuthStateChanged(BuildContext context, AsyncValue<bool> state) async {
    if (!state.isLoading && state.hasValue) {
      try {
        if (state.value == true) {
          final repo = ref.read(sharedAuthRepositoryProvider);
          final role = await repo.getUserRole();
          if (role == 'VENDOR_MEMBER') {
            final vendorId = ref.read(activeVendorProvider);
            if (vendorId == null || vendorId.isEmpty) {
              if (context.mounted) context.go('/select-vendor');
              return;
            }
          }
          if (context.mounted) context.go('/dashboard');
        } else {
          context.go('/login');
        }
      } catch (e) {
        debugPrint('_onAuthStateChanged error: $e');
        if (context.mounted) context.go('/login');
      }
    }
  }

  @override
  void dispose() {
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
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  LucideIcons.package,
                  color: AppColors.primary,
                  size: 64,
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
              const SizedBox(height: 16),
              SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

