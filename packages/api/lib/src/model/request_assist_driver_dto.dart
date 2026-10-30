//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'request_assist_driver_dto.g.dart';

/// RequestAssistDriverDto
///
/// Properties:
/// * [reason] - Why this delivery needs a second pair of hands
/// * [note] 
@BuiltValue()
abstract class RequestAssistDriverDto implements Built<RequestAssistDriverDto, RequestAssistDriverDtoBuilder> {
  /// Why this delivery needs a second pair of hands
  @BuiltValueField(wireName: r'reason')
  RequestAssistDriverDtoReasonEnum get reason;
  // enum reasonEnum {  TOO_LARGE,  TOO_HEAVY,  MULTI_STOP_COMPLEXITY,  LONG_DISTANCE,  ACCESS_RESTRICTED,  OTHER,  };

  @BuiltValueField(wireName: r'note')
  String? get note;

  RequestAssistDriverDto._();

  factory RequestAssistDriverDto([void updates(RequestAssistDriverDtoBuilder b)]) = _$RequestAssistDriverDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RequestAssistDriverDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RequestAssistDriverDto> get serializer => _$RequestAssistDriverDtoSerializer();
}

class _$RequestAssistDriverDtoSerializer implements PrimitiveSerializer<RequestAssistDriverDto> {
  @override
  final Iterable<Type> types = const [RequestAssistDriverDto, _$RequestAssistDriverDto];

  @override
  final String wireName = r'RequestAssistDriverDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RequestAssistDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(RequestAssistDriverDtoReasonEnum),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    RequestAssistDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RequestAssistDriverDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RequestAssistDriverDtoReasonEnum),
          ) as RequestAssistDriverDtoReasonEnum;
          result.reason = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.note = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RequestAssistDriverDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RequestAssistDriverDtoBuilder();
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

class RequestAssistDriverDtoReasonEnum extends EnumClass {

  /// Why this delivery needs a second pair of hands
  @BuiltValueEnumConst(wireName: r'TOO_LARGE')
  static const RequestAssistDriverDtoReasonEnum TOO_LARGE = _$requestAssistDriverDtoReasonEnum_TOO_LARGE;
  /// Why this delivery needs a second pair of hands
  @BuiltValueEnumConst(wireName: r'TOO_HEAVY')
  static const RequestAssistDriverDtoReasonEnum TOO_HEAVY = _$requestAssistDriverDtoReasonEnum_TOO_HEAVY;
  /// Why this delivery needs a second pair of hands
  @BuiltValueEnumConst(wireName: r'MULTI_STOP_COMPLEXITY')
  static const RequestAssistDriverDtoReasonEnum MULTI_STOP_COMPLEXITY = _$requestAssistDriverDtoReasonEnum_MULTI_STOP_COMPLEXITY;
  /// Why this delivery needs a second pair of hands
  @BuiltValueEnumConst(wireName: r'LONG_DISTANCE')
  static const RequestAssistDriverDtoReasonEnum LONG_DISTANCE = _$requestAssistDriverDtoReasonEnum_LONG_DISTANCE;
  /// Why this delivery needs a second pair of hands
  @BuiltValueEnumConst(wireName: r'ACCESS_RESTRICTED')
  static const RequestAssistDriverDtoReasonEnum ACCESS_RESTRICTED = _$requestAssistDriverDtoReasonEnum_ACCESS_RESTRICTED;
  /// Why this delivery needs a second pair of hands
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const RequestAssistDriverDtoReasonEnum OTHER = _$requestAssistDriverDtoReasonEnum_OTHER;

  static Serializer<RequestAssistDriverDtoReasonEnum> get serializer => _$requestAssistDriverDtoReasonEnumSerializer;

  const RequestAssistDriverDtoReasonEnum._(String name): super(name);

  static BuiltSet<RequestAssistDriverDtoReasonEnum> get values => _$requestAssistDriverDtoReasonEnumValues;
  static RequestAssistDriverDtoReasonEnum valueOf(String name) => _$requestAssistDriverDtoReasonEnumValueOf(name);
}

