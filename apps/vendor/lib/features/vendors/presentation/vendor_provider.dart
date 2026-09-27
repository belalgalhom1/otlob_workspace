import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:vendor/core/providers.dart';
import 'package:api/api.dart';
import 'package:dio/dio.dart';
import 'package:built_value/json_object.dart';

part 'vendor_provider.g.dart';

class VendorStateData {
  final List<dynamic> vendors;
  final int total;
  VendorStateData({this.vendors = const [], this.total = 0});
}

@Riverpod(keepAlive: true)
class VendorNotifier extends _$VendorNotifier {
  @override
  AsyncValue<VendorStateData> build() {
    return const AsyncValue.loading();
  }

  Future<void> fetchVendors({String? vendorId, String? search}) async {
    final isInitialLoad = !state.hasValue;
    if (isInitialLoad) {
      state = const AsyncValue.loading();
    }
    try {
      final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
      
      if (role == 'VENDOR_MEMBER') {
         final vId = vendorId ?? ref.read(activeVendorProvider);
         if (vId != null) {
           final vendor = await ref.read(vendorProfileRepositoryProvider).vendorProfileFind(vId);
           if (vendor != null) {
             state = AsyncValue.data(VendorStateData(vendors: [vendor], total: 1));
           } else {
             state = AsyncValue.data(VendorStateData(vendors: [], total: 0));
           }
         } else {
           state = AsyncValue.data(VendorStateData(vendors: [], total: 0));
         }
         return;
      }

      final repository = ref.read(adminVendorsRepositoryProvider);
      if (vendorId != null) {
         final vendor = await repository.vendorsFindBySlug(slug: vendorId); // Or findOne...
         if (vendor != null) {
           state = AsyncValue.data(VendorStateData(vendors: [vendor], total: 1));
         } else {
           state = AsyncValue.data(VendorStateData(vendors: [], total: 0));
         }
      } else {
        final result = await repository.getVendors(search: search);
        state = AsyncValue.data(
          VendorStateData(vendors: result['vendors'] ?? result['items'] ?? [], total: result['total'] ?? 0),
        );
      }
    } catch (e, st) {
      if (isInitialLoad) {
        state = AsyncValue.error('Failed to fetch vendors', st);
      }
    }
  }

  Future<void> createVendor(Map<String, dynamic> data) async {
    final response = await ref.read(adminVendorsRepositoryProvider).vendorsCreate(
      createVendorDto: CreateVendorDto((b) {
        b.storeName = data['storeName'] ?? data['name'] ?? '';
        b.storeNameAr = data['storeNameAr'] ?? data['nameAr'] ?? '';
        b.verticalId = data['verticalId'] ?? '';
        if (data['phone'] != null) b.phone = data['phone'];
        if (data['description'] != null) b.description = data['description'];
        if (data['descriptionAr'] != null) b.descriptionAr = data['descriptionAr'];
        if (data['taxId'] != null) b.taxId = data['taxId'];
        if (data['commissionRate'] != null) b.commissionRate = data['commissionRate'];
        if (data['isContracted'] != null) b.isContracted = data['isContracted'];
        if (data['workingHours'] != null) b.workingHours = JsonObject(data['workingHours']);
      })
    );

    if (data['coverImage'] != null) {
      try {
        final file = data['coverImage'];
        final bytes = await file.readAsBytes();
        final name = file.name;
        final vendorId = response['id'];
        if (vendorId != null) {
          await ref.read(adminVendorsRepositoryProvider).uploadVendorCover(
            vendorId: vendorId,
            fileBytes: bytes,
            fileName: name,
          );
        }
      } catch (e) {
        debugPrint('Failed to upload cover: $e');
      }
    }
    await fetchVendors();
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    final vendorId = data['vendorId'] as String? ?? '';
    if (vendorId.isEmpty) {
      throw Exception('vendorId missing');
    }

    final dto = CreateProductDto((b) {
      b.name = data['name'] ?? '';
      b.nameAr = data['nameAr'] ?? '';
      b.basePrice = num.tryParse(data['basePrice']?.toString() ?? '0') ?? 0;
      if (data['description'] != null) b.description = data['description'];
      if (data['descriptionAr'] != null) b.descriptionAr = data['descriptionAr'];
      if (data['stock'] != null) b.stock = num.tryParse(data['stock'].toString());
      if (data['sku'] != null && data['sku'].toString().trim().isNotEmpty) {
        b.sku = data['sku'].toString().trim();
      }
      b.isActive = data['isActive'] ?? true;
      if (data['sellByStrip'] != null) b.sellByStrip = data['sellByStrip'];
      if (data['tracksStock'] != null) b.tracksStock = data['tracksStock'] == true;
      if (data['stripsPerPackage'] != null) {
        b.stripsPerPackage = num.tryParse(data['stripsPerPackage'].toString());
      }
      b.categoryId = data['categoryId'] ?? '';
      final variants = (data['variants'] as List? ?? []);
      if (variants.isNotEmpty) {
        b.hasVariants = true;
        b.variants.replace(_buildVariantDtos(variants));
      } else {
        b.hasVariants = false;
        final optionGroups = (data['optionGroups'] as List? ?? []);
        if (optionGroups.isNotEmpty) {
          b.optionGroups.replace(_buildOptionGroupDtos(optionGroups));
        }
      }
    });

    dynamic createdProduct;
    if (role == 'VENDOR_MEMBER') {
      createdProduct = await ref
          .read(vendorCatalogRepositoryProvider)
          .createProduct(vendorId, dto);
    } else {
      createdProduct = await ref
          .read(adminVendorsRepositoryProvider)
          .createProduct(vendorId, dto, isAdmin: true);
    }

    final productId = createdProduct?['id'];
    final imageFile = data['imageFile'];
    if (productId != null && imageFile != null) {
      try {
        final multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.name,
        );
        if (role == 'VENDOR_MEMBER') {
          await ref
              .read(vendorCatalogRepositoryProvider)
              .uploadProductImage(vendorId, productId, multipartFile);
        } else {
          await ref
              .read(adminVendorsRepositoryProvider)
              .uploadProductImage(vendorId, productId, multipartFile);
        }
      } catch (e) {
        debugPrint('Failed to upload product image: $e');
      }
    }

