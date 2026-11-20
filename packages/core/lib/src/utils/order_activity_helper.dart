import 'image_utils.dart';

/// Parsed actor information for an order cancellation or status event.
class OrderActorInfo {
  final String name;
  final String? nameAr;
  final String? role;
  final String? avatar;
  final String? userId;
  final String? vendorId;
  final String? reason;
  final DateTime? cancelledAt;
  final bool isSystem;

  const OrderActorInfo({
    required this.name,
    this.nameAr,
    this.role,
    this.avatar,
    this.userId,
    this.vendorId,
    this.reason,
    this.cancelledAt,
    this.isSystem = false,
  });

  String? get resolvedAvatarUrl {
    final formatted = ImageUtils.formatImageUrl(avatar);
    return formatted.isEmpty ? null : formatted;
  }

  String displayName({required bool isArabic}) {
    if (isArabic && nameAr != null && nameAr!.trim().isNotEmpty) {
      return nameAr!.trim();
    }
    if (name.trim().isNotEmpty) {
      final trimmed = name.trim();
      final lower = trimmed.toLowerCase();
      if (lower == 'system' && isSystem) {
        return OrderActivityHelper.roleLabel(null, isArabic: isArabic, isSystem: true);
      }
      if (lower == 'user' || lower == 'unknown') {
        return OrderActivityHelper.roleLabel(role, isArabic: isArabic, isSystem: isSystem);
      }
      return trimmed;
    }
    return OrderActivityHelper.roleLabel(role, isArabic: isArabic, isSystem: isSystem);
  }
}

/// Shared single-source-of-truth helpers for order activity logs,
/// actor resolution, and cancellation attribution across all apps.
class OrderActivityHelper {
  const OrderActivityHelper._();

  static String roleLabel(
    String? role, {
    required bool isArabic,
    bool isSystem = false,
  }) {
    if (isSystem || role?.toUpperCase() == 'SYSTEM') {
      return isArabic ? 'النظام' : 'System';
    }
    switch (role?.toUpperCase()) {
      case 'CUSTOMER':
        return isArabic ? 'العميل' : 'Customer';
      case 'DRIVER':
        return isArabic ? 'السائق' : 'Driver';
      case 'DRIVER_MANAGER':
        return isArabic ? 'مشرف السائقين' : 'Driver Manager';
      case 'VENDOR_MEMBER':
        return isArabic ? 'المتجر' : 'Vendor';
      case 'ADMIN':
        return isArabic ? 'الإدارة' : 'Admin';
      case 'SUPER_ADMIN':
        return isArabic ? 'المدير العام' : 'Super Admin';
      default:
        return isArabic ? 'مستخدم' : 'User';
    }
  }

  /// Resolves the actor snapshot attached to a single [OrderStatusEvent] map.
  static OrderActorInfo? resolveEventActor(Map<String, dynamic> event) {
    final actorMap = _asMap(event['actor']);
    final userId = _nonEmpty(actorMap?['id']) ?? _nonEmpty(event['actorUserId']);
    final name = _nonEmpty(actorMap?['name']) ?? _nonEmpty(event['actorName']);
    final nameAr = _nonEmpty(actorMap?['nameAr']) ?? _nonEmpty(event['actorNameAr']);
    final role = _nonEmpty(actorMap?['role']) ?? _nonEmpty(event['actorRole']);
    final avatar = _nonEmpty(actorMap?['avatar']) ?? _nonEmpty(event['actorAvatar']);
    final vendorId =
        _nonEmpty(actorMap?['vendorId']) ?? _nonEmpty(event['actorVendorId']);
    final isSystem = actorMap?['isSystem'] == true ||
        (role?.toUpperCase() == 'SYSTEM');

    if (name == null &&
        nameAr == null &&
        userId == null &&
        role == null &&
        avatar == null &&
        !isSystem) {
      return null;
    }

    return OrderActorInfo(
      name: name ?? '',
      nameAr: nameAr,
      role: role,
      avatar: avatar,
      userId: userId,
      vendorId: vendorId,
      isSystem: isSystem,
    );
  }

