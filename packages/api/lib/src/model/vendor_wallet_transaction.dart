//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/vendor_transaction_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vendor_wallet_transaction.g.dart';

/// VendorWalletTransaction
///
/// Properties:
/// * [id] 
/// * [vendorId] 
/// * [orderId] 
/// * [type] 
/// * [amount] 
/// * [balanceAfter] 
/// * [description] 
/// * [referenceId] 
/// * [createdAt] 
@BuiltValue()
abstract class VendorWalletTransaction implements Built<VendorWalletTransaction, VendorWalletTransactionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'vendorId')
  String get vendorId;

  @BuiltValueField(wireName: r'orderId')
  String? get orderId;

  @BuiltValueField(wireName: r'type')
  VendorTransactionType get type;
  // enum typeEnum {  ORDER_REVENUE,  COMMISSION_DEDUCTION,  CASH_COLLECTED,  PAYOUT,  REFUND,  ADJUSTMENT,  };

  @BuiltValueField(wireName: r'amount')
  num get amount;

  @BuiltValueField(wireName: r'balanceAfter')
  num get balanceAfter;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'referenceId')
  String? get referenceId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  VendorWalletTransaction._();

  factory VendorWalletTransaction([void updates(VendorWalletTransactionBuilder b)]) = _$VendorWalletTransaction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VendorWalletTransactionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VendorWalletTransaction> get serializer => _$VendorWalletTransactionSerializer();
}

class _$VendorWalletTransactionSerializer implements PrimitiveSerializer<VendorWalletTransaction> {
  @override
  final Iterable<Type> types = const [VendorWalletTransaction, _$VendorWalletTransaction];

  @override
  final String wireName = r'VendorWalletTransaction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VendorWalletTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'vendorId';
    yield serializers.serialize(
      object.vendorId,
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
      specifiedType: const FullType(VendorTransactionType),
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
    if (object.referenceId != null) {
      yield r'referenceId';
      yield serializers.serialize(
        object.referenceId,
        specifiedType: const FullType(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VendorWalletTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VendorWalletTransactionBuilder result,
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
        case r'vendorId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vendorId = valueDes;
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
            specifiedType: const FullType(VendorTransactionType),
          ) as VendorTransactionType;
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
        case r'referenceId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.referenceId = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VendorWalletTransaction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VendorWalletTransactionBuilder();
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

