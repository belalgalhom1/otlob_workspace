import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:driver/features/inbox/presentation/pages/inbox_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/profile/presentation/settings_provider.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/providers/app_preferences_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(driverProfileProvider);
    final appPreferences = ref.watch(appPreferencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = appPreferences.locale.languageCode == 'ar';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(l10n.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: InkWell(
              onTap: () => ref.read(appPreferencesProvider.notifier).toggleTheme(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
            child: InkWell(
              onTap: () => ref.read(appPreferencesProvider.notifier).setLocale(isArabic ? 'en' : 'ar'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
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
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {
              context.push('/notifications');
            },
          ),
        ],
      ),
      body: _buildBody(profileState, l10n),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
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
            icon: const Icon(LucideIcons.messageSquare),
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

  Widget _buildProfileTab(AsyncValue<dynamic> profileState, AppLocalizations l10n) {
    return profileState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(l10n.errorLoadingProfile)),
      data: (profileData) {
        if (profileData == null) {
          return Center(child: Text(l10n.errorLoadingProfile));
        }

        final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
            ? profileData['data']
            : (profileData ?? {});
            
        final user = data['user'] ?? {};
        final avatarPath = data['avatar'] ?? user['avatar'];
        final avatarUrl = avatarPath != null ? 'https://api.otlob-egy.online$avatarPath' : null;

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
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.uploadingAvatar)),
                          );
                        }
                        await ref.read(driverProfileProvider.notifier).uploadAvatar(pickedFile.path);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.avatarUpdated)),
                          );
                        }
                      }
                    },
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: ClipOval(
                        child: avatarUrl != null
                            ? CachedNetworkImage(
                                imageUrl: avatarUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  child: const Center(
                                    child: Icon(LucideIcons.camera, size: 40),
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                child: const Center(
                                  child: Icon(LucideIcons.camera, size: 40),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['name'] ?? user['name'] ?? 'Driver Name',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      l10n.tierLabel(data['tier'] ?? l10n.standardTier),
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileStatusCard(data, l10n),
              const SizedBox(height: 32),
              
              Text(l10n.profile, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
              
              const SizedBox(height: 32),
              Text(l10n.performance, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 16),
              _buildPerformanceField(LucideIcons.star, l10n.rating, '${data['rating'] ?? 500} pts'),
              _buildPerformanceField(LucideIcons.package, l10n.totalOrders, '${data['totalOrders'] ?? 0}'),
              
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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.logout),
                      content: Text(l10n.logoutConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancelUpper),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(authProvider.notifier).logout();
                          },
                          child: Text(l10n.logoutUpper, style: const TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  );
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


  Widget _buildProfileStatusCard(Map<dynamic, dynamic> data, AppLocalizations l10n) {
    final status = data['status'] ?? 'PENDING';
    IconData icon;
    Color color;
    String text;
    switch (status) {
      case 'PENDING':
        icon = LucideIcons.clock;
        color = Colors.orange;
        text = l10n.pendingApproval; // Assuming this exists or falls back to literal
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
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
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

  Widget _buildProfileNavigationTile({required IconData icon, required String title, required VoidCallback onTap}) {
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
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
                Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
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
        Text(l10n.notificationSettings, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 16),
        settingsState.when(
          loading: () => const CircularProgressIndicator(),
          error: (err, _) => Text(l10n.errorLoadingSettings(err.toString())),
          data: (data) {
            final s = data is Map && data.containsKey('data') ? data['data'] : (data ?? {});
            return Column(
              children: [
                SwitchListTile(
                  title: Text(l10n.pushNotifications),
                  value: s['pushEnabled'] ?? true,
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateNotificationSetting(pushEnabled: val),
                ),
                SwitchListTile(
                  title: Text(l10n.orderUpdates),
                  value: s['orderUpdates'] ?? true,
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateNotificationSetting(orderUpdates: val),
                ),
                SwitchListTile(
                  title: Text(l10n.chatMessages),
                  value: s['chatMessages'] ?? true,
                  onChanged: (val) => ref.read(settingsProvider.notifier).updateNotificationSetting(chatMessages: val),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeTab(AsyncValue<dynamic> profileState, AppLocalizations l10n) {
    final currency = ref.watch(configurationProvider.notifier).currency;
    return profileState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l10n.errorLoadingProfile)),
      data: (profileData) {
        final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
            ? profileData['data']
            : (profileData ?? {});
            
        final String currentStatus = data['status'] ?? 'OFFLINE';
        final bool isOnline = currentStatus == 'ONLINE' || currentStatus == 'ON_DELIVERY';

        return RefreshIndicator(
          onRefresh: () => ref.read(driverProfileProvider.notifier).fetchProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(currentStatus, isOnline, l10n),
                const SizedBox(height: 24),
                _buildStatsRow(currency, l10n),
                const SizedBox(height: 24),
                _buildActiveTaskPlaceholder(currentStatus, l10n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(String status, bool isOnline, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline ? AppColors.success : AppColors.error,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isOnline ? LucideIcons.checkCircle : LucideIcons.xCircle,
            size: 48,
            color: isOnline ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            isOnline ? l10n.youAreOnline : l10n.youAreOffline,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOnline 
              ? l10n.waitingForRequests 
              : l10n.goOnlineToReceive,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: PrimaryButton(
              onPressed: () {
                final newStatus = isOnline ? 'OFFLINE' : 'ONLINE';
                ref.read(driverProfileProvider.notifier).updateStatus(newStatus);
              },
              text: isOnline ? l10n.goOffline : l10n.goOnline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String currency, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            l10n.todaysEarnings,
            '0.00 $currency',
            LucideIcons.banknote,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            l10n.completedOrders,
            l10n.countOrders('0'),
            LucideIcons.checkSquare,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTaskPlaceholder(String status, AppLocalizations l10n) {
    if (status != 'ON_DELIVERY') {
      return EmptyStateWidget(
        icon: LucideIcons.map,
        title: l10n.noActiveTasks,
        subtitle: l10n.noActiveTasksSubtitle,
      );
    }
    
    return GestureDetector(
      onTap: () => context.push('/order-execution'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
        children: [
          Icon(LucideIcons.navigation, color: Theme.of(context).colorScheme.onPrimary, size: 48),
          const SizedBox(height: 16),
          Text(
            l10n.activeDeliveryInProgress,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tapToViewRoute,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)),
          ),
        ],
      ),
      ),
    );
  }
}
