// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_category.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const TicketCategory _$DELIVERY = const TicketCategory._('DELIVERY');
const TicketCategory _$VENDOR = const TicketCategory._('VENDOR');
const TicketCategory _$PAYMENT = const TicketCategory._('PAYMENT');
const TicketCategory _$ACCOUNT = const TicketCategory._('ACCOUNT');
const TicketCategory _$RETURN_COMPLAINT = const TicketCategory._(
  'RETURN_COMPLAINT',
);
const TicketCategory _$OTHER = const TicketCategory._('OTHER');

TicketCategory _$valueOf(String name) {
  switch (name) {
    case 'DELIVERY':
      return _$DELIVERY;
    case 'VENDOR':
      return _$VENDOR;
    case 'PAYMENT':
      return _$PAYMENT;
    case 'ACCOUNT':
      return _$ACCOUNT;
    case 'RETURN_COMPLAINT':
      return _$RETURN_COMPLAINT;
    case 'OTHER':
      return _$OTHER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<TicketCategory> _$values = BuiltSet<TicketCategory>(
  const <TicketCategory>[
    _$DELIVERY,
    _$VENDOR,
    _$PAYMENT,
    _$ACCOUNT,
    _$RETURN_COMPLAINT,
    _$OTHER,
  ],
);

class _$TicketCategoryMeta {
  const _$TicketCategoryMeta();
  TicketCategory get DELIVERY => _$DELIVERY;
  TicketCategory get VENDOR => _$VENDOR;
  TicketCategory get PAYMENT => _$PAYMENT;
  TicketCategory get ACCOUNT => _$ACCOUNT;
  TicketCategory get RETURN_COMPLAINT => _$RETURN_COMPLAINT;
  TicketCategory get OTHER => _$OTHER;
  TicketCategory valueOf(String name) => _$valueOf(name);
  BuiltSet<TicketCategory> get values => _$values;
}

mixin _$TicketCategoryMixin {
  // ignore: non_constant_identifier_names
  _$TicketCategoryMeta get TicketCategory => const _$TicketCategoryMeta();
}

Serializer<TicketCategory> _$ticketCategorySerializer =
    _$TicketCategorySerializer();

class _$TicketCategorySerializer
    implements PrimitiveSerializer<TicketCategory> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'DELIVERY': 'DELIVERY',
    'VENDOR': 'VENDOR',
    'PAYMENT': 'PAYMENT',
    'ACCOUNT': 'ACCOUNT',
    'RETURN_COMPLAINT': 'RETURN_COMPLAINT',
    'OTHER': 'OTHER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DELIVERY': 'DELIVERY',
    'VENDOR': 'VENDOR',
    'PAYMENT': 'PAYMENT',
    'ACCOUNT': 'ACCOUNT',
    'RETURN_COMPLAINT': 'RETURN_COMPLAINT',
    'OTHER': 'OTHER',
  };

  @override
  final Iterable<Type> types = const <Type>[TicketCategory];
  @override
  final String wireName = 'TicketCategory';

  @override
  Object serialize(
    Serializers serializers,
    TicketCategory object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  TicketCategory deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => TicketCategory.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
