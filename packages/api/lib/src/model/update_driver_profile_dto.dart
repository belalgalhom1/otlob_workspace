//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_driver_profile_dto.g.dart';

/// UpdateDriverProfileDto
///
/// Properties:
/// * [name] 
/// * [nationalId] 
/// * [licenseNumber] 
/// * [vehicleType] 
/// * [vehiclePlate] 
@BuiltValue()
abstract class UpdateDriverProfileDto implements Built<UpdateDriverProfileDto, UpdateDriverProfileDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'nationalId')
  String? get nationalId;

  @BuiltValueField(wireName: r'licenseNumber')
  String? get licenseNumber;

  @BuiltValueField(wireName: r'vehicleType')
  UpdateDriverProfileDtoVehicleTypeEnum? get vehicleType;
  // enum vehicleTypeEnum {  BICYCLE,  MOTORCYCLE,  CAR,  VAN,  TRUCK,  MOTOR_TRICYCLE,  };

  @BuiltValueField(wireName: r'vehiclePlate')
  String? get vehiclePlate;

  UpdateDriverProfileDto._();

  factory UpdateDriverProfileDto([void updates(UpdateDriverProfileDtoBuilder b)]) = _$UpdateDriverProfileDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateDriverProfileDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateDriverProfileDto> get serializer => _$UpdateDriverProfileDtoSerializer();
}

class _$UpdateDriverProfileDtoSerializer implements PrimitiveSerializer<UpdateDriverProfileDto> {
  @override
  final Iterable<Type> types = const [UpdateDriverProfileDto, _$UpdateDriverProfileDto];

  @override
  final String wireName = r'UpdateDriverProfileDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateDriverProfileDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.nationalId != null) {
      yield r'nationalId';
      yield serializers.serialize(
        object.nationalId,
        specifiedType: const FullType(String),
      );
    }
    if (object.licenseNumber != null) {
      yield r'licenseNumber';
      yield serializers.serialize(
        object.licenseNumber,
        specifiedType: const FullType(String),
      );
    }
    if (object.vehicleType != null) {
      yield r'vehicleType';
      yield serializers.serialize(
        object.vehicleType,
        specifiedType: const FullType(UpdateDriverProfileDtoVehicleTypeEnum),
      );
    }
    if (object.vehiclePlate != null) {
      yield r'vehiclePlate';
      yield serializers.serialize(
        object.vehiclePlate,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateDriverProfileDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateDriverProfileDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'nationalId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nationalId = valueDes;
          break;
        case r'licenseNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.licenseNumber = valueDes;
          break;
        case r'vehicleType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(UpdateDriverProfileDtoVehicleTypeEnum),
          ) as UpdateDriverProfileDtoVehicleTypeEnum;
          result.vehicleType = valueDes;
          break;
        case r'vehiclePlate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vehiclePlate = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateDriverProfileDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateDriverProfileDtoBuilder();
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

class UpdateDriverProfileDtoVehicleTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'BICYCLE')
  static const UpdateDriverProfileDtoVehicleTypeEnum BICYCLE = _$updateDriverProfileDtoVehicleTypeEnum_BICYCLE;
  @BuiltValueEnumConst(wireName: r'MOTORCYCLE')
  static const UpdateDriverProfileDtoVehicleTypeEnum MOTORCYCLE = _$updateDriverProfileDtoVehicleTypeEnum_MOTORCYCLE;
  @BuiltValueEnumConst(wireName: r'CAR')
  static const UpdateDriverProfileDtoVehicleTypeEnum CAR = _$updateDriverProfileDtoVehicleTypeEnum_CAR;
  @BuiltValueEnumConst(wireName: r'VAN')
  static const UpdateDriverProfileDtoVehicleTypeEnum VAN = _$updateDriverProfileDtoVehicleTypeEnum_VAN;
  @BuiltValueEnumConst(wireName: r'TRUCK')
  static const UpdateDriverProfileDtoVehicleTypeEnum TRUCK = _$updateDriverProfileDtoVehicleTypeEnum_TRUCK;
  @BuiltValueEnumConst(wireName: r'MOTOR_TRICYCLE')
  static const UpdateDriverProfileDtoVehicleTypeEnum MOTOR_TRICYCLE = _$updateDriverProfileDtoVehicleTypeEnum_MOTOR_TRICYCLE;

  static Serializer<UpdateDriverProfileDtoVehicleTypeEnum> get serializer => _$updateDriverProfileDtoVehicleTypeEnumSerializer;

  const UpdateDriverProfileDtoVehicleTypeEnum._(String name): super(name);

  static BuiltSet<UpdateDriverProfileDtoVehicleTypeEnum> get values => _$updateDriverProfileDtoVehicleTypeEnumValues;
  static UpdateDriverProfileDtoVehicleTypeEnum valueOf(String name) => _$updateDriverProfileDtoVehicleTypeEnumValueOf(name);
}

