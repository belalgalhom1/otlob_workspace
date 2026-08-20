import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildQuickStat(
              context,
              AppLocalizations.of(context)!.totalCustomers,
              '1,240',
              LucideIcons.users,
            ),
            const SizedBox(width: 24),
            _buildQuickStat(
              context,
              AppLocalizations.of(context)!.activeThisMonth,
              '850',
              LucideIcons.trendingUp,
            ),
            const SizedBox(width: 24),
            _buildQuickStat(
              context,
              AppLocalizations.of(context)!.banned,
              '12',
              LucideIcons.userX,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.customerDirectory,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildCustomerTable(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerTable(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(0.8),
      },
      children: [
        TableRow(
          children:
              [
                    l10n.name,
                    l10n.emailPhone,
                    l10n.orders,
                    l10n.joinedDate,
                    l10n.actions,
                  ]
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        h,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        _buildCustomerRow('John Doe', 'john@example.com', '15', 'May 01, 2026'),
        _buildCustomerRow('Jane Smith', 'jane@test.com', '8', 'Apr 28, 2026'),
        _buildCustomerRow('Ahmed Ali', '+20123456789', '24', 'Apr 25, 2026'),
      ],
    );
  }

  TableRow _buildCustomerRow(
    String name,
    String contact,
    String orders,
    String date,
  ) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(contact),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(orders),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(date),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: IconButton(
            icon: const Icon(LucideIcons.userCog, size: 18),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

