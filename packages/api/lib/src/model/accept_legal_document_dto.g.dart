// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_legal_document_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcceptLegalDocumentDto extends AcceptLegalDocumentDto {
  @override
  final String documentId;
  @override
  final String version;

  factory _$AcceptLegalDocumentDto([
    void Function(AcceptLegalDocumentDtoBuilder)? updates,
  ]) => (AcceptLegalDocumentDtoBuilder()..update(updates))._build();

  _$AcceptLegalDocumentDto._({required this.documentId, required this.version})
    : super._();
  @override
  AcceptLegalDocumentDto rebuild(
    void Function(AcceptLegalDocumentDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AcceptLegalDocumentDtoBuilder toBuilder() =>
      AcceptLegalDocumentDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcceptLegalDocumentDto &&
        documentId == other.documentId &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, documentId.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcceptLegalDocumentDto')
          ..add('documentId', documentId)
          ..add('version', version))
        .toString();
  }
}

class AcceptLegalDocumentDtoBuilder
    implements Builder<AcceptLegalDocumentDto, AcceptLegalDocumentDtoBuilder> {
  _$AcceptLegalDocumentDto? _$v;

  String? _documentId;
  String? get documentId => _$this._documentId;
  set documentId(String? documentId) => _$this._documentId = documentId;

  String? _version;
  String? get version => _$this._version;
  set version(String? version) => _$this._version = version;

  AcceptLegalDocumentDtoBuilder() {
    AcceptLegalDocumentDto._defaults(this);
  }

  AcceptLegalDocumentDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _documentId = $v.documentId;
      _version = $v.version;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcceptLegalDocumentDto other) {
    _$v = other as _$AcceptLegalDocumentDto;
  }

  @override
  void update(void Function(AcceptLegalDocumentDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcceptLegalDocumentDto build() => _build();

  _$AcceptLegalDocumentDto _build() {
    final _$result =
        _$v ??
        _$AcceptLegalDocumentDto._(
          documentId: BuiltValueNullFieldError.checkNotNull(
            documentId,
            r'AcceptLegalDocumentDto',
            'documentId',
          ),
          version: BuiltValueNullFieldError.checkNotNull(
            version,
            r'AcceptLegalDocumentDto',
            'version',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
