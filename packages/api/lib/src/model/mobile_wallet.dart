//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/wallet_type.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mobile_wallet.g.dart';

/// MobileWallet
///
/// Properties:
/// * [id] 
/// * [number] 
/// * [type] 
/// * [isActive] 
/// * [isPlatform] 
/// * [driverId] 
/// * [createdAt] 
/// * [updatedAt] 
@BuiltValue()
abstract class MobileWallet implements Built<MobileWallet, MobileWalletBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'number')
  String get number;

  @BuiltValueField(wireName: r'type')
  WalletType get type;
  // enum typeEnum {  VODAFONE,  ORANGE,  WE,  ETISALAT,  INSTAPAY,  };

  @BuiltValueField(wireName: r'isActive')
  bool get isActive;

  @BuiltValueField(wireName: r'isPlatform')
  bool get isPlatform;

  @BuiltValueField(wireName: r'driverId')
  String? get driverId;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  MobileWallet._();

  factory MobileWallet([void updates(MobileWalletBuilder b)]) = _$MobileWallet;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MobileWalletBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MobileWallet> get serializer => _$MobileWalletSerializer();
}

class _$MobileWalletSerializer implements PrimitiveSerializer<MobileWallet> {
  @override
  final Iterable<Type> types = const [MobileWallet, _$MobileWallet];

  @override
  final String wireName = r'MobileWallet';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MobileWallet object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'number';
    yield serializers.serialize(
      object.number,
      specifiedType: const FullType(String),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(WalletType),
    );
    yield r'isActive';
    yield serializers.serialize(
      object.isActive,
      specifiedType: const FullType(bool),
    );
    yield r'isPlatform';
    yield serializers.serialize(
      object.isPlatform,
      specifiedType: const FullType(bool),
    );
    if (object.driverId != null) {
      yield r'driverId';
      yield serializers.serialize(
        object.driverId,
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
    MobileWallet object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MobileWalletBuilder result,
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
        case r'number':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.number = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(WalletType),
          ) as WalletType;
          result.type = valueDes;
          break;
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'isPlatform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isPlatform = valueDes;
          break;
        case r'driverId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.driverId = valueDes;
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
  MobileWallet deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MobileWalletBuilder();
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

