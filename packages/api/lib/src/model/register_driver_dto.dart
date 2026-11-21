//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'register_driver_dto.g.dart';

/// RegisterDriverDto
///
/// Properties:
/// * [name] 
/// * [nationalId] 
/// * [licenseNumber] 
/// * [vehicleType] 
/// * [vehiclePlate] 
@BuiltValue()
abstract class RegisterDriverDto implements Built<RegisterDriverDto, RegisterDriverDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nationalId')
  String? get nationalId;

  @BuiltValueField(wireName: r'licenseNumber')
  String? get licenseNumber;

  @BuiltValueField(wireName: r'vehicleType')
  RegisterDriverDtoVehicleTypeEnum get vehicleType;
  // enum vehicleTypeEnum {  BICYCLE,  MOTORCYCLE,  CAR,  MINIBUS,  TUK_TUK,  MOTOR_TRICYCLE,  QUARTER_TRUCK,  HALF_TRUCK,  };

  @BuiltValueField(wireName: r'vehiclePlate')
  String? get vehiclePlate;

  RegisterDriverDto._();

  factory RegisterDriverDto([void updates(RegisterDriverDtoBuilder b)]) = _$RegisterDriverDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegisterDriverDtoBuilder b) => b
      ..vehicleType = RegisterDriverDtoVehicleTypeEnum.valueOf('MOTORCYCLE');

  @BuiltValueSerializer(custom: true)
  static Serializer<RegisterDriverDto> get serializer => _$RegisterDriverDtoSerializer();
}

class _$RegisterDriverDtoSerializer implements PrimitiveSerializer<RegisterDriverDto> {
  @override
  final Iterable<Type> types = const [RegisterDriverDto, _$RegisterDriverDto];

  @override
  final String wireName = r'RegisterDriverDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegisterDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
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
    yield r'vehicleType';
    yield serializers.serialize(
      object.vehicleType,
      specifiedType: const FullType(RegisterDriverDtoVehicleTypeEnum),
    );
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
    RegisterDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RegisterDriverDtoBuilder result,
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
            specifiedType: const FullType(RegisterDriverDtoVehicleTypeEnum),
          ) as RegisterDriverDtoVehicleTypeEnum;
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
  RegisterDriverDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegisterDriverDtoBuilder();
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

class RegisterDriverDtoVehicleTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'BICYCLE')
  static const RegisterDriverDtoVehicleTypeEnum BICYCLE = _$registerDriverDtoVehicleTypeEnum_BICYCLE;
  @BuiltValueEnumConst(wireName: r'MOTORCYCLE')
  static const RegisterDriverDtoVehicleTypeEnum MOTORCYCLE = _$registerDriverDtoVehicleTypeEnum_MOTORCYCLE;
  @BuiltValueEnumConst(wireName: r'CAR')
  static const RegisterDriverDtoVehicleTypeEnum CAR = _$registerDriverDtoVehicleTypeEnum_CAR;
  @BuiltValueEnumConst(wireName: r'MINIBUS')
  static const RegisterDriverDtoVehicleTypeEnum MINIBUS = _$registerDriverDtoVehicleTypeEnum_MINIBUS;
  @BuiltValueEnumConst(wireName: r'TUK_TUK')
  static const RegisterDriverDtoVehicleTypeEnum TUK_TUK = _$registerDriverDtoVehicleTypeEnum_TUK_TUK;
  @BuiltValueEnumConst(wireName: r'MOTOR_TRICYCLE')
  static const RegisterDriverDtoVehicleTypeEnum MOTOR_TRICYCLE = _$registerDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE;
  @BuiltValueEnumConst(wireName: r'QUARTER_TRUCK')
  static const RegisterDriverDtoVehicleTypeEnum QUARTER_TRUCK = _$registerDriverDtoVehicleTypeEnum_QUARTER_TRUCK;
  @BuiltValueEnumConst(wireName: r'HALF_TRUCK')
  static const RegisterDriverDtoVehicleTypeEnum HALF_TRUCK = _$registerDriverDtoVehicleTypeEnum_HALF_TRUCK;

  static Serializer<RegisterDriverDtoVehicleTypeEnum> get serializer => _$registerDriverDtoVehicleTypeEnumSerializer;

  const RegisterDriverDtoVehicleTypeEnum._(String name): super(name);

  static BuiltSet<RegisterDriverDtoVehicleTypeEnum> get values => _$registerDriverDtoVehicleTypeEnumValues;
  static RegisterDriverDtoVehicleTypeEnum valueOf(String name) => _$registerDriverDtoVehicleTypeEnumValueOf(name);
}

