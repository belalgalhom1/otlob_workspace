// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SupportTicket extends SupportTicket {
  @override
  final String id;
  @override
  final String ticketNumber;
  @override
  final String subject;
  @override
  final String? description;
  @override
  final JsonObject? status;
  @override
  final JsonObject? category;
  @override
  final String? subCategory;
  @override
  final JsonObject? priority;
  @override
  final String creatorId;
  @override
  final String? assigneeId;
  @override
  final String? orderId;
  @override
  final String? vendorId;
  @override
  final String? conversationId;
  @override
  final DateTime lastStatusUpdateAt;
  @override
  final DateTime? escalatedAt;
  @override
  final JsonObject? metadata;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final JsonObject? assignee;
  @override
  final JsonObject? conversation;
  @override
  final JsonObject? creator;
  @override
  final JsonObject? order;
  @override
  final JsonObject? vendor;

  factory _$SupportTicket([void Function(SupportTicketBuilder)? updates]) =>
      (SupportTicketBuilder()..update(updates))._build();

  _$SupportTicket._({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    this.description,
    this.status,
    this.category,
    this.subCategory,
    this.priority,
    required this.creatorId,
    this.assigneeId,
    this.orderId,
    this.vendorId,
    this.conversationId,
    required this.lastStatusUpdateAt,
    this.escalatedAt,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.assignee,
    this.conversation,
    this.creator,
    this.order,
    this.vendor,
  }) : super._();
  @override
  SupportTicket rebuild(void Function(SupportTicketBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SupportTicketBuilder toBuilder() => SupportTicketBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SupportTicket &&
        id == other.id &&
        ticketNumber == other.ticketNumber &&
        subject == other.subject &&
        description == other.description &&
        status == other.status &&
        category == other.category &&
        subCategory == other.subCategory &&
        priority == other.priority &&
        creatorId == other.creatorId &&
        assigneeId == other.assigneeId &&
        orderId == other.orderId &&
        vendorId == other.vendorId &&
        conversationId == other.conversationId &&
        lastStatusUpdateAt == other.lastStatusUpdateAt &&
        escalatedAt == other.escalatedAt &&
        metadata == other.metadata &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        assignee == other.assignee &&
        conversation == other.conversation &&
        creator == other.creator &&
        order == other.order &&
        vendor == other.vendor;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, ticketNumber.hashCode);
    _$hash = $jc(_$hash, subject.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, subCategory.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, creatorId.hashCode);
    _$hash = $jc(_$hash, assigneeId.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, conversationId.hashCode);
    _$hash = $jc(_$hash, lastStatusUpdateAt.hashCode);
    _$hash = $jc(_$hash, escalatedAt.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, assignee.hashCode);
    _$hash = $jc(_$hash, conversation.hashCode);
    _$hash = $jc(_$hash, creator.hashCode);
    _$hash = $jc(_$hash, order.hashCode);
    _$hash = $jc(_$hash, vendor.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SupportTicket')
          ..add('id', id)
          ..add('ticketNumber', ticketNumber)
          ..add('subject', subject)
          ..add('description', description)
          ..add('status', status)
          ..add('category', category)
          ..add('subCategory', subCategory)
          ..add('priority', priority)
          ..add('creatorId', creatorId)
          ..add('assigneeId', assigneeId)
          ..add('orderId', orderId)
          ..add('vendorId', vendorId)
          ..add('conversationId', conversationId)
          ..add('lastStatusUpdateAt', lastStatusUpdateAt)
          ..add('escalatedAt', escalatedAt)
          ..add('metadata', metadata)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('assignee', assignee)
          ..add('conversation', conversation)
          ..add('creator', creator)
          ..add('order', order)
          ..add('vendor', vendor))
        .toString();
  }
}

