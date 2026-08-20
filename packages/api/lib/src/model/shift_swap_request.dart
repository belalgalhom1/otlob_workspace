//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/swap_request_status.dart';
import 'package:api/src/model/driver_shift.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'shift_swap_request.g.dart';

/// ShiftSwapRequest
///
/// Properties:
/// * [id] 
/// * [driverShiftId] 
/// * [offeredByDriverId] 
/// * [status] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [driverShift] 
@BuiltValue()
abstract class ShiftSwapRequest implements Built<ShiftSwapRequest, ShiftSwapRequestBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'driverShiftId')
  String get driverShiftId;

  @BuiltValueField(wireName: r'offeredByDriverId')
  String get offeredByDriverId;

  @BuiltValueField(wireName: r'status')
  JsonObject? get status;
  // enum statusEnum {  PENDING,  ACCEPTED,  CANCELLED,  };

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'driverShift')
  JsonObject? get driverShift;

  ShiftSwapRequest._();

  factory ShiftSwapRequest([void updates(ShiftSwapRequestBuilder b)]) = _$ShiftSwapRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ShiftSwapRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ShiftSwapRequest> get serializer => _$ShiftSwapRequestSerializer();
}

class _$ShiftSwapRequestSerializer implements PrimitiveSerializer<ShiftSwapRequest> {
  @override
  final Iterable<Type> types = const [ShiftSwapRequest, _$ShiftSwapRequest];

  @override
  final String wireName = r'ShiftSwapRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ShiftSwapRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'driverShiftId';
    yield serializers.serialize(
      object.driverShiftId,
      specifiedType: const FullType(String),
    );
    yield r'offeredByDriverId';
    yield serializers.serialize(
      object.offeredByDriverId,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(SwapRequestStatus),
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
    yield r'driverShift';
    yield serializers.serialize(
      object.driverShift,
      specifiedType: const FullType(DriverShift),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ShiftSwapRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ShiftSwapRequestBuilder result,
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
        case r'driverShiftId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverShiftId = valueDes;
          break;
        case r'offeredByDriverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offeredByDriverId = valueDes;
          break;
        case r'status':
          // Patched: skip enum assignment (JsonObject? vs SwapRequestStatus?)
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
        case r'driverShift':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.driverShift = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ShiftSwapRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ShiftSwapRequestBuilder();
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




