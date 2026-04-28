import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/open_maps_service.dart';
import '../../ride/application/ride_controller.dart';

/// Holds the computed route between pickup and destination.
class RouteState {
  final RouteInfo? routeInfo;
  final bool isLoading;
  final String? error;

  const RouteState({
    this.routeInfo,
    this.isLoading = false,
    this.error,
  });

  RouteState copyWith({
    RouteInfo? routeInfo,
    bool? isLoading,
    String? error,
    bool clearRoute = false,
    bool clearError = false,
  }) {
    return RouteState(
      routeInfo: clearRoute ? null : (routeInfo ?? this.routeInfo),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controller that reacts to ride state changes and fetches routes.
class RouteController extends StateNotifier<RouteState> {
  RouteController(this._mapsService, this._ref) : super(const RouteState()) {
    // Listen to ride state changes
    _subscription = _ref.listen(rideControllerProvider, (previous, next) {
      final pickupChanged = previous?.pickup?.latitude != next.pickup?.latitude ||
          previous?.pickup?.longitude != next.pickup?.longitude;
      final destChanged =
          previous?.destination?.latitude != next.destination?.latitude ||
              previous?.destination?.longitude != next.destination?.longitude;

      if (pickupChanged || destChanged) {
        _fetchRouteIfReady(next);
      }
    });
  }

  final OpenMapsService _mapsService;
  final Ref _ref;
  ProviderSubscription<RideState>? _subscription;

  Future<void> _fetchRouteIfReady(RideState ride) async {
    if (ride.pickup == null || ride.destination == null) {
      state = state.copyWith(clearRoute: true);
      return;
    }

    final origin = LatLng(ride.pickup!.latitude, ride.pickup!.longitude);
    final destination =
        LatLng(ride.destination!.latitude, ride.destination!.longitude);

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final route = await _mapsService.getRoute(
        origin: origin,
        destination: destination,
      );
      if (mounted) {
        state = state.copyWith(
          routeInfo: route,
          isLoading: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch route: $e',
        );
      }
    }
  }

  /// Force refetch the route (e.g., after manual pickup change).
  Future<void> refreshRoute() async {
    final ride = _ref.read(rideControllerProvider);
    await _fetchRouteIfReady(ride);
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }
}

/// Provider for consuming route state throughout the booking flow.
final routeControllerProvider =
    StateNotifierProvider<RouteController, RouteState>((ref) {
  final mapsService = ref.watch(openMapsServiceProvider);
  return RouteController(mapsService, ref);
});
