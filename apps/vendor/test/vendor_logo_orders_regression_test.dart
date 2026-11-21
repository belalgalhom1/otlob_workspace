import 'dart:typed_data';
import 'package:api/api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:data/data.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/features/orders/presentation/orders_screen.dart';
import 'package:vendor/features/vendors/presentation/vendor_provider.dart';
import 'package:vendor/features/vendors/presentation/widgets/add_vendor_dialog.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class _FakeAdminAuthRepo extends Fake implements SharedAuthRepository {
  _FakeAdminAuthRepo(this._role, [this._permissions = const []]);
  final String _role;
  final List<String> _permissions;

  @override
  Future<String?> getUserRole() async => _role;

  @override
  Future<List<String>> getUserPermissions() async => _permissions;

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<List<Map<String, dynamic>>> getVendorMemberships() async => const [];
}

class _SpyOrdersNotifier extends OrdersNotifier {
  _SpyOrdersNotifier(this._orders);
  List<dynamic> _orders;
  int fetchCalls = 0;

  @override
  AsyncValue<OrdersStateData> build() => AsyncValue.data(
        OrdersStateData(_orders, _orders.length, const {}),
      );

  @override
  Future<void> fetchOrders({Map<String, dynamic> params = const {}}) async {
    fetchCalls++;
    state = AsyncValue.data(OrdersStateData(_orders, _orders.length, params));
  }

  void pushUpdatedOrders(List<dynamic> next) {
    _orders = next;
    state = AsyncValue.data(OrdersStateData(_orders, _orders.length, const {}));
  }
}

class _FakeVerticalsRepo extends Fake implements AdminVerticalsRepository {
  @override
  Future<List<dynamic>> verticalsFindAll({bool? activeOnly}) async => const [
        {'id': 'vert-food', 'name': 'Food', 'nameAr': 'طعام'},
      ];
}

class _SpyAdminVendorsRepo extends Fake implements AdminVendorsRepository {
  int updateCalls = 0;
  int uploadLogoCalls = 0;
  int uploadCoverCalls = 0;
  String? lastLogoVendorId;
  String? lastLogoFileName;

  @override
  Future<dynamic> getVendors({String? search}) async =>
      const {'vendors': <dynamic>[], 'total': 0};

  @override
  Future<dynamic> vendorsUpdate({
    required String vendorId,
    required UpdateVendorDto updateVendorDto,
  }) async {
    updateCalls++;
    return {'id': vendorId};
  }

  @override
  Future<dynamic> uploadVendorLogo({
    required String vendorId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    uploadLogoCalls++;
    lastLogoVendorId = vendorId;
    lastLogoFileName = fileName;
    return {'logo': '/media/vendors/$vendorId-logo.webp'};
  }

  @override
  Future<dynamic> uploadVendorCover({
    required String vendorId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    uploadCoverCalls++;
    return {'coverImage': '/media/vendors/$vendorId-cover.webp'};
  }
}

class _FakeXFile extends Fake implements XFile {
  _FakeXFile(this._name, this._bytes);
  final String _name;
  final Uint8List _bytes;

  @override
  String get name => _name;

  @override
  String get path => '/tmp/$_name';

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

class _FakeVendorProfileRepo extends Fake implements VendorProfileRepository {}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.loadFromString(
      envString: 'API_URL=https://api.otlob.test\nWS_URL=wss://api.otlob.test',
    );
  });

