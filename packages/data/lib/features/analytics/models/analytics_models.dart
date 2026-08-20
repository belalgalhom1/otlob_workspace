class AnalyticsDriver {
  final String id;
  final int totalOrders;
  final num walletBalance;
  final String tier;
  final String status;
  final String name;
  final String? phone;
  final String? avatar;

  AnalyticsDriver({
    required this.id,
    required this.totalOrders,
    required this.walletBalance,
    required this.tier,
    required this.status,
    required this.name,
    this.phone,
    this.avatar,
  });

  factory AnalyticsDriver.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return AnalyticsDriver(
      id: json['id'] as String,
      totalOrders: json['totalOrders'] as int? ?? 0,
      walletBalance: json['walletBalance'] as num? ?? 0,
      tier: json['tier'] as String? ?? 'BRONZE',
      status: json['status'] as String? ?? 'OFFLINE',
      name: user['name'] as String? ?? 'Unknown',
      phone: user['phone'] as String?,
      avatar: user['avatar'] as String?,
    );
  }
}

class AnalyticsCustomer {
  final String id;
  final int totalOrders;
  final num totalSpent;
  final num coinBalance;
  final String name;
  final String? phone;
  final String? avatar;

  AnalyticsCustomer({
    required this.id,
    required this.totalOrders,
    required this.totalSpent,
    required this.coinBalance,
    required this.name,
    this.phone,
    this.avatar,
  });

  factory AnalyticsCustomer.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return AnalyticsCustomer(
      id: json['id'] as String,
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalSpent: json['totalSpent'] as num? ?? 0,
      coinBalance: json['coinBalance'] as num? ?? 0,
      name: user['name'] as String? ?? 'Unknown',
      phone: user['phone'] as String?,
      avatar: user['avatar'] as String?,
    );
  }
}

class AnalyticsTopProduct {
  final String name;
  final String? nameAr;
  final String? imageUrl;
  final int totalOrders;

  AnalyticsTopProduct({
    required this.name,
    this.nameAr,
    this.imageUrl,
    required this.totalOrders,
  });

  factory AnalyticsTopProduct.fromJson(Map<String, dynamic> json) {
    return AnalyticsTopProduct(
      name: json['name'] as String? ?? 'Unknown',
      nameAr: json['nameAr'] as String?,
      imageUrl: json['imageUrl'] as String?,
      totalOrders: json['totalOrders'] as int? ?? 0,
    );
  }
}

class AnalyticsVendor {
  final String id;
  final String storeName;
  final String? storeNameAr;
  final String? logo;
  final num walletBalance;
  final int totalOrders;
  final num totalRevenue;
  final AnalyticsTopProduct? topProduct;

  AnalyticsVendor({
    required this.id,
    required this.storeName,
    this.storeNameAr,
    this.logo,
    required this.walletBalance,
    required this.totalOrders,
    required this.totalRevenue,
    this.topProduct,
  });

  factory AnalyticsVendor.fromJson(Map<String, dynamic> json) {
    return AnalyticsVendor(
      id: json['id'] as String,
      storeName: json['storeName'] as String? ?? 'Unknown',
      storeNameAr: json['storeNameAr'] as String?,
      logo: json['logo'] as String?,
      walletBalance: json['walletBalance'] as num? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalRevenue: json['totalRevenue'] as num? ?? 0,
      topProduct: json['topProduct'] != null ? AnalyticsTopProduct.fromJson(json['topProduct']) : null,
    );
  }
}
