import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/widgets/stat_card.dart';
import 'package:intl/intl.dart';
import 'package:vendor/features/access_control/presentation/access_control_screen.dart';
import 'package:vendor/features/vendors/presentation/vendors_screen.dart';
import 'package:vendor/features/orders/presentation/orders_screen.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/features/drivers/presentation/drivers_screen.dart';
import 'package:vendor/features/drivers/data/driver_providers.dart';
import 'package:vendor/features/tickets/presentation/tickets_screen.dart';
import 'package:vendor/features/tickets/presentation/ticket_provider.dart';
import 'package:vendor/features/users/presentation/users_screen.dart';
import 'package:vendor/features/zones/presentation/zones_screen.dart';
import 'package:vendor/features/vendors/presentation/vendor_provider.dart';
import 'package:vendor/features/vendors/presentation/vertical_provider.dart';
import 'package:vendor/features/vendors/presentation/verticals_screen.dart';
import 'package:vendor/features/promotions/presentation/promotions_screen.dart';
import 'package:vendor/features/wallet/presentation/wallet_dashboard_screen.dart';
import 'package:vendor/features/audit_logs/presentation/audit_logs_screen.dart';
import 'package:vendor/features/audit_logs/data/audit_logs_provider.dart';
import 'package:vendor/features/users/presentation/user_provider.dart';
import 'package:vendor/features/zones/presentation/zone_provider.dart';
import 'package:vendor/features/promotions/presentation/promotion_provider.dart';
import 'package:vendor/features/dashboard/presentation/widgets/vendor_context_switcher.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:core/core.dart';
import 'package:vendor/features/settings/presentation/settings_screen.dart';
import 'package:vendor/features/chat/presentation/pages/inbox_screen.dart';
import '../../notifications/presentation/announcements_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import 'package:vendor/features/driver_shifts/presentation/driver_shifts_screen.dart';
import 'package:vendor/features/analytics/presentation/pages/analytics_screen.dart';
import 'package:vendor/features/dashboard/presentation/widgets/user_profile_dialog.dart';

final mostOrderedProductProvider = FutureProvider.family<dynamic, String>((ref, vendorId) async {
  try {
    final repo = ref.read(vendorStatisticsRepositoryProvider);
    return await repo.getMostOrderedProduct(vendorId);
  } catch (e) {
    debugPrint('Failed to fetch most ordered product: $e');
    return null;
  }
});

