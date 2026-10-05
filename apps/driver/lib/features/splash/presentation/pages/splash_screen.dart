import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppStartupState>>(splashProvider, (previous, state) {
      if (state.hasValue && !state.isLoading) {
        switch (state.value!) {
          case AppStartupState.unauthenticated:
            context.go('/login');
            break;

          case AppStartupState.suspended:
            context.go('/suspended');
            break;
          case AppStartupState.dashboard:
            context.go('/dashboard');
            break;
          case AppStartupState.activeOrder:
            context.go('/order-execution');
            break;
          case AppStartupState.loading:
            break;
        }
      }
    });

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
            ],
          ),
        ),
      ),
    );
  }
}
