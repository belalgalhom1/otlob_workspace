// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_wallet_top_up_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ReviewWalletTopUpDtoStatusEnum _$reviewWalletTopUpDtoStatusEnum_APPROVED =
    const ReviewWalletTopUpDtoStatusEnum._('APPROVED');
const ReviewWalletTopUpDtoStatusEnum _$reviewWalletTopUpDtoStatusEnum_REJECTED =
    const ReviewWalletTopUpDtoStatusEnum._('REJECTED');

ReviewWalletTopUpDtoStatusEnum _$reviewWalletTopUpDtoStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'APPROVED':
      return _$reviewWalletTopUpDtoStatusEnum_APPROVED;
    case 'REJECTED':
      return _$reviewWalletTopUpDtoStatusEnum_REJECTED;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ReviewWalletTopUpDtoStatusEnum>
_$reviewWalletTopUpDtoStatusEnumValues =
    BuiltSet<ReviewWalletTopUpDtoStatusEnum>(
      const <ReviewWalletTopUpDtoStatusEnum>[
        _$reviewWalletTopUpDtoStatusEnum_APPROVED,
        _$reviewWalletTopUpDtoStatusEnum_REJECTED,
      ],
    );

Serializer<ReviewWalletTopUpDtoStatusEnum>
_$reviewWalletTopUpDtoStatusEnumSerializer =
    _$ReviewWalletTopUpDtoStatusEnumSerializer();

class _$ReviewWalletTopUpDtoStatusEnumSerializer
    implements PrimitiveSerializer<ReviewWalletTopUpDtoStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'APPROVED': 'APPROVED',
    'REJECTED': 'REJECTED',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'APPROVED': 'APPROVED',
    'REJECTED': 'REJECTED',
  };

  @override
  final Iterable<Type> types = const <Type>[ReviewWalletTopUpDtoStatusEnum];
  @override
  final String wireName = 'ReviewWalletTopUpDtoStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    ReviewWalletTopUpDtoStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ReviewWalletTopUpDtoStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ReviewWalletTopUpDtoStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ReviewWalletTopUpDto extends ReviewWalletTopUpDto {
  @override
  final ReviewWalletTopUpDtoStatusEnum status;
  @override
  final String? notes;

  factory _$ReviewWalletTopUpDto([
    void Function(ReviewWalletTopUpDtoBuilder)? updates,
  ]) => (ReviewWalletTopUpDtoBuilder()..update(updates))._build();

  _$ReviewWalletTopUpDto._({required this.status, this.notes}) : super._();
  @override
  ReviewWalletTopUpDto rebuild(
    void Function(ReviewWalletTopUpDtoBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ReviewWalletTopUpDtoBuilder toBuilder() =>
      ReviewWalletTopUpDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReviewWalletTopUpDto &&
        status == other.status &&
        notes == other.notes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, notes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReviewWalletTopUpDto')
          ..add('status', status)
          ..add('notes', notes))
        .toString();
  }
}

class ReviewWalletTopUpDtoBuilder
    implements Builder<ReviewWalletTopUpDto, ReviewWalletTopUpDtoBuilder> {
  _$ReviewWalletTopUpDto? _$v;

  ReviewWalletTopUpDtoStatusEnum? _status;
  ReviewWalletTopUpDtoStatusEnum? get status => _$this._status;
  set status(ReviewWalletTopUpDtoStatusEnum? status) => _$this._status = status;

  String? _notes;
  String? get notes => _$this._notes;
  set notes(String? notes) => _$this._notes = notes;

  ReviewWalletTopUpDtoBuilder() {
    ReviewWalletTopUpDto._defaults(this);
  }

  ReviewWalletTopUpDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _notes = $v.notes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReviewWalletTopUpDto other) {
    _$v = other as _$ReviewWalletTopUpDto;
  }

  @override
  void update(void Function(ReviewWalletTopUpDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReviewWalletTopUpDto build() => _build();

  _$ReviewWalletTopUpDto _build() {
    final _$result =
        _$v ??
        _$ReviewWalletTopUpDto._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'ReviewWalletTopUpDto',
            'status',
          ),
          notes: notes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
