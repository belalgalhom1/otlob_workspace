//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'decide_assist_request_dto.g.dart';

/// DecideAssistRequestDto
///
/// Properties:
/// * [status] - Support decision on the assistance request
@BuiltValue()
abstract class DecideAssistRequestDto implements Built<DecideAssistRequestDto, DecideAssistRequestDtoBuilder> {
  /// Support decision on the assistance request
  @BuiltValueField(wireName: r'status')
  DecideAssistRequestDtoStatusEnum get status;
  // enum statusEnum {  APPROVED,  REJECTED,  };

  DecideAssistRequestDto._();

  factory DecideAssistRequestDto([void updates(DecideAssistRequestDtoBuilder b)]) = _$DecideAssistRequestDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DecideAssistRequestDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DecideAssistRequestDto> get serializer => _$DecideAssistRequestDtoSerializer();
}

class _$DecideAssistRequestDtoSerializer implements PrimitiveSerializer<DecideAssistRequestDto> {
  @override
  final Iterable<Type> types = const [DecideAssistRequestDto, _$DecideAssistRequestDto];

  @override
  final String wireName = r'DecideAssistRequestDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DecideAssistRequestDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DecideAssistRequestDtoStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DecideAssistRequestDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DecideAssistRequestDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DecideAssistRequestDtoStatusEnum),
          ) as DecideAssistRequestDtoStatusEnum;
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
  DecideAssistRequestDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DecideAssistRequestDtoBuilder();
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

class DecideAssistRequestDtoStatusEnum extends EnumClass {

  /// Support decision on the assistance request
  @BuiltValueEnumConst(wireName: r'APPROVED')
  static const DecideAssistRequestDtoStatusEnum APPROVED = _$decideAssistRequestDtoStatusEnum_APPROVED;
  /// Support decision on the assistance request
  @BuiltValueEnumConst(wireName: r'REJECTED')
  static const DecideAssistRequestDtoStatusEnum REJECTED = _$decideAssistRequestDtoStatusEnum_REJECTED;

  static Serializer<DecideAssistRequestDtoStatusEnum> get serializer => _$decideAssistRequestDtoStatusEnumSerializer;

  const DecideAssistRequestDtoStatusEnum._(String name): super(name);

  static BuiltSet<DecideAssistRequestDtoStatusEnum> get values => _$decideAssistRequestDtoStatusEnumValues;
  static DecideAssistRequestDtoStatusEnum valueOf(String name) => _$decideAssistRequestDtoStatusEnumValueOf(name);
}

