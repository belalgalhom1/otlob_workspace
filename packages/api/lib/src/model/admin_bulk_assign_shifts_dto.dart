//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_bulk_assign_shifts_dto.g.dart';

/// AdminBulkAssignShiftsDto
///
/// Properties:
/// * [driverId] 
/// * [shiftPoolIds] 
@BuiltValue()
abstract class AdminBulkAssignShiftsDto implements Built<AdminBulkAssignShiftsDto, AdminBulkAssignShiftsDtoBuilder> {
  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'shiftPoolIds')
  BuiltList<String> get shiftPoolIds;

  AdminBulkAssignShiftsDto._();

  factory AdminBulkAssignShiftsDto([void updates(AdminBulkAssignShiftsDtoBuilder b)]) = _$AdminBulkAssignShiftsDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminBulkAssignShiftsDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminBulkAssignShiftsDto> get serializer => _$AdminBulkAssignShiftsDtoSerializer();
}

class _$AdminBulkAssignShiftsDtoSerializer implements PrimitiveSerializer<AdminBulkAssignShiftsDto> {
  @override
  final Iterable<Type> types = const [AdminBulkAssignShiftsDto, _$AdminBulkAssignShiftsDto];

  @override
  final String wireName = r'AdminBulkAssignShiftsDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminBulkAssignShiftsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
    yield r'shiftPoolIds';
    yield serializers.serialize(
      object.shiftPoolIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminBulkAssignShiftsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminBulkAssignShiftsDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
          break;
        case r'shiftPoolIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.shiftPoolIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminBulkAssignShiftsDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminBulkAssignShiftsDtoBuilder();
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

