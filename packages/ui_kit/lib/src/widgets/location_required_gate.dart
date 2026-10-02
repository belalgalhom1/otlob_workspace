import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';

/// App-level gate that blocks the whole app until the device's location
/// services are turned ON.
///
/// It keeps [child] (the app's Navigator) mounted underneath and only overlays
/// the blocking screen when the location service is disabled, so navigation
/// state survives a settings round-trip. The check re-runs automatically when
/// the app resumes (e.g. the user returns from the system location settings).
class LocationRequiredGate extends StatefulWidget {
  const LocationRequiredGate({
    super.key,
    required this.child,
    this.title,
    this.message,
    this.buttonLabel,
  });

  final Widget child;
  final String? title;
  final String? message;
  final String? buttonLabel;

  @override
  State<LocationRequiredGate> createState() => _LocationRequiredGateState();
}

class _LocationRequiredGateState extends State<LocationRequiredGate>
    with WidgetsBindingObserver {
  bool? _serviceEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
  }

  Future<void> _check() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted && enabled != _serviceEnabled) {
      setState(() => _serviceEnabled = enabled);
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = _serviceEnabled;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (enabled == null)
          Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          )
        else if (!enabled)
          Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 112,
                      height: 112,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(
                        LucideIcons.mapPin,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.title ?? 'Location required',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.message ??
                          'Please enable location services to continue.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _openLocationSettings,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.navigation, size: 20),
                      label: Text(
                        widget.buttonLabel ?? 'Enable location',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}