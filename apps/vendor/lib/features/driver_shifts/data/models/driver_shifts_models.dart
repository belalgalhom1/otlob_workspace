// Plain Dart models aligned with backend driver-shifts DTOs and Prisma schema.
// No code generation required.

class ShiftPool {
  final String id;
  final String? batchId;
  final String? title;
  final String? titleAr;
  final String? zoneId;
  final String? zoneName;
  final DateTime shiftDate;
  final DateTime startTime;
  final DateTime endTime;
  final int maxDrivers;
  final List<DriverShift> driverShifts;

  const ShiftPool({
    required this.id,
    this.batchId,
    this.title,
    this.titleAr,
    this.zoneId,
    this.zoneName,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.maxDrivers,
    this.driverShifts = const [],
  });

  factory ShiftPool.fromJson(Map<String, dynamic> json) {
    return ShiftPool(
      id: json['id'] as String,
      batchId: json['batchId'] as String?,
      title: json['title'] as String?,
      titleAr: json['titleAr'] as String?,
      zoneId: json['zoneId'] as String?,
      zoneName: json['zone'] != null ? json['zone']['name'] as String? : null,
      shiftDate: DateTime.tryParse(json['shiftDate']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      maxDrivers: (json['maxDrivers'] as num?)?.toInt() ?? 0,
      driverShifts: (json['driverShifts'] as List<dynamic>?)
              ?.map((e) => DriverShift.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Title matching the active language, falling back to the other language
  /// when one side is empty.
  String? localizedTitle(String languageCode) {
    final primary = (languageCode == 'ar' ? titleAr : title)?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    final secondary = (languageCode == 'ar' ? title : titleAr)?.trim();
    if (secondary != null && secondary.isNotEmpty) return secondary;
    return null;
  }
}

class DriverShift {
  final String id;
  final String driverId;
  final String? shiftPoolId;
  final String? batchId;
  final String? poolTitle;
  final String? poolTitleAr;
  final DateTime shiftDate;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final DriverUserInfo? driver;
  final num? totalEarnings;
  final num? totalDeliveries;
  final String? zoneName;
  final String? startPhotoUrl;

  const DriverShift({
    required this.id,
    required this.driverId,
    this.shiftPoolId,
    this.batchId,
    this.poolTitle,
    this.poolTitleAr,
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.driver,
    this.totalEarnings,
    this.totalDeliveries,
    this.zoneName,
    this.startPhotoUrl,
  });

  factory DriverShift.fromJson(Map<String, dynamic> json) {
    final shiftPool = json['shiftPool'] as Map<String, dynamic>?;
    return DriverShift(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      shiftPoolId: json['shiftPoolId'] as String?,
      batchId: shiftPool?['batchId'] as String? ?? json['batchId'] as String?,
      poolTitle: shiftPool?['title'] as String? ?? json['poolTitle'] as String?,
      poolTitleAr: shiftPool?['titleAr'] as String? ?? json['poolTitleAr'] as String?,
      shiftDate: DateTime.parse(json['shiftDate'] as String).toLocal(),
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      endTime: DateTime.parse(json['endTime'] as String).toLocal(),
      status: json['status'] as String? ?? 'SCHEDULED',
      totalEarnings: json['totalEarnings'] as num?,
      totalDeliveries: json['totalDeliveries'] as num?,
      startPhotoUrl: json['startPhotoUrl'] as String?,
      zoneName: json['zone'] != null
          ? (json['zone'] is Map ? (json['zone']['name'] as String?) : null)
          : (shiftPool != null && shiftPool['zone'] != null && shiftPool['zone'] is Map ? (shiftPool['zone']['name'] as String?) : null),
      driver: json['driver'] != null
          ? DriverUserInfo.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }

  String? localizedPoolTitle(String languageCode) {
    final primary = (languageCode == 'ar' ? poolTitleAr : poolTitle)?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    final secondary = (languageCode == 'ar' ? poolTitle : poolTitleAr)?.trim();
    if (secondary != null && secondary.isNotEmpty) return secondary;
    return null;
  }
}

class DriverUserInfo {
  final String id;
  final DriverUserData user;

  const DriverUserInfo({required this.id, required this.user});

  factory DriverUserInfo.fromJson(Map<String, dynamic> json) {
    return DriverUserInfo(
      id: json['id'] as String,
      user: DriverUserData.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class DriverUserData {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? avatar;

  const DriverUserData({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatar,
  });

  factory DriverUserData.fromJson(Map<String, dynamic> json) {
    return DriverUserData(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
    );
  }
}

class GenerateShiftPoolsRequest {
  final String startDate;
  final String endDate;
  final String startTime;
  final String endTime;
  final int maxDrivers;
  final String? zoneId;
  final String? title;
  final String? titleAr;

  const GenerateShiftPoolsRequest({
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.maxDrivers,
    this.zoneId,
    this.title,
    this.titleAr,
  });

  Map<String, dynamic> toJson() => {
        'startDate': startDate,
        'endDate': endDate,
        'startTime': startTime,
        'endTime': endTime,
        'maxDrivers': maxDrivers,
        if (zoneId != null && zoneId!.isNotEmpty) 'zoneId': zoneId,
        if (title != null && title!.isNotEmpty) 'title': title,
        if (titleAr != null && titleAr!.isNotEmpty) 'titleAr': titleAr,
      };
}

class AdminAssignShiftRequest {
  final String shiftPoolId;
  final String driverId;

  const AdminAssignShiftRequest({
    required this.shiftPoolId,
    required this.driverId,
  });

  Map<String, dynamic> toJson() => {
        'shiftPoolId': shiftPoolId,
        'driverId': driverId,
      };
}
