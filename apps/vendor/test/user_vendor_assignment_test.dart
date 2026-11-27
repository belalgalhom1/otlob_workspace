import 'package:api/api.dart';
import 'package:data/data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor/features/users/presentation/user_provider.dart';

class _FakeAdminUsersRepository extends AdminUsersRepository {
  _FakeAdminUsersRepository() : super(UsersApi(Dio(), standardSerializers));

  RegisterDto? capturedRegisterDto;
  String? capturedUpdatedUserId;
  AdminUpdateUserDto? capturedUpdateDto;
  Map<String, dynamic> addUserResponse = {
    'accessToken': 'acc-token',
    'refreshToken': 'ref-token',
    'user': {
      'id': 'user-123',
      'name': 'Vendor Staff',
      'email': 'staff@vendor.com',
      'role': 'VENDOR_MEMBER',
    },
  };

  @override
  Future<dynamic> addUser(RegisterDto registerDto) async {
    capturedRegisterDto = registerDto;
    return addUserResponse;
  }

  @override
  Future<dynamic> updateUser(
    String id,
    AdminUpdateUserDto adminUpdateUserDto,
  ) async {
    capturedUpdatedUserId = id;
    capturedUpdateDto = adminUpdateUserDto;
    return {'id': id};
  }

  @override
  Future<dynamic> getUsers({
    String? role,
    bool? isBanned,
    bool? includeDeleted,
    String? search,
    num? page = 1,
    num? limit = 20,
  }) async {
    return {
      'users': [
        {
          'id': 'user-123',
          'name': 'Vendor Staff',
          'role': 'VENDOR_MEMBER',
          'vendorMemberships': [
            {
              'vendorId': capturedRegisterDto?.vendorId,
              'role': capturedRegisterDto?.vendorRole?.name,
            },
          ],
        },
      ],
      'total': 1,
    };
  }
}

class _FakeVendorMembersRepository extends VendorMembersRepository {
  _FakeVendorMembersRepository()
      : super(VendorsMembersTeamApi(Dio(), standardSerializers));

  bool adminAddMemberCalled = false;

  @override
  Future<dynamic> adminAddMember(
    String vendorId,
    AddVendorMemberDto addVendorMemberDto,
  ) async {
    adminAddMemberCalled = true;
    return {'id': 'vm-1'};
  }
}

void main() {
  test(
    'UserNotifier.addUser sends vendorId and vendorRole in RegisterDto on first create and resolves nested user.id for title/permissions',
    () async {
      final fakeUsersRepo = _FakeAdminUsersRepository();
      final fakeMembersRepo = _FakeVendorMembersRepository();

      final container = ProviderContainer(
        overrides: [
          adminUsersRepositoryProvider.overrideWithValue(fakeUsersRepo),
          vendorMembersRepositoryProvider.overrideWithValue(fakeMembersRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).addUser(
            name: 'Vendor Staff',
            email: 'staff@vendor.com',
            password: 'Password123!',
            role: 'VENDOR_MEMBER',
            phone: '+201000000001',
            vendorId: 'vendor-uuid-1',
            vendorRole: 'MANAGER',
            title: 'Store Manager',
            titleAr: 'مدير المتجر',
          );

      expect(fakeUsersRepo.capturedRegisterDto, isNotNull);
      expect(
        fakeUsersRepo.capturedRegisterDto!.role,
        RegisterDtoRoleEnum.VENDOR_MEMBER,
      );
      expect(fakeUsersRepo.capturedRegisterDto!.vendorId, 'vendor-uuid-1');
      expect(
        fakeUsersRepo.capturedRegisterDto!.vendorRole,
        RegisterDtoVendorRoleEnum.MANAGER,
      );
      expect(fakeMembersRepo.adminAddMemberCalled, isFalse);

      expect(fakeUsersRepo.capturedUpdatedUserId, 'user-123');
      expect(fakeUsersRepo.capturedUpdateDto?.title, 'Store Manager');
      expect(fakeUsersRepo.capturedUpdateDto?.titleAr, 'مدير المتجر');
    },
  );

  test(
    'UserNotifier.addUser does not send vendorId or vendorRole for non-VENDOR_MEMBER roles',
    () async {
      final fakeUsersRepo = _FakeAdminUsersRepository();
      final fakeMembersRepo = _FakeVendorMembersRepository();

      final container = ProviderContainer(
        overrides: [
          adminUsersRepositoryProvider.overrideWithValue(fakeUsersRepo),
          vendorMembersRepositoryProvider.overrideWithValue(fakeMembersRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(userProvider.notifier).addUser(
            name: 'Admin User',
            email: 'admin@otlob.com',
            password: 'Password123!',
            role: 'ADMIN',
            phone: '+201000000002',
            vendorId: 'stale-vendor-id',
            vendorRole: 'OWNER',
            permissions: ['MANAGE_ORDERS'],
          );

      expect(fakeUsersRepo.capturedRegisterDto, isNotNull);
      expect(fakeUsersRepo.capturedRegisterDto!.role, RegisterDtoRoleEnum.ADMIN);
      expect(fakeUsersRepo.capturedRegisterDto!.vendorId, isNull);
      expect(fakeUsersRepo.capturedRegisterDto!.vendorRole, isNull);
      expect(fakeMembersRepo.adminAddMemberCalled, isFalse);

      expect(fakeUsersRepo.capturedUpdatedUserId, 'user-123');
      expect(
        fakeUsersRepo.capturedUpdateDto?.permissions?.toList(),
        [AdminUpdateUserDtoPermissionsEnum.MANAGE_ORDERS],
      );
    },
  );
}
