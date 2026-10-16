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
  final bool isSuspended;
  final bool isApproved;
  final double walletBalance;
  final List<double>? location; // [longitude, latitude]
  final dynamic user; // Include nested user data if joined

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
    required this.isSuspended,
    required this.isApproved,
    required this.walletBalance,
    this.location,
    this.user,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    List<double>? _toLocation(dynamic v) {
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
      avatar: json['avatar']?.toString(),
      nationalId: json['nationalId']?.toString(),
      licenseNumber: json['licenseNumber']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString(),
      status: (json['status']?.toString() ?? 'OFFLINE').toUpperCase(),
      isSuspended: json['isSuspended'] is bool
          ? json['isSuspended'] as bool
          : (json['status']?.toString().toUpperCase() == 'SUSPENDED'),
      isApproved: json['isApproved'] is bool
          ? json['isApproved'] as bool
          : (json['isApproved']?.toString().toLowerCase() == 'true'),
      walletBalance: _toDouble(json['walletBalance']),
      location: _toLocation(json['location']),
      user: rawUser,
    );
  }
}
