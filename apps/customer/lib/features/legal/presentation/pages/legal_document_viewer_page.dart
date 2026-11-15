import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/data.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LegalDocumentViewerPage extends ConsumerStatefulWidget {
  final String type; // 'TERMS_OF_USE' or 'PRIVACY_POLICY'
  final String? initialTitle;

  const LegalDocumentViewerPage({
    super.key,
    required this.type,
    this.initialTitle,
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
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        setState(() {
          _error = isAr
              ? 'تعذر تحميل الوثيقة، يرجى التحقق من الاتصال بالإنترنت والمحاولة مجدداً.'
              : 'Failed to load document. Please check your internet connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _showArabic
        ? (_document?['titleAr'] ?? _document?['title'] ?? widget.initialTitle ?? '')
        : (_document?['title'] ?? _document?['titleAr'] ?? widget.initialTitle ?? '');

    final content = _showArabic
        ? (_document?['contentAr'] ?? _document?['content'] ?? '')
        : (_document?['content'] ?? _document?['contentAr'] ?? '');

    final version = _document?['version']?.toString() ?? '1.0';
    final publishedAt = _document?['publishedAt']?.toString();

    String formattedDate = '';
    if (publishedAt != null && publishedAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(publishedAt);
        formattedDate = _showArabic
            ? 'آخر تحديث: ${dt.year}/${dt.month}/${dt.day}'
            : 'Last updated: ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDate = publishedAt;
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentText =
        isDark ? const Color(0xFFFBBB2B) : const Color(0xFFB45309);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.type == 'TERMS_OF_USE'
              ? (_showArabic ? 'شروط الاستخدام' : 'Terms of Use')
              : (_showArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Tooltip(
              message: _showArabic ? 'English' : 'عربي',
              child: InkWell(
                onTap: () => setState(() => _showArabic = !_showArabic),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 34, minWidth: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFEEEEEE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.languages, size: 15, color: accentText),
                      const SizedBox(width: 5),
                      Text(
                        _showArabic ? 'EN' : 'عربي',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LegalDocumentView(
          title: title,
          version: version,
          lastUpdated: formattedDate,
          content: content,
          isArabic: _showArabic,
          isLoading: _isLoading,
          error: _error,
          onRetry: _fetchDocument,
          onLanguageToggle: () {
            setState(() => _showArabic = !_showArabic);
          },
        ),
      ),
    );
  }
}
