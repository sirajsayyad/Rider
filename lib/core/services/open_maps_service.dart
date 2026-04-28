import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// A place prediction from Nominatim search.
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

/// Route data returned by the OSRM routing API.
class RouteInfo {
  final List<LatLng> polylinePoints;
  final double distanceKm;
  final int durationMinutes;
  final String distanceText;
  final String durationText;
  final LatLngBounds bounds;

  const RouteInfo({
    required this.polylinePoints,
    required this.distanceKm,
    required this.durationMinutes,
    required this.distanceText,
    required this.durationText,
    required this.bounds,
  });
}

/// Bounding box for map camera fitting.
class LatLngBounds {
  final LatLng southwest;
  final LatLng northeast;

  const LatLngBounds({required this.southwest, required this.northeast});
}

/// Geocoded place details.
class PlaceDetails {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  const PlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });
}

/// Free, open-source map service using:
/// - **Nominatim** for geocoding and place search (OpenStreetMap)
/// - **OSRM** for routing directions
///
/// No API key required!
class OpenMapsService {
  OpenMapsService() : _dio = Dio();

  final Dio _dio;

  // Always available — no API key needed
  bool get hasApiKey => true;

  // ─── Nominatim endpoints ──────────────────────────────────────────────
  static const _nominatimSearchUrl =
      'https://nominatim.openstreetmap.org/search';
  static const _nominatimReverseUrl =
      'https://nominatim.openstreetmap.org/reverse';

  // ─── OSRM routing endpoint ────────────────────────────────────────────
  static const _osrmRouteUrl =
      'https://router.project-osrm.org/route/v1/driving';

  // ─── Places Search (Nominatim) ────────────────────────────────────────