  testWidgets(
    'OrdersScreen resolves vendor coverImage fallback, prioritizes explicit logo, isolates per-vendor logos, gracefully handles missing/invalid URLs, and updates after profile change',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({'user_role': 'SUPER_ADMIN'});
      tester.view.physicalSize = const Size(412, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ordersNotifier = _SpyOrdersNotifier([
        // Case 1: Single-vendor order where logo is null -> must fall back to coverImage
        {
          'id': 'ord-bk',
          'orderNumber': 'ORD-BK-1',
          'status': 'DELIVERED',
          'paymentMethod': 'CASH_ON_DELIVERY',
          'subtotal': 90.0,
          'grandTotal': 110.0,
          'deliveryAddress': 'السكة الحديد',
          'createdAt': '2026-11-21T09:22:00Z',
          'customer': {
            'user': {
              'name': 'belalgalhom',
              'phone': '+201132123398',
              'avatar': 'https://cdn.otlob-test.invalid/users/belal.png',
            },
          },
          'vendor': {
            'id': 'v-bk',
            'storeName': 'Burger King',
            'storeNameAr': 'برجر كنج',
            'logo': null,
            'coverImage': '/media/vendors/bk-cover.webp',
            'phone': '01011112222',
            'isContracted': true,
          },
          'vendorBranch': {
            'name': 'haha - bH',
            'isContracted': true,
          },
          'vendorFulfillments': [
            {
              'id': 'ff-bk',
              'vendorId': 'v-bk',
              'status': 'DELIVERED',
              'subtotal': 90.0,
              'vendor': {
                'id': 'v-bk',
                'storeName': 'Burger King',
                'storeNameAr': 'برجر كنج',
                'logo': null,
                'coverImage': '/media/vendors/bk-cover.webp',
                'phone': '01011112222',
                'isContracted': true,
              },
              'vendorBranch': {
                'name': 'haha - bH',
                'isContracted': true,
              },
            },
          ],
          'items': [
            {
              'id': 'it-bk-1',
              'fulfillmentId': 'ff-bk',
              'productName': 'yahah',
              'quantity': 1,
              'unitPrice': 90.0,
              'product': {
                'imageUrl': 'https://cdn.otlob-test.invalid/products/yahah.png',
              },
            },
          ],
        },
        // Case 2: Second vendor order with explicit logo (must beat coverImage) and no cross-vendor bleed
        {
          'id': 'ord-ph',
          'orderNumber': 'ORD-PH-2',
          'status': 'PREPARING',
          'paymentMethod': 'CASH_ON_DELIVERY',
          'subtotal': 120.0,
          'grandTotal': 140.0,
          'deliveryAddress': 'Downtown',
          'createdAt': '2026-11-21T09:25:00Z',
          'customer': {
            'user': {'name': 'Omar', 'phone': '01099990000'},
          },
          'vendor': {
            'id': 'v-ph',
            'storeName': 'Pizza Hut',
            'logo': 'https://cdn.otlob-test.invalid/vendors/ph-logo.png',
            'coverImage': 'https://cdn.otlob-test.invalid/vendors/ph-cover.png',
            'isContracted': true,
          },
          'vendorFulfillments': [
            {
              'id': 'ff-ph',
              'vendorId': 'v-ph',
              'status': 'PREPARING',
              'subtotal': 120.0,
              'vendor': {
                'id': 'v-ph',
                'storeName': 'Pizza Hut',
                'logo': 'https://cdn.otlob-test.invalid/vendors/ph-logo.png',
                'coverImage':
                    'https://cdn.otlob-test.invalid/vendors/ph-cover.png',
              },
            },
          ],
          'items': const [],
        },
        // Case 3: Multi-vendor order with distinct logos + invalid/'null' placeholder store
        {
          'id': 'ord-mv',
          'orderNumber': 'ORD-MV-3',
          'isMultiVendor': true,
          'status': 'PREPARING',
          'paymentMethod': 'CASH_ON_DELIVERY',
          'subtotal': 200.0,
          'grandTotal': 230.0,
          'deliveryAddress': 'Zamalek',
          'createdAt': '2026-11-21T09:30:00Z',
          'customer': {
            'user': {'name': 'Nour', 'phone': '01222334455'},
          },
          'vendor': null,
          'vendorFulfillments': [
            {
              'id': 'ff-a',
              'vendorId': 'v-a',
              'status': 'PREPARING',
              'subtotal': 100.0,
              'vendor': {
                'id': 'v-a',
                'storeName': 'Store Alpha',
                'logo': 'https://cdn.otlob-test.invalid/vendors/alpha.png',
              },
            },
            {
              'id': 'ff-b',
              'vendorId': 'v-b',
              'status': 'PREPARING',
              'subtotal': 50.0,
              'vendor': {
                'id': 'v-b',
                'storeName': 'Store Beta',
                'logo': null,
                'coverImage': '/media/vendors/beta-cover.webp',
              },
            },
            {
              'id': 'ff-c',
              'vendorId': 'v-c',
              'status': 'PENDING',
              'subtotal': 50.0,
              'vendor': {
                'id': 'v-c',
                'storeName': 'Store InvalidUrl',
                'logo': 'null',
                'coverImage': '   ',
              },
            },
          ],
          'items': const [],
        },
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedAuthRepositoryProvider
                .overrideWithValue(_FakeAdminAuthRepo('SUPER_ADMIN', ['MANAGE_ORDERS'])),
            ordersProvider.overrideWith(() => ordersNotifier),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrdersScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Expand all three orders (ensureVisible first because expanded cards grow vertically)
      await tester.ensureVisible(find.text('#ORD-BK-1'));
      await tester.tap(find.text('#ORD-BK-1'));
      await tester.pump();
      await tester.ensureVisible(find.text('#ORD-PH-2'));
      await tester.tap(find.text('#ORD-PH-2'));
      await tester.pump();
      await tester.ensureVisible(find.text('#ORD-MV-3'));
      await tester.tap(find.text('#ORD-MV-3'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final bkResolvedUrl =
          ImageUtils.formatImageUrl('/media/vendors/bk-cover.webp');

      // Burger King single-vendor expanded card displays bk-cover.webp with per-order/per-vendor ValueKey
      final bkAvatar = tester.widget<AppNetworkAvatar>(
        find.byKey(ValueKey('ord_single_vendor_ord-bk_v-bk_$bkResolvedUrl')),
      );
      expect(bkAvatar.imageUrl, bkResolvedUrl);

      // Pizza Hut prioritizes explicit logo over coverImage and uses its own v-ph ValueKey
      const phLogoUrl = 'https://cdn.otlob-test.invalid/vendors/ph-logo.png';
      final phAvatar = tester.widget<AppNetworkAvatar>(
        find.byKey(const ValueKey('ord_single_vendor_ord-ph_v-ph_$phLogoUrl')),
      );
      expect(phAvatar.imageUrl, phLogoUrl);

      final allUrls = tester
          .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .map((w) => w.imageUrl)
          .toList();
      expect(bkResolvedUrl, 'https://api.otlob.test/media/vendors/bk-cover.webp');
      expect(allUrls, contains(bkResolvedUrl));
      expect(allUrls, contains(phLogoUrl));
      expect(
        allUrls,
        isNot(contains('https://cdn.otlob-test.invalid/vendors/ph-cover.png')),
      );
      expect(
        allUrls,
        contains('https://cdn.otlob-test.invalid/vendors/alpha.png'),
      );
      expect(
        allUrls,
        contains('https://api.otlob.test/media/vendors/beta-cover.webp'),
      );

      // Invalid URL store renders store fallback icon instead of crashing
      expect(find.byIcon(LucideIcons.store), findsWidgets);

      // Simulate vendor updating its logo -> order screen updates without sticky old logo
      final updatedOrders = List<dynamic>.from(ordersNotifier.state.value!.orders);
      final updatedBk = Map<String, dynamic>.from(updatedOrders.first as Map);
      updatedBk['vendor'] = {
        'id': 'v-bk',
        'storeName': 'Burger King',
        'logo': 'https://cdn.otlob-test.invalid/vendors/bk-new-logo.png',
        'coverImage': '/media/vendors/bk-cover.webp',
      };
      updatedOrders[0] = updatedBk;
      ordersNotifier.pushUpdatedOrders(updatedOrders);
      await tester.pump();

      const newBkUrl = 'https://cdn.otlob-test.invalid/vendors/bk-new-logo.png';
      expect(
        find.byKey(
          const ValueKey('ord_single_vendor_ord-bk_v-bk_$newBkUrl'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
            .map((w) => w.imageUrl),
        contains(newBkUrl),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AddVendorDialog shows both Store Logo and Cover Image pickers in edit and create modes',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({'user_role': 'SUPER_ADMIN'});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminVerticalsRepositoryProvider
                .overrideWithValue(_FakeVerticalsRepo()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: AddVendorDialog(
                vendor: {
                  'id': 'v-bk',
                  'storeName': 'Burger King',
                  'logo': '/media/vendors/v-bk-logo.webp',
                  'coverImage': '/media/vendors/v-bk-cover.webp',
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Store Logo'), findsOneWidget);
      expect(find.text('Change Logo'), findsOneWidget);
      expect(find.text('Change Image'), findsOneWidget);

      // Create mode (without existing images) exposes dedicated Upload Logo & Upload Cover actions
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminVerticalsRepositoryProvider
                .overrideWithValue(_FakeVerticalsRepo()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(
              body: AddVendorDialog(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Store Logo'), findsOneWidget);
      expect(find.text('Upload Logo'), findsOneWidget);
      expect(find.text('Upload Cover'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'VendorNotifier uploads separate logo & coverImage and refreshes ordersProvider',
    () async {
      FlutterSecureStorage.setMockInitialValues({'user_role': 'SUPER_ADMIN'});
      final spyVendorsRepo = _SpyAdminVendorsRepo();
      final spyOrdersNotifier = _SpyOrdersNotifier(const []);

      final container = ProviderContainer(
        overrides: [
          sharedAuthRepositoryProvider
              .overrideWithValue(_FakeAdminAuthRepo('SUPER_ADMIN')),
          adminVendorsRepositoryProvider.overrideWithValue(spyVendorsRepo),
          vendorProfileRepositoryProvider
              .overrideWithValue(_FakeVendorProfileRepo()),
          ordersProvider.overrideWith(() => spyOrdersNotifier),
        ],
      );
      addTearDown(container.dispose);

      // Keep ordersProvider initialized before updateVendor so refresh fires
      container.read(ordersProvider);
      container.read(vendorProvider.notifier).build();
      await container.read(vendorProvider.notifier).updateVendor('v-bk', {
        'storeName': 'Burger King',
        'logo': _FakeXFile('new-logo.png', Uint8List.fromList([1, 2, 3, 4])),
        'coverImage': _FakeXFile(
          'new-cover.png',
          Uint8List.fromList([5, 6, 7, 8]),
        ),
      });

      expect(spyVendorsRepo.updateCalls, 1);
      expect(spyVendorsRepo.uploadLogoCalls, 1);
      expect(spyVendorsRepo.uploadCoverCalls, 1);
      expect(spyVendorsRepo.lastLogoVendorId, 'v-bk');
      expect(spyVendorsRepo.lastLogoFileName, 'new-logo.png');
      expect(spyOrdersNotifier.fetchCalls, greaterThanOrEqualTo(1));
    },
  );
}
