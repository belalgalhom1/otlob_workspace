//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_vendor_branch_dto.g.dart';

/// CreateVendorBranchDto
///
/// Properties:
/// * [name] 
/// * [nameAr] 
/// * [address] 
/// * [phone] 
/// * [location] 
/// * [zoneId] 
/// * [isOpen] 
@BuiltValue()
abstract class CreateVendorBranchDto implements Built<CreateVendorBranchDto, CreateVendorBranchDtoBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'address')
  String get address;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'location')
  BuiltList<String> get location;

  @BuiltValueField(wireName: r'zoneId')
  String? get zoneId;

  @BuiltValueField(wireName: r'isOpen')
  bool? get isOpen;

  CreateVendorBranchDto._();

  factory CreateVendorBranchDto([void updates(CreateVendorBranchDtoBuilder b)]) = _$CreateVendorBranchDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateVendorBranchDtoBuilder b) => b
      ..isOpen = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateVendorBranchDto> get serializer => _$CreateVendorBranchDtoSerializer();
}

class _$CreateVendorBranchDtoSerializer implements PrimitiveSerializer<CreateVendorBranchDto> {
  @override
  final Iterable<Type> types = const [CreateVendorBranchDto, _$CreateVendorBranchDto];

  @override
  final String wireName = r'CreateVendorBranchDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateVendorBranchDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.nameAr != null) {
      yield r'nameAr';
      yield serializers.serialize(
        object.nameAr,
        specifiedType: const FullType(String),
      );
    }
    yield r'address';
    yield serializers.serialize(
      object.address,
      specifiedType: const FullType(String),
    );
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType(String),
      );
    }
    yield r'location';
    yield serializers.serialize(
      object.location,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    if (object.zoneId != null) {
      yield r'zoneId';
      yield serializers.serialize(
        object.zoneId,
        specifiedType: const FullType(String),
      );
    }
    if (object.isOpen != null) {
      yield r'isOpen';
      yield serializers.serialize(
        object.isOpen,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateVendorBranchDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateVendorBranchDtoBuilder result,
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
        case r'nameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nameAr = valueDes;
          break;
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.address = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.phone = valueDes;
          break;
        case r'location':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.location.replace(valueDes);
          break;
        case r'zoneId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        case r'isOpen':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isOpen = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateVendorBranchDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateVendorBranchDtoBuilder();
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

