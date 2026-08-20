//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'conversation_status.g.dart';

class ConversationStatus extends EnumClass {

  @BuiltValueEnumConst(wireName: r'OPEN')
  static const ConversationStatus OPEN = _$OPEN;
  @BuiltValueEnumConst(wireName: r'CLOSED')
  static const ConversationStatus CLOSED = _$CLOSED;
  @BuiltValueEnumConst(wireName: r'ARCHIVED')
  static const ConversationStatus ARCHIVED = _$ARCHIVED;

  static Serializer<ConversationStatus> get serializer => _$conversationStatusSerializer;

  const ConversationStatus._(String name): super(name);

  static BuiltSet<ConversationStatus> get values => _$values;
  static ConversationStatus valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ConversationStatusMixin = Object with _$ConversationStatusMixin;

