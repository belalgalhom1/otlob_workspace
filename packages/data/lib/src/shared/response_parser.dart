import 'package:api/api.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';

class ResponseParser {
  static dynamic parse(dynamic response) {
    if (response == null || response.data == null) return null;
    try {
      dynamic rawData = response.data;
      if (rawData.success != null && rawData.data != null) {
        return _deepToMap(rawData.data);
      }
    } catch (_) {}
    return _deepToMap(response.data);
  }

  static dynamic parseList(dynamic response) {
    if (response == null || response.data == null) return [];
    try {
      dynamic rawData = response.data;
      if (rawData.success != null && rawData.data != null) {
        return _deepToMap(rawData.data) ?? [];
      }
    } catch (_) {}
    return _deepToMap(response.data) ?? [];
  }

  static dynamic _deepToMap(dynamic obj) {
    if (obj == null) return null;
    if (obj is String || obj is num || obj is bool) return obj;

    if (obj is BuiltList) {
      return obj.map((e) => _deepToMap(e)).toList();
    }
    
    if (obj is BuiltMap) {
      return Map<String, dynamic>.fromEntries(
        obj.toMap().entries.map((e) => MapEntry(e.key.toString(), _deepToMap(e.value))),
      );
    }
    
    if (obj is List) {
      return obj.map((e) => _deepToMap(e)).toList();
    }
    
    if (obj is Map) {
      return Map<String, dynamic>.fromEntries(
        obj.entries.map((e) => MapEntry(e.key.toString(), _deepToMap(e.value))),
      );
    }

    if (obj is JsonObject) {
      return _deepToMap(obj.value);
    }
    
    try {
      final serialized = standardSerializers.serialize(obj);
      if (serialized is Map || serialized is List) {
        return _deepToMap(serialized);
      }
      return serialized;
    } catch (e) {
      return obj; 
    }
  }
}