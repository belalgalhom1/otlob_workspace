import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data/data.dart';
import 'package:driver/core/router/app_router.dart';
import 'package:driver/features/dispatch/presentation/pages/dispatch_modal.dart';
import 'package:driver/features/dashboard/presentation/driver_profile_provider.dart';

enum DispatchTapResult {
  notDispatch,
  pending,
  notPending,
}

bool _mapToOnline(Object? profile) {
  if (profile is! Map) return false;
  final data = profile['data'];
  if (data is Map && data['status'] != null) {
    final s = data['status']?.toString();
    return s == 'ONLINE' || s == 'ON_DELIVERY';
  }
  final s = profile['status']?.toString();
  return s == 'ONLINE' || s == 'ON_DELIVERY';
}

class DriverDispatchCoordinator {
  DriverDispatchCoordinator(this._ref);

  final Ref _ref;

  String? currentShowingDispatchId;

  void showDispatchModal(Map<String, dynamic> dispatchData) {
    final dispatchId =
        dispatchData['dispatchId']?.toString() ?? dispatchData['id']?.toString();
    if (dispatchId == null) return;

    if (dispatchData['expiresAt'] != null) {
      try {
        final expiresAt = DateTime.parse(dispatchData['expiresAt'].toString());
        if (DateTime.now().isAfter(expiresAt)) return;
      } catch (_) {}
    }

    if (currentShowingDispatchId == dispatchId) {
      return;
    }

    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      currentShowingDispatchId = dispatchId;
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();

      DispatchModal.show(context, dispatchData).whenComplete(() {
        if (currentShowingDispatchId == dispatchId) {
          currentShowingDispatchId = null;
        }
      });
    }
  }

  void dismissDispatchModal(String? dispatchId) {
    if (dispatchId != null &&
        currentShowingDispatchId != null &&
        currentShowingDispatchId != dispatchId) {
      return;
    }
    currentShowingDispatchId = null;
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      Navigator.of(context).popUntil((route) {
        if (route.settings.name == 'dispatch_modal_route') {
          return false;
        }
        return true;
      });
    }
  }

  Future<void> checkPendingDispatches({bool checkOnline = true}) async {
    try {
      if (checkOnline) {
        final profile = _ref.read(driverProfileProvider).value;
        if (!_mapToOnline(profile)) {
          return;
        }
      }

      final repo = _ref.read(driverDispatchRepositoryProvider);
      final dispatches = await repo.getMyDispatches();
      if (dispatches is List && dispatches.isNotEmpty) {
        for (final item in dispatches) {
          if (item is Map) {
            showDispatchModal(Map<String, dynamic>.from(item));
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('DriverDispatchCoordinator: check pending dispatches error: $e');
    }
  }

  Future<DispatchTapResult> handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notification,
  ) async {
    Map<String, dynamic>? payload;
    final data = notification['data'];
    if (data is Map) {
      payload = Map<String, dynamic>.from(data);
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    final dispatchId =
        payload?['dispatchId']?.toString() ?? payload?['id']?.toString();
    if (payload?['type'] != 'DISPATCH' && dispatchId == null) {
      return DispatchTapResult.notDispatch;
    }

    try {
      final repo = _ref.read(driverDispatchRepositoryProvider);
      final dispatches = await repo.getMyDispatches();
      if (dispatches is List) {
        for (final item in dispatches) {
          if (item is Map) {
            final match =
                item['dispatchId']?.toString() ?? item['id']?.toString();
            if (dispatchId == null || match == dispatchId) {
              showDispatchModal(Map<String, dynamic>.from(item));
              return DispatchTapResult.pending;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('DriverDispatchCoordinator: notification tap error: $e');
    }

    return DispatchTapResult.notPending;
  }
}

final driverDispatchCoordinatorProvider = Provider<DriverDispatchCoordinator>(
  (ref) => DriverDispatchCoordinator(ref),
);