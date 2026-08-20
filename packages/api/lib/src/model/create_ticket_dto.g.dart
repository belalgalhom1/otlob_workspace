// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_ticket_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CreateTicketDtoCategoryEnum _$createTicketDtoCategoryEnum_DELIVERY =
    const CreateTicketDtoCategoryEnum._('DELIVERY');
const CreateTicketDtoCategoryEnum _$createTicketDtoCategoryEnum_VENDOR =
    const CreateTicketDtoCategoryEnum._('VENDOR');
const CreateTicketDtoCategoryEnum _$createTicketDtoCategoryEnum_PAYMENT =
    const CreateTicketDtoCategoryEnum._('PAYMENT');
const CreateTicketDtoCategoryEnum _$createTicketDtoCategoryEnum_ACCOUNT =
    const CreateTicketDtoCategoryEnum._('ACCOUNT');
const CreateTicketDtoCategoryEnum
_$createTicketDtoCategoryEnum_RETURN_COMPLAINT =
    const CreateTicketDtoCategoryEnum._('RETURN_COMPLAINT');
const CreateTicketDtoCategoryEnum _$createTicketDtoCategoryEnum_OTHER =
    const CreateTicketDtoCategoryEnum._('OTHER');

CreateTicketDtoCategoryEnum _$createTicketDtoCategoryEnumValueOf(String name) {
  switch (name) {
    case 'DELIVERY':
      return _$createTicketDtoCategoryEnum_DELIVERY;
    case 'VENDOR':
      return _$createTicketDtoCategoryEnum_VENDOR;
    case 'PAYMENT':
      return _$createTicketDtoCategoryEnum_PAYMENT;
    case 'ACCOUNT':
      return _$createTicketDtoCategoryEnum_ACCOUNT;
    case 'RETURN_COMPLAINT':
      return _$createTicketDtoCategoryEnum_RETURN_COMPLAINT;
    case 'OTHER':
      return _$createTicketDtoCategoryEnum_OTHER;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateTicketDtoCategoryEnum>
_$createTicketDtoCategoryEnumValues =
    BuiltSet<CreateTicketDtoCategoryEnum>(const <CreateTicketDtoCategoryEnum>[
      _$createTicketDtoCategoryEnum_DELIVERY,
      _$createTicketDtoCategoryEnum_VENDOR,
      _$createTicketDtoCategoryEnum_PAYMENT,
      _$createTicketDtoCategoryEnum_ACCOUNT,
      _$createTicketDtoCategoryEnum_RETURN_COMPLAINT,
      _$createTicketDtoCategoryEnum_OTHER,
    ]);

const CreateTicketDtoPriorityEnum _$createTicketDtoPriorityEnum_LOW =
    const CreateTicketDtoPriorityEnum._('LOW');
const CreateTicketDtoPriorityEnum _$createTicketDtoPriorityEnum_MEDIUM =
    const CreateTicketDtoPriorityEnum._('MEDIUM');
const CreateTicketDtoPriorityEnum _$createTicketDtoPriorityEnum_HIGH =
    const CreateTicketDtoPriorityEnum._('HIGH');
const CreateTicketDtoPriorityEnum _$createTicketDtoPriorityEnum_URGENT =
    const CreateTicketDtoPriorityEnum._('URGENT');

CreateTicketDtoPriorityEnum _$createTicketDtoPriorityEnumValueOf(String name) {
  switch (name) {
    case 'LOW':
      return _$createTicketDtoPriorityEnum_LOW;
    case 'MEDIUM':
      return _$createTicketDtoPriorityEnum_MEDIUM;
    case 'HIGH':
      return _$createTicketDtoPriorityEnum_HIGH;
    case 'URGENT':
      return _$createTicketDtoPriorityEnum_URGENT;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CreateTicketDtoPriorityEnum>
_$createTicketDtoPriorityEnumValues =
    BuiltSet<CreateTicketDtoPriorityEnum>(const <CreateTicketDtoPriorityEnum>[
      _$createTicketDtoPriorityEnum_LOW,
      _$createTicketDtoPriorityEnum_MEDIUM,
      _$createTicketDtoPriorityEnum_HIGH,
      _$createTicketDtoPriorityEnum_URGENT,
    ]);

Serializer<CreateTicketDtoCategoryEnum>
_$createTicketDtoCategoryEnumSerializer =
    _$CreateTicketDtoCategoryEnumSerializer();
Serializer<CreateTicketDtoPriorityEnum>
_$createTicketDtoPriorityEnumSerializer =
    _$CreateTicketDtoPriorityEnumSerializer();

class _$CreateTicketDtoCategoryEnumSerializer
    implements PrimitiveSerializer<CreateTicketDtoCategoryEnum> {
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
  final Iterable<Type> types = const <Type>[CreateTicketDtoCategoryEnum];
  @override
  final String wireName = 'CreateTicketDtoCategoryEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateTicketDtoCategoryEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateTicketDtoCategoryEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateTicketDtoCategoryEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateTicketDtoPriorityEnumSerializer
    implements PrimitiveSerializer<CreateTicketDtoPriorityEnum> {
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
  final Iterable<Type> types = const <Type>[CreateTicketDtoPriorityEnum];
  @override
  final String wireName = 'CreateTicketDtoPriorityEnum';

  @override
  Object serialize(
    Serializers serializers,
    CreateTicketDtoPriorityEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CreateTicketDtoPriorityEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CreateTicketDtoPriorityEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CreateTicketDto extends CreateTicketDto {
  @override
  final String subject;
  @override
  final String? description;
  @override
  final CreateTicketDtoCategoryEnum? category;
  @override
  final String? subCategory;
  @override
  final JsonObject? metadata;
  @override
  final CreateTicketDtoPriorityEnum? priority;
  @override
  final String? orderId;
  @override
  final String? vendorId;

  factory _$CreateTicketDto([void Function(CreateTicketDtoBuilder)? updates]) =>
      (CreateTicketDtoBuilder()..update(updates))._build();

  _$CreateTicketDto._({
    required this.subject,
    this.description,
    this.category,
    this.subCategory,
    this.metadata,
    this.priority,
    this.orderId,
    this.vendorId,
  }) : super._();
  @override
  CreateTicketDto rebuild(void Function(CreateTicketDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreateTicketDtoBuilder toBuilder() => CreateTicketDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreateTicketDto &&
        subject == other.subject &&
        description == other.description &&
        category == other.category &&
        subCategory == other.subCategory &&
        metadata == other.metadata &&
        priority == other.priority &&
        orderId == other.orderId &&
        vendorId == other.vendorId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, subject.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, subCategory.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jc(_$hash, priority.hashCode);
    _$hash = $jc(_$hash, orderId.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreateTicketDto')
          ..add('subject', subject)
          ..add('description', description)
          ..add('category', category)
          ..add('subCategory', subCategory)
          ..add('metadata', metadata)
          ..add('priority', priority)
          ..add('orderId', orderId)
          ..add('vendorId', vendorId))
        .toString();
  }
}

class CreateTicketDtoBuilder
    implements Builder<CreateTicketDto, CreateTicketDtoBuilder> {
  _$CreateTicketDto? _$v;

  String? _subject;
  String? get subject => _$this._subject;
  set subject(String? subject) => _$this._subject = subject;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  CreateTicketDtoCategoryEnum? _category;
  CreateTicketDtoCategoryEnum? get category => _$this._category;
  set category(CreateTicketDtoCategoryEnum? category) =>
      _$this._category = category;

  String? _subCategory;
  String? get subCategory => _$this._subCategory;
  set subCategory(String? subCategory) => _$this._subCategory = subCategory;

  JsonObject? _metadata;
  JsonObject? get metadata => _$this._metadata;
  set metadata(JsonObject? metadata) => _$this._metadata = metadata;

  CreateTicketDtoPriorityEnum? _priority;
  CreateTicketDtoPriorityEnum? get priority => _$this._priority;
  set priority(CreateTicketDtoPriorityEnum? priority) =>
      _$this._priority = priority;

  String? _orderId;
  String? get orderId => _$this._orderId;
  set orderId(String? orderId) => _$this._orderId = orderId;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  CreateTicketDtoBuilder() {
    CreateTicketDto._defaults(this);
  }

  CreateTicketDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _subject = $v.subject;
      _description = $v.description;
      _category = $v.category;
      _subCategory = $v.subCategory;
      _metadata = $v.metadata;
      _priority = $v.priority;
      _orderId = $v.orderId;
      _vendorId = $v.vendorId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreateTicketDto other) {
    _$v = other as _$CreateTicketDto;
  }

  @override
  void update(void Function(CreateTicketDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreateTicketDto build() => _build();

  _$CreateTicketDto _build() {
    final _$result =
        _$v ??
        _$CreateTicketDto._(
          subject: BuiltValueNullFieldError.checkNotNull(
            subject,
            r'CreateTicketDto',
            'subject',
          ),
          description: description,
          category: category,
          subCategory: subCategory,
          metadata: metadata,
          priority: priority,
          orderId: orderId,
          vendorId: vendorId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
