// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_mobile_wallet_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateMobileWalletDtoTypeEnum _$createMobileWalletDtoTypeEnum_VODAFONE =
    const CreateMobileWalletDtoTypeEnum._('VODAFONE');
const CreateMobileWalletDtoTypeEnum _$createMobileWalletDtoTypeEnum_ORANGE =
    const CreateMobileWalletDtoTypeEnum._('ORANGE');
const CreateMobileWalletDtoTypeEnum _$createMobileWalletDtoTypeEnum_WE =
    const CreateMobileWalletDtoTypeEnum._('WE');
const CreateMobileWalletDtoTypeEnum _$createMobileWalletDtoTypeEnum_ETISALAT =
    const CreateMobileWalletDtoTypeEnum._('ETISALAT');
const CreateMobileWalletDtoTypeEnum _$createMobileWalletDtoTypeEnum_INSTAPAY =
    const CreateMobileWalletDtoTypeEnum._('INSTAPAY');

CreateMobileWalletDtoTypeEnum _$createMobileWalletDtoTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'VODAFONE':
      return _$createMobileWalletDtoTypeEnum_VODAFONE;
    case 'ORANGE':
      return _$createMobileWalletDtoTypeEnum_ORANGE;
    case 'WE':
      return _$createMobileWalletDtoTypeEnum_WE;
    case 'ETISALAT':
      return _$createMobileWalletDtoTypeEnum_ETISALAT;
    case 'INSTAPAY':
      return _$createMobileWalletDtoTypeEnum_INSTAPAY;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateMobileWalletDtoTypeEnum>
_$createMobileWalletDtoTypeEnumValues = BuiltSet<CreateMobileWalletDtoTypeEnum>(
  const <CreateMobileWalletDtoTypeEnum>[
    _$createMobileWalletDtoTypeEnum_VODAFONE,
    _$createMobileWalletDtoTypeEnum_ORANGE,
    _$createMobileWalletDtoTypeEnum_WE,
    _$createMobileWalletDtoTypeEnum_ETISALAT,
    _$createMobileWalletDtoTypeEnum_INSTAPAY,
  ],
);

Serializer<CreateMobileWalletDtoTypeEnum>
_$createMobileWalletDtoTypeEnumSerializer =
    _$CreateMobileWalletDtoTypeEnumSerializer();

class _$CreateMobileWalletDtoTypeEnumSerializer
    implements PrimitiveSerializer<CreateMobileWalletDtoTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'VODAFONE': 'VODAFONE',
    'ORANGE': 'ORANGE',
    'WE': 'WE',
    'ETISALAT': 'ETISALAT',
    'INSTAPAY': 'INSTAPAY',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'VODAFONE': 'VODAFONE',
    'ORANGE': 'ORANGE',
    'WE': 'WE',
    'ETISALAT': 'ETISALAT',
    'INSTAPAY': 'INSTAPAY',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateMobileWalletDtoTypeEnum];
  @override
  final String wireName = 'CreateMobileWalletDtoTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateMobileWalletDtoTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateMobileWalletDtoTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateMobileWalletDtoTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateMobileWalletDto extends CreateMobileWalletDto {
  @override
  final String number;
  @override
  final CreateMobileWalletDtoTypeEnum type;
  @override
  final bool? isActive;

  factory _$CreateMobileWalletDto([
    void Function(CreateMobileWalletDtoBuilder)? updates,
  ]) => (CreateMobileWalletDtoBuilder()..update(updates))._build();

  _$CreateMobileWalletDto._({
    required this.number,
    required this.type,
    this.isActive,
  }) : super._();
  @override
  CreateMobileWalletDto rebuild(
    void Function(CreateMobileWalletDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateMobileWalletDtoBuilder toBuilder() =>
      CreateMobileWalletDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateMobileWalletDto &&
        number == other.number &&
        type == other.type &&
        isActive == other.isActive;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, number.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateMobileWalletDto')
          ..add('number', number)
          ..add('type', type)
          ..add('isActive', isActive))
        .toString();
  }
}

class CreateMobileWalletDtoBuilder
    implements Builder<CreateMobileWalletDto, CreateMobileWalletDtoBuilder> {
  _$CreateMobileWalletDto? _$v;

  String? _number;
  String? get number => _$this._number;
  set number(String? number) => _$this._number = number;

  CreateMobileWalletDtoTypeEnum? _type;
  CreateMobileWalletDtoTypeEnum? get type => _$this._type;
  set type(CreateMobileWalletDtoTypeEnum? type) => _$this._type = type;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  CreateMobileWalletDtoBuilder() {
    CreateMobileWalletDto._defaults(this);
  }

  CreateMobileWalletDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _number = $v.number;
      _type = $v.type;
      _isActive = $v.isActive;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateMobileWalletDto other) {
    _$v = other as _$CreateMobileWalletDto;
  }

  @override
  void update(void Function(CreateMobileWalletDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateMobileWalletDto build() => _build();

  _$CreateMobileWalletDto _build() {
    final _$result =
        _$v ??
        _$CreateMobileWalletDto._(
          number: BuiltValueNullFieldError.checkNotNull(
            number,
            r'CreateMobileWalletDto',
            'number',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'CreateMobileWalletDto',
            'type',
          ),
          isActive: isActive,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
