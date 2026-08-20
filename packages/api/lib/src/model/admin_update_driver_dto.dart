//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_update_driver_dto.g.dart';

/// AdminUpdateDriverDto
///
/// Properties:
/// * [name] 
/// * [nationalId] 
/// * [licenseNumber] 
/// * [vehicleType] 
/// * [vehiclePlate] 
/// * [status] 
/// * [isApproved] 
@BuiltValue()
abstract class AdminUpdateDriverDto implements Built<AdminUpdateDriverDto, AdminUpdateDriverDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'nationalId')
  String? get nationalId;

  @BuiltValueField(wireName: r'licenseNumber')
  String? get licenseNumber;

  @BuiltValueField(wireName: r'vehicleType')
  AdminUpdateDriverDtoVehicleTypeEnum? get vehicleType;
  // enum vehicleTypeEnum {  BICYCLE,  MOTORCYCLE,  CAR,  VAN,  TRUCK,  MOTOR_TRICYCLE,  };

  @BuiltValueField(wireName: r'vehiclePlate')
  String? get vehiclePlate;

  @BuiltValueField(wireName: r'status')
  AdminUpdateDriverDtoStatusEnum? get status;
  // enum statusEnum {  OFFLINE,  ONLINE,  BUSY,  ON_DELIVERY,  ON_BREAK,  SUSPENDED,  };

  @BuiltValueField(wireName: r'isApproved')
  bool? get isApproved;

  AdminUpdateDriverDto._();

  factory AdminUpdateDriverDto([void updates(AdminUpdateDriverDtoBuilder b)]) = _$AdminUpdateDriverDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminUpdateDriverDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminUpdateDriverDto> get serializer => _$AdminUpdateDriverDtoSerializer();
}

class _$AdminUpdateDriverDtoSerializer implements PrimitiveSerializer<AdminUpdateDriverDto> {
  @override
  final Iterable<Type> types = const [AdminUpdateDriverDto, _$AdminUpdateDriverDto];

  @override
  final String wireName = r'AdminUpdateDriverDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminUpdateDriverDto object, {
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
        specifiedType: const FullType(AdminUpdateDriverDtoVehicleTypeEnum),
      );
    }
    if (object.vehiclePlate != null) {
      yield r'vehiclePlate';
      yield serializers.serialize(
        object.vehiclePlate,
        specifiedType: const FullType(String),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType(AdminUpdateDriverDtoStatusEnum),
      );
    }
    if (object.isApproved != null) {
      yield r'isApproved';
      yield serializers.serialize(
        object.isApproved,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AdminUpdateDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminUpdateDriverDtoBuilder result,
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
            specifiedType: const FullType(AdminUpdateDriverDtoVehicleTypeEnum),
          ) as AdminUpdateDriverDtoVehicleTypeEnum;
          result.vehicleType = valueDes;
          break;
        case r'vehiclePlate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.vehiclePlate = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AdminUpdateDriverDtoStatusEnum),
          ) as AdminUpdateDriverDtoStatusEnum;
          result.status = valueDes;
          break;
        case r'isApproved':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isApproved = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AdminUpdateDriverDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminUpdateDriverDtoBuilder();
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

class AdminUpdateDriverDtoVehicleTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'BICYCLE')
  static const AdminUpdateDriverDtoVehicleTypeEnum BICYCLE = _$adminUpdateDriverDtoVehicleTypeEnum_BICYCLE;
  @BuiltValueEnumConst(wireName: r'MOTORCYCLE')
  static const AdminUpdateDriverDtoVehicleTypeEnum MOTORCYCLE = _$adminUpdateDriverDtoVehicleTypeEnum_MOTORCYCLE;
  @BuiltValueEnumConst(wireName: r'CAR')
  static const AdminUpdateDriverDtoVehicleTypeEnum CAR = _$adminUpdateDriverDtoVehicleTypeEnum_CAR;
  @BuiltValueEnumConst(wireName: r'VAN')
  static const AdminUpdateDriverDtoVehicleTypeEnum VAN = _$adminUpdateDriverDtoVehicleTypeEnum_VAN;
  @BuiltValueEnumConst(wireName: r'TRUCK')
  static const AdminUpdateDriverDtoVehicleTypeEnum TRUCK = _$adminUpdateDriverDtoVehicleTypeEnum_TRUCK;
  @BuiltValueEnumConst(wireName: r'MOTOR_TRICYCLE')
  static const AdminUpdateDriverDtoVehicleTypeEnum MOTOR_TRICYCLE = _$adminUpdateDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE;

  static Serializer<AdminUpdateDriverDtoVehicleTypeEnum> get serializer => _$adminUpdateDriverDtoVehicleTypeEnumSerializer;

  const AdminUpdateDriverDtoVehicleTypeEnum._(String name): super(name);

  static BuiltSet<AdminUpdateDriverDtoVehicleTypeEnum> get values => _$adminUpdateDriverDtoVehicleTypeEnumValues;
  static AdminUpdateDriverDtoVehicleTypeEnum valueOf(String name) => _$adminUpdateDriverDtoVehicleTypeEnumValueOf(name);
}

class AdminUpdateDriverDtoStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OFFLINE')
  static const AdminUpdateDriverDtoStatusEnum OFFLINE = _$adminUpdateDriverDtoStatusEnum_OFFLINE;
  @BuiltValueEnumConst(wireName: r'ONLINE')
  static const AdminUpdateDriverDtoStatusEnum ONLINE = _$adminUpdateDriverDtoStatusEnum_ONLINE;
  @BuiltValueEnumConst(wireName: r'BUSY')
  static const AdminUpdateDriverDtoStatusEnum BUSY = _$adminUpdateDriverDtoStatusEnum_BUSY;
  @BuiltValueEnumConst(wireName: r'ON_DELIVERY')
  static const AdminUpdateDriverDtoStatusEnum ON_DELIVERY = _$adminUpdateDriverDtoStatusEnum_ON_DELIVERY;
  @BuiltValueEnumConst(wireName: r'ON_BREAK')
  static const AdminUpdateDriverDtoStatusEnum ON_BREAK = _$adminUpdateDriverDtoStatusEnum_ON_BREAK;
  @BuiltValueEnumConst(wireName: r'SUSPENDED')
  static const AdminUpdateDriverDtoStatusEnum SUSPENDED = _$adminUpdateDriverDtoStatusEnum_SUSPENDED;

  static Serializer<AdminUpdateDriverDtoStatusEnum> get serializer => _$adminUpdateDriverDtoStatusEnumSerializer;

  const AdminUpdateDriverDtoStatusEnum._(String name): super(name);

  static BuiltSet<AdminUpdateDriverDtoStatusEnum> get values => _$adminUpdateDriverDtoStatusEnumValues;
  static AdminUpdateDriverDtoStatusEnum valueOf(String name) => _$adminUpdateDriverDtoStatusEnumValueOf(name);
}

