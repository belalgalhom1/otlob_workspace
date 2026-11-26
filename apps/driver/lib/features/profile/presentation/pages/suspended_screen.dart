import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/features/wallet/presentation/widgets/top_up_bottom_sheet.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:data/data.dart';

class SuspendedScreen extends ConsumerStatefulWidget {
  const SuspendedScreen({super.key});

  @override
  ConsumerState<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends ConsumerState<SuspendedScreen> {
  bool _isChecking = false;
  bool _hasRedirected = false;

  String? _extractProfileStatus(dynamic profile) {
    final profileMap = (profile is Map && profile['data'] is Map)
        ? profile['data'] as Map
        : profile;
    if (profileMap is Map) {
      return profileMap['status']?.toString();
    }
    return null;
  }

  Future<void> _checkAccountStatus() async {
    setState(() => _isChecking = true);
    try {
      ref.invalidate(driverWalletProvider);
      ref.invalidate(driverProfileProvider);
      final repo = ref.read(driverProfileRepositoryProvider);
      final profile = await repo.getMyProfile();
      if (!mounted) return;

      final status = _extractProfileStatus(profile);
      if (status != null && status != 'SUSPENDED') {
        _hasRedirected = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم فك تعليق الحساب بنجاح!'
                  : 'Account unsuspended successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'الحساب لا يزال معلقاً. يرجى تسوية رصيدك أو انتظار مراجعة الطلب.'
                  : 'Account is still suspended. Please settle your balance or wait for review.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تعذر التحقق من حالة الحساب. حاول مرة أخرى.'
                  : 'Could not verify account status. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _openTopUpSheet(List<dynamic> platformWallets) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TopUpBottomSheet(platformWallets: platformWallets),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warmAccent = isDark ? AppColors.primary : const Color(0xFF92400E);
    final warningAccent = isDark ? AppColors.warning : const Color(0xFF92400E);
    final rawCurrency =
        ref.watch(configurationProvider).value?['currency']?.toString() ?? 'EGP';
    final currency = (isAr && rawCurrency == 'EGP') ? 'ج.م' : rawCurrency;

    final profileValue = ref.watch(driverProfileProvider).value;
    final profileData = (profileValue is Map && profileValue['data'] is Map)
        ? profileValue['data'] as Map
        : (profileValue is Map ? profileValue : <String, dynamic>{});

    final walletState = ref.watch(driverWalletProvider);
    final walletData = walletState.value;
    final num balance = walletData?['balance'] ?? 0.0;
    final platformWallets =
        walletData?['platformWallets'] as List<dynamic>? ?? [];
    ref.listen<AsyncValue<dynamic>>(driverProfileProvider, (previous, next) {
      if (!mounted || _hasRedirected) return;
      final status = _extractProfileStatus(next.value);
      if (status != null && status != 'SUSPENDED') {
        _hasRedirected = true;
        context.go('/dashboard');
      }
    });

    final topUpRequests =
        walletData?['topUpRequests'] as List<dynamic>? ?? [];
    final pendingTopUps =
        topUpRequests.where((e) => e['status'] == 'PENDING').toList();
    final rejectedTopUps =
        topUpRequests.where((e) => e['status'] == 'REJECTED').take(3).toList();

    final bool isUnpaidCommission =
        profileData['hasUnpaidCommission'] == true || balance < 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountSuspended),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.refreshCw),
            tooltip: isAr ? 'تحديث الحالة' : 'Refresh Status',
            onPressed: _isChecking ? null : _checkAccountStatus,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _checkAccountStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: Icon(
                  LucideIcons.ban,
                  size: 64,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.accountSuspendedMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                isUnpaidCommission
                    ? (isAr
                        ? 'تم تعليق حسابك بسبب مستحقات غير مسددة للمنصة. يرجى تسوية رصيدك لإعادة تفعيل الحساب واستقبال الطلبات.'
                        : 'Your account is suspended due to unpaid platform commission. Please settle your balance to reactivate your account.')
                    : l10n.accountSuspendedDetails,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 24),

              // Wallet Settlement Section (if unpaid commission or negative balance)
              if (isUnpaidCommission || balance < 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              isAr ? 'المبلغ المستحق سداده' : 'Outstanding Balance',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              '${balance.abs().toStringAsFixed(2)} $currency',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'قم بالتحويل إلى إحدى محافظ المنصة ثم ارفع إيصال التحويل لفك التعليق تلقائياً فور الاعتماد.'
                            : 'Transfer the amount to a platform wallet and upload the receipt to unlock your account once approved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Pending Top-Up Card
              if (pendingTopUps.isNotEmpty) ...[
                ...pendingTopUps.map((tx) {
                  final amount =
                      double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.clock,
                          color: warningAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'طلب شحن قيد المراجعة: ${amount.toStringAsFixed(2)} $currency'
                                    : 'Pending Top-Up: +${amount.toStringAsFixed(2)} $currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: warningAccent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr
                                    ? 'تم استلام إيصال التحويل وجاري مراجعته من الإدارة. سيتم تفعيل حسابك تلقائياً.'
                                    : 'Your receipt was received and is under review. Your account will unlock automatically.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (rejectedTopUps.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.topUpRequestsTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...rejectedTopUps.map((rawTx) {
                  final tx = rawTx is Map ? rawTx : const <String, dynamic>{};
                  final amount =
                      double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
                  final notes = (tx['notes'] ?? '').toString().trim();
                  final localTheme = Theme.of(context);
                  return InkWell(
                    onTap: () => context.push('/wallet'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.circleAlert,
                                size: 18,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.rejected,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      '+${amount.toStringAsFixed(2)} $currency',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${l10n.rejectionReasonLabel}: $notes',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: localTheme.colorScheme.onSurface
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],

              // Action Buttons
              PrimaryButton(
                text: isAr
                    ? 'تسوية الرصيد وشحن المحفظة'
                    : 'Settle Balance / Top Up Wallet',
                onPressed: () => _openTopUpSheet(platformWallets),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: warmAccent,
                  side: BorderSide(color: warmAccent.withValues(alpha: 0.45)),
                ),
                onPressed: () => context.push('/wallet'),
                icon: const Icon(LucideIcons.wallet, size: 18),
                label: Text(
                  isAr ? 'عرض تفاصيل المحفظة' : 'View Wallet Details',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: warmAccent,
                  side: BorderSide(color: warmAccent.withValues(alpha: 0.45)),
                ),
                onPressed: _isChecking ? null : _checkAccountStatus,
                icon: const Icon(LucideIcons.checkCircle2, size: 18),
                label: Text(
                  isAr ? 'التحقق من حالة الحساب' : 'Check Account Status',
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              TextButton.icon(
                icon: const Icon(LucideIcons.helpCircle, size: 18),
                label: Text(l10n.contactSupport),
                onPressed: () async {
                  await ExternalActionLauncher.sendEmail(
                    'support@otlob-egy.online',
                    subject: 'Account Suspended',
                    context: context,
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(LucideIcons.logOut, size: 18, color: Colors.red),
                label: Text(
                  l10n.logout,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
