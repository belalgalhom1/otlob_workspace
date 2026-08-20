// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'language.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const Language _$EN = const Language._('EN');
const Language _$AR = const Language._('AR');

Language _$valueOf(String name) {
  switch (name) {
    case 'EN':
      return _$EN;
    case 'AR':
      return _$AR;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<Language> _$values = BuiltSet<Language>(const <Language>[
  _$EN,
  _$AR,
]);

class _$LanguageMeta {
  const _$LanguageMeta();
  Language get EN => _$EN;
  Language get AR => _$AR;
  Language valueOf(String name) => _$valueOf(name);
  BuiltSet<Language> get values => _$values;
}

mixin _$LanguageMixin {
  // ignore: non_constant_identifier_names
  _$LanguageMeta get Language => const _$LanguageMeta();
}

Serializer<Language> _$languageSerializer = _$LanguageSerializer();

class _$LanguageSerializer implements PrimitiveSerializer<Language> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'EN': 'EN',
    'AR': 'AR',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'EN': 'EN',
    'AR': 'AR',
  };

  @override
  final Iterable<Type> types = const <Type>[Language];
  @override
  final String wireName = 'Language';

  @override
  Object serialize(
    Serializers serializers,
    Language object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  Language deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => Language.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
