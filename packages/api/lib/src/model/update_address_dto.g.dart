// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_address_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateAddressDto extends UpdateAddressDto {
  @override
  final String? label;
  @override
  final String? address;
  @override
  final BuiltList<num>? location;
  @override
  final String? details;
  @override
  final bool? isDefault;

  factory _$UpdateAddressDto([
    void Function(UpdateAddressDtoBuilder)? updates,
  ]) => (UpdateAddressDtoBuilder()..update(updates))._build();

  _$UpdateAddressDto._({
    this.label,
    this.address,
    this.location,
    this.details,
    this.isDefault,
  }) : super._();
  @override
  UpdateAddressDto rebuild(void Function(UpdateAddressDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateAddressDtoBuilder toBuilder() =>
      UpdateAddressDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateAddressDto &&
        label == other.label &&
        address == other.address &&
        location == other.location &&
        details == other.details &&
        isDefault == other.isDefault;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, label.hashCode);
    _$hash = $jc(_$hash, address.hashCode);
    _$hash = $jc(_$hash, location.hashCode);
    _$hash = $jc(_$hash, details.hashCode);
    _$hash = $jc(_$hash, isDefault.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateAddressDto')
          ..add('label', label)
          ..add('address', address)
          ..add('location', location)
          ..add('details', details)
          ..add('isDefault', isDefault))
        .toString();
  }
}

class UpdateAddressDtoBuilder
    implements Builder<UpdateAddressDto, UpdateAddressDtoBuilder> {
  _$UpdateAddressDto? _$v;

  String? _label;
  String? get label => _$this._label;
  set label(String? label) => _$this._label = label;

  String? _address;
  String? get address => _$this._address;
  set address(String? address) => _$this._address = address;

  ListBuilder<num>? _location;
  ListBuilder<num> get location => _$this._location ??= ListBuilder<num>();
  set location(ListBuilder<num>? location) => _$this._location = location;

  String? _details;
  String? get details => _$this._details;
  set details(String? details) => _$this._details = details;

  bool? _isDefault;
  bool? get isDefault => _$this._isDefault;
  set isDefault(bool? isDefault) => _$this._isDefault = isDefault;

  UpdateAddressDtoBuilder() {
    UpdateAddressDto._defaults(this);
  }

  UpdateAddressDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _label = $v.label;
      _address = $v.address;
      _location = $v.location?.toBuilder();
      _details = $v.details;
      _isDefault = $v.isDefault;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateAddressDto other) {
    _$v = other as _$UpdateAddressDto;
  }

  @override
  void update(void Function(UpdateAddressDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateAddressDto build() => _build();

  _$UpdateAddressDto _build() {
    _$UpdateAddressDto _$result;
    try {
      _$result =
          _$v ??
          _$UpdateAddressDto._(
            label: label,
            address: address,
            location: _location?.build(),
            details: details,
            isDefault: isDefault,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'location';
        _location?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateAddressDto',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
