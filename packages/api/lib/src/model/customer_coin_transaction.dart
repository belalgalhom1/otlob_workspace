//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/coin_transaction_type.dart';
import 'package:api/src/model/customer.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'customer_coin_transaction.g.dart';

/// CustomerCoinTransaction
///
/// Properties:
/// * [id] 
/// * [customerId] 
/// * [orderId] 
/// * [type] 
/// * [amount] 
/// * [balanceAfter] 
/// * [description] 
/// * [createdAt] 
/// * [customer] 
@BuiltValue()
abstract class CustomerCoinTransaction implements Built<CustomerCoinTransaction, CustomerCoinTransactionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'customerId')
  String get customerId;

  @BuiltValueField(wireName: r'orderId')
  String? get orderId;

  @BuiltValueField(wireName: r'type')
  JsonObject? get type;
  // enum typeEnum {  EARNED,  SPENT,  REFUNDED,  };

  @BuiltValueField(wireName: r'amount')
  num get amount;

  @BuiltValueField(wireName: r'balanceAfter')
  num get balanceAfter;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'customer')
  JsonObject? get customer;

  CustomerCoinTransaction._();

  factory CustomerCoinTransaction([void updates(CustomerCoinTransactionBuilder b)]) = _$CustomerCoinTransaction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CustomerCoinTransactionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CustomerCoinTransaction> get serializer => _$CustomerCoinTransactionSerializer();
}

class _$CustomerCoinTransactionSerializer implements PrimitiveSerializer<CustomerCoinTransaction> {
  @override
  final Iterable<Type> types = const [CustomerCoinTransaction, _$CustomerCoinTransaction];

  @override
  final String wireName = r'CustomerCoinTransaction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CustomerCoinTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'customerId';
    yield serializers.serialize(
      object.customerId,
      specifiedType: const FullType(String),
    );
    if (object.orderId != null) {
      yield r'orderId';
      yield serializers.serialize(
        object.orderId,
        specifiedType: const FullType(String),
      );
    }
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(CoinTransactionType),
    );
    yield r'amount';
    yield serializers.serialize(
      object.amount,
      specifiedType: const FullType(num),
    );
    yield r'balanceAfter';
    yield serializers.serialize(
      object.balanceAfter,
      specifiedType: const FullType(num),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'customer';
    yield serializers.serialize(
      object.customer,
      specifiedType: const FullType(Customer),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CustomerCoinTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CustomerCoinTransactionBuilder result,
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
        case r'customerId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.customerId = valueDes;
          break;
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.type = valueDes;
          break;
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.amount = valueDes;
          break;
        case r'balanceAfter':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.balanceAfter = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'customer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.customer = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CustomerCoinTransaction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CustomerCoinTransactionBuilder();
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

