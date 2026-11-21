/// Canonical client-side request-type classification & presentation helpers,
/// mirrored 1:1 from backend `OrderType` (`STANDARD`, `CUSTOM_DELIVERY`, `RIDE`).
enum AppOrderType {
  standard,
  customDelivery,
  ride;

  bool get isStandard => this == AppOrderType.standard;
  bool get isCustomDelivery => this == AppOrderType.customDelivery;
  bool get isRide => this == AppOrderType.ride;
  bool get isNonStandard => this != AppOrderType.standard;

  /// Mirrors backend `requiresOrderProofPhotos(orderType)`:
  /// `STANDARD` and `CUSTOM_DELIVERY` require pickup & delivery photos;
  /// normal passenger rides (`RIDE`) do not involve packages or goods.
  bool get requiresOrderPhotos => this != AppOrderType.ride;

  /// Mirrors backend vendor-fulfillment model: only `STANDARD` orders involve
  /// vendor stores and store cash/prepaid instructions.
  bool get hasStoreFulfillment => this == AppOrderType.standard;
}

/// Shared single-source-of-truth helpers for distinguishing normal passenger
/// rides (`RIDE`), courier deliveries (`CUSTOM_DELIVERY`), and store orders
/// (`STANDARD`) across Customer, Driver, and Vendor Admin apps.
class OrderTypeHelper {
  const OrderTypeHelper._();

  /// Resolves [AppOrderType] from a raw enum/string or an order payload map.
  /// Explicit backend `type` ALWAYS takes precedence over field heuristics.
  static AppOrderType resolve(dynamic orderOrType) {
    if (orderOrType == null) return AppOrderType.standard;
    if (orderOrType is AppOrderType) return orderOrType;

    String? rawType;
    Map<String, dynamic>? map;
    if (orderOrType is String) {
      rawType = orderOrType;
    } else if (orderOrType is Map<String, dynamic>) {
      map = orderOrType;
      rawType = _nonEmptyString(orderOrType['type']);
    } else if (orderOrType is Map) {
      map = Map<String, dynamic>.from(orderOrType);
      rawType = _nonEmptyString(map['type']);
    } else {
      rawType = _nonEmptyString(orderOrType.toString());
    }

    if (rawType != null) {
      final normalized = rawType.trim().toUpperCase();
      if (normalized == 'RIDE' || normalized.endsWith('.RIDE')) {
        return AppOrderType.ride;
      }
      if (normalized == 'CUSTOM_DELIVERY' ||
          normalized.endsWith('.CUSTOM_DELIVERY') ||
          normalized == 'CUSTOMDELIVERY') {
        return AppOrderType.customDelivery;
      }
      if (normalized == 'STANDARD' || normalized.endsWith('.STANDARD')) {
        return AppOrderType.standard;
      }
    }

    // Legacy fallback ONLY when backend `type` is completely missing on a map.
    if (map != null) {
      final hasVendor =
          map['vendorId'] != null ||
          map['vendor'] != null ||
          (map['vendorFulfillments'] is List &&
              (map['vendorFulfillments'] as List).isNotEmpty);
      final hasCustomPoints =
          map['pickupAddress'] != null ||
          map['deliveryAddress'] != null ||
          map['itemDetails'] != null;
      if (!hasVendor && hasCustomPoints) {
        return AppOrderType.customDelivery;
      }
    }

    return AppOrderType.standard;
  }

  static bool isRide(dynamic orderOrType) =>
      resolve(orderOrType) == AppOrderType.ride;

  static bool isCustomDelivery(dynamic orderOrType) =>
      resolve(orderOrType) == AppOrderType.customDelivery;

  static bool isStandard(dynamic orderOrType) =>
      resolve(orderOrType) == AppOrderType.standard;

  static bool isNonStandard(dynamic orderOrType) =>
      resolve(orderOrType).isNonStandard;

  static bool requiresOrderPhotos(dynamic orderOrType) =>
      resolve(orderOrType).requiresOrderPhotos;

  static bool shouldShowActivityLogOnTracking(dynamic orderOrType) =>
      !isRide(orderOrType);

  static bool shouldShowStoreFulfillmentSections(dynamic orderOrType) =>
      isStandard(orderOrType);

  /// Request type display label (`Ride`, `Custom Delivery`, `Store Order`).
  static String requestTypeLabel(
    AppOrderType type, {
    required bool isArabic,
  }) {
    switch (type) {
      case AppOrderType.ride:
        return isArabic ? 'رحلة' : 'Ride';
      case AppOrderType.customDelivery:
        return isArabic ? 'توصيل خاص' : 'Custom Delivery';
      case AppOrderType.standard:
        return isArabic ? 'طلب متجر' : 'Store Order';
    }
  }

  /// Short passenger vs package/store label for route/card titles.
  static String partnerRoleLabel(
    AppOrderType type, {
    required bool isArabic,
  }) {
    switch (type) {
      case AppOrderType.ride:
        return isArabic ? 'كابتن الرحلة' : 'Driver';
      case AppOrderType.customDelivery:
        return isArabic ? 'مندوب التوصيل' : 'Courier';
      case AppOrderType.standard:
        return isArabic ? 'المتجر' : 'Vendor';
    }
  }

  /// Resolves the Customer app order card headline so rides never fall back
  /// to `"Vendor"`.
  static String customerCardTitle(
    Map<String, dynamic> order, {
    required bool isArabic,
    required String vendorFallback,
    String? resolvedVendorName,
  }) {
    final type = resolve(order);
    switch (type) {
      case AppOrderType.ride:
        return isArabic ? 'رحلة' : 'Ride';
      case AppOrderType.customDelivery:
        return isArabic ? 'توصيل خاص' : 'Custom Delivery';
      case AppOrderType.standard:
        final trimmedVendor = resolvedVendorName?.trim();
        if (trimmedVendor != null && trimmedVendor.isNotEmpty) {
          return trimmedVendor;
        }
        return vendorFallback;
    }
  }

