//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ticket_priority.g.dart';

class TicketPriority extends EnumClass {

  @BuiltValueEnumConst(wireName: r'LOW')
  static const TicketPriority LOW = _$LOW;
  @BuiltValueEnumConst(wireName: r'MEDIUM')
  static const TicketPriority MEDIUM = _$MEDIUM;
  @BuiltValueEnumConst(wireName: r'HIGH')
  static const TicketPriority HIGH = _$HIGH;
  @BuiltValueEnumConst(wireName: r'URGENT')
  static const TicketPriority URGENT = _$URGENT;

  static Serializer<TicketPriority> get serializer => _$ticketPrioritySerializer;

  const TicketPriority._(String name): super(name);

  static BuiltSet<TicketPriority> get values => _$values;
  static TicketPriority valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TicketPriorityMixin = Object with _$TicketPriorityMixin;

