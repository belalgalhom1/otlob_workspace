//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_shift.dart';
import 'package:api/src/model/zone.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'shift_pool.g.dart';

/// ShiftPool
///
/// Properties:
/// * [id] 
/// * [zoneId] 
/// * [shiftDate] 
/// * [startTime] 
/// * [endTime] 
/// * [maxDrivers] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [zone] 
/// * [driverShifts] 
@BuiltValue()
abstract class ShiftPool implements Built<ShiftPool, ShiftPoolBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'zoneId')
  String? get zoneId;

  @BuiltValueField(wireName: r'shiftDate')
  DateTime get shiftDate;

  @BuiltValueField(wireName: r'startTime')
  DateTime get startTime;

  @BuiltValueField(wireName: r'endTime')
  DateTime get endTime;

  @BuiltValueField(wireName: r'maxDrivers')
  num get maxDrivers;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'zone')
  JsonObject? get zone;

  @BuiltValueField(wireName: r'driverShifts')
  BuiltList<DriverShift> get driverShifts;

  ShiftPool._();

  factory ShiftPool([void updates(ShiftPoolBuilder b)]) = _$ShiftPool;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ShiftPoolBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ShiftPool> get serializer => _$ShiftPoolSerializer();
}

class _$ShiftPoolSerializer implements PrimitiveSerializer<ShiftPool> {
  @override
  final Iterable<Type> types = const [ShiftPool, _$ShiftPool];

  @override
  final String wireName = r'ShiftPool';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ShiftPool object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.zoneId != null) {
      yield r'zoneId';
      yield serializers.serialize(
        object.zoneId,
        specifiedType: const FullType(String),
      );
    }
    yield r'shiftDate';
    yield serializers.serialize(
      object.shiftDate,
      specifiedType: const FullType(DateTime),
    );
    yield r'startTime';
    yield serializers.serialize(
      object.startTime,
      specifiedType: const FullType(DateTime),
    );
    yield r'endTime';
    yield serializers.serialize(
      object.endTime,
      specifiedType: const FullType(DateTime),
    );
    yield r'maxDrivers';
    yield serializers.serialize(
      object.maxDrivers,
      specifiedType: const FullType(num),
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
    if (object.zone != null) {
      yield r'zone';
      yield serializers.serialize(
        object.zone,
        specifiedType: const FullType(Zone),
      );
    }
    yield r'driverShifts';
    yield serializers.serialize(
      object.driverShifts,
      specifiedType: const FullType(BuiltList, [FullType(DriverShift)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ShiftPool object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ShiftPoolBuilder result,
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
        case r'zoneId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        case r'shiftDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.shiftDate = valueDes;
          break;
        case r'startTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startTime = valueDes;
          break;
        case r'endTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.endTime = valueDes;
          break;
        case r'maxDrivers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxDrivers = valueDes;
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
        case r'zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.zone = valueDes;
          break;
        case r'driverShifts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverShift)]),
          ) as BuiltList<DriverShift>;
          result.driverShifts.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ShiftPool deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ShiftPoolBuilder();
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

