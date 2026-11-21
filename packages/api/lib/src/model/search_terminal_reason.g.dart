// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_terminal_reason.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SearchTerminalReason _$NONE = const SearchTerminalReason._('NONE');
const SearchTerminalReason _$SEARCH_TIMEOUT = const SearchTerminalReason._(
  'SEARCH_TIMEOUT',
);
const SearchTerminalReason _$NO_DRIVERS_AVAILABLE =
    const SearchTerminalReason._('NO_DRIVERS_AVAILABLE');
const SearchTerminalReason _$CANCELLED_BY_CUSTOMER =
    const SearchTerminalReason._('CANCELLED_BY_CUSTOMER');
const SearchTerminalReason _$CANCELLED_BY_ADMIN = const SearchTerminalReason._(
  'CANCELLED_BY_ADMIN',
);
const SearchTerminalReason _$CANCELLED_BY_SYSTEM = const SearchTerminalReason._(
  'CANCELLED_BY_SYSTEM',
);

SearchTerminalReason _$valueOf(String name) {
  switch (name) {
    case 'NONE':
      return _$NONE;
    case 'SEARCH_TIMEOUT':
      return _$SEARCH_TIMEOUT;
    case 'NO_DRIVERS_AVAILABLE':
      return _$NO_DRIVERS_AVAILABLE;
    case 'CANCELLED_BY_CUSTOMER':
      return _$CANCELLED_BY_CUSTOMER;
    case 'CANCELLED_BY_ADMIN':
      return _$CANCELLED_BY_ADMIN;
    case 'CANCELLED_BY_SYSTEM':
      return _$CANCELLED_BY_SYSTEM;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SearchTerminalReason> _$values =
    BuiltSet<SearchTerminalReason>(const <SearchTerminalReason>[
      _$NONE,
      _$SEARCH_TIMEOUT,
      _$NO_DRIVERS_AVAILABLE,
      _$CANCELLED_BY_CUSTOMER,
      _$CANCELLED_BY_ADMIN,
      _$CANCELLED_BY_SYSTEM,
    ]);

class _$SearchTerminalReasonMeta {
  const _$SearchTerminalReasonMeta();
  SearchTerminalReason get NONE => _$NONE;
  SearchTerminalReason get SEARCH_TIMEOUT => _$SEARCH_TIMEOUT;
  SearchTerminalReason get NO_DRIVERS_AVAILABLE => _$NO_DRIVERS_AVAILABLE;
  SearchTerminalReason get CANCELLED_BY_CUSTOMER => _$CANCELLED_BY_CUSTOMER;
  SearchTerminalReason get CANCELLED_BY_ADMIN => _$CANCELLED_BY_ADMIN;
  SearchTerminalReason get CANCELLED_BY_SYSTEM => _$CANCELLED_BY_SYSTEM;
  SearchTerminalReason valueOf(String name) => _$valueOf(name);
  BuiltSet<SearchTerminalReason> get values => _$values;
}

mixin _$SearchTerminalReasonMixin {
  // ignore: non_constant_identifier_names
  _$SearchTerminalReasonMeta get SearchTerminalReason =>
      const _$SearchTerminalReasonMeta();
}

Serializer<SearchTerminalReason> _$searchTerminalReasonSerializer =
    _$SearchTerminalReasonSerializer();

class _$SearchTerminalReasonSerializer
    implements PrimitiveSerializer<SearchTerminalReason> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'NONE': 'NONE',
    'SEARCH_TIMEOUT': 'SEARCH_TIMEOUT',
    'NO_DRIVERS_AVAILABLE': 'NO_DRIVERS_AVAILABLE',
    'CANCELLED_BY_CUSTOMER': 'CANCELLED_BY_CUSTOMER',
    'CANCELLED_BY_ADMIN': 'CANCELLED_BY_ADMIN',
    'CANCELLED_BY_SYSTEM': 'CANCELLED_BY_SYSTEM',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'NONE': 'NONE',
    'SEARCH_TIMEOUT': 'SEARCH_TIMEOUT',
    'NO_DRIVERS_AVAILABLE': 'NO_DRIVERS_AVAILABLE',
    'CANCELLED_BY_CUSTOMER': 'CANCELLED_BY_CUSTOMER',
    'CANCELLED_BY_ADMIN': 'CANCELLED_BY_ADMIN',
    'CANCELLED_BY_SYSTEM': 'CANCELLED_BY_SYSTEM',
  };

  @override
  final Iterable<Type> types = const <Type>[SearchTerminalReason];
  @override
  final String wireName = 'SearchTerminalReason';

  @override
  Object serialize(
    Serializers serializers,
    SearchTerminalReason object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SearchTerminalReason deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SearchTerminalReason.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
