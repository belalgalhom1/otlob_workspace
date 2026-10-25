import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import '../data/notification_providers.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';
import 'package:api/api.dart';
import 'package:vendor/core/utils/error_utils.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleArController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyArController = TextEditingController();
  String _audience = 'ALL';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _titleArController.dispose();
    _bodyController.dispose();
    _bodyArController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    final audienceLabel =
        {
          'ALL': l10n.allUsersGlobal,
          'CUSTOMERS': l10n.customersOnly,
          'DRIVERS': l10n.driversOnly,
          'VENDORS': l10n.vendorsOnly,
        }[_audience] ??
        _audience;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.radio, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(l10n.confirmBroadcast),
          ],
        ),
        content: Text(l10n.confirmBroadcastBody(audienceLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelAction),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(LucideIcons.send, size: 16),
            onPressed: () => Navigator.pop(context, true),
            label: Text(l10n.broadcastNow),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final dto = DispatchAnnouncementDto(
        (b) => b
          ..audience = DispatchAnnouncementDtoAudienceEnum.valueOf(_audience)
          ..title = _titleController.text.trim()
          ..titleAr = _titleArController.text.trim()
          ..body = _bodyController.text.trim()
          ..bodyAr = _bodyArController.text.trim(),
      );

      await ref
          .read(sharedNotificationsRepositoryProvider)
          .dispatchAnnouncement(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  LucideIcons.checkCircle,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context)!.announcementSuccess),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _formKey.currentState!.reset();
        _titleController.clear();
        _titleArController.clear();
        _bodyController.clear();
        _bodyArController.clear();
        setState(() => _audience = 'ALL');
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card with gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.9),
                      AppColors.primary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        LucideIcons.radio,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.announcementsTitle,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.announcementsSubtitle,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Form card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section title
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.settings2,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.newAnnouncementTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Audience selector (explicit label above the field —
                      // a floating labelText collides with the top border
                      // and gets clipped).
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.users,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.targetAudience,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _audience,
                        decoration: InputDecoration(
                          hintText: l10n.targetAudience,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(LucideIcons.users),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'ALL',
                            child: Text(l10n.allUsersGlobal),
                          ),
                          DropdownMenuItem(
                            value: 'CUSTOMERS',
                            child: Text(l10n.customersOnly),
                          ),
                          DropdownMenuItem(
                            value: 'DRIVERS',
                            child: Text(l10n.driversOnly),
                          ),
                          DropdownMenuItem(
                            value: 'VENDORS',
                            child: Text(l10n.vendorsOnly),
                          ),
                        ],
                        onChanged: (val) => setState(() => _audience = val!),
                      ),
                      const SizedBox(height: 28),

                      // Language columns
                      if (isMobile) ...[
                        _buildLanguageSection(
                          context,
                          l10n,
                          label: l10n.english,
                          icon: LucideIcons.languages,
                          titleController: _titleController,
                          bodyController: _bodyController,
                          titleLabel: l10n.titleEn,
                          bodyLabel: l10n.messageBodyEn,
                          required: true,
                          rtl: false,
                        ),
                        const SizedBox(height: 20),
                        _buildLanguageSection(
                          context,
                          l10n,
                          label: l10n.arabic,
                          icon: LucideIcons.type,
                          titleController: _titleArController,
                          bodyController: _bodyArController,
                          titleLabel: l10n.titleAr,
                          bodyLabel: l10n.messageBodyAr,
                          required: false,
                          rtl: true,
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildLanguageSection(
                                context,
                                l10n,
                                label: l10n.english,
                                icon: LucideIcons.languages,
                                titleController: _titleController,
                                bodyController: _bodyController,
                                titleLabel: l10n.titleEn,
                                bodyLabel: l10n.messageBodyEn,
                                required: true,
                                rtl: false,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildLanguageSection(
                                context,
                                l10n,
                                label: l10n.arabic,
                                icon: LucideIcons.type,
                                titleController: _titleArController,
                                bodyController: _bodyArController,
                                titleLabel: l10n.titleAr,
                                bodyLabel: l10n.messageBodyAr,
                                required: false,
                                rtl: true,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 28),

                      // Submit button (taller with centered text so the
                      // two-word label never looks cramped or clipped).
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                          ),
                          icon: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.send, size: 18),
                          label: Flexible(
                            child: Text(
                              _isLoading
                                  ? l10n.sending
                                  : l10n.broadcastAnnouncement,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          onPressed: _isLoading ? null : _submit,
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

  Widget _buildLanguageSection(
    BuildContext context,
    AppLocalizations l10n, {
    required String label,
    required IconData icon,
    required TextEditingController titleController,
    required TextEditingController bodyController,
    required String titleLabel,
    required String bodyLabel,
    required bool required,
    required bool rtl,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: titleController,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: titleLabel,
            border: const OutlineInputBorder(),
          ),
          validator: required
              ? (val) => (val == null || val.isEmpty) ? l10n.required : null
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: bodyController,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          decoration: InputDecoration(
            labelText: bodyLabel,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          validator: required
              ? (val) => (val == null || val.isEmpty) ? l10n.required : null
              : null,
        ),
      ],
    );
  }
}
