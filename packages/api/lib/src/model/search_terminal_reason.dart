//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'search_terminal_reason.g.dart';

class SearchTerminalReason extends EnumClass {

  @BuiltValueEnumConst(wireName: r'NONE')
  static const SearchTerminalReason NONE = _$NONE;
  @BuiltValueEnumConst(wireName: r'SEARCH_TIMEOUT')
  static const SearchTerminalReason SEARCH_TIMEOUT = _$SEARCH_TIMEOUT;
  @BuiltValueEnumConst(wireName: r'NO_DRIVERS_AVAILABLE')
  static const SearchTerminalReason NO_DRIVERS_AVAILABLE = _$NO_DRIVERS_AVAILABLE;
  @BuiltValueEnumConst(wireName: r'CANCELLED_BY_CUSTOMER')
  static const SearchTerminalReason CANCELLED_BY_CUSTOMER = _$CANCELLED_BY_CUSTOMER;
  @BuiltValueEnumConst(wireName: r'CANCELLED_BY_ADMIN')
  static const SearchTerminalReason CANCELLED_BY_ADMIN = _$CANCELLED_BY_ADMIN;
  @BuiltValueEnumConst(wireName: r'CANCELLED_BY_SYSTEM')
  static const SearchTerminalReason CANCELLED_BY_SYSTEM = _$CANCELLED_BY_SYSTEM;

  static Serializer<SearchTerminalReason> get serializer => _$searchTerminalReasonSerializer;

  const SearchTerminalReason._(String name): super(name);

  static BuiltSet<SearchTerminalReason> get values => _$values;
  static SearchTerminalReason valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class SearchTerminalReasonMixin = Object with _$SearchTerminalReasonMixin;

