import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/providers.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:vendor/core/utils/error_utils.dart';
import '../data/wallet_localization.dart';
import 'widgets/driver_manager_payout_dialog.dart';

class DriverManagerWalletScreen extends ConsumerStatefulWidget {
  final String? userId;
  final String? managerName;
  final bool canPayout;

  const DriverManagerWalletScreen({
    super.key,
    this.userId,
    this.managerName,
    this.canPayout = false,
  });

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
  String? _resolvedManagerName;

  bool get _isAdminInspect =>
      widget.userId != null && widget.userId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _resolvedManagerName = widget.managerName;
    _loadData();
  }

  Future<void> _loadData({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      final res = _isAdminInspect
          ? await repo.getDriverManagerTransactionsByUserId(
              widget.userId!,
              page: page,
            )
          : await repo.getDriverManagerTransactions(page: page);
      if (!mounted) return;
      if (res is Map) {
        final bal = res['walletBalance'];
        final balNum = bal is num
            ? bal.toDouble()
            : double.tryParse(bal?.toString() ?? '0') ?? 0.0;
        final list = res['data'] is List ? (res['data'] as List) : [];
        final meta = res['meta'] is Map ? (res['meta'] as Map) : {};
        final mgr = res['manager'];
        final fetchedName = mgr is Map ? mgr['name']?.toString().trim() : null;
        setState(() {
          _walletBalance = balNum;
          _transactions = list;
          _page = (meta['page'] as num?)?.toInt() ?? 1;
          _totalPages = (meta['totalPages'] as num?)?.toInt() ?? 1;
          if (fetchedName != null && fetchedName.isNotEmpty) {
            _resolvedManagerName = fetchedName;
          }
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

  String _resolveMediaUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final formatted = ImageUtils.formatImageUrl(trimmed);
    if (formatted.startsWith('http://') || formatted.startsWith('https://')) {
      return formatted;
    }
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$cleanBase$cleanPath';
  }

  void _openReceiptViewer(BuildContext context, String receiptUrl) {
    final isAr = _isAr;
    showDialog<void>(
      context: context,
      builder: (c) => AppDialog(
        maxWidth: 720,
        scrollableBody: false,
        bodyPadding: const EdgeInsets.all(16),
        header: AppDialogHeader(
          icon: LucideIcons.image,
          title: isAr ? 'إيصال التحويل' : 'Transfer Receipt',
          onClose: () => Navigator.pop(c),
        ),
        body: SizedBox(
          height: MediaQuery.of(context).size.height * 0.62,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                receiptUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (ctx, err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.imageOff,
                        size: 40,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'تعذر تحميل صورة الإيصال'
                            : 'Unable to load receipt image',
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

  Future<void> _openPayoutDialog() async {
    if (!_isAdminInspect || !widget.canPayout) return;
    final didPayout = await DriverManagerPayoutDialog.show(
      context,
      managerUserId: widget.userId!,
      managerName: _resolvedManagerName ?? '',
      currentBalance: _walletBalance,
    );
    if (didPayout == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAr
                ? 'تم تحويل المستحقات وتحديث المحفظة بنجاح'
                : 'Payout processed and manager notified successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadData(page: 1);
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
    bool includeCurrency = true,
  }) {
    return WalletLocalization.buildMoneyText(
      text,
      style,
      isArabic: _isAr,
      includeCurrency: includeCurrency,
      alignment: alignment,
    );
  }

  String _formatDate(dynamic dateStr) {
    return WalletLocalization.formatDateTime(dateStr, isArabic: _isAr);
  }

  String _typeLabel(String type) {
    return WalletLocalization.typeLabel(type, isArabic: _isAr);
  }

  Widget _wrapIfAdminScaffold(ThemeData theme, Widget body) {
    if (!_isAdminInspect) return body;
    final title = (_resolvedManagerName ?? '').trim().isNotEmpty
        ? (_isAr
            ? 'محفظة ${_resolvedManagerName!.trim()}'
            : '${_resolvedManagerName!.trim()} Wallet')
        : (_isAr ? 'محفظة مسؤول السائقين' : 'Driver Manager Wallet');
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final borderColor = _borderColor(theme);

    if (_isLoading && _transactions.isEmpty) {
      return _wrapIfAdminScaffold(
        theme,
        const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _transactions.isEmpty) {
      return _wrapIfAdminScaffold(
        theme,
        Center(
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
        ),
      );
    }

    final isNegativeBalance = _walletBalance < 0;

    final content = RefreshIndicator(
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
                              softWrap: true,
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
                        includeCurrency: false,
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
                      child: Text(
                        WalletLocalization.currency(_isAr),
                        style: const TextStyle(
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
                if (_isAdminInspect && widget.canPayout) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _walletBalance > 0 ? _openPayoutDialog : null,
                      icon: const Icon(LucideIcons.send, size: 16),
                      label: Text(
                        _walletBalance > 0
                            ? (_isAr
                                ? 'تحويل وتصفير المحفظة وإرفاق إيصال'
                                : 'Settle / Zero Out & Send Receipt')
                            : (_isAr
                                ? 'الرصيد مصفّر حالياً'
                                : 'Balance Already Settled'),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F766E),
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.22,
                        ),
                        disabledForegroundColor: Colors.white70,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
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
                  softWrap: true,
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
              final desc = WalletLocalization.localizeDescription(
                tx,
                isArabic: _isAr,
              );
              final orderNumber = WalletLocalization.extractOrderNumber(tx);
              final rawOrderId = tx['orderId']?.toString();
              final orderBadge = orderNumber.isNotEmpty
                  ? '#$orderNumber'
                  : (rawOrderId != null && rawOrderId.isNotEmpty
                        ? '#${rawOrderId.substring(0, rawOrderId.length > 8 ? 8 : rawOrderId.length).toUpperCase()}'
                        : '');
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
                  builder: (context, constraints) {
                    final scaledFont = MediaQuery.textScalerOf(context).scale(14);
                    final stackHeader =
                        constraints.maxWidth < 290 || scaledFont > 19.0;

                    final titleWrap = Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _typeLabel(type),
                          softWrap: true,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (orderBadge.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              orderBadge,
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
                    );

                    final moneyCol = Column(
                      crossAxisAlignment: stackHeader
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        _scaledMoneyText(
                          '${isCredit ? '+' : '-'}${_moneyFmt.format(amountNum.abs())}',
                          TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: amountColor,
                          ),
                          alignment: stackHeader
                              ? AlignmentDirectional.centerStart
                              : AlignmentDirectional.centerEnd,
                        ),
                        if (hasBalanceAfter) ...[
                          const SizedBox(height: 3),
                          _scaledMoneyText(
                            '${_isAr ? 'الرصيد:' : 'Bal:'} ${balanceAfter < 0 ? '-' : ''}${_moneyFmt.format(balanceAfter.abs())}',
                            TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            includeCurrency: false,
                            alignment: stackHeader
                                ? AlignmentDirectional.centerStart
                                : AlignmentDirectional.centerEnd,
                          ),
                        ],
                      ],
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            Expanded(child: titleWrap),
                            if (!stackHeader) ...[
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.42,
                                ),
                                child: moneyCol,
                              ),
                            ],
                          ],
                        ),
                        if (stackHeader) ...[
                          const SizedBox(height: 8),
                          moneyCol,
                        ],
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                        ],
                        Builder(
                          builder: (context) {
                            final receiptUrl = _resolveMediaUrl(
                              (tx['receiptUrl'] ?? '').toString(),
                            );
                            final processedBy = tx['processedBy'];
                            final processedByName = processedBy is Map
                                ? (processedBy['name'] ?? '').toString().trim()
                                : '';
                            if (receiptUrl.isEmpty && processedByName.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (receiptUrl.isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _openReceiptViewer(context, receiptUrl),
                                      icon: const Icon(
                                        LucideIcons.image,
                                        size: 14,
                                      ),
                                      label: Text(
                                        _isAr
                                            ? 'عرض إيصال التحويل'
                                            : 'View Transfer Receipt',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.45,
                                          ),
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  if (processedByName.isNotEmpty)
                                    Text(
                                      _isAr
                                          ? 'بواسطة: $processedByName'
                                          : 'By: $processedByName',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.62),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(createdAt),
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.58,
                            ),
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
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

    return _wrapIfAdminScaffold(theme, content);
  }
}