    if (role == 'VENDOR_MEMBER') {
      await fetchVendors(vendorId: vendorId);
    } else {
      await fetchVendors();
    }
  }

  Future<void> updateVendor(String id, Map<String, dynamic> data) async {
    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    final updateDto = UpdateVendorDto((b) {
      if (data['storeName'] != null) b.storeName = data['storeName'];
      if (data['storeNameAr'] != null) b.storeNameAr = data['storeNameAr'];
      if (data['description'] != null) b.description = data['description'];
      if (data['descriptionAr'] != null) b.descriptionAr = data['descriptionAr'];
      if (data['taxId'] != null) b.taxId = data['taxId'];
      if (data['commissionRate'] != null) b.commissionRate = data['commissionRate'];
      if (data['phone'] != null) b.phone = data['phone'];
      if (data['isContracted'] != null) b.isContracted = data['isContracted'];
      if (data['isScheduleActive'] != null) b.isScheduleActive = data['isScheduleActive'];
      if (data['verticalId'] != null) b.verticalId = data['verticalId'];
      if (data['workingHours'] != null) b.workingHours = JsonObject(data['workingHours']);
    });

    if (role == 'VENDOR_MEMBER') {
      await ref.read(vendorProfileRepositoryProvider).vendorProfileUpdate(id, updateDto);
      if (data['coverImage'] != null) {
        try {
          final file = data['coverImage'];
          final bytes = await file.readAsBytes();
          final name = file.name;
          final multipartFile = MultipartFile.fromBytes(bytes, filename: name);
          await ref.read(vendorProfileRepositoryProvider).uploadCover(id, multipartFile);
        } catch (e) {
          debugPrint('Failed to upload cover: $e');
        }
      }
      await fetchVendors(vendorId: id);
    } else {
      await ref.read(adminVendorsRepositoryProvider).vendorsUpdate(
        vendorId: id,
        updateVendorDto: updateDto
      );
      if (data['coverImage'] != null) {
        try {
          final file = data['coverImage'];
          final bytes = await file.readAsBytes();
          final name = file.name;
          await ref.read(adminVendorsRepositoryProvider).uploadVendorCover(
            vendorId: id,
            fileBytes: bytes,
            fileName: name,
          );
        } catch (e) {
          debugPrint('Failed to upload cover: $e');
        }
      }
      await fetchVendors();
    }
  }

  Future<void> updateVendorStatus(String id, String status) async {
    final statusEnum = UpdateVendorStatusDtoStatusEnum.valueOf(status);
    await ref.read(adminVendorsRepositoryProvider).updateVendorStatus(
      vendorId: id,
      updateVendorStatusDto: UpdateVendorStatusDto((b) => b..status = statusEnum),
    );
    await fetchVendors();
  }

  Future<void> deleteVendor(String id) async {
    await ref.read(adminVendorsRepositoryProvider).vendorsRemove(vendorId: id);
    await fetchVendors();
  }
}

List<CreateProductVariantDto> _buildVariantDtos(List<dynamic> variants) {
  return variants.map((v) {
    return CreateProductVariantDto((b) {
      b.name = (v['name'] ?? '').toString();
      if (v['nameAr']?.toString().isNotEmpty == true) {
        b.nameAr = v['nameAr'].toString();
      }
      b.basePrice = num.tryParse(v['basePrice']?.toString() ?? '') ?? 0;
      if (v['sku']?.toString().isNotEmpty == true) {
        b.sku = v['sku'].toString();
      }
      if (v['stock'] != null) b.stock = num.tryParse(v['stock'].toString());
      if (v['tracksStock'] != null) b.tracksStock = v['tracksStock'] == true;
      final variantGroups = (v['optionGroups'] as List? ?? []);
      if (variantGroups.isNotEmpty) {
        b.optionGroups.replace(_buildOptionGroupDtos(variantGroups));
      }
    });
  }).toList();
}

List<CreateOptionGroupDto> _buildOptionGroupDtos(List<dynamic> groups) {
  return groups.map((g) {
    return CreateOptionGroupDto((b) {
      b.name = (g['name'] ?? '').toString();
      if (g['nameAr']?.toString().isNotEmpty == true) {
        b.nameAr = g['nameAr'].toString();
      }
      if (g['minSelect'] != null) {
        b.minSelect = num.tryParse(g['minSelect'].toString());
      }
      if (g['maxSelect'] != null) {
        b.maxSelect = num.tryParse(g['maxSelect'].toString());
      }
      if (g['isRequired'] != null) b.isRequired = g['isRequired'] == true;
      final opts = (g['options'] as List? ?? []);
      if (opts.isNotEmpty) {
        b.options.replace(opts.map((o) {
          return CreateProductOptionDto((b) {
            b.name = (o['name'] ?? '').toString();
            if (o['nameAr']?.toString().isNotEmpty == true) {
              b.nameAr = o['nameAr'].toString();
            }
            if (o['priceAdded'] != null) {
              b.priceAdded = num.tryParse(o['priceAdded'].toString());
            }
          });
        }).toList());
      }
    });
  }).toList();
}

