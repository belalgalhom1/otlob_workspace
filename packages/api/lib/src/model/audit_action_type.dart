//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'audit_action_type.g.dart';

class AuditActionType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'CREATE')
  static const AuditActionType CREATE = _$CREATE;
  @BuiltValueEnumConst(wireName: r'UPDATE')
  static const AuditActionType UPDATE = _$UPDATE;
  @BuiltValueEnumConst(wireName: r'DELETE')
  static const AuditActionType DELETE = _$DELETE;
  @BuiltValueEnumConst(wireName: r'OTHER')
  static const AuditActionType OTHER = _$OTHER;

  static Serializer<AuditActionType> get serializer => _$auditActionTypeSerializer;

  const AuditActionType._(String name): super(name);

  static BuiltSet<AuditActionType> get values => _$values;
  static AuditActionType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class AuditActionTypeMixin = Object with _$AuditActionTypeMixin;

