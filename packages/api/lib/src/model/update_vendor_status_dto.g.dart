// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_vendor_status_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateVendorStatusDtoStatusEnum _$updateVendorStatusDtoStatusEnum_CLOSED =
    const UpdateVendorStatusDtoStatusEnum._('CLOSED');
const UpdateVendorStatusDtoStatusEnum _$updateVendorStatusDtoStatusEnum_OPEN =
    const UpdateVendorStatusDtoStatusEnum._('OPEN');
const UpdateVendorStatusDtoStatusEnum _$updateVendorStatusDtoStatusEnum_PAUSED =
    const UpdateVendorStatusDtoStatusEnum._('PAUSED');
const UpdateVendorStatusDtoStatusEnum
_$updateVendorStatusDtoStatusEnum_SUSPENDED =
    const UpdateVendorStatusDtoStatusEnum._('SUSPENDED');

UpdateVendorStatusDtoStatusEnum _$updateVendorStatusDtoStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'CLOSED':
      return _$updateVendorStatusDtoStatusEnum_CLOSED;
    case 'OPEN':
      return _$updateVendorStatusDtoStatusEnum_OPEN;
    case 'PAUSED':
      return _$updateVendorStatusDtoStatusEnum_PAUSED;
    case 'SUSPENDED':
      return _$updateVendorStatusDtoStatusEnum_SUSPENDED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateVendorStatusDtoStatusEnum>
_$updateVendorStatusDtoStatusEnumValues =
    BuiltSet<UpdateVendorStatusDtoStatusEnum>(
      const <UpdateVendorStatusDtoStatusEnum>[
        _$updateVendorStatusDtoStatusEnum_CLOSED,
        _$updateVendorStatusDtoStatusEnum_OPEN,
        _$updateVendorStatusDtoStatusEnum_PAUSED,
        _$updateVendorStatusDtoStatusEnum_SUSPENDED,
      ],
    );

Serializer<UpdateVendorStatusDtoStatusEnum>
_$updateVendorStatusDtoStatusEnumSerializer =
    _$UpdateVendorStatusDtoStatusEnumSerializer();

class _$UpdateVendorStatusDtoStatusEnumSerializer
    implements PrimitiveSerializer<UpdateVendorStatusDtoStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CLOSED': 'CLOSED',
    'OPEN': 'OPEN',
    'PAUSED': 'PAUSED',
    'SUSPENDED': 'SUSPENDED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CLOSED': 'CLOSED',
    'OPEN': 'OPEN',
    'PAUSED': 'PAUSED',
    'SUSPENDED': 'SUSPENDED',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateVendorStatusDtoStatusEnum];
  @override
  final String wireName = 'UpdateVendorStatusDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateVendorStatusDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateVendorStatusDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateVendorStatusDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateVendorStatusDto extends UpdateVendorStatusDto {
  @override
  final UpdateVendorStatusDtoStatusEnum status;

  factory _$UpdateVendorStatusDto([
    void Function(UpdateVendorStatusDtoBuilder)? updates,
  ]) => (UpdateVendorStatusDtoBuilder()..update(updates))._build();

  _$UpdateVendorStatusDto._({required this.status}) : super._();
  @override
  UpdateVendorStatusDto rebuild(
    void Function(UpdateVendorStatusDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateVendorStatusDtoBuilder toBuilder() =>
      UpdateVendorStatusDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateVendorStatusDto && status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'UpdateVendorStatusDto',
    )..add('status', status)).toString();
  }
}

class UpdateVendorStatusDtoBuilder
    implements Builder<UpdateVendorStatusDto, UpdateVendorStatusDtoBuilder> {
  _$UpdateVendorStatusDto? _$v;

  UpdateVendorStatusDtoStatusEnum? _status;
  UpdateVendorStatusDtoStatusEnum? get status => _$this._status;
  set status(UpdateVendorStatusDtoStatusEnum? status) =>
      _$this._status = status;

  UpdateVendorStatusDtoBuilder() {
    UpdateVendorStatusDto._defaults(this);
  }

  UpdateVendorStatusDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateVendorStatusDto other) {
    _$v = other as _$UpdateVendorStatusDto;
  }

  @override
  void update(void Function(UpdateVendorStatusDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateVendorStatusDto build() => _build();

  _$UpdateVendorStatusDto _build() {
    final _$result =
        _$v ??
        _$UpdateVendorStatusDto._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'UpdateVendorStatusDto',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
