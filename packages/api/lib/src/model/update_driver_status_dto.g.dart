// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_driver_status_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateDriverStatusDtoStatusEnum _$updateDriverStatusDtoStatusEnum_ONLINE =
    const UpdateDriverStatusDtoStatusEnum._('ONLINE');
const UpdateDriverStatusDtoStatusEnum
_$updateDriverStatusDtoStatusEnum_OFFLINE =
    const UpdateDriverStatusDtoStatusEnum._('OFFLINE');

UpdateDriverStatusDtoStatusEnum _$updateDriverStatusDtoStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'ONLINE':
      return _$updateDriverStatusDtoStatusEnum_ONLINE;
    case 'OFFLINE':
      return _$updateDriverStatusDtoStatusEnum_OFFLINE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateDriverStatusDtoStatusEnum>
_$updateDriverStatusDtoStatusEnumValues =
    BuiltSet<UpdateDriverStatusDtoStatusEnum>(
      const <UpdateDriverStatusDtoStatusEnum>[
        _$updateDriverStatusDtoStatusEnum_ONLINE,
        _$updateDriverStatusDtoStatusEnum_OFFLINE,
      ],
    );

Serializer<UpdateDriverStatusDtoStatusEnum>
_$updateDriverStatusDtoStatusEnumSerializer =
    _$UpdateDriverStatusDtoStatusEnumSerializer();

class _$UpdateDriverStatusDtoStatusEnumSerializer
    implements PrimitiveSerializer<UpdateDriverStatusDtoStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ONLINE': 'ONLINE',
    'OFFLINE': 'OFFLINE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ONLINE': 'ONLINE',
    'OFFLINE': 'OFFLINE',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateDriverStatusDtoStatusEnum];
  @override
  final String wireName = 'UpdateDriverStatusDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateDriverStatusDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateDriverStatusDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateDriverStatusDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateDriverStatusDto extends UpdateDriverStatusDto {
  @override
  final UpdateDriverStatusDtoStatusEnum status;

  factory _$UpdateDriverStatusDto([
    void Function(UpdateDriverStatusDtoBuilder)? updates,
  ]) => (UpdateDriverStatusDtoBuilder()..update(updates))._build();

  _$UpdateDriverStatusDto._({required this.status}) : super._();
  @override
  UpdateDriverStatusDto rebuild(
    void Function(UpdateDriverStatusDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateDriverStatusDtoBuilder toBuilder() =>
      UpdateDriverStatusDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateDriverStatusDto && status == other.status;
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
      r'UpdateDriverStatusDto',
    )..add('status', status)).toString();
  }
}

class UpdateDriverStatusDtoBuilder
    implements Builder<UpdateDriverStatusDto, UpdateDriverStatusDtoBuilder> {
  _$UpdateDriverStatusDto? _$v;

  UpdateDriverStatusDtoStatusEnum? _status;
  UpdateDriverStatusDtoStatusEnum? get status => _$this._status;
  set status(UpdateDriverStatusDtoStatusEnum? status) =>
      _$this._status = status;

  UpdateDriverStatusDtoBuilder() {
    UpdateDriverStatusDto._defaults(this);
  }

  UpdateDriverStatusDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateDriverStatusDto other) {
    _$v = other as _$UpdateDriverStatusDto;
  }

  @override
  void update(void Function(UpdateDriverStatusDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateDriverStatusDto build() => _build();

  _$UpdateDriverStatusDto _build() {
    final _$result =
        _$v ??
        _$UpdateDriverStatusDto._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'UpdateDriverStatusDto',
            'status',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
