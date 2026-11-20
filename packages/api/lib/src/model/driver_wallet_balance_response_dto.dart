//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_wallet_balance_response_dto.g.dart';

/// DriverWalletBalanceResponseDto
///
/// Properties:
/// * [walletBalance] 
@BuiltValue()
abstract class DriverWalletBalanceResponseDto implements Built<DriverWalletBalanceResponseDto, DriverWalletBalanceResponseDtoBuilder> {
  @BuiltValueField(wireName: r'walletBalance')
  num get walletBalance;

  DriverWalletBalanceResponseDto._();

  factory DriverWalletBalanceResponseDto([void updates(DriverWalletBalanceResponseDtoBuilder b)]) = _$DriverWalletBalanceResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverWalletBalanceResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverWalletBalanceResponseDto> get serializer => _$DriverWalletBalanceResponseDtoSerializer();
}

class _$DriverWalletBalanceResponseDtoSerializer implements PrimitiveSerializer<DriverWalletBalanceResponseDto> {
  @override
  final Iterable<Type> types = const [DriverWalletBalanceResponseDto, _$DriverWalletBalanceResponseDto];

  @override
  final String wireName = r'DriverWalletBalanceResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverWalletBalanceResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'walletBalance';
    yield serializers.serialize(
      object.walletBalance,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverWalletBalanceResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverWalletBalanceResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'walletBalance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.walletBalance = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverWalletBalanceResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverWalletBalanceResponseDtoBuilder();
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

