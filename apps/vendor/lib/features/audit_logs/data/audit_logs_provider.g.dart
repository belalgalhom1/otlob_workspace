// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_logs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuditLogs)
final auditLogsProvider = AuditLogsProvider._();

final class AuditLogsProvider
    extends $AsyncNotifierProvider<AuditLogs, AuditLogsState> {
  AuditLogsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditLogsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditLogsHash();

  @$internal
  @override
  AuditLogs create() => AuditLogs();
}

String _$auditLogsHash() => r'e5a23ca4cd715fc32cbdeff0fa5a465d2f8db2b6';

abstract class _$AuditLogs extends $AsyncNotifier<AuditLogsState> {
  FutureOr<AuditLogsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuditLogsState>, AuditLogsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuditLogsState>, AuditLogsState>,
              AsyncValue<AuditLogsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
