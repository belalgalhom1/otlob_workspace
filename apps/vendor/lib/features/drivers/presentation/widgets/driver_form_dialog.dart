import 'package:data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import '../../data/driver_models.dart';
import '../../data/driver_providers.dart';
import '../../../../core/utils/error_utils.dart';

class DriverFormDialog extends ConsumerStatefulWidget {
  final DriverProfile? driver;

  const DriverFormDialog({super.key, this.driver});

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
    _loadManagers();
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

  Future<void> _submit(BuildContext ctx) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final nationalId = _nationalIdController.text.trim();
    final licenseNumber = _licenseNumberController.text.trim();
    final vehicleType = _selectedVehicleType;
    final vehiclePlate = _vehiclePlateController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(AppLocalizations.of(ctx)!.common_error_validation)));
      return;
    }
    
    if (widget.driver == null && (email.isEmpty || password.isEmpty || phone.isEmpty)) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(AppLocalizations.of(ctx)!.common_error_validation)));
      return;
    }

    setState(() => _isLoading = true);

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.common_success_operation)));
          Navigator.of(context).pop();
        }
      } else {
        await ref.read(driversProvider.notifier).updateDriver(widget.driver!.id, payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.common_success_operation)));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(ctx, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDriverManagerDropdown() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String?>(
        initialValue: _selectedDriverManagerUserId,
        decoration: InputDecoration(
          labelText: isAr ? 'مسؤول السائقين' : 'Driver Manager',
          prefixIcon: const Icon(LucideIcons.userCheck),
          helperText: isAr
              ? 'تحديد مسؤول السائقين لتوجيه العمولات والمتابعة'
              : 'Select driver manager for commissions and oversight',
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(isAr ? 'بدون مدير (غير معين)' : 'None (Unassigned)'),
          ),
          ..._driverManagers.map((m) {
            final uid = (m['userId'] ?? '').toString();
            final name = (m['name'] ?? '').toString();
            final phone = (m['phone'] ?? '').toString();
            final label = phone.isNotEmpty ? '$name ($phone)' : name;
            return DropdownMenuItem<String?>(
              value: uid,
              child: Text(label),
            );
          }),
        ],
        onChanged: (val) => setState(() => _selectedDriverManagerUserId = val),
      ),
    );
  }

  Widget _buildField(String label, IconData icon, TextEditingController controller, [String? hint, bool isPassword = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceBright,
        ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedVehicleType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceBright,
        ),
        items: _vehicleTypes.map((type) {
          final displayType = _getVehicleTypeTranslation(l10n, type);
          return DropdownMenuItem(
            value: type,
            child: Text(displayType),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedVehicleType = value);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.driver == null;
    final l10n = AppLocalizations.of(context)!;
    
    return DialogScaffold(child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isNew ? LucideIcons.userPlus : LucideIcons.user,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isNew ? l10n.createNewUser : l10n.editUserProfile,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildField(l10n.fullName, LucideIcons.user, _nameController),
              _buildField(l10n.emailAddress, LucideIcons.mail, _emailController),
              _buildField(l10n.phone, LucideIcons.phone, _phoneController),
              if (isNew)
                _buildField(l10n.password, LucideIcons.lock, _passwordController, null, true),
              _buildField(l10n.nationalId, LucideIcons.creditCard, _nationalIdController),
              _buildField(l10n.licenseNumber, LucideIcons.fileText, _licenseNumberController),
              _buildVehicleTypeDropdown(l10n.vehicleType, LucideIcons.car),
              _buildField(l10n.vehiclePlate, LucideIcons.hash, _vehiclePlateController),
              _buildDriverManagerDropdown(),
              SwitchListTile(
                title: Text(l10n.driverApprovedTitle),
                subtitle: Text(l10n.driverApprovedSubtitle),
                value: _isApproved,
                onChanged: (val) => setState(() => _isApproved = val),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 12),
                  Builder(
                    builder: (btnCtx) => FilledButton(
                      onPressed: _isLoading ? null : () => _submit(btnCtx),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.save),
                  ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
