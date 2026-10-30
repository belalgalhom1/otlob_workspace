// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Vendor extends Vendor {
  @override
  final String id;
  @override
  final String storeName;
  @override
  final String? storeNameAr;
  @override
  final String slug;
  @override
  final String? description;
  @override
  final String? descriptionAr;
  @override
  final String? logo;
  @override
  final String? coverImage;
  @override
  final String? phone;
  @override
  final String? taxId;
  @override
  final num rating;
  @override
  final num ratingCount;
  @override
  final num commissionRate;
  @override
  final VendorStatus status;
  @override
  final num walletBalance;
  @override
  final bool isContracted;
  @override
  final JsonObject? workingHours;
  @override
  final bool isScheduleActive;
  @override
  final bool is24Hours;
  @override
  final String verticalId;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  factory _$Vendor([void Function(VendorBuilder)? updates]) =>
      (VendorBuilder()..update(updates))._build();

  _$Vendor._({
    required this.id,
    required this.storeName,
    this.storeNameAr,
    required this.slug,
    this.description,
    this.descriptionAr,
    this.logo,
    this.coverImage,
    this.phone,
    this.taxId,
    required this.rating,
    required this.ratingCount,
    required this.commissionRate,
    required this.status,
    required this.walletBalance,
    required this.isContracted,
    this.workingHours,
    required this.isScheduleActive,
    required this.is24Hours,
    required this.verticalId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : super._();
  @override
  Vendor rebuild(void Function(VendorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VendorBuilder toBuilder() => VendorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Vendor &&
        id == other.id &&
        storeName == other.storeName &&
        storeNameAr == other.storeNameAr &&
        slug == other.slug &&
        description == other.description &&
        descriptionAr == other.descriptionAr &&
        logo == other.logo &&
        coverImage == other.coverImage &&
        phone == other.phone &&
        taxId == other.taxId &&
        rating == other.rating &&
        ratingCount == other.ratingCount &&
        commissionRate == other.commissionRate &&
        status == other.status &&
        walletBalance == other.walletBalance &&
        isContracted == other.isContracted &&
        workingHours == other.workingHours &&
        isScheduleActive == other.isScheduleActive &&
        is24Hours == other.is24Hours &&
        verticalId == other.verticalId &&
        deletedAt == other.deletedAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, storeName.hashCode);
    _$hash = $jc(_$hash, storeNameAr.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, descriptionAr.hashCode);
    _$hash = $jc(_$hash, logo.hashCode);
    _$hash = $jc(_$hash, coverImage.hashCode);
    _$hash = $jc(_$hash, phone.hashCode);
    _$hash = $jc(_$hash, taxId.hashCode);
    _$hash = $jc(_$hash, rating.hashCode);
    _$hash = $jc(_$hash, ratingCount.hashCode);
    _$hash = $jc(_$hash, commissionRate.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, walletBalance.hashCode);
    _$hash = $jc(_$hash, isContracted.hashCode);
    _$hash = $jc(_$hash, workingHours.hashCode);
    _$hash = $jc(_$hash, isScheduleActive.hashCode);
    _$hash = $jc(_$hash, is24Hours.hashCode);
    _$hash = $jc(_$hash, verticalId.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Vendor')
          ..add('id', id)
          ..add('storeName', storeName)
          ..add('storeNameAr', storeNameAr)
          ..add('slug', slug)
          ..add('description', description)
          ..add('descriptionAr', descriptionAr)
          ..add('logo', logo)
          ..add('coverImage', coverImage)
          ..add('phone', phone)
          ..add('taxId', taxId)
          ..add('rating', rating)
          ..add('ratingCount', ratingCount)
          ..add('commissionRate', commissionRate)
          ..add('status', status)
          ..add('walletBalance', walletBalance)
          ..add('isContracted', isContracted)
          ..add('workingHours', workingHours)
          ..add('isScheduleActive', isScheduleActive)
          ..add('is24Hours', is24Hours)
          ..add('verticalId', verticalId)
          ..add('deletedAt', deletedAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class VendorBuilder implements Builder<Vendor, VendorBuilder> {
  _$Vendor? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _storeName;
  String? get storeName => _$this._storeName;
  set storeName(String? storeName) => _$this._storeName = storeName;

  String? _storeNameAr;
  String? get storeNameAr => _$this._storeNameAr;
  set storeNameAr(String? storeNameAr) => _$this._storeNameAr = storeNameAr;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _descriptionAr;
  String? get descriptionAr => _$this._descriptionAr;
  set descriptionAr(String? descriptionAr) =>
      _$this._descriptionAr = descriptionAr;

  String? _logo;
  String? get logo => _$this._logo;
  set logo(String? logo) => _$this._logo = logo;

  String? _coverImage;
  String? get coverImage => _$this._coverImage;
  set coverImage(String? coverImage) => _$this._coverImage = coverImage;

  String? _phone;
  String? get phone => _$this._phone;
  set phone(String? phone) => _$this._phone = phone;

  String? _taxId;
  String? get taxId => _$this._taxId;
  set taxId(String? taxId) => _$this._taxId = taxId;

  num? _rating;
  num? get rating => _$this._rating;
  set rating(num? rating) => _$this._rating = rating;

  num? _ratingCount;
  num? get ratingCount => _$this._ratingCount;
  set ratingCount(num? ratingCount) => _$this._ratingCount = ratingCount;

  num? _commissionRate;
  num? get commissionRate => _$this._commissionRate;
  set commissionRate(num? commissionRate) =>
      _$this._commissionRate = commissionRate;

  VendorStatus? _status;
  VendorStatus? get status => _$this._status;
  set status(VendorStatus? status) => _$this._status = status;

  num? _walletBalance;
  num? get walletBalance => _$this._walletBalance;
  set walletBalance(num? walletBalance) =>
      _$this._walletBalance = walletBalance;

  bool? _isContracted;
  bool? get isContracted => _$this._isContracted;
  set isContracted(bool? isContracted) => _$this._isContracted = isContracted;

  JsonObject? _workingHours;
  JsonObject? get workingHours => _$this._workingHours;
  set workingHours(JsonObject? workingHours) =>
      _$this._workingHours = workingHours;

  bool? _isScheduleActive;
  bool? get isScheduleActive => _$this._isScheduleActive;
  set isScheduleActive(bool? isScheduleActive) =>
      _$this._isScheduleActive = isScheduleActive;

  bool? _is24Hours;
  bool? get is24Hours => _$this._is24Hours;
  set is24Hours(bool? is24Hours) => _$this._is24Hours = is24Hours;

  String? _verticalId;
  String? get verticalId => _$this._verticalId;
  set verticalId(String? verticalId) => _$this._verticalId = verticalId;

  DateTime? _deletedAt;
  DateTime? get deletedAt => _$this._deletedAt;
  set deletedAt(DateTime? deletedAt) => _$this._deletedAt = deletedAt;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  VendorBuilder() {
    Vendor._defaults(this);
  }

  VendorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _storeName = $v.storeName;
      _storeNameAr = $v.storeNameAr;
      _slug = $v.slug;
      _description = $v.description;
      _descriptionAr = $v.descriptionAr;
      _logo = $v.logo;
      _coverImage = $v.coverImage;
      _phone = $v.phone;
      _taxId = $v.taxId;
      _rating = $v.rating;
      _ratingCount = $v.ratingCount;
      _commissionRate = $v.commissionRate;
      _status = $v.status;
      _walletBalance = $v.walletBalance;
      _isContracted = $v.isContracted;
      _workingHours = $v.workingHours;
      _isScheduleActive = $v.isScheduleActive;
      _is24Hours = $v.is24Hours;
      _verticalId = $v.verticalId;
      _deletedAt = $v.deletedAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Vendor other) {
    _$v = other as _$Vendor;
  }

  @override
  void update(void Function(VendorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Vendor build() => _build();

  _$Vendor _build() {
    final _$result =
        _$v ??
        _$Vendor._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'Vendor', 'id'),
          storeName: BuiltValueNullFieldError.checkNotNull(
            storeName,
            r'Vendor',
            'storeName',
          ),
          storeNameAr: storeNameAr,
          slug: BuiltValueNullFieldError.checkNotNull(slug, r'Vendor', 'slug'),
          description: description,
          descriptionAr: descriptionAr,
          logo: logo,
          coverImage: coverImage,
          phone: phone,
          taxId: taxId,
          rating: BuiltValueNullFieldError.checkNotNull(
            rating,
            r'Vendor',
            'rating',
          ),
          ratingCount: BuiltValueNullFieldError.checkNotNull(
            ratingCount,
            r'Vendor',
            'ratingCount',
          ),
          commissionRate: BuiltValueNullFieldError.checkNotNull(
            commissionRate,
            r'Vendor',
            'commissionRate',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'Vendor',
            'status',
          ),
          walletBalance: BuiltValueNullFieldError.checkNotNull(
            walletBalance,
            r'Vendor',
            'walletBalance',
          ),
          isContracted: BuiltValueNullFieldError.checkNotNull(
            isContracted,
            r'Vendor',
            'isContracted',
          ),
          workingHours: workingHours,
          isScheduleActive: BuiltValueNullFieldError.checkNotNull(
            isScheduleActive,
            r'Vendor',
            'isScheduleActive',
          ),
          is24Hours: BuiltValueNullFieldError.checkNotNull(
            is24Hours,
            r'Vendor',
            'is24Hours',
          ),
          verticalId: BuiltValueNullFieldError.checkNotNull(
            verticalId,
            r'Vendor',
            'verticalId',
          ),
          deletedAt: deletedAt,
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'Vendor',
            'createdAt',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'Vendor',
            'updatedAt',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
