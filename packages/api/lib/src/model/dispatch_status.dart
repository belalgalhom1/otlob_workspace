//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'dispatch_status.g.dart';

class DispatchStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PENDING')
  static const DispatchStatus PENDING = _$PENDING;
  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const DispatchStatus ACCEPTED = _$ACCEPTED;
  @BuiltValueEnumConst(wireName: r'REJECTED')
  static const DispatchStatus REJECTED = _$REJECTED;
  @BuiltValueEnumConst(wireName: r'EXPIRED')
  static const DispatchStatus EXPIRED = _$EXPIRED;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const DispatchStatus CANCELLED = _$CANCELLED;

  static Serializer<DispatchStatus> get serializer => _$dispatchStatusSerializer;

  const DispatchStatus._(String name): super(name);

  static BuiltSet<DispatchStatus> get values => _$values;
  static DispatchStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DispatchStatusMixin = Object with _$DispatchStatusMixin;

