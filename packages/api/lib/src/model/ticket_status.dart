//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ticket_status.g.dart';

class TicketStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OPEN')
  static const TicketStatus OPEN = _$OPEN;
  @BuiltValueEnumConst(wireName: r'IN_PROGRESS')
  static const TicketStatus IN_PROGRESS = _$IN_PROGRESS;
  @BuiltValueEnumConst(wireName: r'WAITING_ON_USER')
  static const TicketStatus WAITING_ON_USER = _$WAITING_ON_USER;
  @BuiltValueEnumConst(wireName: r'ESCALATED')
  static const TicketStatus ESCALATED = _$ESCALATED;
  @BuiltValueEnumConst(wireName: r'RESOLVED')
  static const TicketStatus RESOLVED = _$RESOLVED;
  @BuiltValueEnumConst(wireName: r'CLOSED')
  static const TicketStatus CLOSED = _$CLOSED;

  static Serializer<TicketStatus> get serializer => _$ticketStatusSerializer;

  const TicketStatus._(String name): super(name);

  static BuiltSet<TicketStatus> get values => _$values;
  static TicketStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class TicketStatusMixin = Object with _$TicketStatusMixin;

