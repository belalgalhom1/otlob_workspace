import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/data.dart';

class ActiveVendorNotifier extends Notifier<String?> {
  @override
  String? build() {
    _init();
    return null;
  }

  Future<void> _init() async {
    final memberships = await ref.read(sharedAuthRepositoryProvider).getVendorMemberships();
    if (memberships.isNotEmpty) {
      final map = memberships.first as Map<String, dynamic>;
      state = map['vendorId'] as String?;
    }
  }

  Future<void> setActiveVendor(String vendorId) async {
    state = vendorId;
  }

  Future<void> clearActiveVendor() async {
    state = null;
  }
}

final activeVendorProvider = NotifierProvider<ActiveVendorNotifier, String?>(() {
  return ActiveVendorNotifier();
});

final vendorMembershipsProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(sharedAuthRepositoryProvider);
  return await repo.getVendorMemberships();
});
