import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
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

  Future<void> _fetchVendors() async {
    try {
      final result = await ref.read(adminVendorsRepositoryProvider).getVendors();
      if (mounted) {
        setState(() {
          _vendors = (result is List) ? result : (result['items'] ?? result['vendors'] ?? result['data']?['vendors'] ?? []);
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
          _products = (result is List) ? result : (result['items'] ?? result['products'] ?? result['data']?['products'] ?? []);
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
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final isVendor = widget.userRole == 'VENDOR';

    return DialogScaffold(child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : mediaQuery.size.width * 0.2,
        vertical: 24,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(l10n, isEdit),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isVendor) _buildVendorDropdown(l10n),
                        if (_selectedVendorId != null) ...[
                          if (!isVendor) const SizedBox(height: 16),
                          _buildProductDropdown(l10n),
                          if (_hasSelectedProductVariants()) ...[
                            const SizedBox(height: 16),
                            _buildVariantDropdown(context, l10n),
                            _buildVariantOfferNotice(context, l10n),
                          ],
                        ],
                        const SizedBox(height: 24),
                        _buildTextField(
                          controller: _offerPriceController,
                          label: l10n.offerPrice,
                          hint: '49',
                          icon: LucideIcons.tag,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.isEmpty)
                              ? l10n.fieldRequired
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _originalPriceController,
                          label: l10n.originalPrice,
                          hint: '99',
                          icon: LucideIcons.scissors,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.isEmpty)
                              ? l10n.fieldRequired
                              : null,
                        ),
                        const SizedBox(height: 24),
                        _buildDateSelectors(l10n),
                        const SizedBox(height: 24),
                        if (!isVendor) ...[
                          _buildTextField(
                            controller: _sortOrderController,
                            label: l10n.sortOrder,
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
                ),
              ),
              _buildFooter(l10n, isEdit),
            ],
          ),
        ),
        ),
      ),
    ));
  }

  Widget _buildHeader(AppLocalizations l10n, bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.tag, color: Theme.of(context).colorScheme.onSurface, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              isEdit ? l10n.editOffer : l10n.addOffer,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedVendorId,
      decoration: InputDecoration(
        labelText: l10n.selectVendor,
        prefixIcon: const Icon(LucideIcons.store, size: 18),
      ),
      items: _vendors
          .map(
            (v) => DropdownMenuItem<String>(
              value: v['id'],
              child: Text(v['storeName'] ?? ''),
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
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    return DropdownButtonFormField<String>(
      initialValue: _selectedProductId,
      decoration: InputDecoration(
        labelText: l10n.selectProduct,
        prefixIcon: const Icon(LucideIcons.package, size: 18),
      ),
      items: _products
          .map(
            (p) => DropdownMenuItem<String>(
              value: p['id'],
              child: Text(p['name'] ?? ''),
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
    return product['hasVariants'] == true || (product['variants'] as List?)?.isNotEmpty == true;
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final variants = _getSelectedProductVariants();

    return DropdownButtonFormField<String?>(
      initialValue: _selectedVariantId,
      decoration: InputDecoration(
        labelText: isAr ? 'تطبيق العرض على' : 'Apply Offer To',
        prefixIcon: const Icon(LucideIcons.layers, size: 18),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            isAr
                ? '🌟 جميع الأصناف (خصم نسبي على كل الأصناف)'
                : '🌟 All Variants (Proportional Discount)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        ...variants.map((v) {
          final vName = isAr
              ? (v['nameAr'] ?? v['name'] ?? '')
              : (v['name'] ?? '');
          final vPrice = v['basePrice'] ?? v['price'] ?? '';
          return DropdownMenuItem<String?>(
            value: v['id'],
            child: Text(
              '$vName ($vPrice EGP)',
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

  Widget _buildVariantOfferNotice(BuildContext context, AppLocalizations l10n) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 18, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'اختر "جميع الأصناف" لتطبيق الخصم بنسبة مئوية على جميع الأنواع (مثل بيتزا جبنة، بيتزا تونة)، أو حدد صنفاً معيناً لخصم ذلك الصنف فقط.'
                  : 'Select "All Variants" to apply the discount proportionally across all flavors/types (e.g. Cheese Pizza, Tuna Pizza), or choose a specific variant to discount only that item.',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildDateSelectors(AppLocalizations l10n) {
    return Column(
      children: [
        _buildDatePicker(
          l10n,
          l10n.startDate,
          _startDate,
          (d) => setState(() => _startDate = d),
        ),
        const SizedBox(height: 16),
        _buildDatePicker(
          l10n,
          l10n.endDate,
          _endDate,
          (d) => setState(() => _endDate = d),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    AppLocalizations l10n,
    String label,
    DateTime? date,
    Function(DateTime?) onSelect,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(LucideIcons.calendar, size: 18),
        suffixIcon: date != null
            ? IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                onPressed: () => onSelect(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : null,
      ),
      child: InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (d != null && mounted) {
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(date ?? DateTime.now()),
            );
            if (t != null) {
              onSelect(DateTime(d.year, d.month, d.day, t.hour, t.minute));
            }
          }
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('MMM dd, yyyy HH:mm').format(date)
                    : l10n.noExpiry,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(AppLocalizations l10n) {
    return SwitchListTile(
      title: Text(
        l10n.active,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      value: _isActive,
      onChanged: (v) => setState(() => _isActive = v),
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFooter(AppLocalizations l10n, bool isEdit) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? l10n.update : l10n.create),
            ),
          ),
        ],
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
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
      });
    }
  }
}

