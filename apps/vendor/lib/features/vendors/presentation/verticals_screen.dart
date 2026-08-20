import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/vendors/presentation/vertical_provider.dart';
import 'package:vendor/features/vendors/presentation/widgets/add_vertical_dialog.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import '../../../l10n/l10n_error_helper.dart';

class VerticalsScreen extends ConsumerStatefulWidget {
  const VerticalsScreen({super.key});

  @override
  ConsumerState<VerticalsScreen> createState() => _VerticalsScreenState();
}

class _VerticalsScreenState extends ConsumerState<VerticalsScreen> {
  int _currentPage = 0;
  final int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<dynamic>>>(verticalProvider, (previous, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorUtils.translate(context, state.error.toString()),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.businessTypes,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.manageVerticalsDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddVerticalDialog(context),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(AppLocalizations.of(context)!.addBusinessType),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Search Bar
        DashboardSearchBar(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _currentPage = 0; // Reset pagination on search
            });
          },
          onClear: () {
            setState(() {
              _searchQuery = '';
              _currentPage = 0;
            });
          },
        ),
        const SizedBox(height: 24),
        _buildVerticalsTable(context),
      ],
    );
  }

  Widget _buildVerticalsTable(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(verticalProvider);
        if (state.isLoading && !state.hasValue) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.hasValue) {
          final filteredVerticals = (state.value ?? []).where((v) {
            final name = (v['name'] ?? '').toString().toLowerCase();
            final nameAr = (v['nameAr'] ?? '').toString().toLowerCase();
            final searchLower = _searchQuery.toLowerCase();
            return name.contains(searchLower) || nameAr.contains(searchLower);
          }).toList();

          if (filteredVerticals.isEmpty) {
            return _buildEmptyState();
          }

          final totalItems = filteredVerticals.length;
          final totalPages = (totalItems / _pageSize).ceil();

          // Ensure current page is valid after deletions
          if (_currentPage >= totalPages && totalPages > 0) {
            _currentPage = totalPages - 1;
          }

          final startIndex = _currentPage * _pageSize;
          final endIndex = (startIndex + _pageSize) > totalItems
              ? totalItems
              : (startIndex + _pageSize);
          final pagedItems = filteredVerticals.sublist(startIndex, endIndex);

          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pagedItems.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final v = pagedItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: v['iconUrl'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _buildImage(v['iconUrl']),
                                      )
                                    : const Icon(
                                        LucideIcons.layers,
                                        color: AppColors.primary,
                                        size: 16,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v['name'] ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (v['nameAr'] != null)
                                      Text(
                                        v['nameAr'],
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(v['isActive'] ?? true),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              _buildActionItem(
                                context: context,
                                icon: LucideIcons.edit3,
                                color: AppColors.primary,
                                label: AppLocalizations.of(context)!.edit,
                                onPressed: () =>
                                    _showEditVerticalDialog(context, v),
                              ),
                              _buildActionItem(
                                context: context,
                                icon: LucideIcons.trash2,
                                color: Theme.of(context).colorScheme.error,
                                label: AppLocalizations.of(context)!.delete,
                                onPressed: () => _confirmDelete(context, v),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: 24),
                _buildPagination(totalPages),
              ],
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(40),
          child: Center(child: Text(AppLocalizations.of(context)!.noDataAvailable)),
        );
      },
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isSelected = _currentPage == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => setState(() => _currentPage = index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.textMuted).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive
            ? AppLocalizations.of(context)!.activeStatus
            : AppLocalizations.of(context)!.inactiveStatus,
        style: TextStyle(
          color: isActive ? AppColors.success : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            const Icon(
              LucideIcons.layers,
              size: 48,
              
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noBusinessTypesFound,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVerticalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddVerticalDialog(),
    ).then((result) async {
      if (result != null) {
        try {
          await ref.read(verticalProvider.notifier).createVertical(result);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.common_success_resource_created),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(L10nErrorHelper.translate(context, e.toString())),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    });
  }

  void _showEditVerticalDialog(BuildContext context, dynamic vertical) {
    showDialog(
      context: context,
      builder: (context) => AddVerticalDialog(vertical: vertical),
    ).then((result) async {
      if (result != null) {
        try {
          await ref.read(verticalProvider.notifier).updateVertical(vertical['id'], result);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.common_success_resource_updated),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(L10nErrorHelper.translate(context, e.toString())),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    });
  }

  void _confirmDelete(BuildContext context, dynamic vertical) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(AppLocalizations.of(context)!.deleteBusinessType),
        content: Text(
          AppLocalizations.of(context)!.deleteBusinessTypeConfirm(
            vertical['name'] ?? AppLocalizations.of(context)!.unknown,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(verticalProvider.notifier)
                  .deleteVertical(vertical['id']);
            },
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return const Icon(LucideIcons.layers, color: AppColors.primary, size: 16);
    }

    if (url.startsWith('file://') ||
        url.startsWith('/data/user/') ||
        url.startsWith('/storage/')) {
      final path = url.replaceFirst('file://', '');
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(LucideIcons.layers, color: AppColors.primary, size: 16),
      );
    }

    // Prepend base URL for relative media paths from the server
    final fullUrl = url.startsWith('/media/')
        ? 'https://api.otlob-egy.online$url'
        : url;

    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(LucideIcons.layers, color: AppColors.primary, size: 16),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