  /// Resolves who cancelled [order], preferring the backend's `cancelledBy`
  /// payload, then flat `cancelledBy*` columns, then the latest `CANCELLED` event.
  static OrderActorInfo? resolveCancelledBy(Map<String, dynamic> order) {
    final cancelledBy = _asMap(order['cancelledBy']);
    final reason = _nonEmpty(cancelledBy?['reason']) ??
        _nonEmpty(order['cancelReason']) ??
        _nonEmpty(order['cancellationReason']);
    final cancelledAt = _parseDate(
      cancelledBy?['cancelledAt'] ?? order['cancelledAt'],
    );

    if (cancelledBy != null) {
      return OrderActorInfo(
        name: _nonEmpty(cancelledBy['name']) ?? '',
        nameAr: _nonEmpty(cancelledBy['nameAr']),
        role: _nonEmpty(cancelledBy['role']),
        avatar: _nonEmpty(cancelledBy['avatar']),
        userId: _nonEmpty(cancelledBy['userId']),
        vendorId: _nonEmpty(cancelledBy['vendorId']),
        reason: reason,
        cancelledAt: cancelledAt,
        isSystem: cancelledBy['isSystem'] == true,
      );
    }

    final flatName = _nonEmpty(order['cancelledByName']);
    final flatNameAr = _nonEmpty(order['cancelledByNameAr']);
    final flatRole = _nonEmpty(order['cancelledByRole']);
    final flatAvatar = _nonEmpty(order['cancelledByAvatar']);
    final flatUserId = _nonEmpty(order['cancelledByUserId']);
    if (flatName != null ||
        flatNameAr != null ||
        flatRole != null ||
        flatAvatar != null ||
        flatUserId != null) {
      return OrderActorInfo(
        name: flatName ?? '',
        nameAr: flatNameAr,
        role: flatRole,
        avatar: flatAvatar,
        userId: flatUserId,
        reason: reason,
        cancelledAt: cancelledAt,
        isSystem: flatRole?.toUpperCase() == 'SYSTEM',
      );
    }

    final events = order['statusEvents'];
    if (events is List) {
      for (final raw in events.reversed) {
        final ev = _asMap(raw);
        if (ev == null) continue;
        if (ev['status']?.toString().toUpperCase() == 'CANCELLED') {
          final actor = resolveEventActor(ev);
          if (actor != null) {
            return OrderActorInfo(
              name: actor.name,
              nameAr: actor.nameAr,
              role: actor.role,
              avatar: actor.avatar,
              userId: actor.userId,
              vendorId: actor.vendorId,
              reason: reason ?? _extractReasonFromNote(_nonEmpty(ev['note'])),
              cancelledAt: cancelledAt ?? _parseDate(ev['createdAt']),
              isSystem: actor.isSystem,
            );
          }
        }
      }
    }

    final status = order['status']?.toString().toUpperCase();
    if (status == 'CANCELLED') {
      return OrderActorInfo(
        name: '',
        reason: reason,
        cancelledAt: cancelledAt,
        isSystem: true,
      );
    }
    return null;
  }

  /// Localized headline e.g. `Canceled by Ahmed Ali` / `تم الإلغاء بواسطة أحمد علي`.
  static String formatCanceledByHeadline(
    OrderActorInfo actor, {
    required bool isArabic,
  }) {
    final name = actor.displayName(isArabic: isArabic);
    return isArabic ? 'تم الإلغاء بواسطة $name' : 'Canceled by $name';
  }

  /// Preserves all legitimate activity entries (never collapses distinct events
  /// solely by status) while deduplicating only identical `id` or `eventKey`.
  static List<Map<String, dynamic>> normalizeTimelineEvents(
    List<dynamic>? rawEvents, {
    bool newestFirst = false,
  }) {
    if (rawEvents == null || rawEvents.isEmpty) return const [];

    final seenIds = <String>{};
    final seenKeys = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final item in rawEvents) {
      final map = _asMap(item);
      if (map == null) continue;
      final id = _nonEmpty(map['id']);
      final eventKey = _nonEmpty(map['eventKey']);
      if (id != null && !seenIds.add(id)) continue;
      if (eventKey != null && !seenKeys.add(eventKey)) continue;
      result.add(map);
    }

    result.sort((a, b) {
      final da = _parseDate(a['createdAt']);
      final db = _parseDate(b['createdAt']);
      if (da == null && db == null) return 0;
      if (da == null) return newestFirst ? 1 : -1;
      if (db == null) return newestFirst ? -1 : 1;
      return newestFirst ? db.compareTo(da) : da.compareTo(db);
    });

