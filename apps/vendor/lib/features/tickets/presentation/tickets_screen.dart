import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/widgets/stat_card.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:vendor/features/chat/presentation/pages/admin_chat_screen.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'ticket_provider.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  String _statusFilter = 'ALL';
  bool _isStatsExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchTickets());
  }

  void _fetchTickets() {
    final params = <String, dynamic>{'page': 1};
    if (_statusFilter != 'ALL') {
      params['status'] = _statusFilter;
    }
    ref.read(ticketProvider.notifier).fetchTickets(params: params);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 1100;

    return Column(
      children: [
        _buildHeader(l10n),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(ticketProvider);
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildStatsGrid(l10n, isMobile, state),
                  _buildShowMoreToggle(l10n),
                  const SizedBox(height: 16),
                  if (state.isLoading && !state.hasValue)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.hasValue)
                    if (state.value!.tickets.isEmpty)
                      _buildEmptyState(l10n)
                    else
                      ...state.value!.tickets.map(
                        (ticket) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildTicketCard(ticket, l10n),
                        ),
                      )
                  else if (state.hasError)
                    Center(child: Text(ErrorUtils.translate(context, state.error))),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          const Icon(
            LucideIcons.helpCircle,
            size: 32,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.tickets,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          IconButton(
            onPressed: _fetchTickets,
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: l10n.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    AppLocalizations l10n,
    bool isMobile,
    AsyncValue<TicketStateData> state,
  ) {
    final counts = state.hasValue ? state.value!.counts : {};

    // Calculate true total by summing all status counts
    final int totalCount = counts.values.fold(
      0,
      (sum, val) => sum + (val as int),
    );
    final totalTickets = totalCount.toString();

    String getCount(String status) => (counts[status] ?? 0).toString();

    final bool isSmallMobile = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: isSmallMobile ? 2 : (isMobile ? 2 : 4),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: isSmallMobile ? 2.0 : 2.4,
        children: [
          StatCard(
            title: l10n.all,
            value: totalTickets,
            icon: LucideIcons.layoutGrid,
            color: AppColors.primary,
            isMobile: isMobile,
            onTap: () => _updateFilter('ALL'),
          ),
          StatCard(
            title: l10n.open,
            value: getCount('OPEN'),
            icon: LucideIcons.inbox,
            color: Colors.green,
            isMobile: isMobile,
            onTap: () => _updateFilter('OPEN'),
          ),
          StatCard(
            title: l10n.inProgress,
            value: getCount('IN_PROGRESS'),
            icon: LucideIcons.loader,
            color: Colors.blue,
            isMobile: isMobile,
            onTap: () => _updateFilter('IN_PROGRESS'),
          ),
          StatCard(
            title: l10n.escalated,
            value: getCount('ESCALATED'),
            icon: LucideIcons.alertCircle,
            color: Colors.red,
            isMobile: isMobile,
            onTap: () => _updateFilter('ESCALATED'),
          ),
          if (_isStatsExpanded) ...[
            StatCard(
              title: l10n.waitingOnUser,
              value: getCount('WAITING_ON_USER'),
              icon: LucideIcons.user,
              color: Colors.orange,
              isMobile: isMobile,
              onTap: () => _updateFilter('WAITING_ON_USER'),
            ),
            StatCard(
              title: l10n.resolved,
              value: getCount('RESOLVED'),
              icon: LucideIcons.checkCircle,
              color: Colors.teal,
              isMobile: isMobile,
              onTap: () => _updateFilter('RESOLVED'),
            ),
            StatCard(
              title: l10n.closed,
              value: getCount('CLOSED'),
              icon: LucideIcons.lock,
              color: Colors.grey,
              isMobile: isMobile,
              onTap: () => _updateFilter('CLOSED'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShowMoreToggle(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: TextButton.icon(
          onPressed: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
          icon: Icon(
            _isStatsExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 16,
          ),
          label: Text(_isStatsExpanded ? l10n.showLess : l10n.showMore),
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ),
    );
  }

  void _updateFilter(String value) {
    setState(() => _statusFilter = value);
    _fetchTickets();
  }

  Widget _buildTicketCard(dynamic ticket, AppLocalizations l10n) {
    final status = ticket['status'] as String;
    final isEscalated = status == 'ESCALATED';
    final createdAt = DateTime.parse(ticket['createdAt']);
    final ticketNumber = ticket['ticketNumber'] ?? '---';
    final category = ticket['category'] as String? ?? 'OTHER';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEscalated
              ? Colors.red.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
          width: isEscalated ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (ticket['conversationId'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminChatScreen(
                  conversationId: ticket['conversationId'],
                  title: ticket['subject'] ?? 'Ticket Support',
                  type: 'SUPPORT',
                  vendorName: ticket['vendor']?['storeName'],
                  vendorId: ticket['vendorId'],
                ),
              ),
            ).then((_) => _fetchTickets());
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    ticketNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(status, l10n),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket['subject'] ?? 'No Subject',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket['creator']?['name'] ?? l10n.unknown,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    LucideIcons.layers,
                    size: 14,
                    color: Colors.purple.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _translateCategory(category, l10n),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    TimeFormatter.formatTimeAgo(context, createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _translateCategory(String category, AppLocalizations l10n) {
    switch (category) {
      case 'DELIVERY':
        return l10n.ticketCategoryDelivery;
      case 'VENDOR':
        return l10n.ticketCategoryVendor;
      case 'PAYMENT':
        return l10n.ticketCategoryPayment;
      case 'ACCOUNT':
        return l10n.ticketCategoryAccount;
      case 'RETURN_COMPLAINT':
        return l10n.ticketCategoryReturn;
      default:
        return l10n.ticketCategoryOther;
    }
  }

  Widget _buildStatusBadge(String status, AppLocalizations l10n) {
    Color color = Colors.grey;
    String label = '';
    IconData icon = LucideIcons.circle;

    switch (status) {
      case 'OPEN':
        color = Colors.green;
        label = l10n.open;
        icon = LucideIcons.inbox;
      case 'IN_PROGRESS':
        color = Colors.blue;
        label = l10n.inProgress;
        icon = LucideIcons.loader;
      case 'WAITING_ON_USER':
        color = Colors.orange;
        label = l10n.waitingOnUser;
        icon = LucideIcons.user;
      case 'ESCALATED':
        color = Colors.red;
        label = l10n.escalated;
        icon = LucideIcons.alertCircle;
      case 'RESOLVED':
        color = Colors.teal;
        label = l10n.resolved;
        icon = LucideIcons.checkCircle;
      case 'CLOSED':
        color = Colors.grey;
        label = l10n.closed;
        icon = LucideIcons.lock;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Icon(
            LucideIcons.ticket,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSupportTickets,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

