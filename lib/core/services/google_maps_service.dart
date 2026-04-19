import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A place prediction from Google Places Autocomplete.
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

/// Route data returned by the Google Maps Directions API.
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

/// Service wrapping Google Maps APIs: Directions, Places Autocomplete, Geocoding.
class GoogleMapsService {
  GoogleMapsService({String? apiKey})
      : _apiKey = apiKey ?? const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
        _dio = Dio();

  final String _apiKey;
  final Dio _dio;

  bool get hasApiKey => _apiKey.isNotEmpty && _apiKey != 'YOUR_API_KEY_HERE';

  static const _directionsUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const _placeDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  // ─── Places Autocomplete ──────────────────────────────────────────────

  /// Search for place predictions using Google Places Autocomplete API.
  /// Returns empty list if no API key or on error.
  Future<List<PlacePrediction>> getPlacePredictions(
    String input, {
    String? countryCode,
    LatLng? location,
    int radiusMeters = 50000,
  }) async {
    if (!hasApiKey || input.trim().length < 2) return [];

    try {
      final params = <String, dynamic>{
        'input': input.trim(),
        'key': _apiKey,
        'types': 'geocode|establishment',
      };
      if (countryCode != null) {
        params['components'] = 'country:$countryCode';
      }
      if (location != null) {
        params['location'] = '${location.latitude},${location.longitude}';
        params['radius'] = radiusMeters;
      }

      final response = await _dio.get(_autocompleteUrl, queryParameters: params);

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final predictions = response.data['predictions'] as List;
        return predictions.map((p) {
          final structured = p['structured_formatting'] ?? {};
          return PlacePrediction(
            placeId: p['place_id'] ?? '',
            description: p['description'] ?? '',
            mainText: structured['main_text'] ?? p['description'] ?? '',
            secondaryText: structured['secondary_text'] ?? '',
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Places Autocomplete error: $e');
    }

    return [];
  }

  /// Get the lat/lng for a Place ID using Google Place Details API.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (!hasApiKey || placeId.isEmpty) return null;

    try {
      final response = await _dio.get(_placeDetailsUrl, queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,formatted_address',
        'key': _apiKey,
      });

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final result = response.data['result'];
        final location = result['geometry']['location'];
        return PlaceDetails(
          latitude: (location['lat'] as num).toDouble(),
          longitude: (location['lng'] as num).toDouble(),
          formattedAddress: result['formatted_address'] ?? '',
        );
      }
    } catch (e) {
      debugPrint('Place Details error: $e');
    }

    return null;
  }

  /// Forward geocode an address string to coordinates using Google Geocoding API.
  Future<PlaceDetails?> geocodeAddress(String address) async {
    if (!hasApiKey || address.trim().isEmpty) return null;

    try {
      final response = await _dio.get(_geocodeUrl, queryParameters: {
        'address': address.trim(),
        'key': _apiKey,
      });

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final results = response.data['results'] as List;
        if (results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          return PlaceDetails(
            latitude: (location['lat'] as num).toDouble(),
            longitude: (location['lng'] as num).toDouble(),
            formattedAddress: results[0]['formatted_address'] ?? address,
          );
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    return null;
  }

  // ─── Directions ──────────────────────────────────────────────────────

  /// Fetch a route between [origin] and [destination].
  ///
  /// Falls back to a simulated route if no API key is set or the request fails.
  Future<RouteInfo?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // Attempt real Directions API when key is provided
    if (hasApiKey) {
      try {
        final response = await _dio.get(
          _directionsUrl,
          queryParameters: {
            'origin': '${origin.latitude},${origin.longitude}',
            'destination': '${destination.latitude},${destination.longitude}',
            'key': _apiKey,
            'mode': 'driving',
          },
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
            return _parseDirectionsResponse(data);
          }
        }
      } catch (e) {
        debugPrint('Directions API error: $e');
      }
    }

    // Fallback: generate a simulated route curve
    return _simulateRoute(origin, destination);
  }

  RouteInfo _parseDirectionsResponse(Map<String, dynamic> data) {
    final route = data['routes'][0];
    final leg = route['legs'][0];

    final polylineEncoded = route['overview_polyline']['points'] as String;
    final points = decodePolyline(polylineEncoded);

    final distanceMeters = leg['distance']['value'] as int;
    final durationSeconds = leg['duration']['value'] as int;

    final sw = LatLng(
      route['bounds']['southwest']['lat'].toDouble(),
      route['bounds']['southwest']['lng'].toDouble(),
    );
    final ne = LatLng(
      route['bounds']['northeast']['lat'].toDouble(),
      route['bounds']['northeast']['lng'].toDouble(),
    );

    return RouteInfo(
      polylinePoints: points,
      distanceKm: distanceMeters / 1000,
      durationMinutes: (durationSeconds / 60).ceil(),
      distanceText: leg['distance']['text'] as String,
      durationText: leg['duration']['text'] as String,
      bounds: LatLngBounds(southwest: sw, northeast: ne),
    );
  }

  /// Decode an encoded Google Maps polyline string into a list of LatLng.
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

  /// Generate a simulated route as a Bezier curve for demo / no-API-key mode.
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

/// Riverpod provider for [GoogleMapsService].
final googleMapsServiceProvider = Provider<GoogleMapsService>((ref) {
  return GoogleMapsService();
});
