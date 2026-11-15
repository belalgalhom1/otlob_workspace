import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/data.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'legal_documents_provider.dart';

class LegalDocumentsScreen extends ConsumerStatefulWidget {
  const LegalDocumentsScreen({super.key});

  @override
  ConsumerState<LegalDocumentsScreen> createState() =>
      _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends ConsumerState<LegalDocumentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(legalDocumentsProvider.notifier).fetchAllDocuments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(legalDocumentsProvider);

    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Screen Header & Action Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 650;

                final infoBlock = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        LucideIcons.fileCheck2,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'إدارة الشروط والسياسات القانونية'
                                : 'Legal Documents & Compliance',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isArabic
                                ? 'إنشاء وتعديل ونشر شروط الاستخدام وسياسة الخصوصية، ومتابعة موافقات المستخدمين'
                                : 'Create, edit, publish legal policies and monitor user acceptances across the platform',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final actionBtn = ElevatedButton.icon(
                  onPressed: () => _openCreateDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(
                    isArabic ? 'إصدار جديد' : 'New Version Draft',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 14,
                    ),
                  ),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      infoBlock,
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(width: double.infinity, child: actionBtn),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: infoBlock),
                    const SizedBox(width: AppSpacing.md),
                    actionBtn,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Modern Pill Segmented Tab Bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.08),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.scrollText, size: 16),
                      const SizedBox(width: 8),
                      Text(isArabic ? 'شروط الاستخدام' : 'Terms of Use'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.termsDocuments.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 16),
                      const SizedBox(width: 8),
                      Text(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.privacyDocuments.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Content body
          Expanded(
            child: state.isLoading &&
                    state.termsDocuments.isEmpty &&
                    state.privacyDocuments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDocumentTabList(
                        context,
                        type: 'TERMS_OF_USE',
                        docs: state.termsDocuments,
                        isArabic: isArabic,
                      ),
                      _buildDocumentTabList(
                        context,
                        type: 'PRIVACY_POLICY',
                        docs: state.privacyDocuments,
                        isArabic: isArabic,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTabList(
    BuildContext context, {
    required String type,
    required List<Map<String, dynamic>> docs,
    required bool isArabic,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeDoc = docs.cast<Map<String, dynamic>?>().firstWhere(
          (d) => d?['isPublished'] == true,
          orElse: () => null,
        );

    if (docs.isEmpty) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(AppSpacing.xxl),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.fileQuestion,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isArabic
                    ? 'لا توجد وثائق مسجلة حالياً'
                    : 'No documents recorded yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isArabic
                    ? 'اضغط على "إصدار جديد" لإنشاء مسودة وتجهيزها للنشر'
                    : 'Click "New Version Draft" to create a document version and prepare it for release',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => _openCreateDialog(context),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text(
                  isArabic ? 'إنشاء مسودة جديدة' : 'Create First Draft',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        // Summary Card of Active Document
        if (activeDoc != null) ...[
          _buildActiveDocumentBanner(context, activeDoc, isArabic),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Section Title: Version History
        Row(
          children: [
            Text(
              isArabic ? 'سجل الإصدارات' : 'Version History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${docs.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // List of document cards
        ...docs.map((doc) => _buildDocumentCard(context, doc, isArabic)),
      ],
    );
  }

  Widget _buildActiveDocumentBanner(
    BuildContext context,
    Map<String, dynamic> doc,
    bool isArabic,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final version = doc['version']?.toString() ?? '1.0';
    final title = isArabic
        ? (doc['titleAr']?.toString() ?? doc['title']?.toString() ?? '')
        : (doc['title']?.toString() ?? doc['titleAr']?.toString() ?? '');
    final altTitle = isArabic
        ? (doc['title']?.toString() ?? '')
        : (doc['titleAr']?.toString() ?? '');
    final count = doc['acceptanceCount']?.toString() ?? '0';
    final id = doc['id']?.toString() ?? '';
    final publishedAt = doc['publishedAt']?.toString();

    String formattedDate = '';
    if (publishedAt != null && publishedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(publishedAt);
        formattedDate = isArabic
            ? '${dt.year}/${dt.month}/${dt.day}'
            : '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = publishedAt;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final headerRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.checkCircle2,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isArabic
                                    ? 'الإصدار النشط المنشور'
                                    : 'Active Enforced Version',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'v$version',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      softWrap: true,
                    ),
                    if (altTitle.isNotEmpty && altTitle != title) ...[
                      const SizedBox(height: 2),
                      Text(
                        altTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final metricsAndActions = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
            children: [
              // Metrics Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.users,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count ${isArabic ? 'موافقات مسجلة' : 'Accepted Users'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (formattedDate.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.calendar,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Preview Action
              OutlinedButton.icon(
                onPressed: () => _openPreviewDialog(context, id, isArabic),
                icon: const Icon(LucideIcons.eye, size: 15),
                label: Text(isArabic ? 'معاينة' : 'Preview'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Stats Action
              OutlinedButton.icon(
                onPressed: () => _openStatsDialog(context, id, isArabic),
                icon: const Icon(LucideIcons.barChart2, size: 15),
                label: Text(isArabic ? 'الإحصائيات' : 'Metrics'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerRow,
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.08),
              ),
              const SizedBox(height: AppSpacing.sm),
              metricsAndActions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    Map<String, dynamic> doc,
    bool isArabic,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPublished = doc['isPublished'] == true;
    final version = doc['version']?.toString() ?? '1.0';
    final titleEn = doc['title']?.toString() ?? '';
    final titleAr = doc['titleAr']?.toString() ?? '';
    final count = doc['acceptanceCount']?.toString() ?? '0';
    final id = doc['id']?.toString() ?? '';

    final primaryTitle = isArabic ? titleAr : titleEn;
    final secondaryTitle = isArabic ? titleEn : titleAr;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPublished
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : theme.dividerColor.withValues(alpha: 0.12),
          width: isPublished ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Status Badge, Version, Acceptances
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPublished
                      ? const Color(0xFF10B981).withValues(alpha: 0.14)
                      : Colors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPublished ? LucideIcons.checkCheck : LucideIcons.clock,
                      size: 13,
                      color: isPublished
                          ? const Color(0xFF10B981)
                          : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPublished
                          ? (isArabic ? 'منشور ونشط' : 'Published & Active')
                          : (isArabic ? 'مسودة' : 'Draft'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isPublished
                            ? const Color(0xFF10B981)
                            : Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Version Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.gitBranch,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'v$version',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Acceptances Chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.userCheck,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count ${isArabic ? 'موافقات' : 'acceptances'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bilingual titles with NO truncation
          Text(
            primaryTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            softWrap: true,
          ),
          if (secondaryTitle.isNotEmpty && secondaryTitle != primaryTitle) ...[
            const SizedBox(height: 3),
            Text(
              secondaryTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              softWrap: true,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.08),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Action Buttons
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // View / Preview
              OutlinedButton.icon(
                onPressed: () => _openPreviewDialog(context, id, isArabic),
                icon: const Icon(LucideIcons.eye, size: 15),
                label: Text(isArabic ? 'معاينة' : 'Preview'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),

              // Edit
              OutlinedButton.icon(
                onPressed: () => _openEditDialog(context, id, isArabic),
                icon: const Icon(LucideIcons.pencil, size: 15),
                label: Text(isArabic ? 'تعديل' : 'Edit'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),

              // Stats breakdown
              OutlinedButton.icon(
                onPressed: () => _openStatsDialog(context, id, isArabic),
                icon: const Icon(LucideIcons.barChart2, size: 15),
                label: Text(isArabic ? 'الإحصائيات' : 'Stats'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),

              // Publish (if not currently published)
              if (!isPublished) ...[
                ElevatedButton.icon(
                  onPressed: () =>
                      _confirmPublish(context, id, version, isArabic),
                  icon: const Icon(LucideIcons.uploadCloud, size: 15),
                  label: Text(
                    isArabic ? 'نشر هذا الإصدار' : 'Publish Version',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),

                // Delete Button (Proper aligned button)
                OutlinedButton.icon(
                  onPressed: () =>
                      _confirmDelete(context, id, version, isArabic),
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 14,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    isArabic ? 'حذف' : 'Delete',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.35),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.lock,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isArabic
                            ? 'الإصدار المعتمد'
                            : 'Active Enforced',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── Actions & Dialogs ─────────────────────────────────────────────────────

  Future<void> _openCreateDialog(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final initialType =
        _tabController.index == 0 ? 'TERMS_OF_USE' : 'PRIVACY_POLICY';

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LegalDocumentFormDialog(initialType: initialType),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم حفظ المسودة بنجاح'
                : 'Draft created successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openEditDialog(
    BuildContext context,
    String id,
    bool isArabic,
  ) async {
    final repo = ref.read(adminLegalDocumentsRepositoryProvider);
    Map<String, dynamic>? doc;
    try {
      doc = await repo.getDocumentById(id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (doc == null || !context.mounted) return;
    final loadedDoc = doc;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LegalDocumentFormDialog(
        documentId: id,
        initialType: loadedDoc['type']?.toString() ?? 'TERMS_OF_USE',
        initialVersion: loadedDoc['version']?.toString() ?? '',
        initialTitle: loadedDoc['title']?.toString() ?? '',
        initialTitleAr: loadedDoc['titleAr']?.toString() ?? '',
        initialContent: loadedDoc['content']?.toString() ?? '',
        initialContentAr: loadedDoc['contentAr']?.toString() ?? '',
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم تحديث الوثيقة بنجاح'
                : 'Document updated successfully',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _openPreviewDialog(
    BuildContext context,
    String id,
    bool isArabic,
  ) async {
    final repo = ref.read(adminLegalDocumentsRepositoryProvider);
    final doc = await repo.getDocumentById(id);
    if (doc == null || !context.mounted) return;

    bool showArabic = isArabic;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final title = showArabic
                ? (doc['titleAr'] ?? doc['title'] ?? '')
                : (doc['title'] ?? doc['titleAr'] ?? '');
            final content = showArabic
                ? (doc['contentAr'] ?? doc['content'] ?? '')
                : (doc['content'] ?? doc['contentAr'] ?? '');
            final version = doc['version']?.toString() ?? '1.0';

            return AppDialog(
              maxWidth: 820,
              maxHeight: 740,
              scrollableBody: false,
              expandBody: true,
              header: AppDialogHeader(
                icon: LucideIcons.fileText,
                title: title,
                subtitleWidget: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppBadgePill(
                      text: 'v$version',
                      accentColor: AppColors.primary,
                    ),
                    AppBadgePill(
                      text: showArabic ? 'عربي' : 'EN',
                    ),
                  ],
                ),
                onClose: () => Navigator.pop(ctx),
              ),
              body: LegalDocumentView(
                title: title,
                version: version,
                content: content,
                isArabic: showArabic,
                onLanguageToggle: () {
                  setDialogState(() => showArabic = !showArabic);
                },
              ),
              footer: AppDialogFooter(
                confirmLabel: showArabic ? 'إغلاق' : 'Close',
                onConfirm: () => Navigator.pop(ctx),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openStatsDialog(
    BuildContext context,
    String id,
    bool isArabic,
  ) async {
    final notifier = ref.read(legalDocumentsProvider.notifier);
    final stats = await notifier.fetchDocumentStats(id);
    if (stats == null || !context.mounted) return;

    final total = stats['totalAcceptances'] ?? 0;
    final breakdown = stats['roleBreakdown'] as Map? ?? {};

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return AppDialog(
          maxWidth: 520,
          header: AppDialogHeader(
            icon: LucideIcons.barChart2,
            title: isArabic
                ? 'إحصائيات موافقات المستخدمين'
                : 'Acceptance Metrics',
            subtitle: isArabic
                ? 'ملخص الموافقات المسجلة حسب نوع المستخدم'
                : 'Summary of recorded acceptances by user role',
            onClose: () => Navigator.pop(ctx),
          ),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDialogSectionCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                borderColor: AppColors.primary.withValues(alpha: 0.25),
                child: Column(
                  children: [
                    Text(
                      '$total',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? AppColors.primary
                            : const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic
                          ? 'إجمالي الموافقات المسجلة'
                          : 'Total Acceptances Recorded',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isArabic
                    ? 'التوزيع حسب نوع المستخدم:'
                    : 'Breakdown by User Role:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppDialogSectionCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _buildRoleStatTile(
                      ctx,
                      role: isArabic ? 'العملاء (Customers)' : 'Customers',
                      count: breakdown['CUSTOMER'] ?? 0,
                      icon: LucideIcons.user,
                    ),
                    const Divider(height: 8),
                    _buildRoleStatTile(
                      ctx,
                      role: isArabic ? 'مندوبي التوصيل (Drivers)' : 'Drivers',
                      count: breakdown['DRIVER'] ?? 0,
                      icon: LucideIcons.bike,
                    ),
                    const Divider(height: 8),
                    _buildRoleStatTile(
                      ctx,
                      role: isArabic
                          ? 'المتاجر والشركاء (Vendors)'
                          : 'Vendors',
                      count: breakdown['VENDOR_MEMBER'] ?? 0,
                      icon: LucideIcons.store,
                    ),
                    const Divider(height: 8),
                    _buildRoleStatTile(
                      ctx,
                      role: isArabic
                          ? 'المشرفين والإداريين (Admins)'
                          : 'Staff & Admins',
                      count: (breakdown['ADMIN'] ?? 0) +
                          (breakdown['SUPER_ADMIN'] ?? 0),
                      icon: LucideIcons.shieldCheck,
                    ),
                  ],
                ),
              ),
            ],
          ),
          footer: AppDialogFooter(
            confirmLabel: isArabic ? 'إغلاق' : 'Close',
            onConfirm: () => Navigator.pop(ctx),
          ),
        );
      },
    );
  }

  Widget _buildRoleStatTile(
    BuildContext context, {
    required String role,
    required dynamic count,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              role,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              softWrap: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surfaceContainerHighest
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPublish(
    BuildContext context,
    String id,
    String version,
    bool isArabic,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: isArabic ? 'تأكيد نشر الإصدار' : 'Confirm Version Release',
      subtitle: 'v$version',
      message: isArabic
          ? 'هل أنت متأكد من نشر الإصدار v$version؟\n\nبمجرد النشر، سيصبح هذا الإصدار هو المعتمد رسميًا، وسيتوجب على كافة المستخدمين (عملاء، مناديب، متاجر) الموافقة على هذا الإصدار الجديد عند فتح التطبيق للمتابعة.'
          : 'Are you sure you want to publish v$version?\n\nPublishing will make this the active version, requiring all users (Customers, Drivers, Vendors) to accept the updated terms before continuing in the app.',
      icon: LucideIcons.checkCircle2,
      accentColor: AppColors.success,
      confirmBackgroundColor: const Color(0xFF059669),
      confirmForegroundColor: Colors.white,
      confirmIcon: LucideIcons.send,
      confirmLabel: isArabic ? 'نشر الآن' : 'Publish Now',
      cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(legalDocumentsProvider.notifier)
          .publishDocument(id);
      if (context.mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم نشر الإصدار بنجاح وتفعيله لكافة المستخدمين'
                  : 'Version published and activated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String id,
    String version,
    bool isArabic,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: isArabic ? 'تأكيد حذف المسودة' : 'Confirm Delete',
      subtitle: 'v$version',
      message: isArabic
          ? 'هل أنت متأكد من رغبتك في حذف هذا الإصدار (v$version)؟'
          : 'Are you sure you want to delete this version (v$version)?',
      isDestructive: true,
      confirmIcon: LucideIcons.trash2,
      confirmLabel: isArabic ? 'حذف' : 'Delete',
      cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
    );

    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(legalDocumentsProvider.notifier)
          .deleteDocument(id);
      if (context.mounted && ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم حذف الإصدار بنجاح'
                  : 'Version deleted successfully',
            ),
          ),
        );
      }
    }
  }
}

class _LegalDocumentFormDialog extends ConsumerStatefulWidget {
  final String initialType;
  final String? documentId;
  final String? initialVersion;
  final String? initialTitle;
  final String? initialTitleAr;
  final String? initialContent;
  final String? initialContentAr;

  const _LegalDocumentFormDialog({
    required this.initialType,
    this.documentId,
    this.initialVersion,
    this.initialTitle,
    this.initialTitleAr,
    this.initialContent,
    this.initialContentAr,
  });

  @override
  ConsumerState<_LegalDocumentFormDialog> createState() =>
      _LegalDocumentFormDialogState();
}

class _LegalDocumentFormDialogState
    extends ConsumerState<_LegalDocumentFormDialog> {
  static const _defaultTitleEnTerms = 'Terms of Use & Service Agreement';
  static const _defaultTitleEnPrivacy = 'Privacy Policy & Data Protection';
  static const _defaultTitleArTerms = 'شروط الاستخدام واتفاقية الخدمة';
  static const _defaultTitleArPrivacy = 'سياسة الخصوصية وحماية البيانات';

  final _formKey = GlobalKey<FormState>();
  late String _type;
  late final TextEditingController _versionController;
  late final TextEditingController _titleController;
  late final TextEditingController _titleArController;
  late final TextEditingController _contentController;
  late final TextEditingController _contentArController;

  bool _isSaving = false;
  String? _submitError;

  bool get _isEdit => widget.documentId != null;

  static String _defaultTitleEn(String type) =>
      type == 'TERMS_OF_USE' ? _defaultTitleEnTerms : _defaultTitleEnPrivacy;

  static String _defaultTitleAr(String type) =>
      type == 'TERMS_OF_USE' ? _defaultTitleArTerms : _defaultTitleArPrivacy;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _versionController = TextEditingController(
      text: widget.initialVersion ?? '1.1',
    );
    _titleController = TextEditingController(
      text: widget.initialTitle ?? _defaultTitleEn(_type),
    );
    _titleArController = TextEditingController(
      text: widget.initialTitleAr ?? _defaultTitleAr(_type),
    );
    _contentController = TextEditingController(
      text: widget.initialContent ?? '',
    );
    _contentArController = TextEditingController(
      text: widget.initialContentAr ?? '',
    );
  }

  @override
  void dispose() {
    _versionController.dispose();
    _titleController.dispose();
    _titleArController.dispose();
    _contentController.dispose();
    _contentArController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? val) {
    if (val == null || val == _type) return;
    final previousType = _type;
    setState(() {
      _type = val;
      if (!_isEdit) {
        final currentEn = _titleController.text.trim();
        if (currentEn.isEmpty || currentEn == _defaultTitleEn(previousType)) {
          _titleController.text = _defaultTitleEn(val);
        }
        final currentAr = _titleArController.text.trim();
        if (currentAr.isEmpty || currentAr == _defaultTitleAr(previousType)) {
          _titleArController.text = _defaultTitleAr(val);
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final repo = ref.read(adminLegalDocumentsRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateDocument(
          widget.documentId!,
          title: _titleController.text.trim(),
          titleAr: _titleArController.text.trim(),
          content: _contentController.text.trim(),
          contentAr: _contentArController.text.trim(),
          version: _versionController.text.trim(),
        );
      } else {
        await repo.createDocument(
          type: _type,
          title: _titleController.text.trim(),
          titleAr: _titleArController.text.trim(),
          content: _contentController.text.trim(),
          contentAr: _contentArController.text.trim(),
          version: _versionController.text.trim(),
        );
      }

      try {
        await ref.read(legalDocumentsProvider.notifier).fetchAllDocuments();
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = ErrorUtils.translate(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final isMobile = AppDialogStyles.isMobile(context);

    final typeLabel = _type == 'TERMS_OF_USE'
        ? (isArabic ? 'شروط الاستخدام' : 'Terms of Use')
        : (isArabic ? 'سياسة الخصوصية' : 'Privacy Policy');

    final typeDropdownField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(
          label: isArabic ? 'نوع الوثيقة' : 'Document Type',
          isRequired: true,
        ),
        DropdownButtonFormField<String>(
          initialValue: _type,
          isExpanded: true,
          dropdownColor: AppDialogStyles.dropdownColor(context),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
          decoration: AppDialogStyles.inputDecoration(
            context,
            hintText: isArabic ? 'اختر نوع الوثيقة' : 'Select document type',
            icon: LucideIcons.fileType,
          ),
          items: [
            DropdownMenuItem(
              value: 'TERMS_OF_USE',
              child: Text(
                isArabic
                    ? 'شروط الاستخدام (Terms of Use)'
                    : 'Terms of Use',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'PRIVACY_POLICY',
              child: Text(
                isArabic
                    ? 'سياسة الخصوصية (Privacy Policy)'
                    : 'Privacy Policy',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: _isSaving ? null : _onTypeChanged,
        ),
      ],
    );

    final versionField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(
          label: isArabic ? 'رقم الإصدار' : 'Version',
          isRequired: true,
        ),
        TextFormField(
          controller: _versionController,
          enabled: !_isSaving,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.next,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: AppDialogStyles.inputDecoration(
            context,
            hintText: isArabic ? 'مثال: 1.1' : 'e.g. 1.1',
            icon: LucideIcons.gitBranch,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? (isArabic ? 'رقم الإصدار مطلوب' : 'Version is required')
              : null,
        ),
      ],
    );

    return AppDialog(
      maxWidth: 740,
      maxHeight: 760,
      canPop: !_isSaving,
      header: AppDialogHeader(
        icon: _isEdit ? LucideIcons.fileEdit : LucideIcons.filePlus2,
        title: _isEdit
            ? (isArabic ? 'تعديل الوثيقة القانونية' : 'Edit Legal Document')
            : (isArabic ? 'إنشاء مسودة إصدار جديد' : 'New Version Draft'),
        subtitleWidget: _isEdit
            ? Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppBadgePill(
                    text: typeLabel,
                    accentColor: AppColors.primary,
                  ),
                  Text(
                    isArabic
                        ? 'تحديث بيانات ونص الوثيقة'
                        : 'Update policy details & content',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Text(
                isArabic
                    ? 'إعداد بيانات الإصدار والمحتوى باللغتين'
                    : 'Configure version metadata and bilingual policy text',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                softWrap: true,
              ),
        isCloseDisabled: _isSaving,
        onClose: () => Navigator.of(context).pop(false),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_submitError != null && _submitError!.trim().isNotEmpty) ...[
              AppDialogErrorBanner(message: _submitError!),
              const SizedBox(height: 16),
            ],
            if (_isEdit)
              versionField
            else if (isMobile) ...[
              typeDropdownField,
              const SizedBox(height: 14),
              versionField,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: typeDropdownField),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: versionField),
                ],
              ),
            const SizedBox(height: 16),
            AppFieldLabel(
              label: isArabic ? 'العنوان' : 'Title',
              isRequired: true,
              languageTag: 'EN',
            ),
            TextFormField(
              controller: _titleController,
              enabled: !_isSaving,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: 'e.g. Terms of Use & Service Agreement',
                icon: LucideIcons.heading,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (isArabic
                      ? 'العنوان بالإنجليزية مطلوب'
                      : 'Title in English is required')
                  : null,
            ),
            const SizedBox(height: 16),
            AppFieldLabel(
              label: isArabic ? 'العنوان' : 'Title',
              isRequired: true,
              languageTag: 'عربي',
            ),
            TextFormField(
              controller: _titleArController,
              enabled: !_isSaving,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: 'مثال: شروط الاستخدام واتفاقية الخدمة',
                icon: LucideIcons.heading,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (isArabic
                      ? 'العنوان باللغة العربية مطلوب'
                      : 'Arabic title is required')
                  : null,
            ),
            const SizedBox(height: 16),
            AppFieldLabel(
              label: isArabic ? 'محتوى الوثيقة' : 'Document Content',
              isRequired: !_isEdit,
              languageTag: 'EN',
              formatTag: 'Markdown',
            ),
            TextFormField(
              controller: _contentController,
              enabled: !_isSaving,
              textDirection: TextDirection.ltr,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              minLines: isMobile ? 4 : 6,
              maxLines: 10,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.5,
              ),
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: isArabic
                    ? 'اكتب النص القانوني بالإنجليزية (يدعم # العناوين و **النص العريض**)...'
                    : 'Write policy terms in English (supports # headings, **bold**, lists)...',
                isMultiline: true,
              ),
              validator: _isEdit
                  ? null
                  : (v) => (v == null || v.trim().isEmpty)
                      ? (isArabic
                          ? 'المحتوى بالإنجليزية مطلوب'
                          : 'English content is required')
                      : null,
            ),
            const SizedBox(height: 16),
            AppFieldLabel(
              label: isArabic ? 'محتوى الوثيقة' : 'Document Content',
              isRequired: !_isEdit,
              languageTag: 'عربي',
              formatTag: 'Markdown',
            ),
            TextFormField(
              controller: _contentArController,
              enabled: !_isSaving,
              textDirection: TextDirection.rtl,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              minLines: isMobile ? 4 : 6,
              maxLines: 10,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.6,
              ),
              decoration: AppDialogStyles.inputDecoration(
                context,
                hintText: isArabic
                    ? 'اكتب النص القانوني باللغة العربية (يدعم # العناوين و **التنسيق**)...'
                    : 'Write policy terms in Arabic (supports # headings, **bold**, lists)...',
                isMultiline: true,
              ),
              validator: _isEdit
                  ? null
                  : (v) => (v == null || v.trim().isEmpty)
                      ? (isArabic
                          ? 'المحتوى باللغة العربية مطلوب'
                          : 'Arabic content is required')
                      : null,
            ),
          ],
        ),
      ),
      footer: AppDialogFooter(
        cancelLabel: isArabic ? 'إلغاء' : 'Cancel',
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: _isEdit
            ? (isArabic ? 'حفظ التعديلات' : 'Save Changes')
            : (isArabic ? 'حفظ المسودة' : 'Save Draft'),
        confirmIcon: LucideIcons.save,
        isLoading: _isSaving,
        loadingLabel: isArabic ? 'جارٍ الحفظ...' : 'Saving...',
        onConfirm: _submit,
      ),
    );
  }
}
