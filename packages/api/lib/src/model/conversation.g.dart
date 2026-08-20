// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Conversation extends Conversation {
  @override
  final String id;
  @override
  final JsonObject? type;
  @override
  final String? orderId;
  @override
  final JsonObject? status;
  @override
  final String? vendorId;
  @override
  final String? creatorId;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final BuiltList<ConversationParticipant> participants;
  @override
  final JsonObject? creator;
  @override
  final JsonObject? vendor;
  @override
  final BuiltList<Message> messages;
  @override
  final JsonObject? supportTicket;

  factory _$Conversation([void Function(ConversationBuilder)? updates]) =>
      (ConversationBuilder()..update(updates))._build();

  _$Conversation._({
    required this.id,
    this.type,
    this.orderId,
    this.status,
    this.vendorId,
    this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.creator,
    this.vendor,
    required this.messages,
    this.supportTicket,
  }) : super._();
  @override
  Conversation rebuild(void Function(ConversationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConversationBuilder toBuilder() => ConversationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Conversation &&
        id == other.id &&
        type == other.type &&
        orderId == other.orderId &&
        status == other.status &&
        vendorId == other.vendorId &&
        creatorId == other.creatorId &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        participants == other.participants &&
        creator == other.creator &&
        vendor == other.vendor &&
        messages == other.messages &&
        supportTicket == other.supportTicket;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, creatorId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, participants.hashCode);
    _$hash = $jc(_$hash, creator.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jc(_$hash, messages.hashCode);
    _$hash = $jc(_$hash, supportTicket.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Conversation')
          ..add('id', id)
          ..add('type', type)
          ..add('orderId', orderId)
          ..add('status', status)
          ..add('vendorId', vendorId)
          ..add('creatorId', creatorId)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('participants', participants)
          ..add('creator', creator)
          ..add('vendor', vendor)
          ..add('messages', messages)
          ..add('supportTicket', supportTicket))
        .toString();
  }
}

class ConversationBuilder
    implements Builder<Conversation, ConversationBuilder> {
  _$Conversation? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  JsonObject? _type;
  JsonObject? get type => _$this._type;
  set type(JsonObject? type) => _$this._type = type;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  JsonObject? _status;
  JsonObject? get status => _$this._status;
  set status(JsonObject? status) => _$this._status = status;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _creatorId;
  String? get creatorId => _$this._creatorId;
  set creatorId(String? creatorId) => _$this._creatorId = creatorId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  ListBuilder<ConversationParticipant>? _participants;
  ListBuilder<ConversationParticipant> get participants =>
      _$this._participants ??= ListBuilder<ConversationParticipant>();
  set participants(ListBuilder<ConversationParticipant>? participants) =>
      _$this._participants = participants;

  JsonObject? _creator;
  JsonObject? get creator => _$this._creator;
  set creator(JsonObject? creator) => _$this._creator = creator;

  JsonObject? _vendor;
  JsonObject? get vendor => _$this._vendor;
  set vendor(JsonObject? vendor) => _$this._vendor = vendor;

  ListBuilder<Message>? _messages;
  ListBuilder<Message> get messages =>
      _$this._messages ??= ListBuilder<Message>();
  set messages(ListBuilder<Message>? messages) => _$this._messages = messages;

  JsonObject? _supportTicket;
  JsonObject? get supportTicket => _$this._supportTicket;
  set supportTicket(JsonObject? supportTicket) =>
      _$this._supportTicket = supportTicket;

  ConversationBuilder() {
    Conversation._defaults(this);
  }

  ConversationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _type = $v.type;
      _orderId = $v.orderId;
      _status = $v.status;
      _vendorId = $v.vendorId;
      _creatorId = $v.creatorId;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _participants = $v.participants.toBuilder();
      _creator = $v.creator;
      _vendor = $v.vendor;
      _messages = $v.messages.toBuilder();
      _supportTicket = $v.supportTicket;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Conversation other) {
    _$v = other as _$Conversation;
  }

  @override
  void update(void Function(ConversationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Conversation build() => _build();

  _$Conversation _build() {
    _$Conversation _$result;
    try {
      _$result =
          _$v ??
          _$Conversation._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'Conversation',
              'id',
            ),
            type: type,
            orderId: orderId,
            status: status,
            vendorId: vendorId,
            creatorId: creatorId,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'Conversation',
              'createdAt',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'Conversation',
              'updatedAt',
            ),
            participants: participants.build(),
            creator: creator,
            vendor: vendor,
            messages: messages.build(),
            supportTicket: supportTicket,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'participants';
        participants.build();

        _$failedField = 'messages';
        messages.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Conversation',
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
