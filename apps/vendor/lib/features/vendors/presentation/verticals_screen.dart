import 'dart:io';
import 'package:flutter/material.dart';
import 'package:core/core.dart' show ImageUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/vendors/presentation/vertical_provider.dart';
import 'package:vendor/features/vendors/presentation/widgets/add_vertical_dialog.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';

class VerticalsScreen extends ConsumerStatefulWidget {
  const VerticalsScreen({super.key});

  @override
  ConsumerState<VerticalsScreen> createState() => _VerticalsScreenState();
}

class _VerticalsScreenState extends ConsumerState<VerticalsScreen> {
  int _currentPage = 0;
  final int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _extractVendors(dynamic vertical) {
    final raw = vertical is Map ? vertical['vendors'] : null;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int _extractVendorCount(dynamic vertical, List<Map<String, dynamic>> vendors) {
    if (vertical is Map) {
      final countMap = vertical['_count'];
      if (countMap is Map && countMap['vendors'] is num) {
        return (countMap['vendors'] as num).toInt();
      }
    }
    return vendors.length;
  }

  bool _vendorMatchesQuery(Map<String, dynamic> vendor, String queryLower) {
    if (queryLower.isEmpty) return true;
    final storeName = (vendor['storeName'] ?? vendor['name'] ?? '')
        .toString()
        .toLowerCase();
    final storeNameAr = (vendor['storeNameAr'] ?? vendor['nameAr'] ?? '')
        .toString()
        .toLowerCase();
    return storeName.contains(queryLower) || storeNameAr.contains(queryLower);
  }

  void _showVendorsModal(
    BuildContext context, {
    required String verticalId,
    required String verticalName,
    required List<Map<String, dynamic>> vendors,
    required int totalCount,
    required bool isAr,
    String initialQuery = '',
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _VerticalVendorsModal(
        verticalId: verticalId,
        verticalName: verticalName,
        vendors: vendors,
        totalCount: totalCount,
        isAr: isAr,
        initialQuery: initialQuery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<dynamic>>>(verticalProvider, (previous, state) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.businessTypes,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.manageVerticalsDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddVerticalDialog(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(AppLocalizations.of(context)!.addBusinessType),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Search Bar
        DashboardSearchBar(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _currentPage = 0; // Reset pagination on search
            });
          },
          onClear: () {
            setState(() {
              _searchQuery = '';
              _currentPage = 0;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildVerticalsTable(context),
      ],
    );
  }

  Widget _buildVerticalsTable(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(verticalProvider);
        if (state.isLoading && !state.hasValue) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.hasValue) {
          final searchLower = _searchQuery.trim().toLowerCase();
          final filteredVerticals = (state.value ?? []).where((v) {
            if (searchLower.isEmpty) return true;
            final name = (v['name'] ?? '').toString().toLowerCase();
            final nameAr = (v['nameAr'] ?? '').toString().toLowerCase();
            if (name.contains(searchLower) || nameAr.contains(searchLower)) {
              return true;
            }
            final vendors = _extractVendors(v);
            return vendors.any((vendor) => _vendorMatchesQuery(vendor, searchLower));
          }).toList();

          if (filteredVerticals.isEmpty) {
            return _buildEmptyState();
          }

          final totalItems = filteredVerticals.length;
          final totalPages = (totalItems / _pageSize).ceil();

          // Ensure current page is valid after deletions
          if (_currentPage >= totalPages && totalPages > 0) {
            _currentPage = totalPages - 1;
          }

          final startIndex = _currentPage * _pageSize;
          final endIndex = (startIndex + _pageSize) > totalItems
              ? totalItems
              : (startIndex + _pageSize);
          final pagedItems = filteredVerticals.sublist(startIndex, endIndex);

          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pagedItems.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.06),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final v = pagedItems[index];
                    return _buildVerticalRow(
                      context,
                      v,
                      isAr: isAr,
                      searchLower: searchLower,
                    );
                  },
                ),
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: 24),
                _buildPagination(totalPages),
              ],
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(40),
          child: Center(child: Text(AppLocalizations.of(context)!.noDataAvailable)),
        );
      },
    );
  }

  Widget _buildVerticalRow(
    BuildContext context,
    dynamic v, {
    required bool isAr,
    required String searchLower,
  }) {
    final theme = Theme.of(context);
    final verticalId = (v['id'] ?? '').toString();
    final vendors = _extractVendors(v);
    final vendorCount = _extractVendorCount(v, vendors);

    final nameEn = (v['name'] ?? '').toString().trim();
    final nameAr = (v['nameAr'] ?? '').toString().trim();
    final primaryName = isAr
        ? (nameAr.isNotEmpty ? nameAr : (nameEn.isNotEmpty ? nameEn : 'N/A'))
        : (nameEn.isNotEmpty ? nameEn : (nameAr.isNotEmpty ? nameAr : 'N/A'));
    final secondaryName = isAr
        ? (nameEn.isNotEmpty && nameEn != primaryName ? nameEn : '')
        : (nameAr.isNotEmpty && nameAr != primaryName ? nameAr : '');

    final nameMatchesSearch = searchLower.isNotEmpty &&
        (nameEn.toLowerCase().contains(searchLower) ||
            nameAr.toLowerCase().contains(searchLower));
    final matchedVendors = (searchLower.isNotEmpty && !nameMatchesSearch)
        ? vendors.where((vendor) => _vendorMatchesQuery(vendor, searchLower)).toList()
        : const <Map<String, dynamic>>[];

    final vendorCountLabel = isAr
        ? (vendorCount == 0
            ? 'لا توجد متاجر'
            : vendorCount == 1
                ? 'متجر واحد'
                : vendorCount == 2
                    ? 'متجران'
                    : '$vendorCount متاجر')
        : (vendorCount == 1 ? '1 Vendor' : '$vendorCount Vendors');

    void openVendorsModal({String initialQuery = ''}) {
      if (vendors.isEmpty) return;
      _showVendorsModal(
        context,
        verticalId: verticalId,
        verticalName: primaryName,
        vendors: vendors,
        totalCount: vendorCount,
        isAr: isAr,
        initialQuery: initialQuery,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: v['iconUrl'] != null &&
                        v['iconUrl'].toString().trim().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImage(v['iconUrl'].toString()),
                      )
                    : const Icon(
                        LucideIcons.layers,
                        color: AppColors.primary,
                        size: 18,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (secondaryName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        secondaryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionItem(
                    context: context,
                    icon: LucideIcons.edit3,
                    color: AppColors.primary,
                    label: AppLocalizations.of(context)!.edit,
                    onPressed: () => _showEditVerticalDialog(context, v),
                  ),
                  const SizedBox(width: 6),
                  _buildActionItem(
                    context: context,
                    icon: LucideIcons.trash2,
                    color: theme.colorScheme.error,
                    label: AppLocalizations.of(context)!.delete,
                    onPressed: () => _confirmDelete(context, v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildStatusBadge(v['isActive'] ?? true),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('vertical_vendors_toggle_$verticalId'),
                  onTap: vendors.isNotEmpty ? () => openVendorsModal() : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: (vendorCount > 0
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (vendorCount > 0
                                ? AppColors.primary
                                : theme.colorScheme.onSurfaceVariant)
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.store,
                          size: 12,
                          color: vendorCount > 0
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            vendorCountLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: vendorCount > 0
                                  ? AppColors.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        if (vendors.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          const AppAdaptiveChevron(
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (matchedVendors.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('vertical_search_match_$verticalId'),
                    onTap: () => openVendorsModal(initialQuery: _searchQuery.trim()),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.search,
                            size: 11.5,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isAr
                                  ? '${matchedVendors.length} نتيجة مطابقة'
                                  : '${matchedVendors.length} matching',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isSelected = _currentPage == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => setState(() => _currentPage = index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.textMuted).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive
            ? AppLocalizations.of(context)!.activeStatus
            : AppLocalizations.of(context)!.inactiveStatus,
        style: TextStyle(
          color: isActive ? AppColors.success : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            const Icon(
              LucideIcons.layers,
              size: 48,
              
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noBusinessTypesFound,
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

  void _showAddVerticalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddVerticalDialog(),
    ).then((result) async {
      if (result != null) {
        try {
          await ref.read(verticalProvider.notifier).createVertical(result);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.common_success_resource_created),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ErrorUtils.translate(context, e)),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    });
  }

  void _showEditVerticalDialog(BuildContext context, dynamic vertical) {
    showDialog(
      context: context,
      builder: (context) => AddVerticalDialog(vertical: vertical),
    ).then((result) async {
      if (result != null) {
        try {
          await ref.read(verticalProvider.notifier).updateVertical(vertical['id'], result);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.common_success_resource_updated),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ErrorUtils.translate(context, e)),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, dynamic vertical) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.deleteBusinessType,
      message: l10n.deleteBusinessTypeConfirm(
        vertical['name'] ?? l10n.unknown,
      ),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      ref.read(verticalProvider.notifier).deleteVertical(vertical['id']);
    }
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return const Icon(LucideIcons.layers, color: AppColors.primary, size: 16);
    }

    if (url.startsWith('file://') ||
        url.startsWith('/data/user/') ||
        url.startsWith('/storage/')) {
      final path = url.replaceFirst('file://', '');
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(LucideIcons.layers, color: AppColors.primary, size: 16),
      );
    }

    // Prepend base URL for relative media paths from the server
    final fullUrl = ImageUtils.formatImageUrl(url);

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(LucideIcons.layers, color: AppColors.primary, size: 16),
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
}

class _VerticalVendorsModal extends StatefulWidget {
  final String verticalId;
  final String verticalName;
  final List<Map<String, dynamic>> vendors;
  final int totalCount;
  final bool isAr;
  final String initialQuery;

  const _VerticalVendorsModal({
    required this.verticalId,
    required this.verticalName,
    required this.vendors,
    required this.totalCount,
    required this.isAr,
    this.initialQuery = '',
  });

  @override
  State<_VerticalVendorsModal> createState() => _VerticalVendorsModalState();
}

class _VerticalVendorsModalState extends State<_VerticalVendorsModal> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim();
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _localizedVendorName(Map<String, dynamic> vendor) {
    final nameEn = (vendor['storeName'] ?? vendor['name'] ?? '').toString().trim();
    final nameAr = (vendor['storeNameAr'] ?? vendor['nameAr'] ?? '').toString().trim();
    if (widget.isAr) {
      return nameAr.isNotEmpty ? nameAr : (nameEn.isNotEmpty ? nameEn : 'N/A');
    }
    return nameEn.isNotEmpty ? nameEn : (nameAr.isNotEmpty ? nameAr : 'N/A');
  }

  String _secondaryVendorName(Map<String, dynamic> vendor, String primary) {
    final nameEn = (vendor['storeName'] ?? vendor['name'] ?? '').toString().trim();
    final nameAr = (vendor['storeNameAr'] ?? vendor['nameAr'] ?? '').toString().trim();
    final other = widget.isAr ? nameEn : nameAr;
    return other.isNotEmpty && other != primary ? other : '';
  }

  Color _statusColor(String? rawStatus) {
    switch ((rawStatus ?? '').toUpperCase()) {
      case 'OPEN':
        return AppColors.success;
      case 'PAUSED':
        return AppColors.warning;
      case 'SUSPENDED':
        return AppColors.textMuted;
      default:
        return AppColors.error;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'OPEN':
        return widget.isAr ? 'مفتوح' : 'Open';
      case 'PAUSED':
        return widget.isAr ? 'متوقف مؤقتاً' : 'Paused';
      case 'SUSPENDED':
        return widget.isAr ? 'موقوف' : 'Suspended';
      default:
        return widget.isAr ? 'مغلق' : 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAr = widget.isAr;
    final queryLower = _query.trim().toLowerCase();
    final filtered = queryLower.isEmpty
        ? widget.vendors
        : widget.vendors.where((vendor) {
            final en = (vendor['storeName'] ?? vendor['name'] ?? '')
                .toString()
                .toLowerCase();
            final ar = (vendor['storeNameAr'] ?? vendor['nameAr'] ?? '')
                .toString()
                .toLowerCase();
            return en.contains(queryLower) || ar.contains(queryLower);
          }).toList();

    final showSearch = widget.vendors.length > 3 || _query.isNotEmpty;
    final maxListHeight =
        (MediaQuery.sizeOf(context).height * 0.52).clamp(220.0, 440.0);

    return AppDialog(
      key: ValueKey('vertical_vendors_modal_${widget.verticalId}'),
      maxWidth: 520,
      header: AppDialogHeader(
        icon: LucideIcons.store,
        title: widget.verticalName,
        subtitle: isAr
            ? 'المتاجر المضافة (${widget.totalCount})'
            : 'Assigned Vendors (${widget.totalCount})',
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSearch) ...[
            TextField(
              key: ValueKey('vertical_vendors_modal_search_${widget.verticalId}'),
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: isAr ? 'ابحث عن متجر...' : 'Search vendors...',
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 15),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppDialogStyles.subtleSurfaceColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppDialogStyles.borderColor(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppDialogStyles.borderColor(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.searchX,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.55,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isAr
                        ? 'لا توجد متاجر مطابقة للبحث'
                        : 'No matching vendors found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: Container(
                decoration: BoxDecoration(
                  color: AppDialogStyles.sectionCardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppDialogStyles.borderColor(context),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                  itemBuilder: (context, idx) {
                    final vendor = filtered[idx];
                    final primary = _localizedVendorName(vendor);
                    final secondary = _secondaryVendorName(vendor, primary);
                    final status = (vendor['status'] ?? 'CLOSED')
                        .toString()
                        .toUpperCase();
                    final statusColor = _statusColor(status);
                    final statusLabel = _statusLabel(status);
                    final isContracted = vendor['isContracted'] == true;
                    final countMap = vendor['_count'];
                    final branchCount =
                        countMap is Map && countMap['branches'] is num
                            ? (countMap['branches'] as num).toInt()
                            : null;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AppNetworkAvatar(
                                imageUrl: ImageUtils.resolveVendorLogoUrl(vendor),
                                size: 38,
                                borderRadius: 10,
                                fallbackIcon: LucideIcons.store,
                                fallbackIconSize: 18,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.10),
                                foregroundColor: AppColors.primary,
                                border: Border.all(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.08,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      primary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (secondary.isNotEmpty) ...[
                                      const SizedBox(height: 1),
                                      Text(
                                        secondary,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11.5,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      statusLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (branchCount != null || isContracted) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(start: 48),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (branchCount != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.mapPin,
                                          size: 11,
                                          color: theme.colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 3),
                                        Flexible(
                                          child: Text(
                                            isAr
                                                ? (branchCount == 1
                                                    ? 'فرع واحد'
                                                    : '$branchCount فروع')
                                                : (branchCount == 1
                                                    ? '1 branch'
                                                    : '$branchCount branches'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 11,
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (isContracted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        isAr ? 'شريك معتمد' : 'Contracted',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

