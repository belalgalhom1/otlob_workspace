//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'wallet_type.g.dart';

class WalletType extends EnumClass {

  @BuiltValueEnumConst(wireName: r'VODAFONE')
  static const WalletType VODAFONE = _$VODAFONE;
  @BuiltValueEnumConst(wireName: r'ORANGE')
  static const WalletType ORANGE = _$ORANGE;
  @BuiltValueEnumConst(wireName: r'WE')
  static const WalletType WE = _$WE;
  @BuiltValueEnumConst(wireName: r'ETISALAT')
  static const WalletType ETISALAT = _$ETISALAT;
  @BuiltValueEnumConst(wireName: r'INSTAPAY')
  static const WalletType INSTAPAY = _$INSTAPAY;

  static Serializer<WalletType> get serializer => _$walletTypeSerializer;

  const WalletType._(String name): super(name);

  static BuiltSet<WalletType> get values => _$values;
  static WalletType valueOf(String name) => _$valueOf(name);
}

/// Optionally, enum_class can generate a mixin to go with your enum for use
/// with Angular. It exposes your enum constants as getters. So, if you mix it
/// in to your Dart component class, the values become available to the
/// corresponding Angular template.
///
/// Trigger mixin generation by writing a line like this one next to your enum.
abstract class WalletTypeMixin = Object with _$WalletTypeMixin;

