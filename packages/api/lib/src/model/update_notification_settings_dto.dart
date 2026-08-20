//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_notification_settings_dto.g.dart';

/// UpdateNotificationSettingsDto
///
/// Properties:
/// * [pushEnabled] 
/// * [orderUpdates] 
/// * [chatMessages] 
/// * [promotions] 
/// * [system] 
@BuiltValue()
abstract class UpdateNotificationSettingsDto implements Built<UpdateNotificationSettingsDto, UpdateNotificationSettingsDtoBuilder> {
  @BuiltValueField(wireName: r'pushEnabled')
  bool? get pushEnabled;

  @BuiltValueField(wireName: r'orderUpdates')
  bool? get orderUpdates;

  @BuiltValueField(wireName: r'chatMessages')
  bool? get chatMessages;

  @BuiltValueField(wireName: r'promotions')
  bool? get promotions;

  @BuiltValueField(wireName: r'system')
  bool? get system;

  UpdateNotificationSettingsDto._();

  factory UpdateNotificationSettingsDto([void updates(UpdateNotificationSettingsDtoBuilder b)]) = _$UpdateNotificationSettingsDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateNotificationSettingsDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateNotificationSettingsDto> get serializer => _$UpdateNotificationSettingsDtoSerializer();
}

class _$UpdateNotificationSettingsDtoSerializer implements PrimitiveSerializer<UpdateNotificationSettingsDto> {
  @override
  final Iterable<Type> types = const [UpdateNotificationSettingsDto, _$UpdateNotificationSettingsDto];

  @override
  final String wireName = r'UpdateNotificationSettingsDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateNotificationSettingsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.pushEnabled != null) {
      yield r'pushEnabled';
      yield serializers.serialize(
        object.pushEnabled,
        specifiedType: const FullType(bool),
      );
    }
    if (object.orderUpdates != null) {
      yield r'orderUpdates';
      yield serializers.serialize(
        object.orderUpdates,
        specifiedType: const FullType(bool),
      );
    }
    if (object.chatMessages != null) {
      yield r'chatMessages';
      yield serializers.serialize(
        object.chatMessages,
        specifiedType: const FullType(bool),
      );
    }
    if (object.promotions != null) {
      yield r'promotions';
      yield serializers.serialize(
        object.promotions,
        specifiedType: const FullType(bool),
      );
    }
    if (object.system != null) {
      yield r'system';
      yield serializers.serialize(
        object.system,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateNotificationSettingsDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateNotificationSettingsDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'pushEnabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.pushEnabled = valueDes;
          break;
        case r'orderUpdates':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.orderUpdates = valueDes;
          break;
        case r'chatMessages':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.chatMessages = valueDes;
          break;
        case r'promotions':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.promotions = valueDes;
          break;
        case r'system':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.system = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateNotificationSettingsDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateNotificationSettingsDtoBuilder();
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

