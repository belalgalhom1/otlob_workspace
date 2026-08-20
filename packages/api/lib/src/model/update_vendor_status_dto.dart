//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_vendor_status_dto.g.dart';

/// UpdateVendorStatusDto
///
/// Properties:
/// * [status] 
@BuiltValue()
abstract class UpdateVendorStatusDto implements Built<UpdateVendorStatusDto, UpdateVendorStatusDtoBuilder> {
  @BuiltValueField(wireName: r'status')
  UpdateVendorStatusDtoStatusEnum get status;
  // enum statusEnum {  CLOSED,  OPEN,  PAUSED,  SUSPENDED,  };

  UpdateVendorStatusDto._();

  factory UpdateVendorStatusDto([void updates(UpdateVendorStatusDtoBuilder b)]) = _$UpdateVendorStatusDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateVendorStatusDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateVendorStatusDto> get serializer => _$UpdateVendorStatusDtoSerializer();
}

class _$UpdateVendorStatusDtoSerializer implements PrimitiveSerializer<UpdateVendorStatusDto> {
  @override
  final Iterable<Type> types = const [UpdateVendorStatusDto, _$UpdateVendorStatusDto];

  @override
  final String wireName = r'UpdateVendorStatusDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateVendorStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(UpdateVendorStatusDtoStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateVendorStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateVendorStatusDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateVendorStatusDtoStatusEnum),
          ) as UpdateVendorStatusDtoStatusEnum;
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
  UpdateVendorStatusDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateVendorStatusDtoBuilder();
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

class UpdateVendorStatusDtoStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CLOSED')
  static const UpdateVendorStatusDtoStatusEnum CLOSED = _$updateVendorStatusDtoStatusEnum_CLOSED;
  @BuiltValueEnumConst(wireName: r'OPEN')
  static const UpdateVendorStatusDtoStatusEnum OPEN = _$updateVendorStatusDtoStatusEnum_OPEN;
  @BuiltValueEnumConst(wireName: r'PAUSED')
  static const UpdateVendorStatusDtoStatusEnum PAUSED = _$updateVendorStatusDtoStatusEnum_PAUSED;
  @BuiltValueEnumConst(wireName: r'SUSPENDED')
  static const UpdateVendorStatusDtoStatusEnum SUSPENDED = _$updateVendorStatusDtoStatusEnum_SUSPENDED;

  static Serializer<UpdateVendorStatusDtoStatusEnum> get serializer => _$updateVendorStatusDtoStatusEnumSerializer;

  const UpdateVendorStatusDtoStatusEnum._(String name): super(name);

  static BuiltSet<UpdateVendorStatusDtoStatusEnum> get values => _$updateVendorStatusDtoStatusEnumValues;
  static UpdateVendorStatusDtoStatusEnum valueOf(String name) => _$updateVendorStatusDtoStatusEnumValueOf(name);
}

