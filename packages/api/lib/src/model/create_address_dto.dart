//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_address_dto.g.dart';

/// CreateAddressDto
///
/// Properties:
/// * [label] 
/// * [address] 
/// * [location] 
/// * [details] 
/// * [isDefault] 
@BuiltValue()
abstract class CreateAddressDto implements Built<CreateAddressDto, CreateAddressDtoBuilder> {
  @BuiltValueField(wireName: r'label')
  String? get label;

  @BuiltValueField(wireName: r'address')
  String get address;

  @BuiltValueField(wireName: r'location')
  BuiltList<num> get location;

  @BuiltValueField(wireName: r'details')
  String? get details;

  @BuiltValueField(wireName: r'isDefault')
  bool? get isDefault;

  CreateAddressDto._();

  factory CreateAddressDto([void updates(CreateAddressDtoBuilder b)]) = _$CreateAddressDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateAddressDtoBuilder b) => b
      ..isDefault = false;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateAddressDto> get serializer => _$CreateAddressDtoSerializer();
}

class _$CreateAddressDtoSerializer implements PrimitiveSerializer<CreateAddressDto> {
  @override
  final Iterable<Type> types = const [CreateAddressDto, _$CreateAddressDto];

  @override
  final String wireName = r'CreateAddressDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateAddressDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.label != null) {
      yield r'label';
      yield serializers.serialize(
        object.label,
        specifiedType: const FullType(String),
      );
    }
    yield r'address';
    yield serializers.serialize(
      object.address,
      specifiedType: const FullType(String),
    );
    yield r'location';
    yield serializers.serialize(
      object.location,
      specifiedType: const FullType(BuiltList, [FullType(num)]),
    );
    if (object.details != null) {
      yield r'details';
      yield serializers.serialize(
        object.details,
        specifiedType: const FullType(String),
      );
    }
    if (object.isDefault != null) {
      yield r'isDefault';
      yield serializers.serialize(
        object.isDefault,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateAddressDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateAddressDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'label':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.label = valueDes;
          break;
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.address = valueDes;
          break;
        case r'location':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(num)]),
          ) as BuiltList<num>;
          result.location.replace(valueDes);
          break;
        case r'details':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.details = valueDes;
          break;
        case r'isDefault':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isDefault = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateAddressDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateAddressDtoBuilder();
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

