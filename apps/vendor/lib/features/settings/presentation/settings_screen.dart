import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';
import 'bloc/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Map<String, dynamic> _editedSettings = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).fetchSettings();
    });
  }

  void _onSettingChanged(String key, dynamic value) {
    setState(() {
      _editedSettings[key] = value;
    });
  }

  Future<void> _saveSettings() async {
    if (_editedSettings.isEmpty) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(settingsProvider.notifier).updateSettings(_editedSettings);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsSavedSuccessfully), backgroundColor: AppColors.success),
        );
      }
      _editedSettings.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSavingSettings(e.toString())), backgroundColor: AppColors.error),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<Map<String, dynamic>>>(settingsProvider, (previous, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final state = ref.watch(settingsProvider);

    if (state.isLoading && !state.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasValue) {
      final settings = state.value!;
      
      // Merge original with edited for display
      final displaySettings = Map<String, dynamic>.from(settings)..addAll(_editedSettings);

      return DefaultTabController(
        length: 7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 16),
            TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: l10n.tabAssets, icon: const Icon(LucideIcons.image)),
                Tab(text: l10n.tabFinancials, icon: const Icon(LucideIcons.dollarSign)),
                Tab(text: l10n.tabDelivery, icon: const Icon(LucideIcons.truck)),
                Tab(text: l10n.tabLoyalty, icon: const Icon(LucideIcons.award)),
                Tab(text: l10n.tabDrivers, icon: const Icon(LucideIcons.users)),
                Tab(text: l10n.tabAppLegal, icon: const Icon(LucideIcons.smartphone)),
                Tab(text: l10n.tabDataRetention, icon: const Icon(LucideIcons.database)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAssetsTab(context, l10n, displaySettings, isDark),
                  _buildFinancialsTab(l10n, displaySettings),
                  _buildDeliveryTab(l10n, displaySettings),
                  _buildLoyaltyTab(l10n, displaySettings),
                  _buildDriversTab(l10n, displaySettings),
                  _buildAppLegalTab(l10n, displaySettings),
                  _buildDataRetentionTab(l10n, displaySettings),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(LucideIcons.settings, size: 28, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          l10n.settings,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (_editedSettings.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Icon(LucideIcons.save, size: 18),
            label: Text(_isSaving ? l10n.saving : l10n.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildFieldRow(String label, String key, dynamic value, {bool isNumber = false, bool isBoolean = false}) {
    if (isBoolean) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Switch(
              value: value == true,
              onChanged: (v) => _onSettingChanged(key, v),
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: value?.toString() ?? '',
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            onChanged: (v) => _onSettingChanged(key, v),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialsTab(AppLocalizations l10n, Map<String, dynamic> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFieldRow(l10n.currency, 'currency', settings['currency']),
          _buildFieldRow(l10n.defaultCommissionRate, 'defaultCommissionRate', settings['defaultCommissionRate'], isNumber: true),
          _buildFieldRow(l10n.deliveryCommissionRate, 'deliveryCommissionRate', settings['deliveryCommissionRate'], isNumber: true),
          _buildFieldRow(l10n.customOrderPlatformFee, 'customOrderPlatformFee', settings['customOrderPlatformFee'], isNumber: true),
          _buildFieldRow(l10n.defaultTaxRate, 'defaultTaxRate', settings['defaultTaxRate'], isNumber: true),
          _buildFieldRow(l10n.minOrderAmount, 'minOrderAmount', settings['minOrderAmount'], isNumber: true),
          _buildFieldRow(l10n.highValueOrderThreshold, 'highValueOrderThreshold', settings['highValueOrderThreshold'], isNumber: true),
          _buildFieldRow(l10n.highValueUpfrontRate, 'highValueUpfrontRate', settings['highValueUpfrontRate'], isNumber: true),
        ],
      ),
    );
  }

  Widget _buildDeliveryTab(AppLocalizations l10n, Map<String, dynamic> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFieldRow(l10n.baseDeliveryFee, 'baseDeliveryFee', settings['baseDeliveryFee'], isNumber: true),
          _buildFieldRow(l10n.pricePerKm, 'pricePerKm', settings['pricePerKm'], isNumber: true),
          _buildFieldRow(l10n.pricePerKmBicycle, 'pricePerKmBicycle', settings['pricePerKmBicycle'], isNumber: true),
          _buildFieldRow(l10n.pricePerKmMotorcycle, 'pricePerKmMotorcycle', settings['pricePerKmMotorcycle'], isNumber: true),
          _buildFieldRow(l10n.pricePerKmCar, 'pricePerKmCar', settings['pricePerKmCar'], isNumber: true),
          _buildFieldRow(l10n.pricePerKmVan, 'pricePerKmVan', settings['pricePerKmVan'], isNumber: true),
          _buildFieldRow(l10n.pricePerKmTruck, 'pricePerKmTruck', settings['pricePerKmTruck'], isNumber: true),
          _buildFieldRow(l10n.pricePerKmMotorTricycle, 'pricePerKmMotorTricycle', settings['pricePerKmMotorTricycle'], isNumber: true),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            l10n.localeName == 'ar' ? 'المركبات المتاحة' : 'Allowed Vehicles',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFieldRow(l10n.localeName == 'ar' ? 'إتاحة الدراجات' : 'Allow Bicycles', 'allowBicycle', settings['allowBicycle'], isBoolean: true),
          _buildFieldRow(l10n.localeName == 'ar' ? 'إتاحة الدراجات النارية' : 'Allow Motorcycles', 'allowMotorcycle', settings['allowMotorcycle'], isBoolean: true),
          _buildFieldRow(l10n.localeName == 'ar' ? 'إتاحة التروسيكل' : 'Allow Tricycles', 'allowMotorTricycle', settings['allowMotorTricycle'], isBoolean: true),
          _buildFieldRow(l10n.localeName == 'ar' ? 'إتاحة السيارات' : 'Allow Cars', 'allowCar', settings['allowCar'], isBoolean: true),
          _buildFieldRow(l10n.localeName == 'ar' ? 'إتاحة الفان' : 'Allow Vans', 'allowVan', settings['allowVan'], isBoolean: true),
          _buildFieldRow(l10n.localeName == 'ar' ? 'إتاحة سيارات النقل' : 'Allow Trucks', 'allowTruck', settings['allowTruck'], isBoolean: true),
          Text(
            l10n.vehicleDeliveryPricing,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFieldRow(l10n.minDeliveryFeeBicycle, 'minDeliveryFeeBicycle', settings['minDeliveryFeeBicycle'], isNumber: true),
          _buildFieldRow(l10n.maxDeliveryFeeBicycle, 'maxDeliveryFeeBicycle', settings['maxDeliveryFeeBicycle'], isNumber: true),
          _buildFieldRow(l10n.minDeliveryFeeMotorcycle, 'minDeliveryFeeMotorcycle', settings['minDeliveryFeeMotorcycle'], isNumber: true),
          _buildFieldRow(l10n.maxDeliveryFeeMotorcycle, 'maxDeliveryFeeMotorcycle', settings['maxDeliveryFeeMotorcycle'], isNumber: true),
          _buildFieldRow(l10n.minDeliveryFeeCar, 'minDeliveryFeeCar', settings['minDeliveryFeeCar'], isNumber: true),
          _buildFieldRow(l10n.maxDeliveryFeeCar, 'maxDeliveryFeeCar', settings['maxDeliveryFeeCar'], isNumber: true),
          _buildFieldRow(l10n.minDeliveryFeeVan, 'minDeliveryFeeVan', settings['minDeliveryFeeVan'], isNumber: true),
          _buildFieldRow(l10n.maxDeliveryFeeVan, 'maxDeliveryFeeVan', settings['maxDeliveryFeeVan'], isNumber: true),
          _buildFieldRow(l10n.minDeliveryFeeTruck, 'minDeliveryFeeTruck', settings['minDeliveryFeeTruck'], isNumber: true),
          _buildFieldRow(l10n.maxDeliveryFeeTruck, 'maxDeliveryFeeTruck', settings['maxDeliveryFeeTruck'], isNumber: true),
          _buildFieldRow(l10n.minDeliveryFeeMotorTricycle, 'minDeliveryFeeMotorTricycle', settings['minDeliveryFeeMotorTricycle'], isNumber: true),
          _buildFieldRow(l10n.maxDeliveryFeeMotorTricycle, 'maxDeliveryFeeMotorTricycle', settings['maxDeliveryFeeMotorTricycle'], isNumber: true),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildFieldRow(l10n.maxDeliveryFee, 'maxDeliveryFee', settings['maxDeliveryFee'], isNumber: true),
          _buildFieldRow(l10n.minOrderKm, 'minOrderKm', settings['minOrderKm'], isNumber: true),
          _buildFieldRow(l10n.minDistanceFixedPrice, 'minDistanceFixedPrice', settings['minDistanceFixedPrice'], isNumber: true),
          _buildFieldRow(l10n.maxDeliveryRadiusKm, 'maxDeliveryRadiusKm', settings['maxDeliveryRadiusKm'], isNumber: true),
          _buildFieldRow(l10n.driverSearchRadiusKm, 'driverSearchRadiusKm', settings['driverSearchRadiusKm'], isNumber: true),
          _buildFieldRow(l10n.driverSearchRadiusStepKm, 'driverSearchRadiusStepKm', settings['driverSearchRadiusStepKm'], isNumber: true),
          _buildFieldRow(l10n.driverSearchRadiusMaxKm, 'driverSearchRadiusMaxKm', settings['driverSearchRadiusMaxKm'], isNumber: true),
          _buildFieldRow(l10n.driverSearchMaxAttempts, 'driverSearchMaxAttempts', settings['driverSearchMaxAttempts'], isNumber: true),
          _buildFieldRow(l10n.fallbackOrderDistanceKm, 'fallbackOrderDistanceKm', settings['fallbackOrderDistanceKm'], isNumber: true),
          _buildFieldRow(l10n.driverAcceptTimeoutSecs, 'driverAcceptTimeoutSecs', settings['driverAcceptTimeoutSecs'], isNumber: true),
          _buildFieldRow(l10n.autoCancelPendingMins, 'autoCancelPendingMins', settings['autoCancelPendingMins'], isNumber: true),
          _buildFieldRow(l10n.maxDispatchBatchSize, 'maxDispatchBatchSize', settings['maxDispatchBatchSize'], isNumber: true),
          _buildFieldRow(l10n.maxKmForBicycle, 'maxKmForBicycle', settings['maxKmForBicycle'], isNumber: true),
        ],
      ),
    );
  }

  Widget _buildLoyaltyTab(AppLocalizations l10n, Map<String, dynamic> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFieldRow(l10n.coinValue, 'coinValue', settings['coinValue'], isNumber: true),
          _buildFieldRow(l10n.amountSpentPerCoin, 'amountSpentPerCoin', settings['amountSpentPerCoin'], isNumber: true),
          _buildFieldRow(l10n.minCoinsToUse, 'minCoinsToUse', settings['minCoinsToUse'], isNumber: true),
        ],
      ),
    );
  }

  Widget _buildDriversTab(AppLocalizations l10n, Map<String, dynamic> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFieldRow(l10n.driverShiftsEnabled, 'driverShiftsEnabled', settings['driverShiftsEnabled'], isBoolean: true),
          _buildFieldRow(l10n.driverBonusActive, 'driverBonusActive', settings['driverBonusActive'], isBoolean: true),
          _buildFieldRow(l10n.driverBonusPaidByCustomer, 'driverBonusPaidByCustomer', settings['driverBonusPaidByCustomer'], isBoolean: true),
          _buildFieldRow(l10n.driverBonusAmount, 'driverBonusAmount', settings['driverBonusAmount'], isNumber: true),
          _buildFieldRow(l10n.bronzeTierBonusPerKm, 'bronzeTierBonusPerKm', settings['bronzeTierBonusPerKm'], isNumber: true),
          _buildFieldRow(l10n.silverTierBonusPerKm, 'silverTierBonusPerKm', settings['silverTierBonusPerKm'], isNumber: true),
          _buildFieldRow(l10n.goldTierBonusPerKm, 'goldTierBonusPerKm', settings['goldTierBonusPerKm'], isNumber: true),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildFieldRow(l10n.driverSettlementOrderThreshold, 'driverSettlementOrderThreshold', settings['driverSettlementOrderThreshold'], isNumber: true),
        ],
      ),
    );
  }

  Widget _buildAppLegalTab(AppLocalizations l10n, Map<String, dynamic> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFieldRow(l10n.isMaintenanceMode, 'isMaintenanceMode', settings['isMaintenanceMode'], isBoolean: true),
          const Divider(height: 32),
          _buildFieldRow(l10n.androidMinVersion, 'androidMinVersion', settings['androidMinVersion']),
          _buildFieldRow(l10n.androidLatestVersion, 'androidLatestVersion', settings['androidLatestVersion']),
          _buildFieldRow(l10n.androidForceUpdate, 'androidForceUpdate', settings['androidForceUpdate'], isBoolean: true),
          _buildFieldRow(l10n.androidStoreUrl, 'androidStoreUrl', settings['androidStoreUrl']),
          const Divider(height: 32),
          _buildFieldRow(l10n.iosMinVersion, 'iosMinVersion', settings['iosMinVersion']),
          _buildFieldRow(l10n.iosLatestVersion, 'iosLatestVersion', settings['iosLatestVersion']),
          _buildFieldRow(l10n.iosForceUpdate, 'iosForceUpdate', settings['iosForceUpdate'], isBoolean: true),
          _buildFieldRow(l10n.iosStoreUrl, 'iosStoreUrl', settings['iosStoreUrl']),
          const Divider(height: 32),
          _buildFieldRow(l10n.supportEmail, 'supportEmail', settings['supportEmail']),
          _buildFieldRow(l10n.supportPhone, 'supportPhone', settings['supportPhone']),
          _buildFieldRow(l10n.supportWhatsapp, 'supportWhatsapp', settings['supportWhatsapp']),
          _buildFieldRow(l10n.termsUrl, 'termsUrl', settings['termsUrl']),
          _buildFieldRow(l10n.privacyUrl, 'privacyUrl', settings['privacyUrl']),
        ],
      ),
    );
  }

  Widget _buildDataRetentionTab(AppLocalizations l10n, Map<String, dynamic> settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFieldRow(l10n.retentionOrdersDays, 'retentionOrdersDays', settings['retentionOrdersDays'], isNumber: true),
          _buildFieldRow(l10n.retentionArchivedChatsDays, 'retentionArchivedChatsDays', settings['retentionArchivedChatsDays'], isNumber: true),
          _buildFieldRow(l10n.retentionNotificationsDays, 'retentionNotificationsDays', settings['retentionNotificationsDays'], isNumber: true),
          _buildFieldRow(l10n.retentionExpiredSessionsDays, 'retentionExpiredSessionsDays', settings['retentionExpiredSessionsDays'], isNumber: true),
          _buildFieldRow(l10n.retentionAuditLogsDays, 'retentionAuditLogsDays', settings['retentionAuditLogsDays'], isNumber: true),
          _buildFieldRow(l10n.retentionAbandonedCartsDays, 'retentionAbandonedCartsDays', settings['retentionAbandonedCartsDays'], isNumber: true),
          _buildFieldRow(l10n.retentionWalletTransactionsDays, 'retentionWalletTransactionsDays', settings['retentionWalletTransactionsDays'], isNumber: true),
          _buildFieldRow(l10n.retentionStatisticsDays, 'retentionStatisticsDays', settings['retentionStatisticsDays'], isNumber: true),
        ],
      ),
    );
  }

  Widget _buildAssetsTab(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> settings,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageUploadItem(
            context: context,
            label: l10n.homeCover,
            imageUrl: settings['homeCoverUrl'],
            type: 'home-cover',
            isWide: true,
          ),
          const Divider(height: 48),
          Row(
            children: [
              Expanded(
                child: _buildImageUploadItem(
                  context: context,
                  label: l10n.motorcycleIcon,
                  imageUrl: settings['motorcycleIconUrl'],
                  type: 'motorcycle',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildImageUploadItem(
                  context: context,
                  label: l10n.carIcon,
                  imageUrl: settings['carIconUrl'],
                  type: 'car',
                ),
              ),
            ],
          ),
          const Divider(height: 48),
          _buildImageUploadItem(
            context: context,
            label: l10n.deliveryBannerIcon,
            imageUrl: settings['deliveryBannerIconUrl'],
            type: 'delivery-banner',
            isWide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadItem({
    required BuildContext context,
    required String label,
    required String? imageUrl,
    required String type,
    bool isWide = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              width: isWide ? double.infinity : 150,
              height: isWide ? 200 : 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: ImageUtils.formatImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(
                          LucideIcons.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      )
                    : const Center(
                        child: Icon(
                          LucideIcons.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            PositionedDirectional(
              end: 8,
              bottom: 8,
              child: FloatingActionButton.small(
                heroTag: type,
                onPressed: () => _pickAndUploadImage(context, type),
                backgroundColor: AppColors.primary,
                child: Icon(
                  LucideIcons.camera,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, String type) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null &&
          result.files.single.path != null &&
          mounted) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        ref
            .read(settingsProvider.notifier)
            .uploadSettingImage(type, bytes, result.files.single.name);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }
}
