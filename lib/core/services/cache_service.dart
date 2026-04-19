import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Keys for Hive boxes
class CacheBoxes {
  static const String rideHistory = 'ride_history';
  static const String userPreferences = 'user_preferences';
  static const String savedPlaces = 'saved_places';
  static const String preloadCache = 'preload_cache';
  static const String routeFrequency = 'route_frequency';
  static const String recentSearches = 'recent_searches';
  static const String offlineQueue = 'offline_queue';
}

/// Individual cache entry with TTL support
class CacheEntry {
  final String data;
  final int createdAtMs;
  final int ttlMs;

  CacheEntry({
    required this.data,
    required this.createdAtMs,
    required this.ttlMs,
  });

  bool get isExpired {
    if (ttlMs <= 0) return false; // 0 = never expires
    return DateTime.now().millisecondsSinceEpoch > createdAtMs + ttlMs;
  }

  Map<String, dynamic> toMap() => {
        'data': data,
        'createdAtMs': createdAtMs,
        'ttlMs': ttlMs,
      };

  factory CacheEntry.fromMap(Map<dynamic, dynamic> map) {
    return CacheEntry(
      data: map['data'] as String,
      createdAtMs: map['createdAtMs'] as int,
      ttlMs: map['ttlMs'] as int,
    );
  }
}

/// Hive-backed cache service with TTL, box management, and typed helpers
class CacheService {
  bool _initialized = false;

