import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/services/open_maps_service.dart' as osm;
import '../../../../core/services/location_service.dart';
import '../../ride/domain/ride_models.dart';

/// A live OpenStreetMap for the tracking screen that:
/// - Shows pickup and drop markers
/// - Draws the route polyline
/// - Animates a driver marker smoothly along the route
/// - Continuously updates user's live location
/// - Works on ALL platforms — no API key required!
class LiveTrackingMap extends ConsumerStatefulWidget {
  const LiveTrackingMap({super.key, required this.trip});

  final RideTrip trip;

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  osm.RouteInfo? _routeInfo;
  LatLng? _driverPosition;
  LatLng? _userPosition;
  Timer? _driverSimTimer;
  int _routeStepIndex = 0;
  AnimationController? _markerAnimController;
  bool _isRouteLoaded = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _driverPosition = LatLng(
      widget.trip.pickup.latitude,
      widget.trip.pickup.longitude,
    );
    _userPosition = LatLng(
      widget.trip.pickup.latitude,
      widget.trip.pickup.longitude,
    );
    _loadRouteAndStartSimulation();
    if (!kIsWeb) {
      _startUserLocationTracking();
    }
  }

  Future<void> _loadRouteAndStartSimulation() async {
    final mapsService = ref.read(osm.openMapsServiceProvider);
    final origin = LatLng(
      widget.trip.pickup.latitude,
      widget.trip.pickup.longitude,
    );
    final destination = LatLng(
      widget.trip.destination.latitude,
      widget.trip.destination.longitude,
    );

    final route = await mapsService.getRoute(
      origin: origin,
      destination: destination,
    );

    if (mounted && route != null) {
      setState(() {
        _routeInfo = route;
        _isRouteLoaded = true;
      });
      // Fit camera to bounds
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds(
                route.bounds.southwest,
                route.bounds.northeast,
              ),
              padding: const EdgeInsets.all(80),
            ),
          );
        } catch (_) {}
      });
      // Start simulating driver movement along the route
      _startDriverSimulation();
    }
  }

  void _startDriverSimulation() {
    if (_routeInfo == null || _routeInfo!.polylinePoints.length < 2) return;

    // Move every 2 seconds, advancing along the polyline
    _driverSimTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _routeInfo == null) {
        timer.cancel();
        return;
      }

      final points = _routeInfo!.polylinePoints;
      if (_routeStepIndex >= points.length - 1) {
        timer.cancel();
        return;
      }

      // Advance 1-3 steps per tick depending on route length
      final stepAdvance = max(1, (points.length / 30).round());
      _routeStepIndex = min(_routeStepIndex + stepAdvance, points.length - 1);

      final nextPos = points[_routeStepIndex];
      _animateDriverTo(nextPos);
    });
  }

  void _animateDriverTo(LatLng target) {
    final from = _driverPosition ?? target;
    _markerAnimController?.dispose();
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final latAnim = Tween<double>(
      begin: from.latitude,
      end: target.latitude,
    ).animate(CurvedAnimation(
      parent: _markerAnimController!,
      curve: Curves.easeInOutCubic,
    ));

    final lngAnim = Tween<double>(
      begin: from.longitude,
      end: target.longitude,
    ).animate(CurvedAnimation(
      parent: _markerAnimController!,
      curve: Curves.easeInOutCubic,
    ));

    _markerAnimController!.addListener(() {
      if (mounted) {
        setState(() {
          _driverPosition = LatLng(latAnim.value, lngAnim.value);
        });
      }
    });
    _markerAnimController!.forward();
  }

  void _startUserLocationTracking() {
    final locationService = ref.read(locationServiceProvider);
    locationService.startTracking(distanceFilter: 15);
    locationService.locationStream.listen((location) {
      if (mounted) {
        setState(() {
          _userPosition = LatLng(location.latitude, location.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    _driverSimTimer?.cancel();
    _markerAnimController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pickupLatLng = LatLng(
      widget.trip.pickup.latitude,
      widget.trip.pickup.longitude,
    );
    final dropLatLng = LatLng(
      widget.trip.destination.latitude,
      widget.trip.destination.longitude,
    );

    return Stack(
      children: [
        _buildMap(isDark, pickupLatLng, dropLatLng),
        // Route info overlay
        if (_isRouteLoaded && _routeInfo != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _RouteInfoBadge(
                  routeInfo: _routeInfo!,
                  trip: widget.trip,
                  isDark: isDark,
                ),
              ),
            ),
          ),
        // Re-center button
        Positioned(
          right: AppSpacing.md,
          bottom: 300,
          child: Material(
            elevation: 4,
            shape: const CircleBorder(),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: InkWell(
              onTap: () {
                if (_routeInfo != null) {
                  try {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: LatLngBounds(
                          _routeInfo!.bounds.southwest,
                          _routeInfo!.bounds.northeast,
                        ),
                        padding: const EdgeInsets.all(80),
                      ),
                    );
                  } catch (_) {}
                }
              },
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.fullscreen_rounded, color: AppColors.primary),
              ),
            ),
          ),
        ),
        // OSM Attribution
        Positioned(
          left: 8,
          bottom: 290,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '© OpenStreetMap',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(bool isDark, LatLng pickupLatLng, LatLng dropLatLng) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: pickupLatLng,
        initialZoom: AppConfig.defaultMapZoom,
      ),
      children: [
        // OpenStreetMap tiles — free, no key needed
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
          userAgentPackageName: 'com.rideconnect.app',
          maxZoom: 19,
        ),
        // Route polyline
        if (_routeInfo != null && _routeInfo!.polylinePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routeInfo!.polylinePoints,
                strokeWidth: 9,
                color: AppColors.primaryDark.withOpacity(0.2),
              ),
              Polyline(
                points: _routeInfo!.polylinePoints,
                strokeWidth: 5,
                color: AppColors.primary,
              ),
            ],
          ),
        // Markers
        MarkerLayer(
          markers: _buildMarkers(pickupLatLng, dropLatLng),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(LatLng pickup, LatLng drop) {
    final markers = <Marker>[
      // Pickup marker
      Marker(
        point: pickup,
        width: 44,
        height: 44,
        child: const _TrackingPin(
          color: AppColors.pickupMarker,
          icon: Icons.my_location_rounded,
          label: 'P',
        ),
      ),
      // Drop marker
      Marker(
        point: drop,
        width: 44,
        height: 44,
        child: const _TrackingPin(
          color: AppColors.dropMarker,
          icon: Icons.location_on_rounded,
          label: 'D',
        ),
      ),
    ];

    // Driver marker
    if (_driverPosition != null) {
      markers.add(
        Marker(
          point: _driverPosition!,
          width: 48,
          height: 48,
          child: _TrackingPin(
            color: Colors.deepPurple,
            icon: Icons.local_taxi_rounded,
            label: widget.trip.driver?.name.substring(0, 1) ?? '🚗',
          ),
        ),
      );
    }

    // User marker
    if (_userPosition != null) {
      markers.add(
        Marker(
          point: _userPosition!,
          width: 36,
          height: 36,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ),
      );
    }

    return markers;
  }
}

/// Custom map marker pin for the tracking screen.
class _TrackingPin extends StatelessWidget {
  const _TrackingPin({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

/// A floating badge showing route distance and ETA on the tracking map.
class _RouteInfoBadge extends StatelessWidget {
  const _RouteInfoBadge({
    required this.routeInfo,
    required this.trip,
    required this.isDark,
  });

  final osm.RouteInfo routeInfo;
  final RideTrip trip;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withOpacity(0.94),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.large,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InfoChip(
            icon: Icons.straighten_rounded,
            label: routeInfo.distanceText,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          _InfoChip(
            icon: Icons.schedule_rounded,
            label: routeInfo.durationText,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.md),
          _InfoChip(
            icon: Icons.local_taxi_rounded,
            label: trip.driver?.name ?? 'Driver',
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}
