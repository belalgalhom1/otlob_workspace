// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_participant.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConversationParticipant extends ConversationParticipant {
  @override
  final String conversationId;
  @override
  final String userId;
  @override
  final DateTime joinedAt;
  @override
  final DateTime lastReadAt;
  @override
  final JsonObject? conversation;
  @override
  final JsonObject? user;

  factory _$ConversationParticipant([
    void Function(ConversationParticipantBuilder)? updates,
  ]) => (ConversationParticipantBuilder()..update(updates))._build();

  _$ConversationParticipant._({
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    required this.lastReadAt,
    this.conversation,
    this.user,
  }) : super._();
  @override
  ConversationParticipant rebuild(
    void Function(ConversationParticipantBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ConversationParticipantBuilder toBuilder() =>
      ConversationParticipantBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConversationParticipant &&
        conversationId == other.conversationId &&
        userId == other.userId &&
        joinedAt == other.joinedAt &&
        lastReadAt == other.lastReadAt &&
        conversation == other.conversation &&
        user == other.user;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, conversationId.hashCode);
    _$hash = $jc(_$hash, userId.hashCode);
    _$hash = $jc(_$hash, joinedAt.hashCode);
    _$hash = $jc(_$hash, lastReadAt.hashCode);
    _$hash = $jc(_$hash, conversation.hashCode);
    _$hash = $jc(_$hash, user.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConversationParticipant')
          ..add('conversationId', conversationId)
          ..add('userId', userId)
          ..add('joinedAt', joinedAt)
          ..add('lastReadAt', lastReadAt)
          ..add('conversation', conversation)
          ..add('user', user))
        .toString();
  }
}

class ConversationParticipantBuilder
    implements
        Builder<ConversationParticipant, ConversationParticipantBuilder> {
  _$ConversationParticipant? _$v;

  String? _conversationId;
  String? get conversationId => _$this._conversationId;
  set conversationId(String? conversationId) =>
      _$this._conversationId = conversationId;

  String? _userId;
  String? get userId => _$this._userId;
  set userId(String? userId) => _$this._userId = userId;

  DateTime? _joinedAt;
  DateTime? get joinedAt => _$this._joinedAt;
  set joinedAt(DateTime? joinedAt) => _$this._joinedAt = joinedAt;

  DateTime? _lastReadAt;
  DateTime? get lastReadAt => _$this._lastReadAt;
  set lastReadAt(DateTime? lastReadAt) => _$this._lastReadAt = lastReadAt;

  JsonObject? _conversation;
  JsonObject? get conversation => _$this._conversation;
  set conversation(JsonObject? conversation) =>
      _$this._conversation = conversation;

  JsonObject? _user;
  JsonObject? get user => _$this._user;
  set user(JsonObject? user) => _$this._user = user;

  ConversationParticipantBuilder() {
    ConversationParticipant._defaults(this);
  }

  ConversationParticipantBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _conversationId = $v.conversationId;
      _userId = $v.userId;
      _joinedAt = $v.joinedAt;
      _lastReadAt = $v.lastReadAt;
      _conversation = $v.conversation;
      _user = $v.user;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConversationParticipant other) {
    _$v = other as _$ConversationParticipant;
  }

  @override
  void update(void Function(ConversationParticipantBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConversationParticipant build() => _build();

  _$ConversationParticipant _build() {
    final _$result =
        _$v ??
        _$ConversationParticipant._(
          conversationId: BuiltValueNullFieldError.checkNotNull(
            conversationId,
            r'ConversationParticipant',
            'conversationId',
          ),
          userId: BuiltValueNullFieldError.checkNotNull(
            userId,
            r'ConversationParticipant',
            'userId',
          ),
          joinedAt: BuiltValueNullFieldError.checkNotNull(
            joinedAt,
            r'ConversationParticipant',
            'joinedAt',
          ),
          lastReadAt: BuiltValueNullFieldError.checkNotNull(
            lastReadAt,
            r'ConversationParticipant',
            'lastReadAt',
          ),
          conversation: conversation,
          user: user,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
