//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_tier.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'override_driver_rank_dto.g.dart';

/// OverrideDriverRankDto
///
/// Properties:
/// * [newTier] 
/// * [reason] 
@BuiltValue()
abstract class OverrideDriverRankDto implements Built<OverrideDriverRankDto, OverrideDriverRankDtoBuilder> {
  @BuiltValueField(wireName: r'newTier')
  DriverTier get newTier;
  // enum newTierEnum {  BRONZE,  SILVER,  GOLD,  };

  @BuiltValueField(wireName: r'reason')
  String get reason;

  OverrideDriverRankDto._();

  factory OverrideDriverRankDto([void updates(OverrideDriverRankDtoBuilder b)]) = _$OverrideDriverRankDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OverrideDriverRankDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OverrideDriverRankDto> get serializer => _$OverrideDriverRankDtoSerializer();
}

class _$OverrideDriverRankDtoSerializer implements PrimitiveSerializer<OverrideDriverRankDto> {
  @override
  final Iterable<Type> types = const [OverrideDriverRankDto, _$OverrideDriverRankDto];

  @override
  final String wireName = r'OverrideDriverRankDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OverrideDriverRankDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'newTier';
    yield serializers.serialize(
      object.newTier,
      specifiedType: const FullType(DriverTier),
    );
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    OverrideDriverRankDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OverrideDriverRankDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'newTier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverTier),
          ) as DriverTier;
          result.newTier = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OverrideDriverRankDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OverrideDriverRankDtoBuilder();
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

