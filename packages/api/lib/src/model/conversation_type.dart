//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'conversation_type.g.dart';

class ConversationType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ORDER')
  static const ConversationType ORDER = _$ORDER;
  @BuiltValueEnumConst(wireName: r'SUPPORT')
  static const ConversationType SUPPORT = _$SUPPORT;
  @BuiltValueEnumConst(wireName: r'VENDOR')
  static const ConversationType VENDOR = _$VENDOR;

  static Serializer<ConversationType> get serializer => _$conversationTypeSerializer;

  const ConversationType._(String name): super(name);

  static BuiltSet<ConversationType> get values => _$values;
  static ConversationType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class ConversationTypeMixin = Object with _$ConversationTypeMixin;

