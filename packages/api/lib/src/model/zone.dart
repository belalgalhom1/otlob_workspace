//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:api/src/model/order.dart';
import 'package:api/src/model/shift_pool.dart';
import 'package:built_collection/built_collection.dart';
import 'package:api/src/model/driver_shift.dart';
import 'package:api/src/model/vendor_branch.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';

part 'zone.g.dart';

/// Zone
///
/// Properties:
/// * [id] 
/// * [name] 
/// * [nameAr] 
/// * [isActive] 
/// * [baseDeliveryFeeOverride] 
/// * [minOrderAmountOverride] 
/// * [createdAt] 
/// * [updatedAt] 
/// * [driverShifts] 
/// * [orders] 
/// * [vendorBranches] 
/// * [shiftPools] 
@BuiltValue()
abstract class Zone implements Built<Zone, ZoneBuilder> {
  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'nameAr')
  String? get nameAr;

  @BuiltValueField(wireName: r'isActive')
  bool get isActive;

  @BuiltValueField(wireName: r'baseDeliveryFeeOverride')
  num? get baseDeliveryFeeOverride;

  @BuiltValueField(wireName: r'minOrderAmountOverride')
  num? get minOrderAmountOverride;

  @BuiltValueField(wireName: r'createdAt')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'updatedAt')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'driverShifts')
  BuiltList<JsonObject>? get driverShifts;

  @BuiltValueField(wireName: r'orders')
  BuiltList<JsonObject>? get orders;

  @BuiltValueField(wireName: r'vendorBranches')
  BuiltList<JsonObject>? get vendorBranches;

  @BuiltValueField(wireName: r'shiftPools')
  BuiltList<JsonObject>? get shiftPools;

  Zone._();

  factory Zone([void updates(ZoneBuilder b)]) = _$Zone;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ZoneBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Zone> get serializer => _$ZoneSerializer();
}

class _$ZoneSerializer implements PrimitiveSerializer<Zone> {
  @override
  final Iterable<Type> types = const [Zone, _$Zone];

  @override
  final String wireName = r'Zone';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Zone object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.nameAr != null) {
      yield r'nameAr';
      yield serializers.serialize(
        object.nameAr,
        specifiedType: const FullType(String),
      );
    }
    yield r'isActive';
    yield serializers.serialize(
      object.isActive,
      specifiedType: const FullType(bool),
    );
    if (object.baseDeliveryFeeOverride != null) {
      yield r'baseDeliveryFeeOverride';
      yield serializers.serialize(
        object.baseDeliveryFeeOverride,
        specifiedType: const FullType(num),
      );
    }
    if (object.minOrderAmountOverride != null) {
      yield r'minOrderAmountOverride';
      yield serializers.serialize(
        object.minOrderAmountOverride,
        specifiedType: const FullType(num),
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
    yield r'driverShifts';
    yield serializers.serialize(
      object.driverShifts,
      specifiedType: const FullType(BuiltList, [FullType(DriverShift)]),
    );
    yield r'orders';
    yield serializers.serialize(
      object.orders,
      specifiedType: const FullType(BuiltList, [FullType(Order)]),
    );
    yield r'vendorBranches';
    yield serializers.serialize(
      object.vendorBranches,
      specifiedType: const FullType(BuiltList, [FullType(VendorBranch)]),
    );
    yield r'shiftPools';
    yield serializers.serialize(
      object.shiftPools,
      specifiedType: const FullType(BuiltList, [FullType(ShiftPool)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Zone object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ZoneBuilder result,
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
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'nameAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nameAr = valueDes;
          break;
        case r'isActive':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'baseDeliveryFeeOverride':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.baseDeliveryFeeOverride = valueDes;
          break;
        case r'minOrderAmountOverride':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.minOrderAmountOverride = valueDes;
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
        case r'driverShifts':
          // Field patched to BuiltList<JsonObject>? - skip deserialization
          break;
        case r'orders':
          // Field patched to BuiltList<JsonObject>? - skip deserialization
          break;
        case r'vendorBranches':
          // Field patched to BuiltList<JsonObject>? - skip deserialization
          break;
        case r'shiftPools':
          // Field patched to BuiltList<JsonObject>? - skip deserialization
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Zone deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ZoneBuilder();
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

