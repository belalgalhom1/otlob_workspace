import 'package:data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import '../../data/driver_models.dart';
import '../../data/driver_providers.dart';
import '../../../../core/utils/error_utils.dart';
import 'driver_vehicle_icon.dart';

class DriverFormDialog extends ConsumerStatefulWidget {
  final DriverProfile? driver;

  /// When true the dialog only displays the driver's information and offers
  /// no way to save changes (used for DRIVER_MANAGER accounts).
  final bool readOnly;

  const DriverFormDialog({super.key, this.driver, this.readOnly = false});

  @override
  ConsumerState<DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends ConsumerState<DriverFormDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  String _selectedVehicleType = 'MOTORCYCLE';
  static const List<String> _vehicleTypes = [
    'BICYCLE',
    'MOTORCYCLE',
    'CAR',
    'VAN',
    'TRUCK',
    'MOTOR_TRICYCLE',
  ];
  final _vehiclePlateController = TextEditingController();
  bool _isApproved = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedDriverManagerUserId;
  List<dynamic> _driverManagers = [];

  @override
  void initState() {
    super.initState();
    if (widget.driver != null) {
      _nameController.text = widget.driver!.name;
      _nationalIdController.text = widget.driver!.nationalId ?? '';
      _licenseNumberController.text = widget.driver!.licenseNumber ?? '';
      if (widget.driver!.vehicleType != null && _vehicleTypes.contains(widget.driver!.vehicleType)) {
        _selectedVehicleType = widget.driver!.vehicleType!;
      }
      _vehiclePlateController.text = widget.driver!.vehiclePlate ?? '';
      _isApproved = widget.driver!.isApproved;
      if (widget.driver!.user != null) {
        _emailController.text = widget.driver!.user['email'] ?? '';
        _phoneController.text = widget.driver!.user['phone'] ?? '';
      }
      _selectedDriverManagerUserId = widget.driver!.driverManagerUserId;
    }
    if (!widget.readOnly) {
      _loadManagers();
    }
  }

