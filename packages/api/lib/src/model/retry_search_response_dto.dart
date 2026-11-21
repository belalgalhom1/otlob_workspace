//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/order_response_dto.dart';
import 'package:api/src/model/order_search_status_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'retry_search_response_dto.g.dart';

/// RetrySearchResponseDto
///
/// Properties:
/// * [order] 
/// * [retried] 
/// * [alreadySearching] 
/// * [alreadyAssigned] 
/// * [searchStatus] 
@BuiltValue()
abstract class RetrySearchResponseDto implements Built<RetrySearchResponseDto, RetrySearchResponseDtoBuilder> {
  @BuiltValueField(wireName: r'order')
  OrderResponseDto get order;

  @BuiltValueField(wireName: r'retried')
  bool get retried;

  @BuiltValueField(wireName: r'alreadySearching')
  bool get alreadySearching;

  @BuiltValueField(wireName: r'alreadyAssigned')
  bool get alreadyAssigned;

  @BuiltValueField(wireName: r'searchStatus')
  OrderSearchStatusDto get searchStatus;

  RetrySearchResponseDto._();

  factory RetrySearchResponseDto([void updates(RetrySearchResponseDtoBuilder b)]) = _$RetrySearchResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RetrySearchResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RetrySearchResponseDto> get serializer => _$RetrySearchResponseDtoSerializer();
}

class _$RetrySearchResponseDtoSerializer implements PrimitiveSerializer<RetrySearchResponseDto> {
  @override
  final Iterable<Type> types = const [RetrySearchResponseDto, _$RetrySearchResponseDto];

  @override
  final String wireName = r'RetrySearchResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RetrySearchResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'order';
    yield serializers.serialize(
      object.order,
      specifiedType: const FullType(OrderResponseDto),
    );
    yield r'retried';
    yield serializers.serialize(
      object.retried,
      specifiedType: const FullType(bool),
    );
    yield r'alreadySearching';
    yield serializers.serialize(
      object.alreadySearching,
      specifiedType: const FullType(bool),
    );
    yield r'alreadyAssigned';
    yield serializers.serialize(
      object.alreadyAssigned,
      specifiedType: const FullType(bool),
    );
    yield r'searchStatus';
    yield serializers.serialize(
      object.searchStatus,
      specifiedType: const FullType(OrderSearchStatusDto),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RetrySearchResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RetrySearchResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'order':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderResponseDto),
          ) as OrderResponseDto;
          result.order.replace(valueDes);
          break;
        case r'retried':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.retried = valueDes;
          break;
        case r'alreadySearching':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.alreadySearching = valueDes;
          break;
        case r'alreadyAssigned':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.alreadyAssigned = valueDes;
          break;
        case r'searchStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderSearchStatusDto),
          ) as OrderSearchStatusDto;
          result.searchStatus.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RetrySearchResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RetrySearchResponseDtoBuilder();
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

