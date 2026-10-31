import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/widgets/stat_card.dart';
import 'package:intl/intl.dart';
import 'package:vendor/features/access_control/presentation/access_control_screen.dart';
import 'package:vendor/features/vendors/presentation/vendors_screen.dart';
import 'package:vendor/features/orders/presentation/orders_screen.dart';
import 'package:vendor/features/chat/presentation/pages/admin_chat_screen.dart';
import 'package:vendor/features/orders/presentation/orders_provider.dart';
import 'package:vendor/features/drivers/presentation/drivers_screen.dart';
import 'package:vendor/features/drivers/presentation/driver_managers_screen.dart';
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
import 'package:vendor/features/driver_breaks/presentation/driver_breaks_screen.dart';
import 'package:vendor/features/analytics/presentation/pages/analytics_screen.dart';
import 'package:vendor/features/dashboard/presentation/widgets/user_profile_dialog.dart';

final mostOrderedProductProvider = FutureProvider.family<dynamic, String>((
  ref,
  vendorId,
) async {
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
  String? _highlightOrderId;
  bool _isStatsExpanded = false;
  String? _userRole;
  String? _userName;
  String? _vendorId;
  String? _vendorRole;
  List<String> _userPermissions = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _hasPermission(String requiredPermission) {
    if (_userRole == 'SUPER_ADMIN') return true;
    if (_userPermissions.contains(requiredPermission)) return true;
    if (_userRole == 'DRIVER_MANAGER' &&
        requiredPermission == 'MANAGE_DRIVERS') {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initData());
    Future.microtask(() => _consumePendingNotificationRoute());
  }

  /// Routes banked notification taps (background + terminated cold starts):
  /// orders open the orders tab with the order expanded, chats open the
  /// conversation directly.
  void _consumePendingNotificationRoute() {
    final pending = ref.read(notificationRouterProvider);
    if (pending == null || !mounted) return;
    ref.read(notificationRouterProvider.notifier).clear();
    if (pending.kind == 'order') {
      setState(() {
        _selectedIndex = 1;
        _highlightOrderId = pending.id;
      });
    } else if (pending.kind == 'chat') {
      setState(() => _selectedIndex = 6);
      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminChatScreen(
            conversationId: pending.id,
            title: l10n.inbox,
            type: 'SUPPORT',
          ),
        ),
      );
    }
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
          ref
              .read(ordersProvider.notifier)
              .fetchOrders(
                params: {'limit': 1},
              ); // Fetch to get total orders count
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
        ref
            .read(ordersProvider.notifier)
            .fetchOrders(
              params: {'limit': 1},
            ); // Vendor members need total orders too
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    final name = await ref.read(sharedAuthRepositoryProvider).getUserName();
    final memberships = await ref
        .read(sharedAuthRepositoryProvider)
        .getVendorMemberships();
    final perms = await ref
        .read(sharedAuthRepositoryProvider)
        .getUserPermissions();
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
        } else if (role == 'DRIVER_MANAGER') {
          _selectedIndex = 3;
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
    ref.listen<PendingNotificationRoute?>(notificationRouterProvider, (
      previous,
      next,
    ) {
      if (next != null && next != previous) {
        _consumePendingNotificationRoute();
      }
    });

    final inboxCounts = ref.watch(inboxCountsProvider);

    return PopScope(
      canPop: _userRole == 'DRIVER_MANAGER'
          ? _selectedIndex == 3
          : _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final homeIndex = _userRole == 'DRIVER_MANAGER' ? 3 : 0;
        if (_selectedIndex != homeIndex) {
          setState(() {
            _selectedIndex = homeIndex;
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
                                  onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  _scaffoldKey.currentState?.openDrawer();
                                },
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

                              if (!isMobile) const SizedBox(width: 16),
                              if (isMobile) const SizedBox(width: 4),
                              _buildHeaderAction(
                                LucideIcons.messageSquare,
                                onTap: () => setState(() => _selectedIndex = 6),
                                isMobile: isMobile,
                                badgeCount: inboxCounts.chatUnread,
                              ),
                              SizedBox(width: isMobile ? 4 : 8),
                              _buildHeaderAction(
                                LucideIcons.bell,
                                onTap: () =>
                                    setState(() => _selectedIndex = 17),
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
                        Expanded(child: _buildIndexedStack(isMobile)),
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
  /// NOTE: 18 (DriverBreaksScreen) must stay here — its Column uses
  /// Expanded(TabBarView), which throws (blank page in release) inside a
  /// scroll view with unbounded height.
  static const _noScrollIndices = {3, 5, 6, 7, 11, 12, 14, 15, 16, 17, 18, 19};

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
          if (_userRole == 'VENDOR_MEMBER')
            VendorContextSwitcher(isMobile: isMobile),
          const SizedBox(height: 16),
          // Quick-jump entry: opens the searchable page palette
          // (abbreviations). Visible everywhere so it's reachable on
          // phones too, where the desktop header search bar is hidden.
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 8,
              vertical: 4,
            ),
            child: InkWell(
              onTap: () {
                if (isMobile) {
                  _scaffoldKey.currentState?.closeDrawer();
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (mounted) _showPageSearch();
                  });
                } else {
                  _showPageSearch();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: isMobile
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    if (isMobile) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.searchHint,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                  ] else if (_userRole == 'DRIVER_MANAGER') ...[
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
                    _buildMenuItem(
                      18,
                      LucideIcons.coffee,
                      AppLocalizations.of(context)!.breaks,
                      isMobile,
                    ),
                    _buildMenuItem(
                      11,
                      LucideIcons.wallet,
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'محفظة الإدارة'
                          : 'Manager Wallet',
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
                  ] else ...[
                    if (_hasPermission('VIEW_STATISTICS'))
                      _buildMenuItem(
                        0,
                        LucideIcons.layoutDashboard,
                        AppLocalizations.of(context)!.dashboard,
                        isMobile,
                      ),
                    // Orders sits above Analytics in the menu.
                    if (_hasPermission('MANAGE_ORDERS'))
                      _buildMenuItem(
                        1,
                        LucideIcons.shoppingBag,
                        AppLocalizations.of(context)!.orders,
                        isMobile,
                      ),
                    if (_hasPermission('VIEW_STATISTICS'))
                      _buildMenuItem(
                        16,
                        LucideIcons.barChart3,
                        AppLocalizations.of(context)!.analytics,
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
                      if (_userRole != 'DRIVER_MANAGER')
                        _buildMenuItem(
                          19,
                          LucideIcons.userCheck,
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'مسؤولو السائقين'
                              : 'Driver Managers',
                          isMobile,
                        ),
                      _buildMenuItem(
                        15,
                        LucideIcons.calendarClock,
                        AppLocalizations.of(context)!.driverShifts,
                        isMobile,
                      ),
                      _buildMenuItem(
                        18,
                        LucideIcons.coffee,
                        AppLocalizations.of(context)!.breaks,
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
                    if (_hasPermission('MANAGE_FINANCE') ||
                        _hasPermission('VIEW_FINANCIALS'))
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
              if (_hasPermission('MANAGE_SETTINGS') ||
                  _userRole == 'SUPER_ADMIN')
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
      builder: (ctx) =>
          UserProfileDialog(onProfileUpdated: () => _loadUserInfo()),
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
      } else if (_userRole == 'DRIVER_MANAGER') {
        translatedRole = Localizations.localeOf(context).languageCode == 'ar'
            ? 'مسؤول سائقين'
            : 'Driver Manager';
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
                      child: Text(
                        initials,
                        style: const TextStyle(fontSize: 12),
                      ),
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
                            child: Text(
                              initials,
                              style: const TextStyle(fontSize: 12),
                            ),
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

  /// Short searchable codes for every dashboard page ("abbreviations"),
  /// in both languages — typing ORD or طلب finds Orders either way.
  static const _pageCodesEn = <int, String>{
    0: 'DASH',
    1: 'ORD',
    2: 'VND',
    3: 'DRV',
    4: 'USR',
    5: 'TKT',
    6: 'INB',
    7: 'SET',
    8: 'ZON',
    9: 'BIZ',
    10: 'PRM',
    11: 'WAL',
    12: 'AUD',
    13: 'ANN',
    14: 'ACL',
    15: 'SHF',
    16: 'ANL',
    17: 'NTF',
    18: 'BRK',
    19: 'DVM',
  };

  static const _pageCodesAr = <int, String>{
    0: 'لوحة',
    1: 'طلب',
    2: 'متجر',
    3: 'سائق',
    4: 'مستخدم',
    5: 'تذكرة',
    6: 'وارد',
    7: 'إعدادات',
    8: 'منطقة',
    9: 'نشاط',
    10: 'عروض',
    11: 'محفظة',
    12: 'تدقيق',
    13: 'إعلان',
    14: 'صلاحيات',
    15: 'شفت',
    16: 'تحليلات',
    17: 'إشعار',
    18: 'استراحة',
    19: 'مدر',
  };

  static const _pageIcons = <int, IconData>{
    0: LucideIcons.layoutDashboard,
    1: LucideIcons.shoppingBag,
    2: LucideIcons.store,
    3: LucideIcons.truck,
    4: LucideIcons.userPlus,
    5: LucideIcons.helpCircle,
    6: LucideIcons.messageSquare,
    7: LucideIcons.settings,
    8: LucideIcons.map,
    9: LucideIcons.layers,
    10: LucideIcons.megaphone,
    11: LucideIcons.wallet,
    12: LucideIcons.shieldAlert,
    13: LucideIcons.radio,
    14: LucideIcons.shieldCheck,
    15: LucideIcons.calendarClock,
    16: LucideIcons.barChart3,
    17: LucideIcons.bell,
    18: LucideIcons.coffee,
    19: LucideIcons.userCheck,
  };

  /// Pages visible to the current user, mirroring the sidebar gates.
  List<int> _visiblePageIndices() {
    if (_userRole == 'VENDOR_MEMBER') {
      return [0, 1, 2, 5, 6, 17, 11];
    }
    if (_userRole == 'DRIVER_MANAGER') {
      return [3, 15, 18, 11, 6, 17];
    }
    final pages = <int>[];
    void add(int index, bool visible) {
      if (visible) pages.add(index);
    }

    add(0, _hasPermission('VIEW_STATISTICS'));
    add(1, _hasPermission('MANAGE_ORDERS'));
    add(16, _hasPermission('VIEW_STATISTICS'));
    add(2, _hasPermission('MANAGE_VENDORS'));
    add(9, _hasPermission('MANAGE_VENDORS'));
    add(3, _hasPermission('MANAGE_DRIVERS'));
    if (_userRole != 'DRIVER_MANAGER') {
      add(19, _hasPermission('MANAGE_DRIVERS') || _userRole == 'SUPER_ADMIN');
    }
    add(15, _hasPermission('MANAGE_DRIVERS'));
    add(18, _hasPermission('MANAGE_DRIVERS'));
    add(4, _hasPermission('MANAGE_USERS'));
    add(14, _hasPermission('MANAGE_USERS'));
    add(8, _hasPermission('MANAGE_SETTINGS'));
    add(10, _hasPermission('MANAGE_PROMOTIONS'));
    add(
      11,
      _hasPermission('MANAGE_FINANCE') || _hasPermission('VIEW_FINANCIALS'),
    );
    add(12, _hasPermission('VIEW_AUDIT_LOGS'));
    add(13, _hasPermission('MANAGE_ANNOUNCEMENTS'));
    add(5, _hasPermission('MANAGE_TICKETS'));
    add(6, _hasPermission('MANAGE_CONVERSATIONS'));
    add(17, true);
    add(7, _hasPermission('MANAGE_SETTINGS') || _userRole == 'SUPER_ADMIN');
    return pages;
  }

  void _showPageSearch() {
    final pages = _visiblePageIndices();
    showDialog(
      context: context,
      builder: (dialogCtx) => _PageSearchDialog(
        pages: pages,
        codesEn: _pageCodesEn,
        codesAr: _pageCodesAr,
        icons: _pageIcons,
        titleFor: (index) => _getMenuTitle(dialogCtx, index),
        onSelect: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildContent(bool isMobile, [int? index]) {
    final pageIndex = index ?? _selectedIndex;
    if (_userRole == 'DRIVER_MANAGER' &&
        ![3, 15, 18, 11, 6, 17].contains(pageIndex)) {
      return const DriversScreen();
    }
    switch (pageIndex) {
      case 0:
        return _buildDashboardContent(isMobile);
      case 1:
        return OrdersScreen(initialOrderId: _highlightOrderId);
      case 2:
        return VendorsScreen(
          userRole: _userRole,
          vendorRole: _vendorRole,
          permissions: _userPermissions,
        );
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
      case 18:
        return const DriverBreaksScreen();
      case 19:
        return const DriverManagersScreen(isEmbedded: true);
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
            const Icon(LucideIcons.construction, size: 64),
            const SizedBox(height: 16),
            Text(
              '${_getMenuTitle(context, _selectedIndex)} ${AppLocalizations.of(context)!.comingSoon}',
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(bool isMobile) {
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final bool isPhone = availableWidth < 600;
                final bool isDesktop = availableWidth >= 1050;

        // Dynamic responsive column count for stats cards
        final int statColumns = isPhone ? 2 : (availableWidth < 850 ? 3 : 4);
        final double spacing = isPhone ? 10.0 : 16.0;
        final double statCardWidth =
            (availableWidth - (statColumns - 1) * spacing) / statColumns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                // Core stats
                if (_hasPermission('MANAGE_VENDORS') ||
                    _userRole == 'VENDOR_MEMBER')
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
                        isMobile: isPhone,
                        width: statCardWidth,
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
                        isMobile: isPhone,
                        width: statCardWidth,
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
                        isMobile: isPhone,
                        width: statCardWidth,
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
                        isMobile: isPhone,
                        width: statCardWidth,
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
                          isMobile: isPhone,
                          width: statCardWidth,
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
                          isMobile: isPhone,
                          width: statCardWidth,
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
                          isMobile: isPhone,
                          width: statCardWidth,
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
                          isMobile: isPhone,
                          width: statCardWidth,
                          onTap: () => setState(() => _selectedIndex = 10),
                        );
                      },
                    ),
                ],
              ],
            ),
            if (_hasPermission('MANAGE_TICKETS') ||
                _hasPermission('MANAGE_SETTINGS') ||
                _hasPermission('MANAGE_VENDORS') ||
                _hasPermission('MANAGE_PROMOTIONS'))
              Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: InkWell(
                    onTap: () =>
                        setState(() => _isStatsExpanded = !_isStatsExpanded),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isStatsExpanded ? l10n.showLess : l10n.showMore,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _isStatsExpanded
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildRecentOrdersList(l10n, isPhone: false),
                  ),
                  if (_hasPermission('VIEW_AUDIT_LOGS')) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildRecentLogsList(l10n, isPhone: false),
                    ),
                  ],
                ],
              )
            else
              Column(
                children: [
                  _buildRecentOrdersList(l10n, isPhone: isPhone),
                  if (_hasPermission('VIEW_AUDIT_LOGS')) ...[
                    const SizedBox(height: 20),
                    _buildRecentLogsList(l10n, isPhone: isPhone),
                  ],
                ],
              ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _buildRecentOrdersList(AppLocalizations l10n, {required bool isPhone}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 16 : 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.shoppingBag,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.liveOrders,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.liveUpdates,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedIndex = 1),
                icon: Icon(
                  isArabic ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
                  size: 14,
                ),
                iconAlignment: IconAlignment.end,
                label: Text(
                  l10n.showMore,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(ordersProvider);
              return state.when(
                data: (data) {
                  if (data.orders.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          l10n.noOrdersFound,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
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
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = data.orders[index];
                      final status = (order['status'] ?? 'PENDING').toString();
                      final isCancelled =
                          status.contains('CANCEL') || status.contains('REJECT');
                      final areFeesFinalized = !isCancelled;

                      final subtotal =
                          double.tryParse(
                            order['subtotal']?.toString() ?? '0',
                          ) ??
                          0.0;
                      final grandTotal =
                          double.tryParse(
                            order['grandTotal']?.toString() ?? '0',
                          ) ??
                          0.0;
                      final displayTotal = areFeesFinalized
                          ? grandTotal
                          : subtotal;

                      Color statusColor;
                      String statusLabel;
                      switch (status) {
                        case 'PENDING':
                          statusColor = AppColors.warning;
                          statusLabel = isArabic ? 'جديد' : 'New';
                          break;
                        case 'ACCEPTED':
                          statusColor = AppColors.primary;
                          statusLabel = isArabic ? 'مقبول' : 'Accepted';
                          break;
                        case 'PREPARING':
                          statusColor = Colors.blue;
                          statusLabel = isArabic ? 'قيد التحضير' : 'Preparing';
                          break;
                        case 'READY_FOR_PICKUP':
                          statusColor = Colors.teal;
                          statusLabel = isArabic ? 'جاهز للاستلام' : 'Ready';
                          break;
                        case 'LOOKING_FOR_DRIVER':
                        case 'DRIVER_ASSIGNED':
                          statusColor = Colors.purple;
                          statusLabel = isArabic ? 'جاري التوصيل' : 'In Delivery';
                          break;
                        case 'DELIVERED':
                          statusColor = AppColors.success;
                          statusLabel = isArabic ? 'تم التوصيل' : 'Delivered';
                          break;
                        case 'CANCELLED':
                        case 'REJECTED':
                          statusColor = AppColors.error;
                          statusLabel = isArabic ? 'ملغي' : 'Cancelled';
                          break;
                        default:
                          statusColor = AppColors.primary;
                          statusLabel = status;
                      }

                      final vendorName = (order['vendor'] is Map
                              ? (isArabic
                                  ? (order['vendor']['storeNameAr'] ??
                                      order['vendor']['storeName'])
                                  : (order['vendor']['storeName'] ??
                                      order['vendor']['storeNameAr']))
                              : null) ??
                          l10n.unknownVendor;

                      final rawOrderNum = order['orderNumber']?.toString();
                      final rawId = order['id']?.toString() ?? '';
                      final orderCode =
                          (rawOrderNum != null && rawOrderNum.isNotEmpty)
                              ? rawOrderNum
                              : (rawId.length >= 8
                                  ? rawId.substring(0, 8).toUpperCase()
                                  : rawId);

                      String timeAgo = '';
                      if (order['createdAt'] != null) {
                        try {
                          final dt = DateTime.parse(
                            order['createdAt'].toString(),
                          ).toLocal();
                          final diff = DateTime.now().difference(dt);
                          if (diff.inMinutes < 60) {
                            timeAgo = isArabic
                                ? 'منذ ${diff.inMinutes} د'
                                : '${diff.inMinutes}m ago';
                          } else if (diff.inHours < 24) {
                            timeAgo = isArabic
                                ? 'منذ ${diff.inHours} س'
                                : '${diff.inHours}h ago';
                          } else {
                            timeAgo = DateFormat(
                              'd MMM',
                              isArabic ? 'ar' : 'en',
                            ).format(dt);
                          }
                        } catch (_) {}
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _highlightOrderId = rawId;
                              _selectedIndex = 1;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isPhone ? 10 : 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    LucideIcons.receipt,
                                    size: 18,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '#$orderCode',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.store,
                                            size: 12,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              vendorName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (timeAgo.isNotEmpty) ...[
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                  ),
                                              child: Text(
                                                '•',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              timeAgo,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${displayTotal.toStringAsFixed(2)} ${l10n.egp}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Icon(
                                      isArabic
                                          ? LucideIcons.chevronLeft
                                          : LucideIcons.chevronRight,
                                      size: 13,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.35),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.errorLoadingOrders,
                      style: const TextStyle(color: AppColors.error),
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

  Widget _buildRecentLogsList(AppLocalizations l10n, {required bool isPhone}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isPhone ? 16 : 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  size: 18,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.systemLogs,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.recentActivity,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _selectedIndex = 12),
                icon: Icon(
                  isArabic ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
                  size: 14,
                ),
                iconAlignment: IconAlignment.end,
                label: Text(
                  l10n.showMore,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(auditLogsProvider);
              return state.when(
                data: (data) {
                  if (data.logs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          l10n.noSystemLogsFound,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
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
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = data.logs[index];
                      final actionTypeRaw =
                          (log['actionType'] ?? 'OTHER').toString();
                      String actionType = actionTypeRaw.toUpperCase();
                      if (actionType == 'POST') actionType = 'CREATE';
                      if (actionType == 'PUT' || actionType == 'PATCH') {
                        actionType = 'UPDATE';
                      }
                      if (actionType == 'GET') actionType = 'READ';

                      Color iconColor;
                      IconData iconData;
                      String actionLabel;
                      switch (actionType) {
                        case 'CREATE':
                          iconColor = AppColors.success;
                          iconData = LucideIcons.plusCircle;
                          actionLabel = l10n.actionCreate;
                          break;
                        case 'UPDATE':
                          iconColor = AppColors.warning;
                          iconData = LucideIcons.edit;
                          actionLabel = l10n.actionUpdate;
                          break;
                        case 'DELETE':
                          iconColor = AppColors.error;
                          iconData = LucideIcons.trash2;
                          actionLabel = l10n.actionDelete;
                          break;
                        case 'LOGIN':
                          iconColor = AppColors.info;
                          iconData = LucideIcons.logIn;
                          actionLabel = l10n.actionLogin;
                          break;
                        case 'LOGOUT':
                          iconColor = Colors.grey;
                          iconData = LucideIcons.logOut;
                          actionLabel = l10n.actionLogout;
                          break;
                        default:
                          iconColor = AppColors.primary;
                          iconData = LucideIcons.activity;
                          actionLabel = actionType;
                      }

                      final rawEntity = (log['entityType'] ?? '').toString();
                      final prettified =
                          AuditLogsScreen.prettifyEntity(rawEntity);
                      final entityLabel = prettified.isNotEmpty
                          ? AuditLogsScreen.entityLabel(prettified, isArabic)
                          : '';

                      final actorName = AuditLogsScreen.userDisplayName(log);

                      final rawDate = (log['createdAt'] ?? '').toString();
                      String dateStr = rawDate;
                      try {
                        final date = DateTime.parse(rawDate).toLocal();
                        dateStr = DateFormat(
                          'd MMM, hh:mm a',
                          isArabic ? 'ar' : 'en',
                        ).format(date);
                      } catch (_) {}

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = 12),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isPhone ? 10 : 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    iconData,
                                    size: 18,
                                    color: iconColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: iconColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              actionLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: iconColor,
                                              ),
                                            ),
                                          ),
                                          if (entityLabel.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                entityLabel,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (actorName.isNotEmpty) ...[
                                            Icon(
                                              LucideIcons.user,
                                              size: 11,
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.5),
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                actorName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme.colorScheme.onSurface
                                                    .withValues(alpha: 0.7),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                  ),
                                              child: Text(
                                                '•',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: theme.colorScheme.onSurface
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                            ),
                                          ],
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isArabic
                                      ? LucideIcons.chevronLeft
                                      : LucideIcons.chevronRight,
                                  size: 13,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, st) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '${l10n.errorLoadingLogs}: ${ErrorUtils.translate(context, e)}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 10,
                      ),
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
          FocusManager.instance.primaryFocus?.unfocus();
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
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                        ),
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
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
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
                          color: isSelected
                              ? AppColors.primary
                              : unselectedColor,
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
    final double btnSize = isMobile ? 38.0 : 42.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: btnSize,
          height: btnSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Badge(
            isLabelVisible: badgeCount > 0,
            label: Text(
              '$badgeCount',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle({bool isMobile = false}) {
    final double btnSize = isMobile ? 38.0 : 42.0;
    return Consumer(
      builder: (context, ref, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              ref.read(themeProvider.notifier).toggleTheme();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: btnSize,
              height: btnSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                isDark ? LucideIcons.sun : LucideIcons.moon,
                size: 18,
                color: Colors.amber,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageToggle({bool isMobile = false}) {
    final double btnHeight = isMobile ? 38.0 : 42.0;
    return Consumer(
      builder: (context, ref, child) {
        final locale = ref.watch(localeProvider);
        final isArabic = locale.languageCode == 'ar';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              ref.read(localeProvider.notifier).toggleLanguage();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: btnHeight,
              constraints: BoxConstraints(minWidth: btnHeight),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isMobile) ...[
                    const Icon(
                      LucideIcons.languages,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    isArabic ? 'EN' : 'عربي',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
        if (_userRole == 'DRIVER_MANAGER') {
          return Localizations.localeOf(context).languageCode == 'ar'
              ? 'محفظة الإدارة'
              : 'Manager Wallet';
        }
        return l10n.walletAndFinancials;
      case 12:
        return l10n.auditLogs;
      case 13:
        return l10n.announcementsTitle;
      case 14:
        return Localizations.localeOf(context).languageCode == 'ar'
            ? 'التحكم في الصلاحيات'
            : 'Access Control';
      case 15:
        return l10n.driverShifts;
      case 16:
        return l10n.analytics;
      case 17:
        return l10n.notificationsTitle;
      case 18:
        return l10n.breaks;
      case 19:
        return Localizations.localeOf(context).languageCode == 'ar'
            ? 'مسؤولو السائقين'
            : 'Driver Managers';
      default:
        return l10n.dashboard;
    }
  }
}

/// Searchable quick-jump dialog over dashboard pages.
class _PageSearchDialog extends StatefulWidget {
  final List<int> pages;
  final Map<int, String> codesEn;
  final Map<int, String> codesAr;
  final Map<int, IconData> icons;
  final String Function(int index) titleFor;
  final ValueChanged<int> onSelect;

  const _PageSearchDialog({
    required this.pages,
    required this.codesEn,
    required this.codesAr,
    required this.icons,
    required this.titleFor,
    required this.onSelect,
  });

  @override
  State<_PageSearchDialog> createState() => _PageSearchDialogState();
}

class _PageSearchDialogState extends State<_PageSearchDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final query = _controller.text.trim().toLowerCase();
    final filtered = widget.pages.where((index) {
      if (query.isEmpty) return true;
      final title = widget.titleFor(index).toLowerCase();
      final codeEn = (widget.codesEn[index] ?? '').toLowerCase();
      final codeAr = widget.codesAr[index] ?? '';
      return title.contains(query) ||
          codeEn.contains(query) ||
          (query.isNotEmpty && codeAr.contains(_controller.text.trim()));
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchHint,
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(AppLocalizations.of(context)!.noPagesFound),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final index = filtered[i];
                        return ListTile(
                          leading: Icon(
                            widget.icons[index] ?? LucideIcons.circleDot,
                            color: AppColors.primary,
                          ),
                          title: Text(widget.titleFor(index)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAr
                                  ? (widget.codesAr[index] ?? '')
                                  : (widget.codesEn[index] ?? ''),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onSelect(index);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
