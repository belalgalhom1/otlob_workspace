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
    final state = ref.watch(legalDocumentsProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Screen Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 650;
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              LucideIcons.fileCheck2,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isArabic
                                      ? 'إدارة الشروط والسياسات القانونية'
                                      : 'Legal Documents Management',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isArabic
                                      ? 'إنشاء وتعديل ونشر الشروط والسياسات ومتابعة الموافقات'
                                      : 'Create, edit & publish legal terms and track acceptances',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openCreateDialog(context),
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: Text(
                            isArabic ? 'إصدار جديد' : 'New Version Draft',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
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
                                : 'Legal Documents Management',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isArabic
                                ? 'إنشاء وتعديل ونشر شروط الاستخدام وسياسة الخصوصية، ومتابعة موافقات المستخدمين'
                                : 'Create, edit, publish terms and privacy policies, and track user acceptances',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openCreateDialog(context),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: Text(
                        isArabic ? 'إصدار جديد' : 'New Version Draft',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Tab Bar
          Container(
            color: theme.colorScheme.surfaceContainerLowest,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: [
                Tab(
                  icon: const Icon(LucideIcons.scrollText, size: 18),
                  text: isArabic ? 'شروط الاستخدام' : 'Terms of Use',
                ),
                Tab(
                  icon: const Icon(LucideIcons.shieldCheck, size: 18),
                  text: isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
                ),
              ],
            ),
          ),

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
    final activeDoc = docs.cast<Map<String, dynamic>?>().firstWhere(
          (d) => d?['isPublished'] == true,
          orElse: () => null,
        );

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.fileQuestion,
                size: 54,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isArabic
                    ? 'لا توجد وثائق مسجلة حالياً'
                    : 'No documents recorded yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isArabic
                    ? 'اضغط على "إصدار جديد" لإنشاء مسودة وتجهيزها للنشر'
                    : 'Click "New Version Draft" to create a document version',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Summary Card of Active Document
        if (activeDoc != null) ...[
          _buildActiveDocumentBanner(context, activeDoc, isArabic),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Section Title: Version History
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
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
                color: theme.colorScheme.surfaceContainerHighest,
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
    final version = doc['version']?.toString() ?? '1.0';
    final title = isArabic
        ? (doc['titleAr']?.toString() ?? doc['title']?.toString() ?? '')
        : (doc['title']?.toString() ?? doc['titleAr']?.toString() ?? '');
    final count = doc['acceptanceCount']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 440;

          final iconWidget = Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              color: Colors.green,
              size: 22,
            ),
          );

          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      isArabic ? 'الإصدار النشط المنشور' : 'Active Published',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'v$version',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );

          final countWidget = Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.users,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isArabic ? 'مستخدم وافقوا' : 'Users Accepted',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconWidget,
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: titleWidget),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                countWidget,
              ],
            );
          }

          return Row(
            children: [
              iconWidget,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: titleWidget),
              const SizedBox(width: AppSpacing.sm),
              countWidget,
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
    final isPublished = doc['isPublished'] == true;
    final version = doc['version']?.toString() ?? '1.0';
    final titleEn = doc['title']?.toString() ?? '';
    final titleAr = doc['titleAr']?.toString() ?? '';
    final count = doc['acceptanceCount']?.toString() ?? '0';
    final id = doc['id']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: isPublished
              ? Colors.green.withValues(alpha: 0.4)
              : theme.dividerColor.withValues(alpha: 0.15),
          width: isPublished ? 1.5 : 1.0,
        ),
      ),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPublished
                            ? LucideIcons.checkCheck
                            : LucideIcons.clock,
                        size: 13,
                        color: isPublished ? Colors.green : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPublished
                            ? (isArabic ? 'منشور ونشط' : 'Published & Active')
                            : (isArabic ? 'مسودة' : 'Draft'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isPublished
                              ? Colors.green
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    'v$version',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  LucideIcons.userCheck,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$count ${isArabic ? 'موافقات' : 'acceptances'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Bilingual titles
            Text(
              isArabic ? titleAr : titleEn,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              isArabic ? titleEn : titleAr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(color: theme.dividerColor.withValues(alpha: 0.1)),
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
                    onPressed: () => _confirmPublish(context, id, version, isArabic),
                    icon: const Icon(LucideIcons.uploadCloud, size: 15),
                    label: Text(isArabic ? 'نشر هذا الإصدار' : 'Publish Version'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ),
                ],

                // Delete
                IconButton(
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: isPublished
                        ? theme.disabledColor
                        : theme.colorScheme.error,
                  ),
                  tooltip: isPublished
                      ? (isArabic
                          ? 'لا يمكن حذف الإصدار المنشور'
                          : 'Cannot delete published version')
                      : (isArabic ? 'حذف' : 'Delete'),
                  onPressed: isPublished
                      ? null
                      : () => _confirmDelete(context, id, version, isArabic),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
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
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return DialogScaffold(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 750),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isArabic ? 'إنشاء مسودة إصدار جديد' : 'New Version Draft',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                              labelText: isArabic ? 'نوع الوثيقة' : 'Document Type',
                              prefixIcon: const Icon(LucideIcons.fileType),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'TERMS_OF_USE',
                                child: Text(
                                  isArabic ? 'شروط الاستخدام (Terms of Use)' : 'Terms of Use',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'PRIVACY_POLICY',
                                child: Text(
                                  isArabic ? 'سياسة الخصوصية (Privacy Policy)' : 'Privacy Policy',
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
                              labelText: isArabic ? 'رقم الإصدار (مثال: 1.1)' : 'Version (e.g. 1.1)',
                              prefixIcon: const Icon(LucideIcons.gitBranch),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? (isArabic ? 'رقم الإصدار مطلوب' : 'Version is required')
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
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Content (English - Markdown supported)',
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
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'المحتوى (باللغة العربية)',
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
    final contentArController = TextEditingController(text: doc['contentAr'] ?? '');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DialogScaffold(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 750),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isArabic ? 'تعديل الوثيقة القانونية' : 'Edit Legal Document',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
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
                            ? (isArabic ? 'رقم الإصدار مطلوب' : 'Version is required')
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
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Content (English)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: contentArController,
                        textDirection: TextDirection.rtl,
                        maxLines: 8,
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
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 750,
                    maxHeight: 700,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(ctx).dividerColor.withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.fileText, color: AppColors.primary),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
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
        return DialogScaffold(
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'إحصائيات موافقات المستخدمين' : 'Acceptance Metrics',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                        Text(
                          isArabic ? 'إجمالي الموافقات المسجلة' : 'Total Acceptances',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    isArabic ? 'التوزيع حسب نوع المستخدم:' : 'Breakdown by Role:',
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
                    role: isArabic ? 'المشرفين والإداريين (Admins)' : 'Staff & Admins',
                    count: (breakdown['ADMIN'] ?? 0) + (breakdown['SUPER_ADMIN'] ?? 0),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              role,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
          title: Text(isArabic ? 'تأكيد نشر الإصدار' : 'Confirm Version Release'),
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
                backgroundColor: Colors.green,
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
              isArabic ? 'تم حذف الإصدار بنجاح' : 'Version deleted successfully',
            ),
          ),
        );
      }
    }
  }
}