class DashboardScreen extends ConsumerStatefulWidget {

  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isStatsExpanded = false;
  String? _userRole;
  String? _userName;
  String? _vendorId;
  String? _vendorRole;
  List<String> _userPermissions = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _hasPermission(String requiredPermission) {
    if (_userRole == 'SUPER_ADMIN') return true;
    if (_userRole == 'ADMIN' && _userPermissions.contains(requiredPermission)) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initData());
  }

  Future<void> _initData() async {
    await _loadUserInfo();
    ref.read(socketServiceProvider).init();
    await ref.read(permissionServiceProvider).requestNotificationPermission();
    if (_userRole != null) {
      final pushService = ref.read(pushNotificationServiceProvider);
      Future(() async {
        try {
          // Initialize push notifications in the background to prevent
          // hanging the UI if Firebase services are unavailable (e.g. SERVICE_NOT_AVAILABLE)
          await pushService.initialize();
          await pushService.subscribeToRoleTopics(_userRole!);
        } catch (e) {
          debugPrint('FCM init error: $e');
        }
      });
    }
    if (mounted) {
      final isVendor = _userRole == 'VENDOR_MEMBER';

      if (isVendor && _vendorId != null && _vendorId != 'null') {
        ref.read(vendorProvider.notifier).fetchVendors(vendorId: _vendorId);
      } else if (!isVendor) {
        if (_hasPermission('MANAGE_VENDORS')) {
          ref.read(vendorProvider.notifier).fetchVendors();
        }
      }

      // Administrative data only for admins
      if (!isVendor) {
        if (_hasPermission('MANAGE_ORDERS')) {
          ref.read(ordersProvider.notifier).fetchOrders(params: {'limit': 1}); // Fetch to get total orders count
        }
        if (_hasPermission('MANAGE_VENDORS')) {
          ref.read(verticalProvider.notifier).fetchVerticals();
        }
        if (_hasPermission('MANAGE_USERS')) {
          ref.read(userProvider.notifier).fetchUsers();
        }
        if (_hasPermission('MANAGE_SETTINGS')) {
          ref.read(zoneProvider.notifier).fetchZones();
        }
        if (_hasPermission('MANAGE_PROMOTIONS')) {
          ref.read(promotionProvider.notifier).fetchPromotions();
        }
        if (_hasPermission('MANAGE_TICKETS')) {
          ref.read(ticketProvider.notifier).fetchTickets(params: {'limit': 1});
        }
      } else {
        ref.read(ordersProvider.notifier).fetchOrders(params: {'limit': 1}); // Vendor members need total orders too
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    final name = await ref.read(sharedAuthRepositoryProvider).getUserName();
    final memberships = await ref.read(sharedAuthRepositoryProvider).getVendorMemberships();
    final perms = await ref.read(sharedAuthRepositoryProvider).getUserPermissions();
    String? vId = ref.read(activeVendorProvider);
    String? vRole;
    if (vId != null) {
      try {
        final activeMem = memberships.firstWhere((m) => m['vendorId'] == vId);
        vRole = activeMem['role'] as String?;
      } catch (_) {}
    } else if (memberships.isNotEmpty) {
      final map = memberships.first as Map<String, dynamic>;
      vId = map['vendorId'] as String?;
      vRole = map['role'] as String?;
    }
    if (mounted) {
      setState(() {
        _userRole = role;
        _userName = name;
        _vendorId = vId;
        _vendorRole = vRole;
        _userPermissions = perms;
        if (role == 'ADMIN') {
          if (_hasPermission('VIEW_STATISTICS')) {
            _selectedIndex = 0;
          } else if (_hasPermission('MANAGE_ORDERS')) {
            _selectedIndex = 1;
          } else if (_hasPermission('MANAGE_VENDORS')) {
            _selectedIndex = 2;
          } else if (_hasPermission('MANAGE_DRIVERS')) {
            _selectedIndex = 3;
          } else if (_hasPermission('MANAGE_USERS')) {
            _selectedIndex = 4;
          } else {
            _selectedIndex = 0;
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(activeVendorProvider, (previous, next) {
      if (next != previous && next != null) {
        setState(() {
          _vendorId = next;
        });
        _initData(); // Refetch data
      }
    });

    final inboxCounts = ref.watch(inboxCountsProvider);

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 1100;

          return Scaffold(
            key: _scaffoldKey,
            drawer: isMobile ? _buildSidebar(isMobile: true) : null,
            body: Row(
              children: [
                if (!isMobile) _buildSidebar(isMobile: false),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12.0 : 24.0,
                            vertical: 24.0,
                          ),
                          child: Row(
                            children: [
                              if (isMobile)
                                IconButton(
                                  icon: Icon(
                                    LucideIcons.menu,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  onPressed: () =>
                                      _scaffoldKey.currentState?.openDrawer(),
                                ),
                              if (isMobile) const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    _getMenuTitle(context, _selectedIndex),
                                    style: TextStyle(
                                      fontSize: isMobile ? 20 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),

                              if (!isMobile) _buildSearchBar(),
                              if (!isMobile) const SizedBox(width: 16),
                              _buildHeaderAction(
                                LucideIcons.messageSquare,
                                onTap: () => setState(() => _selectedIndex = 6),
                                isMobile: isMobile,
                                badgeCount: inboxCounts.chatUnread,
                              ),
                              SizedBox(width: isMobile ? 4 : 8),
                              _buildHeaderAction(
                                LucideIcons.bell,
                                onTap: () => setState(() => _selectedIndex = 17),
                                isMobile: isMobile,
                                badgeCount: inboxCounts.notificationsUnread,
                              ),
                              SizedBox(width: isMobile ? 4 : 8),
                              _buildThemeToggle(isMobile: isMobile),
                              SizedBox(width: isMobile ? 4 : 8),
                              _buildLanguageToggle(isMobile: isMobile),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildIndexedStack(isMobile),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Indices that must NOT be wrapped in a SingleChildScrollView
  /// (they manage their own scroll or require Expanded).
  static const _noScrollIndices = {3, 5, 6, 7, 11, 12, 14, 15, 16, 17};

  Widget _buildIndexedStack(bool isMobile) {
    Widget wrapForIndex(int index, Widget child) {
      if (_noScrollIndices.contains(index)) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: child,
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: child,
      );
    }

    return wrapForIndex(
      _selectedIndex,
      _buildContent(isMobile, _selectedIndex),
    );
  }

  Widget _buildSidebar({required bool isMobile}) {
    final inboxCounts = ref.watch(inboxCountsProvider);

    return Container(
      width: isMobile ? 280 : 110,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: isMobile
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.package,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          LucideIcons.package,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.appTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
          ),
          if (_userRole == 'VENDOR_MEMBER') VendorContextSwitcher(isMobile: isMobile),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_userRole == 'VENDOR_MEMBER') ...[
                    _buildMenuItem(
                      0,
                      LucideIcons.layoutDashboard,
                      AppLocalizations.of(context)!.dashboard,
                      isMobile,
                    ),
                    _buildMenuItem(
                      1,
                      LucideIcons.shoppingBag,
                      AppLocalizations.of(context)!.orders,
                      isMobile,
                    ),
                    _buildMenuItem(
                      2,
                      LucideIcons.store,
                      AppLocalizations.of(context)!.myVendor,
                      isMobile,
                    ),
                    _buildMenuItem(
                      5,
                      LucideIcons.helpCircle,
                      AppLocalizations.of(context)!.tickets,
                      isMobile,
                    ),
                    _buildMenuItem(
                      6,
                      LucideIcons.messageSquare,
                      AppLocalizations.of(context)!.inbox,
                      isMobile,
                      badgeCount: inboxCounts.chatUnread,
                    ),
                    _buildMenuItem(
                      17,
                      LucideIcons.bell,
                      AppLocalizations.of(context)!.notificationsTitle,
                      isMobile,
                      badgeCount: inboxCounts.notificationsUnread,
                    ),
                    _buildMenuItem(
                      11,
                      LucideIcons.wallet,
                      AppLocalizations.of(context)!.walletAndFinancials,
                      isMobile,
                    ),
                  ] else ...[
                    if (_hasPermission('VIEW_STATISTICS')) ...[
                      _buildMenuItem(
                        0,
                        LucideIcons.layoutDashboard,
                        AppLocalizations.of(context)!.dashboard,
                        isMobile,
                      ),
                      _buildMenuItem(
                        16,
                        LucideIcons.barChart3,
                        AppLocalizations.of(context)!.analytics,
                        isMobile,
                      ),
                    ],
                    if (_hasPermission('MANAGE_ORDERS'))
                      _buildMenuItem(
                        1,
                        LucideIcons.shoppingBag,
                        AppLocalizations.of(context)!.orders,
                        isMobile,
                      ),
                    if (_hasPermission('MANAGE_VENDORS')) ...[
                      _buildMenuItem(
                        2,
                        LucideIcons.store,
                        AppLocalizations.of(context)!.vendors,
                        isMobile,
                      ),
                      _buildMenuItem(
                        9,
                        LucideIcons.layers,
                        AppLocalizations.of(context)!.businessTypes,
                        isMobile,
                      ),
                    ],
                    if (_hasPermission('MANAGE_DRIVERS')) ...[
                      _buildMenuItem(
                        3,
                        LucideIcons.truck,
                        AppLocalizations.of(context)!.drivers,
                        isMobile,
                      ),
                      _buildMenuItem(
                        15,
                        LucideIcons.calendarClock,
                        AppLocalizations.of(context)!.driverShifts,
                        isMobile,
                      ),
                    ],
                    if (_hasPermission('MANAGE_USERS')) ...[
                      _buildMenuItem(
                        4,
                        LucideIcons.userPlus,
                        AppLocalizations.of(context)!.users,
                        isMobile,
                      ),
                      _buildMenuItem(
                        14,
                        LucideIcons.shieldCheck,
                        AppLocalizations.of(context)!.accessControl,
                        isMobile,
                      ),
                    ],
                    if (_hasPermission('MANAGE_SETTINGS'))
                      _buildMenuItem(
                        8,
                        LucideIcons.map,
                        AppLocalizations.of(context)!.zones,
                        isMobile,
                      ),
                    if (_hasPermission('MANAGE_PROMOTIONS'))
                      _buildMenuItem(
                        10,
                        LucideIcons.megaphone,
                        AppLocalizations.of(context)!.promotions,
                        isMobile,
                      ),
                    if (_hasPermission('MANAGE_FINANCE') || _hasPermission('VIEW_FINANCIALS'))
                      _buildMenuItem(
                        11,
                        LucideIcons.wallet,
                        AppLocalizations.of(context)!.walletAndFinancials,
                        isMobile,
                      ),
                    if (_hasPermission('VIEW_AUDIT_LOGS'))
                      _buildMenuItem(
                        12,
                        LucideIcons.shieldAlert,
                        AppLocalizations.of(context)!.auditLogs,
                        isMobile,
                      ),
                    if (_hasPermission('MANAGE_ANNOUNCEMENTS'))
                      _buildMenuItem(
                        13,
                        LucideIcons.radio,
                        AppLocalizations.of(context)!.announcementsTitle,
                        isMobile,
                      ),
                    if (_hasPermission('MANAGE_TICKETS'))
                      _buildMenuItem(
                        5,
                        LucideIcons.helpCircle,
                        AppLocalizations.of(context)!.tickets,
                        isMobile,
                      ),
                    if (_hasPermission('MANAGE_CONVERSATIONS'))
                      _buildMenuItem(
                        6,
                        LucideIcons.messageSquare,
                        AppLocalizations.of(context)!.inbox,
                        isMobile,
                        badgeCount: inboxCounts.chatUnread,
                      ),
                    _buildMenuItem(
                      17,
                      LucideIcons.bell,
                      AppLocalizations.of(context)!.notificationsTitle,
                      isMobile,
                      badgeCount: inboxCounts.notificationsUnread,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Column(
            children: [
              Divider(color: Theme.of(context).dividerColor),
              if (_hasPermission('MANAGE_SETTINGS') || _userRole == 'SUPER_ADMIN')
                _buildMenuItem(
                  7,
                  LucideIcons.settings,
                  AppLocalizations.of(context)!.settings,
                  isMobile,
                ),
              _buildUserProfile(context),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  void _openUserProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => UserProfileDialog(
        onProfileUpdated: () => _loadUserInfo(),
      ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1100;
    final l10n = AppLocalizations.of(context);

    String initials = 'AD';
    if (_userName != null && _userName!.trim().isNotEmpty) {
      final parts = _userName!.trim().split(' ');
      if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        initials = parts[0]
            .substring(0, parts[0].length > 1 ? 2 : 1)
            .toUpperCase();
      }
    } else if (_userRole != null && _userRole!.isNotEmpty) {
      initials = _userRole!
          .substring(0, _userRole!.length > 1 ? 2 : 1)
          .toUpperCase();
    }

    String translatedRole = _userRole?.replaceAll('_', ' ') ?? 'User';
    if (l10n != null) {
      if (_userRole == 'SUPER_ADMIN') {
        translatedRole = l10n.superAdmin;
      } else if (_userRole == 'ADMIN') {
        translatedRole = l10n.admin;
      } else if (_userRole == 'VENDOR_MEMBER') {
        translatedRole = l10n.vendorMember;
      } else if (_userRole == 'DRIVER') {
        translatedRole = l10n.driver;
      } else if (_userRole == 'CUSTOMER') {
        translatedRole = l10n.customer;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isDesktop
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _openUserProfileDialog(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Tooltip(
                    message: _userName ?? 'Profile',
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(initials, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(LucideIcons.logOut, size: 16),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openUserProfileDialog(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: Text(initials, style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _userName ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  translatedRole,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.logOut, size: 16),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchHint,
          prefixIcon: const Icon(LucideIcons.search, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildContent(bool isMobile, [int? index]) {
    switch (index ?? _selectedIndex) {
      case 0:
        return _buildDashboardContent(isMobile);
      case 1:
        return const OrdersScreen();
      case 2:
        return VendorsScreen(userRole: _userRole, vendorRole: _vendorRole);
      case 3:
        return const DriversScreen();
      case 4:
        return const UsersScreen();
      case 5:
        return const TicketsScreen();
      case 6:
        return const InboxScreen();
      case 7:
        return const SettingsScreen();
      case 8:
        return const ZonesScreen();
      case 9:
        return const VerticalsScreen();
      case 10:
        return const PromotionsScreen();
      case 11:
        return WalletDashboardScreen(
          userRole: _userRole,
          canManageFinance: _hasPermission('MANAGE_FINANCE'),
          canViewStatistics: _hasPermission('VIEW_STATISTICS'),
        );
      case 12:
        return const AuditLogsScreen();
      case 13:
        return const AnnouncementsScreen();
      case 14:
        return const AccessControlScreen();
      case 15:
        return const DriverShiftsScreen();
      case 16:
        return AnalyticsScreen(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 17:
        return const NotificationsScreen();
      default:
        return _buildComingSoon();
    }
  }

  Widget _buildComingSoon() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.construction,
              size: 64,
              
            ),
            const SizedBox(height: 16),
            Text(
              '${_getMenuTitle(context, _selectedIndex)} ${AppLocalizations.of(context)!.comingSoon}',
              style: const TextStyle(
                fontSize: 20,
                
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(bool isMobile) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Always show these core stats
            if (_hasPermission('MANAGE_VENDORS') || _userRole == 'VENDOR_MEMBER')
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(vendorProvider);
                String count = '...';
                if (state.hasValue) count = state.value!.total.toString();
                return StatCard(
                  title: l10n.totalVendors,
                  value: count,
                  icon: LucideIcons.store,
                  color: AppColors.primary,
                  isMobile: isMobile,
                  onTap: () => setState(() => _selectedIndex = 2),
                );
              },
            ),
            if (_hasPermission('MANAGE_USERS'))
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(userProvider);
                  String count = '...';
                  if (state.hasValue) count = state.value!.total.toString();
                  return StatCard(
                    title: l10n.systemUsers,
                    value: count,
                    icon: LucideIcons.users,
                    color: AppColors.info,
                    isMobile: isMobile,
                    onTap: () => setState(() => _selectedIndex = 4),
                  );
                },
              ),
            if (_hasPermission('MANAGE_ORDERS') || _userRole == 'VENDOR_MEMBER')
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(ordersProvider);
                String orderCount = '0';
                if (state.hasValue) {
                  orderCount = state.value!.total.toString();
                } else if (state.isLoading) {
                  orderCount = '...';
                }

                return StatCard(
                  title: l10n.orders,
                  value: orderCount,
                  icon: LucideIcons.shoppingBag,
                  color: AppColors.warning,
                  isMobile: isMobile,
                  onTap: () => setState(() => _selectedIndex = 1),
                );
              },
            ),
            if (_hasPermission('MANAGE_DRIVERS'))
              Consumer(
                builder: (context, ref, child) {
                  final state = ref.watch(driversProvider);
                  String count = '0';
                  if (state.hasValue) {
                    count = state.value!.total.toString();
                  } else if (state.isLoading) {
                    count = '...';
                  }

                  return StatCard(
                    title: l10n.drivers,
                    value: count,
                    icon: LucideIcons.truck,
                    color: AppColors.success,
                    isMobile: isMobile,
                    onTap: () => setState(() => _selectedIndex = 3),
                  );
                },
              ),

            if (_isStatsExpanded) ...[
              if (_hasPermission('MANAGE_TICKETS'))
                Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(ticketProvider);
                    String count = '0';
                    if (state.hasValue && state.value != null) {
                      count = state.value!.total.toString();
                    } else if (state.isLoading) {
                      count = '...';
                    }

                    return StatCard(
                      title: l10n.tickets,
                      value: count,
                      icon: LucideIcons.helpCircle,
                      color: AppColors.error,
                      isMobile: isMobile,
                      onTap: () => setState(() => _selectedIndex = 5),
                    );
                  },
                ),
              if (_hasPermission('MANAGE_SETTINGS'))
                Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(zoneProvider);
                    String count = '0';
                    if (state.hasValue) count = state.value!.total.toString();
                    return StatCard(
                      title: l10n.deliveryZones,
                      value: count,
                      icon: LucideIcons.map,
                      color: Colors.teal,
                      isMobile: isMobile,
                      onTap: () => setState(() => _selectedIndex = 8),
                    );
                  },
                ),
              if (_hasPermission('MANAGE_VENDORS'))
                Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(verticalProvider);
                    String count = '0';
                    if (state.hasValue) count = state.value!.length.toString();
                    return StatCard(
                      title: l10n.businessTypes,
                      value: count,
                      icon: LucideIcons.layers,
                      color: Colors.purple,
                      isMobile: isMobile,
                      onTap: () => setState(() => _selectedIndex = 9),
                    );
                  },
                ),
              if (_hasPermission('MANAGE_PROMOTIONS'))
                Consumer(
                  builder: (context, ref, child) {
                    final state = ref.watch(promotionProvider);
                    String count = '0';
                    if (state.hasValue) count = state.value!.length.toString();
                    return StatCard(
                      title: l10n.promotions,
                      value: count,
                      icon: LucideIcons.megaphone,
                      color: Colors.orange,
                      isMobile: isMobile,
                      onTap: () => setState(() => _selectedIndex = 10),
                    );
                  },
                ),
            ],
          ],
        ),
        if (_hasPermission('MANAGE_TICKETS') || _hasPermission('MANAGE_SETTINGS') || _hasPermission('MANAGE_VENDORS') || _hasPermission('MANAGE_PROMOTIONS'))
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
                icon: Icon(
                  _isStatsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                ),
                label: Text(_isStatsExpanded ? l10n.showLess : l10n.showMore),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        if (!isMobile)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildRecentOrdersList(l10n)),
              if (_hasPermission('VIEW_AUDIT_LOGS')) ...[
                const SizedBox(width: 24),
                Expanded(child: _buildRecentLogsList(l10n)),
              ],
            ],
          )
        else
          Column(
            children: [
              _buildRecentOrdersList(l10n),
              if (_hasPermission('VIEW_AUDIT_LOGS')) ...[
                const SizedBox(height: 24),
                _buildRecentLogsList(l10n),
              ],
            ],
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRecentOrdersList(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.liveOrders,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                child: Text(
                  l10n.showMore,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(ordersProvider);
              return state.when(
                data: (data) {
                  if (data.orders.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          l10n.noOrdersFound,
                          style: const TextStyle(
                            
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.orders.length > 5 ? 5 : data.orders.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Theme.of(context).dividerColor),
                    itemBuilder: (context, index) {
                      final order = data.orders[index];
                      final status = order['status']?.toString() ?? 'PENDING';
                      final isCancelled = status.contains('CANCEL') || status.contains('REJECT');
                      final areFeesFinalized = !isCancelled;

                      final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
                      final grandTotal = double.tryParse(order['grandTotal']?.toString() ?? '0') ?? 0.0;
                      final displayTotal = areFeesFinalized ? grandTotal : subtotal;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.shoppingBag,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          'Order #${order['orderNumber'] ?? order['id'].toString().substring(0, 8)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          (order['vendor'] is Map ? order['vendor']['storeName'] : null) ?? 'Unknown Vendor',
                          style: const TextStyle(
                            fontSize: 12,
                            
                          ),
                        ),
                        trailing: Text(
                          '${displayTotal.toStringAsFixed(2)} EGP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, st) => Center(
                  child: Text(
                    AppLocalizations.of(context)!.errorLoadingOrders,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLogsList(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.systemLogs,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 12),
                child: Text(
                  l10n.showMore,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(auditLogsProvider);
              return state.when(
                data: (data) {
                  if (data.logs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          AppLocalizations.of(context)!.noSystemLogsFound,
                          style: const TextStyle(
                            
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.logs.length > 5 ? 5 : data.logs.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Theme.of(context).dividerColor),
                    itemBuilder: (context, index) {
                      final log = data.logs[index];
                      final actionType = (log['actionType'] ?? 'OTHER').toString();
                      final rawDate = (log['createdAt'] ?? '').toString();
                      String dateStr = rawDate;
                      try {
                        final date = DateTime.parse(rawDate).toLocal();
                        dateStr = DateFormat('MMM dd, HH:mm').format(date);
                      } catch (_) {}

                      Color iconColor;
                      IconData iconData;
                      switch (actionType) {
                        case 'CREATE':
                          iconColor = AppColors.success;
                          iconData = LucideIcons.plusCircle;
                          break;
                        case 'UPDATE':
                          iconColor = AppColors.warning;
                          iconData = LucideIcons.edit;
                          break;
                        case 'DELETE':
                          iconColor = AppColors.error;
                          iconData = LucideIcons.trash2;
                          break;
                        case 'LOGIN':
                        case 'LOGOUT':
                          iconColor = AppColors.info;
                          iconData = LucideIcons.logIn;
                          break;
                        default:
                          iconColor = AppColors.primary;
                          iconData = LucideIcons.activity;
                      }

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(iconData, size: 16, color: iconColor),
                        ),
                        title: Text(
                          actionType,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 11,
                            
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '${AppLocalizations.of(context)!.errorLoadingLogs}\n$e',
                      style: const TextStyle(color: AppColors.error, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    int index,
    IconData icon,
    String title,
    bool isMobile, {
    int badgeCount = 0,
  }) {
    final isSelected = _selectedIndex == index;
    bool isDesktop = !isMobile;
    final unselectedColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 8 : 16,
        vertical: 4,
      ),
      child: InkWell(
        onTap: () {
          setState(() => _selectedIndex = index);
          if (isMobile) _scaffoldKey.currentState?.closeDrawer();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isDesktop ? 12 : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: isDesktop
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Badge(
                      isLabelVisible: badgeCount > 0,
                      label: Text(
                        '$badgeCount',
                        style: const TextStyle(fontSize: 9, color: Colors.white),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? AppColors.primary : unselectedColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppColors.primary : unselectedColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Badge(
                      isLabelVisible: badgeCount > 0,
                      label: Text(
                        '$badgeCount',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? AppColors.primary : unselectedColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : unselectedColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(
    IconData icon, {
    VoidCallback? onTap,
    bool isMobile = false,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
        ),
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text(
            '$badgeCount',
            style: const TextStyle(fontSize: 10, color: Colors.white),
          ),
          child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildThemeToggle({bool isMobile = false}) {
    return Consumer(
      builder: (context, ref, child) {
        final themeMode = ref.watch(themeProvider);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return InkWell(
          onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              size: 16,
              color: Colors.amber,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageToggle({bool isMobile = false}) {
    return Consumer(
      builder: (context, ref, child) {
        final locale = ref.watch(localeProvider);
        final isArabic = locale.languageCode == 'ar';
        return InkWell(
          onTap: () => ref.read(localeProvider.notifier).toggleLanguage(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                if (!isMobile) ...[
                  const Icon(
                    LucideIcons.languages,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  isArabic ? 'EN' : 'AR',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMenuTitle(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l10n.dashboard;
      case 1:
        return l10n.orders;
      case 2:
        return l10n.vendors;
      case 3:
        return l10n.drivers;
      case 4:
        return l10n.users;
      case 5:
        return l10n.tickets;
      case 6:
        return l10n.inbox;
      case 7:
        return l10n.settings;
      case 8:
        return l10n.deliveryZones;
      case 9:
        return l10n.businessTypes;
      case 10:
        return l10n.promotions;
      case 11:
        return l10n.walletAndFinancials;
      case 12:
        return l10n.auditLogs;
      case 13:
        return l10n.announcementsTitle;
      case 14:
        return Localizations.localeOf(context).languageCode == 'ar' ? 'التحكم في الصلاحيات' : 'Access Control';
      case 15:
        return l10n.driverShifts;
      case 16:
        return l10n.analytics;
      case 17:
        return l10n.notificationsTitle;
      default:
        return l10n.dashboard;
    }
  }
}

