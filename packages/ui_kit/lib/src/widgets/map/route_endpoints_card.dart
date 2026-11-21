import 'package:flutter/material.dart';

/// Presentation-only route summary showing pickup -> dropoff endpoints with a
/// clean vertical indicator. Adapts dynamically to any [TextScaler] and RTL/LTR.
class RouteEndpointsCard extends StatelessWidget {
  const RouteEndpointsCard({
    super.key,
    required this.pickupLabel,
    required this.pickupAddress,
    required this.dropoffLabel,
    required this.dropoffAddress,
    required this.pickupColor,
    required this.dropoffColor,
    this.itemDetailsLabel,
    this.itemDetails,
    this.notesLabel,
    this.notes,
    this.backgroundColor,
    this.borderColor,
  });

  final String pickupLabel;
  final String pickupAddress;
  final String dropoffLabel;
  final String dropoffAddress;
  final Color pickupColor;
  final Color dropoffColor;
  final String? itemDetailsLabel;
  final String? itemDetails;
  final String? notesLabel;
  final String? notes;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasItem = itemDetails != null && itemDetails!.trim().isNotEmpty;
    final hasNotes = notes != null && notes!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteEndpointRow(
            indicator: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: pickupColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: pickupColor, width: 3),
              ),
            ),
            showConnector: true,
            connectorColor: scheme.outlineVariant,
            label: pickupLabel,
            value: pickupAddress,
          ),
          _RouteEndpointRow(
            indicator: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dropoffColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3.5),
                border: Border.all(color: dropoffColor, width: 3),
              ),
            ),
            showConnector: false,
            connectorColor: scheme.outlineVariant,
            label: dropoffLabel,
            value: dropoffAddress,
          ),
          if (hasItem || hasNotes) ...[
            Divider(
              height: 20,
              color: scheme.outlineVariant.withValues(alpha: 0.4),
            ),
            if (hasItem) ...[
              Text(
                itemDetailsLabel ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(itemDetails!.trim(), style: theme.textTheme.bodyMedium),
            ],
            if (hasItem && hasNotes) const SizedBox(height: 8),
            if (hasNotes) ...[
              Text(
                notesLabel ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                notes!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _RouteEndpointRow extends StatelessWidget {
  const _RouteEndpointRow({
    required this.indicator,
    required this.showConnector,
    required this.connectorColor,
    required this.label,
    required this.value,
  });

  final Widget indicator;
  final bool showConnector;
  final Color connectorColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                indicator,
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: connectorColor.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
