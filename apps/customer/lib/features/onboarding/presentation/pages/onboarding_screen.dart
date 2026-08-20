import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/l10n/app_strings.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Replace with your illustration!
              const Icon(Icons.delivery_dining, size: 150, color: AppColors.primary),
              const SizedBox(height: 40),
              Text(
                s.isArabic ? 'أهلاً بك في اطلب!' : 'Welcome to Otlob!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.isArabic 
                    ? 'احصل على طعامك المفضل ليصلك فوراً إلى باب منزلك. طازج، سريع، وموثوق.'
                    : 'Get your favorite food delivered instantly to your door. Fresh, fast, and reliable.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    // Update the global state so they never see this again
                    await ref.read(appSettingsProvider.notifier).completeOnboarding();
                    // Go to Home!
                    if (context.mounted) context.go(RoutePaths.home);
                  },
                  child: Text(s.isArabic ? 'ابدأ الآن' : 'Get Started', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
