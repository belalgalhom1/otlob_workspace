// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_controller_list200_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotificationsControllerList200Response
    extends NotificationsControllerList200Response {
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

  factory _$NotificationsControllerList200Response([
    void Function(NotificationsControllerList200ResponseBuilder)? updates,
  ]) => (NotificationsControllerList200ResponseBuilder()..update(updates))
      ._build();

  _$NotificationsControllerList200Response._({
    required this.success,
    required this.statusCode,
    required this.message,
    this.data,
    this.errors,
    required this.timestamp,
  }) : super._();
  @override
  NotificationsControllerList200Response rebuild(
    void Function(NotificationsControllerList200ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotificationsControllerList200ResponseBuilder toBuilder() =>
      NotificationsControllerList200ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotificationsControllerList200Response &&
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
            r'NotificationsControllerList200Response',
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

class NotificationsControllerList200ResponseBuilder
    implements
        Builder<
          NotificationsControllerList200Response,
          NotificationsControllerList200ResponseBuilder
        >,
        ApiResponseDtoBuilder {
  _$NotificationsControllerList200Response? _$v;

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

  NotificationsControllerList200ResponseBuilder() {
    NotificationsControllerList200Response._defaults(this);
  }

  NotificationsControllerList200ResponseBuilder get _$this {
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
  void replace(covariant NotificationsControllerList200Response other) {
    _$v = other as _$NotificationsControllerList200Response;
  }

  @override
  void update(
    void Function(NotificationsControllerList200ResponseBuilder)? updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  NotificationsControllerList200Response build() => _build();

  _$NotificationsControllerList200Response _build() {
    _$NotificationsControllerList200Response _$result;
    try {
      _$result =
          _$v ??
          _$NotificationsControllerList200Response._(
            success: BuiltValueNullFieldError.checkNotNull(
              success,
              r'NotificationsControllerList200Response',
              'success',
            ),
            statusCode: BuiltValueNullFieldError.checkNotNull(
              statusCode,
              r'NotificationsControllerList200Response',
              'statusCode',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'NotificationsControllerList200Response',
              'message',
            ),
            data: data,
            errors: _errors?.build(),
            timestamp: BuiltValueNullFieldError.checkNotNull(
              timestamp,
              r'NotificationsControllerList200Response',
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
          r'NotificationsControllerList200Response',
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
