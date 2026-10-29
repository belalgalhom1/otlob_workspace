import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/providers.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/core/utils/error_utils.dart';
import '../data/driver_models.dart';

const Color _neutral500 = Color(0xFF6B7280);
const Color _neutral400 = Color(0xFF9CA3AF);

class DriverManagersScreen extends ConsumerStatefulWidget {
  const DriverManagersScreen({super.key});

  @override
  ConsumerState<DriverManagersScreen> createState() => _DriverManagersScreenState();
}

class _DriverManagersScreenState extends ConsumerState<DriverManagersScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _managers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      final res = await repo.listDriverManagers();
      if (mounted) {
        setState(() {
          _managers = res is List ? res : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredManagers = _managers.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (m['name'] ?? '').toString().toLowerCase();
      final email = (m['email'] ?? '').toString().toLowerCase();
      final phone = (m['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAr ? 'مديرو المناديب' : 'Driver Managers',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isAr
                            ? 'إدارة وتعيين السائقين لمديري المناديب ومتابعة محافظهم وعمولاتهم'
                            : 'Assign drivers to managers, oversee scopes, and track manager wallets',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _isLoading ? null : _loadManagers,
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  tooltip: _isAr ? 'تحديث' : 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar & Filter Bar
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          hintText: _isAr ? 'بحث بالاسم، البريد أو الهاتف...' : 'Search by name, email, or phone...',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        onPressed: () => setState(() => _searchQuery = ''),
                        icon: const Icon(LucideIcons.x, size: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 36),
                              const SizedBox(height: 12),
                              Text(ErrorUtils.translate(context, _error)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _loadManagers,
                                icon: const Icon(LucideIcons.refreshCw, size: 16),
                                label: Text(_isAr ? 'إعادة المحاولة' : 'Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredManagers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.users, size: 48, color: _neutral400),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isAr ? 'لا يوجد مديرو مناديب مسجلون' : 'No driver managers found',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isAr
                                        ? 'يمكنك إضافة مدير مناديب جديد من قسم إدارة المستخدمين'
                                        : 'You can create a driver manager account from Users management',
                                    style: const TextStyle(color: _neutral500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredManagers.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 16),
                              itemBuilder: (ctx, idx) {
                                final m = filteredManagers[idx];
                                return _buildManagerCard(m, theme, isDark);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerCard(dynamic m, ThemeData theme, bool isDark) {
    final name = (m['name'] ?? '').toString();
    final email = (m['email'] ?? '').toString();
    final phone = (m['phone'] ?? '').toString();
    final userId = (m['userId'] ?? '').toString();
    final walletBalance = (m['walletBalance'] as num?)?.toDouble() ?? 0.0;
    final manageAll = m['manageAllDrivers'] == true;
    final assignedCount = (m['assignedCount'] as num?)?.toInt() ?? 0;
    final assignedDrivers = m['assignedDrivers'] is List ? (m['assignedDrivers'] as List) : [];
    final zoneName = m['zone'] is Map
        ? (_isAr ? (m['zone']['nameAr'] ?? m['zone']['name']) : m['zone']['name'])
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Manager info, Wallet, and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(LucideIcons.userCheck, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name.isEmpty ? (_isAr ? 'مدير مناديب' : 'Driver Manager') : name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (manageAll)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _isAr ? 'يدير جميع السائقين' : 'Manages All Drivers',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _isAr ? '$assignedCount سائق معين' : '$assignedCount Assigned Drivers',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (zoneName != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                zoneName,
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          if (email.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.mail, size: 14, color: _neutral500),
                                const SizedBox(width: 4),
                                Text(email, style: const TextStyle(color: _neutral500, fontSize: 13)),
                              ],
                            ),
                          if (phone.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.phone, size: 14, color: _neutral500),
                                const SizedBox(width: 4),
                                Text(phone, style: const TextStyle(color: _neutral500, fontSize: 13)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Wallet preview card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _isAr ? 'محفظة العمولة' : 'Commission Wallet',
                        style: const TextStyle(fontSize: 12, color: _neutral500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${walletBalance.toStringAsFixed(1)} ${_isAr ? 'ج.م' : 'EGP'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Drivers list preview / Chips
            if (manageAll)
              Text(
                _isAr
                    ? 'هذا المدير لديه صلاحية إدارة كامل أسطول السائقين بالمنصة تلقائياً.'
                    : 'This manager automatically oversees the entire driver fleet on the platform.',
                style: const TextStyle(color: _neutral500, fontSize: 13),
              )
            else if (assignedDrivers.isEmpty)
              Text(
                _isAr ? 'لم يتم تعيين أي سائقين لهذا المدير بعد.' : 'No drivers assigned to this manager yet.',
                style: const TextStyle(color: _neutral500, fontSize: 13, fontStyle: FontStyle.italic),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: assignedDrivers.map<Widget>((d) {
                  final dName = (d['name'] ?? '').toString();
                  final dStatus = (d['status'] ?? '').toString();
                  final driverId = (d['driverId'] ?? '').toString();
                  Color statusColor = Colors.grey;
                  if (dStatus == 'ONLINE') statusColor = Colors.green;
                  if (dStatus == 'BUSY' || dStatus == 'ON_DELIVERY') statusColor = Colors.blue;
                  if (dStatus == 'ON_BREAK') statusColor = Colors.orange;

                  return Chip(
                    avatar: CircleAvatar(
                      radius: 5,
                      backgroundColor: statusColor,
                    ),
                    label: Text(
                      dName.isEmpty ? (_isAr ? 'سائق' : 'Driver') : dName,
                      style: const TextStyle(fontSize: 13),
                    ),
                    deleteIcon: const Icon(LucideIcons.x, size: 14),
                    onDeleted: () => _confirmUnassignDriver(userId, driverId, dName),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openAssignDriversDialog(m),
                  icon: const Icon(LucideIcons.userPlus, size: 16),
                  label: Text(_isAr ? 'تعيين / تعديل السائقين' : 'Assign / Edit Drivers'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUnassignDriver(String managerUserId, String driverId, String driverName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isAr ? 'إلغاء تعيين السائق' : 'Unassign Driver'),
        content: Text(
          _isAr
              ? 'هل أنت متأكد من إلغاء تعيين السائق "$driverName" من هذا المدير؟'
              : 'Are you sure you want to unassign driver "$driverName" from this manager?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(_isAr ? 'إلغاء التعيين' : 'Unassign'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.unassignDriversFromManager(
        driverManagerUserId: managerUserId,
        driverIds: [driverId],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isAr ? 'تم إلغاء تعيين السائق بنجاح' : 'Driver unassigned successfully')),
        );
        _loadManagers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorUtils.translate(context, e)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _openAssignDriversDialog(dynamic manager) async {
    final managerUserId = (manager['userId'] ?? '').toString();
    final managerName = (manager['name'] ?? '').toString();
    final initialManageAll = manager['manageAllDrivers'] == true;
    final initialAssigned = manager['assignedDrivers'] is List ? (manager['assignedDrivers'] as List) : [];
    final initialSelectedIds = Set<String>.from(initialAssigned.map((d) => (d['driverId'] ?? '').toString()));

    await showDialog(
      context: context,
      builder: (ctx) => _AssignDriversDialog(
        managerUserId: managerUserId,
        managerName: managerName,
        initialManageAll: initialManageAll,
        initialSelectedDriverIds: initialSelectedIds,
        onSaved: _loadManagers,
      ),
    );
  }
}

class _AssignDriversDialog extends ConsumerStatefulWidget {
  final String managerUserId;
  final String managerName;
  final bool initialManageAll;
  final Set<String> initialSelectedDriverIds;
  final VoidCallback onSaved;

  const _AssignDriversDialog({
    required this.managerUserId,
    required this.managerName,
    required this.initialManageAll,
    required this.initialSelectedDriverIds,
    required this.onSaved,
  });

  @override
  ConsumerState<_AssignDriversDialog> createState() => _AssignDriversDialogState();
}

class _AssignDriversDialogState extends ConsumerState<_AssignDriversDialog> {
  late bool _manageAllDrivers;
  late Set<String> _selectedDriverIds;
  bool _isLoadingDrivers = true;
  bool _isSaving = false;
  String? _error;
  List<DriverProfile> _allDrivers = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _manageAllDrivers = widget.initialManageAll;
    _selectedDriverIds = Set<String>.from(widget.initialSelectedDriverIds);
    _loadAllDrivers();
  }

  Future<void> _loadAllDrivers() async {
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      final res = await repo.getDrivers(limit: 100);
      if (res is Map && mounted) {
        final list = res['drivers'] is List ? (res['drivers'] as List) : [];
        setState(() {
          _allDrivers = list.map((j) => DriverProfile.fromJson(j as Map<String, dynamic>)).toList();
          _isLoadingDrivers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingDrivers = false;
        });
      }
    }
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      await repo.assignDriversToManager(
        driverManagerUserId: widget.managerUserId,
        manageAllDrivers: _manageAllDrivers,
        driverIds: _manageAllDrivers ? null : _selectedDriverIds.toList(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isAr ? 'تم تحديث تعيين السائقين بنجاح' : 'Driver assignments updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorUtils.translate(context, e)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredDrivers = _allDrivers.where((d) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return d.name.toLowerCase().contains(q) ||
          (d.nationalId ?? '').toLowerCase().contains(q) ||
          (d.vehiclePlate ?? '').toLowerCase().contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: const Icon(LucideIcons.userPlus, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAr
                              ? 'تعيين السائقين للمدير: ${widget.managerName}'
                              : 'Assign Drivers to: ${widget.managerName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          _isAr
                              ? 'حدد السائقين الذين يتبعون هذا المدير للحصول على العمولات وإدارة الحسابات'
                              : 'Select drivers under this manager to route commissions and management',
                          style: const TextStyle(color: _neutral500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Manage All Drivers Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                child: SwitchListTile(
                  value: _manageAllDrivers,
                  onChanged: (val) => setState(() => _manageAllDrivers = val),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    _isAr ? 'إدارة جميع السائقين تلقائياً' : 'Manage All Drivers Automatically',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _isAr
                        ? 'عند التفعيل، سيتم ربط جميع سائقي المنصة بهذا المدير دون الحاجة لتحديدهم يدوياً'
                        : 'When enabled, this manager oversees all drivers across the platform',
                    style: const TextStyle(fontSize: 12, color: _neutral500),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Individual driver list section (shown only when manageAll is false)
              if (!_manageAllDrivers) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v.trim()),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(LucideIcons.search, size: 16),
                          hintText: _isAr ? 'بحث عن سائق...' : 'Search driver...',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isAr
                          ? 'المحدد: ${_selectedDriverIds.length}'
                          : 'Selected: ${_selectedDriverIds.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _isLoadingDrivers
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(child: Text(ErrorUtils.translate(context, _error)))
                          : filteredDrivers.isEmpty
                              ? Center(
                                  child: Text(_isAr ? 'لم يتم العثور على سائقين' : 'No drivers found'),
                                )
                              : ListView.builder(
                                  itemCount: filteredDrivers.length,
                                  itemBuilder: (ctx, i) {
                                    final d = filteredDrivers[i];
                                    final isSelected = _selectedDriverIds.contains(d.id);
                                    final otherManager = d.driverManagerName;
                                    final isCurrentManager = d.driverManagerUserId == widget.managerUserId;

                                    return CheckboxListTile(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedDriverIds.add(d.id);
                                          } else {
                                            _selectedDriverIds.remove(d.id);
                                          }
                                        });
                                      },
                                      title: Row(
                                        children: [
                                          Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (d.status == 'ONLINE' ? Colors.green : Colors.grey)
                                                  .withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              d.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: d.status == 'ONLINE' ? Colors.green : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        otherManager != null && !isCurrentManager
                                            ? (_isAr
                                                ? 'معين حالياً للمدير: $otherManager (سيتم نقله لهذا المدير)'
                                                : 'Currently assigned to: $otherManager (will be reassigned)')
                                            : (d.vehiclePlate != null ? 'لوحة: ${d.vehiclePlate}' : ''),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: otherManager != null && !isCurrentManager
                                              ? Colors.orange
                                              : _neutral500,
                                        ),
                                      ),
                                      controlAffinity: ListTileControlAffinity.leading,
                                    );
                                  },
                                ),
                ),
              ] else
                const Spacer(),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(_isAr ? 'إلغاء' : 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isAr ? 'حفظ التعيينات' : 'Save Assignments'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
