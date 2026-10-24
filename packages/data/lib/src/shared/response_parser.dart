import 'package:api/api.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';

class ResponseParser {
  static dynamic parse(dynamic response) {
    if (response == null || response.data == null) return null;
    final rawData = response.data;

    if (rawData is Map) {
      if ((rawData.containsKey('success') || rawData.containsKey('statusCode')) &&
          rawData.containsKey('data')) {
        return _deepToMap(rawData['data']);
      }
      return _deepToMap(rawData);
    }

    try {
      if (rawData.data != null) {
        return _deepToMap(rawData.data);
      }
    } catch (_) {}

    return _deepToMap(response.data);
  }

  static dynamic parseList(dynamic response) {
    if (response == null || response.data == null) return [];
    final rawData = response.data;

    if (rawData is Map) {
      if ((rawData.containsKey('success') || rawData.containsKey('statusCode')) &&
          rawData.containsKey('data')) {
        final parsed = _deepToMap(rawData['data']);
        if (parsed is List) return parsed;
        if (parsed is Map && parsed.containsKey('data') && parsed['data'] is List) {
          return parsed['data'];
        }
        return parsed ?? [];
      }
      if (rawData.containsKey('data') && rawData['data'] is List) {
        return _deepToMap(rawData['data']) ?? [];
      }
      return _deepToMap(rawData) ?? [];
    }

    try {
      if (rawData.data != null) {
        final parsed = _deepToMap(rawData.data);
        if (parsed is List) return parsed;
        if (parsed is Map && parsed.containsKey('data') && parsed['data'] is List) {
          return parsed['data'];
        }
        return parsed ?? [];
      }
    } catch (_) {}

    final fallback = _deepToMap(response.data);
    if (fallback is List) return fallback;
    return fallback ?? [];
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
