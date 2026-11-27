import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/dashboard/presentation/widgets/driver_live_map_card.dart';
import 'package:driver/features/order_execution/presentation/order_execution_provider.dart';
import 'package:driver/core/providers/driver_breaks_provider.dart';
import 'package:driver/core/providers/driver_dispatch_coordinator.dart';
import 'package:driver/features/ranking/presentation/driver_ranking_provider.dart';
import 'package:driver/features/ranking/presentation/pages/driver_ranking_screen.dart';
import 'package:driver/features/statistics/presentation/driver_statistics_screen.dart';
import 'package:api/api.dart' show DriverTier;
import 'package:driver/features/profile/presentation/pages/nearby_vendors_map_screen.dart';
import 'package:driver/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:driver/features/wallet/presentation/wallet_provider.dart';
import 'package:driver/features/inbox/presentation/pages/inbox_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/profile/presentation/settings_provider.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:core/core.dart';
import 'package:driver/core/providers/app_preferences_provider.dart';
import 'package:driver/core/providers/notification_router.dart';
import 'package:data/providers.dart';

final pendingAssistOffersProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  try {
    final response = await ref
        .read(driverOrdersRepositoryProvider)
        .getPendingAssistOffers();
    if (response is List) return response;
    if (response is Map && response['items'] is List)
      return response['items'] as List;
    if (response is Map && response['data'] is List)
      return response['data'] as List;
    return [];
  } catch (_) {
    return [];
  }
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isRefreshing = false;
  final Set<String> _respondingAssistOfferIds = <String>{};
  late final AnimationController _refreshAnimController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ref.read(driverDashboardTabProvider);
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleFullRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshAnimController.repeat();
    try {
      HapticFeedback.lightImpact();
      ref.read(coreSocketServiceProvider).connect();
      await ref
          .read(driverDispatchCoordinatorProvider)
          .checkPendingDispatches(checkOnline: false);
      await Future.wait([
        ref.read(driverProfileProvider.notifier).fetchProfile(),
        ref.read(orderExecutionProvider.notifier).refresh(),
      ]);
      ref.invalidate(breaksOverviewProvider);
      ref.invalidate(driverRankingSummaryProvider);
      ref.invalidate(pendingAssistOffersProvider);
    } catch (e) {
      debugPrint('Manual dashboard refresh failed: $e');
    } finally {
      if (mounted) {
        _refreshAnimController.stop();
        _refreshAnimController.reset();
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(driverDashboardTabProvider, (previous, next) {
      if (!mounted) return;
      if (_selectedIndex != next) {
        setState(() {
          _selectedIndex = next;
        });
      }
      if (next == 1) {
        ref.invalidate(driverWalletProvider);
      }
    });

    final profileState = ref.watch(driverProfileProvider);
    final appPreferences = ref.watch(appPreferencesProvider);
    final inboxCounts = ref.watch(inboxCountsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = appPreferences.locale.languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isRefreshing ? null : _handleFullRefresh,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: RotationTransition(
                    turns: _refreshAnimController,
                    child: Icon(
                      LucideIcons.refreshCw,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InkWell(
              onTap: () =>
                  ref.read(appPreferencesProvider.notifier).toggleTheme(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  isDark ? LucideIcons.sun : LucideIcons.moon,
                  size: 16,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  final nextLang = isArabic ? 'en' : 'ar';
                  ref.read(appPreferencesProvider.notifier).setLocale(nextLang);
                  try {
                    context.setLocale(Locale(nextLang));
                  } catch (_) {}
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.languages,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isArabic ? 'EN' : 'AR',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: inboxCounts.notificationsUnread > 0,
              label: Text(
                '${inboxCounts.notificationsUnread}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              child: const Icon(LucideIcons.bell),
            ),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              context.push('/notifications');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final isOnlineAsync = ref.watch(isOnlineStreamProvider);
              final isOnline = isOnlineAsync.asData?.value ?? true;
              return OfflineStatusBanner(
                isOnline: isOnline,
                onRetry: _handleFullRefresh,
                useSafeArea: false,
              );
            },
          ),
          Expanded(child: _buildBody(profileState, l10n)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            _selectedIndex = index;
          });
          ref.read(driverDashboardTabProvider.notifier).setTab(index);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.home),
            label: l10n.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.wallet),
            label: l10n.wallet,
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: inboxCounts.chatUnread > 0,
              label: Text(
                '${inboxCounts.chatUnread}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              child: const Icon(LucideIcons.messageSquare),
            ),
            label: l10n.inbox,
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.user),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<dynamic> profileState, AppLocalizations l10n) {
    if (_selectedIndex == 0) {
      return _buildHomeTab(profileState, l10n);
    } else if (_selectedIndex == 1) {
      return const WalletScreen();
    } else if (_selectedIndex == 2) {
      return const InboxScreen();
    } else {
      return _buildProfileTab(profileState, l10n);
    }
  }

  Widget _buildProfileError(dynamic error, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              ErrorUtils.translate(context, error),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              ApiErrorMapper.fromError(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(driverProfileProvider.notifier).fetchProfile(),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(
    AsyncValue<dynamic> profileState,
    AppLocalizations l10n,
  ) {
    return profileState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildProfileError(err, l10n),
      data: (profileData) {
        if (profileData == null) {
          return Center(child: Text(l10n.pendingApproval));
        }

        final data =
            profileData is Map &&
                profileData.containsKey('data') &&
                profileData['data'] is Map
            ? profileData['data']
            : (profileData ?? {});

        final user = data['user'] ?? {};
        final avatarPath = (data['avatar'] ?? user['avatar'])?.toString();
        final avatarUrl = avatarPath != null && avatarPath.trim().isNotEmpty
            ? ImageUtils.formatImageUrl(avatarPath.trim())
            : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      XFile? pickedFile;
                      try {
                        pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                      } catch (e) {
                        if (mounted) {
                          MediaPermissionHelper.handlePickerError(
                            e,
                            context: context,
                          );
                        }
                        return;
                      }
                      if (pickedFile != null) {
                        String? uploadPath;
                        try {
                          final cropped = await ImageCropper().cropImage(
                            sourcePath: pickedFile.path,
                            aspectRatio: const CropAspectRatio(
                              ratioX: 1,
                              ratioY: 1,
                            ),
                            compressQuality: 85,
                            maxWidth: 1024,
                            maxHeight: 1024,
                            uiSettings: [
                              AndroidUiSettings(
                                toolbarTitle: 'Crop Avatar',
                                toolbarColor: const Color(0xFFD4920E),
                                toolbarWidgetColor: Colors.white,
                                activeControlsWidgetColor: const Color(
                                  0xFFD4920E,
                                ),
                                initAspectRatio: CropAspectRatioPreset.square,
                                lockAspectRatio: true,
                                cropStyle: CropStyle.circle,
                              ),
                              IOSUiSettings(
                                title: 'Crop Avatar',
                                aspectRatioLockEnabled: true,
                                resetAspectRatioEnabled: false,
                                cropStyle: CropStyle.circle,
                              ),
                            ],
                          );
                          if (cropped == null) {
                            return;
                          }
                          uploadPath = cropped.path;
                        } catch (cropErr) {
                          debugPrint(
                            'Cropping avatar failed, using original: $cropErr',
                          );
                          uploadPath = pickedFile.path;
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.uploadingAvatar)),
                          );
                        }
                        await ref
                            .read(driverProfileProvider.notifier)
                            .uploadAvatar(uploadPath);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.avatarUpdated)),
                          );
                        }
                      }
                    },
                    child: AppNetworkAvatar(
                      imageUrl: avatarUrl != null
                          ? ImageUtils.thumbnailUrl(avatarUrl)
                          : null,
                      size: 100,
                      fallbackIcon: LucideIcons.camera,
                      fallbackIconSize: 38,
                      fallbackText: (data['name'] ?? user['name'] ?? '')
                          .toString(),
                      preferInitialFallback: false,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? AppColors.primary
                          : const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['name'] ?? user['name'] ?? 'Driver Name',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final isAr = l10n.localeName == 'ar';
                      final tierAccent = isDark
                          ? AppColors.primary
                          : const Color(0xFF92400E);
                      final rawTier = (data['tier'] ?? '')
                          .toString()
                          .toUpperCase();
                      final localizedTier = switch (rawTier) {
                        'GOLD' => isAr ? 'الذهبية' : 'Gold',
                        'SILVER' => isAr ? 'الفضية' : 'Silver',
                        'BRONZE' => isAr ? 'البرونزية' : 'Bronze',
                        _ => data['tier']?.toString() ?? l10n.standardTier,
                      };
                      return InkWell(
                        onTap: () => context.push('/ranking'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.award,
                                size: 16,
                                color: tierAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.tierLabel(localizedTier),
                                style: TextStyle(
                                  color: tierAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileStatusCard(data, l10n),
              const SizedBox(height: 32),

              Text(
                l10n.profile,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              _buildProfileNavigationTile(
                icon: LucideIcons.user,
                title: l10n.personalInformation,
                onTap: () => context.push('/profile/identity'),
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.car,
                title: l10n.vehicleInformation,
                onTap: () => context.push('/profile/vehicle'),
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.award,
                title: l10n.localeName == 'ar'
                    ? 'الشارة والتصنيف الأسبوعي'
                    : 'Weekly Badge & Ranking',
                onTap: () => context.push('/ranking'),
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.chartNoAxesCombined,
                title: l10n.localeName == 'ar' ? 'الإحصائيات' : 'Statistics',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DriverStatisticsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.map,
                title: l10n.localeName == 'ar'
                    ? 'خريطة المتاجر القريبة'
                    : 'Nearby Vendors Map',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NearbyVendorsMapScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.history,
                title: l10n.deliveryHistory,
                onTap: () => context.push('/deliveries'),
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.fileText,
                title: l10n.terms,
                onTap: () => context.push(
                  '/legal-document',
                  extra: {'type': 'TERMS_OF_USE', 'title': l10n.terms},
                ),
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.shieldCheck,
                title: l10n.privacy,
                onTap: () => context.push(
                  '/legal-document',
                  extra: {'type': 'PRIVACY_POLICY', 'title': l10n.privacy},
                ),
              ),

              const SizedBox(height: 32),
              Text(
                l10n.performance,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildPerformanceField(
                LucideIcons.award,
                l10n.localeName == 'ar' ? 'الشارة الأسبوعية' : 'Weekly Badge',
                l10n.tierLabel(data['tier'] ?? l10n.standardTier),
              ),
              _buildPerformanceField(
                LucideIcons.package,
                l10n.totalOrders,
                '${data['totalOrders'] ?? 0}',
              ),

              const SizedBox(height: 32),
              _buildSettingsSection(l10n),

              const SizedBox(height: 32),
              PrimaryButton(
                text: l10n.myShifts,
                onPressed: () => context.push('/shifts'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: l10n.logoutUpper,
                onPressed: () async {
                  final confirmed = await AppConfirmDialog.show(
                    context,
                    title: l10n.logout,
                    message: l10n.logoutConfirm,
                    confirmLabel: l10n.logout,
                    cancelLabel: l10n.cancel,
                    icon: LucideIcons.logOut,
                    confirmIcon: LucideIcons.logOut,
                    isDestructive: true,
                  );
                  if (confirmed == true) {
                    ref.read(authProvider.notifier).logout();
                  }
                },
                backgroundColor: AppColors.error,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileStatusCard(
    Map<dynamic, dynamic> data,
    AppLocalizations l10n,
  ) {
    final status = data['status'] ?? 'PENDING';
    IconData icon;
    Color color;
    String text;
    switch (status) {
      case 'PENDING':
        icon = LucideIcons.clock;
        color = Colors.orange;
        text = l10n
            .pendingApproval; // Assuming this exists or falls back to literal
        break;
      case 'SUSPENDED':
        icon = LucideIcons.ban;
        color = AppColors.error;
        text = l10n.statusSuspended;
        break;
      default:
        icon = LucideIcons.checkCircle;
        color = AppColors.success;
        text = l10n.statusApproved;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileStatusLabel,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileNavigationTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const AppAdaptiveChevron(size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceField(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(AppLocalizations l10n) {
    final settingsState = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.notificationSettings,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        settingsState.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text(ErrorUtils.translate(context, err)),
          data: (data) {
            final s = data is Map && data.containsKey('data')
                ? data['data']
                : (data ?? {});
            return Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.pushNotifications),
                  value: s['pushEnabled'] ?? true,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .updateNotificationSetting(pushEnabled: val),
                ),
                SwitchListTile(
                  title: Text(l10n.orderUpdates),
                  value: s['orderUpdates'] ?? true,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .updateNotificationSetting(orderUpdates: val),
                ),
                SwitchListTile(
                  title: Text(l10n.chatMessages),
                  value: s['chatMessages'] ?? true,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .updateNotificationSetting(chatMessages: val),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeTab(
    AsyncValue<dynamic> profileState,
    AppLocalizations l10n,
  ) {
    final currency =
        ref.watch(configurationProvider).value?['currency']?.toString() ??
        'EGP';
    final isNetworkOnline =
        ref.watch(isOnlineStreamProvider).asData?.value ?? true;

    return profileState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildProfileError(error, l10n),
      data: (profileData) {
        final data =
            profileData is Map &&
                profileData.containsKey('data') &&
                profileData['data'] is Map
            ? profileData['data']
            : (profileData ?? {});

        final String currentStatus = (data['status'] ?? 'OFFLINE')
            .toString()
            .toUpperCase()
            .trim();
        final statusInfo = DriverStatusPresentation.resolve(
          currentStatus,
          l10n,
        );
        final bool showBreaks =
            currentStatus == 'ONLINE' ||
            currentStatus == 'BUSY' ||
            currentStatus == 'ON_BREAK';
        final bool showActiveTools =
            statusInfo.isWorkingShift && !statusInfo.isOnBreak;
        final String vehicleType =
            (data['vehicleType'] ?? data['vehicle_type'])?.toString().trim() ??
            'MOTORCYCLE';
        final String? plateNumber =
            (data['vehiclePlate'] ?? data['plateNumber'])?.toString().trim();
        final String? driverName = data['name']?.toString().trim();

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCompactStatusBar(
              statusInfo: statusInfo,
              isNetworkOnline: isNetworkOnline,
              vehicleType: vehicleType,
              plateNumber: plateNumber,
              l10n: l10n,
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DriverLiveMapCard(
                    driverStatus: currentStatus,
                    vehicleType: vehicleType,
                    plateNumber: plateNumber,
                    driverName: driverName,
                    expandToFill: true,
                  ),
                  if (showActiveTools)
                    Positioned(
                      top: 10,
                      left: 12,
                      right: 12,
                      child: _buildPendingAssistOffers(l10n),
                    ),
                ],
              ),
            ),
            Container(
              key: const ValueKey('driver_dashboard_cockpit_dock'),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: isDark ? 0.25 : 0.45),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.12,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildActiveTaskPlaceholder(currentStatus, l10n),
                      const SizedBox(height: 8),
                      _buildStatsRow(data, currency, l10n),
                      const SizedBox(height: 8),
                      if (showBreaks)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildWeeklyRankingNavigationCard(
                                  data,
                                  l10n,
                                  compact: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildBreakNavigationCard(
                                  currentStatus,
                                  l10n,
                                  compact: true,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        _buildWeeklyRankingNavigationCard(data, l10n),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactStatusBar({
    required DriverStatusPresentation statusInfo,
    required bool isNetworkOnline,
    required String vehicleType,
    required String? plateNumber,
    required AppLocalizations l10n,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = l10n.localeName == 'ar';
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final Color effectiveAccent = isNetworkOnline
        ? statusInfo.accent
        : AppColors.error;
    final String effectiveLabel = isNetworkOnline
        ? statusInfo.label
        : l10n.driverStatusOffline;

    final vehicleNorm =
        VehicleTypeHelper.normalize(vehicleType) ??
        VehicleTypeHelper.motorcycle;
    final resolvedVehicleType = vehicleNorm.isEmpty
        ? VehicleTypeHelper.motorcycle
        : vehicleNorm;
    final vehicleLabel = VehicleTypeHelper.label(
      resolvedVehicleType,
      isArabic: isAr,
    );
    final vehicleIcon = VehicleTypeHelper.icon(resolvedVehicleType);
    final plate = plateNumber?.trim() ?? '';
    final vehicleSummary = plate.isNotEmpty
        ? '$vehicleLabel • $plate'
        : vehicleLabel;

    return Container(
      key: const ValueKey('driver_dashboard_status_card'),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).dividerColor.withValues(alpha: isDark ? 0.35 : 0.6),
            width: 1,
          ),
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: effectiveAccent.withValues(alpha: isDark ? 0.16 : 0.11),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: effectiveAccent.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: effectiveAccent,
                      shape: BoxShape.circle,
                      boxShadow: statusInfo.isWorkingShift && isNetworkOnline
                          ? [
                              BoxShadow(
                                color: effectiveAccent.withValues(alpha: 0.55),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    effectiveLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: effectiveAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: isDark ? 0.07 : 0.05),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: onSurface.withValues(alpha: isDark ? 0.1 : 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vehicleIcon,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            vehicleSummary,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: onSurface.withValues(alpha: 0.85),
                            ),
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
      ),
    );
  }

  Widget _buildPendingAssistOffers(AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, _) {
        final offersAsync = ref.watch(pendingAssistOffersProvider);
        return offersAsync.when(
          data: (offers) {
            if (offers.isEmpty) return const SizedBox.shrink();
            final firstOffer = offers.first as Map<dynamic, dynamic>;
            final offerId = firstOffer['id']?.toString() ?? '';
            final order = firstOffer['order'] is Map
                ? firstOffer['order'] as Map
                : {};
            final orderNumber = order['orderNumber']?.toString() ?? '';
            final reason = firstOffer['reason']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.users,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.localeName == 'ar'
                              ? 'عرض مساعدة توصيل - كابتن إضافي'
                              : 'Assistant Delivery Offer',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.localeName == 'ar'
                        ? 'طلب مساعدة لشحنة ${orderNumber.isNotEmpty ? '#$orderNumber ' : ''}($reason). يمكنك الانضمام ومشاركة التوصيل ككابتن مساعد.'
                        : 'Assist offer for cargo ${orderNumber.isNotEmpty ? '#$orderNumber ' : ''}($reason). Join as assistant driver.',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _respondingAssistOfferIds.contains(offerId)
                              ? null
                              : () async {
                                  setState(
                                    () =>
                                        _respondingAssistOfferIds.add(offerId),
                                  );
                                  try {
                                    await ref
                                        .read(driverOrdersRepositoryProvider)
                                        .respondToAssistOffer(
                                          offerId,
                                          accept: false,
                                        );
                                    if (!mounted) return;
                                    ref.invalidate(pendingAssistOffersProvider);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ErrorUtils.translate(context, e),
                                          ),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () => _respondingAssistOfferIds.remove(
                                          offerId,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            l10n.localeName == 'ar' ? 'تخطي' : 'Decline',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _respondingAssistOfferIds.contains(offerId)
                              ? null
                              : () async {
                                  setState(
                                    () =>
                                        _respondingAssistOfferIds.add(offerId),
                                  );
                                  try {
                                    await ref
                                        .read(driverOrdersRepositoryProvider)
                                        .respondToAssistOffer(
                                          offerId,
                                          accept: true,
                                        );
                                    if (!mounted) return;
                                    ref.invalidate(pendingAssistOffersProvider);
                                    ref.invalidate(driverProfileProvider);
                                    await ref
                                        .read(orderExecutionProvider.notifier)
                                        .refresh();
                                    if (context.mounted) {
                                      context.push('/order-execution');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ErrorUtils.translate(context, e),
                                          ),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () => _respondingAssistOfferIds.remove(
                                          offerId,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            l10n.localeName == 'ar'
                                ? 'قبول العرض'
                                : 'Accept Offer',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildWeeklyRankingNavigationCard(
    Map<dynamic, dynamic> profileData,
    AppLocalizations l10n, {
    bool compact = false,
  }) {
    final isAr = l10n.localeName == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rankingAsync = ref.watch(driverRankingSummaryProvider);
    final summary = rankingAsync.asData?.value;

    final rawTierStr =
        (summary?.currentTier.name ?? profileData['tier'] ?? 'BRONZE')
            .toString()
            .toUpperCase();
    final tier = rawTierStr == 'GOLD'
        ? DriverTier.GOLD
        : (rawTierStr == 'SILVER' ? DriverTier.SILVER : DriverTier.BRONZE);
    final visuals = DriverTierVisuals.of(tier, isDark: isDark);
    final livePct = summary?.currentWeekProgress?.performancePercentage;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/ranking'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: visuals.border.withValues(alpha: isDark ? 0.65 : 0.8),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 32 : 34,
                height: compact ? 32 : 34,
                decoration: BoxDecoration(
                  color: visuals.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: visuals.border),
                ),
                child: Icon(
                  visuals.icon,
                  color: visuals.primary,
                  size: compact ? 16 : 17,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              visuals.label(isAr),
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: compact ? 13 : 13.5,
                                fontWeight: FontWeight.w800,
                                color: visuals.primary,
                              ),
                            ),
                          ),
                        ),
                        if (livePct != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: visuals.background,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '${livePct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: visuals.primary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      compact
                          ? (isAr ? 'الأداء الأسبوعي' : 'Weekly KPIs')
                          : (isAr
                                ? 'مؤشرات الأداء الأسبوعي (القبول، الإتمام، الانضباط)'
                                : 'Weekly performance KPIs & badge'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const AppAdaptiveChevron(size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakNavigationCard(
    String currentStatus,
    AppLocalizations l10n, {
    bool compact = false,
  }) {
    final breaksAsync = ref.watch(breaksOverviewProvider);
    final overview = breaksAsync.value;
    final bool onBreak =
        currentStatus == 'ON_BREAK' || overview?.active != null;
    final bool hasPending = overview?.pending != null;
    final isAr = l10n.localeName == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color cardBg = onBreak
        ? Colors.amber.shade700.withValues(alpha: 0.14)
        : Theme.of(context).colorScheme.surface;
    final Color borderCol = onBreak
        ? Colors.amber.shade700
        : Theme.of(context).dividerColor.withValues(alpha: isDark ? 0.3 : 0.55);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => context.push('/breaks'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 9 : 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderCol, width: onBreak ? 1.4 : 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 32 : 34,
                height: compact ? 32 : 34,
                decoration: BoxDecoration(
                  color: onBreak
                      ? Colors.amber.shade700
                      : AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.coffee,
                  color: onBreak ? Colors.white : AppColors.primary,
                  size: compact ? 16 : 17,
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              onBreak
                                  ? (isAr ? 'استراحة نشطة' : 'Break Active')
                                  : (hasPending
                                        ? (isAr
                                              ? 'استراحة معلقة'
                                              : 'Break Pending')
                                        : (isAr
                                              ? 'الاستراحات'
                                              : 'Driver Breaks')),
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: compact ? 13 : 13.5,
                                fontWeight: FontWeight.w800,
                                color: onBreak
                                    ? (isDark
                                          ? Colors.amber.shade300
                                          : Colors.amber.shade900)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        if (hasPending && !onBreak) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      onBreak
                          ? (isAr ? 'إنهاء الاستراحة' : 'Manage / End')
                          : (isAr ? 'طلب وسجل' : 'Request & history'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const AppAdaptiveChevron(size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    Map<dynamic, dynamic> data,
    String currency,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = l10n.localeName == 'ar';
    final displayCurrency = (isAr && currency == 'EGP') ? 'ج.م' : currency;
    final totalOrders = data['totalOrders'] ?? data['totalDeliveries'] ?? 0;
    final walletState = ref.watch(driverWalletProvider).asData?.value;
    final rawBalance = walletState?['balance'] ?? data['walletBalance'];
    final double walletBalance = rawBalance is num
        ? rawBalance.toDouble()
        : (double.tryParse(rawBalance?.toString() ?? '0') ?? 0.0);
    final earningsText = data['todaysEarnings'] != null
        ? '${(data['todaysEarnings'] is num ? data['todaysEarnings'] : double.tryParse(data['todaysEarnings'].toString()) ?? 0).toStringAsFixed(2)} $displayCurrency'
        : '${walletBalance.toStringAsFixed(2)} $displayCurrency';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildStatCard(
              data['todaysEarnings'] != null
                  ? l10n.todaysEarnings
                  : (isAr ? 'رصيد المحفظة' : 'Wallet Balance'),
              earningsText,
              LucideIcons.banknote,
              isDark ? AppColors.primary : const Color(0xFF92400E),
              isNumericValue: true,
              onTap: () {
                setState(() => _selectedIndex = 1);
                ref.read(driverDashboardTabProvider.notifier).setTab(1);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              l10n.completedOrders,
              l10n.countOrders('$totalOrders'),
              LucideIcons.checkSquare,
              AppColors.success,
              onTap: () => context.push('/deliveries'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isNumericValue = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor = Theme.of(
      context,
    ).dividerColor.withValues(alpha: isDark ? 0.28 : 0.55);

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.14 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.68),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: isNumericValue
                      ? Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            value,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        )
                      : Text(
                          value,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: content,
            )
          : content,
    );
  }

  Widget _buildActiveTaskPlaceholder(String status, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final activeExecOrder = ref.watch(orderExecutionProvider).asData?.value;
    final hasAssignedExecution =
        activeExecOrder is Map && activeExecOrder['id'] != null;

    if (status != 'ON_DELIVERY' && !hasAssignedExecution) {
      return Container(
        key: const ValueKey('driver_dashboard_no_active_tasks'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(
              context,
            ).dividerColor.withValues(alpha: isDark ? 0.28 : 0.55),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.map,
                size: 17,
                color: onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.noActiveTasks,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    l10n.noActiveTasksSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () => context.push('/order-execution'),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.navigation,
                  color: AppColors.onPrimary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeExecOrder is Map &&
                              OrderTypeHelper.isRide(activeExecOrder)
                          ? (l10n.localeName == 'ar'
                                ? 'رحلة نشطة قيد التنفيذ'
                                : 'Active Ride in Progress')
                          : l10n.activeDeliveryInProgress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      l10n.tapToViewRoute,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.onPrimary.withValues(alpha: 0.82),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const AppAdaptiveChevron(color: AppColors.onPrimary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
