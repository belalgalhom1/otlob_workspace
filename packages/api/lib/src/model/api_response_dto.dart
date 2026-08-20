//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'api_response_dto.g.dart';

/// ApiResponseDto
///
/// Properties:
/// * [success] - Indicates if the operation was successful
/// * [statusCode] - HTTP status code
/// * [message] - Response message or translation key
/// * [data] - The response payload
/// * [errors] - Validation errors dictionary
/// * [timestamp] - ISO Timestamp of the response
@BuiltValue(instantiable: false)
abstract class ApiResponseDto  {
  /// Indicates if the operation was successful
  @BuiltValueField(wireName: r'success')
  bool get success;

  /// HTTP status code
  @BuiltValueField(wireName: r'statusCode')
  num get statusCode;

  /// Response message or translation key
  @BuiltValueField(wireName: r'message')
  String get message;

  /// The response payload
  @BuiltValueField(wireName: r'data')
  JsonObject? get data;

  /// Validation errors dictionary
  @BuiltValueField(wireName: r'errors')
  BuiltMap<String, BuiltList<String>>? get errors;

  /// ISO Timestamp of the response
  @BuiltValueField(wireName: r'timestamp')
  String get timestamp;

  @BuiltValueSerializer(custom: true)
  static Serializer<ApiResponseDto> get serializer => _$ApiResponseDtoSerializer();
}

class _$ApiResponseDtoSerializer implements PrimitiveSerializer<ApiResponseDto> {
  @override
  final Iterable<Type> types = const [ApiResponseDto];

  @override
  final String wireName = r'ApiResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ApiResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'success';
    yield serializers.serialize(
      object.success,
      specifiedType: const FullType(bool),
    );
    yield r'statusCode';
    yield serializers.serialize(
      object.statusCode,
      specifiedType: const FullType(num),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'data';
    yield object.data == null ? null : serializers.serialize(
      object.data,
      specifiedType: const FullType.nullable(JsonObject),
    );
    yield r'errors';
    yield object.errors == null ? null : serializers.serialize(
      object.errors,
      specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType(BuiltList, [FullType(String)])]),
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
    ApiResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  @override
  ApiResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.deserialize(serialized, specifiedType: FullType($ApiResponseDto)) as $ApiResponseDto;
  }
}

/// a concrete implementation of [ApiResponseDto], since [ApiResponseDto] is not instantiable
@BuiltValue(instantiable: true)
abstract class $ApiResponseDto implements ApiResponseDto, Built<$ApiResponseDto, $ApiResponseDtoBuilder> {
  $ApiResponseDto._();

  factory $ApiResponseDto([void Function($ApiResponseDtoBuilder)? updates]) = _$$ApiResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults($ApiResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<$ApiResponseDto> get serializer => _$$ApiResponseDtoSerializer();
}

class _$$ApiResponseDtoSerializer implements PrimitiveSerializer<$ApiResponseDto> {
  @override
  final Iterable<Type> types = const [$ApiResponseDto, _$$ApiResponseDto];

  @override
  final String wireName = r'$ApiResponseDto';

  @override
  Object serialize(
    Serializers serializers,
    $ApiResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return serializers.serialize(object, specifiedType: FullType(ApiResponseDto))!;
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ApiResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'success':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.success = valueDes;
          break;
        case r'statusCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.statusCode = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JsonObject),
          ) as JsonObject?;
          if (valueDes == null) continue;
          result.data = valueDes;
          break;
        case r'errors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType(BuiltList, [FullType(String)])]),
          ) as BuiltMap<String, BuiltList<String>>?;
          if (valueDes == null) continue;
          result.errors.replace(valueDes);
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
  $ApiResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = $ApiResponseDtoBuilder();
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

