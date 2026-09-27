//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/api_response_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/wallet_top_up_request_response_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'wallet_controller_get_pending_top_ups200_response.g.dart';

/// WalletControllerGetPendingTopUps200Response
///
/// Properties:
/// * [success] - Indicates if the operation was successful
/// * [statusCode] - HTTP status code
/// * [message] - Response message or translation key
/// * [data] 
/// * [errors] - Validation errors dictionary
/// * [timestamp] - ISO Timestamp of the response
@BuiltValue()
abstract class WalletControllerGetPendingTopUps200Response implements ApiResponseDto, Built<WalletControllerGetPendingTopUps200Response, WalletControllerGetPendingTopUps200ResponseBuilder> {
  WalletControllerGetPendingTopUps200Response._();

  factory WalletControllerGetPendingTopUps200Response([void updates(WalletControllerGetPendingTopUps200ResponseBuilder b)]) = _$WalletControllerGetPendingTopUps200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WalletControllerGetPendingTopUps200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WalletControllerGetPendingTopUps200Response> get serializer => _$WalletControllerGetPendingTopUps200ResponseSerializer();
}

class _$WalletControllerGetPendingTopUps200ResponseSerializer implements PrimitiveSerializer<WalletControllerGetPendingTopUps200Response> {
  @override
  final Iterable<Type> types = const [WalletControllerGetPendingTopUps200Response, _$WalletControllerGetPendingTopUps200Response];

  @override
  final String wireName = r'WalletControllerGetPendingTopUps200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WalletControllerGetPendingTopUps200Response object, {
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
    WalletControllerGetPendingTopUps200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WalletControllerGetPendingTopUps200ResponseBuilder result,
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
  WalletControllerGetPendingTopUps200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WalletControllerGetPendingTopUps200ResponseBuilder();
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

