// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

abstract mixin class ApiResponseDtoBuilder {
  void replace(ApiResponseDto other);
  void update(void Function(ApiResponseDtoBuilder) updates);
  bool? get success;
  set success(bool? success);

  num? get statusCode;
  set statusCode(num? statusCode);

  String? get message;
  set message(String? message);

  JsonObject? get data;
  set data(JsonObject? data);

  MapBuilder<String, BuiltList<String>> get errors;
  set errors(MapBuilder<String, BuiltList<String>>? errors);

  String? get timestamp;
  set timestamp(String? timestamp);
}

class _$$ApiResponseDto extends $ApiResponseDto {
  @override
  final bool success;
  @override
  final num statusCode;
  @override
  final String message;
  @override
  final JsonObject? data;
  @override
  final BuiltMap<String, BuiltList<String>>? errors;
  @override
  final String timestamp;

  factory _$$ApiResponseDto([void Function($ApiResponseDtoBuilder)? updates]) =>
      ($ApiResponseDtoBuilder()..update(updates))._build();

  _$$ApiResponseDto._({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
    required this.timestamp,
  }) : super._();
  @override
  $ApiResponseDto rebuild(void Function($ApiResponseDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  $ApiResponseDtoBuilder toBuilder() => $ApiResponseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is $ApiResponseDto &&
        success == other.success &&
        statusCode == other.statusCode &&
        message == other.message &&
        data == other.data &&
        errors == other.errors &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, success.hashCode);
    _$hash = $jc(_$hash, statusCode.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jc(_$hash, errors.hashCode);
    _$hash = $jc(_$hash, timestamp.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'$ApiResponseDto')
          ..add('success', success)
          ..add('statusCode', statusCode)
          ..add('message', message)
          ..add('data', data)
          ..add('errors', errors)
          ..add('timestamp', timestamp))
        .toString();
  }
}

class $ApiResponseDtoBuilder
    implements
        Builder<$ApiResponseDto, $ApiResponseDtoBuilder>,
        ApiResponseDtoBuilder {
  _$$ApiResponseDto? _$v;

  bool? _success;
  bool? get success => _$this._success;
  set success(covariant bool? success) => _$this._success = success;

  num? _statusCode;
  num? get statusCode => _$this._statusCode;
  set statusCode(covariant num? statusCode) => _$this._statusCode = statusCode;

  String? _message;
  String? get message => _$this._message;
  set message(covariant String? message) => _$this._message = message;

  JsonObject? _data;
  JsonObject? get data => _$this._data;
  set data(covariant JsonObject? data) => _$this._data = data;

  MapBuilder<String, BuiltList<String>>? _errors;
  MapBuilder<String, BuiltList<String>> get errors =>
      _$this._errors ??= MapBuilder<String, BuiltList<String>>();
  set errors(covariant MapBuilder<String, BuiltList<String>>? errors) =>
      _$this._errors = errors;

  String? _timestamp;
  String? get timestamp => _$this._timestamp;
  set timestamp(covariant String? timestamp) => _$this._timestamp = timestamp;

  $ApiResponseDtoBuilder() {
    $ApiResponseDto._defaults(this);
  }

  $ApiResponseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _success = $v.success;
      _statusCode = $v.statusCode;
      _message = $v.message;
      _data = $v.data;
      _errors = $v.errors?.toBuilder();
      _timestamp = $v.timestamp;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant $ApiResponseDto other) {
    _$v = other as _$$ApiResponseDto;
  }

  @override
  void update(void Function($ApiResponseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  $ApiResponseDto build() => _build();

  _$$ApiResponseDto _build() {
    _$$ApiResponseDto _$result;
    try {
      _$result =
          _$v ??
          _$$ApiResponseDto._(
            success: BuiltValueNullFieldError.checkNotNull(
              success,
              r'$ApiResponseDto',
              'success',
            ),
            statusCode: BuiltValueNullFieldError.checkNotNull(
              statusCode,
              r'$ApiResponseDto',
              'statusCode',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'$ApiResponseDto',
              'message',
            ),
            data: data,
            errors: _errors?.build(),
            timestamp: BuiltValueNullFieldError.checkNotNull(
              timestamp,
              r'$ApiResponseDto',
              'timestamp',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'errors';
        _errors?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'$ApiResponseDto',
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
