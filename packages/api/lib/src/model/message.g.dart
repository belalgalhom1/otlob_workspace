// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Message extends Message {
  @override
  final String id;
  @override
  final String conversationId;
  @override
  final String senderId;
  @override
  final JsonObject? type;
  @override
  final String? text;
  @override
  final String? mediaUrl;
  @override
  final JsonObject? metadata;
  @override
  final String? replyToId;
  @override
  final DateTime createdAt;
  @override
  final DateTime? deletedAt;
  @override
  final JsonObject? conversation;
  @override
  final Message? replyTo;
  @override
  final BuiltList<Message> replies;
  @override
  final JsonObject? sender;

  factory _$Message([void Function(MessageBuilder)? updates]) =>
      (MessageBuilder()..update(updates))._build();

  _$Message._({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.type,
    this.text,
    this.mediaUrl,
    this.metadata,
    this.replyToId,
    required this.createdAt,
    this.deletedAt,
    this.conversation,
    this.replyTo,
    required this.replies,
    this.sender,
  }) : super._();
  @override
  Message rebuild(void Function(MessageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MessageBuilder toBuilder() => MessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Message &&
        id == other.id &&
        conversationId == other.conversationId &&
        senderId == other.senderId &&
        type == other.type &&
        text == other.text &&
        mediaUrl == other.mediaUrl &&
        metadata == other.metadata &&
        replyToId == other.replyToId &&
        createdAt == other.createdAt &&
        deletedAt == other.deletedAt &&
        conversation == other.conversation &&
        replyTo == other.replyTo &&
        replies == other.replies &&
        sender == other.sender;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, conversationId.hashCode);
    _$hash = $jc(_$hash, senderId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, text.hashCode);
    _$hash = $jc(_$hash, mediaUrl.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jc(_$hash, replyToId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, conversation.hashCode);
    _$hash = $jc(_$hash, replyTo.hashCode);
    _$hash = $jc(_$hash, replies.hashCode);
    _$hash = $jc(_$hash, sender.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Message')
          ..add('id', id)
          ..add('conversationId', conversationId)
          ..add('senderId', senderId)
          ..add('type', type)
          ..add('text', text)
          ..add('mediaUrl', mediaUrl)
          ..add('metadata', metadata)
          ..add('replyToId', replyToId)
          ..add('createdAt', createdAt)
          ..add('deletedAt', deletedAt)
          ..add('conversation', conversation)
          ..add('replyTo', replyTo)
          ..add('replies', replies)
          ..add('sender', sender))
        .toString();
  }
}

class MessageBuilder implements Builder<Message, MessageBuilder> {
  _$Message? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _conversationId;
  String? get conversationId => _$this._conversationId;
  set conversationId(String? conversationId) =>
      _$this._conversationId = conversationId;

  String? _senderId;
  String? get senderId => _$this._senderId;
  set senderId(String? senderId) => _$this._senderId = senderId;

  JsonObject? _type;
  JsonObject? get type => _$this._type;
  set type(JsonObject? type) => _$this._type = type;

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

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  JsonObject? _conversation;
  JsonObject? get conversation => _$this._conversation;
  set conversation(JsonObject? conversation) =>
      _$this._conversation = conversation;

  MessageBuilder? _replyTo;
  MessageBuilder get replyTo => _$this._replyTo ??= MessageBuilder();
  set replyTo(MessageBuilder? replyTo) => _$this._replyTo = replyTo;

  ListBuilder<Message>? _replies;
  ListBuilder<Message> get replies =>
      _$this._replies ??= ListBuilder<Message>();
  set replies(ListBuilder<Message>? replies) => _$this._replies = replies;

  JsonObject? _sender;
  JsonObject? get sender => _$this._sender;
  set sender(JsonObject? sender) => _$this._sender = sender;

  MessageBuilder() {
    Message._defaults(this);
  }

  MessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _conversationId = $v.conversationId;
      _senderId = $v.senderId;
      _type = $v.type;
      _text = $v.text;
      _mediaUrl = $v.mediaUrl;
      _metadata = $v.metadata;
      _replyToId = $v.replyToId;
      _createdAt = $v.createdAt;
      _deletedAt = $v.deletedAt;
      _conversation = $v.conversation;
      _replyTo = $v.replyTo?.toBuilder();
      _replies = $v.replies.toBuilder();
      _sender = $v.sender;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Message other) {
    _$v = other as _$Message;
  }

  @override
  void update(void Function(MessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Message build() => _build();

  _$Message _build() {
    _$Message _$result;
    try {
      _$result =
          _$v ??
          _$Message._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Message', 'id'),
            conversationId: BuiltValueNullFieldError.checkNotNull(
              conversationId,
              r'Message',
              'conversationId',
            ),
            senderId: BuiltValueNullFieldError.checkNotNull(
              senderId,
              r'Message',
              'senderId',
            ),
            type: type,
            text: text,
            mediaUrl: mediaUrl,
            metadata: metadata,
            replyToId: replyToId,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'Message',
              'createdAt',
            ),
            deletedAt: deletedAt,
            conversation: conversation,
            replyTo: _replyTo?.build(),
            replies: replies.build(),
            sender: sender,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'replyTo';
        _replyTo?.build();
        _$failedField = 'replies';
        replies.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Message',
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