  /// Resolves a Customer app secondary badge/subtitle for the card header
  /// so a Ride shows Ride/Passenger metadata instead of `"Custom Delivery"`.
  static String? customerCardSubtitle(
    Map<String, dynamic> order, {
    required bool isArabic,
    required String customDeliveryLabel,
    String? multiVendorLabel,
  }) {
    final type = resolve(order);
    switch (type) {
      case AppOrderType.ride:
        return isArabic ? 'توصيل ركاب' : 'Passenger Ride';
      case AppOrderType.customDelivery:
        return customDeliveryLabel;
      case AppOrderType.standard:
        return multiVendorLabel;
    }
  }

  /// Maps backend status into request-type-aware localized text for Customer
  /// list cards and tracking headers.
  static String customerStatusLabel(
    AppOrderType type,
    String? rawStatus, {
    required bool isArabic,
  }) {
    final s = (rawStatus ?? '').trim().toUpperCase();
    switch (s) {
      case 'PENDING':
        if (type.isNonStandard) {
          return isArabic ? 'تم إرسال الطلب' : 'Request Submitted';
        }
        return isArabic ? 'بانتظار المتجر' : 'Pending';
      case 'ACCEPTED':
        return isArabic ? 'تم القبول' : 'Accepted';
      case 'PREPARING':
        return isArabic ? 'جاري التحضير' : 'Preparing';
      case 'LOOKING_FOR_DRIVER':
        return isArabic
            ? (type.isRide ? 'جاري البحث عن كابتن' : 'جاري البحث عن سائق')
            : (type.isRide ? 'Finding Driver' : 'Finding Driver');
      case 'DRIVER_ASSIGNED':
        return isArabic
            ? (type.isRide ? 'الكابتن في طريقه إليك' : 'تم تعيين سائق')
            : 'Driver Assigned';
      case 'PENDING_PAYMENT':
        return isArabic ? 'بانتظار الدفع' : 'Awaiting Payment';
      case 'READY_FOR_PICKUP':
        if (type.isRide) {
          return isArabic ? 'الكابتن متجه إلى نقطة الركوب' : 'Heading to Pickup';
        }
        if (type.isCustomDelivery) {
          return isArabic ? 'السائق في طريقه للاستلام' : 'Heading to Pickup';
        }
        return isArabic ? 'جاهز للاستلام' : 'Ready for Pickup';
      case 'PARTIALLY_PICKED_UP':
        return isArabic ? 'تم استلام جزء من الطلب' : 'Partially Picked Up';
      case 'PICKED_UP':
        if (type.isRide) {
          return isArabic ? 'الرحلة قيد التنفيذ' : 'Ride in Progress';
        }
        if (type.isCustomDelivery) {
          return isArabic ? 'تم الاستلام وفي الطريق' : 'Picked Up';
        }
        return isArabic ? 'تم الاستلام من المتجر' : 'Picked Up';
      case 'DELIVERED':
        return isArabic
            ? (type.isRide ? 'اكتملت الرحلة' : 'تم التوصيل')
            : (type.isRide ? 'Ride Completed' : 'Delivered');
      case 'CANCELLED':
        return isArabic ? 'ملغي' : 'Cancelled';
      case 'CHANGES_REQUESTED':
        return isArabic ? 'مطلوب تعديلات' : 'Changes Requested';
      default:
        return rawStatus ?? (isArabic ? 'غير معروف' : 'Unknown');
    }
  }

  /// Driver-facing dispatch modal header copy.
  static String dispatchModalTitle(
    AppOrderType type, {
    required bool isArabic,
  }) {
    switch (type) {
      case AppOrderType.ride:
        return isArabic ? 'طلب رحلة جديد!' : 'New Ride Request!';
      case AppOrderType.customDelivery:
        return isArabic
            ? 'طلب توصيل خاص جديد!'
            : 'New Custom Delivery Request!';
      case AppOrderType.standard:
        return isArabic ? 'طلب توصيل جديد!' : 'New Delivery Request!';
    }
  }

  static String dispatchAcceptButtonLabel(
    AppOrderType type, {
    required bool isArabic,
  }) {
    switch (type) {
      case AppOrderType.ride:
        return isArabic ? 'قبول الرحلة' : 'Accept Ride';
      case AppOrderType.customDelivery:
      case AppOrderType.standard:
        return isArabic ? 'قبول التوصيل' : 'Accept Delivery';
    }
  }

  static String driverExecutionScreenTitle(
    AppOrderType type, {
    required bool isArabic,
    required String standardFallback,
  }) {
    switch (type) {
      case AppOrderType.ride:
        return isArabic ? 'رحلة نشطة' : 'Active Ride';
      case AppOrderType.customDelivery:
        return isArabic ? 'توصيل خاص نشط' : 'Active Custom Delivery';
      case AppOrderType.standard:
        return standardFallback;
    }
  }

  static String trackingScreenTitle(
    AppOrderType type, {
    required bool isArabic,
  }) {
    switch (type) {
      case AppOrderType.ride:
        return isArabic ? 'تتبع الرحلة' : 'Track Ride';
      case AppOrderType.customDelivery:
        return isArabic ? 'تتبع التوصيل' : 'Track Delivery';
      case AppOrderType.standard:
        return isArabic ? 'تتبع الطلب' : 'Track Order';
    }
  }

  static String? _nonEmptyString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }
}
