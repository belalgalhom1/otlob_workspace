//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_ranking_evaluation_run_dto.dart';
import 'package:api/src/model/api_response_dto.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'driver_ranking_controller_run_evaluation_now200_response.g.dart';

/// DriverRankingControllerRunEvaluationNow200Response
///
/// Properties:
/// * [success] - Indicates if the operation was successful
/// * [statusCode] - HTTP status code
/// * [message] - Response message or translation key
/// * [data] 
/// * [errors] - Validation errors dictionary
/// * [timestamp] - ISO Timestamp of the response
@BuiltValue()
abstract class DriverRankingControllerRunEvaluationNow200Response implements ApiResponseDto, Built<DriverRankingControllerRunEvaluationNow200Response, DriverRankingControllerRunEvaluationNow200ResponseBuilder> {
  DriverRankingControllerRunEvaluationNow200Response._();

  factory DriverRankingControllerRunEvaluationNow200Response([void updates(DriverRankingControllerRunEvaluationNow200ResponseBuilder b)]) = _$DriverRankingControllerRunEvaluationNow200Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverRankingControllerRunEvaluationNow200ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverRankingControllerRunEvaluationNow200Response> get serializer => _$DriverRankingControllerRunEvaluationNow200ResponseSerializer();
}

class _$DriverRankingControllerRunEvaluationNow200ResponseSerializer implements PrimitiveSerializer<DriverRankingControllerRunEvaluationNow200Response> {
  @override
  final Iterable<Type> types = const [DriverRankingControllerRunEvaluationNow200Response, _$DriverRankingControllerRunEvaluationNow200Response];

  @override
  final String wireName = r'DriverRankingControllerRunEvaluationNow200Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverRankingControllerRunEvaluationNow200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'data';
    yield object.data == null ? null : serializers.serialize(
      object.data,
      specifiedType: const FullType.nullable(JsonObject),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'success';
    yield serializers.serialize(
      object.success,
      specifiedType: const FullType(bool),
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
    DriverRankingControllerRunEvaluationNow200Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverRankingControllerRunEvaluationNow200ResponseBuilder result,
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
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'success':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.success = valueDes;
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
  DriverRankingControllerRunEvaluationNow200Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverRankingControllerRunEvaluationNow200ResponseBuilder();
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

