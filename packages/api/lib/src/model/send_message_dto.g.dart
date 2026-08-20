// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_message_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SendMessageDtoTypeEnum _$sendMessageDtoTypeEnum_TEXT =
    const SendMessageDtoTypeEnum._('TEXT');
const SendMessageDtoTypeEnum _$sendMessageDtoTypeEnum_IMAGE =
    const SendMessageDtoTypeEnum._('IMAGE');
const SendMessageDtoTypeEnum _$sendMessageDtoTypeEnum_VIDEO =
    const SendMessageDtoTypeEnum._('VIDEO');
const SendMessageDtoTypeEnum _$sendMessageDtoTypeEnum_AUDIO =
    const SendMessageDtoTypeEnum._('AUDIO');
const SendMessageDtoTypeEnum _$sendMessageDtoTypeEnum_LOCATION =
    const SendMessageDtoTypeEnum._('LOCATION');
const SendMessageDtoTypeEnum _$sendMessageDtoTypeEnum_SYSTEM =
    const SendMessageDtoTypeEnum._('SYSTEM');
const SendMessageDtoTypeEnum _$sendMessageDtoTypeEnum_PRODUCT =
    const SendMessageDtoTypeEnum._('PRODUCT');

SendMessageDtoTypeEnum _$sendMessageDtoTypeEnumValueOf(String name) {
  switch (name) {
    case 'TEXT':
      return _$sendMessageDtoTypeEnum_TEXT;
    case 'IMAGE':
      return _$sendMessageDtoTypeEnum_IMAGE;
    case 'VIDEO':
      return _$sendMessageDtoTypeEnum_VIDEO;
    case 'AUDIO':
      return _$sendMessageDtoTypeEnum_AUDIO;
    case 'LOCATION':
      return _$sendMessageDtoTypeEnum_LOCATION;
    case 'SYSTEM':
      return _$sendMessageDtoTypeEnum_SYSTEM;
    case 'PRODUCT':
      return _$sendMessageDtoTypeEnum_PRODUCT;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SendMessageDtoTypeEnum> _$sendMessageDtoTypeEnumValues =
    BuiltSet<SendMessageDtoTypeEnum>(const <SendMessageDtoTypeEnum>[
      _$sendMessageDtoTypeEnum_TEXT,
      _$sendMessageDtoTypeEnum_IMAGE,
      _$sendMessageDtoTypeEnum_VIDEO,
      _$sendMessageDtoTypeEnum_AUDIO,
      _$sendMessageDtoTypeEnum_LOCATION,
      _$sendMessageDtoTypeEnum_SYSTEM,
      _$sendMessageDtoTypeEnum_PRODUCT,
    ]);

Serializer<SendMessageDtoTypeEnum> _$sendMessageDtoTypeEnumSerializer =
    _$SendMessageDtoTypeEnumSerializer();

class _$SendMessageDtoTypeEnumSerializer
    implements PrimitiveSerializer<SendMessageDtoTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'TEXT': 'TEXT',
    'IMAGE': 'IMAGE',
    'VIDEO': 'VIDEO',
    'AUDIO': 'AUDIO',
    'LOCATION': 'LOCATION',
    'SYSTEM': 'SYSTEM',
    'PRODUCT': 'PRODUCT',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'TEXT': 'TEXT',
    'IMAGE': 'IMAGE',
    'VIDEO': 'VIDEO',
    'AUDIO': 'AUDIO',
    'LOCATION': 'LOCATION',
    'SYSTEM': 'SYSTEM',
    'PRODUCT': 'PRODUCT',
  };

  @override
  final Iterable<Type> types = const <Type>[SendMessageDtoTypeEnum];
  @override
  final String wireName = 'SendMessageDtoTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    SendMessageDtoTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SendMessageDtoTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SendMessageDtoTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$SendMessageDto extends SendMessageDto {
  @override
  final SendMessageDtoTypeEnum type;
  @override
  final String? text;
  @override
  final String? mediaUrl;
  @override
  final JsonObject? metadata;
  @override
  final String? replyToId;

  factory _$SendMessageDto([void Function(SendMessageDtoBuilder)? updates]) =>
      (SendMessageDtoBuilder()..update(updates))._build();

  _$SendMessageDto._({
    required this.type,
    this.text,
    this.mediaUrl,
    this.metadata,
    this.replyToId,
  }) : super._();
  @override
  SendMessageDto rebuild(void Function(SendMessageDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SendMessageDtoBuilder toBuilder() => SendMessageDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SendMessageDto &&
        type == other.type &&
        text == other.text &&
        mediaUrl == other.mediaUrl &&
        metadata == other.metadata &&
        replyToId == other.replyToId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jc(_$hash, mediaUrl.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jc(_$hash, replyToId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SendMessageDto')
          ..add('type', type)
          ..add('text', text)
          ..add('mediaUrl', mediaUrl)
          ..add('metadata', metadata)
          ..add('replyToId', replyToId))
        .toString();
  }
}

class SendMessageDtoBuilder
    implements Builder<SendMessageDto, SendMessageDtoBuilder> {
  _$SendMessageDto? _$v;

  SendMessageDtoTypeEnum? _type;
  SendMessageDtoTypeEnum? get type => _$this._type;
  set type(SendMessageDtoTypeEnum? type) => _$this._type = type;

  String? _text;
  String? get text => _$this._text;
  set text(String? text) => _$this._text = text;

  String? _mediaUrl;
  String? get mediaUrl => _$this._mediaUrl;
  set mediaUrl(String? mediaUrl) => _$this._mediaUrl = mediaUrl;

  JsonObject? _metadata;
  JsonObject? get metadata => _$this._metadata;
  set metadata(JsonObject? metadata) => _$this._metadata = metadata;

  String? _replyToId;
  String? get replyToId => _$this._replyToId;
  set replyToId(String? replyToId) => _$this._replyToId = replyToId;

  SendMessageDtoBuilder() {
    SendMessageDto._defaults(this);
  }

  SendMessageDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _type = $v.type;
      _text = $v.text;
      _mediaUrl = $v.mediaUrl;
      _metadata = $v.metadata;
      _replyToId = $v.replyToId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SendMessageDto other) {
    _$v = other as _$SendMessageDto;
  }

  @override
  void update(void Function(SendMessageDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SendMessageDto build() => _build();

  _$SendMessageDto _build() {
    final _$result =
        _$v ??
        _$SendMessageDto._(
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'SendMessageDto',
            'type',
          ),
          text: text,
          mediaUrl: mediaUrl,
          metadata: metadata,
          replyToId: replyToId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
