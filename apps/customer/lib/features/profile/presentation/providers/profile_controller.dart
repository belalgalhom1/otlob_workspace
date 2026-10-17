import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:data/providers.dart';
import 'package:api/api.dart';
import 'package:core/core.dart' hide tokenServiceProvider;
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/services/token_service.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import 'package:flutter/foundation.dart';

part 'profile_controller.g.dart';

class ProfileState {
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final bool isArabic;
  final List<Map<String, dynamic>> addresses;

  const ProfileState({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.isArabic,
    this.addresses = const [],
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatar,
    bool? isArabic,
    List<Map<String, dynamic>>? addresses,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isArabic: isArabic ?? this.isArabic,
      addresses: addresses ?? this.addresses,
    );
  }
}
@Riverpod(keepAlive: true)
class Profile extends _$Profile {
  @override
  ProfileState build() {
    final settings = ref.read(appSettingsProvider);
    
    ref.listen<AuthStatus>(authControllerProvider, (prev, next) {
      if (next == AuthStatus.authenticated && prev != AuthStatus.authenticated) {
        _init();
      } else if (next == AuthStatus.unauthenticated) {
        state = state.copyWith(
          name: '',
          email: '',
          phone: '',
          avatar: '',
          addresses: [],
        );
      }
    });
    
    // Initial placeholder state
    final initialState = ProfileState(
      name: '',
      email: '',
      phone: '',
      avatar: '',
      isArabic: settings.languageCode == 'ar',
      addresses: [],
    );
    
    // Asynchronously load real data if already authenticated
    if (ref.read(authControllerProvider) == AuthStatus.authenticated) {
      Future.microtask(() => _init());
    }
    
    return initialState;
  }

  Future<void> _init() async {
    final userRepo = ref.read(sharedUserRepositoryProvider);
    final addressRepo = ref.read(customerAddressesRepositoryProvider);
    final tokenService = ref.read(tokenServiceProvider);

    // 1. Try to load from local storage first for instant UI
    final localName = await tokenService.getUserName() ?? '';
    final localEmail = await tokenService.getUserEmail() ?? '';
    final localPhone = await tokenService.getUserPhone() ?? '';
    final localAvatar = await tokenService.getUserAvatar() ?? '';
    
    state = state.copyWith(
      name: localName,
      email: localEmail,
      phone: localPhone,
      avatar: localAvatar,
    );

    // 2. Fetch latest from backend to ensure accuracy
    try {
      final data = await userRepo.getUser();
      final name = data['name'] ?? '';
      final email = data['email'] ?? '';
      final phone = data['phone'] ?? '';
      final avatar = data['avatar'] ?? '';
      
      // Sync to local storage
      await tokenService.saveUserName(name);
      await tokenService.saveUserEmail(email);
      await tokenService.saveUserPhone(phone);
      await tokenService.saveUserAvatar(avatar);

      state = state.copyWith(
        name: name, 
        email: email, 
        phone: phone,
        avatar: avatar,
      );
    } catch (e) {
      debugPrint('Failed to fetch profile: $e');
    }

    // 3. Fetch addresses
    try {
      final addresses = await addressRepo.getAddresses();
      if (addresses is List) {
        state = state.copyWith(addresses: List<Map<String, dynamic>>.from(addresses));
      }
    } catch (e) {
      debugPrint('Failed to fetch addresses: $e');
    }
  }

  Future<void> updateProfileData({required String name, required String email, required String phone}) async {
    final userRepo = ref.read(sharedUserRepositoryProvider);
    final tokenService = ref.read(tokenServiceProvider);

    try {
      final dto = UpdateUserDtoBuilder()
        ..name = name
        ..email = email
        ..phone = phone;
        
      await userRepo.updateUser(dto.build());
      
      await tokenService.saveUserName(name);
      await tokenService.saveUserEmail(email);
      await tokenService.saveUserPhone(phone);
      state = state.copyWith(name: name, email: email, phone: phone);
    } catch (e) {
      throw ApiErrorMapper.fromError(e);
    }
  }

  void toggleLanguage() {
    state = state.copyWith(isArabic: !state.isArabic);
  }

