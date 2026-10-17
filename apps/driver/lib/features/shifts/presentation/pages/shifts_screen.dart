import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:driver/features/shifts/presentation/shifts_provider.dart';
import 'package:driver/l10n/app_localizations.dart';
import 'package:driver/core/utils/error_utils.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:core/core.dart';

import 'package:driver/features/shifts/presentation/widgets/available_shifts_tab.dart';
import 'package:driver/features/shifts/presentation/widgets/swap_board_tab.dart';
import 'package:driver/core/providers/configuration_provider.dart';

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final config = ref.watch(configurationProvider);

    if (config.hasValue && config.value?['driverShiftsEnabled'] == false) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.myShiftsTitle)),
        body: EmptyStateWidget(
          icon: LucideIcons.calendarOff,
          title: l10n.shiftsDisabledTitle,
          subtitle: l10n.shiftsDisabledSubtitle,
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.myShiftsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.myShiftsTab),
              Tab(text: l10n.availableShiftsTab),
              Tab(text: l10n.swapBoardTab),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        body: const TabBarView(
          children: [
            _MyShiftsTab(),
            AvailableShiftsTab(),
            SwapBoardTab(),
          ],
        ),
      ),
    );
  }
}

class _MyShiftsTab extends ConsumerStatefulWidget {
  const _MyShiftsTab();

  @override
  ConsumerState<_MyShiftsTab> createState() => _MyShiftsTabState();
}

class _MyShiftsTabState extends ConsumerState<_MyShiftsTab> {
  String? _startingShiftId;

  String _resolveMediaUrl(String path) {
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    if (path.startsWith('http')) return path;
    return '$cleanBaseUrl$cleanPath';
  }

  void _viewPhoto(String url, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    _resolveMediaUrl(url),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      LucideIcons.imageOff,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(LucideIcons.x, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selfie + GPS start flow: capture a front-camera selfie, confirm it,
  /// then start. The backend requires the photo and verifies the driver
  /// is inside the shift zone; on success the driver goes ONLINE.
  Future<void> _startShiftWithSelfie(
    Map<String, dynamic> shift,
    AppLocalizations l10n,
  ) async {
    final isAr = l10n.localeName == 'ar';
    final shiftId = shift['id']?.toString() ?? '';
    if (shiftId.isEmpty) return;
    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (_) {
      photo = null;
    }
    if (photo == null || !mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(photo!.path),
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'سيتم إرسال هذه الصورة مع موقعك لبدء الوردية. يجب أن تكون داخل منطقة الوردية.'
                  : 'This photo and your location will start the shift. You must be inside the shift zone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(isAr ? 'إعادة الالتقاط' : 'Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.startShift),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      // Retake: restart the flow.
      if (mounted) _startShiftWithSelfie(shift, l10n);
      return;
    }

    setState(() => _startingShiftId = shiftId);
    try {
      double? lat;
      double? lng;
      try {
        final perm = await Geolocator.checkPermission();
        if (perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          ).timeout(const Duration(seconds: 10));
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {
        // No GPS: the server will answer with a clear zone error.
      }
      await ref.read(driverShiftsProvider.notifier).startShift(
            shiftId,
            photoPath: photo.path,
            latitude: lat,
            longitude: lng,
          );
      ref.invalidate(driverProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'بدأت الوردية، أنت الآن متصل' : 'Shift started — you are now online'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.translate(context, e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _startingShiftId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftsState = ref.watch(driverShiftsProvider);
    final l10n = AppLocalizations.of(context)!;

    return shiftsState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (error, _) {
        if (error.toString().toLowerCase().contains('shifts_disabled')) {
          return EmptyStateWidget(
            icon: LucideIcons.calendarOff,
            title: l10n.shiftsDisabledTitle,
            subtitle: l10n.shiftsDisabledSubtitle,
          );
        }
        return Center(child: Text(ErrorUtils.translate(context, error)));
      },
      data: (shifts) {
        if (shifts.isEmpty) {
          return EmptyStateWidget(
            icon: LucideIcons.calendar,
            title: l10n.noShiftsScheduled,
            subtitle: l10n.noUpcomingShifts,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(driverShiftsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shifts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildShiftItem(context, ref, shifts[index], l10n);
            },
          ),
        );
      },
    );
  }

  Widget _buildShiftItem(BuildContext context, WidgetRef ref, Map<String, dynamic> shift, AppLocalizations l10n) {
    final status = shift['status'] ?? 'UNKNOWN';
    String startTime = shift['startTime'] ?? shift['shiftPool']?['startTime'] ?? '';
    String endTime = shift['endTime'] ?? shift['shiftPool']?['endTime'] ?? '';
    String dayLabel = '';

    try {
      final rawStart = shift['startTime'] ?? shift['shiftPool']?['startTime'] ?? '';
      if (rawStart.toString().isNotEmpty) {
        final d = DateTime.parse(rawStart.toString()).toLocal();
        try {
          dayLabel = DateFormat('EEEE, MMM d', l10n.localeName).format(d);
        } catch (_) {
          dayLabel = DateFormat('EEEE, MMM d').format(d);
        }
      }
      if (startTime.isNotEmpty) {
        final d = DateTime.parse(startTime).toLocal();
        startTime = DateFormat.jm().format(d);
      }
      if (endTime.isNotEmpty) {
        final d = DateTime.parse(endTime).toLocal();
        endTime = DateFormat.jm().format(d);
      }
    } catch (_) {}

    final zoneName = shift['zone']?['name'] ?? shift['shiftPool']?['zone']?['name'] ?? l10n.assignedZone;

    final isUpcoming = status == 'SCHEDULED';
    final isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  zoneName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withValues(alpha: 0.2) : (isUpcoming ? AppColors.warning.withValues(alpha: 0.2) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? AppColors.primary : (isUpcoming ? AppColors.warning : Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 16),
          if (dayLabel.isNotEmpty) ...[
            Row(
              children: [
                Icon(LucideIcons.calendarDays, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(LucideIcons.clock, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                '$startTime - $endTime',
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if ((shift['startPhotoUrl']?.toString().isNotEmpty ?? false)) ...[
            GestureDetector(
              onTap: () => _viewPhoto(shift['startPhotoUrl'].toString(), l10n),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _resolveMediaUrl(
                          shift['startPhotoUrl'].toString(),
                        ),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: Theme.of(context).dividerColor,
                          child: const Icon(
                            LucideIcons.imageOff,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.localeName == 'ar'
                            ? 'صورة بدء الوردية — اضغط للتكبير'
                            : 'Shift start photo — tap to enlarge',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(LucideIcons.zoomIn, size: 18),
                  ],
                ),
              ),
            ),
          ],
          if (isUpcoming)
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: l10n.startShift,
                    isLoading: _startingShiftId == shift['id']?.toString(),
                    onPressed: _startingShiftId != null
                        ? null
                        : () => _startShiftWithSelfie(
                              Map<String, dynamic>.from(shift),
                              l10n,
                            ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showOfferSwapDialog(context, ref, shift['id'], l10n);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.offerSwap, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  void _showOfferSwapDialog(BuildContext context, WidgetRef ref, String shiftId, AppLocalizations l10n) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return DialogScaffold(child: AlertDialog(
          title: Text(l10n.offerSwap),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(
              labelText: l10n.reasonOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelAction),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(driverShiftsProvider.notifier).offerSwap(shiftId, reasonController.text);
                Navigator.pop(context);
              },
              child: Text(l10n.offerSwapAction),
            ),
          ],
        ));
      },
    );
  }
}