  Future<void> _loadManagers() async {
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      final res = await repo.listDriverManagers();
      if (res is List && mounted) {
        setState(() {
          _driverManagers = res;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nationalIdController.dispose();
    _licenseNumberController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final nationalId = _nationalIdController.text.trim();
    final licenseNumber = _licenseNumberController.text.trim();
    final vehicleType = _selectedVehicleType;
    final vehiclePlate = _vehiclePlateController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = l10n.common_error_validation);
      return;
    }

    if (widget.driver == null && (email.isEmpty || password.isEmpty || phone.isEmpty)) {
      setState(() => _errorMessage = l10n.common_error_validation);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        if (name.isNotEmpty) 'name': name,
        if (email.isNotEmpty) 'email': email,
        if (phone.isNotEmpty) 'phone': phone,
        if (password.isNotEmpty) 'password': password,
        if (nationalId.isNotEmpty) 'nationalId': nationalId,
        if (licenseNumber.isNotEmpty) 'licenseNumber': licenseNumber,
        if (vehicleType.isNotEmpty) 'vehicleType': vehicleType,
        if (vehiclePlate.isNotEmpty) 'vehiclePlate': vehiclePlate,
        'isApproved': _isApproved,
        'driverManagerUserId': _selectedDriverManagerUserId,
      };

      if (widget.driver == null) {
        await ref.read(driversProvider.notifier).createDriver(payload);
      } else {
        await ref.read(driversProvider.notifier).updateDriver(widget.driver!.id, payload);
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        final msg = l10n.common_success_operation;
        Navigator.of(context).pop();
        messenger?.showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ErrorUtils.translate(context, e);
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDriverManagerDropdown() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    if (widget.readOnly) {
      return _buildReadOnlyField(
        isAr ? 'مسؤول السائقين' : 'Driver Manager',
        LucideIcons.userCheck,
        widget.driver?.driverManagerName,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFieldLabel(label: isAr ? 'مسؤول السائقين' : 'Driver Manager'),
          DropdownButtonFormField<String?>(
            initialValue: _selectedDriverManagerUserId,
            isExpanded: true,
            dropdownColor: AppDialogStyles.dropdownColor(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: isAr ? 'بدون مدير (غير معين)' : 'None (Unassigned)',
              icon: LucideIcons.userCheck,
              helperText: isAr
                  ? 'تحديد مسؤول السائقين لتوجيه العمولات والمتابعة'
                  : 'Select driver manager for commissions and oversight',
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  isAr ? 'بدون مدير (غير معين)' : 'None (Unassigned)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ..._driverManagers.map((m) {
                final uid = (m['userId'] ?? '').toString();
                final name = (m['name'] ?? '').toString();
                final phone = (m['phone'] ?? '').toString();
                final label = phone.isNotEmpty ? '$name ($phone)' : name;
                return DropdownMenuItem<String?>(
                  value: uid,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: _isLoading
                ? null
                : (val) => setState(() => _selectedDriverManagerUserId = val),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    String? hint,
    bool isPassword = false,
    bool isRequired = false,
    TextInputType? keyboardType,
    TextDirection? textDirection,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFieldLabel(label: label, isRequired: isRequired && !widget.readOnly),
          TextField(
            controller: controller,
            enabled: !widget.readOnly && !_isLoading,
            readOnly: widget.readOnly,
            obscureText: isPassword,
            keyboardType: keyboardType,
            textDirection: textDirection,
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: hint ?? label,
              icon: icon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, IconData icon, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFieldLabel(label: label),
          TextFormField(
            initialValue: (value == null || value.trim().isEmpty) ? '—' : value,
            readOnly: true,
            decoration: AppDialogStyles.inputDecoration(
              context,
              icon: icon,
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleTypeTranslation(AppLocalizations l10n, String type) {
    switch (type) {
      case 'BICYCLE': return l10n.vehicleTypeBicycle;
      case 'MOTORCYCLE': return l10n.vehicleTypeMotorcycle;
      case 'CAR': return l10n.vehicleTypeCar;
      case 'VAN': return l10n.vehicleTypeVan;
      case 'TRUCK': return l10n.vehicleTypeTruck;
      case 'MOTOR_TRICYCLE': return l10n.vehicleTypeMotorTricycle;
      default: return type;
    }
  }

  Widget _buildVehicleTypeDropdown(String label, IconData icon) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFieldLabel(label: label),
          DropdownButtonFormField<String>(
            initialValue: _selectedVehicleType,
            isExpanded: true,
            dropdownColor: AppDialogStyles.dropdownColor(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            decoration: AppDialogStyles.inputDecoration(
              context,
              hintText: label,
              icon: icon,
            ),
            items: _vehicleTypes.map((type) {
              final displayType = _getVehicleTypeTranslation(l10n, type);
              return DropdownMenuItem(
                value: type,
                child: Text(displayType, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (widget.readOnly || _isLoading)
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _selectedVehicleType = value);
                    }
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.driver == null;
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    return AppDialog(
      maxWidth: 540,
      canPop: !_isLoading,
      header: AppDialogHeader(
        icon: isNew ? LucideIcons.userPlus : LucideIcons.user,
        title: widget.readOnly
            ? (isAr ? 'تفاصيل السائق' : 'Driver Details')
            : (isNew ? l10n.createNewUser : l10n.editUserProfile),
        isCloseDisabled: _isLoading,
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) ...[
            AppDialogErrorBanner(message: _errorMessage!),
            const SizedBox(height: 16),
          ],
          _buildField(
            l10n.fullName,
            LucideIcons.user,
            _nameController,
            isRequired: true,
          ),
          _buildField(
            l10n.emailAddress,
            LucideIcons.mail,
            _emailController,
            isRequired: isNew,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
          ),
          _buildField(
            l10n.phone,
            LucideIcons.phone,
            _phoneController,
            isRequired: isNew,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
          ),
          if (isNew)
            _buildField(
              l10n.password,
              LucideIcons.lock,
              _passwordController,
              isPassword: true,
              isRequired: true,
            ),
          _buildField(
            l10n.nationalId,
            LucideIcons.creditCard,
            _nationalIdController,
            textDirection: TextDirection.ltr,
          ),
          _buildField(
            l10n.licenseNumber,
            LucideIcons.fileText,
            _licenseNumberController,
            textDirection: TextDirection.ltr,
          ),
          _buildVehicleTypeDropdown(
            l10n.vehicleType,
            driverVehicleIcon(_selectedVehicleType),
          ),
          _buildField(
            l10n.vehiclePlate,
            LucideIcons.hash,
            _vehiclePlateController,
          ),
          _buildDriverManagerDropdown(),
          AppDialogSectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.driverApprovedTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                l10n.driverApprovedSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              value: _isApproved,
              onChanged: (widget.readOnly || _isLoading)
                  ? null
                  : (val) => setState(() => _isApproved = val),
              activeThumbColor: AppColors.primary,
            ),
          ),
        ],
      ),
      footer: widget.readOnly
          ? AppDialogFooter(
              confirmLabel: l10n.done,
              onConfirm: () => Navigator.of(context).pop(),
            )
          : AppDialogFooter(
              cancelLabel: l10n.cancel,
              onCancel: () => Navigator.of(context).pop(),
              confirmLabel: l10n.save,
              confirmIcon: LucideIcons.save,
              isLoading: _isLoading,
              onConfirm: _submit,
            ),
    );
  }
}
