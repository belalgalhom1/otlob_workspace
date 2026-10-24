
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:go_router/go_router.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:driver/core/providers/driver_breaks_provider.dart';
import 'package:driver/features/statistics/presentation/driver_statistics_screen.dart';
import 'package:driver/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:driver/features/inbox/presentation/pages/inbox_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:driver/features/auth/presentation/auth_provider.dart';
import 'package:driver/features/profile/presentation/settings_provider.dart';
import 'package:driver/core/providers/configuration_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core/core.dart';
import 'package:driver/core/providers/app_preferences_provider.dart';
import 'package:data/providers.dart';

final pendingAssistOffersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final response = await ref.read(driverOrdersRepositoryProvider).getPendingAssistOffers();
    if (response is List) return response;
    if (response is Map && response['items'] is List) return response['items'] as List;
    if (response is Map && response['data'] is List) return response['data'] as List;
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

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  bool _breakStatusSynced = false;

  @override
  Widget build(BuildContext context) {
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
            icon: Badge(
              isLabelVisible: inboxCounts.notificationsUnread > 0,
              label: Text(
                '${inboxCounts.notificationsUnread}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              child: const Icon(LucideIcons.bell),
            ),
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
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              ErrorUtils.translate(context, error),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              ApiErrorMapper.fromError(error),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
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

  Widget _buildProfileTab(AsyncValue<dynamic> profileState, AppLocalizations l10n) {
    return profileState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildProfileError(err, l10n),
      data: (profileData) {
        if (profileData == null) {
          return Center(child: Text(l10n.pendingApproval));
        }

        final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
            ? profileData['data']
            : (profileData ?? {});
            
        final user = data['user'] ?? {};
        final avatarPath = data['avatar'] ?? user['avatar'];
        final avatarUrl = avatarPath != null
            ? '${ref.read(dioProvider).options.baseUrl}$avatarPath'
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
                icon: LucideIcons.history,
                title: l10n.deliveryHistory,
                onTap: () => context.push('/deliveries'),
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.fileText,
                title: l10n.terms,
                onTap: () => _openLegalUrl('termsUrl'),
              ),
              const SizedBox(height: 12),
              _buildProfileNavigationTile(
                icon: LucideIcons.shieldCheck,
                title: l10n.privacy,
                onTap: () => _openLegalUrl('privacyUrl'),
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

  Future<void> _openLegalUrl(String key) async {
    final config = ref.read(configurationProvider).value;
    final legal = config?['legal'];
    final url = (legal is Map ? legal[key]?.toString() : null)?.trim() ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          error: (err, _) => Text(ErrorUtils.translate(context, err)),
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
      error: (error, _) => _buildProfileError(error, l10n),
      data: (profileData) {
        final data = profileData is Map && profileData.containsKey('data') && profileData['data'] is Map
            ? profileData['data']
            : (profileData ?? {});
            
        final String currentStatus = data['status'] ?? 'OFFLINE';
        final bool isOnline = currentStatus == 'ONLINE' || currentStatus == 'ON_DELIVERY';
        final bool showBreaks = currentStatus == 'ONLINE' || currentStatus == 'ON_BREAK';

        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(driverProfileProvider.notifier).fetchProfile();
            ref.invalidate(breaksOverviewProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(currentStatus, isOnline, l10n),
                if (showBreaks) ...[
                  const SizedBox(height: 24),
                  _buildBreakSection(currentStatus, l10n),
                ],
                const SizedBox(height: 24),
                _buildStatsRow(data, currency, l10n),
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
    final bool onBreak = status == 'ON_BREAK';
    final Color accent = onBreak
        ? Colors.amber.shade700
        : (isOnline ? AppColors.success : AppColors.error);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            onBreak
                ? LucideIcons.coffee
                : (isOnline ? LucideIcons.checkCircle : LucideIcons.xCircle),
            size: 48,
            color: accent,
          ),
          const SizedBox(height: 16),
          Text(
            onBreak
                ? l10n.youAreOnBreak
                : (isOnline ? l10n.youAreOnline : l10n.youAreOffline),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            onBreak
              ? l10n.onBreakSubtitle
              : (isOnline
                ? l10n.waitingForRequests
                : l10n.goOnlineToReceive),
            textAlign: TextAlign.center,
          ),
          // NOTE: no manual online/offline — status is fully shift-driven
          // (starting a shift goes ONLINE, ending it goes OFFLINE).
          // Offline drivers get a shortcut into their shifts instead.
          // Pending Assist Offers Section
          if (isOnline && !onBreak) ...[
            Consumer(builder: (context, ref, _) {
              final offersAsync = ref.watch(pendingAssistOffersProvider);
              return offersAsync.when(
                data: (offers) {
                  if (offers.isEmpty) return const SizedBox.shrink();
                  final firstOffer = offers.first as Map<dynamic, dynamic>;
                  final offerId = firstOffer['id']?.toString() ?? '';
                  final order = firstOffer['order'] is Map ? firstOffer['order'] as Map : {};
                  final orderNumber = order['orderNumber']?.toString() ?? '';
                  final reason = firstOffer['reason']?.toString() ?? '';
                  

                  return Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.users, color: AppColors.primary, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.localeName == 'ar'
                                    ? 'عرض مساعدة توصيل - كابتن إضافي'
                                    : 'Assistant Delivery Offer',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.localeName == 'ar'
                              ? 'طلب مساعدة لشحنة ${orderNumber.isNotEmpty ? '#$orderNumber ' : ''}($reason). يمكنك الانضمام ومشاركة التوصيل ككابتن مساعد.'
                              : 'Assist offer for cargo ${orderNumber.isNotEmpty ? '#$orderNumber ' : ''}($reason). Join as assistant driver.',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await ref.read(driverOrdersRepositoryProvider).respondToAssistOffer(offerId, accept: false);
                                  ref.invalidate(pendingAssistOffersProvider);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(l10n.localeName == 'ar' ? 'تخطي' : 'Decline'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  await ref.read(driverOrdersRepositoryProvider).respondToAssistOffer(offerId, accept: true);
                                  ref.invalidate(pendingAssistOffersProvider);
                                  if (context.mounted) {
                                    context.push('/order-execution');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(l10n.localeName == 'ar' ? 'قبول العرض' : 'Accept Offer'),
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
            }),
          ],

          if (!onBreak && !isOnline) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: PrimaryButton(
                onPressed: () => context.push('/shifts'),
                text: l10n.localeName == 'ar'
                    ? 'الذهاب إلى الورديات لبدء العمل'
                    : 'Go to Shifts to start working',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _breakReasonLabel(AppLocalizations l10n, String? reason) {
    switch ((reason ?? '').toUpperCase()) {
      case 'PRAYER':
        return l10n.breakReasonPrayer;
      case 'MEAL':
        return l10n.breakReasonMeal;
      case 'PERSONAL':
        return l10n.breakReasonPersonal;
      case 'OTHER':
        return l10n.breakReasonOther;
      case 'REST':
      default:
        return l10n.breakReasonRest;
    }
  }

  String _breakStatusLabel(AppLocalizations l10n, String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PENDING':
        return l10n.breakStatusPending;
      case 'APPROVED':
        return l10n.breakStatusApproved;
      case 'REJECTED':
        return l10n.breakStatusRejected;
      case 'CANCELLED':
        return l10n.breakStatusCancelled;
      case 'ENDED':
        return l10n.breakStatusEnded;
      default:
        return status?.toString() ?? '';
    }
  }

  String _formatBreakTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return '';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  Future<void> _runBreakAction(
    Future<void> Function() action,
  ) async {
    try {
      await action();
      if (mounted) {
        ref.invalidate(driverProfileProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildBreakSection(String currentStatus, AppLocalizations l10n) {
    final breaksAsync = ref.watch(breaksOverviewProvider);
    return breaksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => OutlinedButton.icon(
        onPressed: () => ref.invalidate(breaksOverviewProvider),
        icon: const Icon(LucideIcons.refreshCw, size: 16),
        label: Text(l10n.retry),
      ),
      data: (overview) {
        // The break overview is fresher than the cached profile: if they
        // disagree about ON_BREAK (approved/ended elsewhere), re-pull the
        // profile once so the status card, tracking, and dispatch sweep
        // follow the server truth.
        final mismatch =
            (overview.active != null) != (currentStatus == 'ON_BREAK');
        if (mismatch && !_breakStatusSynced) {
          _breakStatusSynced = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(driverProfileProvider.notifier).fetchProfile();
            }
          });
        } else if (!mismatch) {
          _breakStatusSynced = false;
        }

        final active = overview.active;
        if (active != null || currentStatus == 'ON_BREAK') {
          return _buildActiveBreakCard(active, l10n);
        }
        final pending = overview.pending;
        if (pending != null) {
          return _buildPendingBreakCard(pending, l10n);
        }
        if (currentStatus != 'ONLINE') return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showRequestBreakSheet(l10n),
              icon: const Icon(LucideIcons.coffee, size: 18),
              label: Text(l10n.takeBreak),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (overview.recent.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.breakHistory,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...overview.recent
                  .take(5)
                  .map((b) => _buildBreakHistoryRow(b, l10n)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActiveBreakCard(
    Map<String, dynamic>? active,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.shade700.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.coffee, color: Colors.amber, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.activeBreak,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _breakReasonLabel(l10n, active?['reason']?.toString()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if ((active?['startedAt']?.toString().isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              _formatBreakTime(active?['startedAt']?.toString()),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
          if ((active?['note']?.toString().isNotEmpty ?? false)) ...[
            const SizedBox(height: 6),
            Text(
              active!['note'].toString(),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: PrimaryButton(
              text: l10n.endBreak,
              onPressed: () => _runBreakAction(
                () => ref.read(breakActionsProvider.notifier).end(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBreakCard(
    Map<String, dynamic> pending,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.hourglass, color: Colors.amber, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.breakRequestPending,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_breakReasonLabel(l10n, pending['reason']?.toString())} • ${l10n.breakRequestPendingSubtitle}',
            style: TextStyle(
              fontSize: 13,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _runBreakAction(
                () => ref.read(breakActionsProvider.notifier).cancel(),
              ),
              child: Text(l10n.cancelBreakRequest),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakHistoryRow(
    Map<String, dynamic> item,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(LucideIcons.coffee, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _breakReasonLabel(l10n, item['reason']?.toString()),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatBreakTime(item['startedAt']?.toString()),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _breakStatusLabel(l10n, item['status']?.toString()),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: (item['status']?.toString() ?? '') == 'REJECTED'
                  ? AppColors.error
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestBreakSheet(AppLocalizations l10n) {
    String reason = 'REST';
    final minutesController = TextEditingController();
    final noteController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.requestBreak,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: InputDecoration(
                  labelText: l10n.breakReason,
                  border: const OutlineInputBorder(),
                ),
                items: const ['PRAYER', 'MEAL', 'REST', 'PERSONAL', 'OTHER']
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(_breakReasonLabel(l10n, r)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => reason = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.breakMinutes,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.breakNote,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: PrimaryButton(
                  text: l10n.requestBreak,
                  onPressed: submitting
                      ? null
                      : () async {
                          setSheetState(() => submitting = true);
                          try {
                            final minutes = int.tryParse(
                              minutesController.text.trim(),
                            );
                            await ref
                                .read(breakActionsProvider.notifier)
                                .start(
                                  reason: reason,
                                  note: noteController.text.trim().isEmpty
                                      ? null
                                      : noteController.text.trim(),
                                  requestedMinutes: minutes,
                                );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                          } catch (e) {
                            setSheetState(() => submitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ErrorUtils.translate(ctx, e),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      minutesController.dispose();
      noteController.dispose();
    });
  }

  Widget _buildStatsRow(Map<dynamic, dynamic> data, String currency, AppLocalizations l10n) {
    final totalOrders = data['totalOrders'] ?? 0;
    final rawBalance = data['walletBalance'];
    final double walletBalance = rawBalance is num ? rawBalance.toDouble() : (double.tryParse(rawBalance?.toString() ?? '0') ?? 0.0);
    final earningsText = data['todaysEarnings'] != null
        ? '${(data['todaysEarnings'] is num ? data['todaysEarnings'] : double.tryParse(data['todaysEarnings'].toString()) ?? 0).toStringAsFixed(2)} $currency'
        : '${walletBalance.toStringAsFixed(2)} $currency';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            data['todaysEarnings'] != null ? l10n.todaysEarnings : (l10n.localeName == 'ar' ? 'رصيد المحفظة' : 'Wallet Balance'),
            earningsText,
            LucideIcons.banknote,
            AppColors.primary,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
        ),
        const SizedBox(width: 16),
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
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final card = Container(
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
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      );
    }
    return card;
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
