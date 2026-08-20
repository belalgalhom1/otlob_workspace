import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/dashboard/presentation/dashboard_screen.dart';
import 'package:vendor/features/auth/presentation/auth_provider.dart';
import 'package:go_router/go_router.dart';

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

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(LucideIcons.store, color: AppColors.primary),
                  title: Text(AppLocalizations.of(context)!.vendorIdParam(vendorId)), // We should probably fetch vendor names, but ID is what we have in membership
                  subtitle: Text(AppLocalizations.of(context)!.roleParam(role)),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () async {
                    await ref.read(activeVendorProvider.notifier).setActiveVendor(vendorId);
                    if (context.mounted) {
                      // Navigate to dashboard
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(AppLocalizations.of(context)!.failedWithError(err.toString()))),
      ),
    );
  }
}
