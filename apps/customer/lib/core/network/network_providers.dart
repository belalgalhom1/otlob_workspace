import 'package:core/core.dart' as core;
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_providers.g.dart';

/// Unified Customer Dio client delegating directly to [core.dioProvider] so all
/// HTTP traffic shares one [AuthInterceptor] and one refresh-token mutex.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  return ref.watch(core.dioProvider);
}
