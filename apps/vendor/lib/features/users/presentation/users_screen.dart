import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/widgets/stat_card.dart';
import 'package:vendor/features/users/presentation/user_provider.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:vendor/features/chat/presentation/pages/admin_chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:data/data.dart';
import 'user_form_dialog.dart';
import '../../../l10n/l10n_error_helper.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String? _currentUserId;
  String? _currentUserRole;
  List<dynamic> _vendors = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;

  String _getPermissionName(BuildContext context, String perm) {
    final l10n = AppLocalizations.of(context)!;
    switch (perm) {
      case 'MANAGE_ORDERS': return l10n.perm_manage_orders;
      case 'MANAGE_PRODUCTS': return l10n.perm_manage_products;
      case 'MANAGE_VENDORS': return l10n.perm_manage_vendors;
      case 'MANAGE_DRIVERS': return l10n.perm_manage_drivers;
      case 'MANAGE_CUSTOMERS': return l10n.perm_manage_customers;
      case 'MANAGE_TICKETS': return l10n.perm_manage_tickets;
      case 'MANAGE_CONVERSATIONS': return l10n.perm_manage_conversations;
      case 'VIEW_STATISTICS': return l10n.perm_view_statistics;
      case 'MANAGE_SETTINGS': return l10n.perm_manage_settings;
      case 'MANAGE_USERS': return l10n.perm_manage_users;
      case 'VIEW_FINANCIALS': return l10n.perm_view_financials;
      case 'MANAGE_FINANCE': return l10n.perm_manage_finance;
      case 'MANAGE_PROMOTIONS': return l10n.perm_manage_promotions;
      case 'MANAGE_ANNOUNCEMENTS': return l10n.perm_manage_announcements;
      case 'VIEW_AUDIT_LOGS': return l10n.perm_view_audit_logs;
      default: return perm;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final id = await ref.read(sharedAuthRepositoryProvider).getUserId();
    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    final vendorsResult = await ref
        .read(adminVendorsRepositoryProvider)
        .getVendors();
    if (mounted) {
      setState(() {
        _currentUserId = id;
        _currentUserRole = role;
        final data = vendorsResult is Map && vendorsResult.containsKey('data') ? vendorsResult['data'] : vendorsResult;
        _vendors = data is Map ? (data['vendors'] ?? data['items'] ?? []) : (data is List ? data : []);
        if (role == 'ADMIN') {
          _selectedRole = 'DRIVER';
        }
      });
    }
  }

  void _openChat(dynamic user) async {
    final chatRepo = ref.read(sharedChatRepositoryProvider);
    final conversation = await chatRepo.createDirectConversation(user['id']);
    if (conversation != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminChatScreen(
            conversationId: conversation['id'],
            title: user['name'] ?? 'Chat',
            avatar: user['avatar'],
            vendorId: conversation['vendorId'],
            vendorName: conversation['vendor']?['storeName'],
            type: conversation['type']?.toString() ?? 'DIRECT',
          ),
        ),
      );
    }
  }

  Future<void> _callUser(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'رقم الهاتف غير متاح' : 'Phone number not available',
          ),
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تعذر بدء الاتصال' : 'Could not start the call',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UsersStateData>>(userProvider, (previous, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorUtils.translate(context, state.error),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real-time Stats Header
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(userProvider);
                int totalUsers = 0;
                int totalAdmins = 0;
                int bannedUsers = 0;

                if (state.hasValue) {
                  totalUsers = state.value!.total;
                  totalAdmins = state.value!.users
                      .where((u) => u['role'].toString().contains('ADMIN'))
                      .length;
                  bannedUsers = state.value!.users
                      .where((u) => u['isBanned'] == true)
                      .length;
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(
                      title: AppLocalizations.of(context)!.totalUsers,
                      value: totalUsers.toString(),
                      icon: LucideIcons.users,
                      color: AppColors.primary,
                      isMobile: isMobile,
                    ),
                    StatCard(
                      title: AppLocalizations.of(context)!.platformAdmins,
                      value: totalAdmins.toString(),
                      icon: LucideIcons.shieldCheck,
                      color: AppColors.accent,
                      isMobile: isMobile,
                    ),
                    StatCard(
                      title: AppLocalizations.of(context)!.activeAccounts,
                      value: (totalUsers - bannedUsers).toString(),
                      icon: LucideIcons.checkCircle,
                      color: AppColors.success,
                      isMobile: isMobile,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Management Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.platformUsers,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: () => _showUserFormDialog(context),
                        icon: const Icon(LucideIcons.userPlus, size: 14),
                        label: Text(AppLocalizations.of(context)!.addUser),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(110, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  DashboardSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      ref
                          .read(userProvider.notifier)
                          .fetchUsers(search: value, role: _selectedRole);
                    },
                    onClear: () {
                      ref
                          .read(userProvider.notifier)
                          .fetchUsers(role: _selectedRole);
                    },
                  ),
                  if (_currentUserRole != 'ADMIN') ...[
                    const SizedBox(height: 16),
                    // Role Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: AppLocalizations.of(context)!.all,
                            isSelected: _selectedRole == null,
                            onSelected: (selected) {
                              setState(() => _selectedRole = null);
                              ref
                                  .read(userProvider.notifier)
                                  .fetchUsers(search: _searchController.text);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: AppLocalizations.of(context)!.superAdmin,
                            isSelected: _selectedRole == 'SUPER_ADMIN',
                            onSelected: (selected) {
                              setState(
                                () => _selectedRole = selected
                                    ? 'SUPER_ADMIN'
                                    : null,
                              );
                              ref
                                  .read(userProvider.notifier)
                                  .fetchUsers(
                                    search: _searchController.text,
                                    role: _selectedRole,
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: AppLocalizations.of(context)!.admin,
                            isSelected: _selectedRole == 'ADMIN',
                            onSelected: (selected) {
                              setState(
                                () => _selectedRole = selected ? 'ADMIN' : null,
                              );
                              ref
                                  .read(userProvider.notifier)
                                  .fetchUsers(
                                    search: _searchController.text,
                                    role: _selectedRole,
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: AppLocalizations.of(context)!.vendorMember,
                            isSelected: _selectedRole == 'VENDOR_MEMBER',
                            onSelected: (selected) {
                              setState(
                                () => _selectedRole = selected
                                    ? 'VENDOR_MEMBER'
                                    : null,
                              );
                              ref
                                  .read(userProvider.notifier)
                                  .fetchUsers(
                                    search: _searchController.text,
                                    role: _selectedRole,
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: AppLocalizations.of(context)!.driver,
                            isSelected: _selectedRole == 'DRIVER',
                            onSelected: (selected) {
                              setState(
                                () =>
                                    _selectedRole = selected ? 'DRIVER' : null,
                              );
                              ref
                                  .read(userProvider.notifier)
                                  .fetchUsers(
                                    search: _searchController.text,
                                    role: _selectedRole,
                                  );
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: AppLocalizations.of(context)!.customer,
                            isSelected: _selectedRole == 'CUSTOMER',
                            onSelected: (selected) {
                              setState(
                                () => _selectedRole = selected
                                    ? 'CUSTOMER'
                                    : null,
                              );
                              ref
                                  .read(userProvider.notifier)
                                  .fetchUsers(
                                    search: _searchController.text,
                                    role: _selectedRole,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(userProvider);
                      if (state.isLoading && !state.hasValue) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(60.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (state.hasValue) {
                        return Column(
                          children: [
                            if (constraints.maxWidth < 900)
                              _buildUserList(state.value!.users, context)
                            else
                              _buildUserTable(state.value!.users, context),
                            const SizedBox(height: 24),
                            _buildPagination(state.value!),
                          ],
                        );
                      } else if (state.hasError) {
                        return Center(
                          child: Text(
                            state.error.toString(),
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPagination(UsersStateData state) {
    int totalPages = (state.total / state.limit).ceil();
    if (totalPages <= 1) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: state.page > 1
              ? () => ref
                    .read(userProvider.notifier)
                    .fetchUsers(
                      page: state.page - 1,
                      limit: state.limit,
                      search: _searchController.text,
                      role: _selectedRole,
                    )
              : null,
        ),
        const SizedBox(width: 16),
        Text(
          AppLocalizations.of(context)!.pageXofY(state.page, totalPages),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(LucideIcons.chevronRight),
          onPressed: state.page < totalPages
              ? () => ref
                    .read(userProvider.notifier)
                    .fetchUsers(
                      page: state.page + 1,
                      limit: state.limit,
                      search: _searchController.text,
                      role: _selectedRole,
                    )
              : null,
        ),
      ],
    );
  }

  Widget _buildUserList(List<dynamic> users, BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(AppLocalizations.of(context)!.noUsersFound),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = users[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildUserAvatar(u, 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u['name'] ?? AppLocalizations.of(context)!.unknown,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          u['email'] ?? AppLocalizations.of(context)!.noEmail,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context, u['isBanned'] == true),
                ],
              ),
              Divider(
                height: 24,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.phone,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        u['phone'] ?? '-',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.role,
                        style: const TextStyle(
                          
                          fontSize: 10,
                        ),
                      ),
                      _buildRoleChip(u['role'] ?? 'CUSTOMER'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionItem(
                        context: context,
                        icon: u['isBanned'] == true
                            ? LucideIcons.unlock
                            : LucideIcons.ban,
                        color: u['isBanned'] == true
                            ? AppColors.success
                            : AppColors.warning,
                        label: u['isBanned'] == true
                            ? AppLocalizations.of(context)!.unban
                            : AppLocalizations.of(context)!.ban,
                        onPressed: () => _handleBanToggle(context, u),
                      ),
                      if ((u['phone']?.toString().isNotEmpty ?? false)) ...[
                        const SizedBox(width: 8),
                        _buildActionItem(
                          context: context,
                          icon: LucideIcons.phoneCall,
                          color: AppColors.success,
                          label: Localizations.localeOf(context)
                                      .languageCode ==
                                  'ar'
                              ? 'اتصال'
                              : 'Call',
                          onPressed: () => _callUser(
                            context,
                            u['phone'].toString(),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _buildActionItem(
                        context: context,
                        icon: LucideIcons.messageCircle,
                        color: AppColors.primary,
                        label:
                            Localizations.localeOf(context).languageCode == 'ar'
                            ? 'دردشة'
                            : 'Chat',
                        onPressed: () => _openChat(u),
                      ),
                      const SizedBox(width: 8),
                      _buildActionItem(
                        context: context,
                        icon: LucideIcons.edit3,
                        color: AppColors.info,
                        label: AppLocalizations.of(context)!.edit,
                        onPressed: () => _showUserFormDialog(context, user: u),
                      ),
                      const SizedBox(width: 8),
                      _buildActionItem(
                        context: context,
                        icon: LucideIcons.trash2,
                        color: AppColors.error,
                        label: AppLocalizations.of(context)!.delete,
                        onPressed: () => _showDeleteConfirmation(context, u),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTable(List<dynamic> users, BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Text(AppLocalizations.of(context)!.noUsersFoundSystem),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        horizontalMargin: 0,
        columnSpacing: 12,
        headingRowHeight: 48,
        columns: [
          DataColumn(label: Text(AppLocalizations.of(context)!.name)),
          DataColumn(label: Text(AppLocalizations.of(context)!.emailAddress)),
          DataColumn(label: Text(AppLocalizations.of(context)!.phone)),
          DataColumn(label: Text(AppLocalizations.of(context)!.role)),
          DataColumn(label: Text(AppLocalizations.of(context)!.active)),
          DataColumn(label: Text(AppLocalizations.of(context)!.actions)),
        ],
        rows: users
            .map(
              (u) => DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildUserAvatar(u, 14),
                        const SizedBox(width: 12),
                        Text(
                          u['name'] ?? AppLocalizations.of(context)!.unknown,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      u['email'] ?? AppLocalizations.of(context)!.noEmail,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      u['phone'] ?? '-',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  DataCell(_buildRoleChip(u['role'] ?? 'CUSTOMER')),
                  DataCell(_buildStatusChip(context, u['isBanned'] == true)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionItem(
                          context: context,
                          icon: u['isBanned'] == true
                              ? LucideIcons.unlock
                              : LucideIcons.ban,
                          color: u['isBanned'] == true
                              ? AppColors.success
                              : AppColors.warning,
                          label: u['isBanned'] == true
                              ? AppLocalizations.of(context)!.unban
                              : AppLocalizations.of(context)!.ban,
                          onPressed: () => _handleBanToggle(context, u),
                        ),
                        if ((u['phone']?.toString().isNotEmpty ?? false)) ...[
                          const SizedBox(width: 8),
                          _buildActionItem(
                            context: context,
                            icon: LucideIcons.phoneCall,
                            color: AppColors.success,
                            label: Localizations.localeOf(context)
                                        .languageCode ==
                                    'ar'
                                ? 'اتصال'
                                : 'Call',
                            onPressed: () => _callUser(
                              context,
                              u['phone'].toString(),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _buildActionItem(
                          context: context,
                          icon: LucideIcons.messageCircle,
                          color: AppColors.primary,
                          label:
                              Localizations.localeOf(context).languageCode ==
                                  'ar'
                              ? 'دردشة'
                              : 'Chat',
                          onPressed: () => _openChat(u),
                        ),
                        const SizedBox(width: 8),
                        _buildActionItem(
                          context: context,
                          icon: LucideIcons.edit3,
                          color: AppColors.info,
                          label: AppLocalizations.of(context)!.edit,
                          onPressed: () =>
                              _showUserFormDialog(context, user: u),
                        ),
                        const SizedBox(width: 8),
                        _buildActionItem(
                          context: context,
                          icon: LucideIcons.trash2,
                          color: AppColors.error,
                          label: AppLocalizations.of(context)!.delete,
                          onPressed: () => _showDeleteConfirmation(context, u),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color = role.contains('ADMIN') ? AppColors.accent : AppColors.primary;
    String displayRole = role;
    if (role == 'ADMIN') {
      displayRole = AppLocalizations.of(context)!.admin;
    } else if (role == 'SUPER_ADMIN') {
      displayRole = AppLocalizations.of(context)!.superAdmin;
    } else if (role == 'VENDOR_MEMBER') {
      displayRole = AppLocalizations.of(context)!.vendorMember;
    } else if (role == 'DRIVER') {
      displayRole = AppLocalizations.of(context)!.driver;
    } else if (role == 'CUSTOMER') {
      displayRole = AppLocalizations.of(context)!.customer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayRole,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool isBanned) {
    Color color = isBanned ? AppColors.error : AppColors.success;
    String label = isBanned
        ? AppLocalizations.of(context)!.bannedStatus
        : AppLocalizations.of(context)!.activeStatus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showUserFormDialog(BuildContext context, {dynamic user}) {
    showDialog(
      context: context,
      builder: (_) => UserFormDialog(
        user: user,
        currentUserRole: _currentUserRole,
        vendors: _vendors,
      ),
    );
  }

  void _handleBanToggle(BuildContext context, dynamic user) {
    if (user['id'] == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cannotBanSelf),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (user['isBanned'] == true) {
      ref.read(userProvider.notifier).unbanUser(user['id']);
    } else {
      _showBanReasonDialog(context, user['id']);
    }
  }

  void _showBanReasonDialog(BuildContext context, String userId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppLocalizations.of(context)!.banUser),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.banUserConfirm),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.reasonOptional,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(userProvider.notifier)
                    .banUser(userId, reason: reasonController.text);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(AppLocalizations.of(dialogContext)!.common_success_operation), backgroundColor: AppColors.success));
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(L10nErrorHelper.translate(dialogContext, e)), backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text(AppLocalizations.of(context)!.banUser),
          ),
        ],
      ),
    );
  }

  /// Avatar image with initial-letter fallback. Backend stores a relative
  /// path, so it must be resolved to an absolute URL first.
  Widget _buildUserAvatar(dynamic u, double radius) {
    final raw = u is Map ? u['avatar']?.toString() ?? '' : '';
    final url = ImageUtils.formatImageUrl(raw.isEmpty ? null : raw);
    final name = u is Map ? (u['name']?.toString() ?? '') : '';
    final initial = name.isEmpty ? 'U' : name[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage:
          url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
      onBackgroundImageError:
          url.isNotEmpty ? (_, __) {} : null,
      child: url.isEmpty
          ? Text(
              initial,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: radius * 0.75,
              ),
            )
          : null,
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic user) {
    if (user['id'] == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cannotDeleteSelf),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppLocalizations.of(context)!.deleteUser),
        content: Text(
          AppLocalizations.of(context)!.deleteUserConfirm(user['name'] ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(userProvider.notifier).deleteUser(user['id']);
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(AppLocalizations.of(dialogContext)!.common_success_resource_deleted), backgroundColor: AppColors.success));
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(L10nErrorHelper.translate(dialogContext, e)), backgroundColor: AppColors.error));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? AppColors.primary
            : Theme.of(context).colorScheme.onSurface,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

