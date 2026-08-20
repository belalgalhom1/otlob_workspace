// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispatch_announcement_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DispatchAnnouncementDtoAudienceEnum
_$dispatchAnnouncementDtoAudienceEnum_CUSTOMERS =
    const DispatchAnnouncementDtoAudienceEnum._('CUSTOMERS');
const DispatchAnnouncementDtoAudienceEnum
_$dispatchAnnouncementDtoAudienceEnum_DRIVERS =
    const DispatchAnnouncementDtoAudienceEnum._('DRIVERS');
const DispatchAnnouncementDtoAudienceEnum
_$dispatchAnnouncementDtoAudienceEnum_VENDORS =
    const DispatchAnnouncementDtoAudienceEnum._('VENDORS');
const DispatchAnnouncementDtoAudienceEnum
_$dispatchAnnouncementDtoAudienceEnum_ALL =
    const DispatchAnnouncementDtoAudienceEnum._('ALL');

DispatchAnnouncementDtoAudienceEnum
_$dispatchAnnouncementDtoAudienceEnumValueOf(String name) {
  switch (name) {
    case 'CUSTOMERS':
      return _$dispatchAnnouncementDtoAudienceEnum_CUSTOMERS;
    case 'DRIVERS':
      return _$dispatchAnnouncementDtoAudienceEnum_DRIVERS;
    case 'VENDORS':
      return _$dispatchAnnouncementDtoAudienceEnum_VENDORS;
    case 'ALL':
      return _$dispatchAnnouncementDtoAudienceEnum_ALL;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DispatchAnnouncementDtoAudienceEnum>
_$dispatchAnnouncementDtoAudienceEnumValues =
    BuiltSet<DispatchAnnouncementDtoAudienceEnum>(
      const <DispatchAnnouncementDtoAudienceEnum>[
        _$dispatchAnnouncementDtoAudienceEnum_CUSTOMERS,
        _$dispatchAnnouncementDtoAudienceEnum_DRIVERS,
        _$dispatchAnnouncementDtoAudienceEnum_VENDORS,
        _$dispatchAnnouncementDtoAudienceEnum_ALL,
      ],
    );

const DispatchAnnouncementDtoTypeEnum
_$dispatchAnnouncementDtoTypeEnum_ANNOUNCEMENT =
    const DispatchAnnouncementDtoTypeEnum._('ANNOUNCEMENT');
const DispatchAnnouncementDtoTypeEnum _$dispatchAnnouncementDtoTypeEnum_SYSTEM =
    const DispatchAnnouncementDtoTypeEnum._('SYSTEM');

DispatchAnnouncementDtoTypeEnum _$dispatchAnnouncementDtoTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'ANNOUNCEMENT':
      return _$dispatchAnnouncementDtoTypeEnum_ANNOUNCEMENT;
    case 'SYSTEM':
      return _$dispatchAnnouncementDtoTypeEnum_SYSTEM;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DispatchAnnouncementDtoTypeEnum>
_$dispatchAnnouncementDtoTypeEnumValues =
    BuiltSet<DispatchAnnouncementDtoTypeEnum>(
      const <DispatchAnnouncementDtoTypeEnum>[
        _$dispatchAnnouncementDtoTypeEnum_ANNOUNCEMENT,
        _$dispatchAnnouncementDtoTypeEnum_SYSTEM,
      ],
    );

Serializer<DispatchAnnouncementDtoAudienceEnum>
_$dispatchAnnouncementDtoAudienceEnumSerializer =
    _$DispatchAnnouncementDtoAudienceEnumSerializer();
Serializer<DispatchAnnouncementDtoTypeEnum>
_$dispatchAnnouncementDtoTypeEnumSerializer =
    _$DispatchAnnouncementDtoTypeEnumSerializer();

class _$DispatchAnnouncementDtoAudienceEnumSerializer
    implements PrimitiveSerializer<DispatchAnnouncementDtoAudienceEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'CUSTOMERS': 'CUSTOMERS',
    'DRIVERS': 'DRIVERS',
    'VENDORS': 'VENDORS',
    'ALL': 'ALL',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'CUSTOMERS': 'CUSTOMERS',
    'DRIVERS': 'DRIVERS',
    'VENDORS': 'VENDORS',
    'ALL': 'ALL',
  };

  @override
  final Iterable<Type> types = const <Type>[
    DispatchAnnouncementDtoAudienceEnum,
  ];
  @override
  final String wireName = 'DispatchAnnouncementDtoAudienceEnum';

  @override
  Object serialize(
    Serializers serializers,
    DispatchAnnouncementDtoAudienceEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DispatchAnnouncementDtoAudienceEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DispatchAnnouncementDtoAudienceEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$DispatchAnnouncementDtoTypeEnumSerializer
    implements PrimitiveSerializer<DispatchAnnouncementDtoTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ANNOUNCEMENT': 'ANNOUNCEMENT',
    'SYSTEM': 'SYSTEM',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ANNOUNCEMENT': 'ANNOUNCEMENT',
    'SYSTEM': 'SYSTEM',
  };

  @override
  final Iterable<Type> types = const <Type>[DispatchAnnouncementDtoTypeEnum];
  @override
  final String wireName = 'DispatchAnnouncementDtoTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    DispatchAnnouncementDtoTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DispatchAnnouncementDtoTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DispatchAnnouncementDtoTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$DispatchAnnouncementDto extends DispatchAnnouncementDto {
  @override
  final DispatchAnnouncementDtoAudienceEnum audience;
  @override
  final String title;
  @override
  final String? titleAr;
  @override
  final String body;
  @override
  final String? bodyAr;
  @override
  final JsonObject? data;
  @override
  final DispatchAnnouncementDtoTypeEnum? type;

  factory _$DispatchAnnouncementDto([
    void Function(DispatchAnnouncementDtoBuilder)? updates,
  ]) => (DispatchAnnouncementDtoBuilder()..update(updates))._build();

  _$DispatchAnnouncementDto._({
    required this.audience,
    required this.title,
    this.titleAr,
    required this.body,
    this.bodyAr,
    this.data,
    this.type,
  }) : super._();
  @override
  DispatchAnnouncementDto rebuild(
    void Function(DispatchAnnouncementDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DispatchAnnouncementDtoBuilder toBuilder() =>
      DispatchAnnouncementDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DispatchAnnouncementDto &&
        audience == other.audience &&
        title == other.title &&
        titleAr == other.titleAr &&
        body == other.body &&
        bodyAr == other.bodyAr &&
        data == other.data &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, audience.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, titleAr.hashCode);
    _$hash = $jc(_$hash, body.hashCode);
    _$hash = $jc(_$hash, bodyAr.hashCode);
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DispatchAnnouncementDto')
          ..add('audience', audience)
          ..add('title', title)
          ..add('titleAr', titleAr)
          ..add('body', body)
          ..add('bodyAr', bodyAr)
          ..add('data', data)
          ..add('type', type))
        .toString();
  }
}

