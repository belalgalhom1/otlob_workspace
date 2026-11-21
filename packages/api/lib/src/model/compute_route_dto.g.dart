// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compute_route_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ComputeRouteDto extends ComputeRouteDto {
  @override
  final BuiltList<RouteCoordinateDto> waypoints;

  factory _$ComputeRouteDto([void Function(ComputeRouteDtoBuilder)? updates]) =>
      (ComputeRouteDtoBuilder()..update(updates))._build();

  _$ComputeRouteDto._({required this.waypoints}) : super._();
  @override
  ComputeRouteDto rebuild(void Function(ComputeRouteDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ComputeRouteDtoBuilder toBuilder() => ComputeRouteDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ComputeRouteDto && waypoints == other.waypoints;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, waypoints.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'ComputeRouteDto',
    )..add('waypoints', waypoints)).toString();
  }
}

class ComputeRouteDtoBuilder
    implements Builder<ComputeRouteDto, ComputeRouteDtoBuilder> {
  _$ComputeRouteDto? _$v;

  ListBuilder<RouteCoordinateDto>? _waypoints;
  ListBuilder<RouteCoordinateDto> get waypoints =>
      _$this._waypoints ??= ListBuilder<RouteCoordinateDto>();
  set waypoints(ListBuilder<RouteCoordinateDto>? waypoints) =>
      _$this._waypoints = waypoints;

  ComputeRouteDtoBuilder() {
    ComputeRouteDto._defaults(this);
  }

  ComputeRouteDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _waypoints = $v.waypoints.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ComputeRouteDto other) {
    _$v = other as _$ComputeRouteDto;
  }

  @override
  void update(void Function(ComputeRouteDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ComputeRouteDto build() => _build();

  _$ComputeRouteDto _build() {
    _$ComputeRouteDto _$result;
    try {
      _$result = _$v ?? _$ComputeRouteDto._(waypoints: waypoints.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'waypoints';
        waypoints.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ComputeRouteDto',
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
