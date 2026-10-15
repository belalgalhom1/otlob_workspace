import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/data.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/features/drivers/data/driver_models.dart';
import 'driver_breaks_providers.dart';

class DriverBreaksScreen extends ConsumerStatefulWidget {
  const DriverBreaksScreen({super.key});

  @override
  ConsumerState<DriverBreaksScreen> createState() =>
      _DriverBreaksScreenState();
}

class _DriverBreaksScreenState extends ConsumerState<DriverBreaksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DriverProfile? _selectedDriver;
  TabController? _tabController;
  Timer? _pendingPollTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (_tabController != controller) {
      _tabController?.removeListener(_onTabChanged);
      _tabController = controller;
      _tabController?.addListener(_onTabChanged);
      _onTabChanged();
    }
  }

  void _onTabChanged() {
    // Poll the pending queue only while its tab is visible: new driver
    // requests have no push/socket path to admins, so the list would
    // otherwise go stale. History is pull-to-refresh only (static data).
    if ((_tabController?.index ?? 0) == 0) {
      _pendingPollTimer ??= Timer.periodic(
        const Duration(seconds: 20),
        (_) => ref.invalidate(pendingBreaksProvider),
      );
    } else {
      _pendingPollTimer?.cancel();
      _pendingPollTimer = null;
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _pendingPollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, String? reason) {
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

  String _statusLabel(AppLocalizations l10n, String? status) {
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

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso)?.toLocal();
    if (parsed == null) return '';
    final hh = parsed.hour.toString().padLeft(2, '0');
    final mm = parsed.minute.toString().padLeft(2, '0');
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} $hh:$mm';
  }

  String _elapsed(String? startedAt) {
    if (startedAt == null || startedAt.isEmpty) return '';
    final start = DateTime.tryParse(startedAt);
    if (start == null) return '';
    return '${DateTime.now().difference(start).inMinutes}m';
  }

  String _driverName(Map<String, dynamic> item) {
    final driver = item['driver'];
    if (driver is Map) {
      final name = driver['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
      final user = driver['user'];
      if (user is Map && (user['name']?.toString().isNotEmpty ?? false)) {
        return user['name'].toString();
      }
    }
    return item['driverId']?.toString() ?? '';
  }

  Future<void> _runAdminAction(
    Future<dynamic> Function(DriverBreaksRepository repo) call,
  ) async {
    try {
      final repo = ref.read(driverBreaksRepositoryProvider);
      await call(repo);
      ref.invalidate(pendingBreaksProvider);
      if (_selectedDriver != null) {
        ref.invalidate(
          driverBreaksHistoryProvider(_selectedDriver!.id),
        );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: l10n.breaksPending, icon: const Icon(LucideIcons.hourglass, size: 18)),
              Tab(text: l10n.breaksHistory, icon: const Icon(LucideIcons.history, size: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingTab(l10n),
                _buildHistoryTab(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab(AppLocalizations l10n) {
    final pendingAsync = ref.watch(pendingBreaksProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(pendingBreaksProvider),
      child: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ErrorUtils.translate(context, e)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(pendingBreaksProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text(l10n.noPendingBreaks));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => _buildPendingCard(items[i], l10n),
          );
        },
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> item, AppLocalizations l10n) {
    final breakId = item['id']?.toString() ?? '';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Icon(LucideIcons.user, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _driverName(item),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${_reasonLabel(l10n, item['reason']?.toString())} • ${_formatTime(item['createdAt']?.toString())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item['requestedMinutes'] != null)
                  Chip(
                    label: Text(
                      '${item['requestedMinutes']} ${l10n.breakMinutesShort}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if ((item['note']?.toString().isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Text(
                item['note'].toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _runAdminAction(
                      (repo) => repo.rejectBreak(breakId),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text(l10n.breakReject),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _runAdminAction(
                      (repo) => repo.approveBreak(breakId),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.breakApprove),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchDriverHint,
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => setState(
                  () => _searchQuery = _searchController.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => setState(
                () => _searchQuery = _searchController.text,
              ),
              icon: const Icon(LucideIcons.search, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildHistoryBody(l10n)),
      ],
    );
  }

  Widget _buildHistoryBody(AppLocalizations l10n) {
    if (_selectedDriver == null) {
      if (_searchQuery.trim().isEmpty) {
        return Center(child: Text(l10n.selectDriver));
      }
      final searchAsync = ref.watch(driverBreakSearchProvider(_searchQuery));
      return searchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(ErrorUtils.translate(context, e))),
        data: (drivers) {
          if (drivers.isEmpty) return Center(child: Text(l10n.noDriversFound));
          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, i) {
              final d = drivers[i];
              return ListTile(
                leading: const CircleAvatar(child: Icon(LucideIcons.user, size: 16)),
                title: Text(d.name),
                subtitle: Text(d.status),
                trailing: const Icon(LucideIcons.chevronRight, size: 18),
                onTap: () => setState(() => _selectedDriver = d),
              );
            },
          );
        },
      );
    }

    final driver = _selectedDriver!;
    final historyAsync = ref.watch(driverBreaksHistoryProvider(driver.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _selectedDriver = null),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: Text(driver.name),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _showGrantDialog(driver, l10n),
              icon: const Icon(LucideIcons.coffee, size: 16),
              label: Text(l10n.breakGrant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(driverBreaksHistoryProvider(driver.id)),
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text(ErrorUtils.translate(context, e))),
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(l10n.noDriverBreaks));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _buildHistoryCard(items[i], l10n),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, AppLocalizations l10n) {
    final status = (item['status']?.toString() ?? '').toUpperCase();
    final breakId = item['id']?.toString() ?? '';
    final isActive = status == 'APPROVED' && item['endedAt'] == null;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_reasonLabel(l10n, item['reason']?.toString())} • ${_formatTime(item['startedAt']?.toString() ?? item['createdAt']?.toString())}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.amber.shade700
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(l10n, status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : null,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.breakElapsed}: ${_elapsed(item['startedAt']?.toString())}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
            ],
            if (status == 'PENDING' || isActive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (status == 'PENDING') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _runAdminAction(
                          (repo) => repo.rejectBreak(breakId),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        child: Text(l10n.breakReject),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _runAdminAction(
                          (repo) => repo.approveBreak(breakId),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.breakApprove),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _runAdminAction(
                          (repo) => repo.forceEndBreak(breakId),
                        ),
                        child: Text(l10n.breakForceEnd),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showGrantDialog(DriverProfile driver, AppLocalizations l10n) {
    String reason = 'REST';
    final minutesController = TextEditingController();
    final noteController = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => AlertDialog(
          title: Text('${l10n.breakGrant} — ${driver.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          child: Text(_reasonLabel(l10n, r)),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setSheetState(() => submitting = true);
                      try {
                        final repo =
                            ref.read(driverBreaksRepositoryProvider);
                        await repo.grantBreak(
                          driver.id,
                          reason: reason,
                          note: noteController.text.trim().isEmpty
                              ? null
                              : noteController.text.trim(),
                          requestedMinutes: int.tryParse(
                            minutesController.text.trim(),
                          ),
                        );
                        ref.invalidate(
                          driverBreaksHistoryProvider(driver.id),
                        );
                        ref.invalidate(pendingBreaksProvider);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } catch (e) {
                        setSheetState(() => submitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content:
                                  Text(ErrorUtils.translate(ctx, e)),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: Text(l10n.breakGrant),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      minutesController.dispose();
      noteController.dispose();
    });
  }
}
