//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/device_platform.dart';
import 'package:api/src/model/user.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'device.g.dart';

/// Device
///
/// Properties:
/// * [id] 
/// * [token] 
/// * [platform] 
/// * [userId] 
/// * [lastActive] 
/// * [user] 
@BuiltValue()
abstract class Device implements Built<Device, DeviceBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'token')
  String get token;

  @BuiltValueField(wireName: r'platform')
  JsonObject? get platform;
  // enum platformEnum {  ANDROID,  IOS,  WEB,  };

  @BuiltValueField(wireName: r'userId')
  String get userId;

  @BuiltValueField(wireName: r'lastActive')
  DateTime get lastActive;

  @BuiltValueField(wireName: r'user')
  JsonObject? get user;

  Device._();

  factory Device([void updates(DeviceBuilder b)]) = _$Device;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DeviceBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Device> get serializer => _$DeviceSerializer();
}

class _$DeviceSerializer implements PrimitiveSerializer<Device> {
  @override
  final Iterable<Type> types = const [Device, _$Device];

  @override
  final String wireName = r'Device';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Device object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'token';
    yield serializers.serialize(
      object.token,
      specifiedType: const FullType(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(DevicePlatform),
    );
    yield r'userId';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(String),
    );
    yield r'lastActive';
    yield serializers.serialize(
      object.lastActive,
      specifiedType: const FullType(DateTime),
    );
    yield r'user';
    yield serializers.serialize(
      object.user,
      specifiedType: const FullType(User),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Device object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DeviceBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.token = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.platform = valueDes;
          break;
        case r'userId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.userId = valueDes;
          break;
        case r'lastActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.lastActive = valueDes;
          break;
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          result.user = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Device deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DeviceBuilder();
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

