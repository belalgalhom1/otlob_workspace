// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_platform.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DevicePlatform _$ANDROID = const DevicePlatform._('ANDROID');
const DevicePlatform _$IOS = const DevicePlatform._('IOS');
const DevicePlatform _$WEB = const DevicePlatform._('WEB');

DevicePlatform _$valueOf(String name) {
  switch (name) {
    case 'ANDROID':
      return _$ANDROID;
    case 'IOS':
      return _$IOS;
    case 'WEB':
      return _$WEB;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DevicePlatform> _$values = BuiltSet<DevicePlatform>(
  const <DevicePlatform>[_$ANDROID, _$IOS, _$WEB],
);

class _$DevicePlatformMeta {
  const _$DevicePlatformMeta();
  DevicePlatform get ANDROID => _$ANDROID;
  DevicePlatform get IOS => _$IOS;
  DevicePlatform get WEB => _$WEB;
  DevicePlatform valueOf(String name) => _$valueOf(name);
  BuiltSet<DevicePlatform> get values => _$values;
}

mixin _$DevicePlatformMixin {
  // ignore: non_constant_identifier_names
  _$DevicePlatformMeta get DevicePlatform => const _$DevicePlatformMeta();
}

Serializer<DevicePlatform> _$devicePlatformSerializer =
    _$DevicePlatformSerializer();

class _$DevicePlatformSerializer
    implements PrimitiveSerializer<DevicePlatform> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ANDROID': 'ANDROID',
    'IOS': 'IOS',
    'WEB': 'WEB',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ANDROID': 'ANDROID',
    'IOS': 'IOS',
    'WEB': 'WEB',
  };

  @override
  final Iterable<Type> types = const <Type>[DevicePlatform];
  @override
  final String wireName = 'DevicePlatform';

  @override
  Object serialize(
    Serializers serializers,
    DevicePlatform object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DevicePlatform deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DevicePlatform.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
