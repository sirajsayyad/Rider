import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/services/open_maps_service.dart' as osm;

/// A reusable interactive OpenStreetMap widget that manages:
/// - Pickup and drop markers
/// - Route polyline drawing
/// - Camera animation to fit route bounds
/// - Live location marker with smooth animation
/// - Works everywhere — no API key required!
class RideMapView extends StatefulWidget {
  const RideMapView({
    super.key,
    this.pickupLatLng,
    this.dropLatLng,
    this.routeInfo,
    this.driverLatLng,
    this.isPickupDraggable = false,
    this.onPickupDragEnd,
    this.onMapCreated,
    this.onMapTap,
    this.showMyLocationButton = true,
    this.initialZoom,
    this.padding = EdgeInsets.zero,
  });

  final LatLng? pickupLatLng;
  final LatLng? dropLatLng;
  final osm.RouteInfo? routeInfo;
  final LatLng? driverLatLng;
  final bool isPickupDraggable;
  final ValueChanged<LatLng>? onPickupDragEnd;
  final ValueChanged<MapController>? onMapCreated;
  final ValueChanged<LatLng>? onMapTap;
  final bool showMyLocationButton;
  final double? initialZoom;
  final EdgeInsets padding;

  @override
  State<RideMapView> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  LatLng? _animatedDriverPosition;
  AnimationController? _markerAnimController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animatedDriverPosition = widget.driverLatLng;
  }

  @override
  void didUpdateWidget(covariant RideMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate driver marker smoothly
    if (widget.driverLatLng != null &&
        oldWidget.driverLatLng != null &&
        widget.driverLatLng != oldWidget.driverLatLng) {
      _animateDriverMarker(oldWidget.driverLatLng!, widget.driverLatLng!);
    } else if (widget.driverLatLng != null && oldWidget.driverLatLng == null) {
      _animatedDriverPosition = widget.driverLatLng;
    }

    // Update camera to fit route bounds if a new route arrives
    if (widget.routeInfo != null && widget.routeInfo != oldWidget.routeInfo) {
      _fitBounds(widget.routeInfo!.bounds);
    }
  }

  void _animateDriverMarker(LatLng from, LatLng to) {
    _markerAnimController?.dispose();
    _markerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    final latAnim = Tween<double>(begin: from.latitude, end: to.latitude)
        .animate(CurvedAnimation(
      parent: _markerAnimController!,
      curve: Curves.easeInOutCubic,
    ));
    final lngAnim = Tween<double>(begin: from.longitude, end: to.longitude)
        .animate(CurvedAnimation(
      parent: _markerAnimController!,
      curve: Curves.easeInOutCubic,
    ));

    _markerAnimController!.addListener(() {
      setState(() {
        _animatedDriverPosition = LatLng(latAnim.value, lngAnim.value);
      });
    });
    _markerAnimController!.forward();
  }

  void _fitBounds(osm.LatLngBounds bounds) {
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(bounds.southwest, bounds.northeast),
          padding: const EdgeInsets.all(80),
        ),
      );
    } catch (_) {
      // Map controller might not be ready yet
    }
  }

  /// Public method: caller can ask to recenter on a specific point.
  void animateToPosition(LatLng position, {double? zoom}) {
    _mapController.move(position, zoom ?? AppConfig.defaultMapZoom);
  }

  /// Public method: fit the current route bounds.
  void fitRouteBounds() {
    if (widget.routeInfo != null) {
      _fitBounds(widget.routeInfo!.bounds);
    }
  }

  @override
  void dispose() {
    _markerAnimController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final initialTarget = widget.pickupLatLng ??
        const LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialTarget,
        initialZoom: widget.initialZoom ?? AppConfig.defaultMapZoom,
        onTap: (tapPosition, point) {
          widget.onMapTap?.call(point);
        },
        onMapReady: () {
          widget.onMapCreated?.call(_mapController);
          // If we already have a route, fit to it
          if (widget.routeInfo != null) {
            Future.delayed(const Duration(milliseconds: 400), () {
              _fitBounds(widget.routeInfo!.bounds);
            });
          }
        },
      ),
      children: [
        // OpenStreetMap tile layer — free, no API key
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
          userAgentPackageName: 'com.rideconnect.app',
          maxZoom: 19,
        ),
        // Route polyline
        if (widget.routeInfo != null &&
            widget.routeInfo!.polylinePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Shadow polyline for depth effect
              Polyline(
                points: widget.routeInfo!.polylinePoints,
                strokeWidth: 9,
                color: AppColors.primaryDark.withOpacity(0.25),
              ),
              // Main route polyline
              Polyline(
                points: widget.routeInfo!.polylinePoints,
                strokeWidth: 5,
                color: AppColors.primary,
              ),
            ],
          ),
        // Markers
        MarkerLayer(
          markers: _buildMarkers(),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Pickup marker
    if (widget.pickupLatLng != null) {
      markers.add(
        Marker(
          point: widget.pickupLatLng!,
          width: 44,
          height: 44,
          child: const _MapPin(
            color: AppColors.pickupMarker,
            icon: Icons.my_location_rounded,
          ),
        ),
      );
    }

    // Drop marker
    if (widget.dropLatLng != null) {
      markers.add(
        Marker(
          point: widget.dropLatLng!,
          width: 44,
          height: 44,
          child: const _MapPin(
            color: AppColors.dropMarker,
            icon: Icons.location_on_rounded,
          ),
        ),
      );
    }

    // Driver marker (animated)
    final driverPos = _animatedDriverPosition ?? widget.driverLatLng;
    if (driverPos != null) {
      markers.add(
        Marker(
          point: driverPos,
          width: 44,
          height: 44,
          child: const _MapPin(
            color: Colors.deepPurple,
            icon: Icons.local_taxi_rounded,
          ),
        ),
      );
    }

    return markers;
  }
}

/// A beautiful custom map marker pin widget.
class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}
