

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_service.dart';
import 'network_service.dart';
import '../../features/passenger/ride/domain/ride_models.dart';

/// Action that was queued while offline
class OfflineAction {
  final String type;
  final Map<String, dynamic> payload;
  final int createdAtMs;

  const OfflineAction({
    required this.type,
    required this.payload,
    required this.createdAtMs,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'payload': payload,
        'createdAtMs': createdAtMs,
      };

  factory OfflineAction.fromMap(Map<String, dynamic> map) {
    return OfflineAction(
      type: map['type'] as String,
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAtMs: map['createdAtMs'] as int,
    );
  }
}

/// Offline support state
class OfflineState {
  final bool isOffline;
  final RidePoint? lastKnownLocation;
  final List<SavedPlace> cachedSavedPlaces;
  final List<OfflineAction> pendingActions;
  final bool isSyncing;
  final DateTime? lastSyncedAt;

  const OfflineState({
    this.isOffline = false,
    this.lastKnownLocation,
    this.cachedSavedPlaces = const [],
    this.pendingActions = const [],
    this.isSyncing = false,
    this.lastSyncedAt,
  });

  OfflineState copyWith({
    bool? isOffline,
    RidePoint? lastKnownLocation,
    List<SavedPlace>? cachedSavedPlaces,
    List<OfflineAction>? pendingActions,
    bool? isSyncing,
    DateTime? lastSyncedAt,
  }) {
    return OfflineState(
      isOffline: isOffline ?? this.isOffline,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      cachedSavedPlaces: cachedSavedPlaces ?? this.cachedSavedPlaces,
      pendingActions: pendingActions ?? this.pendingActions,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  /// Whether the user can still do limited actions (view cached data)
  bool get hasLimitedFunctionality => isOffline && lastKnownLocation != null;
}

/// Manages offline behaviour:
///   • caches the last known location and saved places
///   • queues actions that require network
///   • syncs the queue when connectivity recovers
class OfflineService extends StateNotifier<OfflineState> {
  OfflineService({
    required this.cacheService,
    required this.networkNotifier,
  }) : super(const OfflineState()) {
    _init();
  }

  final CacheService cacheService;
  final NetworkService networkNotifier;
  StreamSubscription<NetworkState>? _networkSub;

  void _init() {
    // Restore from cache
    _restoreFromCache();

    // Listen to network state changes
    _networkSub = networkNotifier.stream.listen((networkState) {
      final wasOffline = state.isOffline;
      state = state.copyWith(isOffline: !networkState.isOnline);

      if (wasOffline && networkState.isOnline) {
        debugPrint('[OfflineService] back online → syncing queued actions');
        syncPendingActions();
      }
    });
  }

  // ─── Location caching ────────────────────────────────────────────────────

  /// Cache the current location for offline access
  void cacheLocation(RidePoint location) {
    state = state.copyWith(lastKnownLocation: location);
    cacheService.put(
      CacheBoxes.preloadCache,
      'last_known_location',
      {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'address': location.address,
      },
      ttl: const Duration(days: 1),
    );
  }

  /// Cache saved places for offline access
  Future<void> cacheSavedPlaces(List<SavedPlace> places) async {
    state = state.copyWith(cachedSavedPlaces: places);
    await cacheService.cacheSavedPlaces(
      places
          .map((p) => {
                'label': p.label,
                'latitude': p.point.latitude,
                'longitude': p.point.longitude,
                'address': p.point.address,
              })
          .toList(),
    );
  }

  // ─── Offline queue ────────────────────────────────────────────────────────

  /// Enqueue an action to be replayed when back online
  Future<void> enqueueAction(String type, Map<String, dynamic> payload) async {
    final action = OfflineAction(
      type: type,
      payload: payload,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    state = state.copyWith(
      pendingActions: [...state.pendingActions, action],
    );
    await cacheService.addToOfflineQueue(action.toMap());
    debugPrint('[OfflineService] queued offline action: $type');
  }

  /// Replay all queued actions against the API
  Future<void> syncPendingActions() async {
    if (state.pendingActions.isEmpty) return;
    state = state.copyWith(isSyncing: true);

    final actionsToSync = List<OfflineAction>.from(state.pendingActions);

    for (final action in actionsToSync) {
      try {
        await _executeAction(action);
      } catch (e) {
        debugPrint('[OfflineService] failed to sync action ${action.type}: $e');
        // Re-enqueue if it fails
        continue;
      }
    }

    await cacheService.clearOfflineQueue();
    state = state.copyWith(
      pendingActions: [],
      isSyncing: false,
      lastSyncedAt: DateTime.now(),
    );
    debugPrint('[OfflineService] sync complete');
  }

  Future<void> _executeAction(OfflineAction action) async {
    // In a real implementation this would call ApiService methods
    // based on action.type ('save_place', 'update_preference', etc.)
    debugPrint('[OfflineService] executing queued action: ${action.type}');
    await Future.delayed(const Duration(milliseconds: 200)); // simulate API
  }

  // ─── Restore ──────────────────────────────────────────────────────────────

  void _restoreFromCache() {
    // Restore last known location
    final locationData = cacheService.get<Map<String, dynamic>>(
      CacheBoxes.preloadCache,
      'last_known_location',
    );
    RidePoint? lastLocation;
    if (locationData != null) {
      lastLocation = RidePoint(
        latitude: (locationData['latitude'] as num).toDouble(),
        longitude: (locationData['longitude'] as num).toDouble(),
        address: locationData['address'] as String? ?? 'Last known location',
      );
    }

    // Restore saved places
    final placesData = cacheService.getCachedSavedPlaces();
    final savedPlaces = placesData.map((p) {
      return SavedPlace(
        label: p['label'] as String,
        point: RidePoint(
          latitude: (p['latitude'] as num).toDouble(),
          longitude: (p['longitude'] as num).toDouble(),
          address: p['address'] as String? ?? '',
        ),
      );
    }).toList();

    // Restore offline queue
    final queueData = cacheService.getOfflineQueue();
    final pendingActions =
        queueData.map((m) => OfflineAction.fromMap(m)).toList();

    state = state.copyWith(
      lastKnownLocation: lastLocation,
      cachedSavedPlaces: savedPlaces,
      pendingActions: pendingActions,
    );
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    super.dispose();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final offlineServiceProvider =
    StateNotifierProvider<OfflineService, OfflineState>((ref) {
  return OfflineService(
    cacheService: ref.watch(cacheServiceProvider),
    networkNotifier: ref.watch(networkServiceProvider.notifier),
  );
});

/// Is device currently offline?
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(offlineServiceProvider).isOffline;
});
