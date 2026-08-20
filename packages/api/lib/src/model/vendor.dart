//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/menu_category.dart';
import 'package:api/src/model/order.dart';
import 'package:api/src/model/support_ticket.dart';
import 'package:api/src/model/vendor_wallet_transaction.dart';
import 'package:api/src/model/conversation.dart';
import 'package:api/src/model/offer.dart';
import 'package:api/src/model/vendor_statistic.dart';
import 'package:api/src/model/favorite_vendor.dart';
import 'package:api/src/model/vendor_branch.dart';
import 'package:api/src/model/vendor_member.dart';
import 'package:api/src/model/vendor_vertical.dart';
import 'package:api/src/model/cart.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/product.dart';
import 'package:api/src/model/promotion.dart';
import 'package:api/src/model/vendor_status.dart';
import 'package:api/src/model/audit_log.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vendor.g.dart';

/// Vendor
///
/// Properties:
/// * [id] 
/// * [storeName] 
/// * [storeNameAr] 
/// * [slug] 
/// * [description] 
/// * [descriptionAr] 
/// * [logo] 
/// * [coverImage] 
/// * [phone] 
/// * [taxId] 
/// * [commissionRate] 
/// * [status] 
/// * [walletBalance] 
/// * [isContracted] 
/// * [workingHours] 
/// * [isScheduleActive] 
/// * [verticalId] 
/// * [deletedAt] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [auditLogs] 
/// * [carts] 
/// * [conversations] 
/// * [favoritedBy] 
/// * [categories] 
/// * [orders] 
/// * [products] 
/// * [supportTickets] 
/// * [branches] 
/// * [members] 
/// * [statistics] 
/// * [walletTransactions] 
/// * [promotions] 
/// * [offers] 
/// * [vertical] 
@BuiltValue()
abstract class Vendor implements Built<Vendor, VendorBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'storeName')
  String get storeName;

  @BuiltValueField(wireName: r'storeNameAr')
  String? get storeNameAr;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'descriptionAr')
  String? get descriptionAr;

  @BuiltValueField(wireName: r'logo')
  String? get logo;

  @BuiltValueField(wireName: r'coverImage')
  String? get coverImage;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'taxId')
  String? get taxId;

  @BuiltValueField(wireName: r'commissionRate')
  num get commissionRate;

  @BuiltValueField(wireName: r'status')
  JsonObject? get status;
  // enum statusEnum {  CLOSED,  OPEN,  PAUSED,  SUSPENDED,  };

  @BuiltValueField(wireName: r'walletBalance')
  num get walletBalance;

  @BuiltValueField(wireName: r'isContracted')
  bool get isContracted;

  @BuiltValueField(wireName: r'workingHours')
  JsonObject? get workingHours;

  @BuiltValueField(wireName: r'isScheduleActive')
  bool get isScheduleActive;

  @BuiltValueField(wireName: r'verticalId')
  String get verticalId;

  @BuiltValueField(wireName: r'deletedAt')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'auditLogs')
  BuiltList<AuditLog> get auditLogs;

  @BuiltValueField(wireName: r'carts')
  BuiltList<Cart> get carts;

  @BuiltValueField(wireName: r'conversations')
  BuiltList<Conversation> get conversations;

  @BuiltValueField(wireName: r'favoritedBy')
  BuiltList<FavoriteVendor> get favoritedBy;

  @BuiltValueField(wireName: r'categories')
  BuiltList<MenuCategory> get categories;

  @BuiltValueField(wireName: r'orders')
  BuiltList<Order> get orders;

  @BuiltValueField(wireName: r'products')
  BuiltList<Product> get products;

  @BuiltValueField(wireName: r'supportTickets')
  BuiltList<SupportTicket> get supportTickets;

  @BuiltValueField(wireName: r'branches')
  BuiltList<VendorBranch> get branches;

  @BuiltValueField(wireName: r'members')
  BuiltList<VendorMember> get members;

  @BuiltValueField(wireName: r'statistics')
  BuiltList<VendorStatistic> get statistics;

  @BuiltValueField(wireName: r'walletTransactions')
  BuiltList<VendorWalletTransaction> get walletTransactions;

  @BuiltValueField(wireName: r'promotions')
  BuiltList<Promotion> get promotions;

  @BuiltValueField(wireName: r'offers')
  BuiltList<Offer> get offers;

  @BuiltValueField(wireName: r'vertical')
  JsonObject? get vertical;

  Vendor._();

  factory Vendor([void updates(VendorBuilder b)]) = _$Vendor;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VendorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Vendor> get serializer => _$VendorSerializer();
}

