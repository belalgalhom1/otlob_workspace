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
  final num commissionRate;
  @override
  final JsonObject? status;
  @override
  final num walletBalance;
  @override
  final bool isContracted;
  @override
  final JsonObject? workingHours;
  @override
  final bool isScheduleActive;
  @override
  final String verticalId;
  @override
  final DateTime? deletedAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final BuiltList<AuditLog> auditLogs;
  @override
  final BuiltList<Cart> carts;
  @override
  final BuiltList<Conversation> conversations;
  @override
  final BuiltList<FavoriteVendor> favoritedBy;
  @override
  final BuiltList<MenuCategory> categories;
  @override
  final BuiltList<Order> orders;
  @override
  final BuiltList<Product> products;
  @override
  final BuiltList<SupportTicket> supportTickets;
  @override
  final BuiltList<VendorBranch> branches;
  @override
  final BuiltList<VendorMember> members;
  @override
  final BuiltList<VendorStatistic> statistics;
  @override
  final BuiltList<VendorWalletTransaction> walletTransactions;
  @override
  final BuiltList<Promotion> promotions;
  @override
  final BuiltList<Offer> offers;
  @override
  final JsonObject? vertical;

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
    required this.commissionRate,
    this.status,
    required this.walletBalance,
    required this.isContracted,
    this.workingHours,
    required this.isScheduleActive,
    required this.verticalId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.auditLogs,
    required this.carts,
    required this.conversations,
    required this.favoritedBy,
    required this.categories,
    required this.orders,
    required this.products,
    required this.supportTickets,
    required this.branches,
    required this.members,
    required this.statistics,
    required this.walletTransactions,
    required this.promotions,
    required this.offers,
    this.vertical,
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
        commissionRate == other.commissionRate &&
        status == other.status &&
        walletBalance == other.walletBalance &&
        isContracted == other.isContracted &&
        workingHours == other.workingHours &&
        isScheduleActive == other.isScheduleActive &&
        verticalId == other.verticalId &&
        deletedAt == other.deletedAt &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        auditLogs == other.auditLogs &&
        carts == other.carts &&
        conversations == other.conversations &&
        favoritedBy == other.favoritedBy &&
        categories == other.categories &&
        orders == other.orders &&
        products == other.products &&
        supportTickets == other.supportTickets &&
        branches == other.branches &&
        members == other.members &&
        statistics == other.statistics &&
        walletTransactions == other.walletTransactions &&
        promotions == other.promotions &&
        offers == other.offers &&
        vertical == other.vertical;
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
    _$hash = $jc(_$hash, commissionRate.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, walletBalance.hashCode);
    _$hash = $jc(_$hash, isContracted.hashCode);
    _$hash = $jc(_$hash, workingHours.hashCode);
    _$hash = $jc(_$hash, isScheduleActive.hashCode);
    _$hash = $jc(_$hash, verticalId.hashCode);
    _$hash = $jc(_$hash, deletedAt.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, auditLogs.hashCode);
    _$hash = $jc(_$hash, carts.hashCode);
    _$hash = $jc(_$hash, conversations.hashCode);
    _$hash = $jc(_$hash, favoritedBy.hashCode);
    _$hash = $jc(_$hash, categories.hashCode);
    _$hash = $jc(_$hash, orders.hashCode);
    _$hash = $jc(_$hash, products.hashCode);
    _$hash = $jc(_$hash, supportTickets.hashCode);
    _$hash = $jc(_$hash, branches.hashCode);
    _$hash = $jc(_$hash, members.hashCode);
    _$hash = $jc(_$hash, statistics.hashCode);
    _$hash = $jc(_$hash, walletTransactions.hashCode);
    _$hash = $jc(_$hash, promotions.hashCode);
    _$hash = $jc(_$hash, offers.hashCode);
    _$hash = $jc(_$hash, vertical.hashCode);
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
          ..add('commissionRate', commissionRate)
          ..add('status', status)
          ..add('walletBalance', walletBalance)
          ..add('isContracted', isContracted)
          ..add('workingHours', workingHours)
          ..add('isScheduleActive', isScheduleActive)
          ..add('verticalId', verticalId)
          ..add('deletedAt', deletedAt)
          ..add('createdAt', createdAt)
          ..add('updatedAt', updatedAt)
          ..add('auditLogs', auditLogs)
          ..add('carts', carts)
          ..add('conversations', conversations)
          ..add('favoritedBy', favoritedBy)
          ..add('categories', categories)
          ..add('orders', orders)
          ..add('products', products)
          ..add('supportTickets', supportTickets)
          ..add('branches', branches)
          ..add('members', members)
          ..add('statistics', statistics)
          ..add('walletTransactions', walletTransactions)
          ..add('promotions', promotions)
          ..add('offers', offers)
          ..add('vertical', vertical))
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

  num? _commissionRate;
  num? get commissionRate => _$this._commissionRate;
  set commissionRate(num? commissionRate) =>
      _$this._commissionRate = commissionRate;

  JsonObject? _status;
  JsonObject? get status => _$this._status;
  set status(JsonObject? status) => _$this._status = status;

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

  ListBuilder<AuditLog>? _auditLogs;
  ListBuilder<AuditLog> get auditLogs =>
      _$this._auditLogs ??= ListBuilder<AuditLog>();
  set auditLogs(ListBuilder<AuditLog>? auditLogs) =>
      _$this._auditLogs = auditLogs;

  ListBuilder<Cart>? _carts;
  ListBuilder<Cart> get carts => _$this._carts ??= ListBuilder<Cart>();
  set carts(ListBuilder<Cart>? carts) => _$this._carts = carts;

  ListBuilder<Conversation>? _conversations;
  ListBuilder<Conversation> get conversations =>
      _$this._conversations ??= ListBuilder<Conversation>();
  set conversations(ListBuilder<Conversation>? conversations) =>
      _$this._conversations = conversations;

  ListBuilder<FavoriteVendor>? _favoritedBy;
  ListBuilder<FavoriteVendor> get favoritedBy =>
      _$this._favoritedBy ??= ListBuilder<FavoriteVendor>();
  set favoritedBy(ListBuilder<FavoriteVendor>? favoritedBy) =>
      _$this._favoritedBy = favoritedBy;

  ListBuilder<MenuCategory>? _categories;
  ListBuilder<MenuCategory> get categories =>
      _$this._categories ??= ListBuilder<MenuCategory>();
  set categories(ListBuilder<MenuCategory>? categories) =>
      _$this._categories = categories;

  ListBuilder<Order>? _orders;
  ListBuilder<Order> get orders => _$this._orders ??= ListBuilder<Order>();
  set orders(ListBuilder<Order>? orders) => _$this._orders = orders;

  ListBuilder<Product>? _products;
  ListBuilder<Product> get products =>
      _$this._products ??= ListBuilder<Product>();
  set products(ListBuilder<Product>? products) => _$this._products = products;

  ListBuilder<SupportTicket>? _supportTickets;
  ListBuilder<SupportTicket> get supportTickets =>
      _$this._supportTickets ??= ListBuilder<SupportTicket>();
  set supportTickets(ListBuilder<SupportTicket>? supportTickets) =>
      _$this._supportTickets = supportTickets;

  ListBuilder<VendorBranch>? _branches;
  ListBuilder<VendorBranch> get branches =>
      _$this._branches ??= ListBuilder<VendorBranch>();
  set branches(ListBuilder<VendorBranch>? branches) =>
      _$this._branches = branches;

  ListBuilder<VendorMember>? _members;
  ListBuilder<VendorMember> get members =>
      _$this._members ??= ListBuilder<VendorMember>();
  set members(ListBuilder<VendorMember>? members) => _$this._members = members;

  ListBuilder<VendorStatistic>? _statistics;
  ListBuilder<VendorStatistic> get statistics =>
      _$this._statistics ??= ListBuilder<VendorStatistic>();
  set statistics(ListBuilder<VendorStatistic>? statistics) =>
      _$this._statistics = statistics;

  ListBuilder<VendorWalletTransaction>? _walletTransactions;
  ListBuilder<VendorWalletTransaction> get walletTransactions =>
      _$this._walletTransactions ??= ListBuilder<VendorWalletTransaction>();
  set walletTransactions(
    ListBuilder<VendorWalletTransaction>? walletTransactions,
  ) => _$this._walletTransactions = walletTransactions;

  ListBuilder<Promotion>? _promotions;
  ListBuilder<Promotion> get promotions =>
      _$this._promotions ??= ListBuilder<Promotion>();
  set promotions(ListBuilder<Promotion>? promotions) =>
      _$this._promotions = promotions;

  ListBuilder<Offer>? _offers;
  ListBuilder<Offer> get offers => _$this._offers ??= ListBuilder<Offer>();
  set offers(ListBuilder<Offer>? offers) => _$this._offers = offers;

  JsonObject? _vertical;
  JsonObject? get vertical => _$this._vertical;
  set vertical(JsonObject? vertical) => _$this._vertical = vertical;

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
      _commissionRate = $v.commissionRate;
      _status = $v.status;
      _walletBalance = $v.walletBalance;
      _isContracted = $v.isContracted;
      _workingHours = $v.workingHours;
      _isScheduleActive = $v.isScheduleActive;
      _verticalId = $v.verticalId;
      _deletedAt = $v.deletedAt;
      _createdAt = $v.createdAt;
      _updatedAt = $v.updatedAt;
      _auditLogs = $v.auditLogs.toBuilder();
      _carts = $v.carts.toBuilder();
      _conversations = $v.conversations.toBuilder();
      _favoritedBy = $v.favoritedBy.toBuilder();
      _categories = $v.categories.toBuilder();
      _orders = $v.orders.toBuilder();
      _products = $v.products.toBuilder();
      _supportTickets = $v.supportTickets.toBuilder();
      _branches = $v.branches.toBuilder();
      _members = $v.members.toBuilder();
      _statistics = $v.statistics.toBuilder();
      _walletTransactions = $v.walletTransactions.toBuilder();
      _promotions = $v.promotions.toBuilder();
      _offers = $v.offers.toBuilder();
      _vertical = $v.vertical;
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
    _$Vendor _$result;
    try {
      _$result =
          _$v ??
          _$Vendor._(
            id: BuiltValueNullFieldError.checkNotNull(id, r'Vendor', 'id'),
            storeName: BuiltValueNullFieldError.checkNotNull(
              storeName,
              r'Vendor',
              'storeName',
            ),
            storeNameAr: storeNameAr,
            slug: BuiltValueNullFieldError.checkNotNull(
              slug,
              r'Vendor',
              'slug',
            ),
            description: description,
            descriptionAr: descriptionAr,
            logo: logo,
            coverImage: coverImage,
            phone: phone,
            taxId: taxId,
            commissionRate: BuiltValueNullFieldError.checkNotNull(
              commissionRate,
              r'Vendor',
              'commissionRate',
            ),
            status: status,
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
            auditLogs: auditLogs.build(),
            carts: carts.build(),
            conversations: conversations.build(),
            favoritedBy: favoritedBy.build(),
            categories: categories.build(),
            orders: orders.build(),
            products: products.build(),
            supportTickets: supportTickets.build(),
            branches: branches.build(),
            members: members.build(),
            statistics: statistics.build(),
            walletTransactions: walletTransactions.build(),
            promotions: promotions.build(),
            offers: offers.build(),
            vertical: vertical,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'auditLogs';
        auditLogs.build();
        _$failedField = 'carts';
        carts.build();
        _$failedField = 'conversations';
        conversations.build();
        _$failedField = 'favoritedBy';
        favoritedBy.build();
        _$failedField = 'categories';
        categories.build();
        _$failedField = 'orders';
        orders.build();
        _$failedField = 'products';
        products.build();
        _$failedField = 'supportTickets';
        supportTickets.build();
        _$failedField = 'branches';
        branches.build();
        _$failedField = 'members';
        members.build();
        _$failedField = 'statistics';
        statistics.build();
        _$failedField = 'walletTransactions';
        walletTransactions.build();
        _$failedField = 'promotions';
        promotions.build();
        _$failedField = 'offers';
        offers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'Vendor',
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
