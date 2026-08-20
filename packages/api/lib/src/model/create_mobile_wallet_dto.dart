//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_mobile_wallet_dto.g.dart';

/// CreateMobileWalletDto
///
/// Properties:
/// * [number] 
/// * [type] 
/// * [isActive] 
@BuiltValue()
abstract class CreateMobileWalletDto implements Built<CreateMobileWalletDto, CreateMobileWalletDtoBuilder> {
  @BuiltValueField(wireName: r'number')
  String get number;

  @BuiltValueField(wireName: r'type')
  CreateMobileWalletDtoTypeEnum get type;
  // enum typeEnum {  VODAFONE,  ORANGE,  WE,  ETISALAT,  INSTAPAY,  };

  @BuiltValueField(wireName: r'isActive')
  bool? get isActive;

  CreateMobileWalletDto._();

  factory CreateMobileWalletDto([void updates(CreateMobileWalletDtoBuilder b)]) = _$CreateMobileWalletDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateMobileWalletDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateMobileWalletDto> get serializer => _$CreateMobileWalletDtoSerializer();
}

class _$CreateMobileWalletDtoSerializer implements PrimitiveSerializer<CreateMobileWalletDto> {
  @override
  final Iterable<Type> types = const [CreateMobileWalletDto, _$CreateMobileWalletDto];

  @override
  final String wireName = r'CreateMobileWalletDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateMobileWalletDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'number';
    yield serializers.serialize(
      object.number,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(CreateMobileWalletDtoTypeEnum),
    );
    if (object.isActive != null) {
      yield r'isActive';
      yield serializers.serialize(
        object.isActive,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateMobileWalletDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateMobileWalletDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'number':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.number = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CreateMobileWalletDtoTypeEnum),
          ) as CreateMobileWalletDtoTypeEnum;
          result.type = valueDes;
          break;
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateMobileWalletDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateMobileWalletDtoBuilder();
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

class CreateMobileWalletDtoTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'VODAFONE')
  static const CreateMobileWalletDtoTypeEnum VODAFONE = _$createMobileWalletDtoTypeEnum_VODAFONE;
  @BuiltValueEnumConst(wireName: r'ORANGE')
  static const CreateMobileWalletDtoTypeEnum ORANGE = _$createMobileWalletDtoTypeEnum_ORANGE;
  @BuiltValueEnumConst(wireName: r'WE')
  static const CreateMobileWalletDtoTypeEnum WE = _$createMobileWalletDtoTypeEnum_WE;
  @BuiltValueEnumConst(wireName: r'ETISALAT')
  static const CreateMobileWalletDtoTypeEnum ETISALAT = _$createMobileWalletDtoTypeEnum_ETISALAT;
  @BuiltValueEnumConst(wireName: r'INSTAPAY')
  static const CreateMobileWalletDtoTypeEnum INSTAPAY = _$createMobileWalletDtoTypeEnum_INSTAPAY;

  static Serializer<CreateMobileWalletDtoTypeEnum> get serializer => _$createMobileWalletDtoTypeEnumSerializer;

  const CreateMobileWalletDtoTypeEnum._(String name): super(name);

  static BuiltSet<CreateMobileWalletDtoTypeEnum> get values => _$createMobileWalletDtoTypeEnumValues;
  static CreateMobileWalletDtoTypeEnum valueOf(String name) => _$createMobileWalletDtoTypeEnumValueOf(name);
}

