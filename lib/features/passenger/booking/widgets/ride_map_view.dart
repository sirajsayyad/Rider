import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/services/google_maps_service.dart';

/// A reusable interactive Google Maps widget that manages:
/// - Pickup and drop markers
/// - Route polyline drawing
/// - Camera animation to fit route bounds
/// - Live location marker with smooth animation
/// - Graceful fallback on Web when Maps JS API is unavailable
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
  final RouteInfo? routeInfo;
  final LatLng? driverLatLng;
  final bool isPickupDraggable;
  final ValueChanged<LatLng>? onPickupDragEnd;
  final ValueChanged<GoogleMapController>? onMapCreated;
  final ValueChanged<LatLng>? onMapTap;
  final bool showMyLocationButton;
  final double? initialZoom;
  final EdgeInsets padding;

  @override
  State<RideMapView> createState() => RideMapViewState();
}

class RideMapViewState extends State<RideMapView>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _animatedDriverPosition;
  AnimationController? _markerAnimController;
  Animation<double>? _animLat;
  Animation<double>? _animLng;
  bool _mapLoadFailed = false;

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

    _animLat = Tween<double>(begin: from.latitude, end: to.latitude)
        .animate(CurvedAnimation(
      parent: _markerAnimController!,
      curve: Curves.easeInOutCubic,
    ));
    _animLng = Tween<double>(begin: from.longitude, end: to.longitude)
        .animate(CurvedAnimation(
      parent: _markerAnimController!,
      curve: Curves.easeInOutCubic,
    ));

    _markerAnimController!.addListener(() {
      setState(() {
        _animatedDriverPosition = LatLng(_animLat!.value, _animLng!.value);
      });
    });
    _markerAnimController!.forward();
  }

  void _fitBounds(LatLngBounds bounds) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  /// Public method: caller can ask to recenter on a specific point.
  void animateToPosition(LatLng position, {double? zoom}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: zoom ?? AppConfig.defaultMapZoom,
        ),
      ),
    );
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
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // If map loading previously failed (e.g. missing API key on web), show fallback
    if (_mapLoadFailed) {
      return _FallbackMapView(
        pickupLatLng: widget.pickupLatLng,
        dropLatLng: widget.dropLatLng,
        routeInfo: widget.routeInfo,
        isDark: isDark,
      );
    }

    final initialTarget = widget.pickupLatLng ??
        const LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude);

    // Wrap in an ErrorWidget.builder–safe zone for web
    return _SafeGoogleMap(
      onError: () {
        if (mounted) {
          setState(() => _mapLoadFailed = true);
        }
      },
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialTarget,
          zoom: widget.initialZoom ?? AppConfig.defaultMapZoom,
        ),
        markers: _buildMarkers(),
        polylines: _buildPolylines(isDark),
        onMapCreated: (controller) {
          _mapController = controller;
          widget.onMapCreated?.call(controller);
          if (isDark) {
            _setDarkMapStyle(controller);
          }
          // If we already have a route, fit to it
          if (widget.routeInfo != null) {
            Future.delayed(const Duration(milliseconds: 400), () {
              _fitBounds(widget.routeInfo!.bounds);
            });
          }
        },
        onTap: widget.onMapTap,
        myLocationEnabled: !kIsWeb && widget.showMyLocationButton,
        myLocationButtonEnabled: !kIsWeb && widget.showMyLocationButton,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        padding: widget.padding,
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // Pickup marker
    if (widget.pickupLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          draggable: widget.isPickupDraggable,
          onDragEnd: widget.onPickupDragEnd,
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }

    // Drop marker
    if (widget.dropLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: widget.dropLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Drop-off'),
        ),
      );
    }

    // Driver marker (animated)
    final driverPos = _animatedDriverPosition ?? widget.driverLatLng;
    if (driverPos != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(title: 'Driver'),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(bool isDark) {
    if (widget.routeInfo == null || widget.routeInfo!.polylinePoints.isEmpty) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: widget.routeInfo!.polylinePoints,
        color: AppColors.primary,
        width: 5,
        patterns: const [],
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
      // Shadow polyline for depth effect
      Polyline(
        polylineId: const PolylineId('route_shadow'),
        points: widget.routeInfo!.polylinePoints,
        color: AppColors.primaryDark.withOpacity(0.25),
        width: 9,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Future<void> _setDarkMapStyle(GoogleMapController controller) async {
    const style = '''[
      {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
      {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
      {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
      {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
      {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
      {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
      {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6b9a76"}]},
      {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
      {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
      {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9ca5b3"}]},
      {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#746855"}]},
      {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
      {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f3d19c"}]},
      {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
      {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#d59563"}]},
      {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
      {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#515c6d"}]}
    ]''';
    // ignore: deprecated_member_use
    controller.setMapStyle(style);
  }
}

/// Catches errors from the GoogleMap widget (e.g. missing API key on web)
/// and triggers the [onError] callback so the parent can show a fallback.
class _SafeGoogleMap extends StatefulWidget {
  const _SafeGoogleMap({required this.child, required this.onError});

  final Widget child;
  final VoidCallback onError;

  @override
  State<_SafeGoogleMap> createState() => _SafeGoogleMapState();
}

class _SafeGoogleMapState extends State<_SafeGoogleMap> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _FallbackMapView(isDark: Theme.of(context).brightness == Brightness.dark);
    }

    return _SafeGoogleMapErrorBoundary(
      onError: () {
        if (mounted) {
          setState(() => _hasError = true);
          widget.onError();
        }
      },
      child: widget.child,
    );
  }
}

