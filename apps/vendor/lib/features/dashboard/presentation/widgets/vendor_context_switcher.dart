import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
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
              itemHeight: null,
              value: activeVendorId,
              icon: isMobile ? const Icon(LucideIcons.chevronDown, size: 16) : const SizedBox.shrink(),
              hint: isMobile 
                  ? Text(AppLocalizations.of(context)!.selectVendor, style: const TextStyle(fontSize: 12)) 
                  : const Icon(LucideIcons.store, size: 20),
              selectedItemBuilder: (context) {
                final isAr = Localizations.localeOf(context).languageCode == 'ar';
                return memberships.map<Widget>((item) {
                  final member = item as Map<String, dynamic>;
                  final vId = member['vendorId']?.toString() ?? '';
                  final vendor = member['vendor'] as Map<String, dynamic>?;
                  final storeName = (isAr
                          ? (vendor?['storeNameAr'] ?? vendor?['storeName'])
                          : (vendor?['storeName'] ?? vendor?['storeNameAr']))
                      ?.toString();
                  final storeLogo = ImageUtils.resolveVendorLogoUrl(vendor);
                  final display =
                      (storeName != null && storeName.isNotEmpty) ? storeName : vId;
                  if (!isMobile) {
                    return Center(
                      child: AppNetworkAvatar(
                        key: ValueKey('ctx_mob_logo_${vId}_$storeLogo'),
                        imageUrl: storeLogo,
                        size: 24,
                        borderRadius: 6,
                        fallbackIcon: LucideIcons.store,
                        fallbackIconSize: 16,
                      ),
                    );
                  }
                  return Container(
                    alignment: AlignmentDirectional.centerStart,
                    child: Row(
                      children: [
                        AppNetworkAvatar(
                          key: ValueKey('ctx_bar_logo_${vId}_$storeLogo'),
                          imageUrl: storeLogo,
                          size: 22,
                          borderRadius: 6,
                          fallbackIcon: LucideIcons.store,
                          fallbackIconSize: 13,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            display,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
              items: memberships.map((item) {
                final member = item as Map<String, dynamic>;
                final isAr = Localizations.localeOf(context).languageCode == 'ar';
                final vId = member['vendorId']?.toString() ?? '';
                final role = member['role']?.toString() ?? '';
                final vendor = member['vendor'] as Map<String, dynamic>?;
                final branch = member['branch'] as Map<String, dynamic>?;
                final storeLogo = ImageUtils.resolveVendorLogoUrl(vendor);
                final storeName = (isAr
                        ? (vendor?['storeNameAr'] ?? vendor?['storeName'])
                        : (vendor?['storeName'] ?? vendor?['storeNameAr']))
                    ?.toString();
                final branchName = (isAr
                        ? (branch?['nameAr'] ?? branch?['name'])
                        : (branch?['name'] ?? branch?['nameAr']))
                    ?.toString();
                final title = (storeName != null && storeName.isNotEmpty)
                    ? storeName
                    : 'Vendor $vId';
                final subtitle = [
                  if (branchName != null && branchName.isNotEmpty) branchName,
                  if (role.isNotEmpty) role,
                ].join(' • ');
                return DropdownMenuItem<String>(
                  value: vId,
                  child: Row(
                    children: [
                      AppNetworkAvatar(
                        key: ValueKey('ctx_item_logo_${vId}_$storeLogo'),
                        imageUrl: storeLogo,
                        size: 28,
                        borderRadius: 7,
                        fallbackIcon: LucideIcons.store,
                        fallbackIconSize: 14,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
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
