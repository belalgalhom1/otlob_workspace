//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/top_up_status.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'wallet_top_up_request.g.dart';

/// WalletTopUpRequest
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
@BuiltValue()
abstract class WalletTopUpRequest implements Built<WalletTopUpRequest, WalletTopUpRequestBuilder> {
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

  WalletTopUpRequest._();

  factory WalletTopUpRequest([void updates(WalletTopUpRequestBuilder b)]) = _$WalletTopUpRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WalletTopUpRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WalletTopUpRequest> get serializer => _$WalletTopUpRequestSerializer();
}

class _$WalletTopUpRequestSerializer implements PrimitiveSerializer<WalletTopUpRequest> {
  @override
  final Iterable<Type> types = const [WalletTopUpRequest, _$WalletTopUpRequest];

  @override
  final String wireName = r'WalletTopUpRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WalletTopUpRequest object, {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    WalletTopUpRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WalletTopUpRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WalletTopUpRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WalletTopUpRequestBuilder();
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

