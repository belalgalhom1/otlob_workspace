//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/dispatch_status.dart';
import 'package:api/src/model/order_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_dispatch.g.dart';

/// OrderDispatch
///
/// Properties:
/// * [id] 
/// * [orderId] 
/// * [driverId] 
/// * [driverShiftId] 
/// * [type] 
/// * [status] 
/// * [distanceKm] 
/// * [estimatedEarnings] 
/// * [expiresAt] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class OrderDispatch implements Built<OrderDispatch, OrderDispatchBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'driverShiftId')
  String? get driverShiftId;

  @BuiltValueField(wireName: r'type')
  OrderType get type;
  // enum typeEnum {  STANDARD,  CUSTOM_DELIVERY,  RIDE,  };

  @BuiltValueField(wireName: r'status')
  DispatchStatus get status;
  // enum statusEnum {  PENDING,  ACCEPTED,  REJECTED,  EXPIRED,  CANCELLED,  };

  @BuiltValueField(wireName: r'distanceKm')
  num? get distanceKm;

  @BuiltValueField(wireName: r'estimatedEarnings')
  num? get estimatedEarnings;

  @BuiltValueField(wireName: r'expiresAt')
  DateTime get expiresAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  OrderDispatch._();

  factory OrderDispatch([void updates(OrderDispatchBuilder b)]) = _$OrderDispatch;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderDispatchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderDispatch> get serializer => _$OrderDispatchSerializer();
}

class _$OrderDispatchSerializer implements PrimitiveSerializer<OrderDispatch> {
  @override
  final Iterable<Type> types = const [OrderDispatch, _$OrderDispatch];

  @override
  final String wireName = r'OrderDispatch';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderDispatch object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'orderId';
    yield serializers.serialize(
      object.orderId,
      specifiedType: const FullType(String),
    );
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
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
      specifiedType: const FullType(OrderType),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DispatchStatus),
    );
    if (object.distanceKm != null) {
      yield r'distanceKm';
      yield serializers.serialize(
        object.distanceKm,
        specifiedType: const FullType(num),
      );
    }
    if (object.estimatedEarnings != null) {
      yield r'estimatedEarnings';
      yield serializers.serialize(
        object.estimatedEarnings,
        specifiedType: const FullType(num),
      );
    }
    yield r'expiresAt';
    yield serializers.serialize(
      object.expiresAt,
      specifiedType: const FullType(DateTime),
    );
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
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderDispatch object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderDispatchBuilder result,
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
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
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
            specifiedType: const FullType(OrderType),
          ) as OrderType;
          result.type = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DispatchStatus),
          ) as DispatchStatus;
          result.status = valueDes;
          break;
        case r'distanceKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.distanceKm = valueDes;
          break;
        case r'estimatedEarnings':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.estimatedEarnings = valueDes;
          break;
        case r'expiresAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.expiresAt = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderDispatch deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderDispatchBuilder();
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

