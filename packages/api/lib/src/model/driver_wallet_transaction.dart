//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/wallet_transaction_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_wallet_transaction.g.dart';

/// DriverWalletTransaction
///
/// Properties:
/// * [id] 
/// * [driverId] 
/// * [orderId] 
/// * [driverShiftId] 
/// * [type] 
/// * [amount] 
/// * [balanceAfter] 
/// * [description] 
/// * [referenceId] 
/// * [createdAt] 
@BuiltValue()
abstract class DriverWalletTransaction implements Built<DriverWalletTransaction, DriverWalletTransactionBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'orderId')
  String? get orderId;

  @BuiltValueField(wireName: r'driverShiftId')
  String? get driverShiftId;

  @BuiltValueField(wireName: r'type')
  WalletTransactionType get type;
  // enum typeEnum {  DELIVERY_FEE,  CASH_COLLECTED,  CASH_HANDED_TO_VENDOR,  PAYOUT,  PENALTY,  BONUS,  ADJUSTMENT,  };

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

  DriverWalletTransaction._();

  factory DriverWalletTransaction([void updates(DriverWalletTransactionBuilder b)]) = _$DriverWalletTransaction;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverWalletTransactionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverWalletTransaction> get serializer => _$DriverWalletTransactionSerializer();
}

class _$DriverWalletTransactionSerializer implements PrimitiveSerializer<DriverWalletTransaction> {
  @override
  final Iterable<Type> types = const [DriverWalletTransaction, _$DriverWalletTransaction];

  @override
  final String wireName = r'DriverWalletTransaction';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverWalletTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
    if (object.orderId != null) {
      yield r'orderId';
      yield serializers.serialize(
        object.orderId,
        specifiedType: const FullType(String),
      );
    }
    if (object.driverShiftId != null) {
      yield r'driverShiftId';
      yield serializers.serialize(
        object.driverShiftId,
        specifiedType: const FullType(String),
      );
    }
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(WalletTransactionType),
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
    DriverWalletTransaction object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverWalletTransactionBuilder result,
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
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
          break;
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'driverShiftId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverShiftId = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(WalletTransactionType),
          ) as WalletTransactionType;
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
  DriverWalletTransaction deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverWalletTransactionBuilder();
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

