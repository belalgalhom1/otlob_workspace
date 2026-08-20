//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ticket_category.g.dart';

class TicketCategory extends EnumClass {

  @BuiltValueEnumConst(wireName: r'DELIVERY')
  static const TicketCategory DELIVERY = _$DELIVERY;
  @BuiltValueEnumConst(wireName: r'VENDOR')
  static const TicketCategory VENDOR = _$VENDOR;
  @BuiltValueEnumConst(wireName: r'PAYMENT')
  static const TicketCategory PAYMENT = _$PAYMENT;
  @BuiltValueEnumConst(wireName: r'ACCOUNT')
  static const TicketCategory ACCOUNT = _$ACCOUNT;
  @BuiltValueEnumConst(wireName: r'RETURN_COMPLAINT')
  static const TicketCategory RETURN_COMPLAINT = _$RETURN_COMPLAINT;
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const TicketCategory OTHER = _$OTHER;

  static Serializer<TicketCategory> get serializer => _$ticketCategorySerializer;

  const TicketCategory._(String name): super(name);

  static BuiltSet<TicketCategory> get values => _$values;
  static TicketCategory valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TicketCategoryMixin = Object with _$TicketCategoryMixin;

