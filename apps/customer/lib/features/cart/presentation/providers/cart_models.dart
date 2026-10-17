/// Typed cart domain. Parsed once at the data boundary
/// ([CartItem.fromServerJson]); screens and providers must use these
/// accessors instead of raw `product['…']` lookups.

double _asDouble(dynamic value, [double fallback = 0.0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

bool _asBool(dynamic value, [bool fallback = true]) {
  if (value is bool) return value;
  if (value is String) {
    final v = value.toLowerCase();
    if (v == 'true') return true;
    if (v == 'false') return false;
  }
  return fallback;
}

class CartOptionRef {
  final String id;
  final String name;
  final String? nameAr;
  final double priceAdded;
  final String? groupId;
  final String? groupName;

  const CartOptionRef({
    required this.id,
    required this.name,
    this.nameAr,
    required this.priceAdded,
    this.groupId,
    this.groupName,
  });

  factory CartOptionRef.fromJson(Map<String, dynamic> json) => CartOptionRef(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameAr: json['nameAr']?.toString(),
        priceAdded: _asDouble(json['priceAdded']),
        groupId: json['groupId']?.toString() ?? json['group']?['id']?.toString(),
        groupName:
            json['groupName']?.toString() ?? json['group']?['name']?.toString(),
      );

  String localizedName(bool isAr) =>
      isAr && (nameAr?.isNotEmpty ?? false) ? nameAr! : name;
}

class CartVariantRef {
  final String id;
  final String name;
  final String? nameAr;
  final double basePrice;
  final double? comparePrice;
  final bool isActive;
  final int? stock;
  final bool tracksStock;

  const CartVariantRef({
    required this.id,
    required this.name,
    this.nameAr,
    required this.basePrice,
    this.comparePrice,
    required this.isActive,
    this.stock,
    required this.tracksStock,
  });

  factory CartVariantRef.fromJson(Map<String, dynamic> json) => CartVariantRef(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nameAr: json['nameAr']?.toString(),
        basePrice: _asDouble(json['price'] ?? json['basePrice']),
        comparePrice: json['comparePrice'] == null
            ? null
            : _asDouble(json['comparePrice']),
        isActive: _asBool(json['isActive'], true),
        stock: _asInt(json['stock']),
        tracksStock: _asBool(json['tracksStock'], true),
      );

  String localizedName(bool isAr) =>
      isAr && (nameAr?.isNotEmpty ?? false) ? nameAr! : name;
}

class CartProductRef {
  final String id;
  final String? vendorId;
  final String? vendorName;
  final String? vendorNameAr;
  final String? vendorLogo;
  final String? vendorCoverImage;
  final double? commissionRate;
  final bool? isContracted;
  final String? vendorStatus;
  final String name;
  final String? nameAr;
  final String? imageUrl;
  final double price;
  final double? basePrice;
  final double? comparePrice;
  final bool isActive;
  final bool sellByStrip;
  final int? stripsPerPackage;
  final int? stock;
  final bool tracksStock;
  final bool hasVariants;

  const CartProductRef({
    required this.id,
    this.vendorId,
    this.vendorName,
    this.vendorNameAr,
    this.vendorLogo,
    this.vendorCoverImage,
    this.commissionRate,
    this.isContracted,
    this.vendorStatus,
    required this.name,
    this.nameAr,
    this.imageUrl,
    required this.price,
    this.basePrice,
    this.comparePrice,
    required this.isActive,
    this.sellByStrip = false,
    this.stripsPerPackage,
    this.stock,
    required this.tracksStock,
    this.hasVariants = false,
  });

  factory CartProductRef.fromJson(Map<String, dynamic> json) => CartProductRef(
        id: json['id']?.toString() ?? json['productId']?.toString() ?? '',
        vendorId: json['vendorId']?.toString(),
        vendorName: json['vendorName']?.toString(),
        vendorNameAr: json['vendorNameAr']?.toString(),
        vendorLogo: json['vendorLogo']?.toString(),
        vendorCoverImage: json['vendorCoverImage']?.toString(),
        commissionRate: json['commissionRate'] == null
            ? null
            : _asDouble(json['commissionRate']),
        isContracted: json['isContracted'] as bool?,
        vendorStatus: json['vendorStatus']?.toString(),
        name: json['name']?.toString() ?? '',
        nameAr: json['nameAr']?.toString(),
        imageUrl:
            json['imageUrl']?.toString() ?? json['image']?.toString(),
        price: _asDouble(json['price'] ?? json['basePrice']),
        basePrice: json['basePrice'] == null
            ? null
            : _asDouble(json['basePrice']),
        comparePrice: json['comparePrice'] == null
            ? null
            : _asDouble(json['comparePrice']),
        isActive: _asBool(json['isActive'], true),
        sellByStrip: json['sellByStrip'] == true,
        stripsPerPackage: _asInt(json['stripsPerPackage']),
        stock: _asInt(json['stock']),
        tracksStock: _asBool(json['tracksStock'], true),
        hasVariants: json['hasVariants'] == true,
      );

  String localizedName(bool isAr) =>
      isAr && (nameAr?.isNotEmpty ?? false) ? nameAr! : name;
}

class CartItem {
  final String? backendId;
  final CartProductRef product;
  final int quantity;
  final String selectedUnit; // 'package' or 'strip'
  final CartVariantRef? selectedVariant;
  final List<CartOptionRef> selectedOptions;
  final double? unitPrice;
  final double? backendTotalPrice;

  const CartItem({
    this.backendId,
    required this.product,
    required this.quantity,
    this.selectedUnit = 'package',
    this.selectedVariant,
    this.selectedOptions = const [],
    this.unitPrice,
    this.backendTotalPrice,
  });

  String get productId => product.id;
  String? get variantId => selectedVariant?.id;

  /// Canonical key for the option selection (order-independent).
  String get optionsKey {
    final ids = selectedOptions.map((o) => o.id).where((s) => s.isNotEmpty).toList()
      ..sort();
    return ids.join(',');
  }

  double get optionsTotal =>
      selectedOptions.fold(0.0, (sum, o) => sum + o.priceAdded);

  /// Display-only fallback math. The server quote/charge is authoritative;
  /// this only prices lines the backend hasn't totaled yet.
  double get totalPrice {
    if (backendTotalPrice != null && backendTotalPrice! > 0) {
      return backendTotalPrice!;
    }
    if (unitPrice != null && unitPrice! > 0) {
      return unitPrice! * quantity;
    }

    double price;
    if (selectedVariant != null) {
      price = selectedVariant!.basePrice;
    } else {
      price = product.price;
    }

    if (selectedUnit == 'strip' && product.sellByStrip) {
      final stripsCount = product.stripsPerPackage ?? 1;
      if (stripsCount > 0) {
        price = price / stripsCount;
      }
    }

    return (price + optionsTotal) * quantity;
  }

  CartItem copyWith({
    String? backendId,
    CartProductRef? product,
    int? quantity,
    String? selectedUnit,
    CartVariantRef? selectedVariant,
    List<CartOptionRef>? selectedOptions,
    double? unitPrice,
    double? backendTotalPrice,
  }) {
    return CartItem(
      backendId: backendId ?? this.backendId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      unitPrice: unitPrice ?? this.unitPrice,
      backendTotalPrice: backendTotalPrice ?? this.backendTotalPrice,
    );
  }
}
