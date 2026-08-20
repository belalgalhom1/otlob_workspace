//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'create_wallet_top_up_dto.g.dart';

/// CreateWalletTopUpDto
///
/// Properties:
/// * [platformWalletId] 
/// * [amount] 
/// * [receiptUrl] 
@BuiltValue()
abstract class CreateWalletTopUpDto implements Built<CreateWalletTopUpDto, CreateWalletTopUpDtoBuilder> {
  @BuiltValueField(wireName: r'platformWalletId')
  String get platformWalletId;

  @BuiltValueField(wireName: r'amount')
  num get amount;

  @BuiltValueField(wireName: r'receiptUrl')
  String get receiptUrl;

  CreateWalletTopUpDto._();

  factory CreateWalletTopUpDto([void updates(CreateWalletTopUpDtoBuilder b)]) = _$CreateWalletTopUpDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CreateWalletTopUpDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CreateWalletTopUpDto> get serializer => _$CreateWalletTopUpDtoSerializer();
}

class _$CreateWalletTopUpDtoSerializer implements PrimitiveSerializer<CreateWalletTopUpDto> {
  @override
  final Iterable<Type> types = const [CreateWalletTopUpDto, _$CreateWalletTopUpDto];

  @override
  final String wireName = r'CreateWalletTopUpDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CreateWalletTopUpDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'platformWalletId';
    yield serializers.serialize(
      object.platformWalletId,
      specifiedType: const FullType(String),
    );
    yield r'amount';
    yield serializers.serialize(
      object.amount,
      specifiedType: const FullType(num),
    );
    yield r'receiptUrl';
    yield serializers.serialize(
      object.receiptUrl,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CreateWalletTopUpDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CreateWalletTopUpDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'platformWalletId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.platformWalletId = valueDes;
          break;
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.amount = valueDes;
          break;
        case r'receiptUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.receiptUrl = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CreateWalletTopUpDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CreateWalletTopUpDtoBuilder();
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

