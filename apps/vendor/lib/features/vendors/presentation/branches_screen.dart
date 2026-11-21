import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:vendor/core/widgets/location_picker_map.dart';
import 'package:data/data.dart';
import 'package:vendor/features/zones/presentation/zone_provider.dart';
import 'package:latlong2/latlong.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;
  final String? userRole;

  const BranchesScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.userRole,
  });

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  List<dynamic> _branches = [];
  List<dynamic> _filteredBranches = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchBranches();
    Future.microtask(() => ref.read(zoneProvider.notifier).fetchZones());
  }

  Future<void> _fetchBranches() async {
    setState(() => _isLoading = true);
    final branches = await ref
        .read(adminVendorsRepositoryProvider)
        .getBranches(widget.vendorId);
    if (mounted) {
      setState(() {
        _branches = branches;
        _filteredBranches = branches;
        _isLoading = false;
      });
    }
  }

  void _filterBranches(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBranches = _branches;
      } else {
        _filteredBranches = _branches.where((branch) {
          final name = (branch['name'] ?? '').toString().toLowerCase();
          final nameAr = (branch['nameAr'] ?? '').toString().toLowerCase();
          final address = (branch['address'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) ||
              nameAr.contains(searchLower) ||
              address.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? LucideIcons.arrowRight
                            : LucideIcons.arrowLeft,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.storeBranches,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 20,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            widget.vendorName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddBranchDialog(),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(AppLocalizations.of(context)!.addBranch),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Search Bar
                DashboardSearchBar(
                  controller: _searchController,
                  onChanged: _filterBranches,
                  onClear: () => _filterBranches(''),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredBranches.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          itemCount: _filteredBranches.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final branch = _filteredBranches[index];
                            return _buildBranchCard(branch);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.05),
              ),
            ),
            child: const Icon(LucideIcons.mapPin, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noBranchesFound,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.noBranchesDescription,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContractBadge(dynamic branch) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final dynamic branchContracted = branch['isContracted'];
    Widget contractWidget;
    if (branchContracted == true) {
      contractWidget = Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isAr ? 'شريك معتمد' : 'Contracted',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (branchContracted == false) {
      contractWidget = Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isAr ? 'غير متعاقد' : 'Uncontracted',
          style: const TextStyle(
            color: AppColors.warning,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      contractWidget = Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isAr ? 'يتبع المتجر' : 'Inherits Vendor',
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      );
    }

    final bool isOpen = branch['isOpen'] as bool? ?? true;
    final Widget openBadge = Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isOpen ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isOpen ? (isAr ? 'مفتوح' : 'Open') : (isAr ? 'مغلق' : 'Closed'),
        style: TextStyle(
          color: isOpen ? AppColors.success : AppColors.error,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final dynamic commRate = branch['commissionRate'];
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        openBadge,
        contractWidget,
        if (commRate != null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isAr ? 'عمولة: $commRate٪' : 'Commission: $commRate%',
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBranchCard(dynamic branch) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.mapPin,
            color: AppColors.success,
            size: 20,
          ),
        ),
        title: Text(
          branch['name'] ?? AppLocalizations.of(context)!.unnamedBranch,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContractBadge(branch),
            const SizedBox(height: 4),
            Text(
              branch['address'] ??
                  AppLocalizations.of(context)!.noAddressProvided,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
            if ((branch['phone'] ?? branch['phoneNumber'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(LucideIcons.phone, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      (branch['phone'] ?? branch['phoneNumber'] ?? '').toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionItem(
              context: context,
              icon: LucideIcons.edit3,
              color: Theme.of(context).colorScheme.onSurface,
              label: AppLocalizations.of(context)!.edit,
              onPressed: () => _showAddBranchDialog(branch: branch),
            ),
            const SizedBox(width: 8),
            _buildActionItem(
              context: context,
              icon: LucideIcons.trash2,
              color: AppColors.error,
              label: AppLocalizations.of(context)!.delete,
              onPressed: () => _confirmDelete(branch),
            ),
          ],
        ),
      ),
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
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String? _findMatchingZoneId(LatLng point, List<dynamic> zones) {
    for (final z in zones) {
      final id = z['id']?.toString();
      var boundaryData = z['boundary'] ?? z['coordinates'];
      if (boundaryData is Map && boundaryData['coordinates'] != null) {
        boundaryData = boundaryData['coordinates'];
      }
      if (boundaryData is List && boundaryData.isNotEmpty) {
        final ring = boundaryData.first;
        if (ring is List) {
          final points = <LatLng>[];
          for (final pt in ring) {
            if (pt is List && pt.length >= 2) {
              final lng = double.tryParse(pt[0].toString());
              final lat = double.tryParse(pt[1].toString());
              if (lat != null && lng != null) {
                points.add(LatLng(lat, lng));
              }
            }
          }
          if (points.length >= 3) {
            bool inside = false;
            final n = points.length;
            for (int i = 0, j = n - 1; i < n; j = i++) {
              final xi = points[i].latitude, yi = points[i].longitude;
              final xj = points[j].latitude, yj = points[j].longitude;
              final intersect =
                  ((yi > point.longitude) != (yj > point.longitude)) &&
                  (point.latitude <
                      (xj - xi) * (point.longitude - yi) / (yj - yi) + xi);
              if (intersect) inside = !inside;
            }
            if (inside && id != null) return id;
          }
        }
      }
    }
    return null;
  }

  void _showAddBranchDialog({dynamic branch}) async {
    final isEdit = branch != null;
    final canEditCommission = widget.userRole == 'SUPER_ADMIN';
    final nameController = TextEditingController(text: branch?['name'] ?? '');
    final nameArController = TextEditingController(
      text: branch?['nameAr'] ?? '',
    );
    final addressController = TextEditingController(
      text: branch?['address'] ?? '',
    );
    final phoneController = TextEditingController(
      text: (branch?['phone'] ?? branch?['phoneNumber'] ?? '').toString(),
    );
    final commissionController = TextEditingController(
      text: branch?['commissionRate']?.toString() ?? '',
    );
    double? selectedLat = branch?['lat'] != null
        ? double.tryParse(branch['lat'].toString())
        : null;
    double? selectedLng = branch?['lng'] != null
        ? double.tryParse(branch['lng'].toString())
        : null;
    if (selectedLat == null || selectedLng == null) {
      final loc = branch?['location'];
      final coords = (loc is Map && loc['coordinates'] is List)
          ? (loc['coordinates'] as List)
          : (loc is List ? loc : null);
      if (coords != null && coords.length >= 2) {
        selectedLng ??= double.tryParse(coords[0].toString());
        selectedLat ??= double.tryParse(coords[1].toString());
      }
    }
    String? selectedZoneId = branch?['zoneId'] ?? branch?['zone']?['id'];
    String? errorMessage;
    bool? isContracted = branch?['isContracted'] as bool?;
    bool isOpen = branch?['isOpen'] as bool? ?? true;

    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final l10n = AppLocalizations.of(ctx)!;
          final isAr = Localizations.localeOf(ctx).languageCode == 'ar';
          final theme = Theme.of(ctx);

          return AppDialog(
            maxWidth: 520,
            canPop: !isSubmitting,
            header: AppDialogHeader(
              icon: isEdit ? LucideIcons.edit3 : LucideIcons.mapPin,
              title: isEdit ? l10n.editBranch : l10n.newBranch,
              subtitle: widget.vendorName,
              isCloseDisabled: isSubmitting,
              onClose: () => Navigator.pop(dialogCtx),
            ),
            body: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFieldLabel(
                  label: l10n.branchName,
                  isRequired: true,
                  languageTag: 'EN',
                  languageTagColor: AppColors.info,
                ),
                TextField(
                  controller: nameController,
                  enabled: !isSubmitting,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: AppDialogStyles.inputDecoration(
                    ctx,
                    hintText: 'e.g. Downtown Branch',
                    icon: LucideIcons.type,
                  ),
                ),
                const SizedBox(height: 16),
                AppFieldLabel(
                  label: l10n.branchNameAr,
                  languageTag: 'عربي',
                  languageTagColor: AppColors.success,
                ),
                TextField(
                  controller: nameArController,
                  enabled: !isSubmitting,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: AppDialogStyles.inputDecoration(
                    ctx,
                    hintText: 'اسم الفرع',
                    icon: LucideIcons.languages,
                  ),
                ),
                const SizedBox(height: 16),
                AppFieldLabel(label: l10n.address),
                TextField(
                  controller: addressController,
                  enabled: !isSubmitting,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: AppDialogStyles.inputDecoration(
                    ctx,
                    hintText: 'Full address',
                    icon: LucideIcons.mapPin,
                  ),
                ),
                const SizedBox(height: 16),
                AppFieldLabel(
                  label: l10n.pickLocation,
                  isRequired: !isEdit,
                ),
                AppDialogSectionCard(
                  padding: EdgeInsets.zero,
                  borderColor: selectedLat != null
                      ? AppColors.success.withValues(alpha: 0.35)
                      : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (selectedLat != null
                                ? AppColors.success
                                : AppColors.primary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.map,
                        size: 18,
                        color: selectedLat != null
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                    title: Text(
                      selectedLat != null
                          ? l10n.locationSelected
                          : l10n.pickLocation,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: selectedLat != null
                        ? Text(
                            '${selectedLat!.toStringAsFixed(4)}, ${selectedLng!.toStringAsFixed(4)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          )
                        : null,
                    trailing: Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: isSubmitting
                        ? null
                        : () async {
                            final zones =
                                ref.read(zoneProvider).asData?.value.zones ??
                                    [];
                            final picked = await Navigator.push<LatLng>(
                              ctx,
                              MaterialPageRoute(
                                builder: (context) => LocationPickerMap(
                                  initialLocation:
                                      selectedLat != null && selectedLng != null
                                          ? LatLng(selectedLat!, selectedLng!)
                                          : null,
                                  zones: zones,
                                ),
                              ),
                            );
                            if (picked != null && dialogCtx.mounted) {
                              setDialogState(() {
                                selectedLat = picked.latitude;
                                selectedLng = picked.longitude;
                                final matchedZone =
                                    _findMatchingZoneId(picked, zones);
                                if (matchedZone != null) {
                                  selectedZoneId = matchedZone;
                                }
                              });
                            }
                          },
                  ),
                ),
                const SizedBox(height: 16),
                AppFieldLabel(label: l10n.zones),
                Consumer(
                  builder: (context, ref, child) {
                    final zoneState = ref.watch(zoneProvider);
                    return zoneState.when(
                      data: (data) {
                        final isValidZone = selectedZoneId == null ||
                            data.zones.any(
                              (z) => z['id']?.toString() == selectedZoneId,
                            );
                        final currentZoneValue =
                            isValidZone ? selectedZoneId : null;

                        return DropdownButtonFormField<String?>(
                          key: ValueKey(currentZoneValue),
                          initialValue: currentZoneValue,
                          dropdownColor: AppDialogStyles.dropdownColor(ctx),
                          isExpanded: true,
                          decoration: AppDialogStyles.inputDecoration(
                            ctx,
                            icon: LucideIcons.map,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.autoDetectZone),
                            ),
                            ...data.zones.map((z) {
                              return DropdownMenuItem<String?>(
                                value: z['id']?.toString(),
                                child: Text(z['name']?.toString() ?? ''),
                              );
                            }),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (val) {
                                  setDialogState(() {
                                    selectedZoneId = val;
                                  });
                                },
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (err, stack) => Text(
                        ErrorUtils.translate(ctx, err),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                AppFieldLabel(label: l10n.phone),
                TextField(
                  controller: phoneController,
                  enabled: !isSubmitting,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: AppDialogStyles.inputDecoration(
                    ctx,
                    hintText: '+123...',
                    icon: LucideIcons.phone,
                  ),
                ),
                const SizedBox(height: 16),
                AppDialogSectionCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: SwitchListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      isAr
                          ? 'حالة الفرع (مفتوح للطلبات)'
                          : 'Branch Open for Orders',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      isOpen
                          ? (isAr ? 'مفتوح حالياً' : 'Currently Open')
                          : (isAr ? 'مغلق حالياً' : 'Currently Closed'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOpen ? AppColors.success : AppColors.error,
                      ),
                    ),
                    value: isOpen,
                    activeThumbColor: AppColors.success,
                    onChanged: isSubmitting
                        ? null
                        : (val) {
                            setDialogState(() {
                              isOpen = val;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 16),
                AppDialogSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.handshake,
                            size: 17,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'حالة التعاقد للفرع'
                                  : 'Branch Contract Status',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'إذا لم يتم التحديد، سيتبع الفرع حالة المتجر الرئيسية تلقائياً'
                            : 'If unset, branch inherits the vendor contract status',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<bool?>(
                        initialValue: isContracted,
                        dropdownColor: AppDialogStyles.dropdownColor(ctx),
                        isExpanded: true,
                        decoration: AppDialogStyles.inputDecoration(
                          ctx,
                          hintText: isAr
                              ? 'اختر حالة التعاقد'
                              : 'Select contract status',
                        ),
                        items: [
                          DropdownMenuItem<bool?>(
                            value: null,
                            child: Text(
                              isAr
                                  ? 'افتراضي المتجر (توريث)'
                                  : 'Inherit vendor status',
                            ),
                          ),
                          DropdownMenuItem<bool?>(
                            value: true,
                            child: Text(isAr ? 'شريك معتمد' : 'Contracted'),
                          ),
                          DropdownMenuItem<bool?>(
                            value: false,
                            child: Text(isAr ? 'غير متعاقد' : 'Uncontracted'),
                          ),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (val) {
                                setDialogState(() {
                                  isContracted = val;
                                });
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppFieldLabel(
                  label: isAr
                      ? 'نسبة العمولة الخاصة بالفرع (٪) (اختياري)'
                      : 'Branch Commission Rate (%) (Optional)',
                ),
                TextField(
                  controller: commissionController,
                  keyboardType: TextInputType.number,
                  enabled: canEditCommission && !isSubmitting,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: AppDialogStyles.inputDecoration(
                    ctx,
                    hintText: isAr
                        ? 'اتركه فارغاً ليتبع نسبة المتجر'
                        : 'Leave empty to inherit vendor rate',
                    icon: LucideIcons.percent,
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  AppDialogErrorBanner(message: errorMessage!),
                ],
              ],
            ),
            footer: AppDialogFooter(
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.pop(dialogCtx),
              confirmLabel: isEdit ? l10n.update : l10n.create,
              confirmIcon: isEdit ? LucideIcons.save : LucideIcons.plus,
              isLoading: isSubmitting,
              onConfirm: () async {
                if (nameController.text.trim().isEmpty) {
                  setDialogState(() {
                    errorMessage = l10n.requiredField;
                  });
                  return;
                }
                if (!isEdit &&
                    (selectedLat == null || selectedLng == null)) {
                  setDialogState(() {
                    errorMessage = l10n.pickLocation;
                  });
                  return;
                }

                setDialogState(() {
                  isSubmitting = true;
                  errorMessage = null;
                });

                try {
                  bool success;
                  if (isEdit) {
                    success = await ref
                            .read(adminVendorsRepositoryProvider)
                            .updateBranchRaw(
                              widget.vendorId,
                              branch['id'],
                              name: nameController.text,
                              nameAr: nameArController.text.isNotEmpty
                                  ? nameArController.text
                                  : null,
                              address: addressController.text,
                              phone: phoneController.text.isNotEmpty
                                  ? PhoneUtils.normalize(phoneController.text)
                                  : null,
                              lat: selectedLat,
                              lng: selectedLng,
                              zoneId: selectedZoneId,
                              isOpen: isOpen,
                              isContracted: isContracted,
                              commissionRate: canEditCommission &&
                                      commissionController.text
                                          .trim()
                                          .isNotEmpty
                                  ? int.tryParse(
                                      commissionController.text.trim(),
                                    )
                                  : null,
                              isAdmin: widget.userRole != 'VENDOR_MEMBER',
                            ) !=
                        null;
                  } else {
                    success = await ref
                            .read(adminVendorsRepositoryProvider)
                            .createBranchRaw(
                              widget.vendorId,
                              name: nameController.text,
                              nameAr: nameArController.text.isNotEmpty
                                  ? nameArController.text
                                  : null,
                              address: addressController.text,
                              phone: phoneController.text.isNotEmpty
                                  ? PhoneUtils.normalize(phoneController.text)
                                  : null,
                              lat: selectedLat!,
                              lng: selectedLng!,
                              zoneId: selectedZoneId,
                              isOpen: isOpen,
                              isContracted: isContracted,
                              commissionRate: canEditCommission &&
                                      commissionController.text
                                          .trim()
                                          .isNotEmpty
                                  ? int.tryParse(
                                      commissionController.text.trim(),
                                    )
                                  : null,
                              isAdmin: widget.userRole != 'VENDOR_MEMBER',
                            ) !=
                        null;
                  }
                  if (!dialogCtx.mounted) return;
                  Navigator.pop(dialogCtx, success);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? l10n.common_success_resource_updated
                              : l10n.common_success_resource_created,
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (!dialogCtx.mounted) return;
                  setDialogState(() {
                    isSubmitting = false;
                    errorMessage = ErrorUtils.translate(ctx, e);
                  });
                }
              },
            ),
          );
        },
      ),
    ).whenComplete(() {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        nameController.dispose();
        nameArController.dispose();
        addressController.dispose();
        phoneController.dispose();
        commissionController.dispose();
      });
    });

    if (result == true) _fetchBranches();
  }

  Future<void> _confirmDelete(dynamic branch) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: l10n.deleteBranch,
      message: l10n.deleteBranchConfirm(
        branch['name'] ?? l10n.unnamedBranch,
      ),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;
    try {
      final result = await ref
          .read(adminVendorsRepositoryProvider)
          .deleteBranch(
            widget.vendorId,
            branch['id'],
            isAdmin: widget.userRole != 'VENDOR_MEMBER',
          );
      if (!mounted) return;
      if (result != null) {
        _fetchBranches();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.common_success_resource_deleted),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorUtils.translate(context, e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
