class AuditLog {
  final String id;
  final String actionType; // CREATE, UPDATE, DELETE, OTHER
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> details;
  final String userId;
  final String? vendorId;
  final DateTime createdAt;
  final dynamic user; // For displaying name/email if returned

  AuditLog({
    required this.id,
    required this.actionType,
    required this.entityType,
    this.entityId,
    required this.details,
    required this.userId,
    this.vendorId,
    required this.createdAt,
    this.user,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      actionType: json['actionType'],
      entityType: json['entityType'],
      entityId: json['entityId'],
      details: json['details'] is Map ? json['details'] : {},
      userId: json['userId'],
      vendorId: json['vendorId'],
      createdAt: DateTime.parse(json['createdAt']),
      user: json['user'],
    );
  }
}
