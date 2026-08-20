// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const VerifyOtpDtoPurposeEnum _$verifyOtpDtoPurposeEnum_VERIFICATION =
    const VerifyOtpDtoPurposeEnum._('VERIFICATION');
const VerifyOtpDtoPurposeEnum _$verifyOtpDtoPurposeEnum_PASSWORD_RESET =
    const VerifyOtpDtoPurposeEnum._('PASSWORD_RESET');

VerifyOtpDtoPurposeEnum _$verifyOtpDtoPurposeEnumValueOf(String name) {
  switch (name) {
    case 'VERIFICATION':
      return _$verifyOtpDtoPurposeEnum_VERIFICATION;
    case 'PASSWORD_RESET':
      return _$verifyOtpDtoPurposeEnum_PASSWORD_RESET;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<VerifyOtpDtoPurposeEnum> _$verifyOtpDtoPurposeEnumValues =
    BuiltSet<VerifyOtpDtoPurposeEnum>(const <VerifyOtpDtoPurposeEnum>[
      _$verifyOtpDtoPurposeEnum_VERIFICATION,
      _$verifyOtpDtoPurposeEnum_PASSWORD_RESET,
    ]);

Serializer<VerifyOtpDtoPurposeEnum> _$verifyOtpDtoPurposeEnumSerializer =
    _$VerifyOtpDtoPurposeEnumSerializer();

class _$VerifyOtpDtoPurposeEnumSerializer
    implements PrimitiveSerializer<VerifyOtpDtoPurposeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'VERIFICATION': 'VERIFICATION',
    'PASSWORD_RESET': 'PASSWORD_RESET',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'VERIFICATION': 'VERIFICATION',
    'PASSWORD_RESET': 'PASSWORD_RESET',
  };

  @override
  final Iterable<Type> types = const <Type>[VerifyOtpDtoPurposeEnum];
  @override
  final String wireName = 'VerifyOtpDtoPurposeEnum';

  @override
  Object serialize(
    Serializers serializers,
    VerifyOtpDtoPurposeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  VerifyOtpDtoPurposeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => VerifyOtpDtoPurposeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$VerifyOtpDto extends VerifyOtpDto {
  @override
  final String contact;
  @override
  final String code;
  @override
  final VerifyOtpDtoPurposeEnum? purpose;

  factory _$VerifyOtpDto([void Function(VerifyOtpDtoBuilder)? updates]) =>
      (VerifyOtpDtoBuilder()..update(updates))._build();

  _$VerifyOtpDto._({required this.contact, required this.code, this.purpose})
    : super._();
  @override
  VerifyOtpDto rebuild(void Function(VerifyOtpDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VerifyOtpDtoBuilder toBuilder() => VerifyOtpDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VerifyOtpDto &&
        contact == other.contact &&
        code == other.code &&
        purpose == other.purpose;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, contact.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, purpose.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VerifyOtpDto')
          ..add('contact', contact)
          ..add('code', code)
          ..add('purpose', purpose))
        .toString();
  }
}

class VerifyOtpDtoBuilder
    implements Builder<VerifyOtpDto, VerifyOtpDtoBuilder> {
  _$VerifyOtpDto? _$v;

  String? _contact;
  String? get contact => _$this._contact;
  set contact(String? contact) => _$this._contact = contact;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  VerifyOtpDtoPurposeEnum? _purpose;
  VerifyOtpDtoPurposeEnum? get purpose => _$this._purpose;
  set purpose(VerifyOtpDtoPurposeEnum? purpose) => _$this._purpose = purpose;

  VerifyOtpDtoBuilder() {
    VerifyOtpDto._defaults(this);
  }

  VerifyOtpDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _contact = $v.contact;
      _code = $v.code;
      _purpose = $v.purpose;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VerifyOtpDto other) {
    _$v = other as _$VerifyOtpDto;
  }

  @override
  void update(void Function(VerifyOtpDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VerifyOtpDto build() => _build();

  _$VerifyOtpDto _build() {
    final _$result =
        _$v ??
        _$VerifyOtpDto._(
          contact: BuiltValueNullFieldError.checkNotNull(
            contact,
            r'VerifyOtpDto',
            'contact',
          ),
          code: BuiltValueNullFieldError.checkNotNull(
            code,
            r'VerifyOtpDto',
            'code',
          ),
          purpose: purpose,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
