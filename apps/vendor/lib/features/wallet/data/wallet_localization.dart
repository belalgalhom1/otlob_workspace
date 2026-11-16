import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Shared localization, formatting, and currency helpers for all Wallet &
/// Finances screens in the Vendor/Admin app so Arabic/English modes stay
/// consistent without relying on `intl` Arabic locale initialization.
class WalletLocalization {
  static const List<String> _arMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static final RegExp _orderRevenueRegex = RegExp(
    r'^Order\s+([A-Za-z0-9_-]+)(?:\s*\(([^)]+)\))?\s+revenue$',
    caseSensitive: false,
  );
  static final RegExp _commissionForOrderRegex = RegExp(
    r'^Commission\s+for\s+order\s+([A-Za-z0-9_-]+)(?:\s*\(([^)]+)\))?$',
    caseSensitive: false,
  );
  static final RegExp _managerShareRegex = RegExp(
    r'^Delivery\s+manager\s+share\s+for\s+order\s+([A-Za-z0-9_-]+)$',
    caseSensitive: false,
  );
  static final RegExp _cashCollectedRegex = RegExp(
    r'^Cash\s+collected\s+(?:for\s+)?order\s+([A-Za-z0-9_-]+)(?:\s*\(([^)]+)\))?$',
    caseSensitive: false,
  );
  static final RegExp _orderNumInDescRegex = RegExp(
    r'\b(ORD-[A-Za-z0-9_-]+)\b',
    caseSensitive: false,
  );

  static String currency(bool isArabic) => isArabic ? 'ج.م' : 'EGP';

  static String formatAmountWithCurrency(
    double amount, {
    required bool isArabic,
    bool signed = false,
    NumberFormat? formatter,
  }) {
    final fmt = formatter ?? NumberFormat('#,##0.00', 'en_US');
    final sign = signed
        ? (amount > 0 ? '+' : amount < 0 ? '-' : '')
        : (amount < 0 ? '-' : '');
    return '$sign${fmt.format(amount.abs())} ${currency(isArabic)}';
  }

