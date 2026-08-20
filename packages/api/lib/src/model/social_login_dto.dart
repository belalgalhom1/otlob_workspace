//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'social_login_dto.g.dart';

/// SocialLoginDto
///
/// Properties:
/// * [provider] 
/// * [providerAccountId] 
/// * [idToken] 
/// * [email] 
/// * [name] 
/// * [app] 
@BuiltValue()
abstract class SocialLoginDto implements Built<SocialLoginDto, SocialLoginDtoBuilder> {
  @BuiltValueField(wireName: r'provider')
  String get provider;

  @BuiltValueField(wireName: r'providerAccountId')
  String? get providerAccountId;

  @BuiltValueField(wireName: r'idToken')
  String get idToken;

  @BuiltValueField(wireName: r'email')
  String? get email;

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'app')
  String? get app;

  SocialLoginDto._();

  factory SocialLoginDto([void updates(SocialLoginDtoBuilder b)]) = _$SocialLoginDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SocialLoginDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SocialLoginDto> get serializer => _$SocialLoginDtoSerializer();
}

class _$SocialLoginDtoSerializer implements PrimitiveSerializer<SocialLoginDto> {
  @override
  final Iterable<Type> types = const [SocialLoginDto, _$SocialLoginDto];

  @override
  final String wireName = r'SocialLoginDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SocialLoginDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'provider';
    yield serializers.serialize(
      object.provider,
      specifiedType: const FullType(String),
    );
    if (object.providerAccountId != null) {
      yield r'providerAccountId';
      yield serializers.serialize(
        object.providerAccountId,
        specifiedType: const FullType(String),
      );
    }
    yield r'idToken';
    yield serializers.serialize(
      object.idToken,
      specifiedType: const FullType(String),
    );
    if (object.email != null) {
      yield r'email';
      yield serializers.serialize(
        object.email,
        specifiedType: const FullType(String),
      );
    }
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType(String),
      );
    }
    if (object.app != null) {
      yield r'app';
      yield serializers.serialize(
        object.app,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SocialLoginDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SocialLoginDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'provider':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.provider = valueDes;
          break;
        case r'providerAccountId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.providerAccountId = valueDes;
          break;
        case r'idToken':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.idToken = valueDes;
          break;
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'app':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.app = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SocialLoginDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SocialLoginDtoBuilder();
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

