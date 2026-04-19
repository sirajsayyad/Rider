import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/themes.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/buttons/buttons.dart';
import '../../ride/application/ride_controller.dart';
import '../../ride/domain/ride_models.dart';

/// A fullscreen map screen that lets the user drag the map to position
/// a center-pinned marker for pickup or drop-off selection.
class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.isPickup,
    this.initialPosition,
  });

  /// Whether this picker is for the pickup location (true) or drop (false).
  final bool isPickup;

  /// Optional starting position. Falls back to current GPS or default.
  final LatLng? initialPosition;

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _centerPosition = const LatLng(
    AppConfig.defaultLatitude,
    AppConfig.defaultLongitude,
  );
  String _resolvedAddress = 'Move the map to set location';
  bool _isResolving = false;
  bool _isMoving = false;
  bool _mapLoadFailed = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _centerPosition = widget.initialPosition!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveAddress(_centerPosition);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _centerPosition = position.target;
    if (!_isMoving) {
      setState(() => _isMoving = true);
    }
    _debounce?.cancel();
  }

  void _onCameraIdle() {
    setState(() => _isMoving = false);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _resolveAddress(_centerPosition);
    });
  }

  Future<void> _resolveAddress(LatLng position) async {
    setState(() => _isResolving = true);
    final locationService = ref.read(locationServiceProvider);
    try {
      final result = await locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _resolvedAddress = result.address ?? 'Unknown location';
          _isResolving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress = 'Unable to determine address';
          _isResolving = false;
        });
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);
    final current = await locationService.getCurrentLocation();
    if (current != null && mounted) {
      final pos = LatLng(current.latitude, current.longitude);
      _centerPosition = pos;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pos, zoom: AppConfig.defaultMapZoom),
        ),
      );
    }
  }

  void _confirmLocation() {
    final controller = ref.read(rideControllerProvider.notifier);
    final point = RidePoint(
      latitude: _centerPosition.latitude,
      longitude: _centerPosition.longitude,
      address: _resolvedAddress,
    );

    if (widget.isPickup) {
      controller.setPickup(point);
    } else {
      controller.setDestination(point);
      controller.addRecentSearch(point);
    }

    Navigator.of(context).pop(point);
  }

  Widget _buildMap(bool isDark) {
    if (_mapLoadFailed) {
      return _FallbackPickerMap(isDark: isDark);
    }

    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _centerPosition,
          zoom: AppConfig.defaultMapZoom,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          if (isDark) _setDarkStyle(controller);
        },
        onCameraMove: _onCameraMove,
        onCameraIdle: _onCameraIdle,
        myLocationEnabled: !kIsWeb,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
      );
    } catch (e) {
      debugPrint('GoogleMap failed to render: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mapLoadFailed = true);
      });
      return _FallbackPickerMap(isDark: isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerColor =
        widget.isPickup ? AppColors.pickupMarker : AppColors.dropMarker;

    return Scaffold(
      body: Stack(
        children: [
          // Map (real or fallback)
          _buildMap(isDark),

          // Center pin
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(0, _isMoving ? -12 : 0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: AppShadows.medium,
                    ),
                    child: Text(
                      widget.isPickup ? 'Pickup here' : 'Drop here',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    Icons.location_on,
                    size: 42,
                    color: markerColor,
                    shadows: [
                      Shadow(
                        color: markerColor.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isMoving ? 6 : 10,
                    height: _isMoving ? 3 : 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.black : Colors.white).withOpacity(0.85),
                    (isDark ? Colors.black : Colors.white).withOpacity(0),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      CircularIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          widget.isPickup
                              ? 'Set Pickup Location'
                              : 'Set Drop Location',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      CircularIconButton(
                        icon: Icons.gps_fixed_rounded,
                        onPressed: _goToCurrentLocation,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom confirmation panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                boxShadow: AppShadows.large,
              ),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: markerColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          widget.isPickup
                              ? Icons.my_location_rounded
                              : Icons.location_on_outlined,
                          color: markerColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isPickup
                                  ? 'Pickup Location'
                                  : 'Drop Location',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            _isResolving
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: markerColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Resolving address...',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  )
                                : Text(
                                    _resolvedAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    text: widget.isPickup
                        ? 'Confirm Pickup'
                        : 'Confirm Drop Location',
                    icon: widget.isPickup
                        ? Icons.check_circle_outline
                        : Icons.pin_drop_outlined,
                    onPressed: _isResolving ? null : _confirmLocation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

/// Fallback map for the location picker when Google Maps JS API is unavailable.
class _FallbackPickerMap extends StatelessWidget {
  const _FallbackPickerMap({required this.isDark});

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
      child: CustomPaint(
        painter: _PickerGridPainter(isDark: isDark),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.85),
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadows.small,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Add a Google Maps API key for interactive maps.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerGridPainter extends CustomPainter {
  const _PickerGridPainter({required this.isDark});
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
  bool shouldRepaint(covariant _PickerGridPainter old) => old.isDark != isDark;
}
