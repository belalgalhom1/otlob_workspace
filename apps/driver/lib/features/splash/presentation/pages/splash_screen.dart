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
