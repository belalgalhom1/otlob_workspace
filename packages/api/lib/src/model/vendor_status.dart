//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vendor_status.g.dart';

class VendorStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CLOSED')
  static const VendorStatus CLOSED = _$CLOSED;
  @BuiltValueEnumConst(wireName: r'OPEN')
  static const VendorStatus OPEN = _$OPEN;
  @BuiltValueEnumConst(wireName: r'PAUSED')
  static const VendorStatus PAUSED = _$PAUSED;
  @BuiltValueEnumConst(wireName: r'SUSPENDED')
  static const VendorStatus SUSPENDED = _$SUSPENDED;

  static Serializer<VendorStatus> get serializer => _$vendorStatusSerializer;

  const VendorStatus._(String name): super(name);

  static BuiltSet<VendorStatus> get values => _$values;
  static VendorStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class VendorStatusMixin = Object with _$VendorStatusMixin;

