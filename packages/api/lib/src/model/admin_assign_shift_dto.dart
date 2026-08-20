//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_assign_shift_dto.g.dart';

/// AdminAssignShiftDto
///
/// Properties:
/// * [shiftPoolId] 
/// * [driverId] 
@BuiltValue()
abstract class AdminAssignShiftDto implements Built<AdminAssignShiftDto, AdminAssignShiftDtoBuilder> {
  @BuiltValueField(wireName: r'shiftPoolId')
  String get shiftPoolId;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  AdminAssignShiftDto._();

  factory AdminAssignShiftDto([void updates(AdminAssignShiftDtoBuilder b)]) = _$AdminAssignShiftDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminAssignShiftDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminAssignShiftDto> get serializer => _$AdminAssignShiftDtoSerializer();
}

class _$AdminAssignShiftDtoSerializer implements PrimitiveSerializer<AdminAssignShiftDto> {
  @override
  final Iterable<Type> types = const [AdminAssignShiftDto, _$AdminAssignShiftDto];

  @override
  final String wireName = r'AdminAssignShiftDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminAssignShiftDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'shiftPoolId';
    yield serializers.serialize(
      object.shiftPoolId,
      specifiedType: const FullType(String),
    );
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminAssignShiftDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminAssignShiftDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'shiftPoolId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.shiftPoolId = valueDes;
          break;
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminAssignShiftDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminAssignShiftDtoBuilder();
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