/// Uses a custom ErrorWidget builder during the scope of this widget
/// to catch framework-level errors from GoogleMap on web.
class _SafeGoogleMapErrorBoundary extends StatelessWidget {
  const _SafeGoogleMapErrorBoundary({
    required this.child,
    required this.onError,
  });

  final Widget child;
  final VoidCallback onError;

  @override
  Widget build(BuildContext context) {
    // We use ErrorWidget.builder to catch framework-level errors
    final originalErrorBuilder = ErrorWidget.builder;

    return Builder(
      builder: (context) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          // Schedule the error callback after the frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onError();
          });
          // Restore original builder
          ErrorWidget.builder = originalErrorBuilder;
          return const SizedBox.shrink();
        };

        try {
          final result = child;
          // If building succeeds, eventually restore the builder
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ErrorWidget.builder = originalErrorBuilder;
          });
          return result;
        } catch (_) {
          ErrorWidget.builder = originalErrorBuilder;
          onError();
          return const SizedBox.shrink();
        }
      },
    );
  }
}

/// A beautiful fallback "map" widget shown when Google Maps JS API is not available.
/// Renders a styled card with a map-like gradient, route visualization, and markers.
class _FallbackMapView extends StatelessWidget {
  const _FallbackMapView({
    this.pickupLatLng,
    this.dropLatLng,
    this.routeInfo,
    required this.isDark,
  });

  final LatLng? pickupLatLng;
  final LatLng? dropLatLng;
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
              ? const [Color(0xFF0B2232), Color(0xFF123549), Color(0xFF1A4A5E)]
              : const [Color(0xFFDDF2EB), Color(0xFFD9ECFF), Color(0xFFE8F4FD)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Grid pattern
          CustomPaint(
            painter: _GridPainter(isDark: isDark),
          ),
          // Route line
          if (pickupLatLng != null && dropLatLng != null)
            CustomPaint(
              painter: _RoutePainter(isDark: isDark),
            ),
          // Pickup marker indicator
          if (pickupLatLng != null)
            const Positioned(
              left: 60,
              bottom: 120,
              child: _FallbackMarker(
                color: AppColors.pickupMarker,
                label: 'Pickup',
                icon: Icons.my_location_rounded,
              ),
            ),
          // Drop marker indicator
          if (dropLatLng != null)
            const Positioned(
              right: 60,
              top: 80,
              child: _FallbackMarker(
                color: AppColors.dropMarker,
                label: 'Drop',
                icon: Icons.location_on_rounded,
              ),
            ),
          // Info banner
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.85),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.small,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Map preview — add a Google Maps API key for live maps.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Route info overlay
          if (routeInfo != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straighten_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      routeInfo!.distanceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.schedule_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      routeInfo!.durationText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
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

class _FallbackMarker extends StatelessWidget {
  const _FallbackMarker({
    required this.color,
    required this.label,
    required this.icon,
  });

  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        Icon(icon, color: color, size: 32),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.isDark != isDark;
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.42)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.50,
        size.height * 0.30,
        size.width * 0.80,
        size.height * 0.35,
      );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.isDark != isDark;
}
