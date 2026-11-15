import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data/data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:driver/features/splash/presentation/splash_provider.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';

class TermsAcceptanceGateScreen extends ConsumerStatefulWidget {
  const TermsAcceptanceGateScreen({super.key});

  @override
  ConsumerState<TermsAcceptanceGateScreen> createState() =>
      _TermsAcceptanceGateScreenState();
}

class _TermsAcceptanceGateScreenState
    extends ConsumerState<TermsAcceptanceGateScreen> {
  Map<String, dynamic>? _document;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  bool _showArabic = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      setState(() => _showArabic = isAr);
      _fetchTerms();
    });
  }

  Future<void> _fetchTerms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(sharedLegalDocumentsRepositoryProvider);
      final doc = await repo.getActiveDocument('TERMS_OF_USE');
      if (mounted) {
        setState(() {
          _document = doc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptTerms() async {
    if (_document == null) return;
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(sharedLegalDocumentsRepositoryProvider);
      final docId = _document!['id']?.toString() ?? '';
      final version = _document!['version']?.toString() ?? '1.0';

      await repo.acceptDocument(
        documentId: docId,
        version: version,
      );

      // Re-trigger splash provider to route to dashboard
      ref.invalidate(splashProvider);
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'حدث خطأ أثناء حفظ الموافقة، يرجى المحاولة مرة أخرى'
                  : 'Failed to record acceptance, please try again',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _decline() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await AppConfirmDialog.show(
      context,
      title: isAr ? 'تسجيل الخروج' : 'Log Out',
      message: isAr
          ? 'يتطلب استخدام التطبيق كمندوب توصيل الموافقة على شروط الاستخدام. هل ترغب في تسجيل الخروج؟'
          : 'Continuing as a driver requires accepting the Terms of Use. Would you like to log out?',
      confirmLabel: isAr ? 'تسجيل الخروج' : 'Log Out',
      cancelLabel: isAr ? 'إلغاء' : 'Cancel',
      icon: LucideIcons.logOut,
      confirmIcon: LucideIcons.logOut,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - AppSpacing.xl * 2).clamp(0.0, double.infinity),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            size: 32,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          isAr ? 'تعذر تحميل شروط الاستخدام' : 'Unable to load Terms of Use',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isAr
                              ? 'يرجى التحقق من اتصالك بالإنترنت والمحاولة مجدداً.'
                              : 'Please check your internet connection and try again.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        SizedBox(
                          width: double.infinity,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: PrimaryButton(
                              text: isAr ? 'إعادة المحاولة' : 'Retry',
                              onPressed: _fetchTerms,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: OutlinedButton(
                              onPressed: _decline,
                              child: Text(isAr ? 'تسجيل الخروج' : 'Log Out'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final title = _showArabic
        ? (_document?['titleAr'] ?? _document?['title'] ?? '')
        : (_document?['title'] ?? _document?['titleAr'] ?? '');

    final content = _showArabic
        ? (_document?['contentAr'] ?? _document?['content'] ?? '')
        : (_document?['content'] ?? _document?['contentAr'] ?? '');

    final version = _document?['version']?.toString() ?? '1.0';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: TermsAcceptanceDialog(
          title: title,
          subtitle: isAr
              ? 'يرجى مراجعة شروط الاستخدام والموافقة عليها للمتابعة'
              : 'Please review and accept the Terms of Use to continue',
          version: version,
          content: content,
          isArabic: _showArabic,
          onLanguageToggle: () {
            setState(() => _showArabic = !_showArabic);
          },
          acceptCheckboxLabel: isAr
              ? 'قرأت وأوافق على شروط الاستخدام المذكورة أعلاه'
              : 'I have read and accept the Terms of Use above',
          acceptButtonLabel: isAr ? 'موافقة ومتابعة' : 'Accept & Continue',
          declineButtonLabel: isAr ? 'تسجيل الخروج' : 'Log Out',
          isLoading: _isSubmitting,
          onAccept: _acceptTerms,
          onDecline: _decline,
          onViewPrivacyPolicy: () => context.push(
            '/legal-document',
            extra: {
              'type': 'PRIVACY_POLICY',
              'title': isAr ? 'سياسة الخصوصية' : 'Privacy Policy',
            },
          ),
        ),
        ),
      ),
    );
  }
}
