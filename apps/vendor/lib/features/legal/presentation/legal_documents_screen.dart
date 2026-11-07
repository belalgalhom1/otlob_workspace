import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:data/data.dart';
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
    final formKey = GlobalKey<FormState>();

    String type = _tabController.index == 0 ? 'TERMS_OF_USE' : 'PRIVACY_POLICY';
    final titleController = TextEditingController(
      text: type == 'TERMS_OF_USE'
          ? 'Terms of Use & Service Agreement'
          : 'Privacy Policy & Data Protection',
    );
    final titleArController = TextEditingController(
      text: type == 'TERMS_OF_USE'
          ? 'شروط الاستخدام واتفاقية الخدمة'
          : 'سياسة الخصوصية وحماية البيانات',
    );
    final versionController = TextEditingController(text: '1.1');
    final contentController = TextEditingController();
    final contentArController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return DialogScaffold(
              child: Dialog(
                backgroundColor:
                    isDark ? theme.colorScheme.surface : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  LucideIcons.filePlus2,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  isArabic
                                      ? 'إنشاء مسودة إصدار جديد'
                                      : 'New Version Draft',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.x, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Document Type Selector
                          DropdownButtonFormField<String>(
                            initialValue: type,
                            decoration: InputDecoration(
                              labelText: isArabic
                                  ? 'نوع الوثيقة'
                                  : 'Document Type',
                              prefixIcon: const Icon(LucideIcons.fileType),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'TERMS_OF_USE',
                                child: Text(
                                  isArabic
                                      ? 'شروط الاستخدام (Terms of Use)'
                                      : 'Terms of Use',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'PRIVACY_POLICY',
                                child: Text(
                                  isArabic
                                      ? 'سياسة الخصوصية (Privacy Policy)'
                                      : 'Privacy Policy',
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => type = val);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Version string
                          TextFormField(
                            controller: versionController,
                            decoration: InputDecoration(
                              labelText: isArabic
                                  ? 'رقم الإصدار (مثال: 1.1)'
                                  : 'Version (e.g. 1.1)',
                              prefixIcon: const Icon(LucideIcons.gitBranch),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? (isArabic
                                    ? 'رقم الإصدار مطلوب'
                                    : 'Version is required')
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Title English
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title (English)',
                              prefixIcon: Icon(LucideIcons.heading),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Title in English is required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Title Arabic
                          TextFormField(
                            controller: titleArController,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              labelText: 'العنوان (باللغة العربية)',
                              prefixIcon: Icon(LucideIcons.heading),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'العنوان باللغة العربية مطلوب'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Content English
                          TextFormField(
                            controller: contentController,
                            maxLines: 7,
                            decoration: const InputDecoration(
                              labelText:
                                  'Content (English - Markdown supported)',
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Content is required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Content Arabic
                          TextFormField(
                            controller: contentArController,
                            textDirection: TextDirection.rtl,
                            maxLines: 7,
                            decoration: const InputDecoration(
                              labelText: 'المحتوى (باللغة العربية - يدعم التنسيق)',
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'المحتوى باللغة العربية مطلوب'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              PrimaryButton(
                                text: isArabic ? 'حفظ المسودة' : 'Save Draft',
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  Navigator.pop(ctx);
                                  final ok = await ref
                                      .read(legalDocumentsProvider.notifier)
                                      .createDocument(
                                        type: type,
                                        title: titleController.text,
                                        titleAr: titleArController.text,
                                        content: contentController.text,
                                        contentAr: contentArController.text,
                                        version: versionController.text,
                                      );
                                  if (context.mounted && ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isArabic
                                              ? 'تم حفظ المسودة بنجاح'
                                              : 'Draft created successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    String id,
    bool isArabic,
  ) async {
    final formKey = GlobalKey<FormState>();
    final notifier = ref.read(legalDocumentsProvider.notifier);
    final repo = ref.read(adminLegalDocumentsRepositoryProvider);

    final doc = await repo.getDocumentById(id);
    if (doc == null || !context.mounted) return;

    final titleController = TextEditingController(text: doc['title'] ?? '');
    final titleArController = TextEditingController(text: doc['titleAr'] ?? '');
    final versionController = TextEditingController(text: doc['version'] ?? '');
    final contentController = TextEditingController(text: doc['content'] ?? '');
    final contentArController =
        TextEditingController(text: doc['contentAr'] ?? '');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return DialogScaffold(
          child: Dialog(
            backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 720),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.fileEdit,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isArabic
                                  ? 'تعديل الوثيقة القانونية'
                                  : 'Edit Legal Document',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: versionController,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'رقم الإصدار' : 'Version',
                          prefixIcon: const Icon(LucideIcons.gitBranch),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? (isArabic
                                ? 'رقم الإصدار مطلوب'
                                : 'Version is required')
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title (English)',
                          prefixIcon: Icon(LucideIcons.heading),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Title in English is required'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: titleArController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'العنوان (باللغة العربية)',
                          prefixIcon: Icon(LucideIcons.heading),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'العنوان باللغة العربية مطلوب'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: contentController,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'Content (English)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: contentArController,
                        textDirection: TextDirection.rtl,
                        maxLines: 7,
                        decoration: const InputDecoration(
                          labelText: 'المحتوى (باللغة العربية)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          PrimaryButton(
                            text: isArabic ? 'حفظ التعديلات' : 'Save Changes',
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              Navigator.pop(ctx);
                              final ok = await notifier.updateDocument(
                                id,
                                title: titleController.text,
                                titleAr: titleArController.text,
                                content: contentController.text,
                                contentAr: contentArController.text,
                                version: versionController.text,
                              );
                              if (context.mounted && ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isArabic
                                          ? 'تم تحديث الوثيقة بنجاح'
                                          : 'Document updated successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final title = showArabic
                ? (doc['titleAr'] ?? doc['title'] ?? '')
                : (doc['title'] ?? doc['titleAr'] ?? '');
            final content = showArabic
                ? (doc['contentAr'] ?? doc['content'] ?? '')
                : (doc['content'] ?? doc['contentAr'] ?? '');
            final version = doc['version']?.toString() ?? '1.0';

            return DialogScaffold(
              child: Dialog(
                backgroundColor:
                    isDark ? theme.colorScheme.surface : Colors.white,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 820,
                    maxHeight: 740,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor
                                  .withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.fileText,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LegalDocumentView(
                          title: title,
                          version: version,
                          content: content,
                          isArabic: showArabic,
                          onLanguageToggle: () {
                            setDialogState(() => showArabic = !showArabic);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
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
        final isDark = theme.brightness == Brightness.dark;

        return DialogScaffold(
          child: Dialog(
            backgroundColor:
                isDark ? theme.colorScheme.surface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.barChart2,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isArabic
                                ? 'إحصائيات موافقات المستخدمين'
                                : 'Acceptance Metrics',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$total',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    isArabic
                        ? 'التوزيع حسب نوع المستخدم:'
                        : 'Breakdown by User Role:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildRoleStatTile(
                    ctx,
                    role: isArabic ? 'العملاء (Customers)' : 'Customers',
                    count: breakdown['CUSTOMER'] ?? 0,
                    icon: LucideIcons.user,
                  ),
                  _buildRoleStatTile(
                    ctx,
                    role: isArabic ? 'مندوبي التوصيل (Drivers)' : 'Drivers',
                    count: breakdown['DRIVER'] ?? 0,
                    icon: LucideIcons.bike,
                  ),
                  _buildRoleStatTile(
                    ctx,
                    role: isArabic ? 'المتاجر والشركاء (Vendors)' : 'Vendors',
                    count: breakdown['VENDOR_MEMBER'] ?? 0,
                    icon: LucideIcons.store,
                  ),
                  _buildRoleStatTile(
                    ctx,
                    role: isArabic
                        ? 'المشرفين والإداريين (Admins)'
                        : 'Staff & Admins',
                    count: (breakdown['ADMIN'] ?? 0) +
                        (breakdown['SUPER_ADMIN'] ?? 0),
                    icon: LucideIcons.shieldCheck,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    text: isArabic ? 'إغلاق' : 'Close',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            isArabic ? 'تأكيد نشر الإصدار' : 'Confirm Version Release',
          ),
          content: Text(
            isArabic
                ? 'هل أنت متأكد من نشر الإصدار v$version؟\n\nبمجرد النشر، سيصبح هذا الإصدار هو المعتمد رسميًا، وسيتوجب على كافة المستخدمين (عملاء، مناديب، متاجر) الموافقة على هذا الإصدار الجديد عند فتح التطبيق للمتابعة.'
                : 'Are you sure you want to publish v$version?\n\nPublishing will make this the active version, requiring all users (Customers, Drivers, Vendors) to accept the updated terms before continuing in the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: Text(isArabic ? 'نشر الآن' : 'Publish Now'),
            ),
          ],
        );
      },
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isArabic ? 'تأكيد حذف المسودة' : 'Confirm Delete'),
          content: Text(
            isArabic
                ? 'هل أنت متأكد من رغبتك في حذف هذا الإصدار (v$version)؟'
                : 'Are you sure you want to delete this version (v$version)?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isArabic ? 'حذف' : 'Delete'),
            ),
          ],
        );
      },
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
