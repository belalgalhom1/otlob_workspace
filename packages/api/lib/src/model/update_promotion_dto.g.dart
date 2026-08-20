// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_promotion_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdatePromotionDtoTypeEnum _$updatePromotionDtoTypeEnum_BANNER =
    const UpdatePromotionDtoTypeEnum._('BANNER');
const UpdatePromotionDtoTypeEnum _$updatePromotionDtoTypeEnum_VENDOR =
    const UpdatePromotionDtoTypeEnum._('VENDOR');
const UpdatePromotionDtoTypeEnum _$updatePromotionDtoTypeEnum_PRODUCT =
    const UpdatePromotionDtoTypeEnum._('PRODUCT');
const UpdatePromotionDtoTypeEnum _$updatePromotionDtoTypeEnum_EXTERNAL_LINK =
    const UpdatePromotionDtoTypeEnum._('EXTERNAL_LINK');
const UpdatePromotionDtoTypeEnum _$updatePromotionDtoTypeEnum_POPUP =
    const UpdatePromotionDtoTypeEnum._('POPUP');
const UpdatePromotionDtoTypeEnum _$updatePromotionDtoTypeEnum_NOTIFICATION =
    const UpdatePromotionDtoTypeEnum._('NOTIFICATION');

UpdatePromotionDtoTypeEnum _$updatePromotionDtoTypeEnumValueOf(String name) {
  switch (name) {
    case 'BANNER':
      return _$updatePromotionDtoTypeEnum_BANNER;
    case 'VENDOR':
      return _$updatePromotionDtoTypeEnum_VENDOR;
    case 'PRODUCT':
      return _$updatePromotionDtoTypeEnum_PRODUCT;
    case 'EXTERNAL_LINK':
      return _$updatePromotionDtoTypeEnum_EXTERNAL_LINK;
    case 'POPUP':
      return _$updatePromotionDtoTypeEnum_POPUP;
    case 'NOTIFICATION':
      return _$updatePromotionDtoTypeEnum_NOTIFICATION;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdatePromotionDtoTypeEnum> _$updatePromotionDtoTypeEnumValues =
    BuiltSet<UpdatePromotionDtoTypeEnum>(const <UpdatePromotionDtoTypeEnum>[
      _$updatePromotionDtoTypeEnum_BANNER,
      _$updatePromotionDtoTypeEnum_VENDOR,
      _$updatePromotionDtoTypeEnum_PRODUCT,
      _$updatePromotionDtoTypeEnum_EXTERNAL_LINK,
      _$updatePromotionDtoTypeEnum_POPUP,
      _$updatePromotionDtoTypeEnum_NOTIFICATION,
    ]);

Serializer<UpdatePromotionDtoTypeEnum> _$updatePromotionDtoTypeEnumSerializer =
    _$UpdatePromotionDtoTypeEnumSerializer();

class _$UpdatePromotionDtoTypeEnumSerializer
    implements PrimitiveSerializer<UpdatePromotionDtoTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'BANNER': 'BANNER',
    'VENDOR': 'VENDOR',
    'PRODUCT': 'PRODUCT',
    'EXTERNAL_LINK': 'EXTERNAL_LINK',
    'POPUP': 'POPUP',
    'NOTIFICATION': 'NOTIFICATION',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'BANNER': 'BANNER',
    'VENDOR': 'VENDOR',
    'PRODUCT': 'PRODUCT',
    'EXTERNAL_LINK': 'EXTERNAL_LINK',
    'POPUP': 'POPUP',
    'NOTIFICATION': 'NOTIFICATION',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdatePromotionDtoTypeEnum];
  @override
  final String wireName = 'UpdatePromotionDtoTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdatePromotionDtoTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdatePromotionDtoTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdatePromotionDtoTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdatePromotionDto extends UpdatePromotionDto {
  @override
  final String? title;
  @override
  final String? titleAr;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final UpdatePromotionDtoTypeEnum? type;
  @override
  final String? vendorId;
  @override
  final String? productId;
  @override
  final String? externalUrl;
  @override
  final bool? isActive;
  @override
  final num? sortOrder;
  @override
  final DateTime? startDate;
  @override
  final DateTime? endDate;

  factory _$UpdatePromotionDto([
    void Function(UpdatePromotionDtoBuilder)? updates,
  ]) => (UpdatePromotionDtoBuilder()..update(updates))._build();

  _$UpdatePromotionDto._({
    this.title,
    this.titleAr,
    this.description,
    this.descriptionAr,
    this.type,
    this.vendorId,
    this.productId,
    this.externalUrl,
    this.isActive,
    this.sortOrder,
    this.startDate,
    this.endDate,
  }) : super._();
  @override
  UpdatePromotionDto rebuild(
    void Function(UpdatePromotionDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  UpdatePromotionDtoBuilder toBuilder() =>
      UpdatePromotionDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdatePromotionDto &&
        title == other.title &&
        titleAr == other.titleAr &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        type == other.type &&
        vendorId == other.vendorId &&
        productId == other.productId &&
        externalUrl == other.externalUrl &&
        isActive == other.isActive &&
        sortOrder == other.sortOrder &&
        startDate == other.startDate &&
        endDate == other.endDate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, titleAr.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, vendorId.hashCode);
    _$hash = $jc(_$hash, productId.hashCode);
    _$hash = $jc(_$hash, externalUrl.hashCode);
    _$hash = $jc(_$hash, isActive.hashCode);
    _$hash = $jc(_$hash, sortOrder.hashCode);
    _$hash = $jc(_$hash, startDate.hashCode);
    _$hash = $jc(_$hash, endDate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdatePromotionDto')
          ..add('title', title)
          ..add('titleAr', titleAr)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('type', type)
          ..add('vendorId', vendorId)
          ..add('productId', productId)
          ..add('externalUrl', externalUrl)
          ..add('isActive', isActive)
          ..add('sortOrder', sortOrder)
          ..add('startDate', startDate)
          ..add('endDate', endDate))
        .toString();
  }
}

