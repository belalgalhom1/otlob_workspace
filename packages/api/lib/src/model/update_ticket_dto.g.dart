// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_ticket_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateTicketDtoStatusEnum _$updateTicketDtoStatusEnum_OPEN =
    const UpdateTicketDtoStatusEnum._('OPEN');
const UpdateTicketDtoStatusEnum _$updateTicketDtoStatusEnum_IN_PROGRESS =
    const UpdateTicketDtoStatusEnum._('IN_PROGRESS');
const UpdateTicketDtoStatusEnum _$updateTicketDtoStatusEnum_WAITING_ON_USER =
    const UpdateTicketDtoStatusEnum._('WAITING_ON_USER');
const UpdateTicketDtoStatusEnum _$updateTicketDtoStatusEnum_ESCALATED =
    const UpdateTicketDtoStatusEnum._('ESCALATED');
const UpdateTicketDtoStatusEnum _$updateTicketDtoStatusEnum_RESOLVED =
    const UpdateTicketDtoStatusEnum._('RESOLVED');
const UpdateTicketDtoStatusEnum _$updateTicketDtoStatusEnum_CLOSED =
    const UpdateTicketDtoStatusEnum._('CLOSED');

UpdateTicketDtoStatusEnum _$updateTicketDtoStatusEnumValueOf(String name) {
  switch (name) {
    case 'OPEN':
      return _$updateTicketDtoStatusEnum_OPEN;
    case 'IN_PROGRESS':
      return _$updateTicketDtoStatusEnum_IN_PROGRESS;
    case 'WAITING_ON_USER':
      return _$updateTicketDtoStatusEnum_WAITING_ON_USER;
    case 'ESCALATED':
      return _$updateTicketDtoStatusEnum_ESCALATED;
    case 'RESOLVED':
      return _$updateTicketDtoStatusEnum_RESOLVED;
    case 'CLOSED':
      return _$updateTicketDtoStatusEnum_CLOSED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateTicketDtoStatusEnum> _$updateTicketDtoStatusEnumValues =
    BuiltSet<UpdateTicketDtoStatusEnum>(const <UpdateTicketDtoStatusEnum>[
      _$updateTicketDtoStatusEnum_OPEN,
      _$updateTicketDtoStatusEnum_IN_PROGRESS,
      _$updateTicketDtoStatusEnum_WAITING_ON_USER,
      _$updateTicketDtoStatusEnum_ESCALATED,
      _$updateTicketDtoStatusEnum_RESOLVED,
      _$updateTicketDtoStatusEnum_CLOSED,
    ]);

const UpdateTicketDtoPriorityEnum _$updateTicketDtoPriorityEnum_LOW =
    const UpdateTicketDtoPriorityEnum._('LOW');
const UpdateTicketDtoPriorityEnum _$updateTicketDtoPriorityEnum_MEDIUM =
    const UpdateTicketDtoPriorityEnum._('MEDIUM');
const UpdateTicketDtoPriorityEnum _$updateTicketDtoPriorityEnum_HIGH =
    const UpdateTicketDtoPriorityEnum._('HIGH');
const UpdateTicketDtoPriorityEnum _$updateTicketDtoPriorityEnum_URGENT =
    const UpdateTicketDtoPriorityEnum._('URGENT');

UpdateTicketDtoPriorityEnum _$updateTicketDtoPriorityEnumValueOf(String name) {
  switch (name) {
    case 'LOW':
      return _$updateTicketDtoPriorityEnum_LOW;
    case 'MEDIUM':
      return _$updateTicketDtoPriorityEnum_MEDIUM;
    case 'HIGH':
      return _$updateTicketDtoPriorityEnum_HIGH;
    case 'URGENT':
      return _$updateTicketDtoPriorityEnum_URGENT;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateTicketDtoPriorityEnum>
_$updateTicketDtoPriorityEnumValues =
    BuiltSet<UpdateTicketDtoPriorityEnum>(const <UpdateTicketDtoPriorityEnum>[
      _$updateTicketDtoPriorityEnum_LOW,
      _$updateTicketDtoPriorityEnum_MEDIUM,
      _$updateTicketDtoPriorityEnum_HIGH,
      _$updateTicketDtoPriorityEnum_URGENT,
    ]);

const UpdateTicketDtoCategoryEnum _$updateTicketDtoCategoryEnum_DELIVERY =
    const UpdateTicketDtoCategoryEnum._('DELIVERY');
const UpdateTicketDtoCategoryEnum _$updateTicketDtoCategoryEnum_VENDOR =
    const UpdateTicketDtoCategoryEnum._('VENDOR');
const UpdateTicketDtoCategoryEnum _$updateTicketDtoCategoryEnum_PAYMENT =
    const UpdateTicketDtoCategoryEnum._('PAYMENT');
const UpdateTicketDtoCategoryEnum _$updateTicketDtoCategoryEnum_ACCOUNT =
    const UpdateTicketDtoCategoryEnum._('ACCOUNT');
const UpdateTicketDtoCategoryEnum
_$updateTicketDtoCategoryEnum_RETURN_COMPLAINT =
    const UpdateTicketDtoCategoryEnum._('RETURN_COMPLAINT');
const UpdateTicketDtoCategoryEnum _$updateTicketDtoCategoryEnum_OTHER =
    const UpdateTicketDtoCategoryEnum._('OTHER');

UpdateTicketDtoCategoryEnum _$updateTicketDtoCategoryEnumValueOf(String name) {
  switch (name) {
    case 'DELIVERY':
      return _$updateTicketDtoCategoryEnum_DELIVERY;
    case 'VENDOR':
      return _$updateTicketDtoCategoryEnum_VENDOR;
    case 'PAYMENT':
      return _$updateTicketDtoCategoryEnum_PAYMENT;
    case 'ACCOUNT':
      return _$updateTicketDtoCategoryEnum_ACCOUNT;
    case 'RETURN_COMPLAINT':
      return _$updateTicketDtoCategoryEnum_RETURN_COMPLAINT;
    case 'OTHER':
      return _$updateTicketDtoCategoryEnum_OTHER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateTicketDtoCategoryEnum>
_$updateTicketDtoCategoryEnumValues =
    BuiltSet<UpdateTicketDtoCategoryEnum>(const <UpdateTicketDtoCategoryEnum>[
      _$updateTicketDtoCategoryEnum_DELIVERY,
      _$updateTicketDtoCategoryEnum_VENDOR,
      _$updateTicketDtoCategoryEnum_PAYMENT,
      _$updateTicketDtoCategoryEnum_ACCOUNT,
      _$updateTicketDtoCategoryEnum_RETURN_COMPLAINT,
      _$updateTicketDtoCategoryEnum_OTHER,
    ]);

Serializer<UpdateTicketDtoStatusEnum> _$updateTicketDtoStatusEnumSerializer =
    _$UpdateTicketDtoStatusEnumSerializer();
Serializer<UpdateTicketDtoPriorityEnum>
_$updateTicketDtoPriorityEnumSerializer =
    _$UpdateTicketDtoPriorityEnumSerializer();
Serializer<UpdateTicketDtoCategoryEnum>
_$updateTicketDtoCategoryEnumSerializer =
    _$UpdateTicketDtoCategoryEnumSerializer();

class _$UpdateTicketDtoStatusEnumSerializer
    implements PrimitiveSerializer<UpdateTicketDtoStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'OPEN': 'OPEN',
    'IN_PROGRESS': 'IN_PROGRESS',
    'WAITING_ON_USER': 'WAITING_ON_USER',
    'ESCALATED': 'ESCALATED',
    'RESOLVED': 'RESOLVED',
    'CLOSED': 'CLOSED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OPEN': 'OPEN',
    'IN_PROGRESS': 'IN_PROGRESS',
    'WAITING_ON_USER': 'WAITING_ON_USER',
    'ESCALATED': 'ESCALATED',
    'RESOLVED': 'RESOLVED',
    'CLOSED': 'CLOSED',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateTicketDtoStatusEnum];
  @override
  final String wireName = 'UpdateTicketDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateTicketDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateTicketDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateTicketDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateTicketDtoPriorityEnumSerializer
    implements PrimitiveSerializer<UpdateTicketDtoPriorityEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'LOW': 'LOW',
    'MEDIUM': 'MEDIUM',
    'HIGH': 'HIGH',
    'URGENT': 'URGENT',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'LOW': 'LOW',
    'MEDIUM': 'MEDIUM',
    'HIGH': 'HIGH',
    'URGENT': 'URGENT',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateTicketDtoPriorityEnum];
  @override
  final String wireName = 'UpdateTicketDtoPriorityEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateTicketDtoPriorityEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateTicketDtoPriorityEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateTicketDtoPriorityEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateTicketDtoCategoryEnumSerializer
    implements PrimitiveSerializer<UpdateTicketDtoCategoryEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'DELIVERY': 'DELIVERY',
    'VENDOR': 'VENDOR',
    'PAYMENT': 'PAYMENT',
    'ACCOUNT': 'ACCOUNT',
    'RETURN_COMPLAINT': 'RETURN_COMPLAINT',
    'OTHER': 'OTHER',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DELIVERY': 'DELIVERY',
    'VENDOR': 'VENDOR',
    'PAYMENT': 'PAYMENT',
    'ACCOUNT': 'ACCOUNT',
    'RETURN_COMPLAINT': 'RETURN_COMPLAINT',
    'OTHER': 'OTHER',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateTicketDtoCategoryEnum];
  @override
  final String wireName = 'UpdateTicketDtoCategoryEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateTicketDtoCategoryEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateTicketDtoCategoryEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateTicketDtoCategoryEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateTicketDto extends UpdateTicketDto {
  @override
  final UpdateTicketDtoStatusEnum? status;
  @override
  final UpdateTicketDtoPriorityEnum? priority;
  @override
  final UpdateTicketDtoCategoryEnum? category;
  @override
  final String? assigneeId;
  @override
  final String? subject;
  @override
  final String? description;
  @override
  final String? subCategory;
  @override
  final String? vendorId;
  @override
  final JsonObject? metadata;

  factory _$UpdateTicketDto([void Function(UpdateTicketDtoBuilder)? updates]) =>
      (UpdateTicketDtoBuilder()..update(updates))._build();

  _$UpdateTicketDto._({
    this.status,
    this.priority,
    this.category,
    this.assigneeId,
    this.subject,
    this.description,
    this.subCategory,
    this.vendorId,
    this.metadata,
  }) : super._();
  @override
  UpdateTicketDto rebuild(void Function(UpdateTicketDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateTicketDtoBuilder toBuilder() => UpdateTicketDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateTicketDto &&
        status == other.status &&
        priority == other.priority &&
        category == other.category &&
        assigneeId == other.assigneeId &&
        subject == other.subject &&
        description == other.description &&
        subCategory == other.subCategory &&
        vendorId == other.vendorId &&
        metadata == other.metadata;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, assigneeId.hashCode);
    _$hash = $jc(_$hash, subject.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, subCategory.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateTicketDto')
          ..add('status', status)
          ..add('priority', priority)
          ..add('category', category)
          ..add('assigneeId', assigneeId)
          ..add('subject', subject)
          ..add('description', description)
          ..add('subCategory', subCategory)
          ..add('vendorId', vendorId)
          ..add('metadata', metadata))
        .toString();
  }
}

class UpdateTicketDtoBuilder
    implements Builder<UpdateTicketDto, UpdateTicketDtoBuilder> {
  _$UpdateTicketDto? _$v;

  UpdateTicketDtoStatusEnum? _status;
  UpdateTicketDtoStatusEnum? get status => _$this._status;
  set status(UpdateTicketDtoStatusEnum? status) => _$this._status = status;

  UpdateTicketDtoPriorityEnum? _priority;
  UpdateTicketDtoPriorityEnum? get priority => _$this._priority;
  set priority(UpdateTicketDtoPriorityEnum? priority) =>
      _$this._priority = priority;

  UpdateTicketDtoCategoryEnum? _category;
  UpdateTicketDtoCategoryEnum? get category => _$this._category;
  set category(UpdateTicketDtoCategoryEnum? category) =>
      _$this._category = category;

  String? _assigneeId;
  String? get assigneeId => _$this._assigneeId;
  set assigneeId(String? assigneeId) => _$this._assigneeId = assigneeId;

  String? _subject;
  String? get subject => _$this._subject;
  set subject(String? subject) => _$this._subject = subject;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _subCategory;
  String? get subCategory => _$this._subCategory;
  set subCategory(String? subCategory) => _$this._subCategory = subCategory;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  JsonObject? _metadata;
  JsonObject? get metadata => _$this._metadata;
  set metadata(JsonObject? metadata) => _$this._metadata = metadata;

  UpdateTicketDtoBuilder() {
    UpdateTicketDto._defaults(this);
  }

  UpdateTicketDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _priority = $v.priority;
      _category = $v.category;
      _assigneeId = $v.assigneeId;
      _subject = $v.subject;
      _description = $v.description;
      _subCategory = $v.subCategory;
      _vendorId = $v.vendorId;
      _metadata = $v.metadata;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateTicketDto other) {
    _$v = other as _$UpdateTicketDto;
  }

  @override
  void update(void Function(UpdateTicketDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateTicketDto build() => _build();

  _$UpdateTicketDto _build() {
    final _$result =
        _$v ??
        _$UpdateTicketDto._(
          status: status,
          priority: priority,
          category: category,
          assigneeId: assigneeId,
          subject: subject,
          description: description,
          subCategory: subCategory,
          vendorId: vendorId,
          metadata: metadata,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
