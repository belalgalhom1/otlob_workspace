import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/core.dart';
import 'dart:io';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';

class AddPromotionDialog extends ConsumerStatefulWidget {
  final dynamic promotion;

  const AddPromotionDialog({super.key, this.promotion});

  @override
  ConsumerState<AddPromotionDialog> createState() => _AddPromotionDialogState();
}

class _AddPromotionDialogState extends ConsumerState<AddPromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _titleArController;
  late TextEditingController _descriptionController;
  late TextEditingController _descriptionArController;
  late TextEditingController _urlController;
  late TextEditingController _sortOrderController;

  late String _type;
  late bool _isActive;
  String? _selectedVendorId;
  String? _selectedProductId;

  XFile? _imageFile;

  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _vendors = [];
  List<dynamic> _products = [];
  bool _isLoadingVendors = true;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _titleController = TextEditingController(text: p?['title'] ?? '');
    _titleArController = TextEditingController(text: p?['titleAr'] ?? '');
    _descriptionController = TextEditingController(
      text: p?['description'] ?? '',
    );
    _descriptionArController = TextEditingController(
      text: p?['descriptionAr'] ?? '',
    );
    _urlController = TextEditingController(text: p?['externalUrl'] ?? '');
    _sortOrderController = TextEditingController(
      text: p?['sortOrder']?.toString() ?? '0',
    );

    _type = p?['type'] ?? 'BANNER';
    _isActive = p?['isActive'] ?? true;
    _selectedVendorId = p?['vendorId'];
    _selectedProductId = p?['productId'];

    if (p?['startDate'] != null) {
      _startDate = DateTime.tryParse(p['startDate'].toString());
    }
    if (p?['endDate'] != null) {
      _endDate = DateTime.tryParse(p['endDate'].toString());
    }

    _fetchVendors();
  }

  Future<void> _fetchVendors() async {
    try {
      final result = await ref.read(adminVendorsRepositoryProvider).getVendors();
      if (mounted) {
        setState(() {
          _vendors = (result is List) ? result : (result['items'] ?? result['vendors'] ?? result['data']?['vendors'] ?? []);
          _isLoadingVendors = false;
        });

        if (_selectedVendorId != null && _type == 'PRODUCT') {
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
    final isEdit = widget.promotion != null;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;

    return DialogScaffold(child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : mediaQuery.size.width * 0.15,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 32,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          l10n.uploadBannerImage,
                          LucideIcons.image,
                        ),
                        const SizedBox(height: 12),
                        _buildImagePicker(l10n),
                        const SizedBox(height: 32),

                        _buildSectionHeader(
                          l10n.promotionType,
                          LucideIcons.tag,
                        ),
                        const SizedBox(height: 12),
                        _buildTypeDropdown(l10n),
                        const SizedBox(height: 16),

                        if (_type == 'VENDOR' || _type == 'PRODUCT') ...[
                          _buildVendorDropdown(l10n),
                          if (_type == 'PRODUCT' &&
                              _selectedVendorId != null) ...[
                            const SizedBox(height: 16),
                            _buildProductDropdown(l10n),
                          ],
                        ],

                        if (_type == 'EXTERNAL_LINK') ...[
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _urlController,
                            label: l10n.externalUrl,
                            hint: 'https://...',
                            icon: LucideIcons.link,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return l10n.fieldRequired;
                              }
                              if (!Uri.parse(v).isAbsolute) {
                                return l10n.invalidUrl;
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          l10n.generalInformation,
                          LucideIcons.info,
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _titleController,
                          label: l10n.titleEn,
                          hint: 'Summer Sale',
                          icon: LucideIcons.type,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _titleArController,
                          label: l10n.titleAr,
                          hint: 'عروض الصيف',
                          icon: LucideIcons.languages,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionController,
                          label: l10n.descriptionEn,
                          hint: 'Optional...',
                          icon: LucideIcons.alignLeft,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _descriptionArController,
                          label: l10n.descriptionAr,
                          hint: 'اختياري...',
                          icon: LucideIcons.languages,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 16),
                        _buildDateSelectors(l10n),
                        const SizedBox(height: 32),
                        _buildTextField(
                          controller: _sortOrderController,
                          label: l10n.sortOrder,
                          hint: '0',
                          icon: LucideIcons.listOrdered,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildSwitchTile(l10n),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(l10n, isEdit, isMobile),
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
        color: AppColors.primary.withValues(alpha: 0.05),
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
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.megaphone,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isEdit ? l10n.editPromotion : l10n.addPromotion,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(AppLocalizations l10n) {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
              )
            : (widget.promotion?['imageUrl'] != null && widget.promotion!['imageUrl'].toString().trim().isNotEmpty)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  ImageUtils.formatImageUrl(widget.promotion!['imageUrl']),
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.uploadCloud,
                    size: 32,
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.uploadBannerImage,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imageFile = image);
  }

  Widget _buildTypeDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _type,
      decoration: const InputDecoration(
        prefixIcon: Icon(LucideIcons.layers, size: 18),
      ),
      items: [
        DropdownMenuItem(value: 'BANNER', child: Text(l10n.bannerType)),
        DropdownMenuItem(value: 'VENDOR', child: Text(l10n.vendorType)),
        DropdownMenuItem(value: 'PRODUCT', child: Text(l10n.productType)),
        DropdownMenuItem(value: 'EXTERNAL_LINK', child: Text(l10n.linkType)),
      ],
      onChanged: (v) => setState(() => _type = v!),
    );
  }

  Widget _buildVendorDropdown(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedVendorId,
        decoration: InputDecoration(
          labelText: l10n.selectVendor,
          prefixIcon: const Icon(LucideIcons.store, size: 18),
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
        onChanged: (v) {
          setState(() {
            _selectedVendorId = v;
            _selectedProductId = null;
          });
          if (v != null && _type == 'PRODUCT') _fetchProducts(v);
        },
      ),
    );
  }

  Widget _buildProductDropdown(AppLocalizations l10n) {
    if (_isLoadingProducts) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(l10n.noProductsFound, style: const TextStyle(color: AppColors.error)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedProductId,
        decoration: InputDecoration(
          labelText: l10n.selectProduct,
          prefixIcon: const Icon(LucideIcons.package, size: 18),
        ),
        items: _products
            .map(
              (p) => DropdownMenuItem<String>(
                value: p['id'],
                child: Text(p['name'] ?? '', overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        validator: (v) => v == null ? l10n.fieldRequired : null,
        onChanged: (v) => setState(() => _selectedProductId = v),
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
    TextAlign textAlign = TextAlign.start,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textAlign: textAlign,
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
          l10n.startDate,
          _startDate,
          (d) => setState(() => _startDate = d),
        ),
        const SizedBox(height: 16),
        _buildDatePicker(
          l10n.endDate,
          _endDate,
          (d) => setState(() => _endDate = d),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime? date,
    Function(DateTime?) onSelect,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
          if (d != null) onSelect(d);
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('MMM dd, yyyy').format(date)
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

  Widget _buildFooter(AppLocalizations l10n, bool isEdit, bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
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
            child: Builder(
              builder: (btnCtx) => ElevatedButton(
                onPressed: () => _submit(btnCtx),
                child: Text(isEdit ? l10n.update : l10n.create),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    if (_formKey.currentState?.validate() ?? false) {
      if (_imageFile == null && widget.promotion?['imageUrl'] == null) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text(l10n.imageRequired)));
        return;
      }
      Navigator.pop(context, {
        'title': _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        'titleAr': _titleArController.text.trim().isEmpty ? null : _titleArController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'descriptionAr': _descriptionArController.text.trim().isEmpty ? null : _descriptionArController.text.trim(),
        'type': _type,
        'vendorId': (_type == 'VENDOR' || _type == 'PRODUCT') ? _selectedVendorId : null,
        'productId': _type == 'PRODUCT' ? _selectedProductId : null,
        'externalUrl': _type == 'EXTERNAL_LINK' ? _urlController.text.trim() : null,
        'isActive': _isActive,
        'sortOrder': int.tryParse(_sortOrderController.text) ?? 0,
        'imageFile': _imageFile,
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
      });
    }
  }
}

