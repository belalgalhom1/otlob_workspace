import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';

import '../data/wallet_localization.dart';
import '../data/wallet_models.dart';
import '../data/wallet_providers.dart';

/// Displays full details of a Driver Adjustment (`WalletTopUpRequest`) for
/// eligible Super Admins and `MANAGE_FINANCE` Admins, with receipt inspection
/// and inline approval/rejection + visible driver notes.
class DriverAdjustmentDetailsScreen extends ConsumerStatefulWidget {
  final String requestId;
  final WalletTopUpRequest? initialRequest;

  const DriverAdjustmentDetailsScreen({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  @override
  ConsumerState<DriverAdjustmentDetailsScreen> createState() =>
      _DriverAdjustmentDetailsScreenState();
}

class _DriverAdjustmentDetailsScreenState
    extends ConsumerState<DriverAdjustmentDetailsScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _submitting = false;
  String? _actionError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _resolveMediaUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final formatted = ImageUtils.formatImageUrl(trimmed);
    if (formatted.startsWith('http://') || formatted.startsWith('https://')) {
      return formatted;
    }
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$cleanBase$cleanPath';
  }

  Future<void> _submitReview(String status) async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final isApprove = status == 'APPROVED';

    setState(() {
      _submitting = true;
      _actionError = null;
    });

