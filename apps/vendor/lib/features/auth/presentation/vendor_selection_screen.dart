import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:vendor/core/utils/error_utils.dart';

class VendorSelectionScreen extends ConsumerWidget {
  const VendorSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(vendorMembershipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.selectVendor),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.invalidate(vendorMembershipsProvider);
            },
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            tooltip: AppLocalizations.of(context)!.logout,
          ),
        ],
      ),
      body: membershipsAsync.when(
        data: (memberships) {
          if (memberships.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.noVendorMembershipsFound),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: AppLocalizations.of(context)!.logout,
                    onPressed: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memberships.length,
            itemBuilder: (context, index) {
              final member = memberships[index] as Map<String, dynamic>;
              final vendorId = member['vendorId']?.toString() ?? '';
              final role = member['role']?.toString() ?? 'STAFF';
              final vendor = member['vendor'] is Map
                  ? member['vendor'] as Map
                  : null;
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              final storeName = vendor == null
                  ? null
                  : (isAr
                          ? (vendor['storeNameAr'] ?? vendor['storeName'])
                          : (vendor['storeName'] ?? vendor['storeNameAr']))
                      ?.toString();
              final storeLogo =
                  (vendor?['logo'] ?? vendor?['logoUrl'])?.toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: AppNetworkAvatar(
                    imageUrl: ImageUtils.formatImageUrl(storeLogo),
                    size: 40,
                    borderRadius: 10,
                    fallbackIcon: LucideIcons.store,
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                  title: Text(
                    (storeName != null && storeName.trim().isNotEmpty)
                        ? storeName.trim()
                        : AppLocalizations.of(context)!.vendorIdParam(vendorId),
                  ),
                  subtitle: Text(AppLocalizations.of(context)!.roleParam(role)),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () async {
                    await ref.read(activeVendorProvider.notifier).setActiveVendor(vendorId);
                    if (context.mounted) {
                      context.go('/dashboard');
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(ErrorUtils.translate(context, err))),
      ),
    );
  }
}
