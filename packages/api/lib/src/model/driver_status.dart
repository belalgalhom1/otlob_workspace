//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_status.g.dart';

class DriverStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OFFLINE')
  static const DriverStatus OFFLINE = _$OFFLINE;
  @BuiltValueEnumConst(wireName: r'ONLINE')
  static const DriverStatus ONLINE = _$ONLINE;
  @BuiltValueEnumConst(wireName: r'BUSY')
  static const DriverStatus BUSY = _$BUSY;
  @BuiltValueEnumConst(wireName: r'ON_DELIVERY')
  static const DriverStatus ON_DELIVERY = _$ON_DELIVERY;
  @BuiltValueEnumConst(wireName: r'ON_BREAK')
  static const DriverStatus ON_BREAK = _$ON_BREAK;
  @BuiltValueEnumConst(wireName: r'SUSPENDED')
  static const DriverStatus SUSPENDED = _$SUSPENDED;

  static Serializer<DriverStatus> get serializer => _$driverStatusSerializer;

  const DriverStatus._(String name): super(name);

  static BuiltSet<DriverStatus> get values => _$values;
  static DriverStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DriverStatusMixin = Object with _$DriverStatusMixin;

