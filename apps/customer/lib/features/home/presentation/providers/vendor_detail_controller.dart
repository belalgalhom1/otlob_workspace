import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';

part 'vendor_detail_controller.g.dart';

class BranchSelection {
  final String id;
  final String? name;
  final String? nameAr;
  final String? address;

  const BranchSelection({
    required this.id,
    this.name,
    this.nameAr,
    this.address,
  });

  String localizedName(bool isAr) {
    if (isAr) {
      return (nameAr != null && nameAr!.isNotEmpty) ? nameAr! : (name ?? '');
    }
    return (name != null && name!.isNotEmpty) ? name! : (nameAr ?? '');
  }
}

class SelectedBranchNotifier extends Notifier<Map<String, BranchSelection>> {
  @override
  Map<String, BranchSelection> build() => {};

  void selectBranch(String vendorId, BranchSelection branch) {
    state = {...state, vendorId: branch};
  }

  void selectBranchById(
    String vendorId,
    String branchId, {
    String? name,
    String? nameAr,
    String? address,
  }) {
    state = {
      ...state,
      vendorId: BranchSelection(
        id: branchId,
        name: name,
        nameAr: nameAr,
        address: address,
      ),
    };
  }

  String? getSelectedBranchId(String vendorId) => state[vendorId]?.id;
}

final selectedBranchProvider =
    NotifierProvider<SelectedBranchNotifier, Map<String, BranchSelection>>(
  SelectedBranchNotifier.new,
);

@riverpod
class VendorDetailController extends _$VendorDetailController {
  @override
  FutureOr<Map<String, dynamic>> build(String vendorId) async {
    return fetchVendorDetails(vendorId);
  }

  Future<Map<String, dynamic>> fetchVendorDetails(String vendorId) async {
    final vendorsRepo = ref.read(customerVendorsRepositoryProvider);
    final branchId = ref.watch(selectedBranchProvider)[vendorId]?.id;
    final responseData =
        await vendorsRepo.getVendor(vendorId, branchId: branchId);
    final data = responseData as Map<String, dynamic>;

    // Map vendor fields
    data['name'] = data['storeName'];
    data['nameAr'] = data['storeNameAr'];
    data['image'] = data['coverImage'] ?? data['logo'];
    data['logo'] = data['logo'];
    data['coverImage'] = data['coverImage'];
    data['vendor'] = data['description'];
    data['vendorAr'] = data['descriptionAr'];
    data['type'] = data['vertical']?['slug'] ?? 'other';

    // Flatten categories or use direct products/menu list
    final List<Map<String, dynamic>> menu = [];
    if (data['menu'] != null && (data['menu'] as List).isNotEmpty) {
      for (final item in data['menu']) {
        menu.add(Map<String, dynamic>.from(item as Map));
      }
    } else if (data['products'] != null &&
        (data['products'] as List).isNotEmpty) {
      final products = data['products'] as List<dynamic>;
      for (final prod in products) {
        final Map<String, dynamic> p = Map<String, dynamic>.from(prod as Map);
        p['category'] = p['categoryId'];
        p['image'] = p['imageUrl'];
        p['price'] = p['basePrice'];
        menu.add(p);
      }
    } else {
      final categories = data['categories'] as List<dynamic>? ?? [];
      for (final cat in categories) {
        final products = cat['products'] as List<dynamic>? ?? [];
        for (final prod in products) {
          final Map<String, dynamic> p = Map<String, dynamic>.from(prod as Map);
          p['category'] = cat['id'];
          p['image'] = p['imageUrl'];
          p['price'] = p['basePrice'];
          menu.add(p);
        }
      }
    }
    data['menu'] = menu;

    return data;
  }
}
