//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/driver_shift_status.dart';
import 'package:api/src/model/driver_wallet_transaction.dart';
import 'package:api/src/model/shift_swap_request.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/shift_pool.dart';
import 'package:api/src/model/zone.dart';
import 'package:api/src/model/order.dart';
import 'package:api/src/model/driver.dart';
import 'package:api/src/model/driver_break.dart';
import 'package:api/src/model/order_dispatch.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_shift_response_dto.g.dart';

/// DriverShiftResponseDto
///
/// Properties:
/// * [id] 
/// * [driverId] 
/// * [shiftPoolId] 
/// * [zoneId] 
/// * [shiftDate] 
/// * [startTime] 
/// * [endTime] 
/// * [actualStart] 
/// * [actualEnd] 
/// * [startPhotoUrl] 
/// * [status] 
/// * [breakMinutes] 
/// * [totalEarnings] 
/// * [totalDeliveries] 
/// * [expiredDispatches] 
/// * [rejectedDispatches] 
/// * [warningSent] 
/// * [isExcused] 
/// * [excuseReason] 
/// * [excusedByUserId] 
/// * [excusedAt] 
/// * [createdAt] 
/// * [driver] 
/// * [shiftPool] 
/// * [zone] 
/// * [walletTransactions] 
/// * [dispatches] 
/// * [orders] 
/// * [swapRequests] 
/// * [breaks] 
@BuiltValue()
abstract class DriverShiftResponseDto implements Built<DriverShiftResponseDto, DriverShiftResponseDtoBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'driverId')
  String get driverId;

  @BuiltValueField(wireName: r'shiftPoolId')
  String? get shiftPoolId;

  @BuiltValueField(wireName: r'zoneId')
  String? get zoneId;

  @BuiltValueField(wireName: r'shiftDate')
  DateTime get shiftDate;

  @BuiltValueField(wireName: r'startTime')
  DateTime get startTime;

  @BuiltValueField(wireName: r'endTime')
  DateTime get endTime;

  @BuiltValueField(wireName: r'actualStart')
  DateTime? get actualStart;

  @BuiltValueField(wireName: r'actualEnd')
  DateTime? get actualEnd;

  @BuiltValueField(wireName: r'startPhotoUrl')
  String? get startPhotoUrl;

  @BuiltValueField(wireName: r'status')
  DriverShiftStatus get status;
  // enum statusEnum {  SCHEDULED,  ACTIVE,  COMPLETED,  CANCELLED,  MISSED,  };

  @BuiltValueField(wireName: r'breakMinutes')
  num? get breakMinutes;

  @BuiltValueField(wireName: r'totalEarnings')
  num? get totalEarnings;

  @BuiltValueField(wireName: r'totalDeliveries')
  num? get totalDeliveries;

  @BuiltValueField(wireName: r'expiredDispatches')
  num get expiredDispatches;

  @BuiltValueField(wireName: r'rejectedDispatches')
  num get rejectedDispatches;

  @BuiltValueField(wireName: r'warningSent')
  bool get warningSent;

  @BuiltValueField(wireName: r'isExcused')
  bool get isExcused;

  @BuiltValueField(wireName: r'excuseReason')
  String? get excuseReason;

  @BuiltValueField(wireName: r'excusedByUserId')
  String? get excusedByUserId;

  @BuiltValueField(wireName: r'excusedAt')
  DateTime? get excusedAt;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'driver')
  Driver? get driver;

  @BuiltValueField(wireName: r'shiftPool')
  ShiftPool? get shiftPool;

  @BuiltValueField(wireName: r'zone')
  Zone? get zone;

  @BuiltValueField(wireName: r'walletTransactions')
  BuiltList<DriverWalletTransaction>? get walletTransactions;

  @BuiltValueField(wireName: r'dispatches')
  BuiltList<OrderDispatch>? get dispatches;

  @BuiltValueField(wireName: r'orders')
  BuiltList<Order>? get orders;

  @BuiltValueField(wireName: r'swapRequests')
  BuiltList<ShiftSwapRequest>? get swapRequests;

  @BuiltValueField(wireName: r'breaks')
  BuiltList<DriverBreak>? get breaks;

  DriverShiftResponseDto._();

  factory DriverShiftResponseDto([void updates(DriverShiftResponseDtoBuilder b)]) = _$DriverShiftResponseDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DriverShiftResponseDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DriverShiftResponseDto> get serializer => _$DriverShiftResponseDtoSerializer();
}

