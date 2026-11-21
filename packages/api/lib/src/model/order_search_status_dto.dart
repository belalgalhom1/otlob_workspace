//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/nearby_driver_preview_dto.dart';
import 'package:api/src/model/order_type.dart';
import 'package:api/src/model/order_status.dart';
import 'package:api/src/model/driver_search_phase.dart';
import 'package:api/src/model/geo_point_dto.dart';
import 'package:api/src/model/search_terminal_reason.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'order_search_status_dto.g.dart';

/// OrderSearchStatusDto
///
/// Properties:
/// * [orderId] 
/// * [orderNumber] 
/// * [orderType] 
/// * [orderStatus] 
/// * [revision] 
/// * [phase] 
/// * [attempt] 
/// * [maxAttempts] 
/// * [radiusKm] 
/// * [maxRadiusKm] 
/// * [contactedCount] 
/// * [totalContactedCount] 
/// * [rejectedCount] 
/// * [nearbyAvailableCount] 
/// * [nearbyDrivers] 
/// * [waveExpiresAt] 
/// * [searchTimeoutSecs] 
/// * [searchStartedAt] 
/// * [updatedAt] 
/// * [terminalReason] 
/// * [canRetry] 
/// * [driverLocation] 
/// * [driverDistanceKm] 
/// * [driverEtaMinutes] 
@BuiltValue()
abstract class OrderSearchStatusDto implements Built<OrderSearchStatusDto, OrderSearchStatusDtoBuilder> {
  @BuiltValueField(wireName: r'orderId')
  String get orderId;

  @BuiltValueField(wireName: r'orderNumber')
  String get orderNumber;

  @BuiltValueField(wireName: r'orderType')
  OrderType get orderType;
  // enum orderTypeEnum {  STANDARD,  CUSTOM_DELIVERY,  RIDE,  };

  @BuiltValueField(wireName: r'orderStatus')
  OrderStatus get orderStatus;
  // enum orderStatusEnum {  PENDING,  CHANGES_REQUESTED,  ACCEPTED,  PREPARING,  LOOKING_FOR_DRIVER,  DRIVER_ASSIGNED,  PENDING_PAYMENT,  READY_FOR_PICKUP,  PARTIALLY_PICKED_UP,  PICKED_UP,  DELIVERED,  CANCELLED,  };

  @BuiltValueField(wireName: r'revision')
  num get revision;

  @BuiltValueField(wireName: r'phase')
  DriverSearchPhase get phase;
  // enum phaseEnum {  QUEUED,  FINDING_DRIVERS,  CONTACTING_DRIVERS,  WAITING_DRIVER_RESPONSE,  NO_DRIVERS_IN_WAVE,  DRIVER_FOUND,  SEARCH_TIMEOUT,  NO_DRIVERS_AVAILABLE,  CANCELLED,  };

  @BuiltValueField(wireName: r'attempt')
  num get attempt;

  @BuiltValueField(wireName: r'maxAttempts')
  num get maxAttempts;

  @BuiltValueField(wireName: r'radiusKm')
  num get radiusKm;

  @BuiltValueField(wireName: r'maxRadiusKm')
  num get maxRadiusKm;

  @BuiltValueField(wireName: r'contactedCount')
  num get contactedCount;

  @BuiltValueField(wireName: r'totalContactedCount')
  num get totalContactedCount;

  @BuiltValueField(wireName: r'rejectedCount')
  num get rejectedCount;

  @BuiltValueField(wireName: r'nearbyAvailableCount')
  num get nearbyAvailableCount;

  @BuiltValueField(wireName: r'nearbyDrivers')
  BuiltList<NearbyDriverPreviewDto> get nearbyDrivers;

  @BuiltValueField(wireName: r'waveExpiresAt')
  String? get waveExpiresAt;

  @BuiltValueField(wireName: r'searchTimeoutSecs')
  num get searchTimeoutSecs;

  @BuiltValueField(wireName: r'searchStartedAt')
  String get searchStartedAt;

  @BuiltValueField(wireName: r'updatedAt')
  String get updatedAt;

  @BuiltValueField(wireName: r'terminalReason')
  SearchTerminalReason get terminalReason;
  // enum terminalReasonEnum {  NONE,  SEARCH_TIMEOUT,  NO_DRIVERS_AVAILABLE,  CANCELLED_BY_CUSTOMER,  CANCELLED_BY_ADMIN,  CANCELLED_BY_SYSTEM,  };

  @BuiltValueField(wireName: r'canRetry')
  bool get canRetry;

  @BuiltValueField(wireName: r'driverLocation')
  GeoPointDto? get driverLocation;

  @BuiltValueField(wireName: r'driverDistanceKm')
  num? get driverDistanceKm;

  @BuiltValueField(wireName: r'driverEtaMinutes')
  num? get driverEtaMinutes;

  OrderSearchStatusDto._();

  factory OrderSearchStatusDto([void updates(OrderSearchStatusDtoBuilder b)]) = _$OrderSearchStatusDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OrderSearchStatusDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OrderSearchStatusDto> get serializer => _$OrderSearchStatusDtoSerializer();
}

class _$OrderSearchStatusDtoSerializer implements PrimitiveSerializer<OrderSearchStatusDto> {
  @override
  final Iterable<Type> types = const [OrderSearchStatusDto, _$OrderSearchStatusDto];

