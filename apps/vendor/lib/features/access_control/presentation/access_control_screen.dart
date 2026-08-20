import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'access_control_provider.dart';
import '../../../l10n/l10n_error_helper.dart';

class AccessControlScreen extends ConsumerStatefulWidget {
  const AccessControlScreen({super.key});

  @override
  ConsumerState<AccessControlScreen> createState() => _AccessControlScreenState();
}

class _AccessControlScreenState extends ConsumerState<AccessControlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> allPermissions = [
    'MANAGE_ORDERS',
    'MANAGE_PRODUCTS',
    'MANAGE_VENDORS',
    'MANAGE_DRIVERS',
    'MANAGE_CUSTOMERS',
    'MANAGE_TICKETS',
    'MANAGE_CONVERSATIONS',
    'VIEW_STATISTICS',
    'MANAGE_SETTINGS',
    'MANAGE_USERS',
    'VIEW_FINANCIALS',
    'MANAGE_FINANCE',
    'MANAGE_PROMOTIONS',
    'MANAGE_ANNOUNCEMENTS',
    'VIEW_AUDIT_LOGS'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accessControlProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isMobile 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.shieldCheck,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                isAr ? 'التحكم في الصلاحيات' : 'Access Control',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isAr 
                            ? 'إدارة صلاحيات النظام وعرض مصفوفة الوصول للمديرين'
                            : 'Manage system permissions and view the access matrix for administrators.',
                          style: const TextStyle(
                            
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ref.read(accessControlProvider.notifier).fetchAdministrativeUsers();
                            },
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: Text(l10n.refresh),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.shieldCheck,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'التحكم في الصلاحيات' : 'Access Control',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr 
                                  ? 'إدارة صلاحيات النظام وعرض مصفوفة الوصول للمديرين'
                                  : 'Manage system permissions and view the access matrix for administrators.',
                                style: const TextStyle(
                                  
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(accessControlProvider.notifier).fetchAdministrativeUsers();
                          },
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: Text(l10n.refresh),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                tabs: [
                  Tab(text: isAr ? 'مصفوفة الصلاحيات' : 'Permissions Matrix'),
                  Tab(text: isAr ? 'نظام الأدوار' : 'Role Topology'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPermissionsMatrix(state, isAr, isMobile),
              _buildRoleTopology(isAr, isMobile),
            ],
          ),
        ),
      ],
    );
  }

  String _translatePermission(BuildContext context, String perm) {
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
      default: return perm.replaceAll('_', ' ');
    }
  }

  Widget _buildPermissionsMatrix(AsyncValue<AccessControlStateData> state, bool isAr, bool isMobile) {
    return state.when(
      data: (data) {
        final allAdmins = [...data.superAdminUsers, ...data.adminUsers];
        if (allAdmins.isEmpty) {
          return Center(child: Text(isAr ? 'لا يوجد مديرين' : 'No administrators found.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: allAdmins.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final user = allAdmins[index];
            final isSuperAdmin = user['role'] == 'SUPER_ADMIN';
            final userPerms = (user['permissions'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final hasValidAvatar = user['avatar'] != null && 
                                   user['avatar'].toString().isNotEmpty && 
                                   user['avatar'].toString().startsWith('http');

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: hasValidAvatar ? NetworkImage(user['avatar']) : null,
                        child: !hasValidAvatar
                            ? Text(
                                (user['name'] ?? '?').toString().isNotEmpty ? (user['name'] ?? '?')[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(user['email'] ?? '', style: const TextStyle( fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        if (!isMobile) const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSuperAdmin 
                              ? AppColors.error.withValues(alpha: 0.1) 
                              : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user['role'] == 'SUPER_ADMIN' 
                                ? (isAr ? 'مدير عام' : 'Super Admin')
                                : (user['role'] == 'ADMIN' ? (isAr ? 'مدير' : 'Admin') : user['role']),
                            style: TextStyle(
                              color: isSuperAdmin ? AppColors.error : AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isAr ? 'الصلاحيات:' : 'Permissions:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  if (isSuperAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.checkCheck, color: AppColors.success, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'يمتلك كافة الصلاحيات بشكل كامل' : 'Has Full Unrestricted Access',
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else if (userPerms.isEmpty)
                    Text(
                      isAr ? 'لا يوجد صلاحيات معينة' : 'No permissions assigned',
                      style: const TextStyle( fontStyle: FontStyle.italic),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: userPerms.map((perm) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.check, color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                _translatePermission(context, perm),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text(L10nErrorHelper.translate(context, e.toString()))),
    );
  }

  Widget _buildRoleTopology(bool isAr, bool isMobile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRoleCard(
            title: 'SUPER_ADMIN',
            icon: LucideIcons.shieldAlert,
            color: AppColors.error,
            description: isAr 
              ? 'يمتلك وصولاً كاملاً وغير مقيد لجميع أجزاء النظام. يتجاوز جميع شروط الصلاحيات تلقائياً.'
              : 'Has complete, unrestricted access to all parts of the system. Bypasses all permission checks automatically.',
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            title: 'ADMIN',
            icon: LucideIcons.shield,
            color: AppColors.warning,
            description: isAr 
              ? 'وصول مقيد مبني على الصلاحيات. يجب تعيين كل صلاحية (مثل MANAGE_VENDORS) بشكل فردي لهذا الدور.'
              : 'Restricted, permission-based access. Every specific permission (e.g., MANAGE_VENDORS) must be explicitly assigned to this role.',
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            title: 'VENDOR_MEMBER',
            icon: LucideIcons.store,
            color: AppColors.info,
            description: isAr 
              ? 'وصول معزول ومحصور بنطاق التاجر. لا يمتلك أي صلاحيات إدارية عامة. تتحدد صلاحياته داخل التاجر بناءً على دوره (OWNER, MANAGER, STAFF).'
              : 'Isolated, vendor-scoped access. Does not possess any global administrative permissions. Access inside the vendor is governed by their specific VendorMemberRole (OWNER, MANAGER, STAFF).',
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
