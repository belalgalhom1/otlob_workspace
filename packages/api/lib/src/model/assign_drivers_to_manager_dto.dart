//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'assign_drivers_to_manager_dto.g.dart';

/// AssignDriversToManagerDto
///
/// Properties:
/// * [driverManagerUserId] - User ID of the driver manager
/// * [driverIds] - List of driver IDs to assign to this manager
/// * [manageAllDrivers] - Whether this manager should manage all drivers in the system
@BuiltValue()
abstract class AssignDriversToManagerDto implements Built<AssignDriversToManagerDto, AssignDriversToManagerDtoBuilder> {
  /// User ID of the driver manager
  @BuiltValueField(wireName: r'driverManagerUserId')
  String get driverManagerUserId;

  /// List of driver IDs to assign to this manager
  @BuiltValueField(wireName: r'driverIds')
  BuiltList<String>? get driverIds;

  /// Whether this manager should manage all drivers in the system
  @BuiltValueField(wireName: r'manageAllDrivers')
  bool? get manageAllDrivers;

  AssignDriversToManagerDto._();

  factory AssignDriversToManagerDto([void updates(AssignDriversToManagerDtoBuilder b)]) = _$AssignDriversToManagerDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AssignDriversToManagerDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AssignDriversToManagerDto> get serializer => _$AssignDriversToManagerDtoSerializer();
}

class _$AssignDriversToManagerDtoSerializer implements PrimitiveSerializer<AssignDriversToManagerDto> {
  @override
  final Iterable<Type> types = const [AssignDriversToManagerDto, _$AssignDriversToManagerDto];

  @override
  final String wireName = r'AssignDriversToManagerDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AssignDriversToManagerDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'driverManagerUserId';
    yield serializers.serialize(
      object.driverManagerUserId,
      specifiedType: const FullType(String),
    );
    if (object.driverIds != null) {
      yield r'driverIds';
      yield serializers.serialize(
        object.driverIds,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
    if (object.manageAllDrivers != null) {
      yield r'manageAllDrivers';
      yield serializers.serialize(
        object.manageAllDrivers,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AssignDriversToManagerDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AssignDriversToManagerDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'driverManagerUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverManagerUserId = valueDes;
          break;
        case r'driverIds':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.driverIds.replace(valueDes);
          break;
        case r'manageAllDrivers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.manageAllDrivers = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AssignDriversToManagerDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AssignDriversToManagerDtoBuilder();
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

