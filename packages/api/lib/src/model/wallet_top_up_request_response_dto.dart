//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/top_up_status.dart';
import 'package:api/src/model/driver.dart';
import 'package:api/src/model/mobile_wallet.dart';
import 'package:api/src/model/user.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'wallet_top_up_request_response_dto.g.dart';

/// WalletTopUpRequestResponseDto
///
/// Properties:
/// * [id] 
/// * [driverId] 
/// * [platformWalletId] 
/// * [amount] 
/// * [receiptUrl] 
/// * [status] 
/// * [approvedById] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [driver] 
/// * [platformWallet] 
/// * [approvedBy] 
@BuiltValue()
abstract class WalletTopUpRequestResponseDto implements Built<WalletTopUpRequestResponseDto, WalletTopUpRequestResponseDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'platformWalletId')
  String get platformWalletId;

  @BuiltValueField(wireName: r'amount')
  num get amount;

  @BuiltValueField(wireName: r'receiptUrl')
  String get receiptUrl;

  @BuiltValueField(wireName: r'status')
  TopUpStatus get status;
  // enum statusEnum {  PENDING,  APPROVED,  REJECTED,  };

  @BuiltValueField(wireName: r'approvedById')
  String? get approvedById;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'driver')
  Driver? get driver;

  @BuiltValueField(wireName: r'platformWallet')
  MobileWallet? get platformWallet;

  @BuiltValueField(wireName: r'approvedBy')
  User? get approvedBy;

  WalletTopUpRequestResponseDto._();

  factory WalletTopUpRequestResponseDto([void updates(WalletTopUpRequestResponseDtoBuilder b)]) = _$WalletTopUpRequestResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WalletTopUpRequestResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WalletTopUpRequestResponseDto> get serializer => _$WalletTopUpRequestResponseDtoSerializer();
}

class _$WalletTopUpRequestResponseDtoSerializer implements PrimitiveSerializer<WalletTopUpRequestResponseDto> {
  @override
  final Iterable<Type> types = const [WalletTopUpRequestResponseDto, _$WalletTopUpRequestResponseDto];

  @override
  final String wireName = r'WalletTopUpRequestResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WalletTopUpRequestResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'driverId';
    yield serializers.serialize(
      object.driverId,
      specifiedType: const FullType(String),
    );
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
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(TopUpStatus),
    );
    if (object.approvedById != null) {
      yield r'approvedById';
      yield serializers.serialize(
        object.approvedById,
        specifiedType: const FullType(String),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.driver != null) {
      yield r'driver';
      yield serializers.serialize(
        object.driver,
        specifiedType: const FullType(Driver),
      );
    }
    if (object.platformWallet != null) {
      yield r'platformWallet';
      yield serializers.serialize(
        object.platformWallet,
        specifiedType: const FullType(MobileWallet),
      );
    }
    if (object.approvedBy != null) {
      yield r'approvedBy';
      yield serializers.serialize(
        object.approvedBy,
        specifiedType: const FullType(User),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    WalletTopUpRequestResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WalletTopUpRequestResponseDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
          break;
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
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TopUpStatus),
          ) as TopUpStatus;
          result.status = valueDes;
          break;
        case r'approvedById':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.approvedById = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'driver':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Driver),
          ) as Driver;
          result.driver.replace(valueDes);
          break;
        case r'platformWallet':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MobileWallet),
          ) as MobileWallet;
          result.platformWallet.replace(valueDes);
          break;
        case r'approvedBy':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(User),
          ) as User;
          result.approvedBy.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WalletTopUpRequestResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WalletTopUpRequestResponseDtoBuilder();
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

