import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  
  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });
  
  @override
  String toString() => 'LocationData($latitude, $longitude, $address)';
}

/// Location Service for GPS and geocoding
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<LocationData>.broadcast();
  
  Stream<LocationData> get locationStream => _locationController.stream;
  
  /// Check and request location permissions
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }
  
  /// Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
  
  /// Get current location with address
  Future<LocationData?> getCurrentLocationWithAddress() async {
    try {
      final location = await getCurrentLocation();
      if (location == null) return null;

      final withAddress = await getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
      return LocationData(
        latitude: withAddress.latitude,
        longitude: withAddress.longitude,
        address: (withAddress.address?.isNotEmpty ?? false)
            ? withAddress.address
            : 'Current Location',
        city: withAddress.city,
        state: withAddress.state,
        country: withAddress.country,
        postalCode: withAddress.postalCode,
      );
    } catch (e) {
      debugPrint('Error getting location with address: $e');
      return null;
    }
  }
  
  /// Reverse geocode - get address from coordinates
  Future<LocationData> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final formattedAddress = _formatPlacemarkAddress(place);
        
        if (formattedAddress != null && formattedAddress.isNotEmpty) {
          return LocationData(
            latitude: lat,
            longitude: lng,
            address: formattedAddress,
            city: place.locality,
            state: place.administrativeArea,
            country: place.country,
            postalCode: place.postalCode,
          );
        }
      }
    } catch (e) {
      debugPrint('Native reverse geocoding failed: $e');
    }

    // Fallback to nominatim
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
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
        final data = response.data;
        final addressObj = data['address'] ?? {};
        
        String displayName = data['display_name'] ?? '';
        final parts = displayName.split(',').map((e) => e.trim()).toList();
        parts.removeWhere((part) => RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,8}$', caseSensitive: false).hasMatch(part));
        String cleanAddress = parts.join(', ');
        if (cleanAddress.isEmpty) cleanAddress = 'Current Location';

        return LocationData(
          latitude: lat,
          longitude: lng,
          address: cleanAddress,
          city: addressObj['city'] ?? addressObj['town'] ?? addressObj['village'],
          state: addressObj['state'],
          country: addressObj['country'],
          postalCode: addressObj['postcode'],
        );
      }
    } catch (e) {
      debugPrint('Nominatim fallback failed: $e');
    }

    return LocationData(latitude: lat, longitude: lng, address: 'Current Location');
  }
  
  /// Forward geocode - get coordinates from address
  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        final resolved = await getAddressFromCoordinates(
          location.latitude,
          location.longitude,
        );
        return LocationData(
          latitude: resolved.latitude,
          longitude: resolved.longitude,
          address: (resolved.address?.isNotEmpty ?? false)
              ? resolved.address
              : address,
          city: resolved.city,
          state: resolved.state,
          country: resolved.country,
          postalCode: resolved.postalCode,
        );
      }
    } catch (e) {
      debugPrint('Native forward geocoding failed: $e');
    }

    // Fallback to nominatim
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
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
        final lat = double.parse(result['lat']);
        final lon = double.parse(result['lon']);
        final addressObj = result['address'] ?? {};
        
        String displayName = result['display_name'] ?? address;
        final parts = displayName.split(',').map((e) => e.trim()).toList();
        parts.removeWhere((part) => RegExp(r'^[A-Z0-9]{2,8}\+[A-Z0-9]{2,8}$', caseSensitive: false).hasMatch(part));
        String cleanAddress = parts.join(', ');
        if (cleanAddress.isEmpty) cleanAddress = address;

        return LocationData(
          latitude: lat,
          longitude: lon,
          address: cleanAddress,
          city: addressObj['city'] ?? addressObj['town'] ?? addressObj['village'],
          state: addressObj['state'],
          country: addressObj['country'],
          postalCode: addressObj['postcode'],
        );
      }
    } catch (e) {
      debugPrint('Nominatim forward geocoding failed: $e');
    }

    return null;
  }

  String? _formatPlacemarkAddress(Placemark place) {
    final addressParts = [
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ]
        .where((part) => part != null && part.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    return addressParts.isEmpty ? null : addressParts.join(', ');
  }
  
  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    ) / 1000; // Convert to kilometers
  }
  
  /// Start location tracking
  void startTracking({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).listen((position) async {
      try {
        final withAddress = await getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        _locationController.add(withAddress);
      } catch (_) {
        _locationController.add(
          LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
      }
    });
  }
  
  /// Stop location tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
  
  /// Get default location (used when GPS is unavailable)
  LocationData getDefaultLocation() {
    return LocationData(
      latitude: AppConfig.defaultLatitude,
      longitude: AppConfig.defaultLongitude,
      address: 'Default Location',
    );
  }
  
  /// Dispose resources
  void dispose() {
    stopTracking();
    _locationController.close();
  }
}

/// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Current location provider
final currentLocationProvider = FutureProvider<LocationData?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getCurrentLocationWithAddress();
});

/// Location stream provider
final locationStreamProvider = StreamProvider<LocationData>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  locationService.startTracking();
  return locationService.locationStream;
});
