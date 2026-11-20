// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_delivery_incident_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateDeliveryIncidentDto extends UpdateDeliveryIncidentDto {
  @override
  final DeliveryIncidentResponsibility responsibility;
  @override
  final String? reviewNote;

  factory _$UpdateDeliveryIncidentDto([
    void Function(UpdateDeliveryIncidentDtoBuilder)? updates,
  ]) => (UpdateDeliveryIncidentDtoBuilder()..update(updates))._build();

  _$UpdateDeliveryIncidentDto._({required this.responsibility, this.reviewNote})
    : super._();
  @override
  UpdateDeliveryIncidentDto rebuild(
    void Function(UpdateDeliveryIncidentDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateDeliveryIncidentDtoBuilder toBuilder() =>
      UpdateDeliveryIncidentDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateDeliveryIncidentDto &&
        responsibility == other.responsibility &&
        reviewNote == other.reviewNote;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, responsibility.hashCode);
    _$hash = $jc(_$hash, reviewNote.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateDeliveryIncidentDto')
          ..add('responsibility', responsibility)
          ..add('reviewNote', reviewNote))
        .toString();
  }
}

class UpdateDeliveryIncidentDtoBuilder
    implements
        Builder<UpdateDeliveryIncidentDto, UpdateDeliveryIncidentDtoBuilder> {
  _$UpdateDeliveryIncidentDto? _$v;

  DeliveryIncidentResponsibility? _responsibility;
  DeliveryIncidentResponsibility? get responsibility => _$this._responsibility;
  set responsibility(DeliveryIncidentResponsibility? responsibility) =>
      _$this._responsibility = responsibility;

  String? _reviewNote;
  String? get reviewNote => _$this._reviewNote;
  set reviewNote(String? reviewNote) => _$this._reviewNote = reviewNote;

  UpdateDeliveryIncidentDtoBuilder() {
    UpdateDeliveryIncidentDto._defaults(this);
  }

  UpdateDeliveryIncidentDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _responsibility = $v.responsibility;
      _reviewNote = $v.reviewNote;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateDeliveryIncidentDto other) {
    _$v = other as _$UpdateDeliveryIncidentDto;
  }

  @override
  void update(void Function(UpdateDeliveryIncidentDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateDeliveryIncidentDto build() => _build();

  _$UpdateDeliveryIncidentDto _build() {
    final _$result =
        _$v ??
        _$UpdateDeliveryIncidentDto._(
          responsibility: BuiltValueNullFieldError.checkNotNull(
            responsibility,
            r'UpdateDeliveryIncidentDto',
            'responsibility',
          ),
          reviewNote: reviewNote,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
