//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/api_response_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/json_object.dart';

part 'notifications_controller_list200_response.g.dart';

/// NotificationsControllerList200Response
///
/// Properties:
/// * [success] - Indicates if the operation was successful
/// * [statusCode] - HTTP status code
/// * [message] - Response message or translation key
/// * [data] 
/// * [errors] - Validation errors dictionary
/// * [timestamp] - ISO Timestamp of the response
@BuiltValue()
abstract class NotificationsControllerList200Response implements ApiResponseDto, Built<NotificationsControllerList200Response, NotificationsControllerList200ResponseBuilder> {
  NotificationsControllerList200Response._();

  factory NotificationsControllerList200Response([void updates(NotificationsControllerList200ResponseBuilder b)]) = _$NotificationsControllerList200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(NotificationsControllerList200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<NotificationsControllerList200Response> get serializer => _$NotificationsControllerList200ResponseSerializer();
}

class _$NotificationsControllerList200ResponseSerializer implements PrimitiveSerializer<NotificationsControllerList200Response> {
  @override
  final Iterable<Type> types = const [NotificationsControllerList200Response, _$NotificationsControllerList200Response];

  @override
  final String wireName = r'NotificationsControllerList200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    NotificationsControllerList200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'data';
    yield object.data == null ? null : serializers.serialize(
      object.data,
      specifiedType: const FullType.nullable(JsonObject),
    );
    yield r'success';
    yield serializers.serialize(
      object.success,
      specifiedType: const FullType(bool),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'errors';
    yield object.errors == null ? null : serializers.serialize(
      object.errors,
      specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType(BuiltList, [FullType(String)])]),
    );
    yield r'statusCode';
    yield serializers.serialize(
      object.statusCode,
      specifiedType: const FullType(num),
    );
    yield r'timestamp';
    yield serializers.serialize(
      object.timestamp,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    NotificationsControllerList200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required NotificationsControllerList200ResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.data = valueDes;
          break;
        case r'success':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.success = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'errors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType(BuiltList, [FullType(String)])]),
          ) as BuiltMap<String, BuiltList<String>>?;
          if (valueDes == null) continue;
          result.errors.replace(valueDes);
          break;
        case r'statusCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.statusCode = valueDes;
          break;
        case r'timestamp':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.timestamp = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  NotificationsControllerList200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = NotificationsControllerList200ResponseBuilder();
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