  /// Search for place predictions using Nominatim free-text search.
  /// Returns empty list on error.
  Future<List<PlacePrediction>> getPlacePredictions(
    String input, {
    String? countryCode,
    LatLng? location,
    int radiusMeters = 50000,
  }) async {
    if (input.trim().length < 2) return [];

    try {
      final params = <String, dynamic>{
        'q': input.trim(),
        'format': 'json',
        'addressdetails': '1',
        'limit': '8',
      };
      if (countryCode != null) {
        params['countrycodes'] = countryCode;
      }
      if (location != null) {
        params['viewbox'] =
            '${location.longitude - 0.5},${location.latitude - 0.5},'
            '${location.longitude + 0.5},${location.latitude + 0.5}';
        params['bounded'] = '0';
      }

      final response = await _dio.get(
        _nominatimSearchUrl,
        queryParameters: params,
        options: Options(headers: {
          if (!kIsWeb) 'User-Agent': 'RideConnect/1.0',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        final results = response.data as List;
        return results.map((r) {
          final displayName = r['display_name'] ?? '';
          final parts = displayName.split(',');
          final mainText = parts.isNotEmpty ? parts.first.trim() : displayName;
          final secondaryText =
              parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
          return PlacePrediction(
            placeId: r['place_id']?.toString() ?? '',
            description: displayName,
            mainText: mainText,
            secondaryText: secondaryText,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Nominatim search error: $e');
    }

    return [];
  }

  /// Get the lat/lng for a Nominatim place ID (re-uses search by osm_id).
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      // Look up by Nominatim place_id using reverse with osm_id
      final response = await _dio.get(
        _nominatimSearchUrl,
        queryParameters: {
          'q': placeId,
          'format': 'json',
          'limit': '1',
          'addressdetails': '1',
        },
        options: Options(headers: {
          if (!kIsWeb) 'User-Agent': 'RideConnect/1.0',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 && (response.data as List).isNotEmpty) {
        final result = response.data[0];
        
        String displayName = result['display_name'] ?? '';
        final parts = displayName.split(',').map((e) => e.trim()).toList();
        parts.removeWhere((part) => RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,8}$', caseSensitive: false).hasMatch(part));
        String cleanAddress = parts.join(', ');
        
        return PlaceDetails(
          latitude: double.parse(result['lat']),
          longitude: double.parse(result['lon']),
          formattedAddress: cleanAddress,
        );
      }
    } catch (e) {
      debugPrint('Nominatim place details error: $e');
    }

    return null;
  }

  /// Forward geocode an address string to coordinates using Nominatim.
  Future<PlaceDetails?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      final response = await _dio.get(
        _nominatimSearchUrl,
        queryParameters: {
          'q': address.trim(),
          'format': 'json',
          'limit': '1',
          'addressdetails': '1',
        },
        options: Options(headers: {
          if (!kIsWeb) 'User-Agent': 'RideConnect/1.0',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 && (response.data as List).isNotEmpty) {
        final result = response.data[0];
        
        String displayName = result['display_name'] ?? address;
        final parts = displayName.split(',').map((e) => e.trim()).toList();
        parts.removeWhere((part) => RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,8}$', caseSensitive: false).hasMatch(part));
        String cleanAddress = parts.join(', ');
        if (cleanAddress.isEmpty) cleanAddress = address;
        
        return PlaceDetails(
          latitude: double.parse(result['lat']),
          longitude: double.parse(result['lon']),
          formattedAddress: cleanAddress,
        );
      }
    } catch (e) {
      debugPrint('Nominatim geocoding error: $e');
    }

    return null;
  }

  /// Reverse geocode coordinates to an address using Nominatim.
  Future<PlaceDetails?> reverseGeocode(double lat, double lng) async {
    try {
      final response = await _dio.get(
        _nominatimReverseUrl,
        queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'json',
          'addressdetails': '1',
        },
        options: Options(headers: {
          if (!kIsWeb) 'User-Agent': 'RideConnect/1.0',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        String displayName = response.data['display_name'] ?? '';
        final parts = displayName.split(',').map((e) => e.trim()).toList();
        parts.removeWhere((part) => RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,8}$', caseSensitive: false).hasMatch(part));
        String cleanAddress = parts.join(', ');
        
        return PlaceDetails(
          latitude: double.parse(response.data['lat']),
          longitude: double.parse(response.data['lon']),
          formattedAddress: cleanAddress,
        );
      }
    } catch (e) {
      debugPrint('Nominatim reverse geocode error: $e');
    }

    return null;
  }

  // ─── Directions (OSRM) ───────────────────────────────────────────────

  /// Fetch a route between [origin] and [destination] using OSRM.
  ///
  /// Falls back to a simulated route if the request fails.
  Future<RouteInfo?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url =
          '$_osrmRouteUrl/${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}';

      final response = await _dio.get(
        url,
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline',
          'steps': 'false',
        },
      );

      if (response.statusCode == 200 &&
          response.data['code'] == 'Ok' &&
          (response.data['routes'] as List).isNotEmpty) {
        return _parseOsrmResponse(response.data, origin, destination);
      }
    } catch (e) {
      debugPrint('OSRM Directions error: $e');
    }

    // Fallback: generate a simulated route curve
    return _simulateRoute(origin, destination);
  }

  RouteInfo _parseOsrmResponse(
    Map<String, dynamic> data,
    LatLng origin,
    LatLng destination,
  ) {
    final route = data['routes'][0];
    final geometry = route['geometry'] as String;
    final points = decodePolyline(geometry);

    final distanceMeters = (route['distance'] as num).toDouble();
    final durationSeconds = (route['duration'] as num).toDouble();

    final distanceKm = distanceMeters / 1000;
    final durationMinutes = (durationSeconds / 60).ceil();

    // Calculate bounds from polyline points
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    String distanceText;
    if (distanceKm < 1) {
      distanceText = '${distanceMeters.round()} m';
    } else {
      distanceText = '${distanceKm.toStringAsFixed(1)} km';
    }

    String durationText;
    if (durationMinutes < 60) {
      durationText = '$durationMinutes min';
    } else {
      final hours = durationMinutes ~/ 60;
      final mins = durationMinutes % 60;
      durationText = '${hours}h ${mins}m';
    }

    return RouteInfo(
      polylinePoints: points,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      distanceText: distanceText,
      durationText: durationText,
      bounds: LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
    );
  }

  /// Decode an encoded polyline string (Google/OSRM format) into a list of LatLng.
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1F) << shift;
        shift += 5;
      } while (byte >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Generate a simulated route as a Bezier curve for demo / offline mode.
  RouteInfo _simulateRoute(LatLng origin, LatLng destination) {
    const steps = 40;
    final points = <LatLng>[];

    // Create a slight arc through a control point offset to one side
    final midLat = (origin.latitude + destination.latitude) / 2;
    final midLng = (origin.longitude + destination.longitude) / 2;
    final latDiff = destination.latitude - origin.latitude;
    final lngDiff = destination.longitude - origin.longitude;
    // Perpendicular offset for the arc
    final controlLat = midLat + lngDiff * 0.15;
    final controlLng = midLng - latDiff * 0.15;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = (1 - t) * (1 - t) * origin.latitude +
          2 * (1 - t) * t * controlLat +
          t * t * destination.latitude;
      final lng = (1 - t) * (1 - t) * origin.longitude +
          2 * (1 - t) * t * controlLng +
          t * t * destination.longitude;
      points.add(LatLng(lat, lng));
    }

    // Approximate distance in km using Haversine
    final distanceKm = _haversineDistance(origin, destination);
    // Rough ETA: average speed ~30 km/h in the city
    final durationMinutes = max(3, (distanceKm / 30 * 60).round());

    final allLats = points.map((p) => p.latitude);
    final allLngs = points.map((p) => p.longitude);
    final bounds = LatLngBounds(
      southwest: LatLng(allLats.reduce(min), allLngs.reduce(min)),
      northeast: LatLng(allLats.reduce(max), allLngs.reduce(max)),
    );

    return RouteInfo(
      polylinePoints: points,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      distanceText: '${distanceKm.toStringAsFixed(1)} km',
      durationText: '$durationMinutes min',
      bounds: bounds,
    );
  }

  double _haversineDistance(LatLng a, LatLng b) {
    const earthRadius = 6371.0; // km
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);
    final sinLat = sin(dLat / 2);
    final sinLng = sin(dLng / 2);
    final h = sinLat * sinLat +
        cos(_degToRad(a.latitude)) * cos(_degToRad(b.latitude)) * sinLng * sinLng;
    return 2 * earthRadius * asin(sqrt(h));
  }

  double _degToRad(double deg) => deg * pi / 180;
}

/// Riverpod provider for [OpenMapsService].
final openMapsServiceProvider = Provider<OpenMapsService>((ref) {
  return OpenMapsService();
});
