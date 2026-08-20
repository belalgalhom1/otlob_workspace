class WalletTopUpRequest {
  final String id;
  final String driverId;
  final double amount;
  final String status; // PENDING, APPROVED, REJECTED
  final String receiptUrl;
  final String? notes;
  final DateTime createdAt;
  final String? driverName;

  WalletTopUpRequest({
    required this.id,
    required this.driverId,
    required this.amount,
    required this.status,
    required this.receiptUrl,
    this.notes,
    required this.createdAt,
    this.driverName,
  });

  factory WalletTopUpRequest.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'];
    final user = driver is Map ? driver['user'] : null;
    final name = user is Map ? user['name'] : null;
    return WalletTopUpRequest(
      id: json['id'] ?? '',
      driverId: json['driverId'] ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'PENDING',
      receiptUrl: json['receiptUrl'] ?? '',
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      driverName: name,
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

class ManualTransactionDto {
  final String type;
  final double amount;
  final String? description;
  final String? referenceId;

  ManualTransactionDto({
    required this.type,
    required this.amount,
    this.description,
    this.referenceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      if (description != null) 'description': description,
      if (referenceId != null) 'referenceId': referenceId,
    };
  }
}
