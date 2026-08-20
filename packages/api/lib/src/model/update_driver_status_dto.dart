//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_driver_status_dto.g.dart';

/// UpdateDriverStatusDto
///
/// Properties:
/// * [status] 
@BuiltValue()
abstract class UpdateDriverStatusDto implements Built<UpdateDriverStatusDto, UpdateDriverStatusDtoBuilder> {
  @BuiltValueField(wireName: r'status')
  UpdateDriverStatusDtoStatusEnum get status;
  // enum statusEnum {  ONLINE,  OFFLINE,  ON_BREAK,  };

  UpdateDriverStatusDto._();

  factory UpdateDriverStatusDto([void updates(UpdateDriverStatusDtoBuilder b)]) = _$UpdateDriverStatusDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateDriverStatusDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateDriverStatusDto> get serializer => _$UpdateDriverStatusDtoSerializer();
}

class _$UpdateDriverStatusDtoSerializer implements PrimitiveSerializer<UpdateDriverStatusDto> {
  @override
  final Iterable<Type> types = const [UpdateDriverStatusDto, _$UpdateDriverStatusDto];

  @override
  final String wireName = r'UpdateDriverStatusDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateDriverStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(UpdateDriverStatusDtoStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateDriverStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateDriverStatusDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateDriverStatusDtoStatusEnum),
          ) as UpdateDriverStatusDtoStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateDriverStatusDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateDriverStatusDtoBuilder();
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

class UpdateDriverStatusDtoStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ONLINE')
  static const UpdateDriverStatusDtoStatusEnum ONLINE = _$updateDriverStatusDtoStatusEnum_ONLINE;
  @BuiltValueEnumConst(wireName: r'OFFLINE')
  static const UpdateDriverStatusDtoStatusEnum OFFLINE = _$updateDriverStatusDtoStatusEnum_OFFLINE;
  @BuiltValueEnumConst(wireName: r'ON_BREAK')
  static const UpdateDriverStatusDtoStatusEnum ON_BREAK = _$updateDriverStatusDtoStatusEnum_ON_BREAK;

  static Serializer<UpdateDriverStatusDtoStatusEnum> get serializer => _$updateDriverStatusDtoStatusEnumSerializer;

  const UpdateDriverStatusDtoStatusEnum._(String name): super(name);

  static BuiltSet<UpdateDriverStatusDtoStatusEnum> get values => _$updateDriverStatusDtoStatusEnumValues;
  static UpdateDriverStatusDtoStatusEnum valueOf(String name) => _$updateDriverStatusDtoStatusEnumValueOf(name);
}