class SupportTicketBuilder
    implements Builder<SupportTicket, SupportTicketBuilder> {
  _$SupportTicket? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _ticketNumber;
  String? get ticketNumber => _$this._ticketNumber;
  set ticketNumber(String? ticketNumber) => _$this._ticketNumber = ticketNumber;

  String? _subject;
  String? get subject => _$this._subject;
  set subject(String? subject) => _$this._subject = subject;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  JsonObject? _status;
  JsonObject? get status => _$this._status;
  set status(JsonObject? status) => _$this._status = status;

  JsonObject? _category;
  JsonObject? get category => _$this._category;
  set category(JsonObject? category) => _$this._category = category;

  String? _subCategory;
  String? get subCategory => _$this._subCategory;
  set subCategory(String? subCategory) => _$this._subCategory = subCategory;

  JsonObject? _priority;
  JsonObject? get priority => _$this._priority;
  set priority(JsonObject? priority) => _$this._priority = priority;

  String? _creatorId;
  String? get creatorId => _$this._creatorId;
  set creatorId(String? creatorId) => _$this._creatorId = creatorId;

  String? _assigneeId;
  String? get assigneeId => _$this._assigneeId;
  set assigneeId(String? assigneeId) => _$this._assigneeId = assigneeId;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _conversationId;
  String? get conversationId => _$this._conversationId;
  set conversationId(String? conversationId) =>
      _$this._conversationId = conversationId;

  DateTime? _lastStatusUpdateAt;
  DateTime? get lastStatusUpdateAt => _$this._lastStatusUpdateAt;
  set lastStatusUpdateAt(DateTime? lastStatusUpdateAt) =>
      _$this._lastStatusUpdateAt = lastStatusUpdateAt;

  DateTime? _escalatedAt;
  DateTime? get escalatedAt => _$this._escalatedAt;
  set escalatedAt(DateTime? escalatedAt) => _$this._escalatedAt = escalatedAt;

  JsonObject? _metadata;
  JsonObject? get metadata => _$this._metadata;
  set metadata(JsonObject? metadata) => _$this._metadata = metadata;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  JsonObject? _assignee;
  JsonObject? get assignee => _$this._assignee;
  set assignee(JsonObject? assignee) => _$this._assignee = assignee;

  JsonObject? _conversation;
  JsonObject? get conversation => _$this._conversation;
  set conversation(JsonObject? conversation) =>
      _$this._conversation = conversation;

  JsonObject? _creator;
  JsonObject? get creator => _$this._creator;
  set creator(JsonObject? creator) => _$this._creator = creator;

  JsonObject? _order;
  JsonObject? get order => _$this._order;
  set order(JsonObject? order) => _$this._order = order;

  JsonObject? _vendor;
  JsonObject? get vendor => _$this._vendor;
  set vendor(JsonObject? vendor) => _$this._vendor = vendor;

  SupportTicketBuilder() {
    SupportTicket._defaults(this);
  }

  SupportTicketBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _ticketNumber = $v.ticketNumber;
      _subject = $v.subject;
      _description = $v.description;
      _status = $v.status;
      _category = $v.category;
      _subCategory = $v.subCategory;
      _priority = $v.priority;
      _creatorId = $v.creatorId;
      _assigneeId = $v.assigneeId;
      _orderId = $v.orderId;
      _vendorId = $v.vendorId;
      _conversationId = $v.conversationId;
      _lastStatusUpdateAt = $v.lastStatusUpdateAt;
      _escalatedAt = $v.escalatedAt;
      _metadata = $v.metadata;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _assignee = $v.assignee;
      _conversation = $v.conversation;
      _creator = $v.creator;
      _order = $v.order;
      _vendor = $v.vendor;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SupportTicket other) {
    _$v = other as _$SupportTicket;
  }

  @override
  void update(void Function(SupportTicketBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SupportTicket build() => _build();

  _$SupportTicket _build() {
    final _$result =
        _$v ??
        _$SupportTicket._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'SupportTicket', 'id'),
          ticketNumber: BuiltValueNullFieldError.checkNotNull(
            ticketNumber,
            r'SupportTicket',
            'ticketNumber',
          ),
          subject: BuiltValueNullFieldError.checkNotNull(
            subject,
            r'SupportTicket',
            'subject',
          ),
          description: description,
          status: status,
          category: category,
          subCategory: subCategory,
          priority: priority,
          creatorId: BuiltValueNullFieldError.checkNotNull(
            creatorId,
            r'SupportTicket',
            'creatorId',
          ),
          assigneeId: assigneeId,
          orderId: orderId,
          vendorId: vendorId,
          conversationId: conversationId,
          lastStatusUpdateAt: BuiltValueNullFieldError.checkNotNull(
            lastStatusUpdateAt,
            r'SupportTicket',
            'lastStatusUpdateAt',
          ),
          escalatedAt: escalatedAt,
          metadata: metadata,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'SupportTicket',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'SupportTicket',
            'updatedAt',
          ),
          assignee: assignee,
          conversation: conversation,
          creator: creator,
          order: order,
          vendor: vendor,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