class _$VendorSerializer implements PrimitiveSerializer<Vendor> {
  @override
  final Iterable<Type> types = const [Vendor, _$Vendor];

  @override
  final String wireName = r'Vendor';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Vendor object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'storeName';
    yield serializers.serialize(
      object.storeName,
      specifiedType: const FullType(String),
    );
    if (object.storeNameAr != null) {
      yield r'storeNameAr';
      yield serializers.serialize(
        object.storeNameAr,
        specifiedType: const FullType(String),
      );
    }
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.descriptionAr != null) {
      yield r'descriptionAr';
      yield serializers.serialize(
        object.descriptionAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.logo != null) {
      yield r'logo';
      yield serializers.serialize(
        object.logo,
        specifiedType: const FullType(String),
      );
    }
    if (object.coverImage != null) {
      yield r'coverImage';
      yield serializers.serialize(
        object.coverImage,
        specifiedType: const FullType(String),
      );
    }
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    if (object.taxId != null) {
      yield r'taxId';
      yield serializers.serialize(
        object.taxId,
        specifiedType: const FullType(String),
      );
    }
    yield r'commissionRate';
    yield serializers.serialize(
      object.commissionRate,
      specifiedType: const FullType(num),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(VendorStatus),
    );
    yield r'walletBalance';
    yield serializers.serialize(
      object.walletBalance,
      specifiedType: const FullType(num),
    );
    yield r'isContracted';
    yield serializers.serialize(
      object.isContracted,
      specifiedType: const FullType(bool),
    );
    if (object.workingHours != null) {
      yield r'workingHours';
      yield serializers.serialize(
        object.workingHours,
        specifiedType: const FullType(JsonObject),
      );
    }
    yield r'isScheduleActive';
    yield serializers.serialize(
      object.isScheduleActive,
      specifiedType: const FullType(bool),
    );
    yield r'verticalId';
    yield serializers.serialize(
      object.verticalId,
      specifiedType: const FullType(String),
    );
    if (object.deletedAt != null) {
      yield r'deletedAt';
      yield serializers.serialize(
        object.deletedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'auditLogs';
    yield serializers.serialize(
      object.auditLogs,
      specifiedType: const FullType(BuiltList, [FullType(AuditLog)]),
    );
    yield r'carts';
    yield serializers.serialize(
      object.carts,
      specifiedType: const FullType(BuiltList, [FullType(Cart)]),
    );
    yield r'conversations';
    yield serializers.serialize(
      object.conversations,
      specifiedType: const FullType(BuiltList, [FullType(Conversation)]),
    );
    yield r'favoritedBy';
    yield serializers.serialize(
      object.favoritedBy,
      specifiedType: const FullType(BuiltList, [FullType(FavoriteVendor)]),
    );
    yield r'categories';
    yield serializers.serialize(
      object.categories,
      specifiedType: const FullType(BuiltList, [FullType(MenuCategory)]),
    );
    yield r'orders';
    yield serializers.serialize(
      object.orders,
      specifiedType: const FullType(BuiltList, [FullType(Order)]),
    );
    yield r'products';
    yield serializers.serialize(
      object.products,
      specifiedType: const FullType(BuiltList, [FullType(Product)]),
    );
    yield r'supportTickets';
    yield serializers.serialize(
      object.supportTickets,
      specifiedType: const FullType(BuiltList, [FullType(SupportTicket)]),
    );
    yield r'branches';
    yield serializers.serialize(
      object.branches,
      specifiedType: const FullType(BuiltList, [FullType(VendorBranch)]),
    );
    yield r'members';
    yield serializers.serialize(
      object.members,
      specifiedType: const FullType(BuiltList, [FullType(VendorMember)]),
    );
    yield r'statistics';
    yield serializers.serialize(
      object.statistics,
      specifiedType: const FullType(BuiltList, [FullType(VendorStatistic)]),
    );
    yield r'walletTransactions';
    yield serializers.serialize(
      object.walletTransactions,
      specifiedType: const FullType(BuiltList, [FullType(VendorWalletTransaction)]),
    );
    yield r'promotions';
    yield serializers.serialize(
      object.promotions,
      specifiedType: const FullType(BuiltList, [FullType(Promotion)]),
    );
    yield r'offers';
    yield serializers.serialize(
      object.offers,
      specifiedType: const FullType(BuiltList, [FullType(Offer)]),
    );
    yield r'vertical';
    yield serializers.serialize(
      object.vertical,
      specifiedType: const FullType(VendorVertical),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Vendor object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VendorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'storeName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.storeName = valueDes;
          break;
        case r'storeNameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.storeNameAr = valueDes;
          break;
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'descriptionAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.descriptionAr = valueDes;
          break;
        case r'logo':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.logo = valueDes;
          break;
        case r'coverImage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.coverImage = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'taxId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.taxId = valueDes;
          break;
        case r'commissionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.commissionRate = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.status = valueDes;
          break;
        case r'walletBalance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.walletBalance = valueDes;
          break;
        case r'isContracted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isContracted = valueDes;
          break;
        case r'workingHours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.workingHours = valueDes;
          break;
        case r'isScheduleActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isScheduleActive = valueDes;
          break;
        case r'verticalId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.verticalId = valueDes;
          break;
        case r'deletedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.deletedAt = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'auditLogs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(AuditLog)]),
          ) as BuiltList<AuditLog>;
          result.auditLogs.replace(valueDes);
          break;
        case r'carts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Cart)]),
          ) as BuiltList<Cart>;
          result.carts.replace(valueDes);
          break;
        case r'conversations':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Conversation)]),
          ) as BuiltList<Conversation>;
          result.conversations.replace(valueDes);
          break;
        case r'favoritedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FavoriteVendor)]),
          ) as BuiltList<FavoriteVendor>;
          result.favoritedBy.replace(valueDes);
          break;
        case r'categories':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(MenuCategory)]),
          ) as BuiltList<MenuCategory>;
          result.categories.replace(valueDes);
          break;
        case r'orders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Order)]),
          ) as BuiltList<Order>;
          result.orders.replace(valueDes);
          break;
        case r'products':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Product)]),
          ) as BuiltList<Product>;
          result.products.replace(valueDes);
          break;
        case r'supportTickets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SupportTicket)]),
          ) as BuiltList<SupportTicket>;
          result.supportTickets.replace(valueDes);
          break;
        case r'branches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VendorBranch)]),
          ) as BuiltList<VendorBranch>;
          result.branches.replace(valueDes);
          break;
        case r'members':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VendorMember)]),
          ) as BuiltList<VendorMember>;
          result.members.replace(valueDes);
          break;
        case r'statistics':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VendorStatistic)]),
          ) as BuiltList<VendorStatistic>;
          result.statistics.replace(valueDes);
          break;
        case r'walletTransactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(VendorWalletTransaction)]),
          ) as BuiltList<VendorWalletTransaction>;
          result.walletTransactions.replace(valueDes);
          break;
        case r'promotions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Promotion)]),
          ) as BuiltList<Promotion>;
          result.promotions.replace(valueDes);
          break;
        case r'offers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Offer)]),
          ) as BuiltList<Offer>;
          result.offers.replace(valueDes);
          break;
        case r'vertical':
          // Patched: skip complex nested type assignment (JsonObject? vs VendorVerticalBuilder?)
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Vendor deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VendorBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}




