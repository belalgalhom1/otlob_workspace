//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'start_break_dto.g.dart';

/// StartBreakDto
///
/// Properties:
/// * [reason] 
/// * [note] - Free-text note shown to the reviewing admin
/// * [requestedMinutes] - Requested break length in minutes. Capped by maxSingleBreakMinutes; omit for up to the cap
@BuiltValue()
abstract class StartBreakDto implements Built<StartBreakDto, StartBreakDtoBuilder> {
  @BuiltValueField(wireName: r'reason')
  StartBreakDtoReasonEnum? get reason;
  // enum reasonEnum {  PRAYER,  MEAL,  REST,  PERSONAL,  OTHER,  };

  /// Free-text note shown to the reviewing admin
  @BuiltValueField(wireName: r'note')
  String? get note;

  /// Requested break length in minutes. Capped by maxSingleBreakMinutes; omit for up to the cap
  @BuiltValueField(wireName: r'requestedMinutes')
  num? get requestedMinutes;

  StartBreakDto._();

  factory StartBreakDto([void updates(StartBreakDtoBuilder b)]) = _$StartBreakDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(StartBreakDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<StartBreakDto> get serializer => _$StartBreakDtoSerializer();
}

class _$StartBreakDtoSerializer implements PrimitiveSerializer<StartBreakDto> {
  @override
  final Iterable<Type> types = const [StartBreakDto, _$StartBreakDto];

  @override
  final String wireName = r'StartBreakDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    StartBreakDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType(StartBreakDtoReasonEnum),
      );
    }
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
  }

  @override
  Object serialize(
    Serializers serializers,
    StartBreakDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required StartBreakDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StartBreakDtoReasonEnum),
          ) as StartBreakDtoReasonEnum;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  StartBreakDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = StartBreakDtoBuilder();
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

class StartBreakDtoReasonEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PRAYER')
  static const StartBreakDtoReasonEnum PRAYER = _$startBreakDtoReasonEnum_PRAYER;
  @BuiltValueEnumConst(wireName: r'MEAL')
  static const StartBreakDtoReasonEnum MEAL = _$startBreakDtoReasonEnum_MEAL;
  @BuiltValueEnumConst(wireName: r'REST')
  static const StartBreakDtoReasonEnum REST = _$startBreakDtoReasonEnum_REST;
  @BuiltValueEnumConst(wireName: r'PERSONAL')
  static const StartBreakDtoReasonEnum PERSONAL = _$startBreakDtoReasonEnum_PERSONAL;
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const StartBreakDtoReasonEnum OTHER = _$startBreakDtoReasonEnum_OTHER;

  static Serializer<StartBreakDtoReasonEnum> get serializer => _$startBreakDtoReasonEnumSerializer;

  const StartBreakDtoReasonEnum._(String name): super(name);

  static BuiltSet<StartBreakDtoReasonEnum> get values => _$startBreakDtoReasonEnumValues;
  static StartBreakDtoReasonEnum valueOf(String name) => _$startBreakDtoReasonEnumValueOf(name);
}