class UpdatePromotionDtoBuilder
    implements Builder<UpdatePromotionDto, UpdatePromotionDtoBuilder> {
  _$UpdatePromotionDto? _$v;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  String? _titleAr;
  String? get titleAr => _$this._titleAr;
  set titleAr(String? titleAr) => _$this._titleAr = titleAr;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _descriptionAr;
  String? get descriptionAr => _$this._descriptionAr;
  set descriptionAr(String? descriptionAr) =>
      _$this._descriptionAr = descriptionAr;

  UpdatePromotionDtoTypeEnum? _type;
  UpdatePromotionDtoTypeEnum? get type => _$this._type;
  set type(UpdatePromotionDtoTypeEnum? type) => _$this._type = type;

  String? _vendorId;
  String? get vendorId => _$this._vendorId;
  set vendorId(String? vendorId) => _$this._vendorId = vendorId;

  String? _productId;
  String? get productId => _$this._productId;
  set productId(String? productId) => _$this._productId = productId;

  String? _externalUrl;
  String? get externalUrl => _$this._externalUrl;
  set externalUrl(String? externalUrl) => _$this._externalUrl = externalUrl;

  bool? _isActive;
  bool? get isActive => _$this._isActive;
  set isActive(bool? isActive) => _$this._isActive = isActive;

  num? _sortOrder;
  num? get sortOrder => _$this._sortOrder;
  set sortOrder(num? sortOrder) => _$this._sortOrder = sortOrder;

  DateTime? _startDate;
  DateTime? get startDate => _$this._startDate;
  set startDate(DateTime? startDate) => _$this._startDate = startDate;

  DateTime? _endDate;
  DateTime? get endDate => _$this._endDate;
  set endDate(DateTime? endDate) => _$this._endDate = endDate;

  UpdatePromotionDtoBuilder() {
    UpdatePromotionDto._defaults(this);
  }

  UpdatePromotionDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _title = $v.title;
      _titleAr = $v.titleAr;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _type = $v.type;
      _vendorId = $v.vendorId;
      _productId = $v.productId;
      _externalUrl = $v.externalUrl;
      _isActive = $v.isActive;
      _sortOrder = $v.sortOrder;
      _startDate = $v.startDate;
      _endDate = $v.endDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdatePromotionDto other) {
    _$v = other as _$UpdatePromotionDto;
  }

  @override
  void update(void Function(UpdatePromotionDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdatePromotionDto build() => _build();

  _$UpdatePromotionDto _build() {
    final _$result =
        _$v ??
        _$UpdatePromotionDto._(
          title: title,
          titleAr: titleAr,
          description: description,
          descriptionAr: descriptionAr,
          type: type,
          vendorId: vendorId,
          productId: productId,
          externalUrl: externalUrl,
          isActive: isActive,
          sortOrder: sortOrder,
          startDate: startDate,
          endDate: endDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
