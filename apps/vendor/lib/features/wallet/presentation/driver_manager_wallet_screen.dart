import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/providers.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:vendor/core/utils/error_utils.dart';

class DriverManagerWalletScreen extends ConsumerStatefulWidget {
  const DriverManagerWalletScreen({super.key});

  @override
  ConsumerState<DriverManagerWalletScreen> createState() =>
      _DriverManagerWalletScreenState();
}

class _DriverManagerWalletScreenState
    extends ConsumerState<DriverManagerWalletScreen> {
  static final _moneyFmt = NumberFormat('#,##0.00', 'en_US');
  static final _intFmt = NumberFormat('#,##0', 'en_US');

  bool _isLoading = true;
  Object? _error;
  double _walletBalance = 0.0;
  List<dynamic> _transactions = [];
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      final res = await repo.getDriverManagerTransactions(page: page);
      if (!mounted) return;
      if (res is Map) {
        final bal = res['walletBalance'];
        final balNum = bal is num
            ? bal.toDouble()
            : double.tryParse(bal?.toString() ?? '0') ?? 0.0;
        final list = res['data'] is List ? (res['data'] as List) : [];
        final meta = res['meta'] is Map ? (res['meta'] as Map) : {};
        setState(() {
          _walletBalance = balNum;
          _transactions = list;
          _page = (meta['page'] as num?)?.toInt() ?? 1;
          _totalPages = (meta['totalPages'] as num?)?.toInt() ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  Color _borderColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppColors.borderDark
      : AppColors.borderLight;

  Color _positiveTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? AppColors.success
      : const Color(0xFF047857);

  Color _negativeTextColor(ThemeData theme) =>
      theme.brightness == Brightness.dark
      ? AppColors.error
      : const Color(0xFFB91C1C);

  Color _amberTextColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? AppColors.primary
      : const Color(0xFF92400E);

  Widget _scaledMoneyText(
    String text,
    TextStyle style, {
    AlignmentDirectional alignment = AlignmentDirectional.centerStart,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          text,
          maxLines: 1,
          style: style.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    final dt = DateTime.tryParse(dateStr.toString())?.toLocal();
    if (dt == null) return dateStr.toString();
    return DateFormat('yyyy-MM-dd HH:mm').format(dt);
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'COMMISSION_EARNED':
        return _isAr ? 'عمولة إدارة طلب' : 'Order Commission';
      case 'PENALTY_DEDUCTION':
        return _isAr ? 'خصم جزاءات' : 'Penalty Deduction';
      case 'MANUAL_ADJUSTMENT':
        return _isAr ? 'تسوية يدوية' : 'Manual Adjustment';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final borderColor = _borderColor(theme);

    if (_isLoading && _transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.circleAlert,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _isAr
                    ? 'فشل تحميل بيانات المحفظة'
                    : 'Failed to load wallet data',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ErrorUtils.translate(context, _error),
                style: TextStyle(
                  color: _negativeTextColor(theme),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadData(),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(_isAr ? 'إعادة المحاولة' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isNegativeBalance = _walletBalance < 0;

    return RefreshIndicator(
      onRefresh: () => _loadData(page: 1),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 24,
          isMobile ? 8 : 12,
          isMobile ? 16 : 24,
          24,
        ),
        children: [
          // Balance Card
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A34), const Color(0xFF122320)]
                    : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.wallet,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isAr
                                  ? 'محفظة مسؤول السائقين'
                                  : 'Driver Manager Wallet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.refreshCw,
                        color: Colors.white,
                        size: 18,
                      ),
                      tooltip: _isAr ? 'تحديث' : 'Refresh',
                      onPressed: () => _loadData(page: _page),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: _scaledMoneyText(
                        '${isNegativeBalance ? '-' : ''}${_moneyFmt.format(_walletBalance.abs())}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 32 : 38,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Text(
                        'EGP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isAr
                      ? 'يتم إضافة نسبة عمولة الإدارة تلقائياً عن كل طلب مكتمل في منطقتك'
                      : 'Manager commissions from completed zone orders are credited automatically',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ledger Header
          Row(
            children: [
              Expanded(
                child: Text(
                  _isAr ? 'سجل المعاملات' : 'Transaction History',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isAr
                    ? '${_intFmt.format(_transactions.length)} معاملة'
                    : '${_intFmt.format(_transactions.length)} transactions',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_transactions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.receiptText,
                    size: 44,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isAr ? 'لا توجد معاملات بعد' : 'No transactions yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._transactions.map((tx) {
              if (tx is! Map) return const SizedBox.shrink();
              final amountNum = (tx['amount'] is num)
                  ? (tx['amount'] as num).toDouble()
                  : double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
              final isCredit = amountNum >= 0;
              final hasBalanceAfter = tx['balanceAfter'] != null;
              final balanceAfter = (tx['balanceAfter'] is num)
                  ? (tx['balanceAfter'] as num).toDouble()
                  : double.tryParse(tx['balanceAfter']?.toString() ?? '0') ??
                        0.0;
              final type = tx['type']?.toString() ?? 'TRANSACTION';
              final desc = tx['description']?.toString() ?? '';
              final orderId = tx['orderId']?.toString();
              final createdAt = tx['createdAt'];
              final iconBgColor = isCredit ? AppColors.success : AppColors.error;
              final amountColor = isCredit
                  ? _positiveTextColor(theme)
                  : _negativeTextColor(theme);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) => Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBgColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit
                              ? LucideIcons.arrowDownLeft
                              : LucideIcons.arrowUpRight,
                          color: amountColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc.isNotEmpty ? desc : _typeLabel(type),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                if (orderId != null && orderId.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: _amberTextColor(theme),
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.42,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _scaledMoneyText(
                              '${isCredit ? '+' : '-'}${_moneyFmt.format(amountNum.abs())} EGP',
                              TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: amountColor,
                              ),
                              alignment: AlignmentDirectional.centerEnd,
                            ),
                            if (hasBalanceAfter) ...[
                              const SizedBox(height: 3),
                              _scaledMoneyText(
                                '${_isAr ? 'الرصيد: ' : 'Bal: '}${balanceAfter < 0 ? '-' : ''}${_moneyFmt.format(balanceAfter.abs())}',
                                TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                                alignment: AlignmentDirectional.centerEnd,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          // Pagination controls
          if (_totalPages > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      tooltip: _isAr ? 'السابق' : 'Previous',
                      icon: Icon(
                        isRtl
                            ? LucideIcons.chevronRight
                            : LucideIcons.chevronLeft,
                        size: 18,
                      ),
                      onPressed: _page > 1
                          ? () => _loadData(page: _page - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _isAr
                            ? 'صفحة $_page من $_totalPages'
                            : 'Page $_page of $_totalPages',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: _isAr ? 'التالي' : 'Next',
                      icon: AppAdaptiveChevron(
                        size: 18,
                        color: _page < _totalPages
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.35,
                              ),
                      ),
                      onPressed: _page < _totalPages
                          ? () => _loadData(page: _page + 1)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
