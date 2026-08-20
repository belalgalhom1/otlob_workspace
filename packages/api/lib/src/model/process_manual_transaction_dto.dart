//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'process_manual_transaction_dto.g.dart';

/// ProcessManualTransactionDto
///
/// Properties:
/// * [amount] - Positive or negative amount
/// * [type] - Type of transaction
/// * [description] 
/// * [referenceId] 
@BuiltValue()
abstract class ProcessManualTransactionDto implements Built<ProcessManualTransactionDto, ProcessManualTransactionDtoBuilder> {
  /// Positive or negative amount
  @BuiltValueField(wireName: r'amount')
  num get amount;

  /// Type of transaction
  @BuiltValueField(wireName: r'type')
  String get type;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'referenceId')
  String? get referenceId;

  ProcessManualTransactionDto._();

  factory ProcessManualTransactionDto([void updates(ProcessManualTransactionDtoBuilder b)]) = _$ProcessManualTransactionDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProcessManualTransactionDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProcessManualTransactionDto> get serializer => _$ProcessManualTransactionDtoSerializer();
}

class _$ProcessManualTransactionDtoSerializer implements PrimitiveSerializer<ProcessManualTransactionDto> {
  @override
  final Iterable<Type> types = const [ProcessManualTransactionDto, _$ProcessManualTransactionDto];

  @override
  final String wireName = r'ProcessManualTransactionDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProcessManualTransactionDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'amount';
    yield serializers.serialize(
      object.amount,
      specifiedType: const FullType(num),
    );
    yield r'type';
    yield serializers.serialize(
      object.type,
      specifiedType: const FullType(String),
    );
    if (object.description != null) {
      yield r'description';
      yield serializers.serialize(
        object.description,
        specifiedType: const FullType(String),
      );
    }
    if (object.referenceId != null) {
      yield r'referenceId';
      yield serializers.serialize(
        object.referenceId,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProcessManualTransactionDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProcessManualTransactionDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'amount':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.amount = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.type = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.description = valueDes;
          break;
        case r'referenceId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.referenceId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProcessManualTransactionDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProcessManualTransactionDtoBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

