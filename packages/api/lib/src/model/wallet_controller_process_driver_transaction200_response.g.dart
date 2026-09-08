// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_controller_process_driver_transaction200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WalletControllerProcessDriverTransaction200Response
    extends WalletControllerProcessDriverTransaction200Response {
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

  factory _$WalletControllerProcessDriverTransaction200Response([
    void Function(WalletControllerProcessDriverTransaction200ResponseBuilder)?
    updates,
  ]) =>
      (WalletControllerProcessDriverTransaction200ResponseBuilder()
            ..update(updates))
          ._build();

  _$WalletControllerProcessDriverTransaction200Response._({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
    required this.timestamp,
  }) : super._();
  @override
  WalletControllerProcessDriverTransaction200Response rebuild(
    void Function(WalletControllerProcessDriverTransaction200ResponseBuilder)
    updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WalletControllerProcessDriverTransaction200ResponseBuilder toBuilder() =>
      WalletControllerProcessDriverTransaction200ResponseBuilder()
        ..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WalletControllerProcessDriverTransaction200Response &&
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
    return (newBuiltValueToStringHelper(
            r'WalletControllerProcessDriverTransaction200Response',
          )
          ..add('success', success)
          ..add('statusCode', statusCode)
          ..add('message', message)
          ..add('data', data)
          ..add('errors', errors)
          ..add('timestamp', timestamp))
        .toString();
  }
}

class WalletControllerProcessDriverTransaction200ResponseBuilder
    implements
        Builder<
          WalletControllerProcessDriverTransaction200Response,
          WalletControllerProcessDriverTransaction200ResponseBuilder
        >,
        ApiResponseDtoBuilder {
  _$WalletControllerProcessDriverTransaction200Response? _$v;

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

  WalletControllerProcessDriverTransaction200ResponseBuilder() {
    WalletControllerProcessDriverTransaction200Response._defaults(this);
  }

  WalletControllerProcessDriverTransaction200ResponseBuilder get _$this {
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
  void replace(
    covariant WalletControllerProcessDriverTransaction200Response other,
  ) {
    _$v = other as _$WalletControllerProcessDriverTransaction200Response;
  }

  @override
  void update(
    void Function(WalletControllerProcessDriverTransaction200ResponseBuilder)?
    updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  WalletControllerProcessDriverTransaction200Response build() => _build();

  _$WalletControllerProcessDriverTransaction200Response _build() {
    _$WalletControllerProcessDriverTransaction200Response _$result;
    try {
      _$result =
          _$v ??
          _$WalletControllerProcessDriverTransaction200Response._(
            success: BuiltValueNullFieldError.checkNotNull(
              success,
              r'WalletControllerProcessDriverTransaction200Response',
              'success',
            ),
            statusCode: BuiltValueNullFieldError.checkNotNull(
              statusCode,
              r'WalletControllerProcessDriverTransaction200Response',
              'statusCode',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'WalletControllerProcessDriverTransaction200Response',
              'message',
            ),
            data: data,
            errors: _errors?.build(),
            timestamp: BuiltValueNullFieldError.checkNotNull(
              timestamp,
              r'WalletControllerProcessDriverTransaction200Response',
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
          r'WalletControllerProcessDriverTransaction200Response',
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
