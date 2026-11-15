import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/date_utils.dart';
import 'package:data/data.dart';

class AddOfferDialog extends ConsumerStatefulWidget {
  final dynamic offer;
  final String? userRole;
  final String? vendorId;

  const AddOfferDialog({super.key, this.offer, this.userRole, this.vendorId});

  @override
  ConsumerState<AddOfferDialog> createState() => _AddOfferDialogState();
}

class _AddOfferDialogState extends ConsumerState<AddOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _originalPriceController;
  late TextEditingController _offerPriceController;
  late TextEditingController _sortOrderController;

  late bool _isActive;
  String? _selectedVendorId;
  String? _selectedProductId;
  String? _selectedVariantId;

  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _vendors = [];
  List<dynamic> _products = [];
  bool _isLoadingVendors = true;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _originalPriceController = TextEditingController(
      text: o?['originalPrice']?.toString() ?? '',
    );
    _offerPriceController = TextEditingController(
      text: o?['offerPrice']?.toString() ?? '',
    );
    _sortOrderController = TextEditingController(
      text: o?['sortOrder']?.toString() ?? '0',
    );

    _isActive = o?['isActive'] ?? true;
    _selectedVendorId =
        o?['vendorId'] ??
        (widget.userRole == 'VENDOR' ? widget.vendorId : null);
    _selectedProductId = o?['productId'];
    _selectedVariantId = o?['variantId'];

    if (o?['startDate'] != null) {
      _startDate = DateTime.tryParse(o['startDate'].toString());
    }
    if (o?['endDate'] != null) {
      _endDate = DateTime.tryParse(o['endDate'].toString());
    }

    if (widget.userRole == 'VENDOR') {
      _isLoadingVendors = false;
      if (_selectedVendorId != null) {
        _fetchProducts(_selectedVendorId!);
      }
    } else {
      _fetchVendors();
    }
  }

  @override
  void dispose() {
    _originalPriceController.dispose();
    _offerPriceController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _fetchVendors() async {
    try {
      final result = await ref.read(adminVendorsRepositoryProvider).getVendors();
      if (mounted) {
        setState(() {
          _vendors = (result is List)
              ? result
              : (result['items'] ??
                  result['vendors'] ??
                  result['data']?['vendors'] ??
                  []);
          _isLoadingVendors = false;
        });

        if (_selectedVendorId != null) {
          _fetchProducts(_selectedVendorId!);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVendors = false);
    }
  }

  Future<void> _fetchProducts(String vendorId) async {
    setState(() {
      _isLoadingProducts = true;
      _products = [];
    });
    try {
      final result = await ref
          .read(adminVendorsRepositoryProvider)
          .getProducts(vendorId);
      if (mounted) {
        setState(() {
          _products = (result is List)
              ? result
              : (result['items'] ??
                  result['products'] ??
                  result['data']?['products'] ??
                  []);
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.offer != null;
    final isVendor = widget.userRole == 'VENDOR';

    return AppDialog(
      maxWidth: 620,
      maxHeight: 800,
      header: AppDialogHeader(
        icon: LucideIcons.tag,
        title: isEdit ? l10n.editOffer : l10n.addOffer,
        onClose: () => Navigator.pop(context),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isVendor) ...[
              AppFieldLabel(label: l10n.selectVendor, isRequired: true),
              _buildVendorDropdown(l10n),
            ],
            if (_selectedVendorId != null) ...[
              if (!isVendor) const SizedBox(height: 16),
              AppFieldLabel(label: l10n.selectProduct, isRequired: true),
              _buildProductDropdown(l10n),
              if (_hasSelectedProductVariants()) ...[
                const SizedBox(height: 16),
                AppFieldLabel(
                  label: Localizations.localeOf(context).languageCode == 'ar'
                      ? 'تطبيق العرض على'
                      : 'Apply Offer To',
                ),
                _buildVariantDropdown(context, l10n),
                _buildVariantOfferNotice(context),
              ],
            ],
            const SizedBox(height: 20),
            AppFieldLabel(label: l10n.offerPrice, isRequired: true),
            _buildTextField(
              controller: _offerPriceController,
              hint: '49',
              icon: LucideIcons.tag,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            AppFieldLabel(label: l10n.originalPrice, isRequired: true),
            _buildTextField(
              controller: _originalPriceController,
              hint: '99',
              icon: LucideIcons.scissors,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 20),
            _buildDateSelectors(l10n),
            const SizedBox(height: 16),
            if (!isVendor) ...[
              AppFieldLabel(label: l10n.sortOrder),
              _buildTextField(
                controller: _sortOrderController,
                hint: '0',
                icon: LucideIcons.listOrdered,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
            _buildSwitchTile(l10n),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: l10n.cancel,
        onCancel: () => Navigator.pop(context),
        confirmLabel: isEdit ? l10n.update : l10n.create,
        confirmIcon: LucideIcons.check,
        onConfirm: _submit,
      ),
    );
  }

  Widget _buildVendorDropdown(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (_isLoadingVendors) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedVendorId,
      isExpanded: true,
      dropdownColor: AppDialogStyles.dropdownColor(context),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: AppDialogStyles.inputDecoration(
        context,
        hintText: l10n.selectVendor,
        icon: LucideIcons.store,
      ),
      items: _vendors
          .map(
            (v) => DropdownMenuItem<String>(
              value: v['id'],
              child: Text(
                v['storeName'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: (v) => v == null ? l10n.fieldRequired : null,
      onChanged: widget.offer != null
          ? null
          : (v) {
              setState(() {
                _selectedVendorId = v;
                _selectedProductId = null;
              });
              if (v != null) _fetchProducts(v);
            },
    );
  }

  Widget _buildProductDropdown(AppLocalizations l10n) {
    final theme = Theme.of(context);
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedProductId,
      isExpanded: true,
      dropdownColor: AppDialogStyles.dropdownColor(context),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: AppDialogStyles.inputDecoration(
        context,
        hintText: l10n.selectProduct,
        icon: LucideIcons.package,
      ),
      items: _products
          .map(
            (p) => DropdownMenuItem<String>(
              value: p['id'],
              child: Text(
                p['name'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      validator: (v) => v == null ? l10n.fieldRequired : null,
      onChanged: widget.offer != null
          ? null
          : (v) {
              setState(() => _selectedProductId = v);
              // Auto-fill price
              if (v != null) {
                final product = _products.firstWhere(
                  (p) => p['id'] == v,
                  orElse: () => null,
                );
                if (product != null) {
                  final price = product['basePrice'] ?? product['price'];
                  if (price != null) {
                    _originalPriceController.text = price.toString();
                  }
                }
              }
            },
    );
  }

  bool _hasSelectedProductVariants() {
    if (_selectedProductId == null) return false;
    final product = _products.firstWhere(
      (p) => p['id'] == _selectedProductId,
      orElse: () => null,
    );
    if (product == null) return false;
    return product['hasVariants'] == true ||
        (product['variants'] as List?)?.isNotEmpty == true;
  }

  List<dynamic> _getSelectedProductVariants() {
    if (_selectedProductId == null) return [];
    final product = _products.firstWhere(
      (p) => p['id'] == _selectedProductId,
      orElse: () => null,
    );
    if (product == null) return [];
    return (product['variants'] as List?) ?? [];
  }

  Widget _buildVariantDropdown(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final variants = _getSelectedProductVariants();

    return DropdownButtonFormField<String?>(
      initialValue: _selectedVariantId,
      isExpanded: true,
      dropdownColor: AppDialogStyles.dropdownColor(context),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: theme.colorScheme.onSurface,
      ),
      decoration: AppDialogStyles.inputDecoration(
        context,
        icon: LucideIcons.layers,
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            isAr
                ? 'جميع الأصناف (خصم نسبي على كل الأصناف)'
                : 'All Variants (Proportional Discount)',
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...variants.map((v) {
          final vName =
              isAr ? (v['nameAr'] ?? v['name'] ?? '') : (v['name'] ?? '');
          final vPrice = v['basePrice'] ?? v['price'] ?? '';
          return DropdownMenuItem<String?>(
            value: v['id'],
            child: Text(
              '$vName ($vPrice EGP)',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: widget.offer != null
          ? null
          : (v) {
              setState(() {
                _selectedVariantId = v;
                if (v == null) {
                  final product = _products.firstWhere(
                    (p) => p['id'] == _selectedProductId,
                    orElse: () => null,
                  );
                  if (product != null) {
                    final price = product['basePrice'] ?? product['price'];
                    if (price != null) {
                      _originalPriceController.text = price.toString();
                    }
                  }
                } else {
                  final variant = variants.firstWhere(
                    (item) => item['id'] == v,
                    orElse: () => null,
                  );
                  if (variant != null) {
                    final price = variant['basePrice'] ?? variant['price'];
                    if (price != null) {
                      _originalPriceController.text = price.toString();
                    }
                  }
                }
              });
            },
    );
  }

  Widget _buildVariantOfferNotice(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return AppDialogSectionCard(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      backgroundColor: AppColors.info.withValues(alpha: 0.08),
      borderColor: AppColors.info.withValues(alpha: 0.28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 17, color: AppColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'اختر "جميع الأصناف" لتطبيق الخصم بنسبة مئوية على جميع الأنواع (مثل بيتزا جبنة، بيتزا تونة)، أو حدد صنفاً معيناً لخصم ذلك الصنف فقط.'
                  : 'Select "All Variants" to apply the discount proportionally across all flavors/types (e.g. Cheese Pizza, Tuna Pizza), or choose a specific variant to discount only that item.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textDirection: TextDirection.ltr,
      decoration: AppDialogStyles.inputDecoration(
        context,
        hintText: hint,
        icon: icon,
      ),
    );
  }

  Widget _buildDateSelectors(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: l10n.startDate),
        _buildDatePicker(
          l10n,
          _startDate,
          (d) => setState(() => _startDate = d),
        ),
        const SizedBox(height: 16),
        AppFieldLabel(label: l10n.endDate),
        _buildDatePicker(
          l10n,
          _endDate,
          (d) => setState(() => _endDate = d),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    AppLocalizations l10n,
    DateTime? date,
    Function(DateTime?) onSelect,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: AppDialogStyles.adaptivePickerTheme,
        );
        if (d != null && mounted) {
          final t = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date ?? DateTime.now()),
            builder: AppDialogStyles.adaptivePickerTheme,
          );
          if (t != null) {
            onSelect(DateTime(d.year, d.month, d.day, t.hour, t.minute));
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: AppDialogStyles.inputDecoration(
          context,
          icon: LucideIcons.calendar,
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () => onSelect(null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
        ),
        child: Text(
          date != null
              ? DateFormat('MMM dd, yyyy hh:mm a').format(date)
              : l10n.noExpiry,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: date != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(AppLocalizations l10n) {
    return AppDialogSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: SwitchListTile(
        title: Text(
          l10n.active,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        value: _isActive,
        onChanged: (v) => setState(() => _isActive = v),
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, {
        'productId': _selectedProductId,
        'variantId': _selectedVariantId,
        'vendorId': _selectedVendorId,
        'originalPrice': double.tryParse(_originalPriceController.text) ?? 0,
        'offerPrice': double.tryParse(_offerPriceController.text) ?? 0,
        'isActive': _isActive,
        'sortOrder': int.tryParse(_sortOrderController.text) ?? 0,
        'startDate': _startDate == null
            ? null
            : toOffsetIso8601String(_startDate!),
        'endDate': _endDate == null
            ? null
            : toOffsetIso8601String(_endDate!),
      });
    }
  }
}

