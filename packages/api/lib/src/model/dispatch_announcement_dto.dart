//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'dispatch_announcement_dto.g.dart';

/// DispatchAnnouncementDto
///
/// Properties:
/// * [audience] - Target audience for the broadcast
/// * [title] 
/// * [titleAr] 
/// * [body] 
/// * [bodyAr] 
/// * [data] - Optional deep link or analytics payload
/// * [type] - The type of notification to send. Defaults to ANNOUNCEMENT.
@BuiltValue()
abstract class DispatchAnnouncementDto implements Built<DispatchAnnouncementDto, DispatchAnnouncementDtoBuilder> {
  /// Target audience for the broadcast
  @BuiltValueField(wireName: r'audience')
  DispatchAnnouncementDtoAudienceEnum get audience;
  // enum audienceEnum {  CUSTOMERS,  DRIVERS,  VENDORS,  ALL,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'titleAr')
  String? get titleAr;

  @BuiltValueField(wireName: r'body')
  String get body;

  @BuiltValueField(wireName: r'bodyAr')
  String? get bodyAr;

  /// Optional deep link or analytics payload
  @BuiltValueField(wireName: r'data')
  JsonObject? get data;

  /// The type of notification to send. Defaults to ANNOUNCEMENT.
  @BuiltValueField(wireName: r'type')
  DispatchAnnouncementDtoTypeEnum? get type;
  // enum typeEnum {  ANNOUNCEMENT,  SYSTEM,  };

  DispatchAnnouncementDto._();

  factory DispatchAnnouncementDto([void updates(DispatchAnnouncementDtoBuilder b)]) = _$DispatchAnnouncementDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DispatchAnnouncementDtoBuilder b) => b
      ..type = DispatchAnnouncementDtoTypeEnum.valueOf('ANNOUNCEMENT');

  @BuiltValueSerializer(custom: true)
  static Serializer<DispatchAnnouncementDto> get serializer => _$DispatchAnnouncementDtoSerializer();
}

class _$DispatchAnnouncementDtoSerializer implements PrimitiveSerializer<DispatchAnnouncementDto> {
  @override
  final Iterable<Type> types = const [DispatchAnnouncementDto, _$DispatchAnnouncementDto];

  @override
  final String wireName = r'DispatchAnnouncementDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DispatchAnnouncementDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'audience';
    yield serializers.serialize(
      object.audience,
      specifiedType: const FullType(DispatchAnnouncementDtoAudienceEnum),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    if (object.titleAr != null) {
      yield r'titleAr';
      yield serializers.serialize(
        object.titleAr,
        specifiedType: const FullType(String),
      );
    }
    yield r'body';
    yield serializers.serialize(
      object.body,
      specifiedType: const FullType(String),
    );
    if (object.bodyAr != null) {
      yield r'bodyAr';
      yield serializers.serialize(
        object.bodyAr,
        specifiedType: const FullType(String),
      );
    }
    if (object.data != null) {
      yield r'data';
      yield serializers.serialize(
        object.data,
        specifiedType: const FullType(JsonObject),
      );
    }
    if (object.type != null) {
      yield r'type';
      yield serializers.serialize(
        object.type,
        specifiedType: const FullType(DispatchAnnouncementDtoTypeEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DispatchAnnouncementDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DispatchAnnouncementDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'audience':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DispatchAnnouncementDtoAudienceEnum),
          ) as DispatchAnnouncementDtoAudienceEnum;
          result.audience = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'titleAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.titleAr = valueDes;
          break;
        case r'body':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.body = valueDes;
          break;
        case r'bodyAr':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.bodyAr = valueDes;
          break;
        case r'data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JsonObject),
          ) as JsonObject;
          result.data = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DispatchAnnouncementDtoTypeEnum),
          ) as DispatchAnnouncementDtoTypeEnum;
          result.type = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DispatchAnnouncementDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DispatchAnnouncementDtoBuilder();
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

class DispatchAnnouncementDtoAudienceEnum extends EnumClass {

  /// Target audience for the broadcast
  @BuiltValueEnumConst(wireName: r'CUSTOMERS')
  static const DispatchAnnouncementDtoAudienceEnum CUSTOMERS = _$dispatchAnnouncementDtoAudienceEnum_CUSTOMERS;
  /// Target audience for the broadcast
  @BuiltValueEnumConst(wireName: r'DRIVERS')
  static const DispatchAnnouncementDtoAudienceEnum DRIVERS = _$dispatchAnnouncementDtoAudienceEnum_DRIVERS;
  /// Target audience for the broadcast
  @BuiltValueEnumConst(wireName: r'VENDORS')
  static const DispatchAnnouncementDtoAudienceEnum VENDORS = _$dispatchAnnouncementDtoAudienceEnum_VENDORS;
  /// Target audience for the broadcast
  @BuiltValueEnumConst(wireName: r'ALL')
  static const DispatchAnnouncementDtoAudienceEnum ALL = _$dispatchAnnouncementDtoAudienceEnum_ALL;

  static Serializer<DispatchAnnouncementDtoAudienceEnum> get serializer => _$dispatchAnnouncementDtoAudienceEnumSerializer;

  const DispatchAnnouncementDtoAudienceEnum._(String name): super(name);

  static BuiltSet<DispatchAnnouncementDtoAudienceEnum> get values => _$dispatchAnnouncementDtoAudienceEnumValues;
  static DispatchAnnouncementDtoAudienceEnum valueOf(String name) => _$dispatchAnnouncementDtoAudienceEnumValueOf(name);
}

class DispatchAnnouncementDtoTypeEnum extends EnumClass {

  /// The type of notification to send. Defaults to ANNOUNCEMENT.
  @BuiltValueEnumConst(wireName: r'ANNOUNCEMENT')
  static const DispatchAnnouncementDtoTypeEnum ANNOUNCEMENT = _$dispatchAnnouncementDtoTypeEnum_ANNOUNCEMENT;
  /// The type of notification to send. Defaults to ANNOUNCEMENT.
  @BuiltValueEnumConst(wireName: r'SYSTEM')
  static const DispatchAnnouncementDtoTypeEnum SYSTEM = _$dispatchAnnouncementDtoTypeEnum_SYSTEM;

  static Serializer<DispatchAnnouncementDtoTypeEnum> get serializer => _$dispatchAnnouncementDtoTypeEnumSerializer;

  const DispatchAnnouncementDtoTypeEnum._(String name): super(name);

  static BuiltSet<DispatchAnnouncementDtoTypeEnum> get values => _$dispatchAnnouncementDtoTypeEnumValues;
  static DispatchAnnouncementDtoTypeEnum valueOf(String name) => _$dispatchAnnouncementDtoTypeEnumValueOf(name);
}

