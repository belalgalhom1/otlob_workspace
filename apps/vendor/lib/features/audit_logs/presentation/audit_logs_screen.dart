import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'dart:convert';
import '../data/audit_logs_provider.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(auditLogsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(auditLogsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.auditLogs,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.auditLogsSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCcw, size: 20),
                  tooltip: l10n.refresh,
                  onPressed: () => ref.read(auditLogsProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: state.when(
              data: (data) {
                if (data.logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.clipboardList,
                          size: 64,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noAuditLogsFound,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: data.logs.length + (data.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == data.logs.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildLogCard(context, data.logs[index], l10n, theme);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text('$e', style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.read(auditLogsProvider.notifier).refresh(),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: Text(l10n.refresh),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(
    BuildContext context,
    dynamic log,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return _AuditLogCard(log: log, l10n: l10n, theme: theme);
  }
}

class _AuditLogCard extends StatefulWidget {
  final dynamic log;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _AuditLogCard({required this.log, required this.l10n, required this.theme});

  @override
  State<_AuditLogCard> createState() => _AuditLogCardState();
}

class _AuditLogCardState extends State<_AuditLogCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final l10n = widget.l10n;
    final theme = widget.theme;

    final userRaw = log['user'];
    final userMap = userRaw is Map ? Map<String, dynamic>.from(userRaw) : null;
    String userDisplay = (log['userId'] ?? '').toString();
    if (userMap != null) {
      final name = [userMap['firstName'], userMap['lastName']]
          .where((e) => e != null && e.toString().isNotEmpty)
          .join(' ');
      userDisplay = name.isNotEmpty ? name : (userMap['email'] ?? userDisplay).toString();
    }

    final actionTypeRaw = (log['actionType'] ?? 'OTHER').toString();
    String entityType = (log['entityType'] ?? '').toString();

    // Map HTTP verbs to CRUD actions
    String actionType = actionTypeRaw.toUpperCase();
    if (actionType == 'POST') actionType = 'CREATE';
    if (actionType == 'PUT' || actionType == 'PATCH') actionType = 'UPDATE';
    if (actionType == 'GET') actionType = 'READ';

    // Format URL paths into human-readable entity names
    if (entityType.startsWith('/')) {
      final segments = entityType.split('/').where((s) => 
        s.isNotEmpty && 
        s != 'api' && 
        s != 'v1' && 
        s != 'admin' && 
        s != 'vendor' &&
        !s.contains(RegExp(r'[0-9a-fA-F-]{10,}')) // filter out UUIDs/IDs
      ).toList();
      
      if (segments.isNotEmpty) {
        entityType = segments.map((s) {
          return s[0].toUpperCase() + s.substring(1).toLowerCase();
        }).join(' ');
      }
    }

    final createdAtRaw = (log['createdAt'] ?? '').toString();
    String createdAt = createdAtRaw;
    try {
      final date = DateTime.parse(createdAtRaw).toLocal();
      createdAt = DateFormat('dd MMM yyyy – hh:mm a').format(date);
    } catch (_) {}

    Map<String, dynamic> oldMap = {};
    Map<String, dynamic> newMap = {};

    if (log['oldValues'] != null) {
      if (log['oldValues'] is Map) {
        oldMap = Map<String, dynamic>.from(log['oldValues']);
      } else if (log['oldValues'] is String && log['oldValues'].toString().isNotEmpty) {
        try {
          oldMap = Map<String, dynamic>.from(jsonDecode(log['oldValues']));
        } catch (_) {}
      }
    }

    if (log['newValues'] != null) {
      if (log['newValues'] is Map) {
        newMap = Map<String, dynamic>.from(log['newValues']);
      } else if (log['newValues'] is String && log['newValues'].toString().isNotEmpty) {
        try {
          newMap = Map<String, dynamic>.from(jsonDecode(log['newValues']));
        } catch (_) {}
      }
    }

    List<Widget> changeWidgets = [];

    // Format action if it exists
    final actionDetail = log['action'];
    if (actionDetail != null && actionDetail.toString().isNotEmpty) {
      changeWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            actionDetail.toString(),
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    // Pair up the keys to show exactly what changed
    final allKeys = {...oldMap.keys, ...newMap.keys};
    for (final key in allKeys) {
      final oldVal = oldMap[key];
      final newVal = newMap[key];

      if (oldVal == newVal && oldMap.containsKey(key) && newMap.containsKey(key)) continue;

      changeWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (oldMap.containsKey(key)) ...[
                        TextSpan(
                          text: oldVal?.toString() ?? 'null',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const TextSpan(text: '  →  '),
                      ],
                      if (newMap.containsKey(key))
                        TextSpan(
                          text: newVal?.toString() ?? 'null',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Fallback for details if they exist natively but old/new don't
    if (changeWidgets.isEmpty && log['details'] != null && log['details'].toString().isNotEmpty) {
       changeWidgets.add(Text(log['details'].toString(), style: const TextStyle(fontSize: 12)));
    }

    // Action config
    Color actionColor;
    IconData actionIcon;
    String actionLabel;
    switch (actionType) {
      case 'CREATE':
        actionColor = AppColors.success;
        actionIcon = LucideIcons.plusCircle;
        actionLabel = l10n.actionCreate;
        break;
      case 'UPDATE':
        actionColor = AppColors.warning;
        actionIcon = LucideIcons.edit;
        actionLabel = l10n.actionUpdate;
        break;
      case 'DELETE':
        actionColor = AppColors.error;
        actionIcon = LucideIcons.trash2;
        actionLabel = l10n.actionDelete;
        break;
      case 'LOGIN':
        actionColor = AppColors.info;
        actionIcon = LucideIcons.logIn;
        actionLabel = l10n.actionLogin;
        break;
      case 'LOGOUT':
        actionColor = Colors.grey;
        actionIcon = LucideIcons.logOut;
        actionLabel = l10n.actionLogout;
        break;
      default:
        actionColor = AppColors.primary;
        actionIcon = LucideIcons.activity;
        actionLabel = actionType;
    }
    
    return GestureDetector(
      onTap: changeWidgets.isNotEmpty ? () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      } : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: actionColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(actionIcon, color: actionColor, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: actionColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    actionLabel,
                                    style: TextStyle(
                                      color: actionColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (entityType.isNotEmpty)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        entityType,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                if (changeWidgets.isNotEmpty)
                                  Icon(
                                    _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                                    size: 16,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(LucideIcons.user, size: 13,
                                    color: theme.colorScheme.onSurface),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${l10n.by} $userDisplay',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(LucideIcons.clock, size: 13,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.35)),
                                const SizedBox(width: 5),
                                Text(
                                  createdAt,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            if (_isExpanded && changeWidgets.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: changeWidgets,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
