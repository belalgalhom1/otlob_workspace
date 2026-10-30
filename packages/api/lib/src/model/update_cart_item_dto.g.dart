// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_cart_item_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const UpdateCartItemDtoSelectedUnitEnum
_$updateCartItemDtoSelectedUnitEnum_package =
    const UpdateCartItemDtoSelectedUnitEnum._('package');
const UpdateCartItemDtoSelectedUnitEnum
_$updateCartItemDtoSelectedUnitEnum_strip =
    const UpdateCartItemDtoSelectedUnitEnum._('strip');

UpdateCartItemDtoSelectedUnitEnum _$updateCartItemDtoSelectedUnitEnumValueOf(
  String name,
) {
  switch (name) {
    case 'package':
      return _$updateCartItemDtoSelectedUnitEnum_package;
    case 'strip':
      return _$updateCartItemDtoSelectedUnitEnum_strip;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<UpdateCartItemDtoSelectedUnitEnum>
_$updateCartItemDtoSelectedUnitEnumValues =
    BuiltSet<UpdateCartItemDtoSelectedUnitEnum>(
      const <UpdateCartItemDtoSelectedUnitEnum>[
        _$updateCartItemDtoSelectedUnitEnum_package,
        _$updateCartItemDtoSelectedUnitEnum_strip,
      ],
    );

Serializer<UpdateCartItemDtoSelectedUnitEnum>
_$updateCartItemDtoSelectedUnitEnumSerializer =
    _$UpdateCartItemDtoSelectedUnitEnumSerializer();

class _$UpdateCartItemDtoSelectedUnitEnumSerializer
    implements PrimitiveSerializer<UpdateCartItemDtoSelectedUnitEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'package': 'package',
    'strip': 'strip',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'package': 'package',
    'strip': 'strip',
  };

  @override
  final Iterable<Type> types = const <Type>[UpdateCartItemDtoSelectedUnitEnum];
  @override
  final String wireName = 'UpdateCartItemDtoSelectedUnitEnum';

  @override
  Object serialize(
    Serializers serializers,
    UpdateCartItemDtoSelectedUnitEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  UpdateCartItemDtoSelectedUnitEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => UpdateCartItemDtoSelectedUnitEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$UpdateCartItemDto extends UpdateCartItemDto {
  @override
  final num quantity;
  @override
  final BuiltList<String>? optionIds;
  @override
  final String? specialRequest;
  @override
  final UpdateCartItemDtoSelectedUnitEnum? selectedUnit;

  factory _$UpdateCartItemDto([
    void Function(UpdateCartItemDtoBuilder)? updates,
  ]) => (UpdateCartItemDtoBuilder()..update(updates))._build();

  _$UpdateCartItemDto._({
    required this.quantity,
    this.optionIds,
    this.specialRequest,
    this.selectedUnit,
  }) : super._();
  @override
  UpdateCartItemDto rebuild(void Function(UpdateCartItemDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UpdateCartItemDtoBuilder toBuilder() =>
      UpdateCartItemDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UpdateCartItemDto &&
        quantity == other.quantity &&
        optionIds == other.optionIds &&
        specialRequest == other.specialRequest &&
        selectedUnit == other.selectedUnit;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, quantity.hashCode);
    _$hash = $jc(_$hash, optionIds.hashCode);
    _$hash = $jc(_$hash, specialRequest.hashCode);
    _$hash = $jc(_$hash, selectedUnit.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'UpdateCartItemDto')
          ..add('quantity', quantity)
          ..add('optionIds', optionIds)
          ..add('specialRequest', specialRequest)
          ..add('selectedUnit', selectedUnit))
        .toString();
  }
}

class UpdateCartItemDtoBuilder
    implements Builder<UpdateCartItemDto, UpdateCartItemDtoBuilder> {
  _$UpdateCartItemDto? _$v;

  num? _quantity;
  num? get quantity => _$this._quantity;
  set quantity(num? quantity) => _$this._quantity = quantity;

  ListBuilder<String>? _optionIds;
  ListBuilder<String> get optionIds =>
      _$this._optionIds ??= ListBuilder<String>();
  set optionIds(ListBuilder<String>? optionIds) =>
      _$this._optionIds = optionIds;

  String? _specialRequest;
  String? get specialRequest => _$this._specialRequest;
  set specialRequest(String? specialRequest) =>
      _$this._specialRequest = specialRequest;

  UpdateCartItemDtoSelectedUnitEnum? _selectedUnit;
  UpdateCartItemDtoSelectedUnitEnum? get selectedUnit => _$this._selectedUnit;
  set selectedUnit(UpdateCartItemDtoSelectedUnitEnum? selectedUnit) =>
      _$this._selectedUnit = selectedUnit;

  UpdateCartItemDtoBuilder() {
    UpdateCartItemDto._defaults(this);
  }

  UpdateCartItemDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _quantity = $v.quantity;
      _optionIds = $v.optionIds?.toBuilder();
      _specialRequest = $v.specialRequest;
      _selectedUnit = $v.selectedUnit;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UpdateCartItemDto other) {
    _$v = other as _$UpdateCartItemDto;
  }

  @override
  void update(void Function(UpdateCartItemDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UpdateCartItemDto build() => _build();

  _$UpdateCartItemDto _build() {
    _$UpdateCartItemDto _$result;
    try {
      _$result =
          _$v ??
          _$UpdateCartItemDto._(
            quantity: BuiltValueNullFieldError.checkNotNull(
              quantity,
              r'UpdateCartItemDto',
              'quantity',
            ),
            optionIds: _optionIds?.build(),
            specialRequest: specialRequest,
            selectedUnit: selectedUnit,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'optionIds';
        _optionIds?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'UpdateCartItemDto',
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
