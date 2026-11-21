//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'driver_search_phase.g.dart';

class DriverSearchPhase extends EnumClass {

  @BuiltValueEnumConst(wireName: r'QUEUED')
  static const DriverSearchPhase QUEUED = _$QUEUED;
  @BuiltValueEnumConst(wireName: r'FINDING_DRIVERS')
  static const DriverSearchPhase FINDING_DRIVERS = _$FINDING_DRIVERS;
  @BuiltValueEnumConst(wireName: r'CONTACTING_DRIVERS')
  static const DriverSearchPhase CONTACTING_DRIVERS = _$CONTACTING_DRIVERS;
  @BuiltValueEnumConst(wireName: r'WAITING_DRIVER_RESPONSE')
  static const DriverSearchPhase WAITING_DRIVER_RESPONSE = _$WAITING_DRIVER_RESPONSE;
  @BuiltValueEnumConst(wireName: r'NO_DRIVERS_IN_WAVE')
  static const DriverSearchPhase NO_DRIVERS_IN_WAVE = _$NO_DRIVERS_IN_WAVE;
  @BuiltValueEnumConst(wireName: r'DRIVER_FOUND')
  static const DriverSearchPhase DRIVER_FOUND = _$DRIVER_FOUND;
  @BuiltValueEnumConst(wireName: r'SEARCH_TIMEOUT')
  static const DriverSearchPhase SEARCH_TIMEOUT = _$SEARCH_TIMEOUT;
  @BuiltValueEnumConst(wireName: r'NO_DRIVERS_AVAILABLE')
  static const DriverSearchPhase NO_DRIVERS_AVAILABLE = _$NO_DRIVERS_AVAILABLE;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const DriverSearchPhase CANCELLED = _$CANCELLED;

  static Serializer<DriverSearchPhase> get serializer => _$driverSearchPhaseSerializer;

  const DriverSearchPhase._(String name): super(name);

  static BuiltSet<DriverSearchPhase> get values => _$values;
  static DriverSearchPhase valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DriverSearchPhaseMixin = Object with _$DriverSearchPhaseMixin;

