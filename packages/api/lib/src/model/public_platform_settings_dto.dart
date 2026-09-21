//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'public_platform_settings_dto.g.dart';

/// PublicPlatformSettingsDto
///
/// Properties:
/// * [isMaintenanceMode] 
/// * [currency] 
/// * [minOrderAmount] 
/// * [defaultTaxRate] 
/// * [baseDeliveryFee] 
/// * [customOrderPlatformFee] 
/// * [pricePerKm] 
/// * [pricePerKmBicycle] 
/// * [pricePerKmMotorcycle] 
/// * [pricePerKmCar] 
/// * [pricePerKmVan] 
/// * [pricePerKmTruck] 
/// * [pricePerKmMotorTricycle] 
/// * [allowBicycle] 
/// * [allowMotorcycle] 
/// * [allowCar] 
/// * [allowVan] 
/// * [allowTruck] 
/// * [allowMotorTricycle] 
/// * [coinValue] 
/// * [amountSpentPerCoin] 
/// * [minCoinsToUse] 
/// * [homeCoverUrl] 
/// * [motorcycleIconUrl] 
/// * [carIconUrl] 
/// * [deliveryBannerIconUrl] 
/// * [android] 
/// * [ios] 
/// * [support] 
/// * [legal] 
@BuiltValue()
abstract class PublicPlatformSettingsDto implements Built<PublicPlatformSettingsDto, PublicPlatformSettingsDtoBuilder> {
  @BuiltValueField(wireName: r'isMaintenanceMode')
  bool get isMaintenanceMode;

  @BuiltValueField(wireName: r'currency')
  String get currency;

  @BuiltValueField(wireName: r'minOrderAmount')
  num get minOrderAmount;

  @BuiltValueField(wireName: r'defaultTaxRate')
  num get defaultTaxRate;

  @BuiltValueField(wireName: r'baseDeliveryFee')
  num get baseDeliveryFee;

  @BuiltValueField(wireName: r'customOrderPlatformFee')
  num get customOrderPlatformFee;

  @BuiltValueField(wireName: r'pricePerKm')
  num get pricePerKm;

  @BuiltValueField(wireName: r'pricePerKmBicycle')
  num get pricePerKmBicycle;

  @BuiltValueField(wireName: r'pricePerKmMotorcycle')
  num get pricePerKmMotorcycle;

  @BuiltValueField(wireName: r'pricePerKmCar')
  num get pricePerKmCar;

  @BuiltValueField(wireName: r'pricePerKmVan')
  num get pricePerKmVan;

  @BuiltValueField(wireName: r'pricePerKmTruck')
  num get pricePerKmTruck;

  @BuiltValueField(wireName: r'pricePerKmMotorTricycle')
  num get pricePerKmMotorTricycle;

  @BuiltValueField(wireName: r'allowBicycle')
  bool get allowBicycle;

  @BuiltValueField(wireName: r'allowMotorcycle')
  bool get allowMotorcycle;

  @BuiltValueField(wireName: r'allowCar')
  bool get allowCar;

  @BuiltValueField(wireName: r'allowVan')
  bool get allowVan;

  @BuiltValueField(wireName: r'allowTruck')
  bool get allowTruck;

  @BuiltValueField(wireName: r'allowMotorTricycle')
  bool get allowMotorTricycle;

  @BuiltValueField(wireName: r'coinValue')
  num get coinValue;

  @BuiltValueField(wireName: r'amountSpentPerCoin')
  num get amountSpentPerCoin;

  @BuiltValueField(wireName: r'minCoinsToUse')
  num get minCoinsToUse;

  @BuiltValueField(wireName: r'homeCoverUrl')
  String? get homeCoverUrl;

  @BuiltValueField(wireName: r'motorcycleIconUrl')
  String? get motorcycleIconUrl;

  @BuiltValueField(wireName: r'carIconUrl')
  String? get carIconUrl;

  @BuiltValueField(wireName: r'deliveryBannerIconUrl')
  String? get deliveryBannerIconUrl;

  @BuiltValueField(wireName: r'android')
  JsonObject get android;

  @BuiltValueField(wireName: r'ios')
  JsonObject get ios;

  @BuiltValueField(wireName: r'support')
  JsonObject get support;

  @BuiltValueField(wireName: r'legal')
  JsonObject get legal;

  PublicPlatformSettingsDto._();

  factory PublicPlatformSettingsDto([void updates(PublicPlatformSettingsDtoBuilder b)]) = _$PublicPlatformSettingsDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PublicPlatformSettingsDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PublicPlatformSettingsDto> get serializer => _$PublicPlatformSettingsDtoSerializer();
}

class _$PublicPlatformSettingsDtoSerializer implements PrimitiveSerializer<PublicPlatformSettingsDto> {
  @override
  final Iterable<Type> types = const [PublicPlatformSettingsDto, _$PublicPlatformSettingsDto];

