import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/widgets/stat_card.dart';
import 'package:vendor/features/vendors/presentation/vendor_provider.dart';
import 'package:vendor/features/vendors/presentation/widgets/add_vendor_dialog.dart';
import 'package:vendor/features/vendors/presentation/widgets/add_product_dialog.dart';
import 'package:vendor/features/vendors/presentation/menu_categories_screen.dart';
import 'package:vendor/features/vendors/presentation/branches_screen.dart';
import 'package:vendor/features/vendors/presentation/products_screen.dart';
import 'package:vendor/features/vendors/presentation/vendor_members_screen.dart';
import 'package:vendor/features/wallet/presentation/widgets/manual_transaction_dialog.dart';
import 'package:vendor/features/wallet/presentation/vendor_finance_statistics_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/core/providers.dart';
import '../../../l10n/l10n_error_helper.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  final String? userRole;
  final String? vendorRole;

  const VendorsScreen({super.key, this.userRole, this.vendorRole});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<VendorStateData>>(vendorProvider, (previous, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, state.error)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(vendorProvider);
                int total = state.value?.total ?? 0;
                int active = (state.value?.vendors ?? [])
                    .where((v) => v['status'] == 'OPEN')
                    .length;
                int pending = (state.value?.vendors ?? [])
                    .where(
                      (v) =>
                          v['status'] == 'PAUSED' || v['status'] == 'PENDING',
                    )
                    .length;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    StatCard(
                      title: AppLocalizations.of(context)!.vendors,
                      value: total.toString(),
                      icon: LucideIcons.store,
                      color: AppColors.primary,
                      isMobile: isMobile,
                    ),
                    StatCard(
                      title: AppLocalizations.of(context)!.active,
                      value: active.toString(),
                      icon: LucideIcons.checkCircle,
                      color: AppColors.success,
                      isMobile: isMobile,
                    ),
                    StatCard(
                      title: AppLocalizations.of(context)!.pending,
                      value: pending.toString(),
                      icon: LucideIcons.clock,
                      color: AppColors.warning,
                      isMobile: isMobile,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Search Bar
            DashboardSearchBar(
              controller: _searchController,
              onChanged: (value) {
                ref.read(vendorProvider.notifier).fetchVendors(search: value);
              },
              onClear: () {
                ref.read(vendorProvider.notifier).fetchVendors();
              },
            ),
            const SizedBox(height: 24),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.vendors,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.userRole != 'VENDOR_MEMBER')
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result =
                                await showDialog<Map<String, dynamic>>(
                                  context: context,
                                  builder: (context) => const AddVendorDialog(),
                                );
                            if (result != null && context.mounted) {
                              try {
                                await ref.read(vendorProvider.notifier).createVendor(result);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.common_success_resource_created), backgroundColor: AppColors.success));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10nErrorHelper.translate(context, e)), backgroundColor: AppColors.error));
                                }
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: Text(AppLocalizations.of(context)!.addVendor),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(vendorProvider);
                      if (state.isLoading && !state.hasValue) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (state.hasValue) {
                        return _buildVendorTable(
                          state.value!.vendors,
                          context,
                          isMobile,
                        );
                      } else if (state.hasError) {
                        return Center(
                          child: Text(
                            ErrorUtils.translate(context, state.error),
                            style: const TextStyle(color: AppColors.error),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildVendorTable(
    List<dynamic> vendors,
    BuildContext context,
    bool isMobile,
  ) {
    if (vendors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              const Icon(
                LucideIcons.store,
                size: 48,
                
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noVendorsFound,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vendors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 0),
      itemBuilder: (context, index) {
        final v = vendors[index];
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: isArabic ? TextDirection.ltr : TextDirection.rtl,
                children: [
                  _buildVendorThumbnail(v),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (v['isContracted'] == true) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFFE5A93B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.shieldCheck,
                                  size: 10,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isArabic
                                      ? 'شريك متعاقد'
                                      : 'Contracted Partner',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          isArabic
                              ? (v['storeNameAr']?.toString().isNotEmpty == true
                                        ? v['storeNameAr']
                                        : v['storeName']) ??
                                    AppLocalizations.of(context)!.unnamedStore
                              : v['storeName'] ??
                                    AppLocalizations.of(context)!.unnamedStore,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                        Text(
                          isArabic
                              ? (v['vertical']?['nameAr']
                                                ?.toString()
                                                .isNotEmpty ==
                                            true
                                        ? v['vertical']['nameAr']
                                        : v['vertical']?['name']) ??
                                    AppLocalizations.of(context)!.restaurant
                              : v['vertical']?['name'] ??
                                    AppLocalizations.of(context)!.restaurant,
                          style: TextStyle(
                            
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap:
                              (widget.userRole == 'VENDOR_MEMBER' &&
                                  widget.vendorRole == 'STAFF')
                              ? null
                              : () => _confirmStatusChange(context, v),
                          borderRadius: BorderRadius.circular(8),
                          child: _buildStatusChip(context, v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              const SizedBox(height: 16),
              _buildActions(context, v),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, dynamic v) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      children: [
        _buildActionItem(
          context: context,
          icon: LucideIcons.mapPin,
          color: AppColors.success,
          label: AppLocalizations.of(context)!.branches,
          onPressed: () => _viewBranches(context, v),
        ),
        _buildActionItem(
          context: context,
          icon: LucideIcons.list,
          color: AppColors.primary,
          label: AppLocalizations.of(context)!.menuCategories,
          onPressed: () => _viewMenuCategories(context, v),
        ),
        _buildActionItem(
          context: context,
          icon: LucideIcons.package,
          color: AppColors.primary,
          label: AppLocalizations.of(context)!.products,
          onPressed: () => _viewProducts(context, v),
        ),
        _buildActionItem(
          context: context,
          icon: LucideIcons.trendingUp,
          color: Colors.deepPurple,
          label: AppLocalizations.of(context)!.mostOrderedProduct,
          onPressed: () => _showMostOrderedProduct(context, v),
        ),
        _buildActionItem(
          context: context,
          icon: LucideIcons.chartNoAxesCombined,
          color: AppColors.info,
          label: Localizations.localeOf(context).languageCode == 'ar'
              ? 'إحصائيات المبيعات'
              : 'Statistics',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    VendorFinanceStatisticsScreen(vendorId: v['id']),
              ),
            );
          },
        ),

        if (widget.userRole != 'VENDOR_MEMBER' || widget.vendorRole == 'OWNER' || widget.vendorRole == 'MANAGER')
          _buildActionItem(
            context: context,
            icon: LucideIcons.users,
            color: AppColors.info,
            label: AppLocalizations.of(context)!.staffMembership,
            onPressed: () => _viewStaff(context, v),
          ),
        if (widget.userRole != 'VENDOR_MEMBER' ||
            (widget.vendorRole == 'OWNER' || widget.vendorRole == 'MANAGER'))
          _buildActionItem(
            context: context,
            icon: LucideIcons.edit3,
            color: Theme.of(
              context,
            ).colorScheme.onSurface,
            label: AppLocalizations.of(context)!.editVendor,
            onPressed: () => _showEditVendorDialog(context, v),
          ),
        if (widget.userRole != 'VENDOR_MEMBER' || widget.vendorRole == 'OWNER')
          _buildActionItem(
            context: context,
            icon: LucideIcons.trash2,
            color: AppColors.error,
            label: AppLocalizations.of(context)!.deleteVendor,
            onPressed: () => _confirmDelete(context, v),
          ),
        if (widget.userRole != 'VENDOR_MEMBER')
          _buildActionItem(
            context: context,
            icon: LucideIcons.wallet,
            color: Colors.green,
            label: AppLocalizations.of(context)!.adjustWallet,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) =>
                    ManualTransactionDialog(entityId: v['id'], isVendor: true),
              ).then((result) {
                if (result == true) {
                  ref.read(vendorProvider.notifier).fetchVendors();
                }
              });
            },
          ),
        _buildActionItem(
          context: context,
          icon: LucideIcons.phone,
          color: Colors.blue,
          label: AppLocalizations.of(context)!.call,
          onPressed: () => _callVendor(v),
        ),
      ],
    );
  }

  Widget _buildVendorThumbnail(dynamic v) {
    final imageUrl = ImageUtils.formatImageUrl(v['coverImage'] ?? v['image']);
    return Container(
      width: 100,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  LucideIcons.image,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            )
          : const Icon(LucideIcons.image, color: AppColors.primary, size: 30),
    );
  }

  void _callVendor(dynamic v) async {
    // Try to find a phone number in branches if not on vendor
    String? phone = v['phone'];
    if (phone == null &&
        v['branches'] != null &&
        (v['branches'] as List).isNotEmpty) {
      phone = v['branches'][0]['phone'];
    }

    if (phone != null && phone.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    }
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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getEffectiveStatus(dynamic v) {
    final globalStatus = v['status'] ?? 'CLOSED';
    if (globalStatus != 'OPEN') return globalStatus;

    var workingHours = v['workingHours'];
    if (workingHours is String) {
      try {
        workingHours = jsonDecode(workingHours);
      } catch (e) {
        workingHours = null;
      }
    }
    
    if (workingHours == null || workingHours is! List || workingHours.isEmpty) {
      return 'OPEN';
    }

    final now = DateTime.now();
    final currentDay = now.weekday == 7 ? 0 : now.weekday;
    final yesterdayDay = currentDay == 0 ? 6 : currentDay - 1;

    final scheduleForToday = (workingHours).firstWhere(
      (h) => h is Map && h['day'] == currentDay,
      orElse: () => null,
    );
    final scheduleForYesterday = (workingHours).firstWhere(
      (h) => h is Map && h['day'] == yesterdayDay,
      orElse: () => null,
    );

    bool isOpenNow = false;
    final currentMins = now.hour * 60 + now.minute;

    try {
      // 1. Check if we are in yesterday's overnight shift
      if (scheduleForYesterday != null && scheduleForYesterday['isClosed'] != true) {
        final openParts = (scheduleForYesterday['openTime'] as String).split(':');
        final closeParts = (scheduleForYesterday['closeTime'] as String).split(':');
        final openMins = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
        final closeMins = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

        if (closeMins < openMins) { // It's an overnight shift from yesterday
          if (currentMins <= closeMins) {
            isOpenNow = true;
          }
        }
      }

      // 2. Check if we are in today's shift
      if (!isOpenNow && scheduleForToday != null && scheduleForToday['isClosed'] != true) {
        final openParts = (scheduleForToday['openTime'] as String).split(':');
        final closeParts = (scheduleForToday['closeTime'] as String).split(':');
        final openMins = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
        final closeMins = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

        if (closeMins < openMins) { // Overnight shift starting today
          if (currentMins >= openMins) {
            isOpenNow = true;
          }
        } else { // Normal shift
          if (currentMins >= openMins && currentMins <= closeMins) {
            isOpenNow = true;
          }
        }
      }

      return isOpenNow ? 'OPEN' : 'CLOSED_HOURS';
    } catch (e) {
      return 'OPEN';
    }
  }

  Widget _buildStatusChip(BuildContext context, dynamic v) {
    Color color;
    final l10n = AppLocalizations.of(context)!;
    
    final effectiveStatus = _getEffectiveStatus(v);

    switch (effectiveStatus) {
      case 'OPEN':
        color = AppColors.success;
        break;
      case 'CLOSED':
      case 'CLOSED_HOURS':
        color = AppColors.error;
        break;
      case 'PAUSED':
        color = AppColors.warning;
        break;
      case 'SUSPENDED':
        color = AppColors.textMuted;
        break;
      default:
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        _translateStatus(context, effectiveStatus),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _translateStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    switch (status) {
      case 'OPEN':
        return l10n.open;
      case 'CLOSED':
        return l10n.closed;
      case 'CLOSED_HOURS':
        return isArabic ? 'مغلق (خارج أوقات العمل)' : 'CLOSED (OUT OF HOURS)';
      case 'PAUSED':
        return l10n.paused;
      case 'SUSPENDED':
        return l10n.suspended;
      default:
        return status;
    }
  }

  void _viewProducts(BuildContext context, dynamic v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsScreen(
          vendorId: v['id'] ?? '',
          vendorName: v['storeName'] ?? 'Vendor',
          vendorType: (v['vertical']?['slug'] ?? v['type'])?.toString(),
          isAdmin: widget.userRole != 'VENDOR_MEMBER',
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, dynamic v) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddProductDialog(
        vendorId: v['id'] ?? '',
        vendorName: v['storeName'] ?? 'Vendor',
        vendorType: (v['vertical']?['slug'] ?? v['type'])?.toString(),
      ),
    );
    if (result != null && context.mounted) {
      try {
        await ref.read(vendorProvider.notifier).createProduct(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.common_success_resource_created), backgroundColor: AppColors.success));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10nErrorHelper.translate(context, e)), backgroundColor: AppColors.error));
        }
      }
    }
  }

  void _showMostOrderedProduct(BuildContext context, dynamic v) async {
    final vendorId = v['id']?.toString();
    if (vendorId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FutureBuilder<dynamic>(
            future: ref.read(vendorStatisticsRepositoryProvider).getMostOrderedProduct(vendorId),
            builder: (context, snapshot) {
              final l10n = AppLocalizations.of(context)!;
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final data = snapshot.data;

              if (snapshot.hasError || data == null || (data is Map && data.isEmpty)) {
                return SizedBox(
                  height: 150,
                  child: Center(
                    child: Text(
                      l10n.noMostOrderedProduct,
                      style: const TextStyle( fontSize: 16),
                    ),
                  ),
                );
              }

              final name = data['productName'] ?? data['productNameAr'] ?? 'Unknown';
              final totalOrders = data['totalOrders']?.toString() ?? '0';
              final imageUrl = data['productImage'];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.mostOrderedProduct,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          image: imageUrl != null 
                              ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: imageUrl == null 
                            ? const Icon(LucideIcons.package,  size: 32) 
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$totalOrders ${l10n.ordersCount}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _viewProducts(context, v);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l10n.products),
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }


  void _showEditVendorDialog(BuildContext context, dynamic v) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          AddVendorDialog(vendor: v, userRole: widget.userRole),
    );
    if (result != null && context.mounted) {
      try {
        await ref.read(vendorProvider.notifier).updateVendor(v['id'], result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.common_success_resource_updated), backgroundColor: AppColors.success));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10nErrorHelper.translate(context, e)), backgroundColor: AppColors.error));
        }
      }
    }
  }

  void _viewStaff(BuildContext context, dynamic v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorMembersScreen(
          vendorId: v['id'].toString(),
          vendorName: v['storeName'] ?? v['name'] ?? AppLocalizations.of(context)!.staff,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic v) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppLocalizations.of(context)!.deleteConfirmTitle),
        content: Text(
          AppLocalizations.of(
            context,
          )!.deleteConfirmContent(v['storeName'] ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(vendorProvider.notifier).deleteVendor(v['id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.common_success_resource_deleted), backgroundColor: AppColors.success));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10nErrorHelper.translate(context, e)), backgroundColor: AppColors.error));
                }
              }
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStatusChange(BuildContext context, dynamic v) {
    final currentStatus = v['status'] ?? 'CLOSED';
    final List<String> statuses = ['OPEN', 'CLOSED', 'PAUSED', 'SUSPENDED'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppLocalizations.of(context)!.changeStatusTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isSelected = status == currentStatus;
            return ListTile(
              title: Text(_translateStatus(context, status)),
              trailing: isSelected
                  ? const Icon(LucideIcons.check, color: AppColors.success)
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (!isSelected) {
                  ref
                      .read(vendorProvider.notifier)
                      .updateVendorStatus(v['id'], status);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _viewMenuCategories(BuildContext context, dynamic v) {
    Navigator.push(
      context,
        MaterialPageRoute(
          builder: (context) => MenuCategoriesScreen(
            vendorId: v['id'] ?? '',
            vendorName: v['storeName'] ?? 'Vendor',
            isAdmin: widget.userRole != 'VENDOR_MEMBER',
          ),
        ),
    );
  }

  void _viewBranches(BuildContext context, dynamic v) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BranchesScreen(
          vendorId: v['id'] ?? '',
          vendorName: v['storeName'] ?? 'Vendor',
        ),
      ),
    );
  }
}

