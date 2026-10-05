import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
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

    if (mounted) {
      ref.read(authControllerProvider.notifier).checkAuthStatus();
    }
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
