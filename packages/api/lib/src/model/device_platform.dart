//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'device_platform.g.dart';

class DevicePlatform extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ANDROID')
  static const DevicePlatform ANDROID = _$ANDROID;
  @BuiltValueEnumConst(wireName: r'IOS')
  static const DevicePlatform IOS = _$IOS;
  @BuiltValueEnumConst(wireName: r'WEB')
  static const DevicePlatform WEB = _$WEB;

  static Serializer<DevicePlatform> get serializer => _$devicePlatformSerializer;

  const DevicePlatform._(String name): super(name);

  static BuiltSet<DevicePlatform> get values => _$values;
  static DevicePlatform valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class DevicePlatformMixin = Object with _$DevicePlatformMixin;

