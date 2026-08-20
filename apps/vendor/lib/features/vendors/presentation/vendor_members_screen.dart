import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/vendors/presentation/vendor_members_provider.dart';
import '../../../l10n/l10n_error_helper.dart';

class VendorMembersScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorMembersScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  ConsumerState<VendorMembersScreen> createState() => _VendorMembersScreenState();
}

class _VendorMembersScreenState extends ConsumerState<VendorMembersScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(vendorMembersProvider(widget.vendorId));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              AppColors.info.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        LucideIcons.arrowLeft,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.users, color: AppColors.info),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.staffMembership,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.vendorName,
                            style: const TextStyle(
                              
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(vendorMembersProvider(widget.vendorId).notifier).fetchMembers();
                      },
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      label: Text(l10n.refresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: state.when(
                    data: (members) {
                      if (members.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.noStaffFound,
                            style: const TextStyle(),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final user = member['user'];
                          if (user == null) return const SizedBox.shrink();

                          final memberId = member['id'];
                          final currentRole = member['role'];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    backgroundImage: user['avatar'] != null ? NetworkImage(user['avatar']) : null,
                                    child: user['avatar'] == null
                                        ? Text(
                                            (user['name'] ?? l10n.unknown)[0].toUpperCase(),
                                            style: const TextStyle(color: AppColors.primary),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name'] ?? l10n.unknown,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          user['email'] ?? '',
                                          style: const TextStyle(
                                            
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: currentRole,
                                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                                        items: [
                                          DropdownMenuItem(value: 'OWNER', child: Text(l10n.owner)),
                                          DropdownMenuItem(value: 'MANAGER', child: Text(l10n.manager)),
                                          DropdownMenuItem(value: 'STAFF', child: Text(l10n.staff)),
                                        ],
                                        onChanged: (newRole) async {
                                          if (newRole != null && newRole != currentRole) {
                                            try {
                                              await ref.read(vendorMembersProvider(widget.vendorId).notifier).updateRole(memberId, newRole);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.roleUpdatedSuccessfully), backgroundColor: AppColors.success));
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10nErrorHelper.translate(context, e.toString())), backgroundColor: AppColors.error));
                                              }
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Center(child: Text(L10nErrorHelper.translate(context, e.toString()))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
