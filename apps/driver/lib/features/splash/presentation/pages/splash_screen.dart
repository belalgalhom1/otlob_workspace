import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/l10n/app_localizations.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.package,
                  size: 64,
                  color: AppColors.primary,
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
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
