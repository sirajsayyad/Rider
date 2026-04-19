import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../../../core/services/location_service.dart';
import '../../ride/domain/ride_models.dart';

/// A live Google Map for the tracking screen that:
/// - Shows pickup and drop markers
/// - Draws the route polyline
/// - Animates a driver marker smoothly along the route
/// - Continuously updates user's live location
/// - Falls back to a styled preview on web when Maps JS API is missing
class LiveTrackingMap extends ConsumerStatefulWidget {
  const LiveTrackingMap({super.key, required this.trip});

  final RideTrip trip;

  @override
  ConsumerState<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends ConsumerState<LiveTrackingMap>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  RouteInfo? _routeInfo;
  LatLng? _driverPosition;
  LatLng? _userPosition;
  Timer? _driverSimTimer;
  int _routeStepIndex = 0;
  AnimationController? _markerAnimController;
  bool _isRouteLoaded = false;
  bool _mapLoadFailed = false;

  @override
  void initState() {
    super.initState();
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
    final mapsService = ref.read(googleMapsServiceProvider);
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
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(route.bounds, 80),
        );
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
    _mapController?.dispose();
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

    if (kIsWeb) {
      return _TrackingFallbackMap(
        trip: widget.trip,
        routeInfo: _routeInfo,
        isDark: isDark,
      );
    }

    // Show fallback when GoogleMap fails to load (e.g. missing API key on web)
    if (_mapLoadFailed) {
      return _TrackingFallbackMap(
        trip: widget.trip,
        routeInfo: _routeInfo,
        isDark: isDark,
      );
    }

    return Stack(
      children: [
        _buildGoogleMap(isDark, pickupLatLng, dropLatLng),
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
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngBounds(_routeInfo!.bounds, 80),
                  );
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
      ],
    );
  }

  Widget _buildGoogleMap(bool isDark, LatLng pickupLatLng, LatLng dropLatLng) {
    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: pickupLatLng,
          zoom: AppConfig.defaultMapZoom,
        ),
        markers: _buildMarkers(pickupLatLng, dropLatLng),
        polylines: _buildPolylines(),
        onMapCreated: (controller) {
          _mapController = controller;
          if (isDark) _setDarkStyle(controller);
        },
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        padding: const EdgeInsets.only(bottom: 280),
      );
    } catch (e) {
      debugPrint('GoogleMap failed to render: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mapLoadFailed = true);
      });
      return const SizedBox.shrink();
    }
  }

  Set<Marker> _buildMarkers(LatLng pickup, LatLng drop) {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickup,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow:
            InfoWindow(title: 'Pickup', snippet: widget.trip.pickup.address),
      ),
      Marker(
        markerId: const MarkerId('drop'),
        position: drop,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow:
            InfoWindow(title: 'Drop', snippet: widget.trip.destination.address),
      ),
    };

    if (_driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: widget.trip.driver?.name ?? 'Driver',
            snippet: widget.trip.driver?.vehicleNumber ?? '',
          ),
          anchor: const Offset(0.5, 0.5),
          zIndex: 3,
        ),
      );
    }

    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _userPosition!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
          zIndex: 2,
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_routeInfo == null || _routeInfo!.polylinePoints.isEmpty) return {};

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routeInfo!.polylinePoints,
        color: AppColors.primary,
        width: 5,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      Polyline(
        polylineId: const PolylineId('route_shadow'),
        points: _routeInfo!.polylinePoints,
        color: AppColors.primaryDark.withOpacity(0.2),
        width: 9,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Future<void> _setDarkStyle(GoogleMapController controller) async {
    const style = '''[
      {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]}
    ]''';
    // ignore: deprecated_member_use
    controller.setMapStyle(style);
  }
}

/// Fallback tracking map shown when Google Maps JS API is unavailable on web.
class _TrackingFallbackMap extends StatelessWidget {
  const _TrackingFallbackMap({
    required this.trip,
    required this.routeInfo,
    required this.isDark,
  });

  final RideTrip trip;
  final RouteInfo? routeInfo;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)]
              : const [Color(0xFFE2F4FD), Color(0xFFE8F9ED)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Grid
          CustomPaint(
            painter: _TrackingGridPainter(isDark: isDark),
          ),
          // Route line
          CustomPaint(
            painter: _TrackingRoutePainter(isDark: isDark),
          ),
          // Info badge
          if (routeInfo != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: _RouteInfoBadge(
                    routeInfo: routeInfo!,
                    trip: trip,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          // API key notice
          Positioned(
            left: 12,
            right: 12,
            bottom: 290,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.85),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.small,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add a Google Maps API key for live map tracking.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
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
}

class _TrackingGridPainter extends CustomPainter {
  const _TrackingGridPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrackingRoutePainter extends CustomPainter {
  const _TrackingRoutePainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.35)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final route = Path()
      ..moveTo(size.width * 0.18, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.55,
        size.width * 0.78,
        size.height * 0.30,
      );
    canvas.drawPath(route, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A floating badge showing route distance and ETA on the tracking map.
class _RouteInfoBadge extends StatelessWidget {
  const _RouteInfoBadge({
    required this.routeInfo,
    required this.trip,
    required this.isDark,
  });

  final RouteInfo routeInfo;
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
