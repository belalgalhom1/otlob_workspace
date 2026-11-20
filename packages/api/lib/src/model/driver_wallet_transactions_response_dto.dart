//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_wallet_transaction_response_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_wallet_transactions_response_dto.g.dart';

/// DriverWalletTransactionsResponseDto
///
/// Properties:
/// * [walletBalance] 
/// * [transactions] 
/// * [total] 
/// * [page] 
/// * [limit] 
/// * [totalPages] 
@BuiltValue()
abstract class DriverWalletTransactionsResponseDto implements Built<DriverWalletTransactionsResponseDto, DriverWalletTransactionsResponseDtoBuilder> {
  @BuiltValueField(wireName: r'walletBalance')
  num get walletBalance;

  @BuiltValueField(wireName: r'transactions')
  BuiltList<DriverWalletTransactionResponseDto> get transactions;

  @BuiltValueField(wireName: r'total')
  num get total;

  @BuiltValueField(wireName: r'page')
  num get page;

  @BuiltValueField(wireName: r'limit')
  num get limit;

  @BuiltValueField(wireName: r'totalPages')
  num get totalPages;

  DriverWalletTransactionsResponseDto._();

  factory DriverWalletTransactionsResponseDto([void updates(DriverWalletTransactionsResponseDtoBuilder b)]) = _$DriverWalletTransactionsResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverWalletTransactionsResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverWalletTransactionsResponseDto> get serializer => _$DriverWalletTransactionsResponseDtoSerializer();
}

class _$DriverWalletTransactionsResponseDtoSerializer implements PrimitiveSerializer<DriverWalletTransactionsResponseDto> {
  @override
  final Iterable<Type> types = const [DriverWalletTransactionsResponseDto, _$DriverWalletTransactionsResponseDto];

  @override
  final String wireName = r'DriverWalletTransactionsResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverWalletTransactionsResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'walletBalance';
    yield serializers.serialize(
      object.walletBalance,
      specifiedType: const FullType(num),
    );
    yield r'transactions';
    yield serializers.serialize(
      object.transactions,
      specifiedType: const FullType(BuiltList, [FullType(DriverWalletTransactionResponseDto)]),
    );
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(num),
    );
    yield r'page';
    yield serializers.serialize(
      object.page,
      specifiedType: const FullType(num),
    );
    yield r'limit';
    yield serializers.serialize(
      object.limit,
      specifiedType: const FullType(num),
    );
    yield r'totalPages';
    yield serializers.serialize(
      object.totalPages,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverWalletTransactionsResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverWalletTransactionsResponseDtoBuilder result,
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
        case r'transactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverWalletTransactionResponseDto)]),
          ) as BuiltList<DriverWalletTransactionResponseDto>;
          result.transactions.replace(valueDes);
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.total = valueDes;
          break;
        case r'page':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.page = valueDes;
          break;
        case r'limit':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.limit = valueDes;
          break;
        case r'totalPages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalPages = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverWalletTransactionsResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverWalletTransactionsResponseDtoBuilder();
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

