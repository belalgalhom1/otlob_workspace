//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/order.dart';
import 'package:api/src/model/customer_coin_transaction.dart';
import 'package:api/src/model/address.dart';
import 'package:api/src/model/cart.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/user.dart';
import 'package:api/src/model/favorite_product.dart';
import 'package:api/src/model/favorite_vendor.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'customer.g.dart';

/// Customer
///
/// Properties:
/// * [id] 
/// * [userId] 
/// * [canOrder] 
/// * [deletedAt] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [coinBalance] 
/// * [addresses] 
/// * [carts] 
/// * [user] 
/// * [favoriteProducts] 
/// * [favoriteVendors] 
/// * [orders] 
/// * [coinTransactions] 
@BuiltValue()
abstract class Customer implements Built<Customer, CustomerBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'userId')
  String get userId;

  @BuiltValueField(wireName: r'canOrder')
  bool get canOrder;

  @BuiltValueField(wireName: r'deletedAt')
  DateTime? get deletedAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'coinBalance')
  num get coinBalance;

  @BuiltValueField(wireName: r'addresses')
  BuiltList<Address> get addresses;

  @BuiltValueField(wireName: r'carts')
  BuiltList<Cart> get carts;

  @BuiltValueField(wireName: r'user')
  JsonObject? get user;

  @BuiltValueField(wireName: r'favoriteProducts')
  BuiltList<FavoriteProduct> get favoriteProducts;

  @BuiltValueField(wireName: r'favoriteVendors')
  BuiltList<FavoriteVendor> get favoriteVendors;

  @BuiltValueField(wireName: r'orders')
  BuiltList<Order> get orders;

  @BuiltValueField(wireName: r'coinTransactions')
  BuiltList<CustomerCoinTransaction> get coinTransactions;

  Customer._();

  factory Customer([void updates(CustomerBuilder b)]) = _$Customer;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CustomerBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Customer> get serializer => _$CustomerSerializer();
}

class _$CustomerSerializer implements PrimitiveSerializer<Customer> {
  @override
  final Iterable<Type> types = const [Customer, _$Customer];

  @override
  final String wireName = r'Customer';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Customer object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'userId';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'canOrder';
    yield serializers.serialize(
      object.canOrder,
      specifiedType: const FullType(bool),
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
    yield r'coinBalance';
    yield serializers.serialize(
      object.coinBalance,
      specifiedType: const FullType(num),
    );
    yield r'addresses';
    yield serializers.serialize(
      object.addresses,
      specifiedType: const FullType(BuiltList, [FullType(Address)]),
    );
    yield r'carts';
    yield serializers.serialize(
      object.carts,
      specifiedType: const FullType(BuiltList, [FullType(Cart)]),
    );
    yield r'user';
    yield serializers.serialize(
      object.user,
      specifiedType: const FullType(User),
    );
    yield r'favoriteProducts';
    yield serializers.serialize(
      object.favoriteProducts,
      specifiedType: const FullType(BuiltList, [FullType(FavoriteProduct)]),
    );
    yield r'favoriteVendors';
    yield serializers.serialize(
      object.favoriteVendors,
      specifiedType: const FullType(BuiltList, [FullType(FavoriteVendor)]),
    );
    yield r'orders';
    yield serializers.serialize(
      object.orders,
      specifiedType: const FullType(BuiltList, [FullType(Order)]),
    );
    yield r'coinTransactions';
    yield serializers.serialize(
      object.coinTransactions,
      specifiedType: const FullType(BuiltList, [FullType(CustomerCoinTransaction)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Customer object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CustomerBuilder result,
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
        case r'userId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'canOrder':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.canOrder = valueDes;
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
        case r'coinBalance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.coinBalance = valueDes;
          break;
        case r'addresses':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Address)]),
          ) as BuiltList<Address>;
          result.addresses.replace(valueDes);
          break;
        case r'carts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Cart)]),
          ) as BuiltList<Cart>;
          result.carts.replace(valueDes);
          break;
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.user = valueDes;
          break;
        case r'favoriteProducts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FavoriteProduct)]),
          ) as BuiltList<FavoriteProduct>;
          result.favoriteProducts.replace(valueDes);
          break;
        case r'favoriteVendors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(FavoriteVendor)]),
          ) as BuiltList<FavoriteVendor>;
          result.favoriteVendors.replace(valueDes);
          break;
        case r'orders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Order)]),
          ) as BuiltList<Order>;
          result.orders.replace(valueDes);
          break;
        case r'coinTransactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CustomerCoinTransaction)]),
          ) as BuiltList<CustomerCoinTransaction>;
          result.coinTransactions.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Customer deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CustomerBuilder();
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

