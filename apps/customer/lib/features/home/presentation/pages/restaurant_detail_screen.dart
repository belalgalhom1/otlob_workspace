import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:otlob_customer/core/utils/error_utils.dart';
import 'package:ui_kit/ui_kit.dart' show AppExpandableText;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/widgets/auth_prompt_dialog.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../providers/favorites_provider.dart';
import '../providers/vendor_detail_controller.dart';
import '../widgets/fly_to_cart_overlay.dart';
import '../widgets/product_bottom_sheet.dart';
import '../widgets/store_details_tokens.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;
  const VendorDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _initialProductShown = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _catScrollController = ScrollController();
  final ScrollController _menuScrollController = ScrollController();

  final Map<String, GlobalKey> _categoryPillKeys = {};
  final Map<String, GlobalKey> _productThumbKeys = {};
  final GlobalKey _cartBarKey = GlobalKey();
  final GlobalKey _mainContentKey = GlobalKey();

  bool _showCatStartFade = false;
  bool _showCatEndFade = false;

  // 320ms Cart Pop animation (1.0 -> 1.04 translateY -2px -> 1.0)
  late final AnimationController _cartPopController;
  late final Animation<double> _cartPopScale;
  late final Animation<double> _cartPopTranslateY;

  // Floating Top Toast
  String? _toastMessage;
  bool _toastVisible = false;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();

    _cartPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _cartPopScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.04)
            .chain(CurveTween(curve: const Cubic(0.34, 1.56, 0.64, 1.0))),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
    ]).animate(_cartPopController);
    _cartPopTranslateY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -2.0)
            .chain(CurveTween(curve: const Cubic(0.34, 1.56, 0.64, 1.0))),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -2.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
    ]).animate(_cartPopController);

    _catScrollController.addListener(_updateCategoryFades);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final closestBranch = widget.restaurant['_proximity']?['closestBranch'];
      final closestBranchId = closestBranch?['id']?.toString() ??
          widget.restaurant['branchId']?.toString();
      final vendorId = widget.restaurant['id']?.toString() ?? '';
      if (closestBranchId != null && vendorId.isNotEmpty) {
        ref.read(selectedBranchProvider.notifier).selectBranchById(
              vendorId,
              closestBranchId,
              name: closestBranch?['name']?.toString(),
              nameAr: closestBranch?['nameAr']?.toString(),
              address: closestBranch?['address']?.toString(),
            );
      }
      _updateCategoryFades();
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _cartPopController.dispose();
    _searchController.dispose();
    _catScrollController.removeListener(_updateCategoryFades);
    _catScrollController.dispose();
    _menuScrollController.dispose();
    super.dispose();
  }

  void _updateCategoryFades() {
    if (!mounted || !_catScrollController.hasClients) return;
    final pos = _catScrollController.position;
    final maxScroll = pos.maxScrollExtent;
    final bool startFade;
    final bool endFade;
    if (maxScroll <= 4) {
      startFade = false;
      endFade = false;
    } else {
      startFade = pos.pixels > 8;
      endFade = pos.pixels < maxScroll - 8;
    }
    if (startFade != _showCatStartFade || endFade != _showCatEndFade) {
      setState(() {
        _showCatStartFade = startFade;
        _showCatEndFade = endFade;
      });
    }
  }

  void _showTopToast(String message) {
    _toastTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _toastMessage = message;
      _toastVisible = true;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2100), () {
      if (!mounted) return;
      setState(() => _toastVisible = false);
    });
  }

  void _triggerCartPop() {
    if (!mounted) return;
    _cartPopController.forward(from: 0);
  }

  Rect? _rectFromKey(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    return topLeft & renderBox.size;
  }

  Rect? _resolveCartTargetRect() {
    final existing = _rectFromKey(_cartBarKey);
    if (existing != null && !existing.isEmpty) return existing;

    final contentRect = _rectFromKey(_mainContentKey);
    if (contentRect != null && !contentRect.isEmpty) {
      return Rect.fromLTWH(
        contentRect.left + 14,
        contentRect.bottom - 52,
        (contentRect.width - 28).clamp(120, double.infinity),
        42,
      );
    }
    return null;
  }

  void _selectCategory(String catId) {
    setState(() => _selectedCategory = catId);

    // Auto-center tapped category pill horizontally so upcoming categories slide into view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pillCtx = _categoryPillKeys[catId]?.currentContext;
      if (pillCtx != null) {
        Scrollable.ensureVisible(
          pillCtx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      _updateCategoryFades();
    });

    // Smoothly reset product list to top (no scroll-spy switching)
    if (_menuScrollController.hasClients) {
      _menuScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _handleFavoriteToggle(
    BuildContext context,
    String vendorId,
    String storeName,
    bool isAr,
  ) async {
    final authStatus = ref.read(authControllerProvider);
    if (authStatus == AuthStatus.unauthenticated) {
      AuthPromptDialog.show(context);
      return;
    }
    final wasFav = ref.read(favoritesProvider).contains(vendorId);
    await ref.read(favoritesProvider.notifier).toggleFavorite(vendorId);
    if (!mounted) return;
    final nowFav = ref.read(favoritesProvider).contains(vendorId);
    if (nowFav != wasFav) {
      _showTopToast(
        nowFav
            ? (isAr
                ? 'تمت إضافة $storeName إلى المفضلة'
                : 'Added $storeName to favorites')
            : (isAr ? 'تمت الإزالة من المفضلة' : 'Removed from favorites'),
      );
    }
  }

  void _handleThemeToggle(bool currentlyDark) {
    try {
      ref.read(appSettingsProvider.notifier).changeTheme(
            currentlyDark ? ThemeMode.light : ThemeMode.dark,
          );
    } catch (_) {
      // Safe no-op in isolated test scopes without SharedPreferences override.
    }
  }

  void _runFlyAndCommit({
    required BuildContext context,
    required Rect? sourceRect,
    required String? imageUrl,
    required Future<void> Function() commitAdd,
    required String displayName,
    required bool isAr,
  }) {
    final targetRect = _resolveCartTargetRect();
    FlyToCartOverlay.launch(
      context: context,
      sourceRect: sourceRect,
      targetRect: targetRect,
      imageUrl: imageUrl,
      onLanded: () async {
        try {
          await commitAdd();
          if (!mounted) return;
          _triggerCartPop();
          _showTopToast(
            isAr
                ? 'تمت إضافة "$displayName" للسلة'
                : 'Added "$displayName" to cart',
          );
        } catch (e) {
          if (!mounted) return;
          _showTopToast(ErrorUtils.translate(this.context, e));
        }
      },
    );
  }

  void _openProductBottomSheet({
    required BuildContext context,
    required Map<String, dynamic> item,
    required Map<String, dynamic> fullVendor,
    required AppStrings s,
    required bool isDark,
    required bool isPharmacy,
    required bool isAr,
    String? initialVariantId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (sheetCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: ProductBottomSheet(
          item: item,
          restaurant: fullVendor,
          initialUnit: 'package',
          initialVariantId: initialVariantId,
          s: s,
          isDark: isDark,
          isPharmacy: isPharmacy,
          onRequestFlyAdd: (previewRect, flyImageUrl, commitAdd, displayName) {
            if (!mounted) return;
            _runFlyAndCommit(
              context: context,
              sourceRect: previewRect,
              imageUrl: flyImageUrl,
              commitAdd: commitAdd,
              displayName: displayName,
              isAr: isAr,
            );
          },
        ),
      ),
    );
  }

  void _openBranchModal({
    required BuildContext context,
    required List<dynamic> branches,
    required String vendorId,
    required String? activeBranchId,
    required StoreDetailsPalette palette,
    required bool isAr,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (dialogCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.borderGold, width: 1),
                boxShadow: [palette.cardShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: StoreDetailsTokens.gold,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isAr ? 'اختر الفرع' : 'Select Branch',
                          style: StoreDetailsTokens.text(
                            size: 15,
                            weight: FontWeight.w900,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      _buildModalCloseBtn(
                        palette: palette,
                        onTap: () => Navigator.of(dialogCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: branches.whereType<Map>().map((raw) {
                          final b = Map<String, dynamic>.from(raw);
                          final bId = b['id']?.toString() ?? '';
                          final bName = ((isAr
                                      ? (b['nameAr'] ?? b['name'])
                                      : (b['name'] ?? b['nameAr']))
                                  ?.toString()
                                  .trim() ??
                              '');
                          final bAddress = b['address']?.toString().trim() ?? '';
                          final isSelected = bId == activeBranchId;
                          final isBranchOpen = b['isOpen'] != false;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ref
                                      .read(selectedBranchProvider.notifier)
                                      .selectBranchById(
                                        vendorId,
                                        bId,
                                        name: b['name']?.toString(),
                                        nameAr: b['nameAr']?.toString(),
                                        address: b['address']?.toString(),
                                      );
                                  Navigator.of(dialogCtx).pop();
                                  _showTopToast(
                                    isAr
                                        ? 'تم اختيار فرع $bName'
                                        : 'Selected branch $bName',
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? StoreDetailsTokens.gold
                                            .withValues(alpha: 0.15)
                                        : palette.bgCard2,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? StoreDetailsTokens.gold
                                          : palette.borderGold,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.mapPin,
                                        size: 14,
                                        color: isSelected
                                            ? StoreDetailsTokens.gold
                                            : palette.textMuted,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isAr
                                                  ? 'الفرع: $bName'
                                                  : 'Branch: $bName',
                                              style: StoreDetailsTokens.text(
                                                size: 12,
                                                weight: FontWeight.w800,
                                                color: isSelected
                                                    ? palette.goldText
                                                    : palette.textPrimary,
                                              ),
                                            ),
                                            if (bAddress.isNotEmpty)
                                              Text(
                                                bAddress,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: StoreDetailsTokens.text(
                                                  size: 10.5,
                                                  weight: FontWeight.w500,
                                                  color: palette.textMuted,
                                                ),
                                              ),
                                            if (!isBranchOpen)
                                              Text(
                                                isAr ? 'مغلق الآن' : 'Closed',
                                                style: StoreDetailsTokens.text(
                                                  size: 10,
                                                  weight: FontWeight.w700,
                                                  color: StoreDetailsTokens
                                                      .errorRed,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: StoreDetailsTokens.gold,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCartModal({
    required BuildContext context,
    required String vendorId,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isAr,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (dialogCtx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Consumer(
            builder: (ctx, modalRef, _) {
              final cartState = modalRef.watch(cartProvider);
              final basket = cartState.vendorBaskets[vendorId] ?? const [];
              final total = cartState.getVendorSubtotal(vendorId);
              final maxH = MediaQuery.sizeOf(ctx).height * 0.82;

              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 410, maxHeight: maxH),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.bgCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.borderGold, width: 1),
                    boxShadow: [palette.cardShadow],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Modal Header
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.shoppingBag,
                            size: 16,
                            color: StoreDetailsTokens.gold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr ? 'سلة الطلبات' : 'Order Cart',
                              style: StoreDetailsTokens.text(
                                size: 15,
                                weight: FontWeight.w900,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          _buildModalCloseBtn(
                            palette: palette,
                            onTap: () => Navigator.of(dialogCtx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Cart Items List
                      if (basket.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            isAr ? 'السلة فارغة حالياً' : 'Your cart is empty',
                            style: StoreDetailsTokens.text(
                              size: 12,
                              weight: FontWeight.w700,
                              color: palette.textMuted,
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: basket.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, idx) {
                              final ci = basket[idx];
                              final itemTitle = _cartItemDisplayTitle(ci, isAr);
                              final thumbUrl = ci.displayImageUrl?.trim() ?? '';

                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: palette.bgCard2,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: palette.borderGold,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // 40x40 Thumbnail
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: palette.bgCard,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: palette.borderGold,
                                          width: 0.8,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: thumbUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: ImageUtils.thumbnailUrl(
                                                thumbUrl,
                                              ),
                                              fit: BoxFit.cover,
                                              errorWidget: (_, _, _) => Icon(
                                                Icons.fastfood_rounded,
                                                size: 16,
                                                color: palette.textMuted,
                                              ),
                                            )
                                          : Icon(
                                              Icons.fastfood_rounded,
                                              size: 16,
                                              color: palette.textMuted,
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            itemTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: StoreDetailsTokens.text(
                                              size: 12,
                                              weight: FontWeight.w800,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${StoreDetailsTokens.formatPrice(ci.totalPrice)} ${s.egp}',
                                            style: StoreDetailsTokens.numeric(
                                              size: 11,
                                              weight: FontWeight.w800,
                                              color: palette.goldText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    // 24x24 Stepper Controls (- qty +)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildStepperBtn(
                                          label: '-',
                                          background: palette.bgCard,
                                          borderColor: palette.borderGold,
                                          textColor: palette.textPrimary,
                                          onTap: () async {
                                            try {
                                              await modalRef
                                                  .read(cartProvider.notifier)
                                                  .updateQuantity(
                                                    ci,
                                                    ci.quantity - 1,
                                                  );
                                            } catch (e) {
                                              if (mounted) {
                                                _showTopToast(
                                                  ErrorUtils.translate(
                                                    this.context,
                                                    e,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        SizedBox(
                                          width: 22,
                                          child: Text(
                                            '${ci.quantity}',
                                            textAlign: TextAlign.center,
                                            style: StoreDetailsTokens.numeric(
                                              size: 12,
                                              weight: FontWeight.w900,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                        ),
                                        _buildStepperBtn(
                                          label: '+',
                                          background: StoreDetailsTokens.gold,
                                          borderColor: StoreDetailsTokens.gold,
                                          textColor:
                                              StoreDetailsTokens.darkOnGold,
                                          onTap: () async {
                                            try {
                                              await modalRef
                                                  .read(cartProvider.notifier)
                                                  .updateQuantity(
                                                    ci,
                                                    ci.quantity + 1,
                                                  );
                                            } catch (e) {
                                              if (mounted) {
                                                _showTopToast(
                                                  ErrorUtils.translate(
                                                    this.context,
                                                    e,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 12),
                      Divider(height: 1, color: palette.borderGold),
                      const SizedBox(height: 12),

                      // Total Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'الإجمالي' : 'Total',
                            style: StoreDetailsTokens.text(
                              size: 13,
                              weight: FontWeight.w800,
                              color: palette.textMuted,
                            ),
                          ),
                          Text(
                            '${StoreDetailsTokens.formatPrice(total)} ${s.egp}',
                            style: StoreDetailsTokens.numeric(
                              size: 15,
                              weight: FontWeight.w900,
                              color: palette.goldText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Checkout CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: basket.isEmpty
                              ? null
                              : () {
                                  Navigator.of(dialogCtx).pop();
                                  context.push('/checkout', extra: vendorId);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StoreDetailsTokens.gold,
                            foregroundColor: StoreDetailsTokens.darkOnGold,
                            disabledBackgroundColor: palette.bgCard2,
                            disabledForegroundColor: palette.textMuted,
                            minimumSize: const Size(double.infinity, 44),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isAr ? 'تأكيد الطلب' : 'Proceed to Checkout',
                            style: StoreDetailsTokens.text(
                              size: 13.5,
                              weight: FontWeight.w900,
                              color: basket.isEmpty
                                  ? palette.textMuted
                                  : StoreDetailsTokens.darkOnGold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _cartItemDisplayTitle(CartItem ci, bool isAr) {
    final base = ci.product.localizedName(isAr);
    final parts = <String>[];
    if (ci.selectedVariant != null) {
      final vName = ci.selectedVariant!.localizedName(isAr);
      if (vName.isNotEmpty) parts.add(vName);
    }
    if (ci.selectedOptions.isNotEmpty) {
      parts.add(
        ci.selectedOptions.map((o) => o.localizedName(isAr)).join('، '),
      );
    }
    if (parts.isEmpty) return base;
    return '$base (${parts.join(' • ')})';
  }

  Widget _buildStepperBtn({
    required String label,
    required Color background,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: StoreDetailsTokens.numeric(
              size: 13,
              weight: FontWeight.w900,
              color: textColor,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalCloseBtn({
    required StoreDetailsPalette palette,
    required VoidCallback onTap,
  }) {
    return Material(
      color: palette.bgCard2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: palette.borderGold, width: 0.8),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.close_rounded,
            size: 15,
            color: palette.textMuted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = StoreDetailsPalette.fromBrightness(isDark);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    final vendorId = widget.restaurant['id']?.toString() ?? '';
    final detailAsync = ref.watch(vendorDetailControllerProvider(vendorId));
    final cartState = ref.watch(cartProvider);
    final isFavorite = ref.watch(
      favoritesProvider.select((favs) => favs.contains(vendorId)),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: palette.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: palette.bgMain,
        body: Stack(
          children: [
            detailAsync.when(
              loading: () => _buildLoadingSkeleton(
                context: context,
                palette: palette,
                isRtl: isRtl,
              ),
              error: (err, _) => _buildErrorState(
                context: context,
                palette: palette,
                error: err,
                vendorId: vendorId,
                isAr: isAr,
                isRtl: isRtl,
              ),
              data: (fullVendor) => _buildLoadedViewport(
                context: context,
                fullVendor: fullVendor,
                vendorId: vendorId,
                cartState: cartState,
                isFavorite: isFavorite,
                palette: palette,
                s: s,
                isDark: isDark,
                isAr: isAr,
                isRtl: isRtl,
              ),
            ),

            // Floating Top Toast (top: 56px, pill #E5A93C, #14120E, 11px w800)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 56,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _toastVisible && _toastMessage != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: StoreDetailsTokens.gold,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.35),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        _toastMessage ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: StoreDetailsTokens.text(
                          size: 11,
                          weight: FontWeight.w800,
                          color: StoreDetailsTokens.darkOnGold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedViewport({
    required BuildContext context,
    required Map<String, dynamic> fullVendor,
    required String vendorId,
    required CartState cartState,
    required bool isFavorite,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isDark,
    required bool isAr,
    required bool isRtl,
  }) {
    final resolvedVendorId = fullVendor['id']?.toString() ?? vendorId;
    final typeStr = fullVendor['type']?.toString().toLowerCase() ?? '';
    final vendorSlug = fullVendor['slug']?.toString().toLowerCase() ?? '';
    final vendorNameLower = fullVendor['name']?.toString().toLowerCase() ?? '';
    final isPharmacy = typeStr.contains('pharmacy') ||
        typeStr.contains('pharmacies-') ||
        typeStr.contains('صيدلي') ||
        typeStr.contains('صيدليات') ||
        typeStr.contains('medical') ||
        typeStr.contains('medicine') ||
        typeStr.contains('pharma') ||
        vendorSlug.contains('pharmacy') ||
        vendorSlug.contains('صيدلي') ||
        vendorSlug.contains('صيدليات') ||
        vendorNameLower.contains('pharmacy') ||
        vendorNameLower.contains('صيدلي') ||
        vendorNameLower.contains('صيدليات');

    final allMenu = (fullVendor['menu'] as List<dynamic>?) ?? const [];
    final rawCategories =
        (fullVendor['categories'] as List<dynamic>?) ?? const [];
    final branches = (fullVendor['branches'] as List<dynamic>?) ?? const [];

    final activeBranchId = ref.watch(selectedBranchProvider)[resolvedVendorId]?.id;
    final currentBranch = branches
            .whereType<Map>()
            .where((b) => b['id']?.toString() == activeBranchId)
            .firstOrNull ??
        (fullVendor['closestBranch'] is Map
            ? fullVendor['closestBranch'] as Map
            : null) ??
        (branches.isNotEmpty && branches.first is Map
            ? branches.first as Map
            : null);

    final vendorStatusOpen = fullVendor['status'] == null ||
        fullVendor['status'].toString().toUpperCase() == 'OPEN';
    final branchOpen = currentBranch == null || currentBranch['isOpen'] != false;
    final isOpen = vendorStatusOpen && branchOpen;

    // Handle deep-linked initialProductId / initialVariantId
    final initialProductId = widget.restaurant['productId'];
    final initialVariantId = widget.restaurant['variantId']?.toString();
    if (!_initialProductShown &&
        initialProductId != null &&
        allMenu.isNotEmpty) {
      final item = allMenu
          .whereType<Map>()
          .where((i) => i['id']?.toString() == initialProductId.toString())
          .firstOrNull;
      if (item != null) {
        _initialProductShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !isOpen) return;
          _openProductBottomSheet(
            context: context,
            item: Map<String, dynamic>.from(item),
            fullVendor: fullVendor,
            s: s,
            isDark: isDark,
            isPharmacy: isPharmacy,
            isAr: isAr,
            initialVariantId: initialVariantId,
          );
        });
      }
    }

    final storeName = _localizedStoreName(fullVendor, isAr);
    final storeDescription = _localizedStoreDescription(fullVendor, isAr);
    final storeSubtitle = _buildStoreSubtitle(fullVendor, isOpen, isAr, s);
    final rating = (fullVendor['rating'] as num?)?.toDouble() ??
        double.tryParse(fullVendor['rating']?.toString() ?? '') ??
        0.0;
    final ratingCount = (fullVendor['ratingCount'] as num?)?.toInt() ??
        int.tryParse(fullVendor['ratingCount']?.toString() ?? '') ??
        0;

    final coverImageRaw = (fullVendor['coverImage'] ??
            fullVendor['image'] ??
            fullVendor['logo'])
        ?.toString()
        .trim();

    final branchName = currentBranch != null
        ? ((isAr
                    ? (currentBranch['nameAr'] ?? currentBranch['name'])
                    : (currentBranch['name'] ?? currentBranch['nameAr']))
                ?.toString()
                .trim() ??
            '')
        : '';

    // Build real category pills: 'all' + backend categories
    final categoryPills = <_CategoryPillData>[
      _CategoryPillData(
        id: 'all',
        label: isAr ? 'الكل' : 'All',
        count: allMenu.length,
      ),
      ...rawCategories.whereType<Map>().map((cat) {
        final catId = cat['id']?.toString() ?? '';
        final catLabel = (isAr &&
                cat['nameAr'] != null &&
                cat['nameAr'].toString().trim().isNotEmpty)
            ? cat['nameAr'].toString().trim()
            : (cat['name']?.toString().trim() ?? '');
        final count = allMenu
            .whereType<Map>()
            .where((m) =>
                (m['category'] ?? m['categoryId'])?.toString() == catId)
            .length;
        return _CategoryPillData(id: catId, label: catLabel, count: count);
      }).where((c) => c.id.isNotEmpty && c.label.isNotEmpty),
    ];

    // Ensure selected category stays valid after branch switch
    final effectiveCategory =
        categoryPills.any((c) => c.id == _selectedCategory)
            ? _selectedCategory
            : 'all';

    // Strict name-only filtered menu items
    final filteredMenu = StoreDetailsTokens.filterMenuProducts(
      allMenu: allMenu,
      activeCategoryId: effectiveCategory,
      rawQuery: _searchQuery,
    );

    // Real vendor cart state
    final vendorBasket = cartState.vendorBaskets[resolvedVendorId] ?? const [];
    final vendorCartQty =
        vendorBasket.fold<int>(0, (sum, item) => sum + item.quantity);
    final vendorCartTotal = cartState.getVendorSubtotal(resolvedVendorId);

    // Schedule category fade check after frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCategoryFades());

    // Viewport-locked outer Column: ZERO outer scroll. Only the vertical
    // product list inside Expanded scrolls.
    return SafeArea(
      child: Column(
        children: [
          // B. Top Store Banner (112px fixed)
          _buildTopBanner(
            context: context,
            coverImageUrl: coverImageRaw,
            isFavorite: isFavorite,
            isDark: isDark,
            isRtl: isRtl,
            onBack: () => _handleBack(context),
            onToggleFavorite: () => _handleFavoriteToggle(
              context,
              resolvedVendorId,
              storeName,
              isAr,
            ),
            onToggleTheme: () => _handleThemeToggle(isDark),
          ),

          // C. Main Content Wrapper (flex: 1, padding: 8px 14px 10px 14px, 8px vertical gaps)
          Expanded(
            key: _mainContentKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // D. Store Header, Expandable Description & Branch Row
                  _buildStoreHeaderSection(
                    context: context,
                    palette: palette,
                    s: s,
                    isAr: isAr,
                    storeName: storeName,
                    subtitle: storeSubtitle,
                    isOpen: isOpen,
                    rating: rating,
                    ratingCount: ratingCount,
                    description: storeDescription,
                    branchName: branchName,
                    branches: branches,
                    vendorId: resolvedVendorId,
                    activeBranchId:
                        activeBranchId ?? currentBranch?['id']?.toString(),
                  ),

                  const SizedBox(height: 8),

                  // E. Direct Order CTA Section
                  _buildDirectOrderSection(
                    context: context,
                    palette: palette,
                    isAr: isAr,
                    vendorId: resolvedVendorId,
                    storeName: storeName,
                  ),

                  // F. Horizontal Category Bar (Tap-Only Filtering + Auto-Centering)
                  if (categoryPills.length > 1 || allMenu.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCategoryBar(
                      pills: categoryPills,
                      activeCategoryId: effectiveCategory,
                      palette: palette,
                      isRtl: isRtl,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // G1. Menu Header & Strict Name-Only Search Bar
                  _buildMenuHeaderAndSearch(
                    palette: palette,
                    isAr: isAr,
                  ),

                  const SizedBox(height: 8),

                  // G2. Vertically Scrolling Product Cards (ONLY scrolling area)
                  Expanded(
                    child: _buildScrollableMenuList(
                      context: context,
                      items: filteredMenu,
                      fullVendor: fullVendor,
                      cartState: cartState,
                      palette: palette,
                      s: s,
                      isDark: isDark,
                      isAr: isAr,
                      isOpen: isOpen,
                      isPharmacy: isPharmacy,
                    ),
                  ),

                  // H. Sticky Cart Bar (visible when vendorCartQty > 0)
                  if (vendorCartQty > 0) ...[
                    const SizedBox(height: 8),
                    _buildStickyCartBar(
                      context: context,
                      vendorId: resolvedVendorId,
                      totalQty: vendorCartQty,
                      totalPrice: vendorCartTotal,
                      palette: palette,
                      s: s,
                      isAr: isAr,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner({
    required BuildContext context,
    required String? coverImageUrl,
    required bool isFavorite,
    required bool isDark,
    required bool isRtl,
    required VoidCallback onBack,
    required VoidCallback onToggleFavorite,
    required VoidCallback onToggleTheme,
  }) {
    final hasImage = coverImageUrl != null && coverImageUrl.isNotEmpty;
    return SizedBox(
      height: 112,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: ImageUtils.formatImageUrl(coverImageUrl),
              fit: BoxFit.cover,
              placeholder: (_, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: StoreDetailsTokens.bannerFallbackGradient,
                ),
              ),
              errorWidget: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: StoreDetailsTokens.bannerFallbackGradient,
                ),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: StoreDetailsTokens.bannerFallbackGradient,
              ),
            ),

          // Subtle top scrim for icon legibility
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.25),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),

          // Top-Start Back Button (top-right in RTL, top-left in LTR): 36x36 white circle
          PositionedDirectional(
            top: 12,
            start: 12,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.35),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onBack,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(
                    isRtl
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: const Color(0xFF181613),
                  ),
                ),
              ),
            ),
          ),

          // Top-End Action Buttons (Favorite + Theme toggle): 36x36 frosted dark circles, gap 6px
          PositionedDirectional(
            top: 12,
            end: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBannerGlassButton(
                  key: const Key('store_favorite_button'),
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                  onTap: onToggleFavorite,
                ),
                const SizedBox(width: 6),
                _buildBannerGlassButton(
                  key: const Key('store_theme_toggle_button'),
                  icon: isDark ? LucideIcons.sun : LucideIcons.moon,
                  iconColor: isDark ? StoreDetailsTokens.gold : Colors.white,
                  onTap: onToggleTheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerGlassButton({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ClipOval(
      key: key,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: const Color.fromRGBO(0, 0, 0, 0.55),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.25),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreHeaderSection({
    required BuildContext context,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isAr,
    required String storeName,
    required String subtitle,
    required bool isOpen,
    required double rating,
    required int ratingCount,
    required String description,
    required String branchName,
    required List<dynamic> branches,
    required String vendorId,
    required String? activeBranchId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title & Rating Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StoreDetailsTokens.text(
                      size: 17,
                      weight: FontWeight.w900,
                      color: palette.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOpen
                              ? StoreDetailsTokens.successGreen
                              : StoreDetailsTokens.errorRed,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StoreDetailsTokens.text(
                            size: 11,
                            weight: FontWeight.w700,
                            color: palette.textMuted,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Rating Block (aligned top-end, gap 4px)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '($ratingCount)',
                  style: StoreDetailsTokens.numeric(
                    size: 11,
                    weight: FontWeight.w700,
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: StoreDetailsTokens.numeric(
                    size: 13,
                    weight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: StoreDetailsTokens.gold,
                ),
              ],
            ),
          ],
        ),

        // Expandable Description (1-line clamp by default via AppExpandableText)
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          AppExpandableText(
            text: description,
            trimLines: 1,
            style: StoreDetailsTokens.text(
              size: 11,
              weight: FontWeight.w500,
              color: palette.textMuted,
              height: 1.35,
            ),
            readMoreLabel: s.readMoreAction,
            readLessLabel: s.readLessAction,
            toggleColor: palette.goldText,
            toggleStyle: StoreDetailsTokens.text(
              size: 10.5,
              weight: FontWeight.w800,
              color: palette.goldText,
              height: 1.2,
            ),
            showChevron: true,
          ),
        ],

        // Branch Row (padding-top: 2px)
        if (branchName.isNotEmpty || branches.isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 12,
                  color: StoreDetailsTokens.gold,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    isAr ? 'الفرع: $branchName' : 'Branch: $branchName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StoreDetailsTokens.text(
                      size: 11,
                      weight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (branches.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _openBranchModal(
                      context: context,
                      branches: branches,
                      vendorId: vendorId,
                      activeBranchId: activeBranchId,
                      palette: palette,
                      isAr: isAr,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Text(
                        isAr ? 'تغيير' : 'Change',
                        style: StoreDetailsTokens.text(
                          size: 11,
                          weight: FontWeight.w800,
                          color: palette.goldText,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDirectOrderSection({
    required BuildContext context,
    required StoreDetailsPalette palette,
    required bool isAr,
    required String vendorId,
    required String storeName,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: StoreDetailsTokens.gold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final authStatus = ref.read(authControllerProvider);
              if (authStatus == AuthStatus.unauthenticated) {
                AuthPromptDialog.show(context);
                return;
              }
              context.push(
                '/chat/vendor/$vendorId',
                extra: {'title': storeName},
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: StoreDetailsTokens.gold, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.messageCircle,
                    size: 14,
                    color: palette.goldText,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isAr
                          ? 'تواصل لطلب منتجات بشكل مباشر'
                          : 'Chat to order items directly',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StoreDetailsTokens.text(
                        size: 11.5,
                        weight: FontWeight.w800,
                        color: palette.goldText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.info,
              size: 11,
              color: StoreDetailsTokens.gold,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                isAr
                    ? 'يمكنك طلب منتج غير متواجد بالقائمة.'
                    : 'You can request an item not listed in the menu.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StoreDetailsTokens.text(
                  size: 10,
                  weight: FontWeight.w600,
                  color: palette.textMuted,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBar({
    required List<_CategoryPillData> pills,
    required String activeCategoryId,
    required StoreDetailsPalette palette,
    required bool isRtl,
  }) {
    return SizedBox(
      height: 32,
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _catScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: List<Widget>.generate(pills.length, (idx) {
                final pill = pills[idx];
                final isActive = pill.id == activeCategoryId;
                final pillKey = _categoryPillKeys.putIfAbsent(
                  pill.id,
                  () => GlobalKey(),
                );

                return Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: idx == pills.length - 1 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    key: pillKey,
                    onTap: () => _selectCategory(pill.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? StoreDetailsTokens.gold
                            : palette.bgCard,
                        borderRadius: BorderRadius.circular(9999),
                        border: isActive
                            ? null
                            : Border.all(color: palette.borderGold, width: 1),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: StoreDetailsTokens.gold
                                      .withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            pill.label,
                            style: StoreDetailsTokens.text(
                              size: 11,
                              weight: FontWeight.w800,
                              color: isActive
                                  ? StoreDetailsTokens.darkOnGold
                                  : palette.textPrimary,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${pill.count})',
                            style: StoreDetailsTokens.numeric(
                              size: 9.5,
                              weight: FontWeight.w700,
                              color: (isActive
                                      ? StoreDetailsTokens.darkOnGold
                                      : palette.textPrimary)
                                  .withValues(alpha: 0.80),
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Dynamic Start Edge Fade (28px)
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showCatStartFade ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isRtl
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      end: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                      colors: [
                        palette.bgMain,
                        palette.bgMain.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dynamic End Edge Fade (28px)
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            width: 28,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showCatEndFade ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isRtl
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      end: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                      colors: [
                        palette.bgMain,
                        palette.bgMain.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuHeaderAndSearch({
    required StoreDetailsPalette palette,
    required bool isAr,
  }) {
    return Row(
      children: [
        Text(
          isAr ? 'القائمة' : 'Menu',
          style: StoreDetailsTokens.text(
            size: 13.5,
            weight: FontWeight.w900,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 235),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: palette.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.borderGold, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      size: 14,
                      color: StoreDetailsTokens.gold,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        key: const Key('store_menu_search_input'),
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        style: StoreDetailsTokens.text(
                          size: 11,
                          weight: FontWeight.w600,
                          color: palette.textPrimary,
                          height: 1.2,
                        ),
                        cursorColor: StoreDetailsTokens.gold,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText:
                              isAr ? 'ابحث في القائمة...' : 'Search menu...',
                          hintStyle: StoreDetailsTokens.text(
                            size: 11,
                            weight: FontWeight.w500,
                            color: palette.textMuted,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    if (_searchQuery.trim().isNotEmpty) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        key: const Key('store_menu_search_clear'),
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.textMuted.withValues(alpha: 0.25),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.close_rounded,
                            size: 11,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableMenuList({
    required BuildContext context,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> fullVendor,
    required CartState cartState,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isDark,
    required bool isAr,
    required bool isOpen,
    required bool isPharmacy,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.searchX,
                size: 28,
                color: palette.textMuted.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.trim().isNotEmpty
                    ? (isAr
                        ? 'لا توجد أصناف مطابقة'
                        : 'No matching items found')
                    : (isAr
                        ? 'لا توجد أصناف في هذا القسم'
                        : 'No items in this category'),
                style: StoreDetailsTokens.text(
                  size: 12,
                  weight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
              if (_searchQuery.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Text(
                    isAr ? 'مسح البحث' : 'Clear search',
                    style: StoreDetailsTokens.text(
                      size: 11,
                      weight: FontWeight.w800,
                      color: palette.goldText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Flat vertical product list: NO category headers or dividers inside list
    return ListView.separated(
      key: const Key('store_menu_products_list'),
      controller: _menuScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 6),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) => _buildProductCard(
        context: context,
        item: items[index],
        fullVendor: fullVendor,
        cartState: cartState,
        palette: palette,
        s: s,
        isDark: isDark,
        isAr: isAr,
        isOpen: isOpen,
        isPharmacy: isPharmacy,
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required Map<String, dynamic> item,
    required Map<String, dynamic> fullVendor,
    required CartState cartState,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isDark,
    required bool isAr,
    required bool isOpen,
    required bool isPharmacy,
  }) {
    final prodId = item['id']?.toString() ?? '';
    final thumbKey =
        _productThumbKeys.putIfAbsent(prodId, () => GlobalKey());

    final prodName = (isAr &&
            item['nameAr'] != null &&
            item['nameAr'].toString().trim().isNotEmpty)
        ? item['nameAr'].toString().trim()
        : (item['name']?.toString().trim() ?? '');
    final prodDesc = (isAr &&
            item['descriptionAr'] != null &&
            item['descriptionAr'].toString().trim().isNotEmpty)
        ? item['descriptionAr'].toString().trim()
        : (item['description']?.toString().trim() ?? '');
    final thumbUrl =
        (item['imageUrl'] ?? item['image'])?.toString().trim() ?? '';

    final variants = (item['variants'] as List<dynamic>? ?? const []);
    final bool hasVariants =
        (item['hasVariants'] == true || variants.isNotEmpty) &&
            variants.isNotEmpty;
    final optionGroups = (item['optionGroups'] as List<dynamic>? ?? const []);
    final bool hasOptionGroups = optionGroups.isNotEmpty;
    final bool supportsStrips =
        item['sellByStrip'] == true && item['stripsPerPackage'] != null;
    final bool requiresCustomization =
        hasVariants || hasOptionGroups || supportsStrips;

    final double effectivePrice = double.tryParse(
            (item['price'] ?? item['basePrice'])?.toString() ?? '0') ??
        0.0;
    final double comparePrice =
        double.tryParse(item['comparePrice']?.toString() ?? '') ??
            effectivePrice;
    final bool hasDiscount = comparePrice > effectivePrice && effectivePrice > 0;
    final int discountPct = hasDiscount
        ? (((comparePrice - effectivePrice) / comparePrice) * 100).round()
        : 0;

    final bool isOutOfStock = _isItemOutOfStock(item, cartState);
    final bool canOrder = isOpen && !isOutOfStock;

    final String priceLabel = hasVariants
        ? (isAr
            ? 'يبدأ من ${StoreDetailsTokens.formatPrice(effectivePrice)} ${s.egp}'
            : 'From ${StoreDetailsTokens.formatPrice(effectivePrice)} ${s.egp}')
        : '${StoreDetailsTokens.formatPrice(effectivePrice)} ${s.egp}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (!isOpen) {
            _showTopToast(
              isAr ? 'المتجر مغلق حالياً' : 'Store is currently closed',
            );
            return;
          }
          _openProductBottomSheet(
            context: context,
            item: item,
            fullVendor: fullVendor,
            s: s,
            isDark: isDark,
            isPharmacy: isPharmacy,
            isAr: isAr,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.borderGold, width: 1),
            boxShadow: [palette.cardShadow],
          ),
          child: Row(
            children: [
              // 56x56 Thumbnail + optional real discount badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    key: thumbKey,
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: palette.bgCard2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: palette.borderGold, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: thumbUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: ImageUtils.thumbnailUrl(thumbUrl),
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Center(
                              child: Icon(
                                Icons.fastfood_rounded,
                                size: 22,
                                color: palette.textMuted.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.fastfood_rounded,
                              size: 22,
                              color: palette.textMuted.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                  if (hasDiscount && discountPct > 0)
                    PositionedDirectional(
                      top: -6,
                      start: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: StoreDetailsTokens.gold,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.28),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          '-$discountPct%',
                          textDirection: TextDirection.ltr,
                          style: StoreDetailsTokens.numeric(
                            size: 8.5,
                            weight: FontWeight.w900,
                            color: StoreDetailsTokens.darkOnGold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),

              // Text Stack (Name 12px w900, Desc 10px 1-line, Price 11px Inter w900)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StoreDetailsTokens.text(
                        size: 12,
                        weight: FontWeight.w900,
                        color: palette.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    if (prodDesc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        prodDesc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StoreDetailsTokens.text(
                          size: 10,
                          weight: FontWeight.w500,
                          color: palette.textMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            priceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StoreDetailsTokens.numeric(
                              size: 11,
                              weight: FontWeight.w900,
                              color: palette.goldText,
                            ),
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 5),
                          Text(
                            '${StoreDetailsTokens.formatPrice(comparePrice)} ${s.egp}',
                            style: StoreDetailsTokens.numeric(
                              size: 9.5,
                              weight: FontWeight.w600,
                              color: palette.textMuted,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: palette.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Quick Action Button (+ أضف)
              GestureDetector(
                onTap: () {
                  if (!isOpen) {
                    _showTopToast(
                      isAr ? 'المتجر مغلق حالياً' : 'Store is currently closed',
                    );
                    return;
                  }
                  if (isOutOfStock) {
                    _showTopToast(s.outOfStock);
                    return;
                  }
                  if (requiresCustomization) {
                    _openProductBottomSheet(
                      context: context,
                      item: item,
                      fullVendor: fullVendor,
                      s: s,
                      isDark: isDark,
                      isPharmacy: isPharmacy,
                      isAr: isAr,
                    );
                    return;
                  }

                  final authStatus = ref.read(authControllerProvider);
                  if (authStatus == AuthStatus.unauthenticated) {
                    AuthPromptDialog.show(context);
                    return;
                  }

                  final payload = <String, dynamic>{
                    ...item,
                    'vendorId': fullVendor['id'],
                    'vendorName': fullVendor['name'],
                  };
                  final sourceRect = _rectFromKey(thumbKey);
                  _runFlyAndCommit(
                    context: context,
                    sourceRect: sourceRect,
                    imageUrl: thumbUrl,
                    displayName: prodName,
                    isAr: isAr,
                    commitAdd: () => ref
                        .read(cartProvider.notifier)
                        .addItem(payload, unit: 'package'),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: canOrder ? StoreDetailsTokens.gold : palette.bgCard2,
                    borderRadius: BorderRadius.circular(12),
                    border: canOrder
                        ? null
                        : Border.all(color: palette.borderGold, width: 0.8),
                    boxShadow: canOrder
                        ? [
                            BoxShadow(
                              color: StoreDetailsTokens.gold
                                  .withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    isOutOfStock
                        ? s.outOfStock
                        : (isAr ? '+ أضف' : '+ Add'),
                    style: StoreDetailsTokens.text(
                      size: 10.5,
                      weight: FontWeight.w900,
                      color: canOrder
                          ? StoreDetailsTokens.darkOnGold
                          : palette.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickyCartBar({
    required BuildContext context,
    required String vendorId,
    required int totalQty,
    required double totalPrice,
    required StoreDetailsPalette palette,
    required AppStrings s,
    required bool isAr,
  }) {
    return AnimatedBuilder(
      animation: _cartPopController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cartPopTranslateY.value),
          child: Transform.scale(
            scale: _cartPopScale.value,
            child: child,
          ),
        );
      },
      child: Material(
        key: _cartBarKey,
        color: StoreDetailsTokens.gold,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        shadowColor: StoreDetailsTokens.gold.withValues(alpha: 0.35),
        child: InkWell(
          key: const Key('store_sticky_cart_bar'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openCartModal(
            context: context,
            vendorId: vendorId,
            palette: palette,
            s: s,
            isAr: isAr,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.shoppingBag,
                      size: 15,
                      color: StoreDetailsTokens.darkOnGold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAr
                          ? 'عرض السلة ($totalQty)'
                          : 'View Cart ($totalQty)',
                      style: StoreDetailsTokens.text(
                        size: 12,
                        weight: FontWeight.w900,
                        color: StoreDetailsTokens.darkOnGold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${StoreDetailsTokens.formatPrice(totalPrice)} ${s.egp}',
                  style: StoreDetailsTokens.numeric(
                    size: 12,
                    weight: FontWeight.w900,
                    color: StoreDetailsTokens.darkOnGold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton({
    required BuildContext context,
    required StoreDetailsPalette palette,
    required bool isRtl,
  }) {
    return SafeArea(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 112,
                width: double.infinity,
                color: palette.bgCard2,
              ),
              PositionedDirectional(
                top: 12,
                start: 12,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _handleBack(context),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        isRtl
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: const Color(0xFF181613),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(palette, width: 160, height: 18, radius: 6),
                  const SizedBox(height: 6),
                  _skeletonBox(palette, width: 220, height: 12, radius: 6),
                  const SizedBox(height: 10),
                  _skeletonBox(
                    palette,
                    width: double.infinity,
                    height: 36,
                    radius: 12,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _skeletonBox(palette, width: 68, height: 26, radius: 999),
                      const SizedBox(width: 6),
                      _skeletonBox(palette, width: 84, height: 26, radius: 999),
                      const SizedBox(width: 6),
                      _skeletonBox(palette, width: 76, height: 26, radius: 999),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, _) => Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: palette.borderGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            _skeletonBox(
                              palette,
                              width: 56,
                              height: 56,
                              radius: 12,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _skeletonBox(
                                    palette,
                                    width: 130,
                                    height: 12,
                                    radius: 4,
                                  ),
                                  const SizedBox(height: 6),
                                  _skeletonBox(
                                    palette,
                                    width: 170,
                                    height: 10,
                                    radius: 4,
                                  ),
                                  const SizedBox(height: 6),
                                  _skeletonBox(
                                    palette,
                                    width: 72,
                                    height: 11,
                                    radius: 4,
                                  ),
                                ],
                              ),
                            ),
                            _skeletonBox(
                              palette,
                              width: 54,
                              height: 28,
                              radius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox(
    StoreDetailsPalette palette, {
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.bgCard2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildErrorState({
    required BuildContext context,
    required StoreDetailsPalette palette,
    required Object error,
    required String vendorId,
    required bool isAr,
    required bool isRtl,
  }) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            height: 112,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: StoreDetailsTokens.bannerFallbackGradient,
            ),
            child: Stack(
              children: [
                PositionedDirectional(
                  top: 12,
                  start: 12,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _handleBack(context),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          isRtl
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: const Color(0xFF181613),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.borderGold),
                    boxShadow: [palette.cardShadow],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.triangleAlert,
                        size: 32,
                        color: StoreDetailsTokens.gold,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ErrorUtils.translate(context, error),
                        textAlign: TextAlign.center,
                        style: StoreDetailsTokens.text(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(
                          vendorDetailControllerProvider(vendorId),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StoreDetailsTokens.gold,
                          foregroundColor: StoreDetailsTokens.darkOnGold,
                          minimumSize: const Size(140, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isAr ? 'إعادة المحاولة' : 'Retry',
                          style: StoreDetailsTokens.text(
                            size: 12,
                            weight: FontWeight.w900,
                            color: StoreDetailsTokens.darkOnGold,
                          ),
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
    );
  }

  String _localizedStoreName(Map<String, dynamic> fullVendor, bool isAr) {
    final ar = (fullVendor['nameAr'] ?? fullVendor['storeNameAr'])
        ?.toString()
        .trim();
    final en =
        (fullVendor['name'] ?? fullVendor['storeName'])?.toString().trim();
    if (isAr && ar != null && ar.isNotEmpty) return ar;
    if (en != null && en.isNotEmpty) return en;
    return ar ?? '';
  }

  String _localizedStoreDescription(Map<String, dynamic> fullVendor, bool isAr) {
    final ar = (fullVendor['descriptionAr'] ?? fullVendor['vendorAr'])
        ?.toString()
        .trim();
    final en = (fullVendor['description'] ?? fullVendor['vendor'])
        ?.toString()
        .trim();
    if (isAr && ar != null && ar.isNotEmpty) return ar;
    if (en != null && en.isNotEmpty) return en;
    return ar ?? '';
  }

  String _buildStoreSubtitle(
    Map<String, dynamic> fullVendor,
    bool isOpen,
    bool isAr,
    AppStrings s,
  ) {
    final statusLabel = isOpen
        ? (isAr ? 'مفتوح الآن' : 'Open now')
        : (isAr ? 'مغلق الآن' : 'Closed now');
    final vertical = fullVendor['vertical'];
    final verticalLabel = vertical is Map
        ? ((isAr
                    ? (vertical['nameAr'] ?? vertical['name'])
                    : (vertical['name'] ?? vertical['nameAr']))
                ?.toString()
                .trim() ??
            '')
        : '';
    final deliveryTime = (isAr
            ? fullVendor['deliveryTime']
            : (fullVendor['deliveryTimeEn'] ?? fullVendor['deliveryTime']))
        ?.toString()
        .trim();

    final parts = <String>[statusLabel];
    if (verticalLabel.isNotEmpty) parts.add(verticalLabel);
    if (deliveryTime != null && deliveryTime.isNotEmpty) {
      parts.add(deliveryTime);
    }
    return parts.join(' • ');
  }

  bool _isItemOutOfStock(Map<String, dynamic> item, CartState cartState) {
    final variants = (item['variants'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .toList();
    final bool hasVariants =
        (item['hasVariants'] == true || variants.isNotEmpty) &&
            variants.isNotEmpty;
    final bool productTracksStock = item['tracksStock'] == null
        ? true
        : (item['tracksStock'] == true);

    if (hasVariants) {
      return variants.every((v) {
        final vTracks = v['tracksStock'] == null
            ? productTracksStock
            : (v['tracksStock'] == true);
        final vStock = int.tryParse(v['stock']?.toString() ?? '');
        if (!vTracks || vStock == null) return false;
        if (vStock <= 0) return true;
        final inCart = cartState.allItems
            .where((ci) => ci.selectedVariant?.id == v['id']?.toString())
            .fold<int>(0, (sum, ci) => sum + ci.quantity);
        return inCart >= vStock;
      });
    }

    final productStock = int.tryParse(item['stock']?.toString() ?? '');
    if (!productTracksStock || productStock == null) return false;
    if (productStock <= 0) return true;

    final inCart = cartState.allItems
        .where((ci) =>
            ci.product.id == item['id']?.toString() &&
            ci.selectedVariant == null)
        .fold<int>(0, (sum, ci) => sum + ci.quantity);
    return inCart >= productStock;
  }
}

class _CategoryPillData {
  final String id;
  final String label;
  final int count;

  const _CategoryPillData({
    required this.id,
    required this.label,
    required this.count,
  });
}
