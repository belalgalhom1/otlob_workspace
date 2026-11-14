// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_legal_document_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UpdateLegalDocumentDto extends UpdateLegalDocumentDto {
  @override
  final String? title;
  @override
  final String? titleAr;
  @override
  final String? content;
  @override
  final String? contentAr;
  @override
  final String? version;

  factory _$UpdateLegalDocumentDto([
    void Function(UpdateLegalDocumentDtoBuilder)? updates,
  ]) => (UpdateLegalDocumentDtoBuilder()..update(updates))._build();

  _$UpdateLegalDocumentDto._({
    this.title,
    this.titleAr,
    this.content,
    this.contentAr,
    this.version,
  }) : super._();
  @override
  UpdateLegalDocumentDto rebuild(
    void Function(UpdateLegalDocumentDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdateLegalDocumentDtoBuilder toBuilder() =>
      UpdateLegalDocumentDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateLegalDocumentDto &&
        title == other.title &&
        titleAr == other.titleAr &&
        content == other.content &&
        contentAr == other.contentAr &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, titleAr.hashCode);
    _$hash = $jc(_$hash, content.hashCode);
    _$hash = $jc(_$hash, contentAr.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateLegalDocumentDto')
          ..add('title', title)
          ..add('titleAr', titleAr)
          ..add('content', content)
          ..add('contentAr', contentAr)
          ..add('version', version))
        .toString();
  }
}

class UpdateLegalDocumentDtoBuilder
    implements Builder<UpdateLegalDocumentDto, UpdateLegalDocumentDtoBuilder> {
  _$UpdateLegalDocumentDto? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _titleAr;
  String? get titleAr => _$this._titleAr;
  set titleAr(String? titleAr) => _$this._titleAr = titleAr;

  String? _content;
  String? get content => _$this._content;
  set content(String? content) => _$this._content = content;

  String? _contentAr;
  String? get contentAr => _$this._contentAr;
  set contentAr(String? contentAr) => _$this._contentAr = contentAr;

  String? _version;
  String? get version => _$this._version;
  set version(String? version) => _$this._version = version;

  UpdateLegalDocumentDtoBuilder() {
    UpdateLegalDocumentDto._defaults(this);
  }

  UpdateLegalDocumentDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _titleAr = $v.titleAr;
      _content = $v.content;
      _contentAr = $v.contentAr;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateLegalDocumentDto other) {
    _$v = other as _$UpdateLegalDocumentDto;
  }

  @override
  void update(void Function(UpdateLegalDocumentDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateLegalDocumentDto build() => _build();

  _$UpdateLegalDocumentDto _build() {
    final _$result =
        _$v ??
        _$UpdateLegalDocumentDto._(
          title: title,
          titleAr: titleAr,
          content: content,
          contentAr: contentAr,
          version: version,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
