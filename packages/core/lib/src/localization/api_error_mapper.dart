import 'package:dio/dio.dart';

class ApiErrorMapper {
  /// Extracts the error message key from a DioException or generic Exception.
  static String fromError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('message')) {
          final message = data['message'];
          if (message is String) {
            return message.replaceAll('.', '_');
          } else if (message is List && message.isNotEmpty) {
            return message.first.toString().replaceAll('.', '_');
          }
        }
      }
      return 'common_error_server_error';
    }
    
    final errorString = error.toString().replaceFirst('Exception: ', '');
    return errorString.replaceAll('.', '_');
  }
}
