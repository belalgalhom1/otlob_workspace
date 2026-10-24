import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/providers.dart';
import 'package:intl/intl.dart';

class DriverManagerWalletScreen extends ConsumerStatefulWidget {
  const DriverManagerWalletScreen({super.key});

  @override
  ConsumerState<DriverManagerWalletScreen> createState() =>
      _DriverManagerWalletScreenState();
}

class _DriverManagerWalletScreenState
    extends ConsumerState<DriverManagerWalletScreen> {
  bool _isLoading = true;
  String? _error;
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
      if (res is Map && mounted) {
        final bal = res['walletBalance'];
        final balNum = bal is num ? bal.toDouble() : double.tryParse(bal?.toString() ?? '0') ?? 0.0;
        final list = res['data'] is List ? (res['data'] as List) : [];
        final meta = res['meta'] is Map ? (res['meta'] as Map) : {};
        setState(() {
          _walletBalance = balNum;
          _transactions = list;
          _page = meta['page'] is int ? meta['page'] as int : 1;
          _totalPages = meta['totalPages'] is int ? meta['totalPages'] as int : 1;
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

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
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
              const Icon(LucideIcons.circleAlert, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _isAr ? 'فشل تحميل بيانات المحفظة' : 'Failed to load wallet data',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadData(),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(_isAr ? 'إعادة المحاولة' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(page: 1),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        children: [
          // Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A34), const Color(0xFF122320)]
                    : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.wallet, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isAr ? 'محفظة مدير المناديب' : 'Driver Manager Wallet',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw, color: Colors.white, size: 18),
                      tooltip: _isAr ? 'تحديث' : 'Refresh',
                      onPressed: () => _loadData(page: _page),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${_walletBalance.toStringAsFixed(2)} ${_isAr ? "ج.م" : "EGP"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isAr
                      ? 'يتم إضافة نسبة عمولة الإدارة تلقائياً عن كل طلب مكتمل في منطقتك'
                      : 'Manager commissions from completed zone orders are credited automatically',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Ledger Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isAr ? 'سجل المعاملات' : 'Transaction History',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '${_transactions.length} ${_isAr ? "معاملة" : "transactions"}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(LucideIcons.receiptText, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _isAr ? 'لا توجد معاملات بعد' : 'No transactions yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ..._transactions.map((tx) {
              if (tx is! Map) return const SizedBox.shrink();
              final amountNum = (tx['amount'] is num) ? (tx['amount'] as num).toDouble() : 0.0;
              final isCredit = amountNum >= 0;
              final balanceAfter = (tx['balanceAfter'] is num) ? (tx['balanceAfter'] as num).toDouble() : 0.0;
              final type = tx['type']?.toString() ?? 'TRANSACTION';
              final desc = tx['description']?.toString() ?? '';
              final orderId = tx['orderId']?.toString();
              final createdAt = tx['createdAt'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
                        color: isCredit ? Colors.green : Colors.red,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            desc.isNotEmpty
                                ? desc
                                : _typeLabel(type),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _formatDate(createdAt),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              if (orderId != null && orderId.isNotEmpty) ...[
                                const Text(' • ', style: TextStyle(color: Colors.grey)),
                                Text(
                                  '#${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isCredit ? "+" : ""}${amountNum.toStringAsFixed(2)} ${_isAr ? "ج.م" : "EGP"}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: isCredit ? Colors.green : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_isAr ? "الرصيد: " : "Bal: "}${balanceAfter.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          // Pagination controls
          if (_totalPages > 1) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft),
                  onPressed: _page > 1 ? () => _loadData(page: _page - 1) : null,
                ),
                Text('$_page / $_totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(LucideIcons.chevronRight),
                  onPressed: _page < _totalPages ? () => _loadData(page: _page + 1) : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
