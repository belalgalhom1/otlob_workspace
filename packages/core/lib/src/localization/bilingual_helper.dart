import 'package:flutter/widgets.dart';

class BilingualHelper {
  /// Returns the Arabic text if the current locale is Arabic and the Arabic text is valid.
  /// Otherwise, returns the English text.
  static String getLocalizedText(BuildContext context, {required String? enText, required String? arText}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    if (isArabic && arText != null && arText.trim().isNotEmpty) {
      return arText;
    }
    
    return enText ?? '';
  }

  /// Same as [getLocalizedText] but does not require a BuildContext.
  /// Used in models or providers where context is not available.
  /// Must explicitly pass whether the current language is Arabic.
  static String getLocalizedTextStatic({required bool isArabic, required String? enText, required String? arText}) {
    if (isArabic && arText != null && arText.trim().isNotEmpty) {
      return arText;
    }
    return enText ?? '';
  }

  // ---------------------------------------------------------------------------
  // Domain-Specific Wrappers (For Prisma Database Entities)
  // ---------------------------------------------------------------------------

  /// Helper specifically for resolving Name fields from database entities.
  static String getName(BuildContext context, {required String? name, required String? nameAr}) {
    return getLocalizedText(context, enText: name, arText: nameAr);
  }

  /// Helper specifically for resolving Title fields from database entities.
  static String getTitle(BuildContext context, {required String? title, required String? titleAr}) {
    return getLocalizedText(context, enText: title, arText: titleAr);
  }

  /// Helper specifically for resolving Description fields from database entities.
  static String getDescription(BuildContext context, {required String? description, required String? descriptionAr}) {
    return getLocalizedText(context, enText: description, arText: descriptionAr);
  }

  /// Helper specifically for resolving Body fields from database entities (e.g. Notifications).
  static String getBody(BuildContext context, {required String? body, required String? bodyAr}) {
    return getLocalizedText(context, enText: body, arText: bodyAr);
  }

  /// Helper specifically for resolving Store Name fields from database entities (e.g. Vendors).
  static String getStoreName(BuildContext context, {required String? storeName, required String? storeNameAr}) {
    return getLocalizedText(context, enText: storeName, arText: storeNameAr);
  }
}
