// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_otp_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SendOtpDtoMethodEnum _$sendOtpDtoMethodEnum_EMAIL =
    const SendOtpDtoMethodEnum._('EMAIL');
const SendOtpDtoMethodEnum _$sendOtpDtoMethodEnum_SMS =
    const SendOtpDtoMethodEnum._('SMS');

SendOtpDtoMethodEnum _$sendOtpDtoMethodEnumValueOf(String name) {
  switch (name) {
    case 'EMAIL':
      return _$sendOtpDtoMethodEnum_EMAIL;
    case 'SMS':
      return _$sendOtpDtoMethodEnum_SMS;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SendOtpDtoMethodEnum> _$sendOtpDtoMethodEnumValues =
    BuiltSet<SendOtpDtoMethodEnum>(const <SendOtpDtoMethodEnum>[
      _$sendOtpDtoMethodEnum_EMAIL,
      _$sendOtpDtoMethodEnum_SMS,
    ]);

Serializer<SendOtpDtoMethodEnum> _$sendOtpDtoMethodEnumSerializer =
    _$SendOtpDtoMethodEnumSerializer();

class _$SendOtpDtoMethodEnumSerializer
    implements PrimitiveSerializer<SendOtpDtoMethodEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'EMAIL': 'EMAIL',
    'SMS': 'SMS',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'EMAIL': 'EMAIL',
    'SMS': 'SMS',
  };

  @override
  final Iterable<Type> types = const <Type>[SendOtpDtoMethodEnum];
  @override
  final String wireName = 'SendOtpDtoMethodEnum';

  @override
  Object serialize(
    Serializers serializers,
    SendOtpDtoMethodEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SendOtpDtoMethodEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SendOtpDtoMethodEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$SendOtpDto extends SendOtpDto {
  @override
  final String contact;
  @override
  final SendOtpDtoMethodEnum method;

  factory _$SendOtpDto([void Function(SendOtpDtoBuilder)? updates]) =>
      (SendOtpDtoBuilder()..update(updates))._build();

  _$SendOtpDto._({required this.contact, required this.method}) : super._();
  @override
  SendOtpDto rebuild(void Function(SendOtpDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SendOtpDtoBuilder toBuilder() => SendOtpDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SendOtpDto &&
        contact == other.contact &&
        method == other.method;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, contact.hashCode);
    _$hash = $jc(_$hash, method.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SendOtpDto')
          ..add('contact', contact)
          ..add('method', method))
        .toString();
  }
}

class SendOtpDtoBuilder implements Builder<SendOtpDto, SendOtpDtoBuilder> {
  _$SendOtpDto? _$v;

  String? _contact;
  String? get contact => _$this._contact;
  set contact(String? contact) => _$this._contact = contact;

  SendOtpDtoMethodEnum? _method;
  SendOtpDtoMethodEnum? get method => _$this._method;
  set method(SendOtpDtoMethodEnum? method) => _$this._method = method;

  SendOtpDtoBuilder() {
    SendOtpDto._defaults(this);
  }

  SendOtpDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _contact = $v.contact;
      _method = $v.method;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SendOtpDto other) {
    _$v = other as _$SendOtpDto;
  }

  @override
  void update(void Function(SendOtpDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SendOtpDto build() => _build();

  _$SendOtpDto _build() {
    final _$result =
        _$v ??
        _$SendOtpDto._(
          contact: BuiltValueNullFieldError.checkNotNull(
            contact,
            r'SendOtpDto',
            'contact',
          ),
          method: BuiltValueNullFieldError.checkNotNull(
            method,
            r'SendOtpDto',
            'method',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
