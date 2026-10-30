import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:core/core.dart';
import 'package:vendor/features/vendors/presentation/vendor_provider.dart';
import 'package:vendor/features/vendors/presentation/widgets/add_vendor_dialog.dart';
import 'package:vendor/features/vendors/presentation/menu_categories_screen.dart';
import 'package:vendor/features/vendors/presentation/branches_screen.dart';
import 'package:vendor/features/vendors/presentation/products_screen.dart';
import 'package:vendor/features/vendors/presentation/vendor_members_screen.dart';
import 'package:vendor/features/wallet/presentation/widgets/manual_transaction_dialog.dart';
import 'package:vendor/features/wallet/presentation/vendor_finance_statistics_screen.dart';
import 'package:vendor/features/wallet/presentation/admin_vendor_wallet_screen.dart';
import 'package:vendor/features/wallet/presentation/vendor_product_sales_screen.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/core/providers.dart';
import '../../../l10n/l10n_error_helper.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  final String? userRole;
  final String? vendorRole;
  final List<String> permissions;

  const VendorsScreen({
    super.key,
    this.userRole,
    this.vendorRole,
    this.permissions = const [],
  });

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _hasPermission(String permission) =>
      widget.userRole == 'SUPER_ADMIN' ||
      widget.permissions.contains(permission);

  bool get _canViewWallet =>
      _hasPermission('VIEW_FINANCIALS') || _hasPermission('MANAGE_FINANCE');

  bool get _canManageFinance => _hasPermission('MANAGE_FINANCE');

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
        final double width = constraints.maxWidth;
        final bool isMobile = width < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. Statistics Section (3 Adaptive Cards: Total, Active, Pending)
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(vendorProvider);
                final int total = state.value?.total ?? 0;
                final int active = (state.value?.vendors ?? [])
                    .where((v) => v['status'] == 'OPEN')
                    .length;
                final int pending = (state.value?.vendors ?? [])
                    .where(
                      (v) =>
                          v['status'] == 'PAUSED' || v['status'] == 'PENDING',
                    )
                    .length;

                return _buildStatisticsSection(
                  context: context,
                  width: width,
                  total: total,
                  active: active,
                  pending: pending,
                );
              },
            ),

            const SizedBox(height: 20),

            // B. Search and Add Merchant Toolbar
            _buildToolbar(context: context, width: width),

            const SizedBox(height: 20),

            // C. Merchant List Content
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(vendorProvider);
                if (state.isLoading && !state.hasValue) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (state.hasValue) {
                  return _buildVendorList(
                    state.value!.vendors,
                    context,
                    isMobile,
                  );
                } else if (state.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            size: 40,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            ErrorUtils.translate(context, state.error),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => ref.read(vendorProvider.notifier).fetchVendors(),
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: Text(AppLocalizations.of(context)!.retry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // 1. STATISTICS SECTION (Fully Responsive)
  // ==========================================
  Widget _buildStatisticsSection({
    required BuildContext context,
    required double width,
    required int total,
    required int active,
    required int pending,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final bool isCompact = width < 540;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context: context,
            title: l10n.vendors,
            value: total.toString(),
            icon: LucideIcons.store,
            color: AppColors.primary,
            isCompact: isCompact,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context: context,
            title: l10n.active,
            value: active.toString(),
            icon: LucideIcons.checkCircle2,
            color: const Color(0xFF10B981),
            isCompact: isCompact,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            context: context,
            title: l10n.pending,
            value: pending.toString(),
            icon: LucideIcons.clock,
            color: const Color(0xFFF59E0B),
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isCompact,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 14,
        vertical: isCompact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.14),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.05 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: isCompact
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ==========================================
  // 2. SEARCH & ADD MERCHANT TOOLBAR
  // ==========================================
  Widget _buildToolbar({
    required BuildContext context,
    required double width,
  }) {
    final bool canAdd = widget.userRole != 'VENDOR_MEMBER';
    final bool stackButtons = width < 420;

    final searchField = _buildSearchInput(context);
    final addButton = canAdd ? _buildAddMerchantButton(context) : null;

    if (stackButtons && addButton != null) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: addButton,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: searchField),
        if (addButton != null) ...[
          const SizedBox(width: 12),
          addButton,
        ],
      ],
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref.read(vendorProvider.notifier).fetchVendors(search: value);
          setState(() {});
        },
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          hintText: AppLocalizations.of(context)!.search,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(vendorProvider.notifier).fetchVendors();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAddMerchantButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _openAddVendorDialog(context),
      icon: const Icon(LucideIcons.plus, size: 18),
      label: Text(
        AppLocalizations.of(context)!.addVendor,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13.5,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _openAddVendorDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddVendorDialog(),
    );
    if (result != null && context.mounted) {
      try {
        await ref.read(vendorProvider.notifier).createVendor(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.common_success_resource_created,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10nErrorHelper.translate(context, e)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // ==========================================
  // 3. MERCHANT LIST & CARDS
  // ==========================================
  Widget _buildVendorList(
    List<dynamic> vendors,
    BuildContext context,
    bool isMobile,
  ) {
    if (vendors.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.store,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noVendorsFound,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchController.text.isNotEmpty
                    ? '${AppLocalizations.of(context)!.search}: "${_searchController.text}"'
                    : '',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final v = vendors[index];
        return _buildVendorCard(context, v, isMobile);
      },
    );
  }

  Widget _buildVendorCard(BuildContext context, dynamic v, bool isMobile) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String vendorName = isArabic
        ? (v['storeNameAr']?.toString().isNotEmpty == true
            ? v['storeNameAr']
            : v['storeName']) ?? AppLocalizations.of(context)!.unnamedStore
        : v['storeName'] ?? AppLocalizations.of(context)!.unnamedStore;

    final String categoryName = isArabic
        ? (v['vertical']?['nameAr']?.toString().isNotEmpty == true
            ? v['vertical']['nameAr']
            : v['vertical']?['name']) ?? AppLocalizations.of(context)!.restaurant
        : v['vertical']?['name'] ?? AppLocalizations.of(context)!.restaurant;

    final int branchCount = (v['branches'] is List) ? (v['branches'] as List).length : 0;
    final bool isContracted = v['isContracted'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Natural directional header (RTL in Arabic, LTR in English)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Logo Container (Square, non-stretched, consistent)
              _buildVendorThumbnail(context, v),
              const SizedBox(width: 14),

              // 2. Info area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contracted Partner Badge (if applicable)
                    if (isContracted) ...[
                      _buildContractedBadge(context, isArabic),
                      const SizedBox(height: 5),
                    ],

                    // Store Name
                    Text(
                      vendorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Category & Branches Meta Row
                    Row(
                      children: [
                        Icon(
                          LucideIcons.tag,
                          size: 12,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (branchCount > 0) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          Icon(
                            LucideIcons.mapPin,
                            size: 11,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$branchCount ${isArabic ? 'فروع' : 'branches'}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Status Chip (Clickable for status change)
                    InkWell(
                      onTap: (widget.userRole == 'VENDOR_MEMBER' &&
                              widget.vendorRole == 'STAFF')
                          ? null
                          : () => _confirmStatusChange(context, v),
                      borderRadius: BorderRadius.circular(20),
                      child: _buildStatusChip(context, v),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: theme.dividerColor.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 14),

          // 3. Actions Grid (4 columns on mobile, 6 on tablet/desktop)
          _buildActionsGrid(context, v, isArabic),
        ],
      ),
    );
  }

  Widget _buildVendorThumbnail(BuildContext context, dynamic v) {
    final theme = Theme.of(context);
    final imageUrl = ImageUtils.formatImageUrl(v['coverImage'] ?? v['image'] ?? v['logo']);

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: imageUrl.isNotEmpty && imageUrl.startsWith('http')
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    LucideIcons.store,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    size: 26,
                  ),
                ),
              )
            : Center(
                child: Icon(
                  LucideIcons.store,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  size: 26,
                ),
              ),
      ),
    );
  }

  Widget _buildContractedBadge(BuildContext context, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF78350F).withValues(alpha: 0.45)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.shieldCheck,
            size: 11,
            color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 4),
          Text(
            isArabic ? 'شريك متعاقد' : 'Contracted Partner',
            style: TextStyle(
              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. ACTION GRID (Equal Columns & Semantic Colors)
  // ==========================================
  Widget _buildActionsGrid(BuildContext context, dynamic v, bool isArabic) {
    final actions = _getActionsForVendor(context, v, isArabic);

    return LayoutBuilder(
      builder: (context, constraints) {
        // 4 columns on phones, 6 columns on tablet/desktop
        final int crossAxisCount = constraints.maxWidth >= 600 ? 6 : 4;
        const double spacing = 8.0;
        final double totalGaps = spacing * (crossAxisCount - 1);
        final double itemWidth = (constraints.maxWidth - totalGaps) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: 12.0,
          children: actions.map((action) {
            return SizedBox(
              width: itemWidth,
              child: _buildActionTile(context, action),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionTile(BuildContext context, _VendorActionConfig action) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: action.color.withValues(alpha: isDark ? 0.28 : 0.16),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  action.icon,
                  size: 20,
                  color: action.color,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28, // Guarantees identical baseline across all rows
                child: Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_VendorActionConfig> _getActionsForVendor(
    BuildContext context,
    dynamic v,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return [
      // 1. Branches (Green)
      _VendorActionConfig(
        icon: LucideIcons.mapPin,
        color: const Color(0xFF10B981),
        label: l10n.branches,
        onPressed: () => _viewBranches(context, v),
      ),
      // 2. Menu Categories (Orange)
      _VendorActionConfig(
        icon: LucideIcons.layers,
        color: const Color(0xFFF97316),
        label: l10n.menuCategories,
        onPressed: () => _viewMenuCategories(context, v),
      ),
      // 3. Products (Amber)
      _VendorActionConfig(
        icon: LucideIcons.package,
        color: const Color(0xFFF59E0B),
        label: l10n.products,
        onPressed: () => _viewProducts(context, v),
      ),
      // 4. Most Ordered Product (Violet / Purple)
      _VendorActionConfig(
        icon: LucideIcons.trendingUp,
        color: const Color(0xFF8B5CF6),
        label: l10n.mostOrderedProduct,
        onPressed: () => _showMostOrderedProduct(context, v),
      ),
      // 5. Statistics (Blue)
      _VendorActionConfig(
        icon: LucideIcons.barChart3,
        color: const Color(0xFF3B82F6),
        label: isArabic ? 'إحصائيات' : 'Statistics',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VendorFinanceStatisticsScreen(vendorId: v['id']),
            ),
          );
        },
      ),
      // 6. Products Sold (Teal)
      _VendorActionConfig(
        icon: LucideIcons.shoppingBag,
        color: const Color(0xFF14B8A6),
        label: isArabic ? 'المنتجات المباعة' : 'Products Sold',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VendorProductSalesScreen(
                vendorId: v['id'],
                vendorName: v['storeName'],
              ),
            ),
          );
        },
      ),
      // 7. Employees / Staff (Cyan)
      if (widget.userRole != 'VENDOR_MEMBER' ||
          widget.vendorRole == 'OWNER' ||
          widget.vendorRole == 'MANAGER')
        _VendorActionConfig(
          icon: LucideIcons.users,
          color: const Color(0xFF06B6D4),
          label: l10n.staffMembership,
          onPressed: () => _viewStaff(context, v),
        ),
      // 8. Edit Merchant (Slate Neutral)
      if (widget.userRole != 'VENDOR_MEMBER' ||
          widget.vendorRole == 'OWNER' ||
          widget.vendorRole == 'MANAGER')
        _VendorActionConfig(
          icon: LucideIcons.pencil,
          color: const Color(0xFF64748B),
          label: l10n.editVendor,
          onPressed: () => _showEditVendorDialog(context, v),
        ),
      // 9. View Wallet (Emerald)
      if (widget.userRole != 'VENDOR_MEMBER' && _canViewWallet)
        _VendorActionConfig(
          icon: LucideIcons.wallet,
          color: const Color(0xFF059669),
          label: isArabic ? 'عرض المحفظة' : 'View Wallet',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AdminVendorWalletScreen(
                  vendorId: v['id'],
                  vendorName: v['storeName'],
                ),
              ),
            );
          },
        ),
      // 10. Adjust Wallet (Indigo / Mint - distinctive from View Wallet!)
      if (widget.userRole != 'VENDOR_MEMBER' && _canManageFinance)
        _VendorActionConfig(
          icon: LucideIcons.coins,
          color: const Color(0xFF6366F1),
          label: l10n.adjustWallet,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => ManualTransactionDialog(
                entityId: v['id'],
                isVendor: true,
              ),
            ).then((result) {
              if (result == true) {
                ref.read(vendorProvider.notifier).fetchVendors();
              }
            });
          },
        ),
      // 11. Contact / Call (Sky Blue)
      _VendorActionConfig(
        icon: LucideIcons.phoneCall,
        color: const Color(0xFF0284C7),
        label: l10n.call,
        onPressed: () => _callVendor(v),
      ),
      // 12. Delete Merchant (Rose Red)
      if (widget.userRole != 'VENDOR_MEMBER' || widget.vendorRole == 'OWNER')
        _VendorActionConfig(
          icon: LucideIcons.trash2,
          color: const Color(0xFFEF4444),
          label: l10n.deleteVendor,
          onPressed: () => _confirmDelete(context, v),
        ),
    ];
  }

  // ==========================================
  // 5. STATUS & WORKING HOURS CALCULATION
  // ==========================================
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

        if (closeMins < openMins) {
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

        if (closeMins < openMins) {
          if (currentMins >= openMins) {
            isOpenNow = true;
          }
        } else {
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
    final effectiveStatus = _getEffectiveStatus(v);

    switch (effectiveStatus) {
      case 'OPEN':
        color = const Color(0xFF10B981);
        break;
      case 'CLOSED':
      case 'CLOSED_HOURS':
        color = const Color(0xFFEF4444);
        break;
      case 'PAUSED':
        color = const Color(0xFFF59E0B);
        break;
      case 'SUSPENDED':
        color = const Color(0xFF64748B);
        break;
      default:
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _translateStatus(context, effectiveStatus),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
        return isArabic ? 'مغلق (خارج الدوام)' : 'CLOSED (OFF-HOURS)';
      case 'PAUSED':
        return l10n.paused;
      case 'SUSPENDED':
        return l10n.suspended;
      default:
        return status;
    }
  }

  // ==========================================
  // 6. ACTION HANDLERS & MODALS
  // ==========================================
  void _callVendor(dynamic v) async {
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

  void _showMostOrderedProduct(BuildContext context, dynamic v) async {
    final vendorId = v['id']?.toString();
    if (vendorId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FutureBuilder<dynamic>(
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
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                image: imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(imageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: imageUrl == null
                                  ? const Icon(LucideIcons.package, size: 28)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$totalOrders ${l10n.ordersCount}',
                                      style: const TextStyle(
                                        color: Color(0xFF8B5CF6),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _viewProducts(context, v);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l10n.products,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.common_success_resource_updated,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10nErrorHelper.translate(context, e)),
              backgroundColor: AppColors.error,
            ),
          );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          AppLocalizations.of(context)!.deleteConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteConfirmContent(v['storeName'] ?? ''),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(vendorProvider.notifier).deleteVendor(v['id']);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.common_success_resource_deleted,
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(L10nErrorHelper.translate(context, e)),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(AppLocalizations.of(context)!.delete),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          AppLocalizations.of(context)!.changeStatusTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isSelected = status == currentStatus;
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                _translateStatus(context, status),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              trailing: isSelected
                  ? const Icon(LucideIcons.check, color: AppColors.success)
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (!isSelected) {
                  ref.read(vendorProvider.notifier).updateVendorStatus(v['id'], status);
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

class _VendorActionConfig {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onPressed;

  const _VendorActionConfig({
    required this.icon,
    required this.color,
    required this.label,
    required this.onPressed,
  });
}