    return result;
  }

  /// Formats and localizes backend status-event notes while keeping actor
  /// context accurate (replacing legacy `"Cancelled by user"` when actor exists).
  static String formatEventNote(
    String? rawNote, {
    String? status,
    OrderActorInfo? actor,
    required bool isArabic,
  }) {
    final trimmed = rawNote?.trim() ?? '';
    final statusUpper = status?.toUpperCase() ?? '';

    if (trimmed.isEmpty) {
      if (statusUpper == 'CANCELLED' && actor != null) {
        return formatCanceledByHeadline(actor, isArabic: isArabic);
      }
      return '';
    }

    final lower = trimmed.toLowerCase();

    if (statusUpper == 'CANCELLED' ||
        lower.startsWith('cancelled by ') ||
        lower.startsWith('canceled by ') ||
        lower.startsWith('order cancelled') ||
        lower.startsWith('order canceled')) {
      final extractedReason = _extractReasonFromNote(trimmed);
      final genericMatch = lower == 'cancelled by user' ||
          lower == 'canceled by user' ||
          lower.startsWith('cancelled by user (') ||
          lower.startsWith('canceled by user —') ||
          lower.startsWith('canceled by user -') ||
          lower == 'order cancelled by customer' ||
          lower == 'order cancelled by driver' ||
          lower == 'order cancelled by vendor' ||
          lower == 'order cancelled by admin' ||
          lower == 'order cancelled by super admin' ||
          lower == 'cancelled by customer' ||
          lower == 'cancelled by driver' ||
          lower == 'cancelled by vendor' ||
          lower == 'cancelled by admin' ||
          lower == 'cancelled by super admin';

      if (actor != null &&
          (genericMatch || actor.name.trim().isNotEmpty)) {
        final headline = formatCanceledByHeadline(actor, isArabic: isArabic);
        if (extractedReason != null &&
            !headline.toLowerCase().contains(extractedReason.toLowerCase())) {
          final reasonLabel = isArabic ? 'السبب' : 'Reason';
          return '$headline — $reasonLabel: $extractedReason';
        }
        return headline;
      }

      if (isArabic) {
        return trimmed
            .replaceFirst(
              RegExp(r'^(Order\s+)?Cancell?ed by\s+', caseSensitive: false),
              'تم الإلغاء بواسطة ',
            )
            .replaceAll('— Reason:', '— السبب:')
            .replaceAll('Reason:', 'السبب:');
      }
      return trimmed.replaceFirst(
        RegExp(r'^(Order\s+)?Cancelled by', caseSensitive: false),
        'Canceled by',
      );
    }

    if (!isArabic) return trimmed;

    // Known static & parameterized backend lifecycle notes -> clean Arabic
    const staticTranslations = <String, String>{
      'order placed': 'تم تقديم الطلب',
      'order confirmed by vendor': 'تم تأكيد الطلب من المتجر',
      'all vendor portions accepted': 'تم قبول جميع أجزاء الطلب من المتاجر',
      'all vendor portions started preparing': 'بدأ تجهيز جميع أجزاء الطلب',
      'order is being prepared': 'جاري تجهيز الطلب',
      'all vendor portions ready for pickup': 'جميع أجزاء الطلب جاهزة للاستلام',
      'driver is collecting portions from stores':
          'السائق يقوم باستلام الطلبات من المتاجر',
      'all deliveries picked up': 'تم استلام جميع التوصيلات',
      'all deliveries completed': 'تم إكمال جميع التوصيلات',
      'looking for driver': 'جاري البحث عن سائق',
      'driver assigned': 'تم تعيين السائق للطلب',
      'vendor portion started preparing': 'بدأ المتجر في تجهيز جزء الطلب',
      'vendor portion ready for pickup': 'جزء المتجر جاهز للاستلام',
    };

    final exact = staticTranslations[lower];
    if (exact != null) return exact;

    final portionReadyMatch = RegExp(
      r'^Delivery\s+(\d+):\s*(.+?)\s+portion ready for pickup$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (portionReadyMatch != null) {
      return 'التوصيل ${portionReadyMatch.group(1)}: طلب ${portionReadyMatch.group(2)} جاهز للاستلام';
    }

    final portionPrepMatch = RegExp(
      r'^Delivery\s+(\d+):\s*(.+?)\s+portion started preparing$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (portionPrepMatch != null) {
      return 'التوصيل ${portionPrepMatch.group(1)}: بدأ ${portionPrepMatch.group(2)} في التجهيز';
    }

    final pickedUpStopMatch = RegExp(
      r'^Driver picked up fulfillment stop\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (pickedUpStopMatch != null) {
      return 'استلم السائق الطلب من ${pickedUpStopMatch.group(1)}';
    }

    return trimmed;
  }

  static String? _extractReasonFromNote(String? note) {
    if (note == null || note.trim().isEmpty) return null;
    final match = RegExp(
      r'(?:Reason|السبب)\s*:\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(note.trim());
    if (match != null) {
      final val = match.group(1)?.trim();
      if (val != null && val.isNotEmpty) return val;
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _nonEmpty(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
