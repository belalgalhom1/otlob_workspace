//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'excuse_driver_shift_dto.g.dart';

/// ExcuseDriverShiftDto
///
/// Properties:
/// * [isExcused] 
/// * [excuseReason] 
@BuiltValue()
abstract class ExcuseDriverShiftDto implements Built<ExcuseDriverShiftDto, ExcuseDriverShiftDtoBuilder> {
  @BuiltValueField(wireName: r'isExcused')
  bool get isExcused;

  @BuiltValueField(wireName: r'excuseReason')
  String? get excuseReason;

  ExcuseDriverShiftDto._();

  factory ExcuseDriverShiftDto([void updates(ExcuseDriverShiftDtoBuilder b)]) = _$ExcuseDriverShiftDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExcuseDriverShiftDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExcuseDriverShiftDto> get serializer => _$ExcuseDriverShiftDtoSerializer();
}

class _$ExcuseDriverShiftDtoSerializer implements PrimitiveSerializer<ExcuseDriverShiftDto> {
  @override
  final Iterable<Type> types = const [ExcuseDriverShiftDto, _$ExcuseDriverShiftDto];

  @override
  final String wireName = r'ExcuseDriverShiftDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExcuseDriverShiftDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'isExcused';
    yield serializers.serialize(
      object.isExcused,
      specifiedType: const FullType(bool),
    );
    if (object.excuseReason != null) {
      yield r'excuseReason';
      yield serializers.serialize(
        object.excuseReason,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ExcuseDriverShiftDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExcuseDriverShiftDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'isExcused':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isExcused = valueDes;
          break;
        case r'excuseReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.excuseReason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ExcuseDriverShiftDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExcuseDriverShiftDtoBuilder();
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

