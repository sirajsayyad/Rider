import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_service.dart';
import 'network_service.dart';
import '../../features/passenger/ride/domain/ride_models.dart';
import '../../features/passenger/ride/data/mock_ride_api.dart';

/// Preloaded data available for instant display
class PreloadedData {
  final List<NearbyDriverPreview> nearbyDrivers;
  final Map<String, List<RideTypeQuote>> savedPlaceQuotes;
  final bool isPreloading;
  final DateTime? lastPreloadedAt;

  const PreloadedData({
    this.nearbyDrivers = const [],
    this.savedPlaceQuotes = const {},
    this.isPreloading = false,
    this.lastPreloadedAt,
  });

  PreloadedData copyWith({
    List<NearbyDriverPreview>? nearbyDrivers,
    Map<String, List<RideTypeQuote>>? savedPlaceQuotes,
    bool? isPreloading,
    DateTime? lastPreloadedAt,
  }) {
    return PreloadedData(
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      savedPlaceQuotes: savedPlaceQuotes ?? this.savedPlaceQuotes,
      isPreloading: isPreloading ?? this.isPreloading,
      lastPreloadedAt: lastPreloadedAt ?? this.lastPreloadedAt,
    );
  }

  /// Whether preloaded data is fresh (< 2 minutes old)
  bool get isFresh {
    if (lastPreloadedAt == null) return false;
    return DateTime.now().difference(lastPreloadedAt!).inMinutes < 2;
  }
}

/// Smart preloading service
///   • Preloads nearby drivers when app starts / resumes
///   • Pre-fetches fare quotes for saved places (Home, Work)
///   • Caches data for instant display on the booking screen
class PreloadService extends StateNotifier<PreloadedData> {
  PreloadService({
    required this.api,
    required this.cacheService,
    required this.networkNotifier,
  }) : super(const PreloadedData());

  final MockRideApi api;
  final CacheService cacheService;
  final NetworkService networkNotifier;
  Timer? _refreshTimer;

  /// Run full preload cycle
  Future<void> preload({
    RidePoint? currentLocation,
    List<SavedPlace> savedPlaces = const [],
  }) async {
    if (!networkNotifier.state.isOnline) {
      _restoreFromCache();
      return;
    }

    state = state.copyWith(isPreloading: true);

    try {
      // 1. Preload nearby drivers (default type)
      final drivers = api.nearestDrivers(RideType.economy);

      // 2. Pre-fetch quotes for each saved place
      final quotesMap = <String, List<RideTypeQuote>>{};
      if (currentLocation != null) {
        for (final place in savedPlaces) {
          final distanceKm = _roughDistance(currentLocation, place.point);
          if (distanceKm > 0.5 && distanceKm < 100) {
            final quotes = await api.fetchQuotes(distanceKm: distanceKm);
            quotesMap[place.label] = quotes;

            // Cache for offline / next fast load
            await cacheService.put(
              CacheBoxes.preloadCache,
              'quotes_${place.label}',
              quotes.map((q) => {
                    'type': q.type.index,
                    'label': q.label,
                    'fare': q.fare,
                    'etaMinutes': q.etaMinutes,
                  }).toList(),
              ttl: const Duration(minutes: 5),
            );
          }
        }
      }

      // 3. Cache driver data
      await cacheService.put(
        CacheBoxes.preloadCache,
        'nearby_drivers',
        drivers.map((d) => {
              'id': d.id,
              'name': d.name,
              'vehicleModel': d.vehicleModel,
              'rating': d.rating,
              'distanceKm': d.distanceKm,
              'etaMinutes': d.etaMinutes,
              'acceptanceRate': d.acceptanceRate,
            }).toList(),
        ttl: const Duration(minutes: 2),
      );

      state = state.copyWith(
        nearbyDrivers: drivers,
        savedPlaceQuotes: quotesMap,
        isPreloading: false,
        lastPreloadedAt: DateTime.now(),
      );

      debugPrint(
        '[PreloadService] preloaded ${drivers.length} drivers, '
        '${quotesMap.length} saved-place quotes',
      );
    } catch (e) {
      state = state.copyWith(isPreloading: false);
      debugPrint('[PreloadService] preload error: $e');
    }
  }

  /// Start periodic background refresh (every 90 seconds)
  void startPeriodicRefresh({
    RidePoint? currentLocation,
    List<SavedPlace> savedPlaces = const [],
  }) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 90),
      (_) => preload(currentLocation: currentLocation, savedPlaces: savedPlaces),
    );
  }

  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Restore preloaded data from cache (for instant display)
  void _restoreFromCache() {
    final cachedDrivers = cacheService.get<List<dynamic>>(
      CacheBoxes.preloadCache,
      'nearby_drivers',
    );

    if (cachedDrivers != null) {
      final drivers = cachedDrivers.map((d) {
        final m = Map<String, dynamic>.from(d as Map);
        return NearbyDriverPreview(
          id: m['id'] as String,
          name: m['name'] as String,
          vehicleModel: m['vehicleModel'] as String,
          rating: (m['rating'] as num).toDouble(),
          distanceKm: (m['distanceKm'] as num).toDouble(),
          etaMinutes: m['etaMinutes'] as int,
          acceptanceRate: (m['acceptanceRate'] as num).toDouble(),
        );
      }).toList();

      state = state.copyWith(nearbyDrivers: drivers);
    }
  }

  /// Get pre-cached quotes for a saved-place label
  List<RideTypeQuote>? getQuotesForPlace(String label) {
    return state.savedPlaceQuotes[label];
  }

  double _roughDistance(RidePoint from, RidePoint to) {
    final latDiff = (to.latitude - from.latitude).abs();
    final lngDiff = (to.longitude - from.longitude).abs();
    return (latDiff * latDiff + lngDiff * lngDiff) * 111;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final preloadServiceProvider =
    StateNotifierProvider<PreloadService, PreloadedData>((ref) {
  final api = MockRideApi();
  return PreloadService(
    api: api,
    cacheService: ref.watch(cacheServiceProvider),
    networkNotifier: ref.watch(networkServiceProvider.notifier),
  );
});
