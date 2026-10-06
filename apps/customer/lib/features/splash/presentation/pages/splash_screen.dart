import 'package:data/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final status = await checkAppStatus(
      ref.read(sharedPlatformSettingsRepositoryProvider),
    );
    if (!mounted) return;

    if (status != null) {
      if (status.maintenance) {
        context.go('/maintenance');
        return;
      }
      if (status.mustUpdate) {
        context.go('/update-required', extra: {'storeUrl': status.storeUrl});
        return;
      }
      if (status.shouldUpdate) {
        final s = AppStrings.of(context);
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(s.updateAvailableTitle),
            content: Text(s.updateAvailableMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(s.updateLater),
              ),
            ],
          ),
        );
        if (!mounted) return;
      }
    }

    ref.read(authControllerProvider.notifier).checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: RotationTransition(
          turns: _rotationController,
          child: Image.asset(
            'assets/logo_without_background.png',
            width: 140,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
