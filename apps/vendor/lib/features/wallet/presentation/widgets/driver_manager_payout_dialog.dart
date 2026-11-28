import 'package:data/providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/core/utils/error_utils.dart';

import '../../data/wallet_localization.dart';

/// Super Admin / Finance Admin dialog for settling (zeroing out) or partially
/// paying out a Driver Manager's wallet balance with an optional transfer
/// screenshot receipt and note.
class DriverManagerPayoutDialog extends ConsumerStatefulWidget {
  final String managerUserId;
  final String managerName;
  final double currentBalance;

  const DriverManagerPayoutDialog({
    super.key,
    required this.managerUserId,
    required this.managerName,
    required this.currentBalance,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String managerUserId,
    required String managerName,
    required double currentBalance,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DriverManagerPayoutDialog(
        managerUserId: managerUserId,
        managerName: managerName,
        currentBalance: currentBalance,
      ),
    );
  }

  @override
  ConsumerState<DriverManagerPayoutDialog> createState() =>
      _DriverManagerPayoutDialogState();
}

class _DriverManagerPayoutDialogState
    extends ConsumerState<DriverManagerPayoutDialog> {
  static final _moneyFmt = NumberFormat('#,##0.00', 'en_US');
  static final _intFmt = NumberFormat('#,##0', 'en_US');

  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();
  late final String _idempotencyKey;

  bool _settleFullBalance = true;
  bool _isSubmitting = false;
  String? _statusLabel;
  String? _errorMessage;

  Uint8List? _receiptBytes;
  String? _receiptFileName;
  String? _uploadedReceiptUrl;

  @override
  void initState() {
    super.initState();
    _idempotencyKey =
        'dm_payout_${widget.managerUserId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  int get _wholeBalance => widget.currentBalance.floor();

  int? get _effectiveAmount {
    if (_settleFullBalance) return _wholeBalance > 0 ? _wholeBalance : null;
    final parsed = int.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Future<void> _pickReceipt(ImageSource source) async {
    if (_isSubmitting) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _receiptBytes = bytes;
        _receiptFileName = picked.name.isNotEmpty ? picked.name : 'receipt.jpg';
        _uploadedReceiptUrl = null;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _isAr
            ? 'تعذر اختيار صورة الإيصال'
            : 'Failed to pick receipt image';
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final isAr = _isAr;

    if (_wholeBalance <= 0) {
      setState(() {
        _errorMessage = isAr
            ? 'لا يوجد رصيد موجب متاح للتصفية في محفظة مسؤول السائقين.'
            : 'This driver manager has no positive balance to settle.';
      });
      return;
    }

    final amount = _effectiveAmount;
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = isAr
            ? 'يرجى إدخال مبلغ تحويل صحيح أكبر من الصفر.'
            : 'Please enter a valid positive payout amount.';
      });
      return;
    }

    if (!_settleFullBalance && amount > _wholeBalance) {
      setState(() {
        _errorMessage = isAr
            ? 'مبلغ التحويل أكبر من الرصيد الحالي (${_intFmt.format(_wholeBalance)} ج.م).'
            : 'Payout amount exceeds current balance (${_intFmt.format(_wholeBalance)} EGP).';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusLabel = _receiptBytes != null && _uploadedReceiptUrl == null
          ? (isAr ? 'جاري رفع إيصال التحويل...' : 'Uploading transfer receipt...')
          : (isAr ? 'جاري تنفيذ التحويل...' : 'Processing payout...');
    });

    try {
      final repo = ref.read(adminDriversRepositoryProvider);
      String? receiptUrl = _uploadedReceiptUrl;

      if (_receiptBytes != null && receiptUrl == null) {
        final uploadRes = await repo.uploadDriverManagerPayoutReceipt(
          MultipartFile.fromBytes(
            _receiptBytes!,
            filename: _receiptFileName ?? 'receipt.jpg',
          ),
        );
        if (uploadRes is Map && uploadRes['receiptUrl'] != null) {
          receiptUrl = uploadRes['receiptUrl'].toString().trim();
          _uploadedReceiptUrl = receiptUrl;
        }
      }

      if (mounted) {
        setState(() {
          _statusLabel = isAr
              ? 'جاري تصفية المحفظة وإرسال الإشعار...'
              : 'Settling wallet & notifying manager...';
        });
      }

      await repo.processDriverManagerPayout(
        driverManagerUserId: widget.managerUserId,
        amount: _settleFullBalance ? null : amount,
        settleFullBalance: _settleFullBalance,
        receiptUrl: receiptUrl,
        description: _notesController.text.trim(),
        idempotencyKey: _idempotencyKey,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusLabel = null;
        _errorMessage = ErrorUtils.translate(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAr = _isAr;
    final currency = WalletLocalization.currency(isAr);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subtleText = theme.colorScheme.onSurface.withValues(alpha: 0.68);
    final amountToPay = _effectiveAmount;
    final balanceAfter = amountToPay != null
        ? (widget.currentBalance - amountToPay).clamp(0.0, double.infinity)
        : widget.currentBalance;

    return AppDialog(
      maxWidth: 520,
      canPop: !_isSubmitting,
      header: AppDialogHeader(
        icon: LucideIcons.send,
        title: isAr ? 'تحويل وتصفية المحفظة' : 'Settle & Payout Wallet',
        subtitle: widget.managerName.isNotEmpty
            ? widget.managerName
            : (isAr ? 'مسؤول السائقين' : 'Driver Manager'),
        onClose: _isSubmitting ? null : () => Navigator.of(context).pop(false),
        isCloseDisabled: _isSubmitting,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            AppDialogErrorBanner(message: _errorMessage!),
            const SizedBox(height: 12),
          ],

          // Current balance summary card
          AppDialogSectionCard(
            backgroundColor: AppColors.primary.withValues(
              alpha: isDark ? 0.12 : 0.08,
            ),
            borderColor: AppColors.primary.withValues(alpha: 0.35),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.wallet,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'الرصيد الحالي المتاح' : 'Current Available Balance',
                        style: TextStyle(fontSize: 12, color: subtleText),
                      ),
                      const SizedBox(height: 2),
                      WalletLocalization.buildMoneyText(
                        _moneyFmt.format(widget.currentBalance),
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                        isArabic: isAr,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Payout mode toggle: Full zero-out vs Custom amount
          Text(
            isAr ? 'قيمة التحويل' : 'Payout Amount',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ModeOptionCard(
                  selected: _settleFullBalance,
                  icon: LucideIcons.checkCheck,
                  title: isAr ? 'تصفير كامل الرصيد' : 'Zero Out Full',
                  subtitle: '${_intFmt.format(_wholeBalance)} $currency',
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() {
                          _settleFullBalance = true;
                          _errorMessage = null;
                        }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeOptionCard(
                  selected: !_settleFullBalance,
                  icon: LucideIcons.slidersHorizontal,
                  title: isAr ? 'مبلغ مخصص' : 'Custom Amount',
                  subtitle: isAr ? 'جزء من الرصيد' : 'Partial payout',
                  onTap: _isSubmitting
                      ? null
                      : () => setState(() {
                          _settleFullBalance = false;
                          _errorMessage = null;
                        }),
                ),
              ),
            ],
          ),

          if (!_settleFullBalance) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _errorMessage = null),
              decoration: InputDecoration(
                labelText: isAr ? 'المبلغ المحوّل ($currency)' : 'Transfer Amount ($currency)',
                hintText: _wholeBalance > 0 ? _intFmt.format(_wholeBalance) : '0',
                prefixIcon: const Icon(LucideIcons.banknote, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(
                alpha: isDark ? 0.05 : 0.03,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    isAr ? 'الرصيد بعد التحويل' : 'Balance After Payout',
                    style: TextStyle(fontSize: 12.5, color: subtleText),
                  ),
                ),
                const SizedBox(width: 8),
                WalletLocalization.buildMoneyText(
                  _moneyFmt.format(balanceAfter),
                  TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: balanceAfter == 0
                        ? (isDark ? AppColors.success : const Color(0xFF047857))
                        : theme.colorScheme.onSurface,
                  ),
                  isArabic: isAr,
                  alignment: AlignmentDirectional.centerEnd,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Transfer Screenshot Upload section
          Text(
            isAr ? 'سكرين شوت التحويل (إيصال التحويل)' : 'Transfer Receipt Screenshot',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'سيتم إرساله لمسؤول السائقين في الإشعار وحفظه في سجل المحفظة'
                : 'Sent to the driver manager in the notification and saved in their ledger',
            style: TextStyle(fontSize: 11.5, color: subtleText),
          ),
          const SizedBox(height: 8),

          if (_receiptBytes != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
                color: theme.colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 190),
                      child: Image.memory(
                        _receiptBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.circleCheck,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _receiptFileName ?? 'receipt.jpg',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _pickReceipt(ImageSource.gallery),
                          icon: const Icon(LucideIcons.refreshCw, size: 14),
                          label: Text(
                            isAr ? 'تغيير' : 'Replace',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          tooltip: isAr ? 'حذف الصورة' : 'Remove image',
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() {
                                  _receiptBytes = null;
                                  _receiptFileName = null;
                                  _uploadedReceiptUrl = null;
                                }),
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(
                  alpha: isDark ? 0.04 : 0.025,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.imagePlus,
                    size: 28,
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'ارفع صورة التحويل (إنستا باي / محفظة إلكترونية)'
                        : 'Upload transfer screenshot (InstaPay / Mobile Wallet)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: subtleText),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickReceipt(ImageSource.gallery),
                        icon: const Icon(LucideIcons.image, size: 16),
                        label: Text(isAr ? 'اختر من المعرض' : 'Choose from Gallery'),
                      ),
                      if (!kIsWeb)
                        OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _pickReceipt(ImageSource.camera),
                          icon: const Icon(LucideIcons.camera, size: 16),
                          label: Text(isAr ? 'الكاميرا' : 'Camera'),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Optional transfer notes
          TextField(
            controller: _notesController,
            enabled: !_isSubmitting,
            maxLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: isAr ? 'ملاحظات التحويل (اختياري)' : 'Transfer Notes (Optional)',
              hintText: isAr
                  ? 'مثال: تم التحويل على إنستا باي رقم ...'
                  : 'e.g., Transferred via InstaPay ref #...',
              prefixIcon: const Icon(LucideIcons.fileText, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      footer: AppDialogFooter(
        cancelLabel: isAr ? 'إلغاء' : 'Cancel',
        onCancel: _isSubmitting ? null : () => Navigator.of(context).pop(false),
        confirmLabel: _settleFullBalance
            ? (isAr ? 'تصفير المحفظة وإرسال الإيصال' : 'Zero Out & Send Payout')
            : (isAr ? 'تأكيد التحويل' : 'Confirm Payout'),
        confirmIcon: LucideIcons.send,
        isLoading: _isSubmitting,
        loadingLabel: _statusLabel,
        onConfirm: _wholeBalance > 0 ? _submit : null,
      ),
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ModeOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = selected
        ? AppColors.primary
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