  /// Initialize Hive and open all required boxes
  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox(CacheBoxes.rideHistory),
      Hive.openBox(CacheBoxes.userPreferences),
      Hive.openBox(CacheBoxes.savedPlaces),
      Hive.openBox(CacheBoxes.preloadCache),
      Hive.openBox(CacheBoxes.routeFrequency),
      Hive.openBox(CacheBoxes.recentSearches),
      Hive.openBox(CacheBoxes.offlineQueue),
    ]);

    _initialized = true;
    debugPrint('[CacheService] initialized — ${Hive.isBoxOpen(CacheBoxes.rideHistory)}');
  }

  // ─── Generic cache operations ─────────────────────────────────────────────

  /// Put a JSON-serializable value with optional TTL (default 1 hour)
  Future<void> put(
    String boxName,
    String key,
    dynamic value, {
    Duration ttl = const Duration(hours: 1),
  }) async {
    final box = Hive.box(boxName);
    final entry = CacheEntry(
      data: jsonEncode(value),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ttlMs: ttl.inMilliseconds,
    );
    await box.put(key, entry.toMap());
  }

  /// Get a cached value, returns null if expired or missing
  T? get<T>(String boxName, String key) {
    final box = Hive.box(boxName);
    final raw = box.get(key);
    if (raw == null) return null;

    final entry = CacheEntry.fromMap(raw as Map<dynamic, dynamic>);
    if (entry.isExpired) {
      box.delete(key); // auto-cleanup
      return null;
    }
    return jsonDecode(entry.data) as T;
  }

  /// Check if a non-expired cache entry exists
  bool has(String boxName, String key) {
    return get<dynamic>(boxName, key) != null;
  }

  /// Remove a specific key
  Future<void> remove(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }

  /// Clear an entire box
  Future<void> clearBox(String boxName) async {
    final box = Hive.box(boxName);
    await box.clear();
  }

  /// Get all entries in a box (excluding expired ones)
  Map<String, dynamic> getAll(String boxName) {
    final box = Hive.box(boxName);
    final result = <String, dynamic>{};
    for (final key in box.keys) {
      final value = get<dynamic>(boxName, key as String);
      if (value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  // ─── Ride-history helpers ─────────────────────────────────────────────────

  Future<void> cacheRideHistory(List<Map<String, dynamic>> rides) async {
    await put(
      CacheBoxes.rideHistory,
      'all',
      rides,
      ttl: const Duration(days: 7),
    );
  }

  List<Map<String, dynamic>> getCachedRideHistory() {
    final data = get<List<dynamic>>(CacheBoxes.rideHistory, 'all');
    if (data == null) return [];
    return data.cast<Map<String, dynamic>>();
  }

  // ─── User-preferences helpers ─────────────────────────────────────────────

  Future<void> cacheUserPreferences(Map<String, dynamic> prefs) async {
    await put(
      CacheBoxes.userPreferences,
      'prefs',
      prefs,
      ttl: Duration.zero, // never expires
    );
  }

  Map<String, dynamic>? getCachedUserPreferences() {
    return get<Map<String, dynamic>>(CacheBoxes.userPreferences, 'prefs');
  }

  // ─── Saved-places helpers ─────────────────────────────────────────────────

  Future<void> cacheSavedPlaces(List<Map<String, dynamic>> places) async {
    await put(
      CacheBoxes.savedPlaces,
      'all',
      places,
      ttl: Duration.zero, // never expires
    );
  }

  List<Map<String, dynamic>> getCachedSavedPlaces() {
    final data = get<List<dynamic>>(CacheBoxes.savedPlaces, 'all');
    if (data == null) return [];
    return data.cast<Map<String, dynamic>>();
  }

  // ─── Recent searches helpers ──────────────────────────────────────────────

  Future<void> cacheRecentSearches(List<Map<String, dynamic>> searches) async {
    await put(
      CacheBoxes.recentSearches,
      'all',
      searches,
      ttl: const Duration(days: 30),
    );
  }

  List<Map<String, dynamic>> getCachedRecentSearches() {
    final data = get<List<dynamic>>(CacheBoxes.recentSearches, 'all');
    if (data == null) return [];
    return data.cast<Map<String, dynamic>>();
  }

  // ─── Route-frequency helpers ──────────────────────────────────────────────

  Future<void> incrementRouteFrequency(String routeKey) async {
    final box = Hive.box(CacheBoxes.routeFrequency);
    final existing = box.get(routeKey);
    if (existing == null) {
      await box.put(routeKey, {
        'count': 1,
        'lastUsedMs': DateTime.now().millisecondsSinceEpoch,
        'timestamps': [DateTime.now().millisecondsSinceEpoch],
      });
    } else {
      final map = Map<String, dynamic>.from(existing as Map);
      final timestamps = List<int>.from(map['timestamps'] as List? ?? []);
      timestamps.add(DateTime.now().millisecondsSinceEpoch);
      // Keep last 50 timestamps
      if (timestamps.length > 50) {
        timestamps.removeRange(0, timestamps.length - 50);
      }
      await box.put(routeKey, {
        'count': (map['count'] as int? ?? 0) + 1,
        'lastUsedMs': DateTime.now().millisecondsSinceEpoch,
        'timestamps': timestamps,
      });
    }
  }

  Map<String, Map<String, dynamic>> getAllRouteFrequencies() {
    final box = Hive.box(CacheBoxes.routeFrequency);
    final result = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        result[key as String] = Map<String, dynamic>.from(raw as Map);
      }
    }
    return result;
  }

  // ─── Offline queue helpers ────────────────────────────────────────────────

  Future<void> addToOfflineQueue(Map<String, dynamic> action) async {
    final box = Hive.box(CacheBoxes.offlineQueue);
    await box.add(action);
  }

  List<Map<String, dynamic>> getOfflineQueue() {
    final box = Hive.box(CacheBoxes.offlineQueue);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> clearOfflineQueue() async {
    final box = Hive.box(CacheBoxes.offlineQueue);
    await box.clear();
  }

  // ─── Cleanup ──────────────────────────────────────────────────────────────

  /// Purge all expired entries across every box
  Future<void> purgeExpired() async {
    for (final boxName in [
      CacheBoxes.rideHistory,
      CacheBoxes.preloadCache,
      CacheBoxes.recentSearches,
    ]) {
      final box = Hive.box(boxName);
      final keysToRemove = <dynamic>[];
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw is Map) {
          try {
            final entry = CacheEntry.fromMap(raw);
            if (entry.isExpired) keysToRemove.add(key);
          } catch (_) {}
        }
      }
      await box.deleteAll(keysToRemove);
    }
    debugPrint('[CacheService] expired entries purged');
  }

  /// Clear everything
  Future<void> clearAll() async {
    for (final boxName in [
      CacheBoxes.rideHistory,
      CacheBoxes.userPreferences,
      CacheBoxes.savedPlaces,
      CacheBoxes.preloadCache,
      CacheBoxes.routeFrequency,
      CacheBoxes.recentSearches,
      CacheBoxes.offlineQueue,
    ]) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      }
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});
