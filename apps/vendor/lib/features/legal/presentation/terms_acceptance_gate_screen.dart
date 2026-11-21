import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:vendor/core/providers.dart';

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

      if (!mounted) return;

      final authRepo = ref.read(sharedAuthRepositoryProvider);
      final role = await authRepo.getUserRole();

      if (!mounted) return;

      if (role == 'VENDOR_MEMBER') {
        final vendorId = ref.read(activeVendorProvider);
        if (vendorId == null || vendorId.isEmpty) {
          context.go('/select-vendor');
          return;
        }
      }

      context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        // Handled in finally block
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
      title: isAr ? 'رفض شروط الاستخدام؟' : 'Decline Terms of Use?',
      message: isAr
          ? 'لا يمكنك متابعة استخدام لوحة تحكم المنصة بدون الموافقة على شروط الاستخدام المحدثة. سيتم تسجيل خروجك من حسابك.'
          : 'You cannot use the platform admin without accepting the updated Terms of Use. You will be logged out.',
      confirmLabel: isAr ? 'تسجيل الخروج' : 'Log out',
      cancelLabel: isAr ? 'إلغاء' : 'Cancel',
      icon: LucideIcons.logOut,
      confirmIcon: LucideIcons.logOut,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isAr
                      ? 'جاري تحميل شروط الاستخدام...'
                      : 'Loading Terms of Use...',
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null || _document == null) {
      return Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - AppSpacing.xl * 2)
                      .clamp(0.0, double.infinity),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 48,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        isAr
                            ? 'حدث خطأ أثناء تحميل شروط الاستخدام'
                            : 'Error loading Terms of Use',
                        style: AppTypography.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton.icon(
                        onPressed: _fetchTerms,
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: _decline,
                        child: Text(isAr ? 'تسجيل الخروج' : 'Log out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final title = _showArabic
        ? (_document!['titleAr'] ??
            _document!['title'] ??
            _document!['titleEn'] ??
            '')
        : (_document!['titleEn'] ??
            _document!['title'] ??
            _document!['titleAr'] ??
            '');
    final content = _showArabic
        ? (_document!['contentAr'] ??
            _document!['content'] ??
            _document!['contentEn'] ??
            '')
        : (_document!['contentEn'] ??
            _document!['content'] ??
            _document!['contentAr'] ??
            '');
    final version = _document!['version']?.toString() ?? '1.0';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: TermsAcceptanceDialog(
            variant: TermsDialogVariant.vendor,
          title: title.toString(),
          subtitle: isAr
              ? 'يرجى مراجعة شروط الاستخدام والموافقة عليها للمتابعة'
              : 'Please review and accept the Terms of Use to continue',
          version: version,
          content: content.toString(),
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
          ),
        ),
      ),
    );
  }
}
