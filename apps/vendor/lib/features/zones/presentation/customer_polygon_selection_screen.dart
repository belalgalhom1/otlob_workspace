import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:vendor/generated/l10n/app_localizations.dart';
import 'package:data/data.dart';
import 'package:vendor/core/providers.dart';
import 'package:vendor/core/utils/error_utils.dart';

class CustomerPolygonSelectionScreen extends ConsumerStatefulWidget {
  const CustomerPolygonSelectionScreen({super.key});

  @override
  ConsumerState<CustomerPolygonSelectionScreen> createState() => _CustomerPolygonSelectionScreenState();
}

class _CustomerPolygonSelectionScreenState extends ConsumerState<CustomerPolygonSelectionScreen> {
  final MapController _mapController = MapController();
  final List<LatLng> _polygonPoints = [];
  bool _isLoading = false;
  List<dynamic> _customers = [];

  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    if (_customers.isNotEmpty) {
      // Clear results if user starts drawing again
      setState(() {
        _customers.clear();
      });
    }
    setState(() {
      _polygonPoints.add(latlng);
    });
  }

  void _undoPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
        _customers.clear();
      });
    }
  }

  void _resetPolygon() {
    setState(() {
      _polygonPoints.clear();
      _customers.clear();
    });
  }

  Future<void> _findCustomers() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tapMapToDrawMinimum),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(zonesRepositoryProvider);
      
      // Close the polygon for backend (first point == last point)
      List<List<double>> ring = _polygonPoints.map((p) => [p.longitude, p.latitude]).toList();
      ring.add([_polygonPoints.first.longitude, _polygonPoints.first.latitude]);
      
      final polygon = [ring];

      final response = await repo.searchCustomersInPolygon(polygon);
      
      if (!mounted) return;
      setState(() {
        _customers = response['customers'] ?? [];
        _isLoading = false;
      });

      if (_customers.isNotEmpty) {
        _showResultsBottomSheet();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noUsersFound),
            backgroundColor: AppColors.info,
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorUtils.translate(context, e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showResultsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.customerResults,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.customersFound(_customers.length.toString()),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      itemCount: _customers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        final regDate = customer['registrationDate'] != null 
                            ? DateTime.parse(customer['registrationDate'].toString()).toLocal().toString().split(' ')[0]
                            : '';
                        
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: const Icon(LucideIcons.user, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer['customerName'] ?? AppLocalizations.of(context)!.unknownUser,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          customer['phone'] ?? '',
                                          style: const TextStyle( fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${customer['ordersCount']} ${AppLocalizations.of(context)!.ordersCount}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${AppLocalizations.of(context)!.registrationDate}: $regDate',
                                style: const TextStyle( fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];
    
    // Create markers for customers
    for (var c in _customers) {
      if (c['matchedAddresses'] != null && c['matchedAddresses'] is List) {
        for (var addr in c['matchedAddresses']) {
          if (addr != null && addr['location'] != null) {
            try {
              final coordinates = addr['location']['coordinates'];
              if (coordinates != null && coordinates.length == 2) {
                markers.add(
                  Marker(
                    point: LatLng(coordinates[1], coordinates[0]),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      LucideIcons.mapPin,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                );
              }
            } catch (e) {
              // Ignore invalid coords
            }
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.audienceSelection),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(30.0444, 31.2357), // Default Cairo
              initialZoom: 12,
              onTap: _handleTap,
            ),
            children: [
              const AppMapTileLayer(userAgentPackageName: 'com.otlob.admin'),
              if (_polygonPoints.isNotEmpty)
                PolygonLayer(
                  polygons: <Polygon<Object>>[
                    Polygon<Object>(
                      points: _polygonPoints,
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (_polygonPoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _polygonPoints,
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ],
                ),
              if (markers.isNotEmpty)
                MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: AppColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.polygonInstructions,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_customers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FloatingActionButton.extended(
                      onPressed: _showResultsBottomSheet,
                      icon: const Icon(LucideIcons.list),
                      label: Text(AppLocalizations.of(context)!.customerResults),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _undoPoint,
                        icon: const Icon(LucideIcons.undo),
                        tooltip: AppLocalizations.of(context)!.undoPoint,
                      ),
                      IconButton(
                        onPressed: _resetPolygon,
                        icon: const Icon(LucideIcons.rotateCcw),
                        tooltip: AppLocalizations.of(context)!.resetPolygon,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _findCustomers,
                          icon: _isLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(LucideIcons.search),
                          label: Text(AppLocalizations.of(context)!.findCustomers),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
