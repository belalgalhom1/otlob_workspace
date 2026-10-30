//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'reject_vendor_fulfillment_dto.g.dart';

/// RejectVendorFulfillmentDto
///
/// Properties:
/// * [code] - Stable reason code for the rejection
/// * [reason] - Human-readable reason shown to the customer
/// * [reasonAr] - Arabic reason, shown to Arabic-speaking customers
@BuiltValue()
abstract class RejectVendorFulfillmentDto implements Built<RejectVendorFulfillmentDto, RejectVendorFulfillmentDtoBuilder> {
  /// Stable reason code for the rejection
  @BuiltValueField(wireName: r'code')
  RejectVendorFulfillmentDtoCodeEnum get code;
  // enum codeEnum {  OUT_OF_STOCK,  OUT_OF_DELIVERY_RANGE,  TOO_BUSY,  ITEM_UNAVAILABLE,  ADDRESS_UNREACHABLE,  ORDER_TOO_LARGE,  OTHER,  };

  /// Human-readable reason shown to the customer
  @BuiltValueField(wireName: r'reason')
  String get reason;

  /// Arabic reason, shown to Arabic-speaking customers
  @BuiltValueField(wireName: r'reasonAr')
  String? get reasonAr;

  RejectVendorFulfillmentDto._();

  factory RejectVendorFulfillmentDto([void updates(RejectVendorFulfillmentDtoBuilder b)]) = _$RejectVendorFulfillmentDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RejectVendorFulfillmentDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RejectVendorFulfillmentDto> get serializer => _$RejectVendorFulfillmentDtoSerializer();
}

class _$RejectVendorFulfillmentDtoSerializer implements PrimitiveSerializer<RejectVendorFulfillmentDto> {
  @override
  final Iterable<Type> types = const [RejectVendorFulfillmentDto, _$RejectVendorFulfillmentDto];

  @override
  final String wireName = r'RejectVendorFulfillmentDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RejectVendorFulfillmentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(RejectVendorFulfillmentDtoCodeEnum),
    );
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
    if (object.reasonAr != null) {
      yield r'reasonAr';
      yield serializers.serialize(
        object.reasonAr,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    RejectVendorFulfillmentDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RejectVendorFulfillmentDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RejectVendorFulfillmentDtoCodeEnum),
          ) as RejectVendorFulfillmentDtoCodeEnum;
          result.code = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        case r'reasonAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reasonAr = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RejectVendorFulfillmentDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RejectVendorFulfillmentDtoBuilder();
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

class RejectVendorFulfillmentDtoCodeEnum extends EnumClass {

  /// Stable reason code for the rejection
  @BuiltValueEnumConst(wireName: r'OUT_OF_STOCK')
  static const RejectVendorFulfillmentDtoCodeEnum OUT_OF_STOCK = _$rejectVendorFulfillmentDtoCodeEnum_OUT_OF_STOCK;
  /// Stable reason code for the rejection
  @BuiltValueEnumConst(wireName: r'OUT_OF_DELIVERY_RANGE')
  static const RejectVendorFulfillmentDtoCodeEnum OUT_OF_DELIVERY_RANGE = _$rejectVendorFulfillmentDtoCodeEnum_OUT_OF_DELIVERY_RANGE;
  /// Stable reason code for the rejection
  @BuiltValueEnumConst(wireName: r'TOO_BUSY')
  static const RejectVendorFulfillmentDtoCodeEnum TOO_BUSY = _$rejectVendorFulfillmentDtoCodeEnum_TOO_BUSY;
  /// Stable reason code for the rejection
  @BuiltValueEnumConst(wireName: r'ITEM_UNAVAILABLE')
  static const RejectVendorFulfillmentDtoCodeEnum ITEM_UNAVAILABLE = _$rejectVendorFulfillmentDtoCodeEnum_ITEM_UNAVAILABLE;
  /// Stable reason code for the rejection
  @BuiltValueEnumConst(wireName: r'ADDRESS_UNREACHABLE')
  static const RejectVendorFulfillmentDtoCodeEnum ADDRESS_UNREACHABLE = _$rejectVendorFulfillmentDtoCodeEnum_ADDRESS_UNREACHABLE;
  /// Stable reason code for the rejection
  @BuiltValueEnumConst(wireName: r'ORDER_TOO_LARGE')
  static const RejectVendorFulfillmentDtoCodeEnum ORDER_TOO_LARGE = _$rejectVendorFulfillmentDtoCodeEnum_ORDER_TOO_LARGE;
  /// Stable reason code for the rejection
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const RejectVendorFulfillmentDtoCodeEnum OTHER = _$rejectVendorFulfillmentDtoCodeEnum_OTHER;

  static Serializer<RejectVendorFulfillmentDtoCodeEnum> get serializer => _$rejectVendorFulfillmentDtoCodeEnumSerializer;

  const RejectVendorFulfillmentDtoCodeEnum._(String name): super(name);

  static BuiltSet<RejectVendorFulfillmentDtoCodeEnum> get values => _$rejectVendorFulfillmentDtoCodeEnumValues;
  static RejectVendorFulfillmentDtoCodeEnum valueOf(String name) => _$rejectVendorFulfillmentDtoCodeEnumValueOf(name);
}

