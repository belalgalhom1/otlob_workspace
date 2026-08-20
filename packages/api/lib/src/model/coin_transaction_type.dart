//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'coin_transaction_type.g.dart';

class CoinTransactionType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'EARNED')
  static const CoinTransactionType EARNED = _$EARNED;
  @BuiltValueEnumConst(wireName: r'SPENT')
  static const CoinTransactionType SPENT = _$SPENT;
  @BuiltValueEnumConst(wireName: r'REFUNDED')
  static const CoinTransactionType REFUNDED = _$REFUNDED;

  static Serializer<CoinTransactionType> get serializer => _$coinTransactionTypeSerializer;

  const CoinTransactionType._(String name): super(name);

  static BuiltSet<CoinTransactionType> get values => _$values;
  static CoinTransactionType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class CoinTransactionTypeMixin = Object with _$CoinTransactionTypeMixin;

