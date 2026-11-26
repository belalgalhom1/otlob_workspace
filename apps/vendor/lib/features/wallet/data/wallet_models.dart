class WalletTopUpRequest {
  final String id;
  final String driverId;
  final double amount;
  final String status; // PENDING, APPROVED, REJECTED
  final String receiptUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? approvedById;
  final String? approvedByName;
  final String? platformWalletId;
  final String? platformWalletType;
  final String? platformWalletNumber;
  final String? driverName;
  final String? driverPhone;
  final String? driverAvatar;
  final double? driverWalletBalance;

  WalletTopUpRequest({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.status,
    required this.receiptUrl,
    this.notes,
    required this.createdAt,
    this.reviewedAt,
    this.approvedById,
    this.approvedByName,
    this.platformWalletId,
    this.platformWalletType,
    this.platformWalletNumber,
    this.driverName,
    this.driverPhone,
    this.driverAvatar,
    this.driverWalletBalance,
  });

  String platformWalletLabel({required bool isArabic}) {
    final normalizedType = (platformWalletType ?? '').trim().toUpperCase();
    final typeLabel = normalizedType.isEmpty
        ? ''
        : normalizedType.contains('INSTAPAY')
            ? (isArabic ? 'إنستا باي' : 'InstaPay')
            : (isArabic ? 'محفظة إلكترونية' : 'Mobile Wallet');
    final number = (platformWalletNumber ?? '').trim();
    if (typeLabel.isNotEmpty && number.isNotEmpty) {
      return '$typeLabel - $number';
    }
    return typeLabel.isNotEmpty ? typeLabel : number;
  }

  factory WalletTopUpRequest.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'] is Map ? json['driver'] as Map : null;
    final user = driver != null && driver['user'] is Map
        ? driver['user'] as Map
        : null;
    final platformWallet = json['platformWallet'] is Map
        ? json['platformWallet'] as Map
        : null;
    final approvedBy = json['approvedBy'] is Map
        ? json['approvedBy'] as Map
        : null;

    final rawName = user?['name'] ?? driver?['name'];
    final rawAvatar = driver?['avatar'] ?? user?['avatar'];
    final rawPhone = user?['phone'] ?? driver?['phone'];
    final rawBalance = driver?['walletBalance'];
    final rawReviewedAt = json['reviewedAt']?.toString();

    return WalletTopUpRequest(
      id: (json['id'] ?? '').toString(),
      driverId: (json['driverId'] ?? '').toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      status: (json['status'] ?? 'PENDING').toString(),
      receiptUrl: (json['receiptUrl'] ?? '').toString(),
      notes: json['notes']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAt: rawReviewedAt != null && rawReviewedAt.isNotEmpty
          ? DateTime.tryParse(rawReviewedAt)
          : null,
      approvedById: json['approvedById']?.toString(),
      approvedByName: approvedBy?['name']?.toString(),
      platformWalletId: json['platformWalletId']?.toString(),
      platformWalletType: platformWallet?['type']?.toString(),
      platformWalletNumber: platformWallet?['number']?.toString(),
      driverName: rawName?.toString(),
      driverPhone: rawPhone?.toString(),
      driverAvatar: rawAvatar?.toString(),
      driverWalletBalance: rawBalance != null
          ? double.tryParse(rawBalance.toString())
          : null,
    );
  }
}

class PlatformWallet {
  final String id;
  final String provider; // e.g. MOBILE_WALLET
  final String number;
  final bool isActive;

  PlatformWallet({
    required this.id,
    required this.provider,
    required this.number,
    required this.isActive,
  });

  factory PlatformWallet.fromJson(Map<String, dynamic> json) {
    return PlatformWallet(
      id: json['id'],
      provider: json['provider'],
      number: json['number'] ?? json['accountNumber'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}

class WalletTransaction {
  final String id;
  final String? vendorId;
  final String? driverId;
  final String type; // e.g. PAYOUT, REFUND, TOP_UP, PENALTY, CASH_COLLECTION
  final double amount;
  final double balanceAfter;
  final String? description;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    this.vendorId,
    this.driverId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      vendorId: json['vendorId'],
      driverId: json['driverId'],
      type: json['type'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      balanceAfter: double.tryParse(json['balanceAfter']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