class DispatchAnnouncementDtoBuilder
    implements
        Builder<DispatchAnnouncementDto, DispatchAnnouncementDtoBuilder> {
  _$DispatchAnnouncementDto? _$v;

  DispatchAnnouncementDtoAudienceEnum? _audience;
  DispatchAnnouncementDtoAudienceEnum? get audience => _$this._audience;
  set audience(DispatchAnnouncementDtoAudienceEnum? audience) =>
      _$this._audience = audience;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _titleAr;
  String? get titleAr => _$this._titleAr;
  set titleAr(String? titleAr) => _$this._titleAr = titleAr;

  String? _body;
  String? get body => _$this._body;
  set body(String? body) => _$this._body = body;

  String? _bodyAr;
  String? get bodyAr => _$this._bodyAr;
  set bodyAr(String? bodyAr) => _$this._bodyAr = bodyAr;

  JsonObject? _data;
  JsonObject? get data => _$this._data;
  set data(JsonObject? data) => _$this._data = data;

  DispatchAnnouncementDtoTypeEnum? _type;
  DispatchAnnouncementDtoTypeEnum? get type => _$this._type;
  set type(DispatchAnnouncementDtoTypeEnum? type) => _$this._type = type;

  DispatchAnnouncementDtoBuilder() {
    DispatchAnnouncementDto._defaults(this);
  }

  DispatchAnnouncementDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _audience = $v.audience;
      _title = $v.title;
      _titleAr = $v.titleAr;
      _body = $v.body;
      _bodyAr = $v.bodyAr;
      _data = $v.data;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DispatchAnnouncementDto other) {
    _$v = other as _$DispatchAnnouncementDto;
  }

  @override
  void update(void Function(DispatchAnnouncementDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DispatchAnnouncementDto build() => _build();

  _$DispatchAnnouncementDto _build() {
    final _$result =
        _$v ??
        _$DispatchAnnouncementDto._(
          audience: BuiltValueNullFieldError.checkNotNull(
            audience,
            r'DispatchAnnouncementDto',
            'audience',
          ),
          title: BuiltValueNullFieldError.checkNotNull(
            title,
            r'DispatchAnnouncementDto',
            'title',
          ),
          titleAr: titleAr,
          body: BuiltValueNullFieldError.checkNotNull(
            body,
            r'DispatchAnnouncementDto',
            'body',
          ),
          bodyAr: bodyAr,
          data: data,
          type: type,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
