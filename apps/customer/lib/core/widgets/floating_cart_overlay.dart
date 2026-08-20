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

class _FloatingCartOverlayState extends ConsumerState<FloatingCartOverlay> {
  Offset _offset = const Offset(0, 0);
  bool _isInitialized = false;
  bool _isDragging = false;
  bool _isOverTrash = false;



  void _checkTrashProximity(Size size) {
    // Trash center is at (size.width / 2, size.height - 40)
    final cartCenterX = _offset.dx + 100;
    final cartCenterY = _offset.dy + 30;
    
    final trashCenterX = size.width / 2;
    final trashCenterY = size.height - 40;

    final distance = sqrt(pow(cartCenterX - trashCenterX, 2) + pow(cartCenterY - trashCenterY, 2));

    if (distance < 100) {
      if (!_isOverTrash) setState(() => _isOverTrash = true);
    } else {
      if (_isOverTrash) setState(() => _isOverTrash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    if (cartState.totalItems == 0) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final size = MediaQuery.of(context).size;

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

          // Initialize offset safely within constraints if not already set
          if (!_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _offset = Offset(maxWidth - 216.0, maxHeight - 120.0);
                _isInitialized = true;
              });
            });
            // Provide a temporary default before initialization
            _offset = Offset(maxWidth - 216.0, maxHeight - 120.0);
          }

          return Stack(
            children: [
              // TRASH BIN
              if (_isDragging)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: AnimatedScale(
                    scale: _isOverTrash ? 1.5 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isOverTrash ? AppColors.error : AppColors.error.withValues(alpha: 0.5),
                        boxShadow: _isOverTrash
                            ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)]
                            : [],
                      ),
                      child: const Icon(LucideIcons.trash2, color: Colors.white, size: 32),
                    ),
                  ),
                ),

              // DRAGGABLE CART
              Positioned(
                left: _offset.dx,
                top: _offset.dy,
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() => _isDragging = true);
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _offset += details.delta;
                      // Constrain to parent bounds (LayoutBuilder constraints)
                      _offset = Offset(
                        _offset.dx.clamp(16.0, maxWidth - 216.0),
                        _offset.dy.clamp(16.0, maxHeight - 120.0),
                      );
                    });
                    _checkTrashProximity(Size(maxWidth, maxHeight));
                  },
                  onPanEnd: (_) {
                    if (_isOverTrash) {
                      ref.read(cartProvider.notifier).clearCart();
                    } else {
                      // Snap to nearest edge (left or right)
                      final middle = maxWidth / 2;
                      final isRightSide = (_offset.dx + 100) > middle;
                      _offset = Offset(
                        isRightSide ? (maxWidth - 216.0) : 16.0,
                        _offset.dy,
                      );
                    }
                    setState(() {
                      _isDragging = false;
                      _isOverTrash = false;
                    });
                  },
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
                        width: 200,
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
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
                                const Icon(LucideIcons.shoppingCart, color: Colors.black, size: 20),
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
