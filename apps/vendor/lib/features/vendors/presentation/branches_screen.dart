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

  const BranchesScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
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
                        LucideIcons.arrowLeft,
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isEdit ? LucideIcons.edit3 : LucideIcons.mapPin,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isEdit
                                ? AppLocalizations.of(context)!.editBranch
                                : AppLocalizations.of(context)!.newBranch,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildDialogTextField(
                            controller: nameController,
                            label: AppLocalizations.of(context)!.branchName,
                            hint: 'e.g. Downtown Branch',
                            icon: LucideIcons.type,
                          ),
                          const SizedBox(height: 16),
                          _buildDialogTextField(
                            controller: nameArController,
                            label: AppLocalizations.of(context)!.branchNameAr,
                            hint: 'اسم الفرع',
                            icon: LucideIcons.languages,
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 16),
                          _buildDialogTextField(
                            controller: addressController,
                            label: AppLocalizations.of(context)!.address,
                            hint: 'Full address',
                            icon: LucideIcons.mapPin,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.15),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: Icon(
                                LucideIcons.map,
                                color: selectedLat != null
                                    ? AppColors.success
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                              ),
                              title: Text(
                                selectedLat != null
                                    ? AppLocalizations.of(
                                        context,
                                      )!.locationSelected
                                    : AppLocalizations.of(
                                        context,
                                      )!.pickLocation,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: selectedLat != null
                                  ? Text(
                                      '${selectedLat!.toStringAsFixed(4)}, ${selectedLng!.toStringAsFixed(4)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(LucideIcons.chevronRight),
                              onTap: () async {
                                final zones =
                                    ref
                                        .read(zoneProvider)
                                        .asData
                                        ?.value
                                        .zones ??
                                    [];
                                final result = await Navigator.push<LatLng>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LocationPickerMap(
                                      initialLocation:
                                          selectedLat != null &&
                                              selectedLng != null
                                          ? LatLng(selectedLat!, selectedLng!)
                                          : null,
                                      zones: zones,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    selectedLat = result.latitude;
                                    selectedLng = result.longitude;
                                    final matchedZone = _findMatchingZoneId(
                                      result,
                                      zones,
                                    );
                                    if (matchedZone != null) {
                                      selectedZoneId = matchedZone;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer(
                            builder: (context, ref, child) {
                              final zoneState = ref.watch(zoneProvider);
                              return zoneState.when(
                                data: (data) {
                                  final l10n = AppLocalizations.of(context)!;
                                  final isValidZone =
                                      selectedZoneId == null ||
                                      data.zones.any(
                                        (z) =>
                                            z['id']?.toString() ==
                                            selectedZoneId,
                                      );
                                  final currentZoneValue = isValidZone
                                      ? selectedZoneId
                                      : null;

                                  return DropdownButtonFormField<String?>(
                                    key: ValueKey(currentZoneValue),
                                    initialValue: currentZoneValue,
                                    decoration: InputDecoration(
                                      labelText: l10n.zones,
                                      prefixIcon: const Icon(LucideIcons.map),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text(l10n.autoDetectZone),
                                      ),
                                      ...data.zones.map((z) {
                                        return DropdownMenuItem<String?>(
                                          value: z['id']?.toString(),
                                          child: Text(
                                            z['name']?.toString() ?? '',
                                          ),
                                        );
                                      }),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        selectedZoneId = val;
                                      });
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (err, stack) =>
                                    Text(ErrorUtils.translate(context, err)),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDialogTextField(
                            controller: phoneController,
                            label: AppLocalizations.of(context)!.phone,
                            hint: '+123...',
                            icon: LucideIcons.phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.15),
                              ),
                            ),
                            child: SwitchListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'حالة الفرع (مفتوح للطلبات)'
                                    : 'Branch Open for Orders',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                isOpen
                                    ? (Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 'مفتوح حالياً'
                                        : 'Currently Open')
                                    : (Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 'مغلق حالياً'
                                        : 'Currently Closed'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOpen
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                              value: isOpen,
                              activeThumbColor: AppColors.success,
                              onChanged: (val) {
                                setState(() {
                                  isOpen = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.handshake,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        Localizations.localeOf(
                                                  context,
                                                ).languageCode ==
                                                'ar'
                                            ? 'حالة التعاقد للفرع'
                                            : 'Branch Contract Status',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'ar'
                                      ? 'إذا لم يتم التحديد، سيتبع الفرع حالة المتجر الرئيسية تلقائياً'
                                      : 'If unset, branch inherits the vendor contract status',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: DropdownButtonFormField<bool?>(
                                    initialValue: isContracted,
                                    decoration: InputDecoration(
                                      hintText:
                                          Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'اختر حالة التعاقد'
                                          : 'Select contract status',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                    ),
                                    items: [
                                      DropdownMenuItem<bool?>(
                                        value: null,
                                        child: Text(
                                          Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'ar'
                                              ? 'افتراضي المتجر (توريث)'
                                              : 'Inherit vendor status',
                                        ),
                                      ),
                                      DropdownMenuItem<bool?>(
                                        value: true,
                                        child: Text(
                                          Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'ar'
                                              ? 'شريك معتمد'
                                              : 'Contracted',
                                        ),
                                      ),
                                      DropdownMenuItem<bool?>(
                                        value: false,
                                        child: Text(
                                          Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'ar'
                                              ? 'غير متعاقد'
                                              : 'Uncontracted',
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        isContracted = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDialogTextField(
                            controller: commissionController,
                            label:
                                Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? 'نسبة العمولة الخاصة بالفرع (٪) (اختياري)'
                                : 'Branch Commission Rate (%) (Optional)',
                            hint:
                                Localizations.localeOf(context).languageCode ==
                                    'ar'
                                ? 'اتركه فارغاً ليتبع نسبة المتجر'
                                : 'Leave empty to inherit vendor rate',
                            keyboardType: TextInputType.number,
                            icon: LucideIcons.percent,
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.alertCircle,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.01),
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: const TextStyle(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              if (nameController.text.trim().isEmpty) {
                                setState(() {
                                  errorMessage = AppLocalizations.of(
                                    context,
                                  )!.requiredField;
                                });
                                return;
                              }
                              if (!isEdit &&
                                  (selectedLat == null ||
                                      selectedLng == null)) {
                                setState(() {
                                  errorMessage = AppLocalizations.of(
                                    context,
                                  )!.pickLocation;
                                });
                                return;
                              }

                              setState(() {
                                errorMessage = null;
                              });

                              try {
                                bool success;
                                if (isEdit) {
                                  success =
                                      await ref
                                          .read(adminVendorsRepositoryProvider)
                                          .updateBranchRaw(
                                            widget.vendorId,
                                            branch['id'],
                                            name: nameController.text,
                                            nameAr:
                                                nameArController.text.isNotEmpty
                                                ? nameArController.text
                                                : null,
                                            address: addressController.text,
                                            phone:
                                                phoneController.text.isNotEmpty
                                                ? PhoneUtils.normalize(
                                                    phoneController.text,
                                                  )
                                                : null,
                                            lat: selectedLat,
                                            lng: selectedLng,
                                            zoneId: selectedZoneId,
                                            isOpen: isOpen,
                                            isContracted: isContracted,
                                            commissionRate:
                                                commissionController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? int.tryParse(
                                                    commissionController.text
                                                        .trim(),
                                                  )
                                                : null,
                                          ) !=
                                      null;
                                } else {
                                  success =
                                      await ref
                                          .read(adminVendorsRepositoryProvider)
                                          .createBranchRaw(
                                            widget.vendorId,
                                            name: nameController.text,
                                            nameAr:
                                                nameArController.text.isNotEmpty
                                                ? nameArController.text
                                                : null,
                                            address: addressController.text,
                                            phone:
                                                phoneController.text.isNotEmpty
                                                ? PhoneUtils.normalize(
                                                    phoneController.text,
                                                  )
                                                : null,
                                            lat: selectedLat!,
                                            lng: selectedLng!,
                                            zoneId: selectedZoneId,
                                            isOpen: isOpen,
                                            isContracted: isContracted,
                                            commissionRate:
                                                commissionController.text
                                                    .trim()
                                                    .isNotEmpty
                                                ? int.tryParse(
                                                    commissionController.text
                                                        .trim(),
                                                  )
                                                : null,
                                          ) !=
                                      null;
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context, success);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isEdit
                                          ? AppLocalizations.of(
                                              context,
                                            )!.common_success_resource_updated
                                          : AppLocalizations.of(
                                              context,
                                            )!.common_success_resource_created,
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                setState(() {
                                  errorMessage = ErrorUtils.translate(
                                    context,
                                    e,
                                  );
                                });
                              }
                            },
                            child: Text(
                              isEdit
                                  ? AppLocalizations.of(context)!.update
                                  : AppLocalizations.of(context)!.create,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) _fetchBranches();
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextAlign textAlign = TextAlign.start,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textAlign: textAlign,
          keyboardType: keyboardType,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 18,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(dynamic branch) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                color: AppColors.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.deleteBranch,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.deleteBranchConfirm(
                  branch['name'] ?? AppLocalizations.of(context)!.unnamedBranch,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final result = await ref
                              .read(adminVendorsRepositoryProvider)
                              .deleteBranch(widget.vendorId, branch['id']);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (result != null) {
                            _fetchBranches();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.common_success_resource_deleted,
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ErrorUtils.translate(context, e)),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                      ),
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