  @override
  final String wireName = r'OrderSearchStatusDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OrderSearchStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'orderId';
    yield serializers.serialize(
      object.orderId,
      specifiedType: const FullType(String),
    );
    yield r'orderNumber';
    yield serializers.serialize(
      object.orderNumber,
      specifiedType: const FullType(String),
    );
    yield r'orderType';
    yield serializers.serialize(
      object.orderType,
      specifiedType: const FullType(OrderType),
    );
    yield r'orderStatus';
    yield serializers.serialize(
      object.orderStatus,
      specifiedType: const FullType(OrderStatus),
    );
    yield r'revision';
    yield serializers.serialize(
      object.revision,
      specifiedType: const FullType(num),
    );
    yield r'phase';
    yield serializers.serialize(
      object.phase,
      specifiedType: const FullType(DriverSearchPhase),
    );
    yield r'attempt';
    yield serializers.serialize(
      object.attempt,
      specifiedType: const FullType(num),
    );
    yield r'maxAttempts';
    yield serializers.serialize(
      object.maxAttempts,
      specifiedType: const FullType(num),
    );
    yield r'radiusKm';
    yield serializers.serialize(
      object.radiusKm,
      specifiedType: const FullType(num),
    );
    yield r'maxRadiusKm';
    yield serializers.serialize(
      object.maxRadiusKm,
      specifiedType: const FullType(num),
    );
    yield r'contactedCount';
    yield serializers.serialize(
      object.contactedCount,
      specifiedType: const FullType(num),
    );
    yield r'totalContactedCount';
    yield serializers.serialize(
      object.totalContactedCount,
      specifiedType: const FullType(num),
    );
    yield r'rejectedCount';
    yield serializers.serialize(
      object.rejectedCount,
      specifiedType: const FullType(num),
    );
    yield r'nearbyAvailableCount';
    yield serializers.serialize(
      object.nearbyAvailableCount,
      specifiedType: const FullType(num),
    );
    yield r'nearbyDrivers';
    yield serializers.serialize(
      object.nearbyDrivers,
      specifiedType: const FullType(BuiltList, [FullType(NearbyDriverPreviewDto)]),
    );
    if (object.waveExpiresAt != null) {
      yield r'waveExpiresAt';
      yield serializers.serialize(
        object.waveExpiresAt,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'searchTimeoutSecs';
    yield serializers.serialize(
      object.searchTimeoutSecs,
      specifiedType: const FullType(num),
    );
    yield r'searchStartedAt';
    yield serializers.serialize(
      object.searchStartedAt,
      specifiedType: const FullType(String),
    );
    yield r'updatedAt';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(String),
    );
    yield r'terminalReason';
    yield serializers.serialize(
      object.terminalReason,
      specifiedType: const FullType(SearchTerminalReason),
    );
    yield r'canRetry';
    yield serializers.serialize(
      object.canRetry,
      specifiedType: const FullType(bool),
    );
    if (object.driverLocation != null) {
      yield r'driverLocation';
      yield serializers.serialize(
        object.driverLocation,
        specifiedType: const FullType.nullable(GeoPointDto),
      );
    }
    if (object.driverDistanceKm != null) {
      yield r'driverDistanceKm';
      yield serializers.serialize(
        object.driverDistanceKm,
        specifiedType: const FullType.nullable(num),
      );
    }
    if (object.driverEtaMinutes != null) {
      yield r'driverEtaMinutes';
      yield serializers.serialize(
        object.driverEtaMinutes,
        specifiedType: const FullType.nullable(num),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OrderSearchStatusDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OrderSearchStatusDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'orderId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderId = valueDes;
          break;
        case r'orderNumber':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.orderNumber = valueDes;
          break;
        case r'orderType':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderType),
          ) as OrderType;
          result.orderType = valueDes;
          break;
        case r'orderStatus':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OrderStatus),
          ) as OrderStatus;
          result.orderStatus = valueDes;
          break;
        case r'revision':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.revision = valueDes;
          break;
        case r'phase':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverSearchPhase),
          ) as DriverSearchPhase;
          result.phase = valueDes;
          break;
        case r'attempt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.attempt = valueDes;
          break;
        case r'maxAttempts':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxAttempts = valueDes;
          break;
        case r'radiusKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.radiusKm = valueDes;
          break;
        case r'maxRadiusKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.maxRadiusKm = valueDes;
          break;
        case r'contactedCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.contactedCount = valueDes;
          break;
        case r'totalContactedCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalContactedCount = valueDes;
          break;
        case r'rejectedCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.rejectedCount = valueDes;
          break;
        case r'nearbyAvailableCount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.nearbyAvailableCount = valueDes;
          break;
        case r'nearbyDrivers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(NearbyDriverPreviewDto)]),
          ) as BuiltList<NearbyDriverPreviewDto>;
          result.nearbyDrivers.replace(valueDes);
          break;
        case r'waveExpiresAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.waveExpiresAt = valueDes;
          break;
        case r'searchTimeoutSecs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.searchTimeoutSecs = valueDes;
          break;
        case r'searchStartedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.searchStartedAt = valueDes;
          break;
        case r'updatedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.updatedAt = valueDes;
          break;
        case r'terminalReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SearchTerminalReason),
          ) as SearchTerminalReason;
          result.terminalReason = valueDes;
          break;
        case r'canRetry':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.canRetry = valueDes;
          break;
        case r'driverLocation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(GeoPointDto),
          ) as GeoPointDto?;
          if (valueDes == null) continue;
          result.driverLocation.replace(valueDes);
          break;
        case r'driverDistanceKm':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.driverDistanceKm = valueDes;
          break;
        case r'driverEtaMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(num),
          ) as num?;
          if (valueDes == null) continue;
          result.driverEtaMinutes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OrderSearchStatusDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OrderSearchStatusDtoBuilder();
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

