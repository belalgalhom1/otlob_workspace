//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'swap_request_status.g.dart';

class SwapRequestStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'PENDING')
  static const SwapRequestStatus PENDING = _$PENDING;
  @BuiltValueEnumConst(wireName: r'ACCEPTED')
  static const SwapRequestStatus ACCEPTED = _$ACCEPTED;
  @BuiltValueEnumConst(wireName: r'CANCELLED')
  static const SwapRequestStatus CANCELLED = _$CANCELLED;

  static Serializer<SwapRequestStatus> get serializer => _$swapRequestStatusSerializer;

  const SwapRequestStatus._(String name): super(name);

  static BuiltSet<SwapRequestStatus> get values => _$values;
  static SwapRequestStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class SwapRequestStatusMixin = Object with _$SwapRequestStatusMixin;

