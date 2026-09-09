import 'package:flutter/material.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:core/core.dart';

class ErrorUtils {
  /// Translates a backend error/success key to a localized string.
  ///
  /// The backend sends keys like 'auth.error.user_exists'.
  /// Our ARB files have keys like 'auth_error_user_exists'.
  static String translate(BuildContext context, String message) {
    if (message.isEmpty) return message;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return message;

    final lowerMessage = message.trim().toLowerCase();
    if (lowerMessage == 'forbidden resource' ||
        lowerMessage == 'forbidden' ||
        lowerMessage == 'access denied') {
      return l10n.common_error_forbidden;
    }

    // Convert backend key (dot separated) to ARB key (underscore separated)
    // e.g. 'auth.error.user_exists' -> 'auth_error_user_exists'
    final arbKey = message.replaceAll('.', '_').toLowerCase();

    // Mapping of keys to their localized values
    // We use a switch/case approach because the generated AppLocalizations
    // doesn't provide a direct way to access keys by string without reflection.
    switch (arbKey) {
      case 'common_error_validation':
        return l10n.common_error_validation;
      case 'common_error_server_error':
        return l10n.common_error_server_error;
      case 'common_error_unknown':
        return l10n.common_error_unknown;
      case 'common_error_forbidden':
        return l10n.common_error_forbidden;
      case 'common_error_unauthorized':
        return l10n.common_error_unauthorized;
      case 'common_error_too_many_requests':
        return l10n.common_error_too_many_requests;

      case 'common_success_operation':
        return l10n.common_success_operation;
      case 'common_success_resource_created':
        return l10n.common_success_resource_created;
      case 'common_success_resource_updated':
        return l10n.common_success_resource_updated;
      case 'common_success_resource_deleted':
        return l10n.common_success_resource_deleted;

      case 'auth_error_user_exists':
        return l10n.auth_error_user_exists;
      case 'auth_error_invalid_credentials':
        return l10n.auth_error_invalid_credentials;
      case 'auth_error_unverified':
        return l10n.auth_error_unverified;
      case 'auth_error_banned':
        return l10n.auth_error_banned;
      case 'auth_error_user_not_found':
        return l10n.auth_error_user_not_found;
      case 'auth_error_otp_invalid':
        return l10n.auth_error_otp_invalid;
      case 'auth_error_otp_expired':
        return l10n.auth_error_otp_expired;
      case 'auth_error_session_expired':
        return l10n.auth_error_session_expired;

      case 'user_error_user_not_found':
        return l10n.user_error_user_not_found;
      case 'user_error_profile_update_failed':
        return l10n.user_error_profile_update_failed;
      case 'user_error_avatar_upload_failed':
        return l10n.user_error_avatar_upload_failed;
      case 'user_error_invalid_password':
        return l10n.user_error_invalid_password;
      case 'user_error_password_same_as_old':
        return l10n.user_error_password_same_as_old;
      case 'user_error_only_drivers_allowed':
        return l10n.user_error_only_drivers_allowed;
      case 'user_error_only_driver_creation_allowed':
        return l10n.user_error_only_driver_creation_allowed;
      case 'user_error_only_driver_role_allowed':
        return l10n.user_error_only_driver_role_allowed;

      case 'vendor_error_not_found':
        return l10n.vendor_error_not_found;
      case 'vendor_error_slug_taken':
        return l10n.vendor_error_slug_taken;
      case 'vendor_branch_error_not_found':
        return l10n.vendor_branch_error_not_found;
      case 'menu_category_error_not_found':
        return l10n.menu_category_error_not_found;
      case 'product_error_not_found':
        return l10n.product_error_not_found;
      case 'product_error_sku_taken':
        return l10n.product_error_sku_taken;
      case 'vendor_vertical_error_not_found':
        return l10n.vendor_vertical_error_not_found;
      case 'zone_error_not_found':
        return l10n.zone_error_not_found;
      case 'zone_error_invalid_boundary_polygon':
        return l10n.zone_error_invalid_boundary_polygon;
      case 'zone_error_invalid_location_for_zone':
        return l10n.zone_error_invalid_location_for_zone;

      // Add more mappings as needed...

      default:
        final currentLocale = l10n.localeName;
        return ApiErrorMapper.translate(message, locale: currentLocale, context: context);
    }
  }
}

