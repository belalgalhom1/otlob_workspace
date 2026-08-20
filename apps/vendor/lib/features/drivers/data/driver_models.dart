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
    return DriverProfile(
      id: json['id'],
      userId: json['userId'],
      name: json['name'] ?? '',
      avatar: json['avatar'],
      nationalId: json['nationalId'],
      licenseNumber: json['licenseNumber'],
      vehicleType: json['vehicleType'],
      vehiclePlate: json['vehiclePlate'],
      status: json['status'] ?? 'OFFLINE',
      isSuspended: json['isSuspended'] ?? json['status'] == 'SUSPENDED',
      isApproved: json['isApproved'] ?? false,
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      location: json['location'] != null
          ? List<double>.from(json['location'].map((x) => x.toDouble()))
          : null,
      user: json['user'],
    );
  }
}
