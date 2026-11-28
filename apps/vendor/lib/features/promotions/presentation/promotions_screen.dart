import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api/api.dart';
import 'package:core/core.dart' show ImageUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/features/promotions/presentation/promotion_provider.dart';
import 'package:vendor/features/promotions/presentation/widgets/add_promotion_dialog.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/core/widgets/dashboard_search_bar.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vendor/core/utils/error_utils.dart';
import 'widgets/add_offer_dialog.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  Timer? _refreshTimer;
  String? _userRole;
  String? _vendorId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Refresh every 30 seconds to catch auto-deactivated promotions
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        ref.read(promotionProvider.notifier).fetchPromotions();
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final role = await ref.read(sharedAuthRepositoryProvider).getUserRole();
    final vId = ref.read(activeVendorProvider);
    if (mounted) {
      setState(() {
        _userRole = role;
        _vendorId = vId;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AsyncValue<List<dynamic>>>(promotionProvider, (previous, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, state.error)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: isMobile
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.promotions,
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing:
                            Localizations.localeOf(context).languageCode == 'ar'
                            ? null
                            : -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.manageBannersAndOffers,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMobile) const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddOfferDialog(context),
                    icon: const Icon(LucideIcons.tag, size: 18),
                    label: Text(l10n.addOffer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 14 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPromotionDialog(context),
                    icon: const Icon(LucideIcons.plus, size: 18),
                    label: Text(l10n.addPromotion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 14 : 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DashboardSearchBar(
          controller: _searchController,
          hintText: Localizations.localeOf(context).languageCode == 'ar'
              ? 'بحث في العروض والبانرات...'
              : 'Search promotions and banners...',
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim().toLowerCase();
            });
          },
          onClear: () {
            setState(() {
              _searchQuery = '';
            });
          },
        ),
        const SizedBox(height: 24),

        // List Grid
        Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(promotionProvider);
            var promotions = state.value ?? [];
            if ((_userRole == 'VENDOR_MEMBER' || _userRole == 'VENDOR') &&
                _vendorId != null) {
              promotions = promotions
                  .where((p) => p['vendorId']?.toString() == _vendorId)
                  .toList();
            }

            final totalCount = promotions.length;

            if (_searchQuery.isNotEmpty) {
              promotions = promotions.where((p) {
                final title = (p['title'] ?? '').toString().toLowerCase();
                final titleAr = (p['titleAr'] ?? '').toString().toLowerCase();
                final desc = (p['description'] ?? '').toString().toLowerCase();
                final descAr = (p['descriptionAr'] ?? '').toString().toLowerCase();
                final type = (p['type'] ?? '').toString().toLowerCase();
                final discount = (p['discountValue'] ?? '').toString().toLowerCase();
                final vertical = p['vertical'] as Map?;
                final verticalName = (vertical?['name'] ?? '').toString().toLowerCase();
                final verticalNameAr = (vertical?['nameAr'] ?? '').toString().toLowerCase();
                return title.contains(_searchQuery) ||
                    titleAr.contains(_searchQuery) ||
                    desc.contains(_searchQuery) ||
                    descAr.contains(_searchQuery) ||
                    type.contains(_searchQuery) ||
                    discount.contains(_searchQuery) ||
                    verticalName.contains(_searchQuery) ||
                    verticalNameAr.contains(_searchQuery);
              }).toList();
            }

            if (state.isLoading && totalCount == 0) {
              return const SizedBox(
                height: 400,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (totalCount == 0) {
              return _buildEmptyState(context, l10n);
            }

            if (promotions.isEmpty && totalCount > 0) {
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.searchX,
                          size: 28,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAr
                            ? 'لا توجد عروض أو بانرات تطابق بحثك'
                            : 'No promotions or banners matching your search',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Text(
                          isAr ? 'مسح البحث' : 'Clear search',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final textScale = MediaQuery.textScalerOf(
              context,
            ).scale(1.0).clamp(1.0, 2.0);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: size.width > 1400
                    ? 3
                    : (size.width > 900 ? 2 : 1),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: (size.width > 1400
                        ? 1.5
                        : (size.width > 900 ? 1.45 : 1.4)) /
                    textScale,
              ),
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final promo = promotions[index];
                return _buildPromotionCard(context, promo, l10n);
              },
            );
          },
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.megaphone,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.noPromotionsFound,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.startCreatingBanners,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(
    BuildContext context,
    dynamic promo,
    AppLocalizations l10n,
  ) {
    final bool isOffer = promo['_isOffer'] == true;
    final bool isActive = promo['isActive'] ?? true;
    final String type = isOffer ? 'OFFER' : (promo['type'] ?? 'BANNER');
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final product = promo['product'] as Map?;
    final variant = promo['variant'] as Map?;
    final variantName = isArabic
        ? (variant?['nameAr'] ?? variant?['name'])
        : variant?['name'];
    final productTitle = isOffer
        ? (isArabic ? (product?['nameAr'] ?? '') : (product?['name'] ?? ''))
        : ((isArabic && promo['titleAr'] != null)
              ? promo['titleAr']
              : promo['title']);
    final title = (isOffer && variantName != null && variantName.toString().isNotEmpty)
        ? '$productTitle ($variantName)'
        : productTitle;

    final String? imageUrl = isOffer
        ? (product?['imageUrl'])
        : (promo['imageUrl']);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Banner Image with Ken Burns-like zoom feel
            Positioned.fill(
              child: imageUrl != null && imageUrl.toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _formatImageUrl(imageUrl),
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey.withValues(alpha: 0.05)),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.withValues(alpha: 0.1),
                        child: const Icon(
                          LucideIcons.image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: isOffer
                          ? Colors.orange.withValues(alpha: 0.05)
                          : AppColors.primary.withValues(alpha: 0.05),
                      child: Icon(
                        isOffer ? LucideIcons.tag : LucideIcons.megaphone,
                        color: isOffer ? Colors.orange : AppColors.primary,
                        size: 40,
                      ),
                    ),
            ),

            // Deep Gradient Overlay for better text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.2, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildBadge(
                        isArabic
                            ? (const {
                                  'BANNER': 'إعلان',
                                  'OFFER': 'عرض',
                                  'PRODUCT': 'منتج',
                                  'CUSTOM': 'مخصص',
                                  'CATEGORY': 'فئة',
                                  'VENDOR': 'متجر',
                                }[type.toUpperCase()] ??
                                type.toUpperCase())
                            : type.toUpperCase(),
                        AppColors.primary,
                      ),
                      if (isOffer && variantName != null && variantName.toString().isNotEmpty)
                        _buildBadge(variantName.toString().toUpperCase(), Colors.purple),
                      if (!isOffer) ...[
                        () {
                          final vertical = promo['vertical'] as Map?;
                          final verticalLabel = vertical != null
                              ? (isArabic
                                  ? (vertical['nameAr'] ?? vertical['name'] ?? '')
                                      .toString()
                                  : (vertical['name'] ?? vertical['nameAr'] ?? '')
                                      .toString())
                              : (isArabic ? 'الصفحة الرئيسية' : 'HOME');
                          return _buildBadge(
                            verticalLabel.isNotEmpty
                                ? verticalLabel
                                : (isArabic ? 'الصفحة الرئيسية' : 'HOME'),
                            vertical != null ? Colors.indigo : Colors.teal,
                          );
                        }(),
                      ],
                      _buildBadge(
                        isActive
                            ? (isArabic ? 'نشط' : 'ACTIVE')
                            : (isArabic ? 'غير نشط' : 'INACTIVE'),
                        isActive ? AppColors.success : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title ?? (isArabic ? 'بدون عنوان' : 'Untitled'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                    ),
                  ),
                  if (promo['description'] != null && promo['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        promo['description'].toString(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.3,
                        ),
                        softWrap: true,
                      ),
                    ),
                  if (isOffer ||
                      (type == 'PRODUCT' &&
                          (promo['offerPrice'] != null ||
                              promo['originalPrice'] != null)))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          if (promo['offerPrice'] != null)
                            Text(
                              '${promo['offerPrice']} ${isArabic ? 'ج.م' : 'EGP'}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          if (promo['originalPrice'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${promo['originalPrice']} ${isArabic ? 'ج.م' : 'EGP'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Floating Actions
            PositionedDirectional(
              top: 16,
              end: 16,
              child: Row(
                children: [
                  _buildActionCircle(
                    icon: LucideIcons.edit3,
                    onTap: () => isOffer
                        ? _showAddOfferDialog(context, offer: promo)
                        : _showAddPromotionDialog(context, promotion: promo),
                  ),
                  const SizedBox(width: 10),
                  _buildActionCircle(
                    icon: LucideIcons.trash2,
                    color: AppColors.error,
                    onTap: () => _confirmDelete(context, promo, l10n),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    final foregroundColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black
            : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: Localizations.localeOf(context).languageCode == 'ar' ? null : 0.5,
        ),
      ),
    );
  }

  Widget _buildActionCircle({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _showAddPromotionDialog(
    BuildContext context, {
    dynamic promotion,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddPromotionDialog(promotion: promotion),
    );

    if (result != null && context.mounted) {
      try {
        bool success = false;
        String? id;

        if (promotion != null) {
          final dto = UpdatePromotionDto((b) {
            if (result['title'] != null && result['title'].toString().isNotEmpty) b.title = result['title'];
            if (result['titleAr'] != null && result['titleAr'].toString().isNotEmpty) b.titleAr = result['titleAr'];
            if (result['description'] != null) b.description = result['description'];
            if (result['descriptionAr'] != null) b.descriptionAr = result['descriptionAr'];
            if (result['type'] != null) {
               switch (result['type']) {
                 case 'BANNER': b.type = UpdatePromotionDtoTypeEnum.BANNER; break;
                 case 'VENDOR': b.type = UpdatePromotionDtoTypeEnum.VENDOR; break;
                 case 'PRODUCT': b.type = UpdatePromotionDtoTypeEnum.PRODUCT; break;
                 case 'EXTERNAL_LINK': b.type = UpdatePromotionDtoTypeEnum.EXTERNAL_LINK; break;
               }
            }
            if (result['vendorId'] != null) b.vendorId = result['vendorId'];
            if (result['productId'] != null) b.productId = result['productId'];
            if (result['externalUrl'] != null) b.externalUrl = result['externalUrl'];
            if (result['isActive'] != null) b.isActive = result['isActive'];
            if (result['sortOrder'] != null) b.sortOrder = result['sortOrder'];
            if (result['startDate'] != null) b.startDate = DateTime.parse(result['startDate']);
            if (result['endDate'] != null) b.endDate = DateTime.parse(result['endDate']);
          });
          final responseData = await ref
              .read(adminVendorsRepositoryProvider)
              .updatePromotion(promotion['id'] ?? promotion['_id'], dto);
          final promoId = (promotion['id'] ?? promotion['_id']).toString();
          final previousVerticalId = promotion['verticalId']?.toString();
          final nextVerticalId = result['verticalId']?.toString();
          if (previousVerticalId != nextVerticalId) {
            await ref
                .read(adminVendorsRepositoryProvider)
                .updatePromotionVertical(promoId, nextVerticalId);
          }
          success = responseData != null;
          id = promoId;
        } else {
          final dataToSubmit = Map<String, dynamic>.from(result);
          dataToSubmit.remove('imageFile');
          dataToSubmit.removeWhere((key, value) => value == null || value == '');
          final responseData = await ref.read(adminVendorsRepositoryProvider).createPromotion(dataToSubmit);
          id = responseData is Map ? (responseData['id'] ?? responseData['_id'] ?? responseData['data']?['id'] ?? responseData['data']?['_id'] ?? responseData['promotion']?['id'] ?? responseData['promotion']?['_id'])?.toString() : responseData?.toString();
          if (id == null || id.isEmpty) {
            throw Exception('Banner created but failed to get ID for image upload. (Response: $responseData)');
          }
          success = true;
        }

        if (success && id.isNotEmpty && result['imageFile'] != null) {
          final imageFile = result['imageFile'] as XFile;
          final bytes = await imageFile.readAsBytes();
          final multipartFile = dio.MultipartFile.fromBytes(
            bytes,
            filename: imageFile.name,
          );
          await ref
              .read(adminVendorsRepositoryProvider)
              .uploadPromotionImage(id, multipartFile);
        }

        if (success && context.mounted) {
          final message = promotion != null
              ? ErrorUtils.translate(context, 'common.success.resource_updated')
              : ErrorUtils.translate(
                  context,
                  'common.success.resource_created',
                );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.success,
            ),
          );
          ref.read(promotionProvider.notifier).fetchPromotions();
        }
      } catch (e) {
        if (context.mounted) {
          final errorMessage = ErrorUtils.translate(context, e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  void _showAddOfferDialog(BuildContext context, {dynamic offer}) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddOfferDialog(
        offer: offer,
        userRole: _userRole,
        vendorId: _vendorId,
      ),
    );

    if (result != null && context.mounted) {
      try {
        if (offer != null) {
          await ref
              .read(adminOffersRepositoryProvider)
              .offersUpdate(id: offer['id'] ?? offer['_id'], updateOfferDto: UpdateOfferDto((b) => b
                ..variantId = result['variantId']
                ..originalPrice = result['originalPrice']
                ..offerPrice = result['offerPrice']
                ..sortOrder = result['sortOrder']
                ..isActive = result['isActive']
                ..startDate = result['startDate'] != null ? DateTime.parse(result['startDate']) : null
                ..endDate = result['endDate'] != null ? DateTime.parse(result['endDate']) : null
              ));
        } else {
          await ref.read(adminOffersRepositoryProvider).createOffer(CreateOfferDto((b) => b
            ..productId = result['productId'] ?? ''
            ..variantId = result['variantId']
            ..vendorId = result['vendorId'] ?? ''
            ..originalPrice = result['originalPrice'] ?? 0
            ..offerPrice = result['offerPrice'] ?? 0
            ..sortOrder = result['sortOrder'] ?? 0
            ..startDate = result['startDate'] != null ? DateTime.parse(result['startDate']) : null
            ..endDate = result['endDate'] != null ? DateTime.parse(result['endDate']) : null
          ));
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                offer != null ? l10n.offerUpdated : l10n.offerCreated,
              ),
              backgroundColor: AppColors.success,
            ),
          );
          ref.read(promotionProvider.notifier).fetchPromotions();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
                  ).showSnackBar(SnackBar(content: Text(ErrorUtils.translate(context, e))));
        }
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    dynamic item,
    AppLocalizations l10n,
  ) async {
    final isOffer = item['_isOffer'] == true;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: isOffer ? l10n.deleteOffer : l10n.deletePromotion,
      message: isOffer
          ? l10n.deleteOfferConfirm
          : l10n.deletePromotionConfirm(item['title'] ?? ''),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      icon: LucideIcons.trash2,
      confirmIcon: LucideIcons.trash2,
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;
    try {
      if (isOffer) {
        await ref
            .read(adminOffersRepositoryProvider)
            .offersRemove(id: item['id'] ?? item['_id']);
      } else {
        await ref
            .read(adminVendorsRepositoryProvider)
            .deletePromotion(item['id'] ?? item['_id']);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffer ? l10n.offerDeleted : l10n.deletePromotion,
            ),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(promotionProvider.notifier).fetchPromotions();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatImageUrl(String? url) => ImageUtils.formatImageUrl(url);
}

