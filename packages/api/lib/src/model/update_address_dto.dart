//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_address_dto.g.dart';

/// UpdateAddressDto
///
/// Properties:
/// * [label] 
/// * [address] 
/// * [location] 
/// * [details] 
/// * [isDefault] 
@BuiltValue()
abstract class UpdateAddressDto implements Built<UpdateAddressDto, UpdateAddressDtoBuilder> {
  @BuiltValueField(wireName: r'label')
  String? get label;

  @BuiltValueField(wireName: r'address')
  String? get address;

  @BuiltValueField(wireName: r'location')
  BuiltList<num>? get location;

  @BuiltValueField(wireName: r'details')
  String? get details;

  @BuiltValueField(wireName: r'isDefault')
  bool? get isDefault;

  UpdateAddressDto._();

  factory UpdateAddressDto([void updates(UpdateAddressDtoBuilder b)]) = _$UpdateAddressDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateAddressDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateAddressDto> get serializer => _$UpdateAddressDtoSerializer();
}

class _$UpdateAddressDtoSerializer implements PrimitiveSerializer<UpdateAddressDto> {
  @override
  final Iterable<Type> types = const [UpdateAddressDto, _$UpdateAddressDto];

  @override
  final String wireName = r'UpdateAddressDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateAddressDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.label != null) {
      yield r'label';
      yield serializers.serialize(
        object.label,
        specifiedType: const FullType(String),
      );
    }
    if (object.address != null) {
      yield r'address';
      yield serializers.serialize(
        object.address,
        specifiedType: const FullType(String),
      );
    }
    if (object.location != null) {
      yield r'location';
      yield serializers.serialize(
        object.location,
        specifiedType: const FullType(BuiltList, [FullType(num)]),
      );
    }
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
    UpdateAddressDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateAddressDtoBuilder result,
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
  UpdateAddressDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateAddressDtoBuilder();
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

