//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'unassign_drivers_from_manager_dto.g.dart';

/// UnassignDriversFromManagerDto
///
/// Properties:
/// * [driverIds] - List of driver IDs to unassign from this manager
@BuiltValue()
abstract class UnassignDriversFromManagerDto implements Built<UnassignDriversFromManagerDto, UnassignDriversFromManagerDtoBuilder> {
  /// List of driver IDs to unassign from this manager
  @BuiltValueField(wireName: r'driverIds')
  BuiltList<String> get driverIds;

  UnassignDriversFromManagerDto._();

  factory UnassignDriversFromManagerDto([void updates(UnassignDriversFromManagerDtoBuilder b)]) = _$UnassignDriversFromManagerDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UnassignDriversFromManagerDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UnassignDriversFromManagerDto> get serializer => _$UnassignDriversFromManagerDtoSerializer();
}

class _$UnassignDriversFromManagerDtoSerializer implements PrimitiveSerializer<UnassignDriversFromManagerDto> {
  @override
  final Iterable<Type> types = const [UnassignDriversFromManagerDto, _$UnassignDriversFromManagerDto];

  @override
  final String wireName = r'UnassignDriversFromManagerDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UnassignDriversFromManagerDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'driverIds';
    yield serializers.serialize(
      object.driverIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UnassignDriversFromManagerDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UnassignDriversFromManagerDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'driverIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.driverIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UnassignDriversFromManagerDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UnassignDriversFromManagerDtoBuilder();
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

