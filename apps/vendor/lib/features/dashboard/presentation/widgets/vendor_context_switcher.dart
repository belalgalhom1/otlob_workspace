import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class VendorContextSwitcher extends ConsumerWidget {
  final bool isMobile;
  const VendorContextSwitcher({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(vendorMembershipsProvider);
    final activeVendorId = ref.watch(activeVendorProvider);

    return membershipsAsync.when(
      data: (memberships) {
        if (memberships.length <= 1) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 4, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: isMobile,
              value: activeVendorId,
              icon: isMobile ? const Icon(LucideIcons.chevronDown, size: 16) : const SizedBox.shrink(),
              hint: isMobile 
                  ? Text(AppLocalizations.of(context)!.selectVendor, style: const TextStyle(fontSize: 12)) 
                  : const Icon(LucideIcons.store, size: 20),
              selectedItemBuilder: (context) {
                return memberships.map<Widget>((item) {
                  final vId = (item as Map<String, dynamic>)['vendorId']?.toString() ?? '';
                  if (!isMobile) return const Center(child: Icon(LucideIcons.store, size: 20));
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      (item)['vendor']?['storeName']?.toString() ?? vId,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: memberships.map((item) {
                final member = item as Map<String, dynamic>;
                final vId = member['vendorId']?.toString() ?? '';
                final role = member['role']?.toString() ?? '';
                return DropdownMenuItem<String>(
                  value: vId,
                  child: Text(
                    'Vendor $vId\n($role)',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId != null && newId != activeVendorId) {
                  ref.read(activeVendorProvider.notifier).setActiveVendor(newId);
                }
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