    try {
      await ref
          .read(pendingTopUpsProvider.notifier)
          .reviewTopUp(
            widget.requestId,
            status,
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(topUpDetailsProvider(widget.requestId));
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isApprove ? l10n.topUpApproved : l10n.topUpRejected),
          backgroundColor: isApprove ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _actionError = '${l10n.topUpFailed}: ${ErrorUtils.translate(context, e)}';
      });
    }
  }

  void _openReceiptViewer(
    BuildContext context,
    String receiptUrl,
    AppLocalizations l10n,
  ) {
    showDialog<void>(
      context: context,
      builder: (c) => AppDialog(
        maxWidth: 720,
        scrollableBody: false,
        bodyPadding: const EdgeInsets.all(16),
        header: AppDialogHeader(
          icon: LucideIcons.image,
          title: l10n.transferReceipt,
          onClose: () => Navigator.pop(c),
        ),
        body: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                receiptUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (ctx, err, stack) => SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.imageOff,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.noReceiptAvailable),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        footer: AppDialogFooter(
          cancelLabel: l10n.closeAction,
          onCancel: () => Navigator.pop(c),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final detailsAsync = ref.watch(topUpDetailsProvider(widget.requestId));

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            l10n.driverAdjustmentDetails,
            maxLines: 1,
            softWrap: false,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _submitting
                ? null
                : () => ref.invalidate(topUpDetailsProvider(widget.requestId)),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
          ),
        ],
      ),
      body: SafeArea(
        child: detailsAsync.when(
          loading: () {
            final preview = widget.initialRequest;
            if (preview != null) {
              return _buildContent(
                context,
                preview,
                l10n: l10n,
                theme: theme,
                isDark: isDark,
                isAr: isAr,
                borderColor: borderColor,
                isSyncing: true,
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, _) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ErrorUtils.translate(context, error),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(
                          topUpDetailsProvider(widget.requestId),
                        ),
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: Text(l10n.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          data: (request) => _buildContent(
            context,
            request,
            l10n: l10n,
            theme: theme,
            isDark: isDark,
            isAr: isAr,
            borderColor: borderColor,
            isSyncing: false,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WalletTopUpRequest request, {
    required AppLocalizations l10n,
    required ThemeData theme,
    required bool isDark,
    required bool isAr,
    required Color borderColor,
    required bool isSyncing,
  }) {
    final normalizedStatus = request.status.trim().toUpperCase();
    final isPending = normalizedStatus == 'PENDING';
    final isApproved = normalizedStatus == 'APPROVED';

    final statusColor = isApproved
        ? AppColors.success
        : isPending
            ? AppColors.warning
            : AppColors.error;
    final statusIcon = isApproved
        ? LucideIcons.checkCircle
        : isPending
            ? LucideIcons.clock
            : LucideIcons.xCircle;
    final statusLabel = isApproved
        ? l10n.approved
        : isPending
            ? l10n.pending
            : l10n.rejected;

    final moneyFmt = NumberFormat('#,##0.##', 'en_US');
    final amountText = moneyFmt.format(request.amount);
    final receiptUrl = _resolveMediaUrl(request.receiptUrl);
    final avatarUrl = _resolveMediaUrl(request.driverAvatar ?? '');
    final walletLabel = request.platformWalletLabel(isArabic: isAr);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(topUpDetailsProvider(widget.requestId));
        await ref.read(topUpDetailsProvider(widget.requestId).future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isSyncing) const LinearProgressIndicator(minHeight: 2),
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 15, color: statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '#${request.id.length > 8 ? request.id.substring(0, 8) : request.id}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.amount,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      WalletLocalization.buildMoneyText(
                        amountText,
                        theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ) ??
                            const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                        isArabic: isAr,
                        alignment: AlignmentDirectional.centerStart,
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: LucideIcons.calendar,
                        label: l10n.submittedAtLabel,
                        value: WalletLocalization.formatDateTime(
                          request.createdAt,
                          isArabic: isAr,
                        ),
                      ),
                      if (walletLabel.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: LucideIcons.wallet,
                          label: l10n.walletProvider,
                          value: walletLabel,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Driver Details Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.driverDetails,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          AppNetworkAvatar(
                            imageUrl: avatarUrl,
                            size: 48,
                            fallbackIcon: LucideIcons.user,
                            fallbackIconSize: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (request.driverName ?? '').trim().isNotEmpty
                                      ? request.driverName!
                                      : l10n.unknownUser,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${l10n.driverId}: ${request.driverId}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.68),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if ((request.driverPhone ?? '').trim().isNotEmpty)
                            IconButton.filledTonal(
                              tooltip: l10n.callDriver,
                              onPressed: () => ExternalActionLauncher.callPhone(
                                request.driverPhone,
                                context: context,
                              ),
                              icon: const Icon(LucideIcons.phone, size: 18),
                            ),
                        ],
                      ),
                      if (request.driverWalletBalance != null) ...[
                        const SizedBox(height: 14),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.driverCurrentBalance,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            WalletLocalization.buildMoneyText(
                              WalletLocalization.formatAmountWithCurrency(
                                request.driverWalletBalance!,
                                isArabic: isAr,
                              ).replaceAll(
                                RegExp(r'\s*(EGP|ج\.م)$'),
                                '',
                              ),
                              TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: request.driverWalletBalance! < 0
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                              isArabic: isAr,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Receipt Preview Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.transferReceipt,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (receiptUrl.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l10n.tapToZoom,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (receiptUrl.isEmpty)
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.04,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(
                            child: Text(
                              l10n.noReceiptAvailable,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _openReceiptViewer(context, receiptUrl, l10n),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: AlignmentDirectional.bottomEnd,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 280,
                                    minWidth: double.infinity,
                                  ),
                                  child: Image.network(
                                    receiptUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        height: 180,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    },
                                    errorBuilder: (ctx, err, stack) => Container(
                                      height: 140,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.05),
                                      child: const Center(
                                        child: Icon(
                                          LucideIcons.imageOff,
                                          size: 36,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Icon(
                                    LucideIcons.maximize2,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Review Outcome or Action Section
                if (isPending)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppFieldLabel(label: l10n.reviewNotesLabel),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          enabled: !_submitting,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: AppDialogStyles.inputDecoration(
                            context,
                            hintText: l10n.rejectionReasonHint,
                            icon: LucideIcons.messageSquare,
                            isMultiline: true,
                          ),
                        ),
                        if (_actionError != null) ...[
                          const SizedBox(height: 12),
                          AppDialogErrorBanner(message: _actionError!),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _submitting
                                    ? null
                                    : () => _submitReview('REJECTED'),
                                icon: const Icon(
                                  LucideIcons.xCircle,
                                  size: 18,
                                ),
                                label: Text(l10n.reject),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(
                                    color: AppColors.error.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _submitting
                                    ? null
                                    : () => _submitReview('APPROVED'),
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        LucideIcons.checkCircle,
                                        size: 18,
                                      ),
                                label: Text(l10n.approve),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(statusIcon, size: 18, color: statusColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.requestAlreadyReviewed,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((request.approvedByName ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: LucideIcons.userCheck,
                            label: l10n.reviewedByLabel,
                            value: request.approvedByName!,
                          ),
                        ],
                        if (request.reviewedAt != null) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: LucideIcons.clock,
                            label: l10n.reviewedAtLabel,
                            value: WalletLocalization.formatDateTime(
                              request.reviewedAt!,
                              isArabic: isAr,
                            ),
                          ),
                        ],
                        if ((request.notes ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            l10n.reviewNotesLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.notes!.trim(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
