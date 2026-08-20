//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'wallet_transaction_type.g.dart';

class WalletTransactionType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'DELIVERY_FEE')
  static const WalletTransactionType DELIVERY_FEE = _$DELIVERY_FEE;
  @BuiltValueEnumConst(wireName: r'CASH_COLLECTED')
  static const WalletTransactionType CASH_COLLECTED = _$CASH_COLLECTED;
  @BuiltValueEnumConst(wireName: r'CASH_HANDED_TO_VENDOR')
  static const WalletTransactionType CASH_HANDED_TO_VENDOR = _$CASH_HANDED_TO_VENDOR;
  @BuiltValueEnumConst(wireName: r'PAYOUT')
  static const WalletTransactionType PAYOUT = _$PAYOUT;
  @BuiltValueEnumConst(wireName: r'PENALTY')
  static const WalletTransactionType PENALTY = _$PENALTY;
  @BuiltValueEnumConst(wireName: r'BONUS')
  static const WalletTransactionType BONUS = _$BONUS;
  @BuiltValueEnumConst(wireName: r'ADJUSTMENT')
  static const WalletTransactionType ADJUSTMENT = _$ADJUSTMENT;

  static Serializer<WalletTransactionType> get serializer => _$walletTransactionTypeSerializer;

  const WalletTransactionType._(String name): super(name);

  static BuiltSet<WalletTransactionType> get values => _$values;
  static WalletTransactionType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class WalletTransactionTypeMixin = Object with _$WalletTransactionTypeMixin;

