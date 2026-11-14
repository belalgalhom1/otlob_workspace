import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vendor/core/providers.dart';

part 'vendor_wallet_provider.g.dart';

@riverpod
class VendorWalletData extends _$VendorWalletData {
  static const int pageSize = 20;

  String? _type;
  String? _branchId;
  DateTime? _from;
  DateTime? _to;
  int _page = 1;

  String? get selectedType => _type;
  String? get selectedBranchId => _branchId;
  DateTime? get fromDate => _from;
  DateTime? get toDate => _to;

  @override
  Future<Map<String, dynamic>> build() async {
    final activeVendor = ref.watch(activeVendorProvider);
    if (activeVendor == null) return {};

    _page = 1;
    return _fetch(activeVendor);
  }

  Future<void> applyFilters({
    String? type,
    String? branchId,
    DateTime? from,
    DateTime? to,
    bool clearType = false,
    bool clearBranch = false,
    bool clearDates = false,
  }) async {
    if (clearType) {
      _type = null;
    } else if (type != null) {
      _type = type;
    }
    if (clearBranch) {
      _branchId = null;
    } else if (branchId != null) {
      _branchId = branchId;
    }
    if (clearDates) {
      _from = null;
      _to = null;
    } else {
      if (from != null) _from = from;
      if (to != null) _to = to;
    }
    await _reload();
  }

  Future<void> setType(String? type) async {
    _type = type;
    await _reload();
  }

  Future<void> setBranch(String? branchId) async {
    _branchId = branchId;
    await _reload();
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    _from = from;
    _to = to;
    await _reload();
  }

  Future<void> clearFilters() async {
    _type = null;
    _branchId = null;
    _from = null;
    _to = null;
    await _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current['hasMore'] != true || state.isLoading) {
      return;
    }
    final vendorId = ref.read(activeVendorProvider);
    if (vendorId == null) return;

    final nextPage = _page + 1;
    try {
      final repo = ref.read(vendorWalletRepositoryProvider);
      final transactionsRes = await repo.vendorWalletGetTransactions(
        vendorId,
        type: _type,
        branchId: _branchId,
        from: _dateParam(_from),
        to: _dateParam(_to),
        page: nextPage,
        limit: pageSize,
      );
      final newTransactions = _extractTransactions(transactionsRes);
      final totalPages = _totalPages(transactionsRes, nextPage);

      _page = nextPage;
      final merged = <dynamic>[
        ...(current['transactions'] as List<dynamic>),
        ...newTransactions,
      ];

      state = AsyncData({
        ...current,
        'transactions': merged,
        'page': _page,
        'totalPages': totalPages,
        'hasMore': _page < totalPages,
      });
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _reload() async {
    final vendorId = ref.read(activeVendorProvider);
    if (vendorId == null) return;

    _page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(vendorId));
  }

  Future<Map<String, dynamic>> _fetch(String vendorId) async {
    final repo = ref.read(vendorWalletRepositoryProvider);
    final branchesRepo = ref.read(vendorBranchesRepositoryProvider);

    // Balance, page, summary, and branches are independent; fetch together.
    final results = await Future.wait<dynamic>([
      repo.vendorWalletGetBalance(vendorId),
      repo.vendorWalletGetTransactions(
        vendorId,
        type: _type,
        branchId: _branchId,
        from: _dateParam(_from),
        to: _dateParam(_to),
        page: _page,
        limit: pageSize,
      ),
      repo.vendorWalletGetSummary(
        vendorId,
        type: _type,
        branchId: _branchId,
        from: _dateParam(_from),
        to: _dateParam(_to),
      ),
      branchesRepo.getBranches(vendorId).catchError((_) => const <dynamic>[]),
    ]);

    final balanceData = results[0];
    final transactionsRes = results[1];
    final summary = results[2];
    final branchesRaw = results[3];

    final branches = _extractBranches(branchesRaw);
    final transactions = _extractTransactions(transactionsRes);
    final totalPages = _totalPages(transactionsRes, _page);

    return {
      'balance': balanceData is Map
          ? balanceData
          : {'walletBalance': balanceData ?? 0},
      'summary': summary is Map ? summary : <String, dynamic>{},
      'branches': branches,
      'transactions': transactions,
      'page': _page,
      'totalPages': totalPages,
      'hasMore': _page < totalPages,
      'total': transactionsRes is Map
          ? (transactionsRes['total'] ?? transactions.length)
          : transactions.length,
    };
  }

  static List<dynamic> _extractBranches(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      if (response['data'] is List) return response['data'] as List<dynamic>;
      if (response['branches'] is List) {
        return response['branches'] as List<dynamic>;
      }
    }
    return const [];
  }

  static List<dynamic> _extractTransactions(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      if (response['transactions'] is List) {
        return response['transactions'] as List<dynamic>;
      }
      if (response['data'] is List) {
        return response['data'] as List<dynamic>;
      }
    }
    return const [];
  }

  static int _totalPages(dynamic response, int fallbackPage) {
    if (response is Map) {
      final totalPages = response['totalPages'];
      if (totalPages is num) return totalPages.toInt();
    }
    return fallbackPage;
  }

  static String? _dateParam(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
