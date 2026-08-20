//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'admin_create_driver_dto.g.dart';

/// AdminCreateDriverDto
///
/// Properties:
/// * [email] 
/// * [phone] 
/// * [password] 
/// * [name] 
/// * [nationalId] 
/// * [licenseNumber] 
/// * [vehicleType] 
/// * [vehiclePlate] 
/// * [status] 
/// * [tier] 
/// * [isApproved] 
@BuiltValue()
abstract class AdminCreateDriverDto implements Built<AdminCreateDriverDto, AdminCreateDriverDtoBuilder> {
  @BuiltValueField(wireName: r'email')
  String get email;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'password')
  String get password;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nationalId')
  String? get nationalId;

  @BuiltValueField(wireName: r'licenseNumber')
  String? get licenseNumber;

  @BuiltValueField(wireName: r'vehicleType')
  AdminCreateDriverDtoVehicleTypeEnum get vehicleType;
  // enum vehicleTypeEnum {  BICYCLE,  MOTORCYCLE,  CAR,  VAN,  TRUCK,  MOTOR_TRICYCLE,  };

  @BuiltValueField(wireName: r'vehiclePlate')
  String? get vehiclePlate;

  @BuiltValueField(wireName: r'status')
  AdminCreateDriverDtoStatusEnum? get status;
  // enum statusEnum {  OFFLINE,  ONLINE,  BUSY,  ON_DELIVERY,  ON_BREAK,  SUSPENDED,  };

  @BuiltValueField(wireName: r'tier')
  String? get tier;

  @BuiltValueField(wireName: r'isApproved')
  bool? get isApproved;

  AdminCreateDriverDto._();

  factory AdminCreateDriverDto([void updates(AdminCreateDriverDtoBuilder b)]) = _$AdminCreateDriverDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdminCreateDriverDtoBuilder b) => b
      ..vehicleType = AdminCreateDriverDtoVehicleTypeEnum.valueOf('MOTORCYCLE');

  @BuiltValueSerializer(custom: true)
  static Serializer<AdminCreateDriverDto> get serializer => _$AdminCreateDriverDtoSerializer();
}

class _$AdminCreateDriverDtoSerializer implements PrimitiveSerializer<AdminCreateDriverDto> {
  @override
  final Iterable<Type> types = const [AdminCreateDriverDto, _$AdminCreateDriverDto];

  @override
  final String wireName = r'AdminCreateDriverDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AdminCreateDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    yield r'password';
    yield serializers.serialize(
      object.password,
      specifiedType: const FullType(String),
    );
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
      specifiedType: const FullType(AdminCreateDriverDtoVehicleTypeEnum),
    );
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
        specifiedType: const FullType(AdminCreateDriverDtoStatusEnum),
      );
    }
    if (object.tier != null) {
      yield r'tier';
      yield serializers.serialize(
        object.tier,
        specifiedType: const FullType(String),
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
    AdminCreateDriverDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdminCreateDriverDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.password = valueDes;
          break;
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
            specifiedType: const FullType(AdminCreateDriverDtoVehicleTypeEnum),
          ) as AdminCreateDriverDtoVehicleTypeEnum;
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
            specifiedType: const FullType(AdminCreateDriverDtoStatusEnum),
          ) as AdminCreateDriverDtoStatusEnum;
          result.status = valueDes;
          break;
        case r'tier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tier = valueDes;
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
  AdminCreateDriverDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdminCreateDriverDtoBuilder();
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

class AdminCreateDriverDtoVehicleTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'BICYCLE')
  static const AdminCreateDriverDtoVehicleTypeEnum BICYCLE = _$adminCreateDriverDtoVehicleTypeEnum_BICYCLE;
  @BuiltValueEnumConst(wireName: r'MOTORCYCLE')
  static const AdminCreateDriverDtoVehicleTypeEnum MOTORCYCLE = _$adminCreateDriverDtoVehicleTypeEnum_MOTORCYCLE;
  @BuiltValueEnumConst(wireName: r'CAR')
  static const AdminCreateDriverDtoVehicleTypeEnum CAR = _$adminCreateDriverDtoVehicleTypeEnum_CAR;
  @BuiltValueEnumConst(wireName: r'VAN')
  static const AdminCreateDriverDtoVehicleTypeEnum VAN = _$adminCreateDriverDtoVehicleTypeEnum_VAN;
  @BuiltValueEnumConst(wireName: r'TRUCK')
  static const AdminCreateDriverDtoVehicleTypeEnum TRUCK = _$adminCreateDriverDtoVehicleTypeEnum_TRUCK;
  @BuiltValueEnumConst(wireName: r'MOTOR_TRICYCLE')
  static const AdminCreateDriverDtoVehicleTypeEnum MOTOR_TRICYCLE = _$adminCreateDriverDtoVehicleTypeEnum_MOTOR_TRICYCLE;

  static Serializer<AdminCreateDriverDtoVehicleTypeEnum> get serializer => _$adminCreateDriverDtoVehicleTypeEnumSerializer;

  const AdminCreateDriverDtoVehicleTypeEnum._(String name): super(name);

  static BuiltSet<AdminCreateDriverDtoVehicleTypeEnum> get values => _$adminCreateDriverDtoVehicleTypeEnumValues;
  static AdminCreateDriverDtoVehicleTypeEnum valueOf(String name) => _$adminCreateDriverDtoVehicleTypeEnumValueOf(name);
}

class AdminCreateDriverDtoStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OFFLINE')
  static const AdminCreateDriverDtoStatusEnum OFFLINE = _$adminCreateDriverDtoStatusEnum_OFFLINE;
  @BuiltValueEnumConst(wireName: r'ONLINE')
  static const AdminCreateDriverDtoStatusEnum ONLINE = _$adminCreateDriverDtoStatusEnum_ONLINE;
  @BuiltValueEnumConst(wireName: r'BUSY')
  static const AdminCreateDriverDtoStatusEnum BUSY = _$adminCreateDriverDtoStatusEnum_BUSY;
  @BuiltValueEnumConst(wireName: r'ON_DELIVERY')
  static const AdminCreateDriverDtoStatusEnum ON_DELIVERY = _$adminCreateDriverDtoStatusEnum_ON_DELIVERY;
  @BuiltValueEnumConst(wireName: r'ON_BREAK')
  static const AdminCreateDriverDtoStatusEnum ON_BREAK = _$adminCreateDriverDtoStatusEnum_ON_BREAK;
  @BuiltValueEnumConst(wireName: r'SUSPENDED')
  static const AdminCreateDriverDtoStatusEnum SUSPENDED = _$adminCreateDriverDtoStatusEnum_SUSPENDED;

  static Serializer<AdminCreateDriverDtoStatusEnum> get serializer => _$adminCreateDriverDtoStatusEnumSerializer;

  const AdminCreateDriverDtoStatusEnum._(String name): super(name);

  static BuiltSet<AdminCreateDriverDtoStatusEnum> get values => _$adminCreateDriverDtoStatusEnumValues;
  static AdminCreateDriverDtoStatusEnum valueOf(String name) => _$adminCreateDriverDtoStatusEnumValueOf(name);
}

