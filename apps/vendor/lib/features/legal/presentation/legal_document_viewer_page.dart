import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/data.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LegalDocumentViewerPage extends ConsumerStatefulWidget {
  final String type; // 'TERMS_OF_USE' or 'PRIVACY_POLICY'
  final String? title;

  const LegalDocumentViewerPage({
    super.key,
    required this.type,
    this.title,
  });

  @override
  ConsumerState<LegalDocumentViewerPage> createState() =>
      _LegalDocumentViewerPageState();
}

class _LegalDocumentViewerPageState
    extends ConsumerState<LegalDocumentViewerPage> {
  Map<String, dynamic>? _document;
  bool _isLoading = true;
  String? _error;
  bool _showArabic = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      setState(() => _showArabic = isAr);
      _fetchDocument();
    });
  }

  Future<void> _fetchDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(sharedLegalDocumentsRepositoryProvider);
      final doc = await repo.getActiveDocument(widget.type);
      if (mounted) {
        setState(() {
          _document = doc;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArLocale = Localizations.localeOf(context).languageCode == 'ar';

    final title = _showArabic
        ? (_document?['titleAr'] ?? _document?['title'] ?? widget.title ?? '')
        : (_document?['title'] ?? _document?['titleAr'] ?? widget.title ?? '');

    final content = _showArabic
        ? (_document?['contentAr'] ?? _document?['content'] ?? '')
        : (_document?['content'] ?? _document?['contentAr'] ?? '');

    final version = _document?['version']?.toString() ?? '1.0';
    final publishedAt = _document?['publishedAt']?.toString();

    String formattedDate = '';
    if (publishedAt != null && publishedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(publishedAt);
        formattedDate = isArLocale
            ? 'آخر تحديث: ${dt.year}/${dt.month}/${dt.day}'
            : 'Last updated: ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = publishedAt;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).colorScheme.surface
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.title ??
              (widget.type == 'TERMS_OF_USE'
                  ? (isArLocale ? 'شروط الاستخدام' : 'Terms of Use')
                  : (isArLocale ? 'سياسة الخصوصية' : 'Privacy Policy')),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.languages, size: 20),
            tooltip: _showArabic ? 'English' : 'عربي',
            onPressed: () {
              setState(() => _showArabic = !_showArabic);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context).colorScheme.surface
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LegalDocumentView(
                  title: title.toString(),
                  version: version,
                  lastUpdated: formattedDate,
                  content: content.toString(),
                  isArabic: _showArabic,
                  isLoading: _isLoading,
                  error: _error,
                  onRetry: _fetchDocument,
                  onLanguageToggle: () {
                    setState(() => _showArabic = !_showArabic);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
