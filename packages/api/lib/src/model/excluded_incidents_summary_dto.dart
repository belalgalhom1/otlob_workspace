//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'excluded_incidents_summary_dto.g.dart';

/// ExcludedIncidentsSummaryDto
///
/// Properties:
/// * [customer] 
/// * [vendor] 
/// * [externalOrSystem] 
/// * [underReview] 
@BuiltValue()
abstract class ExcludedIncidentsSummaryDto implements Built<ExcludedIncidentsSummaryDto, ExcludedIncidentsSummaryDtoBuilder> {
  @BuiltValueField(wireName: r'customer')
  num get customer;

  @BuiltValueField(wireName: r'vendor')
  num get vendor;

  @BuiltValueField(wireName: r'externalOrSystem')
  num get externalOrSystem;

  @BuiltValueField(wireName: r'underReview')
  num get underReview;

  ExcludedIncidentsSummaryDto._();

  factory ExcludedIncidentsSummaryDto([void updates(ExcludedIncidentsSummaryDtoBuilder b)]) = _$ExcludedIncidentsSummaryDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExcludedIncidentsSummaryDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExcludedIncidentsSummaryDto> get serializer => _$ExcludedIncidentsSummaryDtoSerializer();
}

class _$ExcludedIncidentsSummaryDtoSerializer implements PrimitiveSerializer<ExcludedIncidentsSummaryDto> {
  @override
  final Iterable<Type> types = const [ExcludedIncidentsSummaryDto, _$ExcludedIncidentsSummaryDto];

  @override
  final String wireName = r'ExcludedIncidentsSummaryDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExcludedIncidentsSummaryDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'customer';
    yield serializers.serialize(
      object.customer,
      specifiedType: const FullType(num),
    );
    yield r'vendor';
    yield serializers.serialize(
      object.vendor,
      specifiedType: const FullType(num),
    );
    yield r'externalOrSystem';
    yield serializers.serialize(
      object.externalOrSystem,
      specifiedType: const FullType(num),
    );
    yield r'underReview';
    yield serializers.serialize(
      object.underReview,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ExcludedIncidentsSummaryDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ExcludedIncidentsSummaryDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'customer':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.customer = valueDes;
          break;
        case r'vendor':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.vendor = valueDes;
          break;
        case r'externalOrSystem':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.externalOrSystem = valueDes;
          break;
        case r'underReview':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.underReview = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ExcludedIncidentsSummaryDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExcludedIncidentsSummaryDtoBuilder();
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