  @override
  final String wireName = r'PublicPlatformSettingsDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PublicPlatformSettingsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'isMaintenanceMode';
    yield serializers.serialize(
      object.isMaintenanceMode,
      specifiedType: const FullType(bool),
    );
    yield r'currency';
    yield serializers.serialize(
      object.currency,
      specifiedType: const FullType(String),
    );
    yield r'minOrderAmount';
    yield serializers.serialize(
      object.minOrderAmount,
      specifiedType: const FullType(num),
    );
    yield r'defaultTaxRate';
    yield serializers.serialize(
      object.defaultTaxRate,
      specifiedType: const FullType(num),
    );
    yield r'baseDeliveryFee';
    yield serializers.serialize(
      object.baseDeliveryFee,
      specifiedType: const FullType(num),
    );
    yield r'customOrderPlatformFee';
    yield serializers.serialize(
      object.customOrderPlatformFee,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKm';
    yield serializers.serialize(
      object.pricePerKm,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmBicycle';
    yield serializers.serialize(
      object.pricePerKmBicycle,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmMotorcycle';
    yield serializers.serialize(
      object.pricePerKmMotorcycle,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmCar';
    yield serializers.serialize(
      object.pricePerKmCar,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmVan';
    yield serializers.serialize(
      object.pricePerKmVan,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmTruck';
    yield serializers.serialize(
      object.pricePerKmTruck,
      specifiedType: const FullType(num),
    );
    yield r'pricePerKmMotorTricycle';
    yield serializers.serialize(
      object.pricePerKmMotorTricycle,
      specifiedType: const FullType(num),
    );
    yield r'allowBicycle';
    yield serializers.serialize(
      object.allowBicycle,
      specifiedType: const FullType(bool),
    );
    yield r'allowMotorcycle';
    yield serializers.serialize(
      object.allowMotorcycle,
      specifiedType: const FullType(bool),
    );
    yield r'allowCar';
    yield serializers.serialize(
      object.allowCar,
      specifiedType: const FullType(bool),
    );
    yield r'allowVan';
    yield serializers.serialize(
      object.allowVan,
      specifiedType: const FullType(bool),
    );
    yield r'allowTruck';
    yield serializers.serialize(
      object.allowTruck,
      specifiedType: const FullType(bool),
    );
    yield r'allowMotorTricycle';
    yield serializers.serialize(
      object.allowMotorTricycle,
      specifiedType: const FullType(bool),
    );
    yield r'coinValue';
    yield serializers.serialize(
      object.coinValue,
      specifiedType: const FullType(num),
    );
    yield r'amountSpentPerCoin';
    yield serializers.serialize(
      object.amountSpentPerCoin,
      specifiedType: const FullType(num),
    );
    yield r'minCoinsToUse';
    yield serializers.serialize(
      object.minCoinsToUse,
      specifiedType: const FullType(num),
    );
    if (object.homeCoverUrl != null) {
      yield r'homeCoverUrl';
      yield serializers.serialize(
        object.homeCoverUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.motorcycleIconUrl != null) {
      yield r'motorcycleIconUrl';
      yield serializers.serialize(
        object.motorcycleIconUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.carIconUrl != null) {
      yield r'carIconUrl';
      yield serializers.serialize(
        object.carIconUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.deliveryBannerIconUrl != null) {
      yield r'deliveryBannerIconUrl';
      yield serializers.serialize(
        object.deliveryBannerIconUrl,
        specifiedType: const FullType(String),
      );
    }
    yield r'android';
    yield serializers.serialize(
      object.android,
      specifiedType: const FullType(JsonObject),
    );
    yield r'ios';
    yield serializers.serialize(
      object.ios,
      specifiedType: const FullType(JsonObject),
    );
    yield r'support';
    yield serializers.serialize(
      object.support,
      specifiedType: const FullType(JsonObject),
    );
    yield r'legal';
    yield serializers.serialize(
      object.legal,
      specifiedType: const FullType(JsonObject),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PublicPlatformSettingsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PublicPlatformSettingsDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'isMaintenanceMode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isMaintenanceMode = valueDes;
          break;
        case r'currency':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.currency = valueDes;
          break;
        case r'minOrderAmount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minOrderAmount = valueDes;
          break;
        case r'defaultTaxRate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.defaultTaxRate = valueDes;
          break;
        case r'baseDeliveryFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.baseDeliveryFee = valueDes;
          break;
        case r'customOrderPlatformFee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.customOrderPlatformFee = valueDes;
          break;
        case r'pricePerKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKm = valueDes;
          break;
        case r'pricePerKmBicycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmBicycle = valueDes;
          break;
        case r'pricePerKmMotorcycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmMotorcycle = valueDes;
          break;
        case r'pricePerKmCar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmCar = valueDes;
          break;
        case r'pricePerKmVan':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmVan = valueDes;
          break;
        case r'pricePerKmTruck':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmTruck = valueDes;
          break;
        case r'pricePerKmMotorTricycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.pricePerKmMotorTricycle = valueDes;
          break;
        case r'allowBicycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowBicycle = valueDes;
          break;
        case r'allowMotorcycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowMotorcycle = valueDes;
          break;
        case r'allowCar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowCar = valueDes;
          break;
        case r'allowVan':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowVan = valueDes;
          break;
        case r'allowTruck':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowTruck = valueDes;
          break;
        case r'allowMotorTricycle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.allowMotorTricycle = valueDes;
          break;
        case r'coinValue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.coinValue = valueDes;
          break;
        case r'amountSpentPerCoin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.amountSpentPerCoin = valueDes;
          break;
        case r'minCoinsToUse':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minCoinsToUse = valueDes;
          break;
        case r'homeCoverUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.homeCoverUrl = valueDes;
          break;
        case r'motorcycleIconUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motorcycleIconUrl = valueDes;
          break;
        case r'carIconUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.carIconUrl = valueDes;
          break;
        case r'deliveryBannerIconUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.deliveryBannerIconUrl = valueDes;
          break;
        case r'android':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.android = valueDes;
          break;
        case r'ios':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.ios = valueDes;
          break;
        case r'support':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.support = valueDes;
          break;
        case r'legal':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.legal = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PublicPlatformSettingsDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PublicPlatformSettingsDtoBuilder();
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

