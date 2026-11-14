// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'respond_assist_offer_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RespondAssistOfferDto extends RespondAssistOfferDto {
  @override
  final bool accept;

  factory _$RespondAssistOfferDto([
    void Function(RespondAssistOfferDtoBuilder)? updates,
  ]) => (RespondAssistOfferDtoBuilder()..update(updates))._build();

  _$RespondAssistOfferDto._({required this.accept}) : super._();
  @override
  RespondAssistOfferDto rebuild(
    void Function(RespondAssistOfferDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RespondAssistOfferDtoBuilder toBuilder() =>
      RespondAssistOfferDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RespondAssistOfferDto && accept == other.accept;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accept.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'RespondAssistOfferDto',
    )..add('accept', accept)).toString();
  }
}

class RespondAssistOfferDtoBuilder
    implements Builder<RespondAssistOfferDto, RespondAssistOfferDtoBuilder> {
  _$RespondAssistOfferDto? _$v;

  bool? _accept;
  bool? get accept => _$this._accept;
  set accept(bool? accept) => _$this._accept = accept;

  RespondAssistOfferDtoBuilder() {
    RespondAssistOfferDto._defaults(this);
  }

  RespondAssistOfferDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accept = $v.accept;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RespondAssistOfferDto other) {
    _$v = other as _$RespondAssistOfferDto;
  }

  @override
  void update(void Function(RespondAssistOfferDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RespondAssistOfferDto build() => _build();

  _$RespondAssistOfferDto _build() {
    final _$result =
        _$v ??
        _$RespondAssistOfferDto._(
          accept: BuiltValueNullFieldError.checkNotNull(
            accept,
            r'RespondAssistOfferDto',
            'accept',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
