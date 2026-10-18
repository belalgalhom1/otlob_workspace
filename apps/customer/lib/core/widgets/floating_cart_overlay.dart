import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../features/cart/presentation/providers/cart_controller.dart';
import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';

class FloatingCartOverlay extends ConsumerStatefulWidget {
  const FloatingCartOverlay({super.key});

  @override
  ConsumerState<FloatingCartOverlay> createState() => _FloatingCartOverlayState();
}

class _FloatingCartOverlayState extends ConsumerState<FloatingCartOverlay>
    with WidgetsBindingObserver {
  static const double _cartWidth = 200;
  static const double _cartHeight = 60;
  static const double _margin = 16;
  static const double _bottomClearance = 28;
  static const double _trashSize = 80;
  static const double _dropRadius = 110;

  Offset _offset = const Offset(0, 0);
  bool _isInitialized = false;
  bool _isDragging = false;
  bool _isOverTrash = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning to the app can change the viewport (system bars, split screen,
    // rotation, keyboard). Force a rebuild so the build-time clamp below snaps
    // the cart back inside the visible area instead of leaving it stranded
    // off-screen where it can no longer be dragged.
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  void _resetDragState() {
    if (!_isDragging && !_isOverTrash) return;
    setState(() {
      _isDragging = false;
      _isOverTrash = false;
    });
  }

  bool _isOverTrashZone(double cartCenterX, double cartCenterY,
      Offset trashCenter) {
    final distance = sqrt(pow(cartCenterX - trashCenter.dx, 2) +
        pow(cartCenterY - trashCenter.dy, 2));
    return distance < _dropRadius;
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    if (cartState.totalItems == 0) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    double totalCartPrice = 0;
    for (final vendorItems in cartState.vendorBaskets.values) {
      for (final item in vendorItems) {
        totalCartPrice += item.totalPrice;
      }
    }

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          final maxX = (maxWidth - _cartWidth - _margin)
              .clamp(_margin, double.infinity);
          final maxY = (maxHeight -
                  _cartHeight -
                  _margin -
                  bottomInset -
                  _bottomClearance)
              .clamp(_margin, double.infinity);

          if (!_isInitialized) {
            _offset = Offset(maxX, maxY);
            _isInitialized = true;
          }

          // Self-heal: always keep the cart inside the current viewport, even
          // if the layout changed while it was parked at a previous position.
          _offset = Offset(
            _offset.dx.clamp(_margin, maxX),
            _offset.dy.clamp(_margin, maxY),
          );
          final effectiveOffset = _offset;

          // The trash sits inside the same reachable area as the cart, so the
          // cart can always be dropped onto it instead of getting stuck above
          // it (e.g. behind the system navigation bar).
          final trashCenter = Offset(
            maxWidth / 2,
            maxHeight - _margin - bottomInset - _trashSize / 2,
          );

          return Stack(
            children: [
              // TRASH BIN
              if (_isDragging)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _margin + bottomInset,
                  child: Center(
                    child: AnimatedScale(
                      scale: _isOverTrash ? 1.3 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: _trashSize,
                        height: _trashSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOverTrash
                              ? AppColors.error
                              : AppColors.error.withValues(alpha: 0.5),
                          boxShadow: _isOverTrash
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.error.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ]
                              : [],
                        ),
                        child: const Icon(LucideIcons.trash2,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),

              // DRAGGABLE CART
              Positioned(
                left: effectiveOffset.dx,
                top: effectiveOffset.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) {
                    setState(() => _isDragging = true);
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _offset = Offset(
                        (_offset.dx + details.delta.dx).clamp(_margin, maxX),
                        (_offset.dy + details.delta.dy).clamp(_margin, maxY),
                      );
                      _isOverTrash = _isOverTrashZone(
                        _offset.dx + _cartWidth / 2,
                        _offset.dy + _cartHeight / 2,
                        trashCenter,
                      );
                    });
                  },
                  onPanEnd: (_) {
                    if (_isOverTrash) {
                      ref.read(cartProvider.notifier).clearCart();
                      // Reset so a re-added cart starts fresh at the default
                      // corner instead of being stuck where it was dropped.
                      _isInitialized = false;
                      _offset = const Offset(0, 0);
                    } else {
                      // Snap to nearest edge (left or right)
                      final middle = maxWidth / 2;
                      final isRightSide = (_offset.dx + _cartWidth / 2) > middle;
                      _offset = Offset(isRightSide ? maxX : _margin, _offset.dy);
                    }
                    setState(() {
                      _isDragging = false;
                      _isOverTrash = false;
                    });
                  },
                  // A cancelled pan must not leave the drag/trash visuals stuck
                  // on screen with the cart frozen in the dragging state.
                  onPanCancel: _resetDragState,
                  child: AnimatedOpacity(
                    opacity: _isOverTrash ? 0.5 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedScale(
                      scale: _isOverTrash ? 0.8 : (_isDragging ? 1.05 : 1.0),
                      duration: const Duration(milliseconds: 200),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.push('/cart'),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: _cartWidth,
                            height: _cartHeight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${cartState.totalItems}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(LucideIcons.shoppingCart,
                                        color: Colors.black, size: 20),
                                  ],
                                ),
                                Text(
                                  '${totalCartPrice.toStringAsFixed(2)} ${s.egp}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
