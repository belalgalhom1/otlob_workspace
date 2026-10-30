//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_break_status.dart';
import 'package:api/src/model/driver_break_reason.dart';
import 'package:api/src/model/driver_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_break.g.dart';

/// DriverBreak
///
/// Properties:
/// * [id] 
/// * [driverId] 
/// * [shiftId] 
/// * [reason] 
/// * [note] 
/// * [requestedMinutes] 
/// * [status] 
/// * [prevStatus] 
/// * [startedAt] 
/// * [endedAt] 
/// * [durationMinutes] 
/// * [autoEnded] 
/// * [reviewedById] 
/// * [reviewedAt] 
/// * [createdAt] 
@BuiltValue()
abstract class DriverBreak implements Built<DriverBreak, DriverBreakBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'shiftId')
  String? get shiftId;

  @BuiltValueField(wireName: r'reason')
  DriverBreakReason get reason;
  // enum reasonEnum {  PRAYER,  MEAL,  REST,  PERSONAL,  OTHER,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  @BuiltValueField(wireName: r'requestedMinutes')
  num? get requestedMinutes;

  @BuiltValueField(wireName: r'status')
  DriverBreakStatus get status;
  // enum statusEnum {  PENDING,  APPROVED,  REJECTED,  CANCELLED,  ENDED,  };

  @BuiltValueField(wireName: r'prevStatus')
  DriverStatus? get prevStatus;
  // enum prevStatusEnum {  OFFLINE,  ONLINE,  BUSY,  ON_DELIVERY,  ON_BREAK,  SUSPENDED,  };

  @BuiltValueField(wireName: r'startedAt')
  DateTime get startedAt;

  @BuiltValueField(wireName: r'endedAt')
  DateTime? get endedAt;

  @BuiltValueField(wireName: r'durationMinutes')
  num? get durationMinutes;

  @BuiltValueField(wireName: r'autoEnded')
  bool get autoEnded;

  @BuiltValueField(wireName: r'reviewedById')
  String? get reviewedById;

  @BuiltValueField(wireName: r'reviewedAt')
  DateTime? get reviewedAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  DriverBreak._();

  factory DriverBreak([void updates(DriverBreakBuilder b)]) = _$DriverBreak;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverBreakBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverBreak> get serializer => _$DriverBreakSerializer();
}

class _$DriverBreakSerializer implements PrimitiveSerializer<DriverBreak> {
  @override
  final Iterable<Type> types = const [DriverBreak, _$DriverBreak];

  @override
  final String wireName = r'DriverBreak';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverBreak object, {
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
    if (object.shiftId != null) {
      yield r'shiftId';
      yield serializers.serialize(
        object.shiftId,
        specifiedType: const FullType(String),
      );
    }
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(DriverBreakReason),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
    if (object.requestedMinutes != null) {
      yield r'requestedMinutes';
      yield serializers.serialize(
        object.requestedMinutes,
        specifiedType: const FullType(num),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DriverBreakStatus),
    );
    if (object.prevStatus != null) {
      yield r'prevStatus';
      yield serializers.serialize(
        object.prevStatus,
        specifiedType: const FullType(DriverStatus),
      );
    }
    yield r'startedAt';
    yield serializers.serialize(
      object.startedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.endedAt != null) {
      yield r'endedAt';
      yield serializers.serialize(
        object.endedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.durationMinutes != null) {
      yield r'durationMinutes';
      yield serializers.serialize(
        object.durationMinutes,
        specifiedType: const FullType(num),
      );
    }
    yield r'autoEnded';
    yield serializers.serialize(
      object.autoEnded,
      specifiedType: const FullType(bool),
    );
    if (object.reviewedById != null) {
      yield r'reviewedById';
      yield serializers.serialize(
        object.reviewedById,
        specifiedType: const FullType(String),
      );
    }
    if (object.reviewedAt != null) {
      yield r'reviewedAt';
      yield serializers.serialize(
        object.reviewedAt,
        specifiedType: const FullType(DateTime),
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
    DriverBreak object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverBreakBuilder result,
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
        case r'shiftId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.shiftId = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverBreakReason),
          ) as DriverBreakReason;
          result.reason = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.note = valueDes;
          break;
        case r'requestedMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.requestedMinutes = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverBreakStatus),
          ) as DriverBreakStatus;
          result.status = valueDes;
          break;
        case r'prevStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverStatus),
          ) as DriverStatus;
          result.prevStatus = valueDes;
          break;
        case r'startedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startedAt = valueDes;
          break;
        case r'endedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.endedAt = valueDes;
          break;
        case r'durationMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.durationMinutes = valueDes;
          break;
        case r'autoEnded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.autoEnded = valueDes;
          break;
        case r'reviewedById':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reviewedById = valueDes;
          break;
        case r'reviewedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.reviewedAt = valueDes;
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
  DriverBreak deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverBreakBuilder();
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