  Future<void> addAddress(Map<String, dynamic> addressData) async {
    try {
      final addressRepo = ref.read(customerAddressesRepositoryProvider);
      
      final addressStr = addressData['address'] as String? ?? 'Unknown';
      final labelStr = addressData['label'] as String?;

      final detailsStr = [
        if (addressData['buildingName'] != null) 'Building: ${addressData['buildingName']}',
        if (addressData['apartmentNumber'] != null) 'Apt: ${addressData['apartmentNumber']}',
        if (addressData['floor'] != null) 'Floor: ${addressData['floor']}',
        if (addressData['additionalDirections'] != null) addressData['additionalDirections']
      ].join(', ');

      final builder = CreateAddressDtoBuilder()
        ..address = addressStr
        ..isDefault = addressData['isDefault'] ?? false;
        
      if (labelStr != null && labelStr.isNotEmpty) {
        builder.label = labelStr;
      }
        
      if (detailsStr.isNotEmpty) {
        builder.details = detailsStr;
      }
      
      if (addressData['location'] != null && addressData['location'] is List && addressData['location'].length >= 2) {
        builder.location.replace([
          (addressData['location'][0] as num).toDouble(),
          (addressData['location'][1] as num).toDouble(),
        ]);
      }
      
      final address = await addressRepo.createAddress(builder.build());

      state = state.copyWith(addresses: [...state.addresses, Map<String, dynamic>.from(address)]);
      // First address saved — release the post-login address gate.
      ref.read(needsAddressProvider.notifier).set(false);
    } catch (e) {
      debugPrint('Add Address Error: $e');
      throw ApiErrorMapper.fromError(e);
    }
  }

  Future<void> editAddress(String id, Map<String, dynamic> addressData) async {
    try {
      final addressRepo = ref.read(customerAddressesRepositoryProvider);
      
      final addressStr = addressData['address'] as String? ?? '';
      final labelStr = addressData['label'] as String?;

      final detailsStr = [
        if (addressData['buildingName'] != null) 'Building: ${addressData['buildingName']}',
        if (addressData['apartmentNumber'] != null) 'Apt: ${addressData['apartmentNumber']}',
        if (addressData['floor'] != null) 'Floor: ${addressData['floor']}',
        if (addressData['additionalDirections'] != null) addressData['additionalDirections']
      ].join(', ');

      final builder = UpdateAddressDtoBuilder();
      
      if (addressStr.isNotEmpty) builder.address = addressStr;
      if (labelStr != null && labelStr.isNotEmpty) builder.label = labelStr;
      if (addressData['isDefault'] != null) builder.isDefault = addressData['isDefault'];
        
      if (detailsStr.isNotEmpty) builder.details = detailsStr;
      
      if (addressData['location'] != null && addressData['location'] is List && addressData['location'].length >= 2) {
        builder.location.replace([
          (addressData['location'][0] as num).toDouble(),
          (addressData['location'][1] as num).toDouble(),
        ]);
      }
      
      final updatedAddress = await addressRepo.updateAddress(id, builder.build());
      
      state = state.copyWith(
        addresses: state.addresses.map((a) => a['id'] == id ? Map<String, dynamic>.from(updatedAddress) : a).toList(),
      );
    } catch (e) {
      debugPrint('Edit Address Error: $e');
      rethrow;
    }
  }

  Future<void> removeAddress(String id) async {
    try {
      final addressRepo = ref.read(customerAddressesRepositoryProvider);
      await addressRepo.deleteAddress(id);

      state = state.copyWith(
        addresses: state.addresses.where((a) => a['id'] != id).toList(),
      );
    } catch (e) {
      throw ApiErrorMapper.fromError(e);
    }
  }

  Future<void> pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final userRepo = ref.read(sharedUserRepositoryProvider);
      final tokenService = ref.read(tokenServiceProvider);
      
      try {
        final multipartFile = await MultipartFile.fromFile(image.path);
        final data = await userRepo.uploadAvatar(multipartFile);
        
        final avatarUrl = data['avatar'];
        if (avatarUrl != null) {
          await tokenService.saveUserAvatar(avatarUrl);
          state = state.copyWith(avatar: avatarUrl);
        }
      } catch (e) {
        throw ApiErrorMapper.fromError(e);
      }
    }
  }
}