  /// Renders tabular numbers on the leading side and currency adjacent without
  /// bidirectional `-`/`+` sign flips in Arabic RTL.
  static Widget buildMoneyText(
    String formattedNumberWithSign,
    TextStyle style, {
    required bool isArabic,
    bool includeCurrency = true,
    AlignmentDirectional alignment = AlignmentDirectional.centerEnd,
  }) {
    final effectiveStyle = style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              formattedNumberWithSign,
              maxLines: 1,
              style: effectiveStyle,
            ),
          ),
          if (includeCurrency) ...[
            const SizedBox(width: 4),
            Text(
              currency(isArabic),
              maxLines: 1,
              style: effectiveStyle,
            ),
          ],
        ],
      ),
    );
  }

  static String typeLabel(String rawType, {required bool isArabic}) {
    switch (rawType.trim().toUpperCase()) {
      case 'ORDER_REVENUE':
        return isArabic ? 'إيراد طلب' : 'Order Revenue';
      case 'COMMISSION_DEDUCTION':
      case 'COMMISSION':
        return isArabic ? 'خصم عمولة' : 'Commission';
      case 'CASH_COLLECTED':
      case 'CASH_COLLECTION':
        return isArabic ? 'تحصيل نقدي' : 'Cash Collected';
      case 'PAYOUT':
        return isArabic ? 'مدفوعات' : 'Payout';
      case 'REFUND':
        return isArabic ? 'استرداد' : 'Refund';
      case 'ADJUSTMENT':
        return isArabic ? 'تسوية' : 'Adjustment';
      case 'MANUAL_ADJUSTMENT':
        return isArabic ? 'تسوية يدوية' : 'Manual Adjustment';
      case 'TOP_UP':
      case 'TOPUP':
        return isArabic ? 'شحن محفظة' : 'Top Up';
      case 'COMMISSION_EARNED':
        return isArabic ? 'عمولة إدارة طلب' : 'Order Commission';
      case 'DELIVERY_SHARE':
        return isArabic ? 'نسبة مسؤول التوصيل' : 'Delivery Manager Share';
      case 'PENALTY':
      case 'PENALTY_DEDUCTION':
        return isArabic ? 'خصم جزاءات' : 'Penalty Deduction';
      default:
        final pretty = rawType.replaceAll('_', ' ').trim();
        if (pretty.isEmpty) {
          return isArabic ? 'معاملة' : 'Transaction';
        }
        return pretty;
    }
  }

  static String? branchDisplayName(Map tx, {required bool isArabic}) {
    final fulfillment = tx['fulfillment'];
    final fBranch = fulfillment is Map ? fulfillment['vendorBranch'] : null;
    final orderObj = tx['order'];
    final oBranch = orderObj is Map ? orderObj['vendorBranch'] : null;
    final branch = fBranch is Map
        ? fBranch
        : (oBranch is Map ? oBranch : null);
    if (branch == null) return null;

    final ar = branch['nameAr']?.toString().trim() ?? '';
    final en = branch['name']?.toString().trim() ?? '';
    final picked = isArabic ? (ar.isNotEmpty ? ar : en) : (en.isNotEmpty ? en : ar);
    return picked.isEmpty ? null : picked;
  }

  static String extractOrderNumber(Map tx) {
    final orderObj = tx['order'];
    if (orderObj is Map) {
      final num = orderObj['orderNumber']?.toString().trim() ?? '';
      if (num.isNotEmpty) return num;
    }
    final direct = tx['orderNumber']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;

    final rawDesc = tx['description']?.toString() ?? '';
    final match = _orderNumInDescRegex.firstMatch(rawDesc);
    if (match != null) return match.group(1)!.toUpperCase();
    return '';
  }

  /// Translates backend-generated settlement/system descriptions (including
  /// historical English rows stored in Postgres) using attached localized
  /// relations (`order`, `vendorBranch.nameAr`) or regex templates. Custom
  /// free-form admin notes are returned unchanged.
  static String localizeDescription(Map tx, {required bool isArabic}) {
    final rawDesc = (tx['description'] ?? '').toString().trim();
    final type = (tx['type'] ?? '').toString().trim().toUpperCase();
    final orderNum = extractOrderNumber(tx);
    final localizedBranch = branchDisplayName(tx, isArabic: isArabic);

    final revMatch = _orderRevenueRegex.firstMatch(rawDesc);
    if (revMatch != null) {
      final ord = orderNum.isNotEmpty ? orderNum : revMatch.group(1)!.trim();
      final branch =
          localizedBranch ?? (revMatch.group(2)?.trim() ?? '');
      if (isArabic) {
        return branch.isNotEmpty ? 'إيراد الطلب $ord ($branch)' : 'إيراد الطلب $ord';
      }
      return branch.isNotEmpty ? 'Order $ord ($branch) revenue' : 'Order $ord revenue';
    }

    final commMatch = _commissionForOrderRegex.firstMatch(rawDesc);
    if (commMatch != null) {
      final ord = orderNum.isNotEmpty ? orderNum : commMatch.group(1)!.trim();
      final branch =
          localizedBranch ?? (commMatch.group(2)?.trim() ?? '');
      if (isArabic) {
        return branch.isNotEmpty ? 'عمولة الطلب $ord ($branch)' : 'عمولة الطلب $ord';
      }
      return branch.isNotEmpty
          ? 'Commission for order $ord ($branch)'
          : 'Commission for order $ord';
    }

    final mgrMatch = _managerShareRegex.firstMatch(rawDesc);
    if (mgrMatch != null) {
      final ord = orderNum.isNotEmpty ? orderNum : mgrMatch.group(1)!.trim();
      return isArabic
          ? 'نسبة إدارة التوصيل للطلب $ord'
          : 'Delivery manager share for order $ord';
    }

    final cashMatch = _cashCollectedRegex.firstMatch(rawDesc);
    if (cashMatch != null) {
      final ord = orderNum.isNotEmpty ? orderNum : cashMatch.group(1)!.trim();
      final branch =
          localizedBranch ?? (cashMatch.group(2)?.trim() ?? '');
      if (isArabic) {
        return branch.isNotEmpty
            ? 'تحصيل نقدي للطلب $ord ($branch)'
            : 'تحصيل نقدي للطلب $ord';
      }
      return rawDesc;
    }

    final lower = rawDesc.toLowerCase();
    if (lower == 'manual admin transaction' ||
        lower == 'manual admin adjustment') {
      return isArabic ? 'معاملة إدارية يدوية' : rawDesc;
    }
    if (lower == 'manual driver manager transaction') {
      return isArabic ? 'معاملة يدوية لإدارة التوصيل' : rawDesc;
    }

    if (rawDesc.isEmpty && orderNum.isNotEmpty) {
      final branch = localizedBranch ?? '';
      if (type == 'ORDER_REVENUE') {
        if (isArabic) {
          return branch.isNotEmpty
              ? 'إيراد الطلب $orderNum ($branch)'
              : 'إيراد الطلب $orderNum';
        }
        return branch.isNotEmpty
            ? 'Order $orderNum ($branch) revenue'
            : 'Order $orderNum revenue';
      }
      if (type == 'COMMISSION_DEDUCTION' || type == 'COMMISSION') {
        if (isArabic) {
          return branch.isNotEmpty
              ? 'عمولة الطلب $orderNum ($branch)'
              : 'عمولة الطلب $orderNum';
        }
        return branch.isNotEmpty
            ? 'Commission for order $orderNum ($branch)'
            : 'Commission for order $orderNum';
      }
    }

    return rawDesc;
  }

  static String formatDateTime(
    dynamic rawDate, {
    required bool isArabic,
    bool includeTime = true,
  }) {
    if (rawDate == null) return '';
    final dt = rawDate is DateTime
        ? rawDate.toLocal()
        : DateTime.tryParse(rawDate.toString())?.toLocal();
    if (dt == null) return rawDate.toString();

    if (!isArabic) {
      return DateFormat(
        includeTime ? 'MMM dd, yyyy - hh:mm a' : 'MMM dd, yyyy',
        'en_US',
      ).format(dt);
    }

    final baseDate = '${dt.day} ${_arMonths[dt.month - 1]} ${dt.year}';
    if (!includeTime) return baseDate;

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'ص' : 'م';
    return '$baseDate - $hour12:$minute $period';
  }
}
