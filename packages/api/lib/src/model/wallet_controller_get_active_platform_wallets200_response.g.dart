// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_controller_get_active_platform_wallets200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WalletControllerGetActivePlatformWallets200Response
    extends WalletControllerGetActivePlatformWallets200Response {
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

  factory _$WalletControllerGetActivePlatformWallets200Response([
    void Function(WalletControllerGetActivePlatformWallets200ResponseBuilder)?
    updates,
  ]) =>
      (WalletControllerGetActivePlatformWallets200ResponseBuilder()
            ..update(updates))
          ._build();

  _$WalletControllerGetActivePlatformWallets200Response._({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
    required this.timestamp,
  }) : super._();
  @override
  WalletControllerGetActivePlatformWallets200Response rebuild(
    void Function(WalletControllerGetActivePlatformWallets200ResponseBuilder)
    updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WalletControllerGetActivePlatformWallets200ResponseBuilder toBuilder() =>
      WalletControllerGetActivePlatformWallets200ResponseBuilder()
        ..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WalletControllerGetActivePlatformWallets200Response &&
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
            r'WalletControllerGetActivePlatformWallets200Response',
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

class WalletControllerGetActivePlatformWallets200ResponseBuilder
    implements
        Builder<
          WalletControllerGetActivePlatformWallets200Response,
          WalletControllerGetActivePlatformWallets200ResponseBuilder
        >,
        ApiResponseDtoBuilder {
  _$WalletControllerGetActivePlatformWallets200Response? _$v;

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

  WalletControllerGetActivePlatformWallets200ResponseBuilder() {
    WalletControllerGetActivePlatformWallets200Response._defaults(this);
  }

  WalletControllerGetActivePlatformWallets200ResponseBuilder get _$this {
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
    covariant WalletControllerGetActivePlatformWallets200Response other,
  ) {
    _$v = other as _$WalletControllerGetActivePlatformWallets200Response;
  }

  @override
  void update(
    void Function(WalletControllerGetActivePlatformWallets200ResponseBuilder)?
    updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  WalletControllerGetActivePlatformWallets200Response build() => _build();

  _$WalletControllerGetActivePlatformWallets200Response _build() {
    _$WalletControllerGetActivePlatformWallets200Response _$result;
    try {
      _$result =
          _$v ??
          _$WalletControllerGetActivePlatformWallets200Response._(
            success: BuiltValueNullFieldError.checkNotNull(
              success,
              r'WalletControllerGetActivePlatformWallets200Response',
              'success',
            ),
            statusCode: BuiltValueNullFieldError.checkNotNull(
              statusCode,
              r'WalletControllerGetActivePlatformWallets200Response',
              'statusCode',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'WalletControllerGetActivePlatformWallets200Response',
              'message',
            ),
            data: data,
            errors: _errors?.build(),
            timestamp: BuiltValueNullFieldError.checkNotNull(
              timestamp,
              r'WalletControllerGetActivePlatformWallets200Response',
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
          r'WalletControllerGetActivePlatformWallets200Response',
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