class _$DriverShiftResponseDtoSerializer implements PrimitiveSerializer<DriverShiftResponseDto> {
  @override
  final Iterable<Type> types = const [DriverShiftResponseDto, _$DriverShiftResponseDto];

  @override
  final String wireName = r'DriverShiftResponseDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DriverShiftResponseDto object, {
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
    if (object.shiftPoolId != null) {
      yield r'shiftPoolId';
      yield serializers.serialize(
        object.shiftPoolId,
        specifiedType: const FullType(String),
      );
    }
    if (object.zoneId != null) {
      yield r'zoneId';
      yield serializers.serialize(
        object.zoneId,
        specifiedType: const FullType(String),
      );
    }
    yield r'shiftDate';
    yield serializers.serialize(
      object.shiftDate,
      specifiedType: const FullType(DateTime),
    );
    yield r'startTime';
    yield serializers.serialize(
      object.startTime,
      specifiedType: const FullType(DateTime),
    );
    yield r'endTime';
    yield serializers.serialize(
      object.endTime,
      specifiedType: const FullType(DateTime),
    );
    if (object.actualStart != null) {
      yield r'actualStart';
      yield serializers.serialize(
        object.actualStart,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.actualEnd != null) {
      yield r'actualEnd';
      yield serializers.serialize(
        object.actualEnd,
        specifiedType: const FullType(DateTime),
      );
    }
    if (object.startPhotoUrl != null) {
      yield r'startPhotoUrl';
      yield serializers.serialize(
        object.startPhotoUrl,
        specifiedType: const FullType(String),
      );
    }
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(DriverShiftStatus),
    );
    if (object.breakMinutes != null) {
      yield r'breakMinutes';
      yield serializers.serialize(
        object.breakMinutes,
        specifiedType: const FullType(num),
      );
    }
    if (object.totalEarnings != null) {
      yield r'totalEarnings';
      yield serializers.serialize(
        object.totalEarnings,
        specifiedType: const FullType(num),
      );
    }
    if (object.totalDeliveries != null) {
      yield r'totalDeliveries';
      yield serializers.serialize(
        object.totalDeliveries,
        specifiedType: const FullType(num),
      );
    }
    yield r'expiredDispatches';
    yield serializers.serialize(
      object.expiredDispatches,
      specifiedType: const FullType(num),
    );
    yield r'rejectedDispatches';
    yield serializers.serialize(
      object.rejectedDispatches,
      specifiedType: const FullType(num),
    );
    yield r'warningSent';
    yield serializers.serialize(
      object.warningSent,
      specifiedType: const FullType(bool),
    );
    yield r'isExcused';
    yield serializers.serialize(
      object.isExcused,
      specifiedType: const FullType(bool),
    );
    if (object.excuseReason != null) {
      yield r'excuseReason';
      yield serializers.serialize(
        object.excuseReason,
        specifiedType: const FullType(String),
      );
    }
    if (object.excusedByUserId != null) {
      yield r'excusedByUserId';
      yield serializers.serialize(
        object.excusedByUserId,
        specifiedType: const FullType(String),
      );
    }
    if (object.excusedAt != null) {
      yield r'excusedAt';
      yield serializers.serialize(
        object.excusedAt,
        specifiedType: const FullType(DateTime),
      );
    }
    yield r'createdAt';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.driver != null) {
      yield r'driver';
      yield serializers.serialize(
        object.driver,
        specifiedType: const FullType(Driver),
      );
    }
    if (object.shiftPool != null) {
      yield r'shiftPool';
      yield serializers.serialize(
        object.shiftPool,
        specifiedType: const FullType(ShiftPool),
      );
    }
    if (object.zone != null) {
      yield r'zone';
      yield serializers.serialize(
        object.zone,
        specifiedType: const FullType(Zone),
      );
    }
    if (object.walletTransactions != null) {
      yield r'walletTransactions';
      yield serializers.serialize(
        object.walletTransactions,
        specifiedType: const FullType(BuiltList, [FullType(DriverWalletTransaction)]),
      );
    }
    if (object.dispatches != null) {
      yield r'dispatches';
      yield serializers.serialize(
        object.dispatches,
        specifiedType: const FullType(BuiltList, [FullType(OrderDispatch)]),
      );
    }
    if (object.orders != null) {
      yield r'orders';
      yield serializers.serialize(
        object.orders,
        specifiedType: const FullType(BuiltList, [FullType(Order)]),
      );
    }
    if (object.swapRequests != null) {
      yield r'swapRequests';
      yield serializers.serialize(
        object.swapRequests,
        specifiedType: const FullType(BuiltList, [FullType(ShiftSwapRequest)]),
      );
    }
    if (object.breaks != null) {
      yield r'breaks';
      yield serializers.serialize(
        object.breaks,
        specifiedType: const FullType(BuiltList, [FullType(DriverBreak)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DriverShiftResponseDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DriverShiftResponseDtoBuilder result,
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
        case r'shiftPoolId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.shiftPoolId = valueDes;
          break;
        case r'zoneId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        case r'shiftDate':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.shiftDate = valueDes;
          break;
        case r'startTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.startTime = valueDes;
          break;
        case r'endTime':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.endTime = valueDes;
          break;
        case r'actualStart':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.actualStart = valueDes;
          break;
        case r'actualEnd':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.actualEnd = valueDes;
          break;
        case r'startPhotoUrl':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.startPhotoUrl = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DriverShiftStatus),
          ) as DriverShiftStatus;
          result.status = valueDes;
          break;
        case r'breakMinutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.breakMinutes = valueDes;
          break;
        case r'totalEarnings':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalEarnings = valueDes;
          break;
        case r'totalDeliveries':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.totalDeliveries = valueDes;
          break;
        case r'expiredDispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.expiredDispatches = valueDes;
          break;
        case r'rejectedDispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.rejectedDispatches = valueDes;
          break;
        case r'warningSent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.warningSent = valueDes;
          break;
        case r'isExcused':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isExcused = valueDes;
          break;
        case r'excuseReason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.excuseReason = valueDes;
          break;
        case r'excusedByUserId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.excusedByUserId = valueDes;
          break;
        case r'excusedAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.excusedAt = valueDes;
          break;
        case r'createdAt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'driver':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Driver),
          ) as Driver;
          result.driver.replace(valueDes);
          break;
        case r'shiftPool':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ShiftPool),
          ) as ShiftPool;
          result.shiftPool.replace(valueDes);
          break;
        case r'zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Zone),
          ) as Zone;
          result.zone.replace(valueDes);
          break;
        case r'walletTransactions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverWalletTransaction)]),
          ) as BuiltList<DriverWalletTransaction>;
          result.walletTransactions.replace(valueDes);
          break;
        case r'dispatches':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(OrderDispatch)]),
          ) as BuiltList<OrderDispatch>;
          result.dispatches.replace(valueDes);
          break;
        case r'orders':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Order)]),
          ) as BuiltList<Order>;
          result.orders.replace(valueDes);
          break;
        case r'swapRequests':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ShiftSwapRequest)]),
          ) as BuiltList<ShiftSwapRequest>;
          result.swapRequests.replace(valueDes);
          break;
        case r'breaks':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DriverBreak)]),
          ) as BuiltList<DriverBreak>;
          result.breaks.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DriverShiftResponseDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DriverShiftResponseDtoBuilder();
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

