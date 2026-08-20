//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_vendor_dto.g.dart';

/// CreateVendorDto
///
/// Properties:
/// * [storeName] 
/// * [storeNameAr] 
/// * [description] 
/// * [descriptionAr] 
/// * [verticalId] 
/// * [taxId] 
/// * [commissionRate] 
/// * [phone] 
/// * [isContracted] 
/// * [workingHours] 
/// * [is24Hours] 
@BuiltValue()
abstract class CreateVendorDto implements Built<CreateVendorDto, CreateVendorDtoBuilder> {
  @BuiltValueField(wireName: r'storeName')
  String get storeName;

  @BuiltValueField(wireName: r'storeNameAr')
  String? get storeNameAr;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'descriptionAr')
  String? get descriptionAr;

  @BuiltValueField(wireName: r'verticalId')
  String get verticalId;

  @BuiltValueField(wireName: r'taxId')
  String? get taxId;

  @BuiltValueField(wireName: r'commissionRate')
  num? get commissionRate;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'isContracted')
  bool? get isContracted;

  @BuiltValueField(wireName: r'workingHours')
  JsonObject? get workingHours;

  @BuiltValueField(wireName: r'is24Hours')
  bool? get is24Hours;

  CreateVendorDto._();

  factory CreateVendorDto([void updates(CreateVendorDtoBuilder b)]) = _$CreateVendorDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateVendorDtoBuilder b) => b
      ..isContracted = false
      ..is24Hours = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateVendorDto> get serializer => _$CreateVendorDtoSerializer();
}

class _$CreateVendorDtoSerializer implements PrimitiveSerializer<CreateVendorDto> {
  @override
  final Iterable<Type> types = const [CreateVendorDto, _$CreateVendorDto];

  @override
  final String wireName = r'CreateVendorDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateVendorDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'storeName';
    yield serializers.serialize(
      object.storeName,
      specifiedType: const FullType(String),
    );
    if (object.storeNameAr != null) {
      yield r'storeNameAr';
      yield serializers.serialize(
        object.storeNameAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.descriptionAr != null) {
      yield r'descriptionAr';
      yield serializers.serialize(
        object.descriptionAr,
        specifiedType: const FullType(String),
      );
    }
    yield r'verticalId';
    yield serializers.serialize(
      object.verticalId,
      specifiedType: const FullType(String),
    );
    if (object.taxId != null) {
      yield r'taxId';
      yield serializers.serialize(
        object.taxId,
        specifiedType: const FullType(String),
      );
    }
    if (object.commissionRate != null) {
      yield r'commissionRate';
      yield serializers.serialize(
        object.commissionRate,
        specifiedType: const FullType(num),
      );
    }
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    if (object.isContracted != null) {
      yield r'isContracted';
      yield serializers.serialize(
        object.isContracted,
        specifiedType: const FullType(bool),
      );
    }
    if (object.workingHours != null) {
      yield r'workingHours';
      yield serializers.serialize(
        object.workingHours,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.is24Hours != null) {
      yield r'is24Hours';
      yield serializers.serialize(
        object.is24Hours,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateVendorDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateVendorDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'storeName':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.storeName = valueDes;
          break;
        case r'storeNameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.storeNameAr = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'descriptionAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.descriptionAr = valueDes;
          break;
        case r'verticalId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.verticalId = valueDes;
          break;
        case r'taxId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.taxId = valueDes;
          break;
        case r'commissionRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.commissionRate = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'isContracted':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isContracted = valueDes;
          break;
        case r'workingHours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.workingHours = valueDes;
          break;
        case r'is24Hours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.is24Hours = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateVendorDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateVendorDtoBuilder();
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

