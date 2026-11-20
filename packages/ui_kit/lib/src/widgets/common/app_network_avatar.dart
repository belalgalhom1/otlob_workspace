import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Presentation-only network avatar with graceful fallback on missing,
/// relative/invalid, or failing image URLs.
///
/// Uses a circular shape when [borderRadius] is `null`, or a rounded
/// rectangle (ideal for store/vendor logos) when [borderRadius] is provided.
class AppNetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double? borderRadius;
  final IconData fallbackIcon;
  final double? fallbackIconSize;
  final String? fallbackText;
  final bool preferInitialFallback;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final BoxFit fit;
  final Map<String, String>? httpHeaders;

  const AppNetworkAvatar({
    super.key,
    this.imageUrl,
    this.size = 40,
    this.borderRadius,
    this.fallbackIcon = Icons.person_rounded,
    this.fallbackIconSize,
    this.fallbackText,
    this.preferInitialFallback = false,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.border,
    this.fit = BoxFit.cover,
    this.httpHeaders,
  });

  /// Returns [rawUrl] trimmed when it is a valid `http` / `https` URI,
  /// otherwise `null`.
  static String? normalizeHttpUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedBg = backgroundColor ??
        colorScheme.primary.withValues(alpha: 0.12);
    final resolvedFg = foregroundColor ?? colorScheme.primary;
    final resolvedUrl = normalizeHttpUrl(imageUrl);
    final isCircle = borderRadius == null;
    final effectiveRadius = borderRadius != null
        ? BorderRadius.circular(borderRadius!)
        : null;

    final fallback = _buildFallback(resolvedBg, resolvedFg, isCircle, effectiveRadius);

    Widget content;
    if (resolvedUrl == null) {
      content = fallback;
    } else {
      final cacheDim = (size * 3).round().clamp(48, 512);
      final image = CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: size,
        height: size,
        fit: fit,
        httpHeaders: httpHeaders,
        memCacheWidth: cacheDim,
        memCacheHeight: cacheDim,
        fadeInDuration: const Duration(milliseconds: 160),
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );

      content = isCircle
          ? ClipOval(child: image)
          : ClipRRect(borderRadius: effectiveRadius!, child: image);
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: effectiveRadius,
          border: border,
        ),
        child: content,
      ),
    );
  }

  Widget _buildFallback(
    Color bg,
    Color fg,
    bool isCircle,
    BorderRadius? effectiveRadius,
  ) {
    final initial = _extractInitial(fallbackText);
    final useInitial = preferInitialFallback && initial != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: effectiveRadius,
      ),
      child: Center(
        child: useInitial
            ? Text(
                initial,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: fg,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              )
            : Icon(
                fallbackIcon,
                color: fg,
                size: fallbackIconSize ?? (size * 0.5),
              ),
      ),
    );
  }

  static String? _extractInitial(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final firstRune = trimmed.runes.firstOrNull;
    if (firstRune == null) return null;
    return String.fromCharCode(firstRune).toUpperCase();
  }
}
