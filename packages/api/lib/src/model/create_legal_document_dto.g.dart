// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_legal_document_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateLegalDocumentDtoTypeEnum
_$createLegalDocumentDtoTypeEnum_TERMS_OF_USE =
    const CreateLegalDocumentDtoTypeEnum._('TERMS_OF_USE');
const CreateLegalDocumentDtoTypeEnum
_$createLegalDocumentDtoTypeEnum_PRIVACY_POLICY =
    const CreateLegalDocumentDtoTypeEnum._('PRIVACY_POLICY');

CreateLegalDocumentDtoTypeEnum _$createLegalDocumentDtoTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'TERMS_OF_USE':
      return _$createLegalDocumentDtoTypeEnum_TERMS_OF_USE;
    case 'PRIVACY_POLICY':
      return _$createLegalDocumentDtoTypeEnum_PRIVACY_POLICY;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateLegalDocumentDtoTypeEnum>
_$createLegalDocumentDtoTypeEnumValues =
    BuiltSet<CreateLegalDocumentDtoTypeEnum>(
      const <CreateLegalDocumentDtoTypeEnum>[
        _$createLegalDocumentDtoTypeEnum_TERMS_OF_USE,
        _$createLegalDocumentDtoTypeEnum_PRIVACY_POLICY,
      ],
    );

Serializer<CreateLegalDocumentDtoTypeEnum>
_$createLegalDocumentDtoTypeEnumSerializer =
    _$CreateLegalDocumentDtoTypeEnumSerializer();

class _$CreateLegalDocumentDtoTypeEnumSerializer
    implements PrimitiveSerializer<CreateLegalDocumentDtoTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'TERMS_OF_USE': 'TERMS_OF_USE',
    'PRIVACY_POLICY': 'PRIVACY_POLICY',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'TERMS_OF_USE': 'TERMS_OF_USE',
    'PRIVACY_POLICY': 'PRIVACY_POLICY',
  };

  @override
  final Iterable<Type> types = const <Type>[CreateLegalDocumentDtoTypeEnum];
  @override
  final String wireName = 'CreateLegalDocumentDtoTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateLegalDocumentDtoTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateLegalDocumentDtoTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateLegalDocumentDtoTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateLegalDocumentDto extends CreateLegalDocumentDto {
  @override
  final CreateLegalDocumentDtoTypeEnum type;
  @override
  final String title;
  @override
  final String titleAr;
  @override
  final String content;
  @override
  final String contentAr;
  @override
  final String version;

  factory _$CreateLegalDocumentDto([
    void Function(CreateLegalDocumentDtoBuilder)? updates,
  ]) => (CreateLegalDocumentDtoBuilder()..update(updates))._build();

  _$CreateLegalDocumentDto._({
    required this.type,
    required this.title,
    required this.titleAr,
    required this.content,
    required this.contentAr,
    required this.version,
  }) : super._();
  @override
  CreateLegalDocumentDto rebuild(
    void Function(CreateLegalDocumentDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CreateLegalDocumentDtoBuilder toBuilder() =>
      CreateLegalDocumentDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateLegalDocumentDto &&
        type == other.type &&
        title == other.title &&
        titleAr == other.titleAr &&
        content == other.content &&
        contentAr == other.contentAr &&
        version == other.version;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
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
    return (newBuiltValueToStringHelper(r'CreateLegalDocumentDto')
          ..add('type', type)
          ..add('title', title)
          ..add('titleAr', titleAr)
          ..add('content', content)
          ..add('contentAr', contentAr)
          ..add('version', version))
        .toString();
  }
}

class CreateLegalDocumentDtoBuilder
    implements Builder<CreateLegalDocumentDto, CreateLegalDocumentDtoBuilder> {
  _$CreateLegalDocumentDto? _$v;

  CreateLegalDocumentDtoTypeEnum? _type;
  CreateLegalDocumentDtoTypeEnum? get type => _$this._type;
  set type(CreateLegalDocumentDtoTypeEnum? type) => _$this._type = type;

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

  CreateLegalDocumentDtoBuilder() {
    CreateLegalDocumentDto._defaults(this);
  }

  CreateLegalDocumentDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
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
  void replace(CreateLegalDocumentDto other) {
    _$v = other as _$CreateLegalDocumentDto;
  }

  @override
  void update(void Function(CreateLegalDocumentDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateLegalDocumentDto build() => _build();

  _$CreateLegalDocumentDto _build() {
    final _$result =
        _$v ??
        _$CreateLegalDocumentDto._(
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'CreateLegalDocumentDto',
            'type',
          ),
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'CreateLegalDocumentDto',
            'title',
          ),
          titleAr: BuiltValueNullFieldError.checkNotNull(
            titleAr,
            r'CreateLegalDocumentDto',
            'titleAr',
          ),
          content: BuiltValueNullFieldError.checkNotNull(
            content,
            r'CreateLegalDocumentDto',
            'content',
          ),
          contentAr: BuiltValueNullFieldError.checkNotNull(
            contentAr,
            r'CreateLegalDocumentDto',
            'contentAr',
          ),
          version: BuiltValueNullFieldError.checkNotNull(
            version,
            r'CreateLegalDocumentDto',
            'version',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
