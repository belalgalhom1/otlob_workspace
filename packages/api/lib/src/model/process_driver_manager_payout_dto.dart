//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'process_driver_manager_payout_dto.g.dart';

/// ProcessDriverManagerPayoutDto
///
/// Properties:
/// * [amount] - Amount in EGP to deduct and transfer to the driver manager. Omit when settleFullBalance is true to zero out the full positive balance.
/// * [settleFullBalance] - When true, transfers the full current positive walletBalance and resets it to 0.
/// * [receiptUrl] - Uploaded transfer screenshot URL
/// * [description] - Optional payout description or transfer reference note
/// * [idempotencyKey] - Optional idempotency key to prevent duplicate payouts
@BuiltValue()
abstract class ProcessDriverManagerPayoutDto implements Built<ProcessDriverManagerPayoutDto, ProcessDriverManagerPayoutDtoBuilder> {
  /// Amount in EGP to deduct and transfer to the driver manager. Omit when settleFullBalance is true to zero out the full positive balance.
  @BuiltValueField(wireName: r'amount')
  num? get amount;

  /// When true, transfers the full current positive walletBalance and resets it to 0.
  @BuiltValueField(wireName: r'settleFullBalance')
  bool? get settleFullBalance;

  /// Uploaded transfer screenshot URL
  @BuiltValueField(wireName: r'receiptUrl')
  String? get receiptUrl;

  /// Optional payout description or transfer reference note
  @BuiltValueField(wireName: r'description')
  String? get description;

  /// Optional idempotency key to prevent duplicate payouts
  @BuiltValueField(wireName: r'idempotencyKey')
  String? get idempotencyKey;

  ProcessDriverManagerPayoutDto._();

  factory ProcessDriverManagerPayoutDto([void updates(ProcessDriverManagerPayoutDtoBuilder b)]) = _$ProcessDriverManagerPayoutDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProcessDriverManagerPayoutDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProcessDriverManagerPayoutDto> get serializer => _$ProcessDriverManagerPayoutDtoSerializer();
}

class _$ProcessDriverManagerPayoutDtoSerializer implements PrimitiveSerializer<ProcessDriverManagerPayoutDto> {
  @override
  final Iterable<Type> types = const [ProcessDriverManagerPayoutDto, _$ProcessDriverManagerPayoutDto];

  @override
  final String wireName = r'ProcessDriverManagerPayoutDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProcessDriverManagerPayoutDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.amount != null) {
      yield r'amount';
      yield serializers.serialize(
        object.amount,
        specifiedType: const FullType(num),
      );
    }
    if (object.settleFullBalance != null) {
      yield r'settleFullBalance';
      yield serializers.serialize(
        object.settleFullBalance,
        specifiedType: const FullType(bool),
      );
    }
    if (object.receiptUrl != null) {
      yield r'receiptUrl';
      yield serializers.serialize(
        object.receiptUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.idempotencyKey != null) {
      yield r'idempotencyKey';
      yield serializers.serialize(
        object.idempotencyKey,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProcessDriverManagerPayoutDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProcessDriverManagerPayoutDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.amount = valueDes;
          break;
        case r'settleFullBalance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.settleFullBalance = valueDes;
          break;
        case r'receiptUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.receiptUrl = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'idempotencyKey':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.idempotencyKey = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProcessDriverManagerPayoutDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProcessDriverManagerPayoutDtoBuilder();
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

