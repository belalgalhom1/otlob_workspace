class DriverProfile {
  final String id;
  final String userId;
  final String name;
  final String? avatar;
  final String? nationalId;
  final String? licenseNumber;
  final String? vehicleType;
  final String? vehiclePlate;
  final String status; // ONLINE, OFFLINE, ON_BREAK, SUSPENDED
  final String tier; // BRONZE, SILVER, GOLD
  final bool isSuspended;
  final bool isApproved;
  final double walletBalance;
  final List<double>? location; // [longitude, latitude]
  final dynamic user; // Include nested user data if joined
  final Map<String, dynamic>? driverManager;

  String? get driverManagerName => driverManager?['name']?.toString();
  String? get phone => user is Map ? user['phone']?.toString() : null;
  String? get zoneName => (user is Map && user['zone'] is Map) ? user['zone']['name']?.toString() : null;
  String? get driverManagerUserId => driverManager?['userId']?.toString();

  DriverProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.nationalId,
    this.licenseNumber,
    this.vehicleType,
    this.vehiclePlate,
    required this.status,
    this.tier = 'BRONZE',
    required this.isSuspended,
    required this.isApproved,
    required this.walletBalance,
    this.location,
    this.user,
    this.driverManager,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    List<double>? toLocation(dynamic v) {
      try {
        if (v == null) return null;
        if (v is List) {
          return v.map((x) {
            if (x is num) return x.toDouble();
            return double.tryParse(x.toString()) ?? 0.0;
          }).toList();
        }
      } catch (_) {}
      return null;
    }

    final rawUser = json['user'];
    String resolvedName = (json['name']?.toString() ?? '').trim();
    if (resolvedName.isEmpty && rawUser is Map) {
      resolvedName = (rawUser['name']?.toString() ?? '').trim();
    }
    return DriverProfile(
      id: (json['id']?.toString() ?? '').trim(),
      userId: (json['userId']?.toString() ?? json['user_id']?.toString() ?? '').trim(),
      name: resolvedName,
      avatar: (json['avatar'] ?? (rawUser is Map ? rawUser['avatar'] : null))
          ?.toString(),
      nationalId: json['nationalId']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
      vehicleType: (json['vehicleType'] ??
              json['vehicle_type'] ??
              (json['vehicle'] is Map ? json['vehicle']['type'] : null))
          ?.toString()
          .toUpperCase()
          .trim(),
      vehiclePlate: (json['vehiclePlate'] ??
              json['vehicle_plate'] ??
              (json['vehicle'] is Map ? json['vehicle']['plate'] : null))
          ?.toString()
          .trim(),
      status: (json['status']?.toString() ?? 'OFFLINE').toUpperCase(),
      tier: (json['tier']?.toString() ?? 'BRONZE').toUpperCase(),
      isSuspended: json['isSuspended'] is bool
          ? json['isSuspended'] as bool
          : (json['status']?.toString().toUpperCase() == 'SUSPENDED'),
      isApproved: json['isApproved'] is bool
          ? json['isApproved'] as bool
          : (json['isApproved']?.toString().toLowerCase() == 'true'),
      walletBalance: toDouble(json['walletBalance']),
      location: toLocation(json['location']),
      user: rawUser,
      driverManager: json['driverManager'] is Map ? Map<String, dynamic>.from(json['driverManager']) : null,
    );
  }

  DriverProfile copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatar,
    String? nationalId,
    String? licenseNumber,
    String? vehicleType,
    String? vehiclePlate,
    String? status,
    String? tier,
    bool? isSuspended,
    bool? isApproved,
    double? walletBalance,
    List<double>? location,
    dynamic user,
    Map<String, dynamic>? driverManager,
  }) {
    return DriverProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      nationalId: nationalId ?? this.nationalId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      status: status ?? this.status,
      tier: tier ?? this.tier,
      isSuspended: isSuspended ?? this.isSuspended,
      isApproved: isApproved ?? this.isApproved,
      walletBalance: walletBalance ?? this.walletBalance,
      location: location ?? this.location,
      user: user ?? this.user,
      driverManager: driverManager ?? this.driverManager,
    );
  }
}
