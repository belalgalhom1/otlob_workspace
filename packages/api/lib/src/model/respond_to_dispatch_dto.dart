//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'respond_to_dispatch_dto.g.dart';

/// RespondToDispatchDto
///
/// Properties:
/// * [response] 
@BuiltValue()
abstract class RespondToDispatchDto implements Built<RespondToDispatchDto, RespondToDispatchDtoBuilder> {
  @BuiltValueField(wireName: r'response')
  RespondToDispatchDtoResponseEnum get response;
  // enum responseEnum {  ACCEPTED,  REJECTED,  };

  RespondToDispatchDto._();

  factory RespondToDispatchDto([void updates(RespondToDispatchDtoBuilder b)]) = _$RespondToDispatchDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RespondToDispatchDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RespondToDispatchDto> get serializer => _$RespondToDispatchDtoSerializer();
}

class _$RespondToDispatchDtoSerializer implements PrimitiveSerializer<RespondToDispatchDto> {
  @override
  final Iterable<Type> types = const [RespondToDispatchDto, _$RespondToDispatchDto];

  @override
  final String wireName = r'RespondToDispatchDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RespondToDispatchDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'response';
    yield serializers.serialize(
      object.response,
      specifiedType: const FullType(RespondToDispatchDtoResponseEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RespondToDispatchDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RespondToDispatchDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'response':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RespondToDispatchDtoResponseEnum),
          ) as RespondToDispatchDtoResponseEnum;
          result.response = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RespondToDispatchDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RespondToDispatchDtoBuilder();
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

class RespondToDispatchDtoResponseEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const RespondToDispatchDtoResponseEnum ACCEPTED = _$respondToDispatchDtoResponseEnum_ACCEPTED;
  @BuiltValueEnumConst(wireName: r'REJECTED')
  static const RespondToDispatchDtoResponseEnum REJECTED = _$respondToDispatchDtoResponseEnum_REJECTED;

  static Serializer<RespondToDispatchDtoResponseEnum> get serializer => _$respondToDispatchDtoResponseEnumSerializer;

  const RespondToDispatchDtoResponseEnum._(String name): super(name);

  static BuiltSet<RespondToDispatchDtoResponseEnum> get values => _$respondToDispatchDtoResponseEnumValues;
  static RespondToDispatchDtoResponseEnum valueOf(String name) => _$respondToDispatchDtoResponseEnumValueOf(name);
}

